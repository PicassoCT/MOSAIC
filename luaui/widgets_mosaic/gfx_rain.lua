function widget:GetInfo()
    return {
        name = "_Rain",
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

local GL_MODELVIEW           = GL.MODELVIEW
local GL_NEAREST             = GL.NEAREST
local GL_ONE                 = GL.ONE
local GL_ONE_MINUS_SRC_ALPHA = GL.ONE_MINUS_SRC_ALPHA
local GL_PROJECTION          = GL.PROJECTION
local GL_QUADS               = GL.QUADS
local GL_SRC_ALPHA           = GL.SRC_ALPHA
local glBeginEnd             = gl.BeginEnd
local glBlending             = gl.Blending
local glCallList             = gl.CallList
local glColor                = gl.Color
local glColorMask            = gl.ColorMask
local glCopyToTexture        = gl.CopyToTexture
local glCreateList           = gl.CreateList
local glCreateShader         = gl.CreateShader
local glCreateTexture        = gl.CreateTexture
local glDeleteShader         = gl.DeleteShader
local glDeleteTexture        = gl.DeleteTexture
local glDepthMask            = gl.DepthMask
local glDepthTest            = gl.DepthTest
local glGetMatrixData        = gl.GetMatrixData
local glGetShaderLog         = gl.GetShaderLog
local glGetUniformLocation   = gl.GetUniformLocation
local glGetViewSizes         = gl.GetViewSizes
local glLoadIdentity         = gl.LoadIdentity
local glLoadMatrix           = gl.LoadMatrix
local glMatrixMode           = gl.MatrixMode
local glMultiTexCoord        = gl.MultiTexCoord
local glPopMatrix            = gl.PopMatrix
local glPushMatrix           = gl.PushMatrix
local glRenderToTexture      = gl.RenderToTexture
local glResetMatrices        = gl.ResetMatrices
local glTexCoord             = gl.TexCoord
local glTexture              = gl.Texture
local glRect                 = gl.Rect
local glUniform              = gl.Uniform
local glUniformMatrix        = gl.UniformMatrix
local glUseShader            = gl.UseShader
local glVertex               = gl.Vertex
local glTranslate            = gl.Translate
local spGetCameraPosition    = Spring.GetCameraPosition
local spGetCameraVectors     = Spring.GetCameraVectors
local spGetWind              = Spring.GetWind
local time                   = Spring.GetGameSeconds
local spGetDrawFrame         = Spring.GetDrawFrame

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
local noisetextureFilePath = ":l:luaui/images/noise.png"
local canvasRainTextureID = 0
local vsx, vsy = Spring.GetViewGeometry()
local cam = {}
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
    local function errorOutIfNotInitialized(value, name)
        if value == nil then
            Spring.Echo("No "..name.." - aborting")
            widgetHandler:RemoveWidget(self)
        end
    end

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

    if (depthtex) then
        glDeleteTexture(depthtex)
    end
    
    if (raincanvastex) then
        glDeleteTexture(raincanvastex)
    end

     if (screentex) then
        glDeleteTexture(screentex)
    end


    raincanvastex =
        gl.CreateTexture(
        vsx,
        vsy,
        {
            min_filter = GL.LINEAR,
            mag_filter = GL.LINEAR,
            wrap_s = GL.CLAMP_TO_EDGE,
            wrap_t = GL.CLAMP_TO_EDGE,
            fbo = true,
        }
    )
    errorOutIfNotInitialized(raincanvastex, "raincanvastex not existing")

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
    errorOutIfNotInitialized(depthtex, "depthtex not existing")    

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
    errorOutIfNotInitialized(screentex, "screentex not existing")       
    widgetHandler:UpdateCallIn("DrawScreenEffects")  
end

local function init()
    Spring.Echo("gfx_rain:Initialize")
    -- abort if not enabled

    errorOutIfNotInitialized(glCreateShader, "no shader support")

    --https://www.shadertoy.com/view/wd2GDG inspiration
    local fragmentShader =  VFS.LoadFile(shaderFilePath .. "rainShader.frag") --defaultTestFragmentShader
    local vertexShader = VFS.LoadFile(shaderFilePath .. "rainShader.vert") --defaultVertexShader
    local uniformInt = {
        depthtex = 0,
        noisetex = 1,
        screentex = 2,
        raincanvastex = 3,
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

    shaderTimeLoc                   = glGetUniformLocation(rainShader, "time")
    shaderRainDensityLoc            = glGetUniformLocation(rainShader, "rainDensity")
    shaderCamPosLoc                 = glGetUniformLocation(rainShader, "camWorldPos")
    shaderMaxLightSrcLoc            = glGetUniformLocation(rainShader, "maxLightSources")
    shaderLightSourcescLoc          = glGetUniformLocation(rainShader, "lightSources")
      for i=1,maxLightSources do
        shaderLightSourcescLoc[i]   = gl.GetUniformLocation(rainShader,"lightSources["..(i-1).."]")
      end
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
    return getDetermenisticHash() % 2 == 0
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
    boolRainActive = true --isRaining()
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
    noisetex = glTexture(2, noisetextureFilePath)
    Spring.Echo("Preparing Texture start")
    glCopyToTexture(screentex, 0, 0, 0, 0, vsx, vsy)
    glCopyToTexture(depthtex, 0, 0, 0, 0, vsx, vsy) -- the depth texture
    glCopyToTexture(raincanvastex, 0, 0, 0, 0, vsx, vsy) -- the original screen image
    Spring.Echo("Preparing Texture end")
end

local function updateUniforms()
    cam[1], cam[2], cam[3] = Spring.GetCameraPosition()
    diffTime = Spring.DiffTimers(lastFrametime, startTimer) - pausedTime

    glUniform(shaderTimeLoc, diffTime )
    glUniform(shaderCamPosLoc,  cam[1], cam[2], cam[3])
    glUniform(shaderRainDensityLoc, rainDensity )
    glUniform(shaderMaxLightSrcLoc, math.floor(maxLightSources))

    for i=1,maxLightSources do
      glUniform( shaderLightSourcescLoc[i] ,0.0, 0.0, 0.0 )
    end
end

local function renderToTextureFunc()
    -- render a full screen quad
    glTexture(0, depthTexture)
    glTexture(0, false)
    glTexture(1,":l:luaui/images/rgbnoise.png");
    glTexture(1, false)
    gl.TexRect(-1, -1, 1, 1, 0, 0, 1, 1)
end

local function DrawRain()
   if boolRainActive == false then return  end

    local _, _, isPaused = Spring.GetGameSpeed()
    if isPaused then
       pausedTime = pausedTime + Spring.DiffTimers(Spring.GetTimer(), lastFrametime)
       return
    end

    lastFrametime = Spring.GetTimer()

    prepareTextures()
    upateUniforms()

    DrawRain()

    local osClock = os.clock()
    local timePassed = osClock - prevOsClock
    prevOsClock = osClock        
    glRenderToTexture(raincanvastex, renderToTextureFunc);
    cleanUp()    
end

function widget:DrawScreen()
    glPushMatrix()
    glBlending(false)
    DrawRain()
    glBlending(true)
    glPopMatrix()
end


function widget:DrawScreenEffects()
    glBlending(GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA) -- in theory not needed but sometimes evil widgets disable it w/o reenabling it
    glTexture(raincanvasetex);
    gl.TexRect(0,0,vsx,vsy,0,0,1,1);
    glTexture(false);
end

local function cleanUp()
        glTexture(0, false)
        glTexture(1, false)
        glTexture(2, false)
        glTexture(3, false)
        
        glResetState()
        glUseShader(0)
end

function widget:DrawScreenEffects()

    if boolRainActive == false then return  end

    local _, _, isPaused = Spring.GetGameSpeed()
    if isPaused then
       pausedTime = pausedTime + Spring.DiffTimers(Spring.GetTimer(), lastFrametime)
       return
    end

    lastFrametime = Spring.GetTimer()

    DrawRain()

    local osClock = os.clock()
    local timePassed = osClock - prevOsClock
    prevOsClock = osClock        
    cleanUp()    
end

function widget:Initialize()
    init()
    vsx, vsy = widgetHandler:GetViewSizes()
    widget:ViewResize(vsx, vsy)
    startOsClock = os.clock()
end

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
