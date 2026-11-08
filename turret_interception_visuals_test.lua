-- Lua 5.1+: execute the real turret animation and interception paths.
local function noop()end
local function loadIn(path, env)
    setmetatable(env,{__index=_G})
    if setfenv then return setfenv(assert(loadfile(path)),env)() end
    return assert(loadfile(path,'t',env))()
end
local function setup()
    local s={projectiles={},deleted={},tracers={},flashes=0,turns={},explosions=0,damage=0}
    local env={include=noop,piece=function(n)return n end,script={},unitID=1,unitDefID=1,
        x_axis=1,y_axis=2,z_axis=3,Game={gameSpeed=30},UnitDefs={{name='ground_turret_mg'}},
        WeaponDefs={},WeaponDefNames={interceptiontracer={id=99}},Spring={},
        getCruiseMissileProjectileTypes=function()return {[12]=true}end,
        getGameConfig=function()return {military={cruiseMissiles={interceptOneIn=10}}}end,
        Signal=noop,WaitForTurns=noop,PlaySoundByUnitDefID=noop}
    env.Spring.GetUnitTeam=function()return 0 end
    env.Spring.UnitScript={GetPieceRotation=function()return 0,0,0 end}
    env.Spring.GetUnitPiecePosDir=function()return 0,10,0 end
    env.Spring.GetUnitVectors=function()return {0,0,1},{0,1,0},{-1,0,0}end
    env.Spring.GetProjectileDefID=function(id)return s.projectiles[id] and s.projectiles[id].def end
    env.Spring.GetProjectilePosition=function(id)
        local p=s.projectiles[id];if p then return p.x,p.y,p.z end
    end
    env.Spring.GetUnitPosition=function(id)if id==44 then return 100,50,0 end end
    env.Spring.DeleteProjectile=function(id)assert(s.projectiles[id]);s.deleted[id]=true;s.projectiles[id]=nil end
    env.Spring.SpawnCEG=function(name)assert(name=='missile_explosion');s.explosions=s.explosions+1 end
    env.Spring.SpawnProjectile=function(def,p)
        assert(def==99 and p.owner==1 and p.ttl>0 and p.gravity==0)
        assert(p.speed[2]>0,'tracer did not aim up at the drone')
        s.tracers[#s.tracers+1]=p
    end
    env.Spring.AddUnitDamage=function(id,damage)assert(id==44 and damage==50);s.damage=s.damage+damage end
    env.EmitSfx=function(piece,effect)assert(piece=='aimpiece' and effect==1025);s.flashes=s.flashes+1 end
    env.Turn=function(piece,axis,angle,speed)
        assert(speed>0 and angle==angle);s.turns[#s.turns+1]={piece,axis,angle}
    end
    env.Sleep=function()if s.onSleep then s.onSleep()end end
    env.StartThread=function(fn,...)
        if fn==env.fireFlowers then return fn(...)end
    end
    loadIn('scripts/ground_turretscript.lua',env)
    s.env=env;return s
end
local s=setup()
s.projectiles[500]={def=11,x=100,y=50,z=0}
s.projectiles[1007]={def=11,x=100,y=50,z=0}
s.env.playProjectileInterceptAnimation({[1007]=11,[500]=11},500,1)
assert(s.deleted[500] and not s.deleted[1007],'sparse target list or cap was mishandled')
assert(#s.tracers==3 and s.flashes==3 and s.explosions==1)
assert(s.turns[1][1]=='center' and s.turns[2][1]=='Turret' and s.turns[2][3]<0)
-- Empty selections never divide by zero or fire.
s=setup();s.env.playProjectileInterceptAnimation({},500,4)
assert(s.flashes==0 and #s.tracers==0)
-- A target which disappears while the burst plays is not exploded again.
s=setup();s.projectiles[500]={def=11,x=100,y=50,z=0}
s.onSleep=function()s.projectiles[500]=nil end
s.env.playProjectileInterceptAnimation({[500]=11},500,1)
assert(s.flashes==1 and #s.tracers==1 and s.explosions==0)
-- Cruise-missile resistance uses the actual weapon ID, not a misspelled global.
s=setup();s.projectiles[500]={def=12,x=100,y=50,z=0}
s.env.math=setmetatable({random=function()return 2 end},{__index=math})
s.env.playProjectileInterceptAnimation({[500]=12},500,1)
assert(not s.deleted[500] and s.flashes==0)
-- Air-drone damage is unchanged; normal firing shares the same muzzle effects.
s=setup();s.env.playDroneInterceptAnimation({[44]=1},500,1)
assert(s.damage==50 and #s.tracers==3 and s.flashes==3)
s=setup();s.env.script.FireWeapon1()
assert(s.flashes==15 and #s.tracers==0)
-- Visual rounds inherit the normal gun's rendering but cannot add damage.
local env={lowerkeys=function(t)return t end,VFS={}}
env.VFS.Include=function(path)return loadIn(path,env)end
local weapons=loadIn('weapons/military_support.lua',env)
local tracer,gun=weapons.interceptiontracer,weapons.covermachinegun
assert(tracer.damage.default==0 and tracer.areaofeffect==0 and tracer.impulsefactor==0)
assert(tracer.cegtag==gun.cegtag and tracer.size==gun.size and tracer.stages==gun.stages)
assert(not tracer.collideenemy and not tracer.collideneutral and not tracer.collidefriendly)
print('PASS: interception aiming, shared muzzle effects, travelling rounds, limits and target loss')
