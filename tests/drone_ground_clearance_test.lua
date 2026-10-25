-- Lua 5.1+: native guidance is left intact; its bounded step cannot hit terrain.
local function loadIn(path, env)
    setmetatable(env,{__index=_G})
    if setfenv then return setfenv(assert(loadfile(path)),env)() end
    return assert(loadfile(path,'t',env))()
end
local def=loadIn('weapons/smartDroneMine.lua',{lowerkeys=function(t)return t end}).smartminedrone
local cfg=def.customParams
assert(def.collideGround==false and def.collideEnemy and def.collideNeutral)
assert(def.damage.default==50 and def.burst==5 and def.tracks)
assert(def.BurnBlow and def.flightTime==15,'non-colliding missiles must still expire')
assert(cfg.drone_terrain_step >= def.weaponVelocity/30+def.weaponAcceleration/900+2*def.dance/30)
local projectiles, moves, watched = {}, {}, {}
local ground=function()return 0 end
local env={gadget={},gadgetHandler={IsSyncedCode=function()return true end},
    Game={squareSize=8,mapSizeX=4096,mapSizeZ=4096},
    WeaponDefs={[1]={customParams=cfg},[2]={customParams={}}},
    Script={SetWatchWeapon=function(id,on)watched[id]=on end},Spring={}}
env.Spring.GetProjectilePosition=function(id)
    local p=projectiles[id];if p then return p.x,p.y,p.z end
end
env.Spring.GetProjectileDefID=function(id)return projectiles[id] and projectiles[id].def end
env.Spring.GetProjectilesInRectangle=function()
    local ids={};for id in pairs(projectiles)do ids[#ids+1]=id end;return ids
end
env.Spring.GetGroundHeight=function(x,z)return ground(x,z)end
env.Spring.SetProjectilePosition=function(id,x,y,z)
    local p=assert(projectiles[id]);assert(x==p.x and z==p.z,'guidance changed')
    p.y=y;moves[id]=(moves[id] or 0)+1
end
local function reload()
    env.gadget={};loadIn('luarules/gadgets/game_drone_ground_clearance.lua',env)
    env.gadget:Initialize()
end
reload();assert(watched[1] and not watched[2])
projectiles[10]={x=128,y=-5,z=128,def=1}
env.gadget:ProjectileCreated(10,9,1)
assert(projectiles[10].y>=cfg.drone_ground_clearance+cfg.drone_terrain_step)
-- Maximum downward travel still leaves enough room for the whole rotated mesh.
projectiles[10].y=projectiles[10].y-cfg.drone_terrain_step
assert(projectiles[10].y>=cfg.drone_ground_clearance)
env.gadget:GameFrame()
-- A narrow ridge between flight endpoints must be sampled before native motion.
ground=function(x,z)return (x==136 and z==128) and 80 or 0 end
env.gadget:GameFrame()
assert(projectiles[10].y>=80+cfg.drone_ground_clearance+cfg.drone_terrain_step)
-- High flight remains untouched; no forced level flight or target replacement.
projectiles[10].y=500;local previous=moves[10]
env.gadget:GameFrame();assert(moves[10]==previous)
-- Reload repairs an existing drone; unrelated weapons and recycled IDs stay alone.
projectiles[10].y=-1;projectiles[20]={x=128,y=-1,z=128,def=2}
reload();assert(projectiles[10].y>80 and projectiles[20].y==-1)
env.gadget:ProjectileDestroyed(10)
projectiles[10]={x=128,y=-1,z=128,def=2}
env.gadget:ProjectileCreated(10,9,2);env.gadget:GameFrame()
assert(projectiles[10].y==-1,'intercepted drone ID was resurrected')
projectiles[30]={x=128,y=100,z=128,def=1}
env.gadget:ProjectileCreated(30,9,1);projectiles[30]=nil;env.gadget:GameFrame()
print('PASS: drone terrain clearance, native motion bounds, ridges, reload and interception cleanup')
