-- Execute the production pool and the actual shooting-triggered spawn branch.
local f=assert(io.open('luarules/gadgets/game_ProjectileImpacts.lua'))
local source=f:read('*a'):gsub('\r','');f:close()
local pool=assert(source:match('(    local MAX_SHOT_BIRD_SWARMS.-)    function gadget:ProjectileCreated'))
local trigger=assert(source:match('(        if loudLongRangeWeaponTypes%[projWeaponDefID%] and GG.GlobalGameState.-)    coolDownTimerCrowsInFrame'))
local compile=loadstring or load
local LIMIT=10
local live,created,killed={},{},{}
local nextID,house,frame,failed,coastal=100,1000,0,false,false
GG={GlobalGameState='normal'};gadget={}
loudLongRangeWeaponTypes={[1]=true};GaiaTeamID=0;houseTypeTable={[7]=true}
civilianBuildingBirdTimer={};coolDownTimerCrowsInFrame=14400
spGetGameFrame=function()return frame end
spGetUnitDefID=function()return 7 end
getExtremasInArea=function()return {value=coastal and 0 or 100},{value=coastal and 20 or 200}end
Spring={
    GetProjectilePosition=function()return 10,120,10 end,
    GetUnitsInCylinder=function()return {house}end,
    GetUnitPosition=function()return 20,0,20 end,
    GetUnitHeight=function()return 180 end,
    ValidUnitID=function(id)return live[id]~=nil end,
    GetUnitIsDead=function(id)return not live[id]end,
    CreateUnit=function(name,x,y,z)
        if failed then return nil end
        nextID=nextID+1;live[nextID]=true
        created[#created+1]={id=nextID,name=name,y=y}
        return nextID
    end,
    DestroyUnit=function(id,selfDestruct,reclaimed)
        assert(live[id] and not selfDestruct and reclaimed)
        live[id]=nil;killed[#killed+1]=id;gadget:UnitDestroyed(id)
    end,
}
genericCallUnitFunctionPassArgs=function(id,name,args)
    assert(live[id] and name=='setShotNearby' and args.height==180)
end
local function reload()
    gadget={}
    assert(compile(pool..'\nfunction fire(proID,proOwnerID,projWeaponDefID)\n'..trigger))()
end
local function shoot()
    house=house+1;coastal=not coastal;fire(1,2,1)
end
reload()
for i=1,LIMIT do shoot();assert(#GG.ShotBirdSwarms==i and #killed==0)end
assert(created[1].name=='gullswarm' and created[2].name=='ravenswarm')
shoot()
assert(#GG.ShotBirdSwarms==LIMIT and killed[1]==101 and GG.ShotBirdSwarms[1]==102)
-- All eleven shots share one game frame: creation order still selects the oldest.
for i=1,20 do shoot();assert(#GG.ShotBirdSwarms==LIMIT)end
assert(#killed==21 and killed[21]==121 and GG.ShotBirdSwarms[1]==122)
failed=true;shoot();failed=false
assert(#killed==21 and #GG.ShotBirdSwarms==LIMIT,'failed creation evicted a living swarm')
local removed=GG.ShotBirdSwarms[3]
live[removed]=nil;gadget:UnitDestroyed(removed)
assert(#GG.ShotBirdSwarms==LIMIT-1)
shoot();assert(#GG.ShotBirdSwarms==LIMIT and #killed==21,'natural death failed to free its slot')
-- A stale death missed while reloading must also be pruned before eviction.
live[GG.ShotBirdSwarms[2]]=nil
reload();shoot();assert(#GG.ShotBirdSwarms==LIMIT and #killed==21)
local oldest=GG.ShotBirdSwarms[1]
reload();shoot();assert(killed[#killed]==oldest and #GG.ShotBirdSwarms==LIMIT)
local total=#created
fire(1,2,1);assert(#created==total,'per-building cooldown changed')
GG.GlobalGameState='anarchy';shoot();assert(#created==total,'city-state gate changed')
gadget:UnitDestroyed(9999);assert(#GG.ShotBirdSwarms==LIMIT)
print('PASS: shared ten-swarm FIFO, same-frame bursts, oldest eviction, failed spawn, natural/stale deaths, reload, cooldown and state gate')
