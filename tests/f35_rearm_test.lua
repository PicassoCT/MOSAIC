-- Run with lua or luatex --luaonly from the repository root.
local params, threads, orders = {}, {}, {}
local px, pz, baseTeam, progress, dead, stunned = 1000, 0, 1, 1, false, false
script = {}; unitID = 7; UnitDefNames = {armybase={id=20}}; CMD = {GUARD=25}
function include() end
function piece(name) return name end
function Hide() end
function getPieceTableByNameGroups() return {} end
function Sleep(ms) coroutine.yield(ms) end
function StartThread(fn)
    local co = coroutine.create(fn)
    threads[#threads+1] = co
    assert(coroutine.resume(co))
end
Spring = {
    SetUnitRulesParam=function(_, key, value) params[key]=value end,
    GetUnitRulesParam=function(_, key) return params[key] end,
    ValidUnitID=function(id) return id==8 end,
    GetUnitIsDead=function() return dead end,
    GetUnitTeam=function(id) return id==7 and 1 or baseTeam end,
    GetUnitDefID=function() return 20 end,
    GetUnitHealth=function() return 4000,4000,0,0,progress end,
    GetUnitIsStunned=function() return stunned end,
    GetTeamUnitsByDefs=function() return {8} end,
    GetUnitPosition=function(id) if id==7 then return px,512,pz end return 0,0,0 end,
    GiveOrderToUnit=function(_, cmd, args) orders[#orders+1]={cmd,args[1]} end,
}
local function tick(n)
    for i=1,n do
        for _, co in ipairs(threads) do
            if coroutine.status(co)~='dead' then assert(coroutine.resume(co)) end
        end
    end
end
dofile('scripts/airplanefighterjetscript.lua')
script.Create()
assert(script.AimWeapon2() and not script.BlockShot2())
script.FireWeapon2()
assert(not script.AimWeapon2() and script.BlockShot2())
assert(script.AimWeapon1(), 'AA remains available')
script.FireWeapon2(); assert(#threads==1, 'no duplicate rearm threads')
tick(80)
assert(not script.AimWeapon2(), 'time alone cannot rearm away from base')
assert(orders[1][1]==CMD.GUARD and orders[1][2]==8)
px=0; tick(10); px=1000; tick(1); px=0; tick(10)
assert(not script.AimWeapon2(), 'leaving base restarts service')
baseTeam=2; tick(20)
assert(not script.AimWeapon2(), 'captured base cannot rearm')
baseTeam=1; progress=0.5; tick(20)
assert(not script.AimWeapon2(), 'unfinished base cannot rearm')
progress=1; stunned=true; tick(20)
assert(not script.AimWeapon2(), 'stunned base cannot rearm')
stunned=false; dead=true; tick(20)
assert(not script.AimWeapon2(), 'destroyed base cannot rearm')
dead=false; tick(16)
assert(script.AimWeapon2() and params.f35_bomb_loaded==1)
script.FireWeapon2(); px=1000; tick(30)
assert(not script.AimWeapon2(), 'second sortie also consumes the bomb')
-- Unit-script recreation must preserve the empty magazine.
threads={}; dofile('scripts/airplanefighterjetscript.lua'); script.Create()
assert(not script.AimWeapon2() and #threads==1)
px=0; tick(16); assert(script.AimWeapon2())
print('PASS: F35 single bomb, AA, base return, service interruption, capture, destruction and reload persistence')
