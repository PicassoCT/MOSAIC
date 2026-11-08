-- texlua tests/vehicle_wreck_flames.lua (also Lua 5.1 compatible)
-- Real car script publication + real combat source collection; unrelated
-- Cinder and tank-muzzle modules are deliberately isolated fixtures.
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
assert(rules.mosaic_fire_broad==1 and rules.mosaic_fire_piece==2)
assert(rules.mosaic_fire_flames==nil,'obsolete flame-count parameter is still published')
assert(math.abs(rules.mosaic_fire_until-26.1)<.0001,'original burn deadline changed')

local parameters={[7]=rules}
local reserved,cinderExtras=0,0
VFS={Include=function(path)
    if path:match('pyro_flame_collision.lua$') then return function() return {} end end
    if path:match('pyro_flame_budget.lua$') then return function()
        return {Collect=function(_,context)
            reserved=context.otherRibbons
            for i=1,cinderExtras do
                context.extraFlames[#context.extraFlames+1]={ribbon={fixture='cinder'},d2=i}
            end
        end}
    end end
    if path:match('tank_muzzle_flash.lua$') then return {} end
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
local viewX,viewY,viewZ=105,0,100
Spring.GetUnitViewPosition=function() return viewX,viewY,viewZ end
Spring.GetUnitVectors=function() error('single wreck flame must not query heading for siblings') end
Spring.GetUnitRulesParam=function(id,key) return parameters[id] and parameters[id][key] end
local M=dofile('luaui/widgets_mosaic/include/combat_light_sources.lua')
local source=M.New({});source:UnitCreated(7,1)
local function collect(s) draw=draw+1;return (s or source):Collect() end
local function near(a,b,label) assert(math.abs(a-b)<1e-8,label) end
local function broad(f)
    assert(f.length==90 and f.width==20 and f.scale==1,'broad flame dimensions changed')
    assert(f.direction[1]==0 and f.direction[2]==1 and f.direction[3]==0,'flame does not rise vertically')
    assert(f.speed==3 and f.strands==4 and f.curl==.28 and f.windInfluence==.18,'upward-column tuning changed')
    assert(f.trailTime==.7 and f.emission[1]==3.5 and f.emission[2]==.35 and f.sourceGlow[4]==.55)
end
frame=10
local lights,flames=collect()
assert(#lights==1 and #flames==1 and reserved==1,'wreck must reserve and collect exactly one flame')
broad(flames[1]);assert(flames[1].opacity==1)
assert(lights[1].x==105 and lights[1].y==9 and lights[1].z==100,'radiance anchor changed')
assert(flames[1].x==105 and flames[1].y==9 and flames[1].z==100,'flame anchor changed')
assert(lights[1].radius==100 and not lights[1].nightOnly,'radiance radius/daylight changed')
local originalLight=lights[1]
local seed=flames[1].seed
rules.mosaic_fire_broad=nil;lights,flames=collect()
assert(#flames==1 and flames[1].length==45 and flames[1].width==12,'unmarked wreck preset changed')
for _,key in ipairs({'x','y','z','radius','strength','nightOnly'}) do
    assert(lights[1][key]==originalLight[key],'broad flame changed radiance '..key)
end
for i=1,3 do assert(lights[1].color[i]==originalLight.color[i],'radiance colour changed') end
rules.mosaic_fire_broad=1
-- Old snapshots cannot recreate the removed sibling fanout, regardless of count.
for _,count in ipairs({3,1000,math.huge}) do
    rules.mosaic_fire_flames=count;lights,flames=collect()
    assert(#flames==1 and reserved==1,'legacy count recreated siblings');broad(flames[1])
end
rules.mosaic_fire_flames=nil
viewX,viewY,viewZ=115,3,108
lights,flames=collect();broad(flames[1])
assert(flames[1].x==115 and flames[1].y==12 and flames[1].z==108,'interpolated wreck movement lost')
assert(flames[1].seed==seed,'moving wreck changed animation seed')
local cachedLights,cachedFlames=source:Collect()
assert(cachedLights==lights and cachedFlames==flames,'same draw rebuilt the flame')
viewX,viewY,viewZ=105,0,100
local restarted=M.New({});restarted:UnitCreated(7,1)
local _,restored=collect(restarted);assert(#restored==1,'renderer reload changed flame count');broad(restored[1])
for _,condition in ipairs({'hidden','dead','cloaked','transported'}) do
    visible=condition~='hidden';dead=condition=='dead';cloaked=condition=='cloaked';transported=condition=='transported'
    lights,flames=collect();assert(#lights==0 and #flames==0,condition..' wreck retained fire')
end
visible=false;dead=false;cloaked=false;transported=false;full=true
lights,flames=collect();assert(#flames==1,'full-view spectator lost wreck');broad(flames[1])
full=false;visible=true
frame=rules.mosaic_fire_until-7.5;lights,flames=collect()
near(flames[1].opacity,.5,'original end-of-burn fade changed')
frame=rules.mosaic_fire_until;lights,flames=collect()
assert(#lights==0 and #flames==0,'broad flame outlived original burn phase')
frame=10;source:UnitDestroyed(7);lights,flames=collect();assert(#flames==0)
parameters[8]={mosaic_fire_piece=2,mosaic_fire_until=100}
source:UnitCreated(8,2);lights,flames=collect()
assert(#lights==1 and #flames==1 and reserved==1,'tank flame count changed')
assert(flames[1].length==67.5 and flames[1].width==18 and flames[1].speed==2.2,'tank wreck size/speed changed')
assert(flames[1].curl==.65 and flames[1].windInfluence==.45 and flames[1].strands==3,'tank wreck appearance changed')
source:UnitDestroyed(8)
source:SetFire(1,20,0,20,0,100);lights,flames=collect()
assert(#lights==1 and #flames==1,'ordinary ground fire count changed')
near(flames[1].length,49.5,'ordinary ground fire length changed')
near(flames[1].width,13.2,'ordinary ground fire width changed')
assert(flames[1].speed==2.2 and flames[1].strands==3,'ground fire inherited car tuning')
source=M.New({})
for id=1,60 do parameters[id]=rules;source:UnitCreated(id,1) end
lights,flames=collect()
assert(#lights==60 and #flames==60 and reserved==60,'massed wrecks created extra flames')
for _,f in ipairs(flames) do broad(f) end
-- Cinder still owns extraFlames; removing car siblings must not remove its jets.
cinderExtras=8;lights,flames=collect()
local extras=0;for _,f in ipairs(flames) do if f.fixture=='cinder' then extras=extras+1 end end
assert(#lights==60 and #flames==64 and extras==4,'Cinder extras or shared allowance changed')
cinderExtras=0
for id=61,200 do parameters[id]=rules;source:UnitCreated(id,1) end
lights,flames=collect()
assert(#lights==M.maxLights and #flames==#lights,'light budget or one-flame-per-retained-wreck changed')
print('PASS: car-only single broad upward flame, retained smoke/explosion/burn cadence, unchanged radiance, stable seed/view interpolation/cache/reload, visibility/fade/expiry, tank/ground isolation, ignored legacy counts and shared Cinder budget')
