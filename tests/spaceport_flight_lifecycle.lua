-- Execute the real unit script and both ribbon helpers with yielding move waits.
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
Spring={Echo=function(err) error(err) end,PlaySoundFile=function() end}
include=function(name)
    if name=='lib_objective_ribbon_flames.lua' or name=='lib_spaceport_landing_flames.lua' then
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
driveOutMainStage=function() end
craneLoadToPlatform=function() ShowRocket();Show(pieces.CapsuleRocket) end
destroyUnitsNearby=function() end
plattformFireBloomCleanup=function() end
local function resume(co,...)
    local ok,kind,p,axis,target=coroutine.resume(co,...); assert(ok,kind)
    return kind,p,axis,target
end
local launch=coroutine.create(launchAnimation)
for _,height in ipairs({3000,12000,18000,32000,58000}) do
    local kind,p,axis,target=resume(launch)
    assert(kind=='move' and p==pieces.Rocket and target==height,'ascent paused or skipped a stage')
    assert(ribbons['objective-launch'] and shown[pieces.RocketFusionPlume],'powered climb lost exhaust')
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
local function count() local n=0;for _ in pairs(ribbons) do n=n+1 end;return n end
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
assert(count()==1 and ribbons['objective-launch'],'second launch failed to reignite')
local returnAgain=coroutine.create(landBooster);resume(returnAgain,1)
while not ribbons['spaceport-landing-1-1'] do resume(returnAgain) end
script.Killed();assert(count()==0,'death retained exhaust')
local deadLaunch=coroutine.create(launchAnimation);resume(deadLaunch)
assert(count()==0,'death allowed launch flames to restart')
print('PASS: powered ascent, immediate disappearance, safe parent reset, three concurrent boosters, larger jets, pad routing, touchdown, relaunch and death')
