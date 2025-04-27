function widget:GetInfo()
    return {
        name = "Raymarched Rain",
        desc = "Lets it rain",
        author = "Picasso",
        date = "2023",
        license = "GNU GPL, v2 or later",
        layer = -13,
        enabled = true, --  loaded by default?
        hidden = false
    }
end

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

-- > debugEchoT(
local boolDebugActive = false --TODODO
local rainShader = nil

--------------------------------------------------------------------------------
--------------------------Configuration Components -----------------------------
local shaderFilePath        = "luaui/widgets_mosaic/shaders/"
local noisetextureFilePath  = ":l:luaui/images/noisetextures/rgbnoise.png"
local DAYLENGTH             = 28800

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
local spGetCameraDirection   = Spring.GetCameraDirection
local eyex,eyey,eyez         = 0,0,0


--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
-- Variables
local boolRainActive = false
local pausedTime = 0
local lastFrametime = Spring.GetTimer()
local mapDepthTex = nil
local modelDepthTex = nil
local noisetex = nil
local screentex = nil
local normaltex = nil
local normalunittex = nil
local raincanvastex = nil
local depthCopyTex= nil
local startOsClock

local shaderMaxLightSrcLoc
local shaderLightSourcescLoc  = {}
local cityCenterLoc
local boolRainyArea = nil
local maxLightSources = 20
local rainChangeIntervalSeconds = 90
local lightSourceIndex = 0
local shaderLightSources = {} --TODO Needs a transfer function from worldspace to screenspace / Scrap the whole idea?
local canvasRainTextureID = 0
local vsx, vsy, vpx, vpy = Spring.GetViewGeometry()
local rainPicPath                   = ":i256,256:luaui/images/snow/rain5.png"
local rainDroplettextureFilePath    = ":i256,256:luaui/images/snow/rain_droplets.png"
local prevOsClock = os.clock()
local startTimer = Spring.GetTimer()
local diffTime = 0
local uniformViewPrjInv
local uniformViewInv
local uniformViewProjection
local GL_DEPTH_BITS = 0x0D56
local GL_DEPTH_COMPONENT   = 0x1902
local GL_DEPTH_COMPONENT16 = 0x81A5
local GL_DEPTH_COMPONENT24 = 0x81A6
local GL_DEPTH_COMPONENT32 = 0x81A7

local GL_RGB8_SNORM = 0x8F96
local GL_RGBA8 = 0x8058
local GL_FUNC_ADD = 0x8006
local GL_FUNC_REVERSE_SUBTRACT = 0x800B

local timePercentLoc
local rainPercentLoc
local rainPercent = 0.0
local timePercent = 0
local hours = 12
local minutes = 0
local seconds = 0

local sunCol = {0,0,0}
local skyCol = {0,0,0}
local sunPos = {0.0,0.0, 1.0}

local uniformSunColor
local uniformSkyColor
local uniformSunPos
local uniformEyePos
local unformEyeDirection
local uniformProjection
local uniformTime
local uniformViewPortSize
local modelDepthTexIndex    = 0
local mapDepthTexIndex      = 1
local rainDroplettTexIndex  = 2
local screentexIndex        = 3
local normaltexIndex        = 4
local normalunittexIndex    = 5
local raincanvastexIndex    = 6
local noisetexIndex         = 7
local raintexIndex          = 8
local dephtCopyTexIndex     = 9
local emitmaptexIndex       = 10
local emitunittexIndex      = 11
local eyePos = {spGetCameraPosition()}
local eyeDir = {spGetCameraDirection()}
--TODO: Rain is - highly Directional and reflects only from the ground
-- directional- should instead reflect in all camera directions
-- Debugstep: render only reflection, debug till it works for all diretions

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

  --[[  if (modelDepthTex ~= nil ) then
        glDeleteTexture(modelDepthTex)
    end

    if (mapDepthTex ~= nil ) then
        glDeleteTexture(mapDepthTex)
    end--]]

    if (screentex ~= nil  ) then
        glDeleteTexture(screentex)
    end     

    if (depthCopyTex ~= nil  ) then
        glDeleteTexture(depthCopyTex)
    end   

    depthCopyTex =   gl.CreateTexture(vsx,vsy, {
        target = GL_TEXTURE_2D,
        format = GL_DEPTH_COMPONENT,
        min_filter = GL.NEAREST,
        mag_filter = GL.NEAREST,
    })
    errorOutIfNotInitialized(depthCopyTex, "depthCopyTex not existing")    

    screentex =
        glCreateTexture(
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
    Spring.Echo("RaincanvastexIndex:".. raincanvastex)
    local commonTexOpts = {
        target = GL_TEXTURE_2D,
        border = false,
        min_filter = GL.NEAREST,
        mag_filter = GL.NEAREST,

        wrap_s = GL.CLAMP_TO_EDGE,
        wrap_t = GL.CLAMP_TO_EDGE,
    }
    commonTexOpts.format = GL_RGB8_SNORM

    normaltex = glCreateTexture(vsx, vsy, commonTexOpts)
    errorOutIfNotInitialized(normaltex, "normaltex not existing")   
    
    normalunittex = glCreateTexture(vsx, vsy, commonTexOpts)
    errorOutIfNotInitialized(normalunittex, "normalunittex not existing")   

    widgetHandler:UpdateCallIn("DrawScreenEffects")
end

widget:ViewResize()

local function init()
    startTimer = Spring.GetTimer()
    Spring.Echo("gfx_rain:Initialize")
    -- abort if not enabled
    widgetHandler:UpdateCallIn("Update")  
    errorOutIfNotInitialized(glCreateShader, "no shader support")

    --https://www.shadertoy.com/view/wd2GDG inspiration
    local fragmentShader =  VFS.LoadFile(shaderFilePath .. "rainShader.frag") 
    local vertexShader = VFS.LoadFile(shaderFilePath .. "rainShader.vert") 
    --local fragmentShaderAddSource = VFS.LoadFile(shaderFilePath .. "rainShaderReflectionSource.c") 
	--fragmentShader = string.replace(fragmentShader, "REFLECTIONMARCH", fragmentShaderAddSource)
    --Spring.Echo("FragmentShader".. fragmentShader)
    --Spring.Echo("VertexShader".. vertexShader)
    local uniformInt = {
        modelDepthTex = modelDepthTexIndex,
        mapDepthTex = mapDepthTexIndex,
        rainDroplettTex = rainDroplettTexIndex,
        screentex = screentexIndex,
        normaltex = normaltexIndex,
        normalunittex= normalunittexIndex,      
        raincanvastex = raincanvastexIndex,
        noisetex = noisetexIndex,
        raintex = raintexIndex,
        dephtCopyTex = dephtCopyTexIndex
    }

    rainShader =
        glCreateShader(
        {
            fragment = fragmentShader,
            vertex = vertexShader,
            uniformInt = uniformInt,
            uniform = {
                timePercent = 0,
                rainPercent= 0,
                time = diffTime,
                scale = 0,
            },
            uniformFloat = {
                viewPortSize = {vsx, vsy},
                cityCenter  = {0,0,0},
                sunCol    = {0,0,0},
                skyCol    = {0,0,0},
                sunPos      = {0,0,1},
                eyePos = {0, 0, 0},
                eyeDir = {0, 0, 0}
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

    timePercentLoc                  = glGetUniformLocation(rainShader, "timePercent")
    rainPercentLoc                  = glGetUniformLocation(rainShader, "rainPercent")
    uniformViewPortSize             = glGetUniformLocation(rainShader, "viewPortSize")
    cityCenterLoc                   = glGetUniformLocation(rainShader, "cityCenter")
    uniformTime                     = glGetUniformLocation(rainShader, "time")
    uniformEyePos                   = glGetUniformLocation(rainShader, "eyePos")
    unformEyeDir                    = glGetUniformLocation(rainShader, "eyeDir")

    uniformViewPrjInv               = glGetUniformLocation(rainShader, 'viewProjectionInv')
    uniformViewInv                  = glGetUniformLocation(rainShader, 'viewInv')
    uniformViewMatrix               = glGetUniformLocation(rainShader, 'viewMatrix')
    uniformViewProjection           = glGetUniformLocation(rainShader, 'viewProjection')
    uniformProjection               = glGetUniformLocation(rainShader, 'projection')
    uniformSunColor                 = glGetUniformLocation(rainShader, 'sunCol')
    uniformSkyColor                 = glGetUniformLocation(rainShader, 'skyCol')
    uniformSunPos                   = glGetUniformLocation(rainShader, 'sunPos')
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
local boolIsMapNameOverride = false
local function isMapNameRainyOverride(mapName)
    local map = string.lower(mapName)
    local ManualBuildingPlacement = {}        
        ManualBuildingPlacement[1] = "mosaic_lastdayofdubai_v"

      for i=1, #ManualBuildingPlacement do
        if string.find(map, ManualBuildingPlacement[i] ) then return true end
    end
    return false

end

local function isRainyArea()
    return getDetermenisticHash() % 2 == 0 or boolIsMapNameOverride 
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
        Spring.Echo("Is rainy area:"..tostring(boolRainyArea))
    end

    if boolRainyArea == false then
        return false
    end

    local gameFrames = Spring.GetGameFrame()
    local dayNr = gameFrames / DAYLENGTH

    return dayNr % 3 < 1.0 and (hours > 18 or hours < 7)
end

local function split(self, delimiter)
  local result = { }
  local from  = 1

  local delim_from, delim_to = string.find( self, delimiter, from  )
  while delim_from do
    table.insert( result, string.sub( self, from , delim_from-1 ) )
    from  = delim_to + 1
    delim_from, delim_to = string.find( self, delimiter, from  )
  end
  table.insert( result, string.sub( self, from  ) )
  return result
end
local tresholdCrossValueStore = 0.0
local function onTresholdCrossWriteToMapTexture()
    if math.abs(tresholdCrossValueStore - rainPercent) > 0.1 then
        tresholdCrossValueStore = rainPercent

        --glCopyToTexture("$map_reflection", 0, 0, vpx, vpy, vsx, vsy)
    end
end

local accumulatedDT = 0
local lastActiveRainSoundDt = 0

function widget:Update(dt)  
    accumulatedDT = accumulatedDT + dt 
    if boolDebugActive then  
        rainPercent = 1.0
        return 
    end
    if rainPercent > 0 and accumulatedDT - lastActiveRainSoundDt > 15.0 then
        Spring.PlaySoundFile("LuaUi/sounds/weather/rain.ogg", math.min(1.0, 2.0*rainPercent), 'ui')
        lastActiveRainSoundDt= accumulatedDT
    end

    if isRaining() == true   then--isRaining() then
        rainPercent = math.min(1.0, rainPercent + 0.0002)
        --Spring.Echo("Rainvalue:".. rainPercent)
    else
        rainPercent = math.max(0.0, rainPercent - 0.0001)
        --Spring.Echo("Rainvalue:".. rainPercent)
    end
end

function widget:Shutdown()
    if glDeleteTexture then
        glDeleteTexture(depthtex or "")
        glDeleteTexture(rainDroplettex or "")
        glDeleteTexture(screentex or "")
    end

    if rainShader then
        gl.DeleteShader(rainShader)
    end
end

local function updateUniforms()
    onTresholdCrossWriteToMapTexture()
    diffTime = Spring.DiffTimers(lastFrametime, startTimer) 
    diffTime = diffTime - pausedTime
    --Spring.Echo("Time passed:"..diffTime)
    glUniform(rainPercentLoc, rainPercent)
    glUniform(timePercentLoc, timePercent)
    glUniform(uniformViewPortSize, vsx, vsy )
    glUniform(uniformTime, diffTime )
    local eyePos = {spGetCameraPosition()}
    glUniform(uniformEyePos,eyePos[1],eyePos[2], eyePos[3] )
    local eyeDir = {spGetCameraDirection()}
    glUniform(unformEyeDir,eyeDir[1], eyeDir[2], eyeDir[3] )


    glUniform(uniformSunColor, sunCol[1], sunCol[2], sunCol[3]);
    glUniform(uniformSkyColor, skyCol[1], skyCol[2], skyCol[3]);
    glUniform(uniformSunPos, sunPos[1], sunPos[2], sunPos[3]);

    glUniformMatrix(uniformViewPrjInv     , "viewprojectioninverse")
    glUniformMatrix(uniformViewInv        , "viewinverse")
    glUniformMatrix(uniformViewProjection , "viewprojection")
    glUniformMatrix(uniformViewMatrix     , "view")
    glUniformMatrix(uniformProjection     , "projection")

end

local function renderToTextureFunc()
    glTexRect(-1, -1, 1, 1, 0, 0, 1, 1)
end
--[[
        modelDepthTex = 0,
        mapDepthTex = 1,
        rainDroplettex = 2,
        screentex = 3,
        normaltex = 4,
        normalunittex= 5,
        raincanvastex = 6,
        noisetex = 7,
        raintex = 8s
]]

local function cleanUp()    
    glResetState()
    glUseShader(0)
    --for i=0, dephtCopyTexIndex do
    --    gl.Texture(i, false)
    --end
    glBlending(true)
end

local function prepareTextures()
    glBlending(false)

    glTexture(modelDepthTexIndex,"$model_gbuffer_zvaltex")
    glTexture(mapDepthTexIndex,"$map_gbuffer_zvaltex")
    glTexture(rainDroplettTexIndex, rainDroplettextureFilePath);
    glCopyToTexture(screentex, 0, 0, 0, 0, vsx, vsy)
    glTexture(screentexIndex, screentex)
    glTexture(normaltexIndex,"$map_gbuffer_normtex")
    glTexture(normalunittexIndex,"$model_gbuffer_normtex")
    glTexture(noisetexIndex, noisetextureFilePath);
    glTexture(raintexIndex, rainPicPath)
    glCopyToTexture(depthCopyTex, 0, 0, vpx, vpy, vsx, vsy)
    glTexture(dephtCopyTexIndex, depthCopyTex)
end

local function DrawRain()
    local _, _, isPaused = Spring.GetGameSpeed()
    if isPaused then
       local timerNow = Spring.GetTimer()
       pausedTime = pausedTime + Spring.DiffTimers(timerNow, lastFrametime)       
       return
    end

    lastFrametime = Spring.GetTimer()
    prepareTextures()
    glUseShader(rainShader)
    updateUniforms()

    glRenderToTexture(raincanvastex, renderToTextureFunc);
    local osClock = os.clock()
    local timePassed = osClock - prevOsClock
    prevOsClock = osClock  
    cleanUp()    
end

function widget:DrawScreenEffects()
    glBlending(GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA) 
    glTexture(0, raincanvastex)
    glTexRect(0, vsy, vsx, 0)
    glTexture(0, false);
end

function widget:Initialize()
    if (not gl.RenderToTexture) then --super bad graphic driver
        return
    end
    boolIsMapNameOverride = isMapNameRainyOverride(Game.mapName)
    if not isRainyArea() then
       Spring.Echo("Is not a rainy area:"..tostring(boolRainyArea))
        widgetHandler:RemoveWidget(self)
    end
    lastFrametime = Spring.GetTimer()
    startOsClock = os.clock()
    init()
    widget:ViewResize()

end

local function cameraIsUnchanged()
    local newCamPos = {spGetCameraPosition()}
    local newCamDir = {spGetCameraDirection()}
        if newCamPos ~= eyePos then return false end

        if  newCamDir ~= eyeDir then return false end
        return true
    end

function widget:DrawWorld()

    local _, _, isPaused = Spring.GetGameSpeed()
    if isPaused and cameraIsUnchanged()then
       local currentTime = Spring.GetTimer() 
       pausedTime = pausedTime + Spring.DiffTimers(currentTime, lastFrametime)
       return
    end

    lastFrametime = Spring.GetTimer()
    --glPushMatrix()
    glBlending(false)
    DrawRain()
    glBlending(true)
    --glPopMatrix()

    local osClock = os.clock()
    local timePassed = osClock - prevOsClock
    prevOsClock = osClock        
end


function widget:GameFrame()
    hours,minutes,seconds, timePercent = getDayTime()
    sunCol = {gl.GetAtmosphere("sunColor")}
    skyCol = {gl.GetAtmosphere("skyColor")}
    sunPos = {gl.GetSun('pos')}

    eyePos = {spGetCameraPosition()}
    eyeDir =  {spGetCameraDirection()} 
    --Spring.Echo("Time:"..hours..":"..minutes..":"..seconds)
    --Spring.Echo("Sunpos:"..sunPos[1]..":"..sunPos[2]..":"..sunPos[3])
    --Spring.Echo("Sunposition:", sunPos[1], sunPos[2], sunPos[3]) 
end
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
