function widget:GetInfo()
    return {
        name = "aRain",
        desc = "Lets it automaticly rain",
        author = "Picasso",
        date = "2023",
        license = "GNU GPL, v2 or later",
        layer = 1,
        enabled = true, --  loaded by default?
        handler = true
    }
end

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

-- /rain    -- toggles snow on current map (also remembers this)

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

-- > debugEchoT(

local shader = nil

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
local spGetGameFrame = Spring.GetGameFrame
local glBeginEnd = gl.BeginEnd
local glVertex = gl.Vertex
local glColor = gl.Color
local glBlending = gl.Blending
local glTranslate = gl.Translate
local glCallList = gl.CallList
local glDepthTest = gl.DepthTest
local glCopyToTexture = gl.CopyToTexture
local glCreateList = gl.CreateList
local glDeleteList = gl.DeleteList
local glTexture = gl.Texture
local glGetShaderLog = gl.GetShaderLog
local glCreateShader = gl.CreateShader
local glDeleteShader = gl.DeleteShader
local glUseShader = gl.UseShader
local glUniformMatrix = gl.UniformMatrix
local glUniformInt = gl.UniformInt
local glUniform = gl.Uniform
local glGetUniformLocation = gl.GetUniformLocation
local glGetActiveUniforms = gl.GetActiveUniforms
local glBeginEnd = gl.BeginEnd
local glPointSprite = gl.PointSprite
local glPointSize = gl.PointSize
local glPointParameter = gl.PointParameter
local glResetState = gl.ResetState
local GL_POINTS = GL.POINTS

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
-- Variables
local boolRainActive = false
local pausedTime = 0
local lastFrametime = Spring.GetTimer()
local raincanvasTex = nil
local depthTex = nil
local noiseTex = nil
local screenTex = nil
local startOsClock
local shaderFilePath = "luaui/widgets_mosaic/shaders/"
local DAYLENGTH = 28800
local rainDensity = 0.5
local shaderTimeLoc
local shaderRainDensityLoc
local shaderCamPosLoc
local shaderMaxLightSrcLoc
local shaderLightSourcescLoc
local boolRainyArea = false
local maxLightSources = 0
local shaderLightSources = {}
local noiseTextureFilePath = ":n:LuaUI/images/noise.png"
local canvasRainTextureID = 0
local vsx, vsy = Spring.GetViewGeometry()
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

    local defaultVertexShader = 
    [[
       #version 150 compatibility
       #line 100087

        uniform sampler2D raincanvasTex;
        uniform sampler2D screenTex;
        uniform sampler2D depthTex;
        uniform sampler2D noiseTex;

        uniform float time;
        //uniform vec3 unitCenterPosition;
        //uniform float viewPosX;
        //uniform float viewPosY;

        void main() {
            vec4 posCopy = gl_Vertex;
            posCopy.z = sin(time)*posCopy.z;
            gl_Position = posCopy;
        }
    ]]
    local defaultTestFragmentShader = 
    [[
        #version 150 compatibility
        #line 200103

        uniform sampler2D raincanvasTex;
        uniform sampler2D screenTex;
        uniform sampler2D depthTex;
        uniform sampler2D noiseTex;
        
        uniform float time;
        //uniform vec3 unitCenterPosition;
        //uniform float viewPosX;
        //uniform float viewPosY;

        void main() 
        {
            gl_FragColor = vec4( 1.0, 0.0, 0.0, 0.5);
        }
    ]]


function widget:ViewResize(viewSizeX, viewSizeY)
    vsx, vsy = viewSizeX, viewSizeY
    noiseTex = gl.Texture(0, noiseTextureFilePath)
    raincanvasTex =
        gl.CreateTexture(
        vsx,
        vsy,
        {
            border = false,
            min_filter = GL.NEAREST,
            mag_filter = GL.NEAREST
        }
    )
    if raincanvasTex == nil then
        Spring.Echo("No raincanvasTex - aborting")       
        widgetHandler:RemoveWidget(self)
        return
    end

    depthTex =
        gl.CreateTexture(
        vsx,
        vsy,
        {
            border = false,
            format = GL_DEPTH_COMPONENT24,
            min_filter = GL.NEAREST,
            mag_filter = GL.NEAREST
        }
    )
    if depthTex == nil then
        Spring.Echo("No depthTex - aborting")
        widgetHandler:RemoveWidget(self)
        return
    end

    screenTex =
        gl.CreateTexture(
        vsx,
        vsy,
        {
        fbo = true, 
        min_filter = GL.LINEAR, 
        mag_filter = GL.LINEAR,
        wrap_s = GL.CLAMP_TO_EDGE, 
        wrap_t = GL.CLAMP_TO_EDGE,
        }
    )
    if screenTex == nil then
        Spring.Echo("No screen Tex - aborting")
        widgetHandler:RemoveWidget(self)
        return 
    else
        widgetHandler:UpdateCallIn("DrawScreenEffects")
    end
end

local function init()
    Spring.Echo("gfx_rain:Initialize")
    -- abort if not enabled

    if (glCreateShader == nil) then
        Spring.Echo("[Rain widget:Initialize] no shader support")
        widgetHandler:RemoveWidget(self)
        return
    end
    --https://www.shadertoy.com/view/wd2GDG inspiration
    local fragmentShader =  VFS.LoadFile(shaderFilePath .. "rainShader.frag") --defaultTestFragmentShader
    local vertexShader = VFS.LoadFile(shaderFilePath .. "rainShader.vert") --defaultVertexShader
    local uniformInt = {
        raincanvasTex = 0,
        depthTex = 1,
        noiseTex = 2,
        screenTex = 3
    }

    shader =
        glCreateShader(
        {
            fragment = fragmentShader,
            vertex = vertexShader,
            uniformInt = uniformInt,
            uniform = {
                time = diffTime,
                scale = 0,
                camWorldPos = {0, 0, 0}
            },
            uniformFloat = {
                viewPortSize = {vsx, vsy}
            }
        }
    )

    if (shader == nil) then
        Spring.Echo("gfx_rain:Initialize] particle shader compilation failed")
        Spring.Echo(glGetShaderLog())
        widgetHandler:RemoveWidget(self)
        return
    else
        Spring.Echo("gfx_rain: Shader compiled: "..glGetShaderLog())
    end

    shaderTimeLoc = glGetUniformLocation(shader, "time")
    shaderRainDensityLoc = glGetUniformLocation(shader, "rainDensity")
    shaderCamPosLoc = glGetUniformLocation(shader, "camWorldPos")
    shaderMaxLightSrcLoc = glGetUniformLocation(shader, "maxLightSources")
    shaderLightSourcescLoc = glGetUniformLocation(shader, "lightSources")

    Spring.Echo("gfx_rain:Initialize ended")
end

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
local function getDetermenisticHash()
    local accumulated = 0
    local mapName = Game.mapName
    local mapNameLength = string.len(mapName)

    for i = 1, mapNameLength do
        accumulated = accumulated + string.byte(mapName, i)
    end

    accumulated = accumulated + Game.mapSizeX
    accumulated = accumulated + Game.mapSizeZ
    return accumulated
end

local function isRainyArea()
    return true
--    return getDetermenisticHash() % 2 == 0
end

local function getDayTime()
    local morningOffset = (DAYLENGTH / 2)
    local Frame = (Spring.GetGameFrame() + morningOffset) % DAYLENGTH
    local percent = Frame / DAYLENGTH
    local hours = math.floor((Frame / DAYLENGTH) * 24)
    local minutes = math.ceil((((Frame / DAYLENGTH) * 24) - hours) * 60)
    local seconds = 60 - ((24 * 60 * 60 - (hours * 60 * 60) - (minutes * 60)) % 60)
    return hours, minutes, seconds, percent
end

local function isRaining()
    if boolRainyArea == nil then
        boolRainyArea = isRainyArea()
    end
    if boolRainyArea == false then
        return false
    end

    local hours = getDayTime()
    local gameFrames = Spring.GetGameFrame()
    local dayNr = gameFrames / DAYLENGTH

    return dayNr % 3 < 1.0 and (hours > 18 or hours < 7)
end

function widget:Update(dt)
    boolRainActive = isRaining()
end

function widget:Shutdown()
    glDeleteTexture(0, raincanvasTex)
    glDeleteTexture(1, depthTex)
    glDeleteTexture(2, noiseTex)
    glDeleteTexture(3, screenTex)
    enabled = false
end


function widget:Shutdown()
    if glDeleteTexture then
        glDeleteTexture(raincanvasTex or "")
        glDeleteTexture(depthTex or "")
        glDeleteTexture(noiseTex or "")
        glDeleteTexture(screenTex or "")
    end

    if shader then
        gl.DeleteShader(shader)
    end
end

function widget:DrawScreenEffects()
           -- Spring.Echo("Using rain shader1")
    --if boolRainActive == false then
    --            Spring.Echo("Using rain shader2")
    --    return
    --end

    local _, _, isPaused = Spring.GetGameSpeed()
    --if isPaused then
    --    pausedTime = pausedTime + Spring.DiffTimers(Spring.GetTimer(), lastFrametime)
    --            Spring.Echo("Using rain shader3")
    --    return
    --end

    lastFrametime = Spring.GetTimer()


    if shader == nil then 
        Spring.Echo("No Shader")
        return 
    else

        Spring.Echo("Using rain shader")
        --glCopyToTexture(screenTex, 0, 0, 0, 0, vsx, vsy)
        --glCopyToTexture(depthTex, 0, 0, 0, 0, vsx, vsy) -- the depth texture
        --glCopyToTexture(raincanvasTex, 0, 0, 0, 0, vsx, vsy) -- the original screen image

        camX, camY, camZ = Spring.GetCameraPosition()
        diffTime = Spring.DiffTimers(lastFrametime, startTimer) - pausedTime

        glUniform(shaderTimeLoc, diffTime * 1)
        glUniform(shaderCamPosLoc, camX, camY, camZ)
        glUniform(shaderRainDensityLoc, rainDensity * 1)
        glUniform(shaderMaxLightSrcLoc, math.floor(maxLightSources))
        glUniform(shaderLightSourcescLoc, shaderLightSources)
       
        glUseShader(shaderProgram)
        glTexRect(0,vsy,vsx,0)

        --glBlending(GL_ONE, GL_ONE_MINUS_SRC_ALPHA)
        --glTexRect(canvasRainTextureID, vsy, vsx, 0)
        --glBlending(GL.SRC_ALPHA, GL.ONE)
        local osClock = os.clock()
        local timePassed = osClock - prevOsClock
        prevOsClock = osClock
        glTexRect(0,vsy,vsx,0)
        glTexture(0, false)
        glTexture(1, false)
        glTexture(2, false)
        glTexture(3, false)
        glResetState()
        glUseShader(0)
    end
    
end

function widget:ViewResize(newX, newY)
    vsx, vsy = newX, newY
end

function widget:Initialize()
    init()
    vsx, vsy = widgetHandler:GetViewSizes()
    widget:ViewResize(vsx, vsy)
    startOsClock = os.clock()
end

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
