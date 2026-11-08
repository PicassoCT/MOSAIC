-- Exercise the production weapon selection, projectile trigger and swarm script.
local function source(path)
    local f=assert(io.open(path));local s=f:read('*a');f:close();return s:gsub('\r','')
end
local lib=source('scripts/lib_mosaic.lua')
assert(load(lib:match('(function getLoudLongRangeWeaponTypes.-)  function getLaunchablePayloadTypes')))()
local selected=getLoudLongRangeWeaponTypes({[1]={name='sniperrifle'},[2]={name='slowsniperrifle'},[3]={name='closecombat'}})
assert(selected[1] and selected[2] and not selected[3])
local impacts=source('luarules/gadgets/game_ProjectileImpacts.lua')
local trigger=assert(impacts:match('(        if loudLongRangeWeaponTypes%[projWeaponDefID%] and GG.GlobalGameState.-)    coolDownTimerCrowsInFrame'))
-- This slice includes the end of ProjectileCreated; wrap its actual body.
local frame,spawned,coastal=0,{},false
GG={GlobalGameState='normal'}
loudLongRangeWeaponTypes=selected;GaiaTeamID=0;houseTypeTable={[7]=true}
civilianBuildingBirdTimer={};coolDownTimerCrowsInFrame=14400
spGetGameFrame=function() return frame end
spGetUnitDefID=function() return 7 end
getExtremasInArea=function() return {value=coastal and 0 or 100},{value=coastal and 20 or 200} end
local called
Spring={GetProjectilePosition=function() return 10,120,10 end,
 GetUnitsInCylinder=function() return {10} end,GetUnitPosition=function() return 20,0,20 end,
 GetUnitHeight=function() return 180 end,
 CreateUnit=function(name,x,y,z) spawned[#spawned+1]={name=name,y=y};return 99 end}
genericCallUnitFunctionPassArgs=function(id,name,args) called={id,name,args} end
assert(load('function fire(proID,proOwnerID,projWeaponDefID)\n'..trigger))()
fire(500,1,1);assert(#spawned==1 and spawned[1].name=='ravenswarm' and spawned[1].y==180)
assert(called[1]==99 and called[2]=='setShotNearby' and called[3].x==10)
frame=14399;fire(500,1,1);assert(#spawned==1,'cooldown')
frame=14400;coastal=true;fire(500,1,1);assert(#spawned==2 and spawned[2].name=='gullswarm')
GG.GlobalGameState='anarchy';frame=30000;fire(500,1,1);assert(#spawned==2,'normal-state gating')
-- Flight: exact coincidence must remain finite, never issue an order to the shooter.
local threads={};local moved=0
include=function() end;piece=function() return 1 end
unitID=99;unitDefID=1;UnitDefs={[1]={name='ravenswarm'}};script={};y_axis=2
getPieceTableByNameGroups=function() return {Raven={2},Gull={3}} end
Hide=function() end;Show=function() end;Spin=function() end;Sleep=function() end
StartThread=function(fn) threads[#threads+1]=fn end
Spring.SetUnitAlwaysVisible=function() end;Spring.SetUnitNoSelect=function() end
Spring.SetUnitBlocking=function() end;Spring.PlaySoundFile=function() end
Spring.GetGroundHeight=function() return 0 end
Spring.MoveCtrl={Enable=function() end,SetPosition=function(id,x,y,z)
 assert(id==99 and x==x and y==y and z==z);moved=moved+1 end}
local destroyed=false;Spring.DestroyUnit=function(id) assert(id==99);destroyed=true end
Command=function() error('bird must not command its shooter') end
assert(load(source('scripts/birdswarmscript.lua')))()
script.Create();setShotNearby({x=20,z=20,height=180});threads[1]()
assert(moved==900 and destroyed)
print('PASS: sniper selection, ravens/gulls, height, cooldown, state gate, callback, finite flight, cleanup')
