-- Execute the real unit script and ribbon helpers with yielding move waits.
-- Run from the repository root with Lua 5.1/LuaJIT.
local pieces, names, shown, ribbons, groups, moves, threads = {},{},{},{},{},{},{}
unitID=42; script={}; x_axis=1; y_axis=2; z_axis=3
piece=function(name)
    if not pieces[name] then pieces[name]=#names+1; names[#names+1]=name end
    return pieces[name]
end
for _,name in ipairs({'GroundRearDoor','GroundFrontDoor','CraneHeadClaw','CrawlerBooster',
    'Booster','RocketThrustPillar','ReturningBooster','BoosterRotator','LandCone',
    'CrawlerBoosterRing','CrawlerBoosterGasRing','LandedBooster',
    'RocketPlume','RocketPlumeA','RocketPlumeB','RocketScience','FireFlower'}) do
    groups[name]={}
    for i=1,5 do groups[name][i]=piece(name..i) end
end
for nr=1,3 do
    local name='ReturningBooster'..nr..'ThrusterPlum'
    groups[name]={}
    for i=1,3 do groups[name][i]=piece(name..i) end
end
GG={GlobalGameState='normal',SmokeRibbon={
    Set=function(_,slot,p,options) ribbons[slot]={piece=p,options=options};return true end,
    Remove=function(_,slot) ribbons[slot]=nil end,
}}
Spring={Echo=function(err) error(err) end,PlaySoundFile=function() end,
    GetUnitPieceInfo=function() return {min={-303,-282,-40},max={210,275,832}} end}
include=function(name)
    if name=='lib_objective_ribbon_flames.lua' or name=='lib_spaceport_landing_flames.lua'
        or name=='lib_spaceport_cold_vapor.lua' then
        return dofile('scripts/'..name)
    elseif name=='lib_cloud_pieces.lua' then return function() return {Shutdown=function() end} end end
end
Show=function(p) assert(p);shown[p]=true end
Hide=function(p) assert(p);shown[p]=nil end
ShowRadiancePiece=Show;HideRadiancePiece=Hide
showT=function(t) for _,p in pairs(t) do Show(p) end end
hideT=function(t) for _,p in pairs(t) do Hide(p) end end
HideRadiancePieces=hideT
getPieceTableByNameGroups=function() return groups end
getGameConfig=function() return {game={states={normal='normal'}}} end
getScrapheapTypeTable=function() return {} end
hideAll=function() shown={} end
resetAll=function() end
Move=function(p,axis,target,speed)
    if p==pieces.Rocket and axis==y_axis and target==0 then
        assert(not shown[pieces.MainStageRocket], 'parent reset dragged a visible rocket down')
    end
    moves[p]={axis=axis,target=target,speed=speed}
end
WMove=function(...) Move(...);return coroutine.yield('move',...) end
WaitForMoves=function(p) coroutine.yield('move',p,moves[p].axis,moves[p].target) end
mSyncIn=function(p,x,y,z,ms) Move(p,y_axis,y,ms) end
WTurn=function() end; Turn=function() end; Spin=function() end; StopSpin=function() end
turnT=function() end;spinT=function() end
StartThread=function(fn,...) threads[#threads+1]={fn=fn,args={...}} end
Sleep=function(ms) coroutine.yield('sleep',ms) end
foreach=function(t,fn) for _,v in pairs(t) do fn(v) end end
randSign=function() return 1 end; maRa=function() return false end
holdsForAllBool=function() return false end
dofile('scripts/objective_spaceportscript.lua')
script.Create()
assert(next(ribbons)==nil,'preparation started exhaust')
local function count() local n=0;for _ in pairs(ribbons) do n=n+1 end;return n end
local function checkFueling()
    assert(count()==8 and not ribbons['objective-launch'],'fueling mixed vapor with exhaust')
    for _,r in pairs(ribbons) do
        local o=r.options
        assert(r.piece==pieces.MainStageRocket,'vapor did not attach to tank')
        assert(o.directionSpace=='world' and o.direction[2]==-1,'cold vapor must fall')
        assert(o.emission[1]==0 and o.emission[2]==0,'cold vapor glows like fire')
        assert(o.colorStart[3]>=o.colorStart[1] and o.speed<1,'vapor lost its cold, slow appearance')
        local offset=o.rootOffset
        assert((offset[1]+46.5)^2+(offset[2]+3.5)^2>250^2,'vapor buried inside the tank')
        assert(offset[3]>-40 and offset[3]<832,'vapor outside tank height')
    end
end
ShowRocket();checkFueling()
ShowRocket();checkFueling() -- repeated show replaces the same outlets
HideRocket();assert(count()==0,'hiding the parked rocket retained vapor')
driveOutMainStage=function() end
craneLoadToPlatform=function() ShowRocket();Show(pieces.CapsuleRocket);Sleep(5000) end
destroyUnitsNearby=function() end
plattformFireBloomCleanup=function() end
local function resume(co,...)
    local ok,kind,p,axis,target=coroutine.resume(co,...); assert(ok,kind)
    return kind,p,axis,target
end
local launch=coroutine.create(launchAnimation)
local kind,p=resume(launch)
assert(kind=='sleep' and p==5000,'fueling interval missing');checkFueling()
for _,height in ipairs({3000,12000,18000,32000,58000}) do
    local kind,p,axis,target=resume(launch)
    assert(kind=='move' and p==pieces.Rocket and target==height,'ascent paused or skipped a stage')
    assert(ribbons['objective-launch'] and shown[pieces.RocketFusionPlume],'powered climb lost exhaust')
    assert(count()==1,'cold vapor continued after ignition')
    local o=ribbons['objective-launch'].options
    assert(o.mode=='landing' and o.padPiece==pieces.LaunchCone and o.strands==4,'launch streamers missing')
    assert(shown[pieces.MainStageRocket] and shown[pieces.CapsuleRocket])
end
local kind,p,axis,target=resume(launch)
assert(kind=='move' and p==pieces.MainStage and target==92000,'final climb missing')
assert(ribbons['objective-launch'] and shown[pieces.RocketFusionPlume])
for _,t in ipairs(threads) do assert(t.fn~=cloudFallingDown,'cloud reset started during powered flight') end
kind,p=resume(launch)
assert(kind=='sleep' and p==9000,'recovery timing changed')
assert(not ribbons['objective-launch'] and not shown[pieces.RocketFusionPlume],'exhaust survived disappearance')
for _,name in ipairs({'MainStage','MainStageRocket','CapsuleRocket'}) do
    assert(not shown[pieces[name]],'rocket lingered at maximum altitude: '..name)
end
assert(launchState=='recovery')
local cloud
for _,t in ipairs(threads) do if t.fn==cloudFallingDown then cloud=t end end
assert(cloud,'cloud recovery was lost')
-- This executes the parent reset guard in Move, after HideRocket.
resume(coroutine.create(cloud.fn),unpack(cloud.args))

local boosters={}
for nr=1,3 do
    boosters[nr]=coroutine.create(landBooster)
    resume(boosters[nr],nr)
    for i=1,100 do
        if ribbons['spaceport-landing-'..nr..'-1'] then break end
        resume(boosters[nr])
    end
    assert(count()==nr*3,'concurrent booster overwrote another booster flame')
    for i=1,3 do
        local r=assert(ribbons['spaceport-landing-'..nr..'-'..i])
        assert(r.piece==groups['ReturningBooster'..nr..'ThrusterPlum'][i])
        assert(r.options.length==640 and r.options.width==84 and r.options.mode=='landing')
        assert(r.options.padPiece==groups.LandCone[nr],'wrong landing pad')
    end
end
for nr=1,3 do
    local reachedDeck=false
    for i=1,1000 do
        if not ribbons['spaceport-landing-'..nr..'-1'] then break end
        kind,p,axis,target=resume(boosters[nr])
        if kind=='move' and p==groups.ReturningBooster[nr] and target==0 then
            reachedDeck=true
            assert(ribbons['spaceport-landing-'..nr..'-1'],'flame stopped before touchdown')
        end
    end
    assert(reachedDeck and count()==(3-nr)*3,'touchdown failed to stop only its own flames')
    assert(not shown[groups.ReturningBooster[nr]] and shown[groups.LandedBooster[nr]])
end
-- Repeated launch and destruction must not accumulate or resurrect slots.
local again=coroutine.create(launchAnimation);resume(again)
checkFueling();resume(again)
assert(count()==1 and ribbons['objective-launch'],'second launch failed to reignite')
local returnAgain=coroutine.create(landBooster);resume(returnAgain,1)
while not ribbons['spaceport-landing-1-1'] do resume(returnAgain) end
script.Killed();assert(count()==0,'death retained exhaust')
local deadLaunch=coroutine.create(launchAnimation);resume(deadLaunch)
assert(count()==0,'death allowed tank vapor to restart')
resume(deadLaunch);assert(count()==0,'death allowed launch flames to restart')
-- Death during fueling must also clean the eight parked-hull outlets.
local createVapor=dofile('scripts/lib_spaceport_cold_vapor.lua')
local vapor=createVapor(unitID)
assert(vapor.Start(pieces.MainStageRocket));checkFueling()
vapor.Shutdown();assert(count()==0,'death during fueling retained vapor')
assert(not vapor.Start(pieces.MainStageRocket),'dead vapor helper restarted')
print('PASS: cold tank vapor, ignition handoff, launch streamers, powered ascent, immediate disappearance, safe parent reset, three concurrent boosters, pad routing, touchdown, relaunch and death')
