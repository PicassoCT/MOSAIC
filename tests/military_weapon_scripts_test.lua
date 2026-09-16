-- Standalone: lua tests/military_weapon_scripts_test.lua
-- Exercise the real aim/fire/reload callbacks without an engine or model assets.
local function noop() end
include=noop; piece=function(name) return name end
x_axis=1; y_axis=2; z_axis=3
unitID=10; unitDefID=7; UnitDefs={}; Game={}
getGameConfig=function() return {instance={culture='arabic'}} end
getCultureUnitModelTypes=function() return {} end
getHologramTypes=function() return {} end
Turn=noop; Move=noop; WTurn=noop; WMove=noop; WaitForTurns=noop
spawnCegNearUnitGround=noop; Hide=noop; Show=noop
local shots, fired, modelVisible=0,false,false
GG={RevealNimrodOnFire=function(id) assert(id==10);shots=shots+1;fired=true end}
Spring={GetUnitDefID=function() return 7 end, SetUnitNanoPieces=noop,
    GetUnitRulesParam=function() return fired and 1 or nil end}
showAll=function() modelVisible=true end
hideAll=function() modelVisible=false end
showT=noop; hideT=noop
script={}; dofile('scripts/nimrodscript.lua')
shiverHologramsNearby=noop
boolBuilding=true; assert(not script.AimWeapon1(0,0))
boolBuilding=false; boolOrbitalRailGunAiming=true; assert(not script.AimWeapon1(0,0))
boolOrbitalRailGunAiming=false; assert(script.AimWeapon1(0,0), 'ground weapon can actually fire')
showHideIcon(true); assert(not modelVisible, 'unfired weapon can still hide')
script.FireWeapon1(); assert(shots==1)
showHideIcon(true); assert(modelVisible, 'later cloak visuals cannot hide a fired Nimrod')
script.FireWeapon2(); assert(shots==2, 'orbital fire also reveals')

-- Minimal signal-aware cooperative scheduler. The old SetSignalMask/Signal
-- ordering killed the reload coroutine; that must fail this regression test.
local threads, masks, killed = {}, {}, {}
function Signal(mask)
    local current=coroutine.running()
    for thread, active in pairs(masks) do
        if active == mask then
            killed[thread]=true
            assert(thread~=current, 'thread killed itself by signalling its own mask')
        end
    end
end
function SetSignalMask(mask) masks[coroutine.running()]=mask end
function Sleep(ms) coroutine.yield(ms) end
function StartThread(fn, ...)
    local thread=coroutine.create(fn)
    threads[#threads+1]=thread
    local ok, err=coroutine.resume(thread, ...); assert(ok, err)
    return thread
end
PlaySoundByUnitDefID=noop
getPieceTableByNameGroups=function()
    return {Rocket={1,2,3},Wing={1,2,3,4}}
end
script={}; dofile('scripts/airplanerocketscript.lua')
local function fireMagazine()
    for i=1,3 do
        assert(script.AimWeapon1(0,0), 'available salvo must be fireable')
        script.FireWeapon1()
    end
    assert(not script.AimWeapon1(0,0), 'empty magazine must wait for reload')
    assert(not script.AimWeapon2(0,0), 'target laser disabled during reload')
end
local function finishReload()
    local resumed=0
    for _, thread in ipairs(threads) do
        if not killed[thread] and coroutine.status(thread)=='suspended' then
            local ok, err=coroutine.resume(thread); assert(ok, err); resumed=resumed+1
        end
    end
    assert(resumed==1, 'only one reload thread may run')
    assert(script.AimWeapon1(0,0) and script.AimWeapon2(0,0))
end
fireMagazine(); finishReload()
fireMagazine(); finishReload()
StartThread(unfold); StartThread(fold)
print('PASS: Nimrod aim/fire/visibility and two full Predator magazine/reload cycles')
