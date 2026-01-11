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
-------------------------------------------------------------------------------
-- Config
--------------------------------------------------------------------------------

local DEBUG_VIEW = "L0"
local ATLAS_SIZE = 2048        -- start small
local CAMERA_HEIGHT = 10000

local DAYLENGTH = 28800

--[[--------------------------------------------------------------------------
-- RADIANCE CASCADE STAGE 1 (DISABLED)
--
-- This stage introduces multi-scale light propagation in 2.5D.
-- Do NOT enable until the base atlas is visually correct and stable.
----------------------------------------------------------------------------]]

-- local CASCADE_COUNT = 3
-- local CASCADE_BASE_RES = ATLAS_SIZE
-- local CASCADE_SCALE = 2

-- local cascadeTex = {}   -- cascadeTex[0] = emission atlas
-- local cascadeFBO = {}

--------------------------------------------------------------------------------
-- State
--------------------------------------------------------------------------------

local vsx, vsy = gl.GetViewSizes()
local neonUnitTables = {}
local neonLightPercent = 0

local topDownTex
local topDownFBO
local mapMinX, mapMaxX
local mapMinZ, mapMaxZ
local orthoWidth
local orthoHeight
local perspShader

--------------------------------------------------------------------------------
-- Utils
--------------------------------------------------------------------------------
local glOrtho                = gl.Ortho

local function dayPercentToNeonPercent(p)
    if p < 0.25 then return 1 - p / 0.25 end
    if p > 0.75 then return 1 - (1 - p) / 0.25 end
    return 0
end

local function getDayPercent()
    local f = (Spring.GetGameFrame() % DAYLENGTH) / DAYLENGTH
    return f
end

--[[--------------------------------------------------------------------------
-- Allocate cascade textures
-- Each cascade is half resolution of the previous
----------------------------------------------------------------------------]]

-- local function initRadianceCascades()
--     local res = CASCADE_BASE_RES
--     for i = 1, CASCADE_COUNT do
--         cascadeTex[i] = gl.CreateTexture(res, res, {
--             min_filter = GL.LINEAR,
--             mag_filter = GL.LINEAR,
--             wrap_s = GL.CLAMP_TO_EDGE,
--             wrap_t = GL.CLAMP_TO_EDGE,
--             fbo = true,
--         })
--         res = math.floor(res / CASCADE_SCALE)
--     end
-- end


--------------------------------------------------------------------------------
-- Top-down camera
--------------------------------------------------------------------------------

local function pushCamera()
    return Spring.GetCameraState()
end

local function popCamera(state)
    Spring.SetCameraState(state, 0)
end


local function setTopDownCamera()
    Spring.SetCameraState({
        name = "pos",
        mode = 0,
        px = (mapMinX + mapMaxX) * 0.5,
        py = CAMERA_HEIGHT,
        pz = (mapMinZ + mapMaxZ) * 0.5,
        dx = 0, dy = -1, dz = 0,
        rx = 0, ry = 0, rz = 0,
        fov = 45,
    }, 0)
end

--------------------------------------------------------------------------------
-- Perspective shader
--------------------------------------------------------------------------------
--[[--------------------------------------------------------------------------
-- Radiance propagation shader
--
-- Input : previous cascade
-- Output: current cascade
-- Behavior:
--  - Sample neighborhood
--  - Attenuate by distance
--  - Accumulate conservatively
----------------------------------------------------------------------------]]

-- fragment shader pseudocode:
--
-- vec3 sum = vec3(0);
-- for each offset in kernel:
--     sum += texture(prevCascade, uv + offset).rgb * weight;
-- output = sum * falloff;

local function initPerspectiveShader()
    perspShader = gl.CreateShader({
        vertex = [[
            #version 150
            in vec3 position;
            uniform mat4 viewProjectionMatrix;
            out vec3 worldPos;
            void main() {
                worldPos = position;
                gl_Position = viewProjectionMatrix * vec4(position, 1.0);
            }
        ]],
        fragment = [[
            #version 150
            uniform sampler2D uLightTex;
            uniform vec2 worldMin;
            uniform vec2 worldMax;
            in vec3 worldPos;
            out vec4 fragColor;
            void main() {
                vec2 uv = (worldPos.xz - worldMin) / (worldMax - worldMin);
                vec3 light = texture(uLightTex, uv).rgb;
                fragColor = vec4(light, 1.0);
            }
        ]],
        uniformInt = {
            uLightTex = 0,
        },
    })

    if not perspShader then
        Spring.Echo("NeonLight: shader compile failed")
        Spring.Echo("NeonLight:"..gl.GetShaderLog())
        widgetHandler:RemoveWidget(self)
    end

    if DEBUG_VIEW then 
        Spring.Echo("Neonligth: shader has Debugview activated with ".. DEBUG_VIEW)
    end
end

--------------------------------------------------------------------------------
-- Initialization
--------------------------------------------------------------------------------

local function recieveNeonHoloLightPiecesByUnit(unitPiecesTable)
    neonUnitTables = unitPiecesTable or {}
end

function widget:Initialize()
    mapMinX = 0
    mapMinZ = 0
    mapMaxX = Game.mapSizeX
    mapMaxZ = Game.mapSizeZ
    orthoWidth = (mapMaxX - mapMinX) * 0.5
    orthoHeight = (mapMaxZ - mapMinZ) * 0.5


    topDownTex = gl.CreateTexture(ATLAS_SIZE, ATLAS_SIZE, {
        min_filter = GL.LINEAR,
        mag_filter = GL.LINEAR,
        wrap_s = GL.CLAMP_TO_EDGE,
        wrap_t = GL.CLAMP_TO_EDGE,
        fbo = true,
    })

    initPerspectiveShader()

    widgetHandler:RegisterGlobal("RecieveAllNeonUnitsPieces", recieveNeonHoloLightPiecesByUnit)
end

--------------------------------------------------------------------------------
-- Top-down emission pass
--------------------------------------------------------------------------------

local function renderTopDownAtlas()
    local camState = pushCamera()
    setTopDownCamera()
     -- A: Orthogonal Topdown shader: 0) From ortho camera produce a depthmap Render a topdownview of all Neonsigns, lightsources in the size of cameraviewWidth x Scenedepth
    glOrtho(orthoWidth, orthoHeight, -orthoWidth, orthoWidth) --> https://github.com/beyond-all-reason/Beyond-All-Reason/blob/8e6f934ab10e549f17438061eb6e1d4e267d995e/luarules/gadgets/unit_icongenerator.lua#L669
   
    gl.RenderToTexture(topDownTex, function()
        gl.Clear(0, 0, 0, 1)
        gl.DepthTest(true)
        gl.Color(neonLightPercent, neonLightPercent, neonLightPercent, 1)

        for unitID, pieces in pairs(neonUnitTables) do
            gl.PushMatrix()
            gl.UnitMultMatrix(unitID)
            for _, pieceID in ipairs(pieces) do
                gl.PushMatrix()
                gl.UnitPieceMultMatrix(unitID, pieceID)
             
                gl.UnitPiece(unitID, pieceID)
                gl.PopMatrix()
            end
            gl.PopMatrix()
        end
    end)

    popCamera(camState)
end

--[[--------------------------------------------------------------------------
-- Build cascades from emission atlas
----------------------------------------------------------------------------]]
-- local function buildRadianceCascades()
--     local prevTex = topDownTex  -- L0 emission
--
--     for i = 1, CASCADE_COUNT do
--         gl.RenderToTexture(cascadeTex[i], function()
--             gl.UseShader(propagationShader)
--             gl.Texture(0, prevTex)
--             gl.Uniform(propagationShader, "radius", i * 4)
--             gl.TexRect(-1, -1, 1, 1)
--             gl.UseShader(0)
--             gl.Texture(0, false)
--         end)
--
--         prevTex = cascadeTex[i]
--     end
-- end

--[[--------------------------------------------------------------------------
-- Combine cascades into a final light atlas
-- This is intentionally explicit for debugging
----------------------------------------------------------------------------]]

-- local function combineCascades()
--     gl.RenderToTexture(finalLightTex, function()
--         gl.Clear(0,0,0,1)
--         gl.Blending(GL.ONE, GL.ONE)
--
--         gl.Texture(0, topDownTex) -- L0
--         gl.TexRect(-1,-1,1,1)
--
--         for i = 1, CASCADE_COUNT do
--             gl.Texture(0, cascadeTex[i])
--             gl.TexRect(-1,-1,1,1)
--         end
--
--         gl.Blending(false)
--         gl.Texture(0, false)
--     end)
-- end


--------------------------------------------------------------------------------
-- Update
--------------------------------------------------------------------------------

function widget:Update(dt)
    neonLightPercent = dayPercentToNeonPercent(getDayPercent())
end

--------------------------------------------------------------------------------
-- Draw
--------------------------------------------------------------------------------

function widget:DrawWorldPreUnit()
    renderTopDownAtlas()
end

--[[--------------------------------------------------------------------------
-- Debug cascade visualization
----------------------------------------------------------------------------]]
function widget:DrawScreen()
    if DEBUG_VIEW then
        if DEBUG_VIEW == "L0" then gl.Texture(topDownTex) end
        if DEBUG_VIEW == "L1" then gl.Texture(cascadeTex[1]) end
        if DEBUG_VIEW == "L2" then gl.Texture(cascadeTex[2]) end
        if DEBUG_VIEW == "L3" then gl.Texture(cascadeTex[3]) end
        gl.TexRect(0, vsy, vsx, 0)
        gl.Texture(false)
    end
end

function widget:DrawWorld()
    if DEBUG_VIEW then return end

    gl.UseShader(perspShader)
    gl.Texture(0, topDownTex)
    gl.Uniform(perspShader, "worldMin", mapMinX, mapMinZ)
    gl.Uniform(perspShader, "worldMax", mapMaxX, mapMaxZ)

    gl.Blending(GL.ONE, GL.ONE)
    gl.TexRect(-1, -1, 1, 1)

    gl.UseShader(0)
    gl.Texture(0, false)
    gl.Blending(false)
end

--------------------------------------------------------------------------------
-- Shutdown
--------------------------------------------------------------------------------

function widget:Shutdown()
    if topDownTex then gl.DeleteTexture(topDownTex) end
    if perspShader then gl.DeleteShader(perspShader) end
end
