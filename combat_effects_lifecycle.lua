-- Run from repository root: texlua tests/combat_effects_lifecycle.lua
unpack=unpack or table.unpack
local frame,drawFrame,visible,fullView=0,0,true,false
local projectiles,dead,rules={},false,{}
local projectileQueries=0
Game={gameSpeed=30,mapSizeX=4096,mapSizeZ=4096}
WeaponDefs={
    {name='tankcannon',type='Cannon',damageAreaOfEffect=80,visuals={}},
    {name='molotow',type='Cannon',damageAreaOfEffect=50,visuals={}},
    {name='flamethrower',type='Flame',damageAreaOfEffect=20,visuals={}},
}
UnitDefs={[1]={name='vehiclecorpse'},[2]={name='tankcorpse'}}
Spring={
    GetGameFrame=function() return frame end,GetDrawFrame=function() return drawFrame end,
    GetFrameTimeOffset=function() return .5 end,GetCameraPosition=function() return 0,20,0 end,
    GetSpectatingState=function() return fullView,fullView end,GetMyAllyTeamID=function() return 0 end,
    IsPosInLos=function() return visible end,GetUnitLosState=function() return {los=visible} end,
    GetVisibleProjectiles=function()
        projectileQueries=projectileQueries+1;local result={};for id in pairs(projectiles) do result[#result+1]=id end;return result
    end,
    GetProjectileDefID=function(id) return projectiles[id] end,
    GetProjectilePosition=function(id) if projectiles[id] then return id,10,50 end end,
    GetProjectileVelocity=function() return 4,2,0 end,
    ValidUnitID=function() return not dead end,GetUnitIsDead=function() return dead end,
    GetUnitIsCloaked=function() return false end,GetUnitNoDraw=function() return false end,
    GetUnitTransporter=function() end,GetUnitRulesParam=function(_,key) return rules[key] end,
    GetUnitPiecePosDir=function() return 100,5,100 end,
    GetUnitPosition=function() return 100,0,100 end,GetUnitViewPosition=function() return 105,0,100 end,
    GetGroundHeight=function() return 0 end,
    IsSphereInView=function() return true end,GetWind=function() return 1,0,1 end,
}
local M=dofile('luaui/widgets_mosaic/include/combat_light_sources.lua')
local conf={[1]={life=10,radius=100,r=1,g=.5,b=.1,orgMult=1}}
local s=M.New(conf)
for i=1,1000 do s:AddExplosion(i,0,0,1,false) end
local function count(t) local n=0;for _ in pairs(t) do n=n+1 end;return n end
assert(count(s.transient)==128,'unbounded light queue')
frame=30;s:Update(.01)
assert(count(s.transient)==0,'expiry depended on renderer/cascade being enabled')

s:UnitCreated(7,1);s:UnitCreated(8,999)
assert(count(s.wrecks)==1)
rules.mosaic_fire_piece=2;rules.mosaic_fire_until=100
drawFrame=drawFrame+1
local lights,flames=s:Collect()
assert(#lights==1 and #flames==1 and lights[1].x==105,'wreck emitter did not follow view transform')
assert(not lights[1].nightOnly and flames[1].emission[1]>1)
dead=true;drawFrame=drawFrame+1;assert(#s:Collect()==0,'dead wreck retained fire')
dead=false;s:UnitDestroyed(7)

s:SetFire(1,200,0,200,30,480)
s:SetFire(129,0,0,0,30,480)
assert(count(s.fires)==1,'fire ring accepted unbounded IDs')
drawFrame=drawFrame+1;lights,flames=s:Collect()
assert(#lights==1 and #flames==1 and not lights[1].nightOnly,'daylight ground fire missing')
visible=false;drawFrame=drawFrame+1;assert(#s:Collect()==0,'fire leaked across LOS loss')
fullView=true;drawFrame=drawFrame+1;assert(#s:Collect()==1,'full-view spectator lost fire')
fullView=false;visible=true
frame=480;s:Update(.1);drawFrame=drawFrame+1;assert(#s:Collect()==0,'Molotov outlived gameplay fire')

projectiles={[31]=2,[32]=3,[33]=1};s:Update(.1);drawFrame=drawFrame+1
lights,flames=s:Collect();assert(#lights==3 and #flames==2,'Molotov/Flame weapon integration missing')
assert(lights[1].x==33 and lights[1].y==11,'projectile render interpolation missing')
local scans=projectileQueries
s:Collect();s:Collect();s:Update(.01)
assert(projectileQueries==scans,'projectile discovery runs per capture instead of 10 Hz')
projectiles[31]=1;drawFrame=drawFrame+1
lights,flames=s:Collect();assert(#lights==2 and #flames==1,'reused projectile ID inherited a flame')
projectiles={};drawFrame=drawFrame+1;assert(#s:Collect()==0,'destroyed projectiles left light')
for i=1,200 do projectiles[i]=2 end
s:Update(.1);drawFrame=drawFrame+1;lights,flames=s:Collect()
assert(#s.projectiles==64 and #lights==64)
for i=1,128 do s:SetFire(i,i,0,0,frame,frame+100) end
drawFrame=drawFrame+1;assert(#s:Collect()==96,'render light budget exceeded')

-- Production point-light renderer: no allocation APIs are even supplied.
local gains,deleted={},0
GL={ONE=1,QUADS=7,TRIANGLE_STRIP=5,ALL_ATTRIB_BITS=1,ONE_MINUS_SRC_ALPHA=2}
gl=setmetatable({
    CreateShader=function() return 1 end,GetUniformLocation=function(_,name) return name end,
    Uniform=function(name,value) if name=='strength' then gains[#gains+1]=value end end,
    BeginEnd=function(_,fn,...) fn(...) end,DeleteShader=function() deleted=deleted+1 end,
}, {__index=function() return function() end end})
VFS={LoadFile=function() return '' end};WG={GetVehicleLightOcclusion=function() return 9 end}
local mixed={Collect=function() return {
    {x=50,y=5,z=50,radius=100,color={1,.5,.1},strength=1,nightOnly=true},
    {x=100,y=5,z=100,radius=100,color={1,.3,.05},strength=1,nightOnly=false},
} end}
local renderer=assert(dofile('luaui/widgets_mosaic/include/combat_light_renderer.lua')(mixed))
renderer:Capture(0,128,1,0);assert(#gains==1 and gains[1]==1,'daylight weapon flash/fire gating')
gains={};renderer:Capture(0,128,.08,.5)
assert(#gains==2 and gains[1]==.04 and gains[2]==.08,'cascade spill intensity applied twice')
renderer:Shutdown();assert(deleted==1)

-- Real FlamePainter renderer accepts world/projectile records without unit APIs.
local drawn,drift=0
gl.CreateList=function(fn) fn();return 1 end
gl.CallList=function() drawn=drawn+1 end
gl.GetSun=function() return .3,.3,.3 end
gl.Uniform=function(name,...) if name=='directionalDrift' then drift={...} end end
local ribbon=assert(dofile('luarules/gadgets/include/smoke_ribbon_renderer.lua')())
projectiles={[31]=2};s=M.New(conf);s:Update(.1);drawFrame=drawFrame+1
lights,flames=s:Collect();ribbon:Draw(flames)
assert(drawn==1 and drift[1]<0,'moving FlamePainter trail does not follow projectile')
visible=false;ribbon:Draw(flames);assert(drawn==1,'FlamePainter bypassed LOS')
ribbon:Shutdown()
print('PASS: bounded queues, independent expiry, wreck lifecycle, Molotov/Flame trails, LOS, interpolation, 10 Hz discovery, shared captures and FlamePainter')
