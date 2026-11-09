function gadget:GetInfo()
    return {
        name = 'House icon holograms',
        desc = 'Cyan architectural volumes replace house billboards in icon mode',
        author = 'MOSAIC contributors', license = 'GPL3', layer = 0, enabled = true,
    }
end

if gadgetHandler:IsSyncedCode() then return false end

local shader, cube
local uniforms, houses, suppressed, houseDefs = {}, {}, {}, {}
local shaderDir = 'luarules/gadgets/shaders/house_icon/'
local bases = {house_asian0=true, house_western0=true, house_arab0=true}
for id, def in pairs(UnitDefs) do
    local cp = def.customParams or {}
    -- Match residential definitions, never advertising holograms or decals.
    if bases[def.name] or def.name:match('^house_asian[1-4]$')
        or bases[cp.house_asian_base] or bases[cp.house_western_base]
        or bases[cp.house_arab_base] or cp.house_icon_hologram == '1' then
        houseDefs[id] = true
    end
end

local function restore(id)
    if suppressed[id] then
        if Spring.ValidUnitID(id) then Spring.SetUnitIconDraw(id, true) end
        suppressed[id] = nil
    end
end
local function restoreAll()
    for id in pairs(suppressed) do restore(id) end
end

local function buildCube()
    -- A unit-height box with separate face UVs; dimensions are supplied from
    -- the live collision volume, including procedural building updates.
    local faces = {
        {{-.5,0,-.5},{.5,0,-.5},{.5,1,-.5},{-.5,1,-.5}},
        {{.5,0,.5},{-.5,0,.5},{-.5,1,.5},{.5,1,.5}},
        {{-.5,0,.5},{-.5,0,-.5},{-.5,1,-.5},{-.5,1,.5}},
        {{.5,0,-.5},{.5,0,.5},{.5,1,.5},{.5,1,-.5}},
        {{-.5,1,-.5},{.5,1,-.5},{.5,1,.5},{-.5,1,.5}},
    }
    local uv = {{0,0},{1,0},{1,1},{0,1}}
    gl.BeginEnd(GL.QUADS, function()
        for _, face in ipairs(faces) do
            for i = 4, 1, -1 do
                local v = face[i]
                gl.TexCoord(uv[i][1], uv[i][2]); gl.Vertex(v[1], v[2], v[3])
            end
        end
    end)
end

function gadget:UnitCreated(id, defID)
    if houseDefs[defID] then houses[id] = true end
end
function gadget:UnitEnteredLos(id, team, allyTeam, defID)
    self:UnitCreated(id, defID or Spring.GetUnitDefID(id))
end
function gadget:UnitDestroyed(id)
    restore(id); houses[id] = nil
end
function gadget:UnitLeftLos(id)
    restore(id)
end

function gadget:Initialize()
    if not (gl.CreateShader and Spring.SetUnitIconDraw and Spring.IsUnitIcon) then
        Spring.Echo('[House icon holograms] Required rendering API unavailable')
        gadgetHandler:RemoveGadget(self); return
    end
    shader = gl.CreateShader({
        vertex = VFS.LoadFile(shaderDir .. 'house.vert'),
        fragment = VFS.LoadFile(shaderDir .. 'house.frag'),
    })
    if not shader then
        Spring.Echo('[House icon holograms] Shader failed:', gl.GetShaderLog() or '')
        gadgetHandler:RemoveGadget(self); return
    end
    for _, name in ipairs({'time','height','selected'}) do
        uniforms[name] = gl.GetUniformLocation(shader, name)
    end
    cube = gl.CreateList(buildCube)
    if not cube then gadgetHandler:RemoveGadget(self); return end
    for _, id in ipairs(Spring.GetAllUnits()) do self:UnitCreated(id, Spring.GetUnitDefID(id)) end
end

-- Prepare before the engine's icon pass. Evaluate camera/icon and LOS state
-- every frame, so zooming or changing spectator perspective cannot leave stale
-- holograms. No model/noDraw flags or gameplay state are changed.
local visible = {}
function gadget:DrawWorldPreUnit()
    visible = {}
    if not shader or not cube or Spring.IsGUIHidden() then restoreAll(); return end
    local _, fullView = Spring.GetSpectatingState()
    local allyTeam = Spring.GetMyAllyTeamID()
    local active = {}
    for id in pairs(houses) do
        if not Spring.ValidUnitID(id) then
            houses[id] = nil; suppressed[id] = nil
        elseif Spring.IsUnitIcon(id) and Spring.IsUnitInView(id)
            and not Spring.GetUnitIsCloaked(id) and not Spring.GetUnitNoDraw(id) then
            local los = Spring.GetUnitLosState(id, allyTeam)
            if fullView or (los and los.los) then
                local x,y,z = Spring.GetUnitPosition(id)
                local sx,sy,sz,ox,oy,oz = Spring.GetUnitCollisionVolumeData(id)
                -- Fail open to the original billboard if live bounds are absent.
                if x and sx and sy and sz and sx>0 and sy>0 and sz>0 then
                    visible[#visible+1] = {id=id,x=x,y=y,z=z,sx=sx,sy=sy,sz=sz,
                        ox=ox or 0,oy=oy or sy/2,oz=oz or 0,
                        heading=(Spring.GetUnitHeading(id) or 0)*360/65536}
                    active[id] = true
                    if not suppressed[id] then
                        Spring.SetUnitIconDraw(id, false); suppressed[id] = true
                    end
                end
            end
        end
    end
    for id in pairs(suppressed) do if not active[id] then restore(id) end end
end

function gadget:DrawWorld()
    if not shader or not cube or #visible==0 then return end
    gl.PushAttrib(GL.ALL_ATTRIB_BITS)
    gl.DepthTest(true); gl.DepthMask(false); gl.Culling(GL.BACK)
    gl.Blending(GL.SRC_ALPHA, GL.ONE)
    gl.UseShader(shader)
    gl.Uniform(uniforms.time, Spring.GetGameSeconds())
    for _, v in ipairs(visible) do
        gl.Uniform(uniforms.height, v.sy)
        gl.Uniform(uniforms.selected, Spring.IsUnitSelected(v.id) and 1 or 0)
        gl.PushMatrix()
        gl.Translate(v.x,v.y,v.z); gl.Rotate(v.heading,0,1,0)
        gl.Translate(v.ox,v.oy-v.sy/2,v.oz); gl.Scale(v.sx,v.sy,v.sz)
        gl.CallList(cube)
        gl.PopMatrix()
    end
    gl.UseShader(0); gl.PopAttrib()
end
function gadget:Shutdown()
    restoreAll()
    if cube then gl.DeleteList(cube); cube=nil end
    if shader then gl.DeleteShader(shader); shader=nil end
end
