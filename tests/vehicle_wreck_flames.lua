-- texlua tests/vehicle_wreck_flames.lua (also Lua 5.1 compatible)
-- Real car script publication + real combat source collection; unrelated
-- Cinder, tank-muzzle and trace modules are deliberately isolated fixtures.
local frame,draw,visible,full,dead,cloaked,transported=0,0,true,false,false,false,false
local rules,emitted={},{}
Game={gameSpeed=30};unitID=7;script={}
include=function() end
piece=function(name) return name=='emitfire' and 2 or 1 end
StartThread=function() end
Sleep=function(ms) frame=frame+ms*.03 end
EmitSfx=function(_,code) emitted[code]=(emitted[code] or 0)+1 end
Spring={GetGaiaTeamID=function() return 0 end,GetGameFrame=function() return frame end,
    GetUnitPiecePosDir=function() return 100,5,100 end,
    SetUnitRulesParam=function(_,key,value,visibility)
        assert(visibility.inlos);rules[key]=value
    end}
dofile('scripts/vehicleCorpsescript.lua')
onFire(10,4)
assert(not emitted[1025],'car still emits the recurring flames CEG')
assert(emitted[1024]==3 and emitted[1026]==3 and emitted[1028]==10,'explosion/smoke cadence changed')
assert(rules.mosaic_fire_flames==3 and rules.mosaic_fire_piece==2)
assert(math.abs(rules.mosaic_fire_until-26.1)<.0001,'original burn deadline changed')

local parameters={[7]=rules}
local reserved
VFS={Include=function(path)
    if path:match('pyro_flame_collision.lua$') then return function() return {} end end
    if path:match('pyro_flame_budget.lua$') then return function()
        return {Collect=function(_,context) reserved=context.otherRibbons end}
    end end
    if path:match('tank_muzzle_flash.lua$') then return {} end
    if path:match('execution_trace.lua$') then return {New=function()
        return {Log=function() end,Forget=function() end}
    end} end
    error('unexpected dependency '..path)
end}
WeaponDefs={};UnitDefs={[1]={name='vehiclecorpse'},[2]={name='tankcorpse'}}
Spring.GetDrawFrame=function() return draw end
Spring.GetFrameTimeOffset=function() return 0 end
Spring.GetCameraPosition=function() return 0,20,0 end
Spring.GetSpectatingState=function() return full,full end
Spring.GetMyAllyTeamID=function() return 0 end
Spring.IsPosInLos=function() return visible end
Spring.GetUnitLosState=function() return {los=visible} end
Spring.ValidUnitID=function() return not dead end
Spring.GetUnitIsDead=function() return dead end
Spring.GetUnitIsCloaked=function() return cloaked end
Spring.GetUnitNoDraw=function() return false end
Spring.GetUnitTransporter=function() return transported and 99 or nil end
Spring.GetUnitPosition=function() return 100,0,100 end
Spring.GetUnitViewPosition=function() return 105,0,100 end
local front={1,0,0}
Spring.GetUnitVectors=function() return front end
Spring.GetUnitRulesParam=function(id,key) return parameters[id] and parameters[id][key] end
local M=dofile('luaui/widgets_mosaic/include/combat_light_sources.lua')
local source=M.New({});source:UnitCreated(7,1)
local function collect(s) draw=draw+1;return (s or source):Collect() end
frame=10
local lights,flames=collect()
assert(#lights==1 and #flames==3 and reserved==3,'three flames were not reserved/collected')
assert(lights[1].x==105 and lights[1].y==9 and lights[1].z==100,'view-space anchor changed')
local seeds,positions={},{}
for _,f in ipairs(flames) do
    assert(f.length==45 and f.width==12 and f.direction[2]==1 and f.opacity==1,'unequal or tiny flame')
    assert(not seeds[f.seed],'correlated sibling animation seeds');seeds[f.seed]=true
    positions[f.x]=true
end
assert(positions[97] and positions[105] and positions[113],'flames do not follow vehicle heading')
local strength=lights[1].strength
rules.mosaic_fire_flames=nil;lights,flames=collect()
assert(#flames==1 and lights[1].strength==strength,'three flames multiplied the radiance light')
rules.mosaic_fire_flames=3
front={0,0,1};lights,flames=collect();positions={}
for _,f in ipairs(flames) do positions[f.z]=true end
assert(positions[92] and positions[100] and positions[108],'rotated wreck offsets were world fixed')
local restarted=M.New({});restarted:UnitCreated(7,1)
local _,restored=collect(restarted);assert(#restored==3,'renderer reload did not restore burning wreck')
for _,condition in ipairs({'hidden','dead','cloaked','transported'}) do
    visible=condition~='hidden';dead=condition=='dead';cloaked=condition=='cloaked';transported=condition=='transported'
    lights,flames=collect();assert(#lights==0 and #flames==0,condition..' wreck retained a sibling')
end
visible=true;dead=false;cloaked=false;transported=false
frame=rules.mosaic_fire_until;lights,flames=collect()
assert(#lights==0 and #flames==0,'siblings outlived original burn phase')
frame=10;source:UnitDestroyed(7);lights,flames=collect();assert(#flames==0)
parameters[8]={mosaic_fire_piece=2,mosaic_fire_until=100}
source:UnitCreated(8,2);lights,flames=collect()
assert(#lights==1 and #flames==1 and flames[1].length==67.5 and flames[1].width==18,'tank wreck changed')
source:UnitDestroyed(8)
source:SetFire(1,20,0,20,0,100);lights,flames=collect()
assert(#lights==1 and #flames==1,'ordinary ground fire inherited car flame count')
source=M.New({})
for id=1,60 do parameters[id]=rules;source:UnitCreated(id,1) end
lights,flames=collect();assert(#lights==60 and #flames==64,'siblings exceeded shared ribbon allowance')
for _,value in ipairs({1000,math.huge}) do
    source=M.New({});rules.mosaic_fire_flames=value;source:UnitCreated(7,1)
    lights,flames=collect();assert(#flames==3,'unbounded rule-param count')
end
print('PASS: car-only CEG removal, unchanged smoke/explosion/burn duration, three equal rotated/interpolated flames, independent seeds, one radiance source, expiry/visibility/reload, tank/ground-fire isolation and bounded siblings')
