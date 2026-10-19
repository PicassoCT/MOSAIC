-- Run from repository root: texlua tests/aiming_laser_radiance.lua
-- No GL context or running Recoil instance required: uses the real collector.
local function near(a,b,label)
    assert(type(a)=='number' and math.abs(a-b)<0.0001,
        (label or 'value')..' expected '..tostring(b)..', got '..tostring(a))
end

WeaponDefs = {
    [3]={name='targetlaser',type='BeamLaser',damageAreaOfEffect=0},
    [4]={name='targetlaseroperative',type='BeamLaser',damageAreaOfEffect=0},
    [5]={name='slowsniperrifle',type='Cannon',damageAreaOfEffect=0},
    [6]={name='targetlaser',type='Cannon',damageAreaOfEffect=0},
}
UnitDefs = {
    [11]={name='air_plane_sniper',weapons={{weaponDef=5},{weaponDef=3}}},
    [12]={name='operativeasset',weapons={{weaponDef=5},{weaponDef=4}}},
    [13]={name='air_plane_other',weapons={{weaponDef=5}}},
}
Game={mapSizeX=8192,mapSizeZ=8192}
local units={}
local projectiles={}
local visibleProjectiles={}
local frame,drawFrame,scanCalls,pointLOS=100,0,0,true
local function unitVisible(id)
    return units[id] and not units[id].hidden and not units[id].cloaked
end
Spring={
    GetGameFrame=function() return frame end,
    GetDrawFrame=function() return drawFrame end,
    GetFrameTimeOffset=function() return .9 end,
    GetCameraPosition=function() return 0,100,0 end,
    GetSpectatingState=function() return false,false end,
    GetMyAllyTeamID=function() return 0 end,
    IsPosInLos=function() return pointLOS end,
    ValidUnitID=function(id) return units[id]~=nil end,
    GetUnitIsDead=function(id) return units[id] and units[id].dead end,
    GetUnitIsCloaked=function(id) return units[id] and units[id].cloaked end,
    GetUnitNoDraw=function(id) return units[id] and units[id].hidden end,
    GetUnitTransporter=function() return nil end,
    GetUnitLosState=function(id) return {los=unitVisible(id)} end,
    GetVisibleProjectiles=function()
        scanCalls=scanCalls+1
        return visibleProjectiles
    end,
    GetProjectileDefID=function(id) return projectiles[id] and projectiles[id].defID end,
    GetProjectileOwnerID=function(id) return projectiles[id] and projectiles[id].owner end,
    GetProjectilePosition=function(id)
        local p=projectiles[id]
        if p then return p.x,p.y,p.z end
    end,
    GetProjectileVelocity=function(id)
        local p=projectiles[id]
        if p then return p.vx,p.vy,p.vz end
    end,
    GetGroundHeight=function() return 0 end,
}
VFS={Include=function(path)
    if path:find('aiming_laser_glow.lua',1,true) then
        return dofile(path)
    end
    if path:find('pyro_flame_collision.lua',1,true) then
        return function() return {} end
    end
    if path:find('pyro_flame_budget.lua',1,true) then
        return function() return {Collect=function() end} end
    end
    if path:find('tank_muzzle_flash.lua',1,true) then
        return {}
    end
    error('unexpected include: '..path)
end}

local Sources=dofile('luaui/widgets_mosaic/include/combat_light_sources.lua')
local fx=Sources.New({})
local function collect()
    drawFrame=drawFrame+1
    local lights=fx:Collect()
    return lights
end
local function beam(id,owner,defID,x,y,z,vx,vy,vz)
    projectiles[id]={owner=owner,defID=defID,x=x,y=y,z=z,vx=vx,vy=vy,vz=vz}
    visibleProjectiles[#visibleProjectiles+1]=id
end
local function resetBeams() visibleProjectiles={} end

-- No laser-equipped units: do not even scan the visible-projectile list.
local lights=collect()
assert(#lights==0 and scanCalls==0,'inactive tracker must be zero-cost')
units[10]={}
fx:UnitCreated(10,13)
lights=collect()
assert(#lights==0 and scanCalls==0,'unrelated combat units must not enable scanning')

units[1]={}
fx:UnitCreated(1,11)
fx:UnitCreated(1,11) -- LOS re-entry should not double-count
beam(101,1,3,50,100,200,100,-90,0)
beam(102,1,5,50,100,200,300,-90,0) -- live sniper bullet, not a laser
lights=collect()
assert(#lights==1,'one sniper laser should emit exactly one radiance light')
local source=lights[1]
local distance=math.sqrt(100*100+90*90)
near(source.x+100*8/distance,150,'red dot endpoint X')
near(source.y-90*8/distance,10,'red dot endpoint Y')
near(source.z,200,'red dot endpoint Z')
near(source.radius,36,'red dot radius')
near(source.strength,1.35,'red dot strength')
assert(source.color[1]==1 and source.color[2]<0.05 and source.color[3]<0.05
    and source.nightOnly==false,'laser light must be red and visible by day')
assert(source.ribbon==nil and source.tracer==nil,'no extra beam, flame or tracer')
assert(source.unitID==nil,'endpoint must use positional LOS, not emitter LOS')

-- Recoil reports hitscan velocity as endpoint displacement, not motion per frame.
-- No interpolation at a fractional draw-frame offset is allowed.
near(source.x,150-100*8/distance,'hitscan displacement must not extrapolate')

pointLOS=false
assert(#collect()==0,'visible owner must not light a hidden endpoint')
pointLOS=true
units[1].cloaked=true
assert(#collect()==0,'cloaked owner must not leak aiming endpoint')
units[1].cloaked=false
assert(#collect()==1,'glow should resume when visible and firing')

-- The latest beam segment wins; shield reflections must not leave
-- a second glow at an intermediate endpoint.
resetBeams()
beam(201,1,3,0,100,0,30,-20,0)
beam(202,1,3,30,80,0,20,-70,0)
lights=collect()
assert(#lights==1 and lights[1].x>40,'last shield-reflected segment should glow')

-- Another supported aiming weapon should glow independently.
units[2]={}
fx:UnitCreated(2,12)
beam(203,2,4,200,100,300,10,-90,0)
lights=collect()
assert(#lights==2,'operative and sniper aiming lasers must coexist')

-- The beam is ephemeral. Losing the projectile removes the dot immediately.
resetBeams()
assert(#collect()==0,'no ghost radiance after a laser stops firing')
fx:UnitDestroyed(1)
fx:UnitDestroyed(1)
fx:UnitDestroyed(2)
fx:UnitDestroyed(10)
assert(#collect()==0,'destroyed owners must not leave light records')
local before=scanCalls
collect()
assert(scanCalls==before,'inactive units must stop projectile scanning')
print('aiming laser radiance: PASS')
