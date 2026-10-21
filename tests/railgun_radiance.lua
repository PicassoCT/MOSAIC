-- Run from repository root: lua5.1 tests/railgun_radiance.lua
unpack=unpack or table.unpack
local function loadIn(path,env)
    local chunk=setfenv and setfenv(assert(loadfile(path)),env) or assert(loadfile(path,'t',env))
    return chunk()
end
local function lowerkeys(t)
    local out={};for k,v in pairs(t) do out[k:lower()]=v end;return out
end
local weaponEnv=setmetatable({lowerkeys=lowerkeys},{__index=_G})
local rail=loadIn('weapons/railgun.lua',weaponEnv).railgun
local orbital=loadIn('weapons/orbitalRailgun.lua',weaponEnv).orbitalrailgun
assert(rail.customParams.railgun_wake==1 and orbital.customParams.railgun_wake==1)
assert(rail.customParams.wall_damage_multiplier==.5 and rail.reloadtime==35 and orbital.burst==2,
    'railgun visual profile changed gameplay')
local cegs=dofile('gamedata/explosions/railGunCeg.lua')
assert(not cegs.railgunceg.tealflash,'duplicate groundflash survived radiance replacement')
assert(cegs.railgunceg.trail.properties.explosiongenerator=='custom:GAUSS_RING_H'
    and cegs.railgunceg.trail2.properties.explosiongenerator=='custom:GAUSS_RING_S',
    'existing expanding rings were removed')
assert(cegs.gauss_ring_h.tealring.properties.ttl==23 and cegs.gauss_ring_s.tealring2.properties.ttl==23)

local frame,drawFrame=100,0
local visible,fullView,cloaked,dead=true,false,false,false
local rules,projectiles={},{}
Game={gameSpeed=30,mapSizeX=4096,mapSizeZ=4096}
WeaponDefs={
    {name='railgun',type='Cannon',damageAreaOfEffect=160,customParams=rail.customParams,visuals={}},
    {name='orbitalrailgun',type='Cannon',damageAreaOfEffect=16,customParams=orbital.customParams,visuals={}},
    {name='tankcannon',type='Cannon',damageAreaOfEffect=80,customParams={},visuals={}},
}
UnitDefs={[1]={name='nimrod'},[2]={name='unrelated'}}
Spring={
    GetGameFrame=function() return frame end,GetDrawFrame=function() return drawFrame end,
    GetFrameTimeOffset=function() return 0 end,GetCameraPosition=function() return 0,20,0 end,
    GetSpectatingState=function() return fullView,fullView end,GetMyAllyTeamID=function() return 0 end,
    IsPosInLos=function() return visible end,GetUnitLosState=function() return {los=visible} end,
    GetVisibleProjectiles=function() local t={};for id in pairs(projectiles) do t[#t+1]=id end;return t end,
    GetProjectileDefID=function(id) return projectiles[id] end,
    GetProjectilePosition=function(id) if projectiles[id] then return id,70,100 end end,
    GetProjectileVelocity=function() return 4,0,0 end,
    ValidUnitID=function(id) return id==7 or id==8 end,GetUnitIsDead=function() return dead end,
    GetUnitIsCloaked=function() return cloaked end,GetUnitNoDraw=function() return false end,
    GetUnitTransporter=function() end,GetUnitRulesParam=function(_,key) return rules[key] end,
    GetUnitPosition=function() return 100,20,100 end,GetGroundHeight=function() return 20 end,
    IsSphereInView=function() return true end,GetWind=function() return 0,0,0 end,
}
local M=dofile('luaui/widgets_mosaic/include/combat_light_sources.lua')
local conf={}
for i=1,3 do conf[i]={life=90,radius=100,r=1,g=.5,b=.1,orgMult=1} end
local s=M.New(conf)
local function collect()
    drawFrame=drawFrame+1
    return s:Collect()
end
local function byX(lights,x) for _,l in ipairs(lights) do if l.x==x then return l end end end
local function count(t) local n=0;for _ in pairs(t) do n=n+1 end;return n end
s:AddExplosion(10,50,0,1,true,7)
s:AddExplosion(20,50,0,2,false,7)
s:AddExplosion(30,50,0,3,false,7)
local lights=collect()
local muzzle,impact,ordinary=byX(lights,10),byX(lights,20),byX(lights,30)
assert(muzzle and impact and ordinary and #lights==3)
assert(not muzzle.nightOnly and not impact.nightOnly and ordinary.nightOnly,
    'daytime railgun profile altered other weapons')
assert(muzzle.unitID==7 and impact.unitID==nil and ordinary.unitID==nil,
    'owner exclusion escaped railgun muzzle or was lost')
assert(muzzle.radius==150 and impact.radius==200 and muzzle.color[1]<muzzle.color[2]
    and muzzle.color[2]<muzzle.color[3],'cold cyan profile missing')
assert(ordinary.strength==1 and ordinary.radius==100 and ordinary.color[1]==1,
    'generic combat light profile changed')
frame=106;lights=collect()
assert(byX(lights,10).strength<muzzle.strength*.5,'railgun discharge did not cool quickly')
visible=false;s:AddExplosion(40,50,0,1,true,7)
assert(count(s.transient)==3 and #collect()==0,'owner metadata bypassed positional LOS')
fullView=true;assert(#collect()==3,'full-view spectator lost valid flashes')
fullView=false;visible=true
frame=112;s:Update(.01);lights=collect()
assert(not byX(lights,10) and byX(lights,20),'muzzle lifetime is not 0.4 seconds')
frame=118;s:Update(.01);lights=collect()
assert(#lights==1 and byX(lights,30),'impact outlived its 0.6-second budget')
frame=190;s:Update(.01);assert(#collect()==0,'ordinary expiry regression')

projectiles={[101]=1,[102]=2,[103]=3};s:Update(.1);lights=collect()
assert(#lights==3 and not byX(lights,101).nightOnly and not byX(lights,102).nightOnly
    and byX(lights,103).nightOnly,'moving railgun head used generic night-only lighting')
assert(byX(lights,101).radius==160)
projectiles={};assert(#collect()==0,'destroyed projectile retained radiance')

-- Reconstruct both original deployment pairs from finite, visible timestamps.
s:UnitCreated(7,1);s:UnitCreated(8,2)
assert(s.railguns[7] and not s.railguns[8])
rules.mosaic_railgun_charge_a_frame=300
rules.mosaic_railgun_charge_b_frame=305
frame=300;lights=collect();assert(#lights==2,'future deployment phase leaked')
local heights={};for _,l in ipairs(lights) do heights[l.y]=true;assert(not l.nightOnly and l.unitID==7) end
assert(heights[65] and heights[30],'initial deployment heights changed')
frame=305;lights=collect();assert(#lights==4,'second deployment pair was lost')
heights={};for _,l in ipairs(lights) do heights[l.y]=true end
assert(heights[85] and heights[55],'later deployment heights changed')
cloaked=true;assert(#collect()==0,'charge revealed a cloaked Nimrod')
cloaked=false;visible=false;assert(#collect()==0,'charge crossed LOS')
visible=true;frame=342;assert(#collect()==2,'first deployment pair did not expire')
frame=347;assert(#collect()==0,'deployment light persisted after 42 frames')
s:UnitDestroyed(7);assert(not s.railguns[7])
frame=400
for i=1,500 do s:AddExplosion(i,50,0,1,true,7) end
assert(count(s.transient)==128 and #collect()==96,'railgun bypassed shared light limits')
frame=412;s:Update(.01);assert(count(s.transient)==0,'offscreen railgun expiry required drawing')

-- The real Nimrod script stamps the two phases around its blocking slider move.
local phaseStamps,reveals,cegCalls={},0,0
local function noop() end
local scriptEnv=setmetatable({script={},unitID=7,UnitDefs={},
    include=noop,piece=function(name) return name end,
    getGameConfig=function() return {game={culture='arabic'}} end,
    getCultureUnitModelTypes=function() return {} end,getHologramTypes=function() return {} end,
    WMove=function() frame=frame+7 end,WTurn=noop,Turn=noop,Move=noop,WaitForTurns=noop,
    x_axis=1,y_axis=2,z_axis=3,
    foreach=noop,getAllNearUnit=function() return {} end,
    spawnCegNearUnitGround=function() cegCalls=cegCalls+1 end,
    GG={RevealNimrodOnFire=function(id) assert(id==7);reveals=reveals+1 end},
    Spring={GetUnitDefID=function() return 1 end,SetUnitNanoPieces=noop,
        GetGameFrame=function() return frame end,
        SetUnitRulesParam=function(id,key,value,access)
            assert(id==7 and access.inlos==true and not access.public)
            phaseStamps[key]=value
        end},
},{__index=_G})
loadIn('scripts/nimrodscript.lua',scriptEnv)
frame=500;scriptEnv.goToFireMode()
assert(phaseStamps.mosaic_railgun_charge_a_frame==500
    and phaseStamps.mosaic_railgun_charge_b_frame==507,'deployment timing no longer follows animation')
scriptEnv.script.FireWeapon1();scriptEnv.script.FireWeapon2()
assert(reveals==2 and cegCalls==0,'firing lost reveal gameplay or duplicated CEG light')
print('PASS: cold finite day-visible railgun radiance, owner/LOS isolation, original deployment pairs, shared budgets, preserved rings and unchanged gameplay')
