-- Run through run.sh -- lua tests/house_icon_holograms_lifecycle.lua
-- Use the real renderer and mesh with Recoil's actual icon API spelling.
local function read(path)
    local f = assert(io.open(path)); local s = f:read('*a'); f:close(); return s
end
local source = read('luarules/gadgets/gfx_house_icon_holograms.lua')
local function fixture(options)
    options = options or {}
    local s = {icon=true, drawIcon=true, enabled=1, los=true, draws=0,
        vertices=0, lists=0, deleted=0, messages={}, grids={}}
    local function noop() end
    local spring = {
        UnitIconSetDraw=function(id, draw) assert(id==7); s.drawIcon=draw end,
        IsUnitIcon=function() return s.icon end,
        ValidUnitID=function() return true end,
        GetAllUnits=function() return {7} end,
        GetUnitDefID=function() return 1 end,
        GetConfigInt=function() return s.enabled end,
        IsGUIHidden=function() return s.hidden end,
        GetSpectatingState=function() return false,false end,
        GetMyAllyTeamID=function() return 0 end,
        IsUnitInView=function() return true end,
        GetUnitIsCloaked=function() return s.cloaked end,
        GetUnitNoDraw=function() return false end,
        GetUnitLosState=function() return {los=s.los} end,
        GetGameSeconds=function() return 1 end,
        GetUnitBasePosition=function() return 0,0,0 end,
        GetUnitVectors=function() return {0,0,1},{0,1,0},{-1,0,0} end,
        Echo=function(message) s.messages[#s.messages+1]=message end,
    }
    if options.missingAPI then spring.UnitIconSetDraw=nil end
    local gl = setmetatable({
        CreateShader=function(spec)
            assert(spec.vertex:find('gl_Position') and spec.fragment:find('fragColor'))
            s.shaderAttempted=true
            if not options.shaderFailure then return 1 end
        end,
        GetShaderLog=function() return 'test shader failure' end,
        GetUniformLocation=function() return 0 end,
        CreateList=function(fn) fn(); s.lists=s.lists+1; return s.lists end,
        DeleteList=function() s.deleted=s.deleted+1 end,
        BeginEnd=function(_,fn,...) fn(...) end,
        Vertex=function() s.vertices=s.vertices+1 end,
        CallList=function() s.draws=s.draws+1 end,
    }, {__index=function() return noop end})
    local env=setmetatable({gadget={}, Spring=spring, gl=gl,
        GL={QUADS=7}, GG={HouseIconShadowGrids=s.grids},
        UnitDefs={[1]={name='house_western0'}},
        VFS={Include=dofile, LoadFile=read},
        gadgetHandler={IsSyncedCode=function() return false end,
            RemoveGadget=function() s.removed=true end},
    }, {__index=_G})
    local f
    if setfenv then f=assert(loadstring(source)); setfenv(f,env)
    else f=assert(load(source,'house icon renderer','t',env)) end
    f(); s.gadget=env.gadget; s.gadget:Initialize()
    function s:frame() self.gadget:DrawWorldPreUnit(); self.gadget:DrawWorld() end
    function s:geometry()
        self.grids[7]={dx=10,dy=10,dz=10,columns={{x=0,z=0,base=0,mask=1}}}
    end
    return s
end

local s=fixture()
assert(s.shaderAttempted and not s.removed, 'renderer must load with UnitIconSetDraw')
s:frame()
assert(s.drawIcon and s.draws==0, 'keep regular icon while geometry is unavailable')
s:geometry(); s:frame()
assert(not s.drawIcon and s.draws==1 and s.vertices==24, 'zoomed-out house must draw its voxel mesh')
s:frame()
assert(not s.drawIcon and s.draws==2 and s.lists==1, 'retain mesh and icon suppression across frames')
s.icon=false; s:frame()
assert(s.drawIcon and s.draws==2, 'zooming in must restore ordinary rendering')
s.icon=true; s:frame()
assert(not s.drawIcon and s.draws==3, 'zooming out must reactivate hologram')
s.enabled=0; s:frame()
assert(s.drawIcon and s.draws==3, 'option off must restore icon')
s.enabled=1; s:frame(); s.hidden=true; s:frame()
assert(s.drawIcon and s.draws==4, 'hidden GUI must stop the hologram')
s.hidden=false; s:frame(); s.los=false; s:frame()
assert(s.drawIcon and s.draws==5, 'LOS loss must stop the hologram')
s.los=true; s:frame(); s.cloaked=true; s:frame()
assert(s.drawIcon and s.draws==6, 'cloaking must stop the hologram')
s.cloaked=false; s:frame(); s:geometry(); s:frame()
assert(s.lists==2 and s.deleted==1, 'changed geometry must replace the cached mesh')
s.gadget:Shutdown()
assert(s.drawIcon and s.deleted==2, 'shutdown must restore icon and release meshes')

local missing=fixture({missingAPI=true})
assert(missing.removed and not missing.shaderAttempted and missing.drawIcon)
assert(missing.messages[1]:find('Spring.UnitIconSetDraw',1,true), 'missing API must produce a diagnostic')
local failed=fixture({shaderFailure=true})
assert(failed.removed and failed.drawIcon and failed.messages[1]:find('Shader failed',1,true))
print('house icon hologram lifecycle: passed')
