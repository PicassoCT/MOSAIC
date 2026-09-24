-- Reproduce unit_script.lua: prepend the production header to scripts AND
-- cached include chunks, then execute each in its own unit environment.
local function read(path)local f=assert(io.open(path));local s=f:read('*a');f:close();return s end
local header=CLOUD_TEST_HEADER or read('gamedata/unit_script_header.lua')
local cache,records,shown,lights={},{},{},{}
local defs={[1]={name='cloud unit',customParams={cloud_piece_volumes=1}},[2]={customParams={}}}
local function makeUnit(id,kind,enabled)
    local map=kind=='pump' and {Smoke1=1,Explosion1=2,FlameA1=3,Tank=4}
        or {ArenaSmoke=1,GroundGases=2,LaunchCone=3,SpaceHarbour=4}
    local env={unitID=id,unitDefID=enabled and 1 or 2,UnitDefs=defs,script={}}
    setmetatable(env,{__index=_G});env._G=env
    local function key(p)return id..':'..p end
    local rawShow=function(p)shown[key(p)]=true end
    local rawHide=function(p)shown[key(p)]=nil end
    env.Spring={GetUnitDefID=function()return 1 end,GetUnitTeam=function()return 0 end,GetUnitPieceMap=function()return map end,
        Echo=function()end,UnitScript={Show=rawShow,Hide=rawHide}}
    env.GG={CloudVolume={SetPiece=function(u,p,preset)records[u..':'..p]=preset;return true end,
            RemovePiece=function(u,p)records[u..':'..p]=nil end},
        SetObjectiveRadiancePieceVisible=function(u,p,on)lights[u..':'..p]=on end}
    env.VFS={Include=function(path)return dofile(path)end}
    env.include=function(name)
        local chunk=cache[name] or assert(loadstring(header..'\n'..read('scripts/'..name),name))
        cache[name]=chunk;setfenv(chunk,env);return chunk()
    end
    local source=[[
include('lib_UnitScript.lua')
include('lib_radiance_emitters.lua')
local clouds=include('lib_cloud_pieces.lua')(KIND)
function script.direct(p,on) if on then Show(p) else Hide(p) end end
function script.groups(p,on) if on then showT(p) else hideT(p) end end
function script.radiance(p,on) if on then ShowRadiancePieces(p) else HideRadiancePieces(p) end end
function script.all(on) if on then showAll() else hideAll() end end
function script.shutdown()clouds.Shutdown()end
]]
    env.KIND=kind
    if not enabled then source='script.show=Show;script.hide=Hide' end
    local chunk=assert(loadstring(header..'\n'..source));setfenv(chunk,env);chunk()
    return env,key,rawShow,rawHide
end
local a,ka=makeUnit(10,'pump',true)
local b,kb=makeUnit(20,'spaceport',true)
for _,case in ipairs({{a,ka},{b,kb}})do
    local e,k=unpack(case)
    e.script.direct(1,true)
    assert(records[k(1)] and not shown[k(1)],'header-local Show bypassed cloud hook')
    e.script.direct(1,false);assert(not records[k(1)])
    e.script.groups({1,2,3,4},true)
    for i=1,3 do assert(records[k(i)] and not shown[k(i)],'included group helper bypassed hook')end
    assert(shown[k(4)] and not records[k(4)],'structural mesh hidden')
    e.script.groups({1,2,3,4},false)
    e.script.radiance({1,2,3},true)
    for i=1,3 do assert(lights[k(i)] and records[k(i)] and not shown[k(i)])end
    e.script.radiance({1,2,3},false)
    e.script.all(true);assert(records[k(1)] and shown[k(4)])
    e.script.all(false);assert(not records[k(1)] and not shown[k(4)])
    e.script.direct(1,true);e.script.shutdown();assert(not records[k(1)])
end
local ordinary,_,rawShow,rawHide=makeUnit(30,'pump',false)
assert(ordinary.script.show==rawShow and ordinary.script.hide==rawHide,'non-cloud unit gained dispatch overhead')
print('PASS: header-local calls, real included group/radiance helpers, cached includes across units, hideAll/showAll, shutdown, ordinary direct path')
