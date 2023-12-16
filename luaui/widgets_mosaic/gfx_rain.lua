function widget:GetInfo()
    return {
        name = "aRain",
        desc = "Lets it automaticly rain",
        author = "Picasso",
        date = "2023",
        license = "GNU GPL, v2 or later",
        layer = 3,
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

local rainShader = nil

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
local spGetGameFrame = Spring.GetGameFrame
local glBeginEnd = gl.BeginEnd
local glVertex = gl.Vertex
local glBlending = gl.Blending
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
local glResetState = gl.ResetState


--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
-- Variables
local boolRainActive = false
local pausedTime = 0
local lastFrametime = Spring.GetTimer()
local raincanvastex = nil
local depthtex = nil
local noisetex = nil
local screentex = nil
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
local noisetextureFilePath = ":n:LuaUI/images/noise.png"
local canvasRainTextureID = 0
local vsx, vsy = Spring.GetViewGeometry()
local cam = {}
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

    local defaultVertexShader = 
    [[
       #version 150 compatibility
       #line 100087

        uniform sampler2D raincanvastex;
        uniform sampler2D screentex;
        uniform sampler2D depthtex;
        uniform sampler2D noisetex;

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

        uniform sampler2D raincanvastex;
        uniform sampler2D screentex;
        uniform sampler2D depthtex;
        uniform sampler2D noisetex;
        
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
    noisetex = gl.Texture(0, noisetextureFilePath)
    raincanvastex =
        gl.CreateTexture(
        vsx,
        vsy,
        {
            border = false,
            min_filter = GL.NEAREST,
            mag_filter = GL.NEAREST
        }
    )
    if raincanvastex == nil then
        Spring.Echo("No raincanvastex - aborting")       
        widgetHandler:RemoveWidget(self)
        return
    end

    depthtex =
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
    if depthtex == nil then
        Spring.Echo("No depthtex - aborting")
        widgetHandler:RemoveWidget(self)
        return
    end

    screentex =
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
    if screentex == nil then
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
        raincanvastex = 0,
        depthtex = 1,
        noisetex = 2,
        screentex = 3
    }

    rainShader =
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

    if (rainShader == nil) then
        Spring.Echo("gfx_rain:Initialize] particle shader compilation failed")
        Spring.Echo(glGetShaderLog())
        widgetHandler:RemoveWidget(self)
        return
    else
        Spring.Echo("gfx_rain: Shader compiled: "..glGetShaderLog())
    end

    shaderTimeLoc = glGetUniformLocation(rainShader, "time")
    shaderRainDensityLoc = glGetUniformLocation(rainShader, "rainDensity")
    shaderCamPosLoc = glGetUniformLocation(rainShader, "camWorldPos")
    shaderMaxLightSrcLoc = glGetUniformLocation(rainShader, "maxLightSources")
    shaderLightSourcescLoc = glGetUniformLocation(rainShader, "lightSources")

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
    glDeleteTexture(0, raincanvastex)
    glDeleteTexture(1, depthtex)
    glDeleteTexture(2, noisetex)
    glDeleteTexture(3, screentex)
    enabled = false
end


function widget:Shutdown()
    if glDeleteTexture then
        glDeleteTexture(raincanvastex or "")
        glDeleteTexture(depthtex or "")
        glDeleteTexture(noisetex or "")
        glDeleteTexture(screentex or "")
    end

    if rainShader then
        gl.DeleteShader(rainShader)
    end
end
local function prepareTextures()
    Spring.Echo("Preparing Texture start")
    glCopyToTexture(screenTex, 0, 0, 0, 0, vsx, vsy)
    glCopyToTexture(depthTex, 0, 0, 0, 0, vsx, vsy) -- the depth texture
    glCopyToTexture(raincanvasTex, 0, 0, 0, 0, vsx, vsy) -- the original screen image
    Spring.Echo("Preparing Texture end")
end

function widget:DrawScreenEffects()
    Spring.Echo("Enter DrawScreenEffects")
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
    if rainShader == nil then 
        Spring.Echo("No Shader")
        return 
    else
        Spring.Echo("Using rain shader")
        prepareTextures()

        camX, camY, camZ = Spring.GetCameraPosition()
        diffTime = Spring.DiffTimers(lastFrametime, startTimer) - pausedTime

        glUniform(shaderTimeLoc, diffTime )
        glUniform(shaderCamPosLoc,  {camX, camY, camZ})
        glUniform(shaderRainDensityLoc, rainDensity )
        glUniform(shaderMaxLightSrcLoc, math.floor(maxLightSources))
        glUniform(shaderLightSourcescLoc, shaderLightSources)
       
        glUseShader(shaderProgram)
		--draw the result as rectangle (with transparency in gui space)
        glTexRect(0,vsy,vsx,0)

        --glBlending(GL_ONE, GL_ONE_MINUS_SRC_ALPHA)
        --glTexRect(canvasRainTextureID, vsy, vsx, 0)
        --glBlending(GL.SRC_ALPHA, GL.ONE)
        local osClock = os.clock()
        local timePassed = osClock - prevOsClock
        prevOsClock = osClock

        
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
