function widget:GetInfo()
    return {
        name = "Raymarched Rain",
        desc = "Lets it rain",
        author = "Picasso",
        date = "2023",
        license = "GNU GPL, v2 or later",
        layer = 1,
        enabled = false, --  loaded by default?
        hidden = false
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
local depthtex = nil
local noisetex = nil
local screentex = nil
local normaltex = nil
local normalunittex = nil
local raincanvastex = nil
local startOsClock

local shaderMaxLightSrcLoc
local shaderLightSourcescLoc  = {}
local cityCenterLoc
local boolRainyArea = false
local maxLightSources = 20
local lightSourceIndex = 0
local shaderLightSources = {} --TODO Needs a transfer function from worldspace to screenspace / Scrap the whole idea?
local canvasRainTextureID = 0
local vsx, vsy = Spring.GetViewGeometry()
local rainPicPath     = ":i256,256:luaui/images/snow/rain5.png"
local cam = {}
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

local percentTime
local timePercentLoc
local timePercent = 0
local sunDir = {0,0,0}
local sunCol = {0,0,0}
local skyCol = {0,0,0}
local uniformSundir
local uniformSunColor
local uniformSkyColor
local uniformEyePos
local uniformTime
local uniformRainDensity
local uniformViewPortSize

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


     if (screentex ~= nil  ) then
        glDeleteTexture(screentex)
    end   

    if (normaltex ~= nil  ) then
        glDeleteTexture(normaltex)
    end
   if (normalunittex ~= nil  ) then
        glDeleteTexture(normalunittex)
    end

    depthtex =
        glCreateTexture(
            vsx,
            vsy,
        {
            border = false,
            format = GL_DEPTH_COMPONENT32,
            min_filter = GL.NEAREST,
            mag_filter = GL.NEAREST
        }
    )
    errorOutIfNotInitialized(depthtex, "depthtex not existing")    

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
    --Spring.Echo("FragmentShader".. fragmentShader)
    --Spring.Echo("VertexShader".. vertexShader)
    local uniformInt = {
        depthtex = 0,
        noisetex = 1,
        screentex = 2,
        normaltex = 3,
        normalunittex= 4,
        raincanvastex = 5,
        skyboxtex = 6,
        raintex = 7
    }

    rainShader =
        glCreateShader(
        {
            fragment = fragmentShader,
            vertex = vertexShader,
            uniformInt = uniformInt,
            uniform = {
                timePercent = 0,
                time = diffTime,
                scale = 0,
                eyePos = {0, 0, 0}
            },
            uniformFloat = {
                viewPortSize = {vsx, vsy},
                cityCenter  = {0,0,0},
                sundir      = {0,0,0},
                suncolor    = {0,0,0},
                skycolor    = {0,0,0},
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
    uniformViewPortSize             = glGetUniformLocation(rainShader, "viewPortSize")
    cityCenterLoc                   = glGetUniformLocation(rainShader, "cityCenter")
    uniformTime                     = glGetUniformLocation(rainShader, "time")
    uniformRainDensity              = glGetUniformLocation(rainShader, "rainDensity")
    uniformEyePos                   = glGetUniformLocation(rainShader, "eyePos")
    shaderMaxLightSrcLoc            = glGetUniformLocation(rainShader, "maxLightSources")

    uniformViewPrjInv               = glGetUniformLocation(rainShader, 'viewProjectionInv')
    uniformViewInv                  = glGetUniformLocation(rainShader, 'viewInv')
    uniformViewProjection           = glGetUniformLocation(rainShader, 'viewProjection')
    uniformSundir                   = glGetUniformLocation(rainShader, 'sundir')
    uniformSunColor                 = glGetUniformLocation(rainShader, 'suncolor')
    uniformSkyColor                 = glGetUniformLocation(rainShader, 'skycolor')
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

    local hours,_,_, timePercent = getDayTime()
    percentTime = timePercent
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

function widget:Update(dt)   
    if boolDebugActive then boolRainActive = true; return end
    boolRainActive = isRaining()
end

function widget:Shutdown()
    if glDeleteTexture then
        glDeleteTexture(depthtex or "")
        glDeleteTexture(noisetex or "")
        glDeleteTexture(screentex or "")
    end

    if rainShader then
        gl.DeleteShader(rainShader)
    end
end
--[[
{
vec4  position + distance ?? TODO: distance is a factor of physics, as in strenght of light source * log of distnace?
vec4  color + strength.a
}
]]
local lightIDCounter = 0 
local function addLightSources(positionWorld, color, strength )
    indexPosition = lightSourceIndex 
    indexColor = indexPosition +1
    lightIDCounter= lightIDCounter +1
    shaderLightSourcescLoc[indexPosition] = {positionWorld[0], positionWorld[1], positionWorld[2], strength}
    shaderLightSourcescLoc[indexColor] = {color[0], color[1], color[2], color[3], lightIDCounter}
    lightSourceIndex = lightSourceIndex + 2
    return lightIDCounter
end

local function resetLightSources()
    lightSourceIndex = 0
end

local function removeLightSources(id)
    for i=1,maxLightSources-2, 2 do
        if  shaderLightSourcescLoc[i + 1][4] == id then
            --compress
            for start =i, maxLightSources, 2 do
                shaderLightSourcescLoc[i] = shaderLightSourcescLoc[i+2]
                shaderLightSourcescLoc[i+ 1] = shaderLightSourcescLoc[i+2 +1]
            end
        end
    end
end

local function updateUniforms()
    diffTime = Spring.DiffTimers(lastFrametime, startTimer) 
    diffTime = diffTime - pausedTime
    --Spring.Echo("Time passed:"..diffTime)
    glUniform(timePercentLoc, timePercent)
    glUniform(uniformViewPortSize, vsx, vsy )
    glUniform(uniformTime, diffTime )
    glUniform(uniformEyePos, spGetCameraPosition())
    glUniform(uniformRainDensity, rainDensity )
    glUniform(shaderMaxLightSrcLoc, math.floor(lightSourceIndex))
    glUniform(uniformSundir, sunDir[1], sunDir[2], sunDir[3]);
    glUniform(uniformSunColor, sunCol[1], sunCol[2], sunCol[3]);
    glUniform(uniformSkyColor, skyCol[1], skyCol[2], skyCol[3]);
    glTexture(7, rainPicPath)
    glUniformMatrix(uniformViewPrjInv     , "viewprojectioninverse")
    glUniformMatrix(uniformViewInv        , "viewinverse")
    glUniformMatrix(uniformViewProjection , "viewprojection")
    for i=1,maxLightSources, 2 do
      glUniform(shaderLightSourcescLoc[i] ,0.0, 0.0, 0.0)
      glUniform(shaderLightSourcescLoc[i + 1] ,0.0, 0.0, 0.0)
    end
end

local function renderToTextureFunc()
    -- render a full screen quad
    --glClear (GL.COLOR_BUFFER_BIT,0,0,0,0 )
    glTexture(1, noisetextureFilePath);
    glTexRect(-1, -1, 1, 1, 0, 0, 1, 1)
end

local function cleanUp()    
    glResetState()
    glUseShader(0)
    glTexture(0, false)
    glTexture(1, false)
    glTexture(2, false)
    glBlending(true)
end

local function prepare()
    glBlending(false)
    glCopyToTexture(depthtex, 0, 0, 0, 0, vsx, vsy) -- the depth texture
    glTexture(depthtex)
    glCopyToTexture(screentex, 0, 0, 0, 0, vsx, vsy)
    glTexture(screentex)
    glTexture(3, "$map_gbuffer_normtex")
    glTexture(4, "$model_gbuffer_normtex")
    glTexture(6, "$sky_reflection")
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
    prepare()
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
    --glTexture(4, raincanvastex)
    glTexture(0, raincanvastex)
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

--[[
Draw Rain Reflection once:
8:53 PM]ivand: Spring.SetMapShadingTexture("$ssmf_specular", luaTex) and Spring.SetMapShadingTexture("$ssmf_sky_refl", luaTex) look relevant 
[8:55 PM]ivand: $ssmf_sky_refl specifically controls how strong the reflection is
[8:56 PM]ivand: So make a lua texture with FBO, draw the default $ssmf_sky_refl there and with shader modulate it as much as you want
[8:56 PM]ivand: Then Spring.SetMapShadingTexture("$ssmf_sky_refl", luaTex) (once) 

]]

function widget:DrawWorld()
    if boolRainActive == false then
        return  
    end

    local _, _, isPaused = Spring.GetGameSpeed()
    if isPaused then
       local currentTime = Spring.GetTimer() 
       pausedTime = pausedTime + Spring.DiffTimers(currentTime, lastFrametime)
       
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

local function splitStringIntoPositonColorStrength(dynLightPosString)
    local splitResult = split(dynLightPosString, '/')
    resetLightSources()
    for i=1, #splitResult, 7 do
        local x,y,z = 
        addLightSources({
                        tonumber(splitResult[i]),
                        tonumber(splitResult[i+1]),
                        tonumber(splitResult[i+2])
                        }, 
                        {
                        tonumber(splitResult[i+3]),
                        tonumber(splitResult[i+4]),
                        tonumber(splitResult[i+5])     
                        }, 
                        tonumber(splitResult[i+6]))
    end
end

function widget:GameFrame()
    sunDir = {gl.GetSun('pos')}
    sunCol = {gl.GetSun('specular')}
    local dynLightPosString = Spring.GetGameRulesParam("dynamic_lights")
end
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
