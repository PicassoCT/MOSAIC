function widget:GetInfo()
    return {
        name = "NeonLight Radiance Cascade",
        desc = "Produces a topdown fbo neonlightmap of the city in cameraview via radiance cascade ",
        author = "Picasso",
        date = "2023",
        license = "GNU GPL, v2 or later",
        layer = -9,
        enabled = true, --  loaded by default?
        hidden = false
    }
end

--[[

--Examples:
--https://www.youtube.com/watch?v=3so7xdZHKxw
--https://www.shadertoy.com/view/mlSfRD
--https://www.shadertoy.com/view/X3XfRM
--Documentation: 
--The algo:
    A: Orthogonal Topdown shader
        1) From ortho camera produce a depthmap Render a topdownview of all Neonsigns, lightsources in the size of cameraviewWidth x Scenedepth
            -> produces neonPiecesInputFbo
        2) Transfer this data, in radiance cascade computationshader - into a 2d radiance cascade sampler texture 
            -> gets/transfers radiance cascade Samplecube 
        3) Calculate a lighttexture from the radiance cascade to 2nd FBO : TODO buffer size: cameraviewWidth x Scenedepth 
        4) Calculate viewshade from the scene camera in world via heightmap traceRay. If it can not be seen- it remains in the radiancecascade, 
           but is not rendered into the lightmap 

        Artifacts: 
        -> Updated Radiance cascade sampeler   
        -> Orthogonal TopDownOutput Picture

    B: Perspective scene Lookup shader
        1) From the scene camera - lookup the pixel mapping to topdown 2nd FBO
        2) Apply the looked up value by addition (its light after all)
        3) Blur if needed
        Artifacts -> Light on Groundsurfaces to apply from perspective


                            [ Scene Orthogonal Top-Down View ]
     +---------------------------------------------------------------+
     |/                  City / Map Geometry                         |
     /                     _____               _____                 |
_00_/|      +-------------+     +-------------+     +-------------+  |
|  | |      |             |View |             |View |             |  |
|__| |      |  Building A |Shade|  Building B |Shade|  Building C |  |
    \|      +-------------+_____+-------------+_____+-------------+  |
     \                                                               |
     |\                Terrain / Ground Mesh                         |
     |                                                               |
     +---------------------------------------------------------------+


                     [ Rendering Pipeline Flow ]

+----------------+         +-----------------+        +----------------------+
|  Geometry Pass | ---->   | Depth / Normal  | ---->  | Neon Light Shader    |
|  (Draw city    |         | Textures        |        | (apply neon light    |
|   meshes)      |         | (G-buffer)      |        |  on top-down canvas) |
+----------------+         +-----------------+        +----------------------+
                                                              |
                                                              v
                                     +-----------------------------+
                                     | Neon Light Canvas Texture   |
                                     | (2D Top-down projection     |
                                     |  with blended neon lights)  |
                                     +-----------------------------+
                                                              |
                                                              v
                  +--------------------------------------------+
                  | Final Composition Pass                     |
                  | (Combine neon light canvas with scene      |
                  |  using blending — possibly additive/mul)   |
                  +--------------------------------------------+
                                                              |
                                                              v
                  +--------------------------------------------+
                  |              Final Framebuffer             |
                  |           (Displayed on screen)            |
                  +--------------------------------------------+


               [ Key Data Flow in the Widget ]

  Depth Texture -->  normaltex   -->  neonLightcanvastex  -->  Final Output
]]
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

-- > debugEchoT(
local boolDebugActive = true  --TODODO
local topDownRadianceCascadeShader = nil
local mapLightMapToPerspectiveShader = nil

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
local glCreateFBO            = gl.CreateFBO
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
local radianceCascadeCubeSampler = nil
local depthCopyTex= nil
local seedTex = nil
local pingTex = nil
local pongTex = nil
local sdfTex  = nil

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

local uniform_topDown_SunColor
local uniform_topDown_SkyColor
local uniform_topDown_SunPos
local uniform_topDown_EyePos
local uniform_topDown_EyeDirection
local uniform_topDown_Projection
local uniform_topDown_Time
local uniform_topDown_ViewPortSize

local uniform_mapPerspective_ViewPortSize 
local uniform_mapPerspective_InvProjView  
local uniform_mapPerspective_sunColor     
local uniform_mapPerspective_skyColor     
local uniform_mapPerspective_worldMin     
local uniform_mapPerspective_worldMax     

local modelDepthTexIndex            = 0
local mapDepthTexIndex              = 1
local screentexIndex                = 2
local normaltexIndex                = 3
local normalunittexIndex            = 4
local neonPiecesInputTextureIndex   = 5

local dephtCopyTexIndex             = 6
local sdfTexIndex                   = 7

local eyePos = {spGetCameraPosition()}
local eyeDir = {spGetCameraDirection()}
local neonUnitTables = {}
local UnitUnitDefIDMap = {}
local counterNeonUnits = 0
local shaderName = "gfx_neonlights_radiancecascade"
local sdfTexSize = 256
local sdfTexParams = {
  format = GL.RG32F,
  min_filter = GL.NEAREST,
  mag_filter = GL.NEAREST,
}
-- Here we go, the size, where you ask yourself, why do i do so much boilerplate and dont use frameworks.Foo
local luaShaderDir = "luaui/widgets_mosaic/include/"
local LuaShader = VFS.Include(luaShaderDir.."LuaShader.lua")
assert(LuaShader)
--
local DAYLENGTH  = 28800

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
local function errorOutIfNotInitialized(value, message)
    if value == nil then
        Spring.Echo(shaderName..": "..message .." - aborting initialization of ".. shaderName)
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

    if (neonPiecesInputFbo ~= nil  ) then
        glDeleteTexture(neonPiecesInputFbo)
    end

    if (radianceCascadeCubeSampler ~= nil  ) then
        glDeleteTexture(radianceCascadeCubeSampler)
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

    neonPiecesInputFbo =  
    glCreateTexture (  
        4096, 
        4096,
        {
            min_filter = GL.LINEAR,
            mag_filter = GL.LINEAR,
            wrap_s = GL.CLAMP_TO_EDGE,
            wrap_t = GL.CLAMP_TO_EDGE,
            fbo = true
        }
        )
    errorOutIfNotInitialized(neonPiecesInputFbo, "neon pieces input fbo not existing")       
  

    radianceCascadeCubeSampler =
        glCreateTexture(
        4096,
        4096,
        {
        min_filter = GL.LINEAR, 
        mag_filter = GL.LINEAR,
        wrap_s = GL.CLAMP_TO_EDGE, 
        wrap_t = GL.CLAMP_TO_EDGE,
        }
    )
    errorOutIfNotInitialized(radianceCascadeCubeSampler, "radiance cascade sampler not existing")       

    neonLightcanvastex =
        glCreateTexture(
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

    local commonTexOpts = {
        target = GL_TEXTURE_2D,
        border = false,
        min_filter = GL.NEAREST,
        mag_filter = GL.NEAREST,

        wrap_s = GL.CLAMP_TO_EDGE,
        wrap_t = GL.CLAMP_TO_EDGE,
    }
    commonTexOpts.format = GL_RGB8_SNORM
    widgetHandler:UpdateCallIn("DrawScreenEffects")
end

widget:ViewResize()
local function initMapToPerspectiveLightShader()
   Spring.Echo("gfx_neonlight_radiancecascade:initMapToPerspectiveLightShader")
    local fragmentShader =  VFS.LoadFile(shaderFilePath .. "mapTopDownToPerspectiveLightShader.frag") 
    local vertexShader = VFS.LoadFile(shaderFilePath .. "identity.vert.glsl") 
    local uniformInt = {
        modelDepthTex = 0, -- needed to calculate the 3dish shadows
        radianceCascadeTex = 1,
    }

    mapLightMapToPerspectiveShader =
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
                worldMin    = {0,0},
                worldMax    = {0,0,0},
                sunColor = sunCol,
                skyColor = skyCol,              
            }
        }
    )
    if not mapLightMapToPerspectiveShader then
        Spring.Echo(shaderName..": Radiance Cascade TopDown Shader failed to compile")
        Spring.Echo(glGetShaderLog())
        widgetHandler:RemoveWidget(self)
        return
    end

    uniform_mapPerspective_ViewPortSize = glGetUniformLocation(mapLightMapToPerspectiveShader, "viewPortSize")
    uniform_mapPerspective_InvProjView  = glGetUniformLocation(mapLightMapToPerspectiveShader, "invProjView")
    uniform_mapPerspective_worldMin     = glGetUniformLocation(mapLightMapToPerspectiveShader, "worldMin")
    uniform_mapPerspective_worldMax     = glGetUniformLocation(mapLightMapToPerspectiveShader, "worldMax")
end

local function initJumpFloodSdfShader()

    local fragmentShader = VFS.LoadFile(shaderFilePath .. "jumpfloodsdf/.frag") 
    local vertexShader   = VFS.LoadFile(shaderFilePath .. "jumpfloodsdf/.vert.glsl") 
    local placeholderTable = {}

  seedShader = LuaShader({ vertex = "shaders/seed.glsl", fragment = "shaders/seed.glsl" }, "seedShader")
  jfaShader  = LuaShader({ vertex = "shaders/jfa.glsl", fragment = "shaders/jfa.glsl" }, "jfaShader")
  distShader = LuaShader({ vertex = "shaders/distance.glsl", fragment = "shaders/distance.glsl" }, "distShader")
  displayShader = LuaShader({ vertex = "shaders/display.glsl", fragment = "shaders/display.glsl" }, "displayShader")
  seedShader:Initialize()
  jfaShader:Initialize()
  distShader:Initialize()

    seedTex = gl.CreateTexture(sdfTexSize, sdfTexSize, sdfTexParams)
    pingTex = gl.CreateTexture(sdfTexSize, sdfTexSize, placeholderTable)
    pongTex = gl.CreateTexture(sdfTexSize, sdfTexSize, placeholderTable)
    sdfTex  = gl.CreateTexture(sdfTexSize, sdfTexSize, { format = GL.R32F })
end

local function initTopDownRadianceCascadeShader()
    Spring.Echo("gfx_neonlight_radiancecascade: initTopDownRadianceCascadeShader")

    local fragmentShader = VFS.LoadFile(shaderFilePath .. "topDownNeonLightRadianceCascadeShader.frag") 
    local vertexShader   = VFS.LoadFile(shaderFilePath .. "identity.vert.glsl") 
    
    local uniformInt = {
        modelDepthTex    = modelDepthTexIndex,
        mapDepthTex      = mapDepthTexIndex,
        screentex        = screentexIndex,
        normaltex        = normaltexIndex,
        normalunittex    = normalunittexIndex,
        neonLightcanvastex = neonPiecesInputTextureIndex,
        dephtCopyTex     = dephtCopyTexIndex,
        sdfTex          = sdfTexIndex
    }

    topDownRadianceCascadeShader = glCreateShader({
        fragment = fragmentShader,
        vertex   = vertexShader,
        uniformInt = uniformInt,
        uniform = {
            timePercent = 0,
            neonLightPercent = 0,
        },
        uniformFloat = {
            viewPortSize = {vsx, vsy},
            sunCol  = sunCol,
            skyCol  = skyCol,
            sunPos  = sunPos,
            eyePos  = eyePos,
            eyeDir  = eyeDir,
        }
    })

    if not topDownRadianceCascadeShader then
        Spring.Echo(shaderName .. ": Radiance Cascade Topdown Shader failed to compile")
        Spring.Echo(glGetShaderLog())
        widgetHandler:RemoveWidget(self)
        return
    end

    -- Cache uniform locations for later updates
    timePercentLoc              = glGetUniformLocation(topDownRadianceCascadeShader, "timePercent")
    neonLightPercentLoc         = glGetUniformLocation(topDownRadianceCascadeShader, "neonLightPercent")
    uniform_topDown_ViewPortSize= glGetUniformLocation(topDownRadianceCascadeShader, "viewPortSize")
    uniform_topDown_EyePos      = glGetUniformLocation(topDownRadianceCascadeShader, "eyePos")
    uniform_topDown_EyeDir      = glGetUniformLocation(topDownRadianceCascadeShader, "eyeDir")
    uniform_topDown_SunColor    = glGetUniformLocation(topDownRadianceCascadeShader, "sunCol")
    uniform_topDown_SunPos      = glGetUniformLocation(topDownRadianceCascadeShader, "sunPos")

    -- Optional matrix uniforms
    uniform_topDown_ViewPrjInv  = glGetUniformLocation(topDownRadianceCascadeShader, "viewProjectionInv")
    uniform_topDown_ViewInv     = glGetUniformLocation(topDownRadianceCascadeShader, "viewInv")
    uniform_topDown_ViewProjection = glGetUniformLocation(topDownRadianceCascadeShader, "viewProjection")
    uniform_topDown_Projection  = glGetUniformLocation(topDownRadianceCascadeShader, "projection")
    
    
    --uniform sampler2D uDepthMap; // Depth texture for cascading
    --uniform sampler2D uEmissionMap; // Input: Emissive neon glow map
    --uniform samplerCube radianceCascade;

    Spring.Echo(shaderName .. ": Radiance Cascade Shader initialized")
end

local function init()
    widgetHandler:UpdateCallIn("Update")  
    errorOutIfNotInitialized(glCreateShader, "no shader support")
    errorOutIfNotInitialized(glCreateFBO, "no fbo support")

    local headless = Spring.GetConfigInt("Headless", 0) > 0
    if headless then
        Spring.Echo(shaderName.. "running in Headless mode")
        return
    end
    initTopDownRadianceCascadeShader()
    initMapToPerspectiveLightShader()
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
        glDeleteTexture(depthCopyTex or "")
        glDeleteTexture(screentex or "")
        glDeleteTexture(neonPiecesInputFbo or "")
        glDeleteTexture(radianceCascadeCubeSampler or "")
        glDeleteTexture(normalunittex or "")
        glDeleteTexture(seedTex or "")
        glDeleteTexture(pingTex or "")
        glDeleteTexture(pongTex or "")
        glDeleteTexture(sdfTex or "")
    end
end

local function updateTopDownRadianceCascadeUniforms()
    glUniform(timePercentLoc, timePercent)
    glUniform(neonLightPercentLoc, neonLightPercent)
    glUniform(uniform_topDown_ViewPortSize, vsx, vsy)

    glUniform(uniform_topDown_EyePos, eyePos[1], eyePos[2], eyePos[3])
    glUniform(uniform_topDown_EyeDir, eyeDir[1], eyeDir[2], eyeDir[3])

    glUniform(uniform_topDown_SunColor, sunCol[1], sunCol[2], sunCol[3])
    glUniform(uniform_topDown_SkyColor, skyCol[1], skyCol[2], skyCol[3])
    glUniform(uniform_topDown_SunPos, sunPos[1], sunPos[2], sunPos[3])

    -- Optional matrices, update if you have correct matrices ready
    glUniformMatrix(uniform_topDown_ViewPrjInv, "viewprojectioninverse")
    glUniformMatrix(uniform_topDown_ViewInv, "viewinverse")
    glUniformMatrix(uniform_topDown_ViewProjection, "viewprojection")
    glUniformMatrix(uniform_topDown_Projection, "projection")
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
    glTexture(sdfTexIndex, sdfTex)

    glCopyToTexture(screentex, 0, 0, 0, 0, vsx, vsy)
    glCopyToTexture(depthCopyTex, 0, 0, vpx, vpy, vsx, vsy)
end

local function updatedTopDownUniforms()
    glUniform(topDownRadianceCascadeShader, "neonLightTex", 0)
    glUniform(topDownRadianceCascadeShader, "depthTex", 1)
    glUniform(topDownRadianceCascadeShader, "radianceCascade", 2)

    glUniform(topDownRadianceCascadeShader, "viewPortSize", viewSizeX, viewSizeY)
    glUniform(topDownRadianceCascadeShader, "invProjView", invProjViewMatrix)
    glUniform(topDownRadianceCascadeShader, "sunCol",  sunCol)
    glUniform(topDownRadianceCascadeShader, "skyCol",  skyCol)
    glUniform(topDownRadianceCascadeShader, "worldMin", todoX, todoMinZ)
    glUniform(topDownRadianceCascadeShader, "worldMax", todoMaxX, todoMaxZ)

end

local function DrawNeonLightsToFbo()
    prepareTextures()
    glUseShader(topDownRadianceCascadeShader)
    updatedTopDownUniforms()
    glRenderToTexture(neonLightcanvastex, renderToTextureFunc);
   
    cleanUp()    
end

local function updatePerspectiveShaderUniforms()
    glUniform(mapLightMapToPerspectiveShader, "neonLightTex", 0)
    glUniform(mapLightMapToPerspectiveShader, "depthTex", 1)
    glUniform(mapLightMapToPerspectiveShader, "radianceCascade", 2)

    glUniform(mapLightMapToPerspectiveShader, "invProjView", invProjViewMatrix)
    glUniform(mapLightMapToPerspectiveShader, "viewProjection", invProjViewMatrix)
    glUniform(mapLightMapToPerspectiveShader, "viewInverse", invProjViewMatrix)
    glUniform(mapLightMapToPerspectiveShader, "projection", todo)
    glUniform(mapLightMapToPerspectiveShader, "worldMin", todo, todo)
    glUniform(mapLightMapToPerspectiveShader, "worldMax", todo, todo)

end
local function DrawNeonLightMapIntoScene()
    glTexture(1, "$depthtex2") -- or your scene depth tex!
    glUseShader()
    glTexRect(0, vsy, vsx, 0)
end

function widget:DrawScreenEffects()
        glBlending(GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA)
        glTexture(0, neonLightcanvastex)
    if boolDebugActive then
        glTexRect(0, vsy, vsx, 0)
        glTexture(0, false);
    else
        updatePerspectiveShaderUniforms()
        DrawNeonLightMapIntoScene()
        glTexRect(0, vsy, vsx, 0)
        glUseShader(0)
        glTexture(0, false);
    end
end

local function recieveNeonHoloLightPiecesByUnit(unitPiecesTable)
    neonUnitTables =unitPiecesTable
    --Spring.Echo("Recieved recieveNeonHoloLightPiecesByUnit")
end

function widget:Initialize()
    if (not glRenderToTexture) then --super bad graphic driver
        Spring.Echo("gfx_neonlight_radiancecascades: Im tired boss, tired of companies beeing ugly to devs, i wanna go home! Quitting!")
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

local function renderCameraOrthogonal()
    --TODO Optimize towards https://developer.download.nvidia.com/SDK/10.5/opengl/src/cascaded_shadow_maps/doc/cascaded_shadow_maps.pdf
    orgCamState = Spring.GetCameraState() 
    local camera, ortho = computeTopDownCamera(orgCam)
    Spring.SetCameraState(camera) 
    -- A: Orthogonal Topdown shader: 0) From ortho camera produce a depthmap Render a topdownview of all Neonsigns, lightsources in the size of cameraviewWidth x Scenedepth
    glOrtho(ortho.width, ortho,height, ortho.near, ortho.far) --> https://github.com/beyond-all-reason/Beyond-All-Reason/blob/8e6f934ab10e549f17438061eb6e1d4e267d995e/luarules/gadgets/unit_icongenerator.lua#L669
    glRenderToTexture(neonPiecesInputFbo)
end
local log2TexSize = math.floor(math.log(sdfTexSize) / math.log(2))
function widget:DrawUnits()
  --TODO Integrate
  -- 1. Seed
  glRenderToTexture(seedTex, function()
    seedShader:Activate()
    -- assume glow mask is bound to texture unit 0
    seedShader:SetUniform("u_texSize", sdfTexSize, sdfTexSize)
    gl.Texture(0, seedTex)
    gl.TexRect(-1, -1, 1, 1, false, true)
    gl.Texture(0, false)
    seedShader:Deactivate()
  end)

  -- 2. Jump Flooding
  local src, dst = pingTex, pongTex
  for i = log2TexSize, 0, -1 do
    local jump = 2^i
    glRenderToTexture(dst, function()
      jfaShader:Activate()
      jfaShader:SetUniform("u_texSize", sdfTexSize, sdfTexSize)
      jfaShader:SetUniform("u_jump", jump)
      gl.Texture(0, src)
      gl.TexRect(-1, -1, 1, 1, false, true)
      gl.Texture(0, false)
      jfaShader:Deactivate()
    end)
    src, dst = dst, src
  end

  -- 3. Distance Field
  glRenderToTexture(sdfTex, function()
    distShader:Activate()
    distShader:SetUniform("u_texSize", sdfTexSize, sdfTexSize)
    gl.Texture(0, src)
    gl.TexRect(-1, -1, 1, 1, false, true)
    gl.Texture(0, false)
    distShader:Deactivate()
  end)

    topDownRadianceCascadeShader:ActivateWith(
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
    gl.ActiveFBO(neonPiecesInputFbo, renderCameraOrthogonal)
    DrawNeonLightsToFbo()
    end)
    
   restoreCameraPosDir()
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
