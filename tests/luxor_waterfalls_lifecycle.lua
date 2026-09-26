-- Run from repository root with Lua 5.1 or lupa.lua51.
local rules, shown, draws = {}, {}, {}
local frame, fullView, inLos, noDraw, cloaked, dead = 30, false, true, false, false, false
local map = {base1=1,base2=2,base3=3,base4=4,Plate=5}
local nextPiece = 10
piece=function(name)
    if not map[name] then nextPiece=nextPiece+1;map[name]=nextPiece end
    return map[name]
end
include=function()end
GG={};script={};unitID=100
getGameConfig=function()return {}end
Spring={
    GetUnitPieceList=function()return {}end,GetUnitPieceMap=function()return map end,
    SetUnitRulesParam=function(id,k,v,scope)assert(scope.inlos);rules[k]=v end,
    GetUnitRulesParam=function(id,k)return rules[k]end,
    GetVisibleUnits=function(team,radius,icons)assert(icons==false);return {100,200}end,
    GetUnitDefID=function(id)return id==100 and 4 or 1 end,
    GetSpectatingState=function()return false,fullView end,GetMyAllyTeamID=function()return 0 end,
    GetUnitLosState=function()return {los=inLos}end,
    GetUnitNoDraw=function()return noDraw end,GetUnitIsCloaked=function()return cloaked end,
    GetUnitIsDead=function()return dead end,
    GetGameFrame=function()return frame end,GetFrameTimeOffset=function()return .5 end,
    GetCameraPosition=function()return 0,0,500 end,Echo=function()end,
}
showT=function(t)for _,p in ipairs(t)do shown[p]=true end end
hideT=function(t)for _,p in ipairs(t)do shown[p]=nil end end
Turn=function()error('waterfall meshes must not flip')end
StartThread=function()error('waterfall setup must not create a polling thread')end

dofile('scripts/house_asian_comb_script.lua')
TablesOfPieceGroups={PlateWater={31,32,33,34},base1Water={41},base2Water={51,52,53,54},base3Water={61,62}}
for _,variant in ipairs({base1,base2,base3,base4})do
    base=variant;ToShowTable={};shown={};rules={}
    setupWaterfalls();showHouse()
    local count=variant==base1 and 5 or (variant==base2 and 8 or 6)
    assert(rules.luxor_waterfall_count==count and #ToShowTable==count)
    for i=1,count do assert(shown[rules['luxor_waterfall_piece_'..i]])end
    hideHouse();assert(not next(shown) and rules.luxor_waterfall_visible==0)
    showHouse();assert(rules.luxor_waterfall_visible==1)
end

local removed, deleted, attrib, matrices, blend, depthWrite = 0,0,0,0
local noop=function()end
gadget={};gadgetHandler={IsSyncedCode=function()return false end,RemoveGadget=function()removed=removed+1 end}
UnitDefNames={house_asian4={id=4}};Game={gameSpeed=30};GL={ALL_ATTRIB_BITS=1,LEQUAL=2}
VFS={LoadFile=function(path)local f=assert(io.open(path));local s=f:read('*a');f:close();return s end}
gl={CreateShader=function()return 7 end,GetUniformLocation=function(s,n)return n end,
    DeleteShader=function()deleted=deleted+1 end,GetShaderLog=function()return 'test failure'end,
    PushAttrib=function()attrib=attrib+1 end,PopAttrib=function()attrib=attrib-1 end,
    PushMatrix=function()matrices=matrices+1 end,PopMatrix=function()matrices=matrices-1 end,
    DepthTest=noop,DepthMask=function(v)depthWrite=v end,Blending=function(v)blend=v end,
    Culling=noop,PolygonOffset=noop,Texture=noop,UseShader=noop,UniformMatrix=noop,
    Uniform=noop,GetSun=function()return .5,.5,.5 end,UnitMultMatrix=noop,UnitPieceMultMatrix=noop,
    UnitPiece=function(id,p)assert(id==100 and blend==false and depthWrite);draws[#draws+1]=p end,
}
local function loadRenderer()
    gadget={};dofile('luarules/gadgets/gfx_luxor_waterfalls.lua');gadget:Initialize()
end
local function renderCount()
    draws={};gadget:DrawWorld();assert(attrib==0 and matrices==0,'GL state stack leaked');return #draws
end
loadRenderer();assert(renderCount()==6)
hideHouse();assert(renderCount()==0,'hidden waterfall rendered');showHouse()
inLos=false;assert(renderCount()==0,'waterfall revealed in fog of war')
fullView=true;assert(renderCount()==6,'full-view spectator lost waterfall');fullView=false;inLos=true
noDraw=true;assert(renderCount()==0);noDraw=false
cloaked=true;assert(renderCount()==0);cloaked=false
dead=true;assert(renderCount()==0);dead=false
-- Destroy/reuse an ID: incomplete rules must not resurrect cached old pieces.
gadget:UnitDestroyed(100)
local saved=rules.luxor_waterfall_piece_6;rules.luxor_waterfall_piece_6=nil
assert(renderCount()==0);rules.luxor_waterfall_piece_6=saved;assert(renderCount()==6)
gadget:Shutdown();assert(deleted==1 and renderCount()==0)
loadRenderer();assert(renderCount()==6,'reload failed to recover existing water');gadget:Shutdown()
gl.CreateShader=function()return nil end
loadRenderer();assert(removed==1 and renderCount()==0)
assert(shown[31] and shown[61],'shader failure hid fallback meshes')
print('PASS: all Luxor variants, no flip threads, building hide/show, local LOS/spectator, noDraw/cloak/death, ID reuse, incomplete metadata, reload, shader-failure fallback, opaque draw state and cleanup')
