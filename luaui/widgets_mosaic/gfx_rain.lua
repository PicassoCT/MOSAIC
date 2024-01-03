function widget:GetInfo()
    return {
        name = "Raymarched Rain",
        desc = "Lets it rain",
        author = "Picasso",
        date = "2023",
        license = "GNU GPL, v2 or later",
        layer = 20,
        enabled = true, --  loaded by default?
        hidden = true
    }
end

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

-- > debugEchoT(
local boolDebugActive = true
local rainShader = nil

--------------------------------------------------------------------------------
--------------------------Configuration Components -----------------------------
local shaderFilePath = "luaui/widgets_mosaic/shaders/"
local noisetextureFilePath = ":l:luaui/images/rgbnoise.png"
local DAYLENGTH = 28800
local rainDensity = 0.5

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
local glClear                = gl.Clear
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
local glResetState           = gl.ResetState
local glTexCoord             = gl.TexCoord
local glTexture              = gl.Texture
local glTexRect              = gl.TexRect
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
local shaderTimeLoc
local shaderRainDensityLoc
local viewPortSizeLoc
local uniformEyePos
local shaderMaxLightSrcLoc
local shaderLightSourcescLoc 
local boolRainyArea = false
local maxLightSources = 0
local shaderLightSources = {}
local canvasRainTextureID = 0
local vsx, vsy = Spring.GetViewGeometry()
local cam = {}
local prevOsClock = os.clock()
local startTimer = Spring.GetTimer()
local diffTime = 0
local uniformViewPrjInv
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
local function errorOutIfNotInitialized(value, name)
    if value == nil then
        Spring.Echo("No "..name.." - aborting")
        widgetHandler:RemoveWidget(self)
    end
end

function widget:ViewResize()
    vsx, vsy = gl.GetViewSizes()

    if (depthtex ~= nil ) then
        glDeleteTexture(depthtex)
    end
    
    if (raincanvastex ~= nil ) then
        glDeleteTexture(raincanvastex)
    end

     if (screentex ~= nil  ) then
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
        min_filter = GL.LINEAR, 
        mag_filter = GL.LINEAR,
        wrap_s = GL.CLAMP_TO_EDGE, 
        wrap_t = GL.CLAMP_TO_EDGE,
        }
    )
    errorOutIfNotInitialized(screentex, "screentex not existing")       
    widgetHandler:UpdateCallIn("DrawScreenEffects")  
end
widget:ViewResize()

function widget:Update()
    widgetHandler:RemoveWidgetCallIn("Update", self)
    startTimer = Spring.GetTimer()
end

local function init()
    Spring.Echo("gfx_rain:Initialize")
    -- abort if not enabled

    errorOutIfNotInitialized(glCreateShader, "no shader support")

    --https://www.shadertoy.com/view/wd2GDG inspiration
    local fragmentShader =  VFS.LoadFile(shaderFilePath .. "rainShader.frag") 
    local vertexShader = VFS.LoadFile(shaderFilePath .. "rainShader.vert") 
    --local fragmentShaderAddSource = VFS.LoadFile(shaderFilePath .. "rainShaderReflectionSource.c") 
	--fragmentShader = string.replace(fragmentShader, "REFLECTIONMARCH", fragmentShaderAddSource)
    Spring.Echo("FragmentShader".. fragmentShader)
    Spring.Echo("VertexShader".. vertexShader)
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
        Spring.Echo("gfx_rain: Shader compiled: ")
    end

    viewPortSizeLoc                 = glGetUniformLocation(rainShader, "viewPortSize")
    shaderTimeLoc                   = glGetUniformLocation(rainShader, "time")
    shaderRainDensityLoc            = glGetUniformLocation(rainShader, "rainDensity")
    uniformEyePos                   = glGetUniformLocation(rainShader, "eyePos")
    shaderMaxLightSrcLoc            = glGetUniformLocation(rainShader, "maxLightSources")
    shaderLightSourcescLoc          = glGetUniformLocation(rainShader, "lightSources")
    uniformViewPrjInv               = glGetUniformLocation(rainShader, 'viewProjectionInv')
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
    if boolDebugActive then boolRainActive = true; return end

    boolRainActive = isRaining()
end

function widget:Shutdown()
    if glDeleteTexture then
        glDeleteTexture(depthtex or "")
        glDeleteTexture(noisetex or "")
        glDeleteTexture(screentex or "")
        glDeleteTexture(raincanvastex or "")
    end

    if rainShader then
        gl.DeleteShader(rainShader)
    end
end
local function prepareTextures()
    glCopyToTexture(screentex, 0, 0, 0, 0, vsx, vsy)
    glCopyToTexture(depthtex, 0, 0, 0, 0, vsx, vsy) -- the depth texture
end

local function updateUniforms()
    diffTime = Spring.DiffTimers(lastFrametime, startTimer) 
    diffTime = diffTime - pausedTime

    glUniform(viewPortSizeLoc, vsx, vsy )
    glUniform(shaderTimeLoc, diffTime )
    glUniform(uniformEyePos,  Spring.GetCameraPosition())
    glUniform(shaderRainDensityLoc, rainDensity )
    glUniform(shaderMaxLightSrcLoc, math.floor(maxLightSources))
    glUniformMatrix(uniformViewPrjInv,  "viewprojectioninverse")
    for i=1,maxLightSources do
      glUniform(shaderLightSourcescLoc[i] ,0.0, 0.0, 0.0)
    end
end

local function renderToTextureFunc()
    -- render a full screen quad
    --glClear (GL.COLOR_BUFFER_BIT,0,0,0,0 )
    glTexture(0, depthtex)
    glTexture(1, noisetextureFilePath);
    glTexture(2, screentex);
    glTexRect(-1, -1, 1, 1, 0, 0, 1, 1)
end

local function cleanUp()    
    glResetState()
    glUseShader(0)
    glTexture(0, false)
    glTexture(1, false)
    glTexture(2, false)
end

local function DrawRain()
   if boolRainActive == false then return  end

    local _, _, isPaused = Spring.GetGameSpeed()
    if isPaused then
       local timerNow = Spring.GetTimer()
       pausedTime = pausedTime + Spring.DiffTimers(now, lastFrametime)
       return
    end

    lastFrametime = Spring.GetTimer()

    prepareTextures()

    glUseShader(rainShader)
    updateUniforms()
    local osClock = os.clock()
    local timePassed = osClock - prevOsClock
    prevOsClock = osClock      
--[[    Spring.Echo("ReDrawing the rain")  --]]
    glRenderToTexture(raincanvastex, renderToTextureFunc);
    cleanUp()    
end

function widget:DrawScreenEffects()

    glBlending(GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA) 
    --glBlending(GL_ONE, GL_ONE_MINUS_SRC_ALPHA)
    glTexture(raincanvastex);
    glTexRect(0, vsy, vsx, 0)
    glTexture(false);
end


function widget:Initialize()
    if (not gl.RenderToTexture) then --super bad graphic driver
        return
    end

    lastFrametime = Spring.GetTimer()
    startOsClock = os.clock()
    init()
    widget:ViewResize()

end

function widget:DrawScreen()
    if boolRainActive == false then
        Spring.Echo("Rain not active")
        return  
    end

    local _, _, isPaused = Spring.GetGameSpeed()
    if isPaused then
       local currentTime = Spring.GetTimer() 
       pausedTime = pausedTime + Spring.DiffTimers(currentTime, lastFrametime)
       Spring.Echo("Paused")
       return
    end

    lastFrametime = Spring.GetTimer()

    glPushMatrix()
    glBlending(false)
    DrawRain()
    glBlending(true)
    glPopMatrix()

    local osClock = os.clock()
    local timePassed = osClock - prevOsClock
    prevOsClock = osClock        
end
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
