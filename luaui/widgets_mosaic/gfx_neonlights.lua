function widget:GetInfo()
    return {
        name = "Neonlights",
        desc = "Produces a topdown fbo neonlightmap of the city in cameraview via radiance cascade",
        author = "Picasso",
        date = "2023",
        license = "GNU GPL, v2 or later",
        layer = -9,
        enabled = true, --  loaded by default?
        hidden = false
    }
end

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

-- > debugEchoT(
local boolDebugActive = false  --TODODO
local neonLightShader = nil

--------------------------------------------------------------------------------
--------------------------Configuration Components -----------------------------
local shaderFilePath        = "luaui/widgets_mosaic/shaders/"

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
local pausedTime = 0
local lastFrametime = Spring.GetTimer()
local mapDepthTex = nil
local modelDepthTex = nil

local screentex = nil
local normaltex = nil
local normalunittex = nil
local neonLightcanvastex = nil
local depthCopyTex= nil
local startOsClock

local cityCenterLoc

local shaderLightSources = {} --TODO Needs a transfer function from worldspace to screenspace / Scrap the whole idea?
local canvasneonLightTextureID = 0
local vsx, vsy, vpx, vpy = Spring.GetViewGeometry()

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
local screentexIndex        = 2
local normaltexIndex        = 3
local normalunittexIndex    = 4
local neonLightcanvastexIndex = 5


local dephtCopyTexIndex     = 6
local emitmaptexIndex       = 7
local emitunittexIndex      = 8
local eyePos = {spGetCameraPosition()}
local eyeDir = {spGetCameraDirection()}


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

    neonLightcanvastex =
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
    errorOutIfNotInitialized(neonLightcanvastex, "neonLightcanvastex not existing")
    Spring.Echo("neonLightcanvastexIndex:".. neonLightcanvastex)
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
    Spring.Echo("gfx_neonLight:Initialize")
    -- abort if not enabled
    widgetHandler:UpdateCallIn("Update")  
    errorOutIfNotInitialized(glCreateShader, "no shader support")

    --https://www.shadertoy.com/view/wd2GDG inspiration
    local fragmentShader =  VFS.LoadFile(shaderFilePath .. "neonLightShader.frag") 
    local vertexShader = VFS.LoadFile(shaderFilePath .. "neonLightShader.vert") 
    
    local uniformInt = {
        modelDepthTex = modelDepthTexIndex,
        mapDepthTex = mapDepthTexIndex,
        screentex = screentexIndex,
        normaltex = normaltexIndex,
        normalunittex= normalunittexIndex,      
        neonLightcanvastex = neonLightcanvastexIndex,
        dephtCopyTex = dephtCopyTexIndex
    }

    neonLightShader =
        glCreateShader(
        {
            fragment = fragmentShader,
            vertex = vertexShader,
            uniformInt = uniformInt,
            uniform = {
                timePercent = 0,
                neonLightPercent= 0,
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

    if (neonLightShader == nil) then
        Spring.Echo("gfx_neonLight:Initialize] particle shader compilation failed")
        Spring.Echo(glGetShaderLog())
        widgetHandler:RemoveWidget(self)
        return
    else
        Spring.Echo("gfx_neonLight: Shader compiled: ")
    end

    timePercentLoc                  = glGetUniformLocation(neonLightShader, "timePercent")
    neonLightPercentLoc                  = glGetUniformLocation(neonLightShader, "neonLightPercent")
    uniformViewPortSize             = glGetUniformLocation(neonLightShader, "viewPortSize")
    cityCenterLoc                   = glGetUniformLocation(neonLightShader, "cityCenter")
    uniformTime                     = glGetUniformLocation(neonLightShader, "time")
    uniformEyePos                   = glGetUniformLocation(neonLightShader, "eyePos")
    unformEyeDir                    = glGetUniformLocation(neonLightShader, "eyeDir")

    uniformViewPrjInv               = glGetUniformLocation(neonLightShader, 'viewProjectionInv')
    uniformViewInv                  = glGetUniformLocation(neonLightShader, 'viewInv')
    uniformViewMatrix               = glGetUniformLocation(neonLightShader, 'viewMatrix')
    uniformViewProjection           = glGetUniformLocation(neonLightShader, 'viewProjection')
    uniformProjection               = glGetUniformLocation(neonLightShader, 'projection')
    uniformSunColor                 = glGetUniformLocation(neonLightShader, 'sunCol')
    uniformSkyColor                 = glGetUniformLocation(neonLightShader, 'skyCol')
    uniformSunPos                   = glGetUniformLocation(neonLightShader, 'sunPos')
    Spring.Echo("gfx_neonLight:Initialize ended")
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


local function getDayTime()
    local morningOffset = (DAYLENGTH / 2)
    local Frame = (Spring.GetGameFrame() + morningOffset) % DAYLENGTH
    local percent = Frame / DAYLENGTH
    local hours = math.floor((Frame / DAYLENGTH) * 24)
    local minutes = math.ceil((((Frame / DAYLENGTH) * 24) - hours) * 60)
    local seconds = 60 - ((24 * 60 * 60 - (hours * 60 * 60) - (minutes * 60)) % 60)
    return hours, minutes, seconds, percent
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


local accumulatedDT = 0

function widget:Update(dt)  
    accumulatedDT = accumulatedDT + dt 
    local _,_,_,percent = getDayTime()
    neonLightPercent = percent     
end

function widget:Shutdown()
    if glDeleteTexture then
        glDeleteTexture(depthtex or "")
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
        screentex = 2,
        normaltex = 3,
        normalunittex= 4,
        raincanvastex = 5,

]]

local function cleanUp()    
    glResetState()
    glUseShader(0)
    for i=0, dephtCopyTexIndex do
        gl.Texture(i, false)
    end
    glBlending(true)
end

local function prepareTextures()
    glBlending(false)

    glTexture(modelDepthTexIndex,"$model_gbuffer_zvaltex")
    glTexture(mapDepthTexIndex,"$map_gbuffer_zvaltex")
    glTexture(dephtCopyTexIndex, depthCopyTex)
    glTexture(screentexIndex, screentex)
    glTexture(normaltexIndex,"$map_gbuffer_normtex")
    glTexture(normalunittexIndex,"$model_gbuffer_normtex")

    glCopyToTexture(screentex, 0, 0, 0, 0, vsx, vsy)
    glCopyToTexture(depthCopyTex, 0, 0, vpx, vpy, vsx, vsy)

end

local function DrawNeonLightsToFbo()
    local _, _, isPaused = Spring.GetGameSpeed()
    if isPaused then
       local timerNow = Spring.GetTimer()
       pausedTime = pausedTime + Spring.DiffTimers(timerNow, lastFrametime)       
       return
    end

    lastFrametime = Spring.GetTimer()
    prepareTextures()
    glUseShader(neonLightShader)
    updateUniforms()

    glRenderToTexture(neonLightcanvastex, renderToTextureFunc);
    local osClock = os.clock()
    local timePassed = osClock - prevOsClock
    prevOsClock = osClock  
    cleanUp()    
end

--only used for debug purposes
function widget:DrawScreenEffects()
    glBlending(GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA) 
    glTexture(0, neonLightcanvastex)
    glTexRect(0, vsy, vsx, 0)
    glTexture(0, false);
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
    glBlending(false)
    DrawNeonLightsToFbo()
    glBlending(true)

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
    eyeDir = {spGetCameraDirection()}     
end
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
