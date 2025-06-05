function widget:GetInfo()
    return {
        name = "NeonLight Radiance Cascade",
        desc = "Produces a topdown fbo neonlightmap of the city in cameraview via radiance cascade",
        author = "Picasso",
        date = "2023",
        license = "GNU GPL, v2 or later",
        layer = -9,
        enabled = false, --  loaded by default?
        hidden = false
    }
end
--Documentation: 
--https://www.youtube.com/watch?v=3so7xdZHKxw
--https://www.shadertoy.com/view/mlSfRD
--https://www.shadertoy.com/view/X3XfRM
--TODO transfer the baking to neonlights that already has the pieces setup
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

-- > debugEchoT(
local boolDebugActive = true  --TODODO
local topDownRadianceCascadeShader = nil

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
local glOrtho                = gl.Ortho
local spGetCameraPosition    = Spring.GetCameraPosition
local spGetCameraVectors     = Spring.GetCameraVectors
local spGetWind              = Spring.GetWind
local time                   = Spring.GetGameSeconds
local spGetDrawFrame         = Spring.GetDrawFrame
local spGetCameraDirection   = Spring.GetCameraDirection
local eyex,eyey,eyez         = 0,0,0


--------------------------------------------------------------------------------
--Constants
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
local neonUnitTables = {}
local UnitUnitDefIDMap = {}
local counterNeonUnits = 0



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

local function inittopDownRadianceCascadeShader()
   Spring.Echo("gfx_neonLight:Initialize")
    -- abort if not enabled
    widgetHandler:UpdateCallIn("Update")  
    errorOutIfNotInitialized(glCreateShader, "no shader support")

    local fragmentShader =  VFS.LoadFile(shaderFilePath .. "topDownNeonLightRadianceCascadeShader.frag") 
    local vertexShader = VFS.LoadFile(shaderFilePath .. "topDownNeonLightRadianceCascadeShader.vert") 
    
    local uniformInt = {
        modelDepthTex = modelDepthTexIndex, -- needed to calculate the 3dish shadows
        mapDepthTex = mapDepthTexIndex,     -- needed to calculate the mapDept for shadows
        screentex = screentexIndex,         -- the  background picture - mostly for debug purposes
        normaltex = normaltexIndex,         -- normal maptex 
        normalunittex= normalunittexIndex,  -- normal unittex    
        neonLightcanvastex = neonLightcanvastexIndex,
        dephtCopyTex = dephtCopyTexIndex
    }

    topDownRadianceCascadeShader =
        glCreateShader(
        {
            fragment = fragmentShader,
            vertex = vertexShader,
            uniformInt = uniformInt,
            uniform = {
                timePercent = 0,
                neonLightPercent= 0,
                scale = 0,
            },
            uniformFloat = {
                viewPortSize = {vsx, vsy},
                sunCol    = {0,0,0},
                skyCol    = {0,0,0},
                sunPos      = {0,0,1},
                eyePos = {0, 0, 0},
                eyeDir = {0, 0, 0}
            }
        }
    )

    if (topDownRadianceCascadeShader == nil) then
        Spring.Echo("gfx_neonLight:Initialize] particle shader compilation failed")
        Spring.Echo(glGetShaderLog())
        widgetHandler:RemoveWidget(self)
        return
    else
        Spring.Echo("gfx_neonLight: Shader compiled: ")
    end

    timePercentLoc                  = glGetUniformLocation(topDownRadianceCascadeShader, "timePercent")
    neonLightPercentLoc                  = glGetUniformLocation(topDownRadianceCascadeShader, "neonLightPercent")
    uniformViewPortSize             = glGetUniformLocation(topDownRadianceCascadeShader, "viewPortSize")

    uniformTime                     = glGetUniformLocation(topDownRadianceCascadeShader, "time")
    uniformEyePos                   = glGetUniformLocation(topDownRadianceCascadeShader, "eyePos")
    unformEyeDir                    = glGetUniformLocation(topDownRadianceCascadeShader, "eyeDir")

    uniformViewPrjInv               = glGetUniformLocation(topDownRadianceCascadeShader, 'viewProjectionInv')
    uniformViewInv                  = glGetUniformLocation(topDownRadianceCascadeShader, 'viewInv')
    uniformViewMatrix               = glGetUniformLocation(topDownRadianceCascadeShader, 'viewMatrix')
    uniformViewProjection           = glGetUniformLocation(topDownRadianceCascadeShader, 'viewProjection')
    uniformProjection               = glGetUniformLocation(topDownRadianceCascadeShader, 'projection')
    uniformSunColor                 = glGetUniformLocation(topDownRadianceCascadeShader, 'sunCol')
    uniformSkyColor                 = glGetUniformLocation(topDownRadianceCascadeShader, 'skyCol')
    uniformSunPos                   = glGetUniformLocation(topDownRadianceCascadeShader, 'sunPos')
    Spring.Echo("gfx_neonLight:Initialize ended")
end


local function init()
    inittopDownRadianceCascadeShader()
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

local function dayPercentToNeonPercent(dayPercent)
    if dayPercent <= 0.25 then return (1 - dayPercent/0.25) end
    if dayPercent >= 0.75 then return  (1 - dayPercent/0.75) end

    return 0.0
end

function widget:Update(dt)  
    accumulatedDT = accumulatedDT + dt 
    local _,_,_,percent = getDayTime()
    neonLightPercent = dayPercentToNeonPercent(percent)     
end

function widget:Shutdown()
    if glDeleteTexture then
        glDeleteTexture(depthtex or "")
        glDeleteTexture(screentex or "")
        glDeleteTexture(neonLightcanvastex or "")
        glDeleteTexture(normaltex or "")
        glDeleteTexture(normalunittex or "")
    end

    if topDownRadianceCascadeShader then
        gl.DeleteShader(topDownRadianceCascadeShader)
    end
end

local function updateUniforms()
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
]]

local function cleanUp()    
    glResetState()
    glUseShader(0)
    for i=0, dephtCopyTexIndex do
        glTexture(i, false)
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
    prepareTextures()
    glUseShader(topDownRadianceCascadeShader)
    updateUniforms()

    glRenderToTexture(neonLightcanvastex, renderToTextureFunc);
   
    cleanUp()    
end


function widget:DrawScreenEffects()
    if boolDebugActive then
        glBlending(GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA) 
        glTexture(0, neonLightcanvastex)
        glTexRect(0, vsy, vsx, 0)
        glTexture(0, false);
    end
end

local function recieveNeonHoloLightPiecesByUnit(unitPiecesTable)
    neonUnitTables =unitPiecesTable
end

function widget:Initialize()
    if (not gl.RenderToTexture) then --super bad graphic driver
        Spring.Echo("gfx_neonLights: Im tired boss, tired of companies beeing ugly to devs, i wanna go home! Quitting!")
        return
    end
    init()
    widget:ViewResize()
    widgetHandler:RegisterGlobal('RecieveAllNeonUnitsPieces', recieveNeonHoloLightPiecesByUnit)

end

function GetTopDownCamera()
  local camState = Spring.GetCameraState()
  local viewSizeX, viewSizeY = gl.GetViewSizes()
  local viewMatrix = gl.GetMatrixData("view")
  local projMatrix = gl.GetMatrixData("proj")

  -- Get 8 NDC corners of the camera frustum
  local ndcCorners = {
    {-1, -1, -1}, {1, -1, -1},
    {-1,  1, -1}, {1,  1, -1},
    {-1, -1,  1}, {1, -1,  1},
    {-1,  1,  1}, {1,  1,  1},
  }

  local function UnProjectNDC(x, y, z)
    -- Convert NDC [-1,1] to window coordinates
    local winX = (x * 0.5 + 0.5) * viewSizeX
    local winY = (y * 0.5 + 0.5) * viewSizeY
    return gl.UnProject(winX, winY, (z * 0.5 + 0.5))
  end

  -- Unproject frustum corners
  local worldCorners = {}
  for _, ndc in ipairs(ndcCorners) do
    local wx, wy, wz = UnProjectNDC(ndc[1], ndc[2], ndc[3])
    table.insert(worldCorners, {x = wx, y = wy, z = wz})
  end

  -- Compute AABB
  local minX, minY, minZ = math.huge, math.huge, math.huge
  local maxX, maxY, maxZ = -math.huge, -math.huge, -math.huge
  for _, p in ipairs(worldCorners) do
    minX = math.min(minX, p.x)
    minY = math.min(minY, p.y)
    minZ = math.min(minZ, p.z)
    maxX = math.max(maxX, p.x)
    maxY = math.max(maxY, p.y)
    maxZ = math.max(maxZ, p.z)
  end

  local centerX = (minX + maxX) * 0.5
  local centerZ = (minZ + maxZ) * 0.5
  local width = maxX - minX
  local depth = maxZ - minZ
  local heightAbove = maxY - minY + 100  -- buffer

  -- Extract yaw from original camera
  local dx, dz = camState.dir[1], camState.dir[3]
  local yaw = math.atan2(dx, dz)

  local ortho = {
            width = width,
            height = depth,
            near = 0.1,
            far = heightAbove * 2,
        }

  -- Construct new top-down camera state
  local topDownCam = {
    name = "pos",  -- use positional camera
    mode = 0,      -- absolute position
    px = centerX,
    py = maxY + heightAbove,
    pz = centerZ,
    dx = 0,
    dy = -1,
    dz = 0,
    ry = 0,
    rx = 0,
    rz = 0,
    fov = 45,
    height = 0,
    oldHeight = 0,
    flipped = false,
    angle = yaw,
    dist = 0,
  }

  return topDownCam, ortho
end

local orgCamState = nil
local function  restoreCameraPosDir()
    Spring.SetCameraState(orgCamState)
end

local function setCameraOrthogonal()
    --TODO Optimize towards https://developer.download.nvidia.com/SDK/10.5/opengl/src/cascaded_shadow_maps/doc/cascaded_shadow_maps.pdf
    orgCamState = Spring.GetCameraState() 
    local camera, ortho = computeTopDownCamera(orgCam)
    Spring.SetCameraState(camera) 
    glOrtho(ortho.width, ortho,height, ortho.near, ortho.far)
end

function widget:DrawUnits()
    renderToTextureShader:ActivateWith(
    function()  
   --render NeonUnits to mask
        for unitID, neonHoloParts in pairs(neonUnitTables) do
            for  _, pieceID in ipairs(neonHoloParts)do
              glPushPopMatrix( 
                function()
                    glUnitMultMatrix(unitID)
                    glUnitPieceMultMatrix(unitID, pieceID)
                    glUnitPiece(unitID, pieceID)
                end)
            end
        end
    setCameraOrthogonal()
    DrawNeonLightsToFbo()
    end)
    
   restoreCameraPosDir()
end

function widget:DrawScreenEffects()
    if not debugDisplayShader then return end
    local _, _, isPaused = Spring.GetGameSpeed()
    if isPaused then
       return
    end

    glUseShader(debugDisplayShader)   
    glTexture(1, neonLightcanvastex)
    glTexRect(0, vsy, vsx, 0)
    glTexture(1, false)
    glUseShader(0)
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
