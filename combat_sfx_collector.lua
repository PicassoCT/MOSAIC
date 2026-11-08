-- Actual production collector. Unchanged tank/laser/pyro submodules are stubs;
-- new policy, event queues, projectile loops and budget selection execute here.
local frame,draw,zoom,seen,inView=100,1,100,true,true
local projectiles={}
Game={gameSpeed=30};UnitDefs={}
WeaponDefs={
    [1]={name='mg',type='Cannon',customParams={night_tracer=1}},
    [2]={name='mortar',type='Cannon'},
    [3]={name='rocket',type='MissileLauncher'},
    [4]={name='railgun',type='Cannon',customParams={railgun_wake=1}},
    [5]={name='ordinary',type='Cannon'},
}
WeaponDefNames={s16rocket={id=3},supportmortar={id=2}}
Spring={
    GetGameFrame=function() return frame end,GetDrawFrame=function() return draw end,
    GetFrameTimeOffset=function() return 0 end,GetCameraPosition=function() return 0,zoom,0 end,
    GetSpectatingState=function() return false,false end,GetMyAllyTeamID=function() return 0 end,
    IsPosInLos=function() return seen end,GetUnitLosState=function() return {los=seen} end,
    ValidUnitID=function() return true end,GetUnitIsDead=function() return false end,
    GetUnitIsCloaked=function() return false end,GetUnitNoDraw=function() return false end,
    GetUnitTransporter=function() end,GetGroundHeight=function() return 0 end,
    GetUnitPosition=function() return 0,10,0 end,
    GetUnitRulesParam=function() end,IsSphereInView=function() return inView end,
    GetVisibleProjectiles=function() local r={};for id in pairs(projectiles) do r[#r+1]=id end;return r end,
    GetProjectileDefID=function(id) return projectiles[id] end,
    GetProjectilePosition=function(id) if projectiles[id] then return id%100,20,0 end end,
    GetProjectileVelocity=function() return 3,0,0 end,
}
local noop=function() end
VFS={Include=function(path)
    if path:find('pyro_flame_collision',1,true) then return function() return {} end end
    if path:find('pyro_flame_budget',1,true) then return function() return {Collect=noop,lastStats={}} end end
    if path:find('tank_muzzle_flash',1,true) then return {ActiveFrame=noop,Collect=noop} end
    if path:find('aiming_laser_glow',1,true) then return {New=function()
        return {UnitCreated=noop,UnitDestroyed=noop,Collect=function() return {} end}
    end} end
    return dofile(path)
end}
local P=dofile('luaui/widgets_mosaic/include/combat_sfx_policy.lua')
local M=dofile('luaui/widgets_mosaic/include/combat_light_sources.lua')
local conf={};for i=1,5 do conf[i]={life=12,radius=100,r=1,g=.5,b=.1,orgMult=1} end
local s=M.New(conf)
local function collect()
    draw=draw+1
    return s:Collect()
end
projectiles={[10]=1,[11]=3,[12]=4}
s:Update(.1)
local lights,flames,tracers=collect()
assert(#tracers==1 and #lights==2 and #flames==1,'tracer still owns a moving light')
assert(flames[1].direction[1]==-1,'missile tail points forward')
zoom=12000
lights,flames,tracers=collect()
assert(#tracers==1 and #lights==1 and #flames==0,'Low survived zoom-out or cheap tracer disappeared')
assert(lights[1].priority=='High','railgun lost strategic lighting')
s:AddExplosion(0,0,0,P.stickyEvent,false,50)
s:AddExplosion(50,10,0,P.empEvent,false,51)
s:AddExplosion(10,0,0,2,false,52)
lights,flames,tracers=collect()
assert(#lights==3 and #flames==3 and #tracers==1,'High bridge event did not reach shared collectors')
for _,r in ipairs(flames) do assert(r.priority=='High') end
-- Turning away suppresses High and Low lighting; engine bullets stay independent.
inView=false;lights,flames=collect();assert(#lights==0 and #flames==0)
inView=true;seen=false;lights,flames,tracers=collect()
assert(#lights==0 and #flames==0 and #tracers==0,'hidden source leaked')
seen=true;zoom=100;frame=200;s:Update(.1)
projectiles={};s:Update(.1)
s:AddExplosion(0,0,0,2,false,8)
s:AddExplosion(40,15,0,1,true,9)
s:AddExplosion(41,15,0,1,false,9)
lights,flames,tracers=collect()
assert(#lights==2 and #flames==1 and #tracers==0,'near mortar/gun pulse duplicated or absent')
zoom=12000;lights,flames=collect();assert(#lights==0 and #flames==0)
-- Low events cannot overwrite 128 retained High railgun flashes.
zoom=100;frame=300;s=M.New(conf)
for i=1,128 do s:AddExplosion(i,10,0,4,true,3) end
for i=1,500 do s:AddExplosion(i%100,10,0,5,true,3) end
local n=0;for _,r in pairs(s.transient) do n=n+1;assert(r.priority=='High') end
assert(n==128 and #collect()==96,'shared light budget or protected retention failed')
-- Missile cap is enforced before ribbon construction and existing 64 tracker cap.
frame=500;s=M.New(conf)
for id=1,1000 do projectiles[id]=3 end
s:Update(.1);lights,flames,tracers=collect()
assert(#s.projectiles==64 and #lights==8 and #flames==8)
zoom=12000;lights,flames=collect();assert(#lights==0 and #flames==0)
-- Projectile ID reuse cannot inherit a rocket exhaust.
zoom=100;projectiles={[1]=1};lights,flames=collect();assert(#flames==0)
print('PASS: production collector integration; cheap tracers survive orbit; no per-bullet lights; near-only rocket/mortar/gun detail; High events/railgun; LOS/frustum; caps; ID reuse')
