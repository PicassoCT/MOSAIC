-- Standalone: lua tests/military_balance_test.lua (Lua 5.1+).
local function read(path)
    local f = assert(io.open(path, "r"))
    local s = f:read("*a"); f:close(); return s
end
local function normalize(t)
    if type(t) ~= "table" then return t end
    local normalized = {}
    for k, v in pairs(t) do
        normalized[type(k) == "string" and k:lower() or k] = normalize(v)
    end
    return normalized
end
function lowerkeys(t)
    local result = normalize(t)
    for k in pairs(t) do t[k] = nil end
    for k, v in pairs(result) do t[k] = v end
    return t
end
Spring = {GetModOptions = function() return {} end}
VFS = {ZIP = 1, Include = function(path)
    if path == 'gamedata/VFSUtils.lua' then return end
    if path == 'gamedata/system.lua' then return {lowerkeys = lowerkeys} end
    if path == 'gamedata/sidedata.lua' then
        return {{shortName='protagon'}, {shortName='antagon'}}
    end
    return dofile(path)
end}

-- Exercise the game's real prototype inheritance, not a test-only clone.
local pre = read('gamedata/unitdefs_pre.lua')
local boundary = assert(pre:find('local sharedEnv =', 1, true))
assert((loadstring or load)(pre:sub(1, boundary - 1)))()
for _, path in ipairs({'Buildings','GroundDrones','Vehicles','AirDrones'}) do
    for name, class in pairs(dofile('baseclasses/units/'..path..'.lua')) do _G[name] = class end
end
local assemblies = dofile('units/shared/house_expansions/Assembly.lua')
local function contains(list, name)
    for _, v in ipairs(list) do if v == name then return true end end
    return false
end
local a, p = assemblies.antagonassembly, assemblies.protagonassembly
assert(a ~= p and a.buildoptions ~= p.buildoptions)
assert(contains(a.buildoptions, 'civilian_truck_mg') and not contains(p.buildoptions, 'civilian_truck_mg'))
assert(contains(p.buildoptions, 'ground_truck_mg') and not contains(a.buildoptions, 'ground_truck_mg'))
assert(contains(a.buildoptions, 'air_copter_ssied') and not contains(p.buildoptions, 'air_copter_ssied'))
assert(contains(p.buildoptions, 'air_copter_mg') and not contains(a.buildoptions, 'air_copter_mg'))
a.buildoptions[1] = 'test'; assert(p.buildoptions[1] ~= 'test', 'menus must not alias')

local weapons = dofile('weapons/military_support.lua')
assert(weapons.escortantiair.range < weapons.militaryantiair.range)
assert(weapons.campaignrocket.canattackground and not weapons.campaignrocket.tracks)
assert(weapons.campaignrocket.burst > 1 and weapons.campaignrocket.reloadtime >= 20)
assert(weapons.breachingcannon.areaofeffect < weapons.supportmortar.areaofeffect)
assert(dofile('weapons/submachinegun.lua').submachingegun.reloadtime == 7, 'shared operative weapon stays unchanged')
assert(dofile('weapons/guidedrocket.lua').s16rocket.damage.default == 512, 'police missile stays unchanged')
assert(dofile('weapons/javelinrocket.lua').javelinrocket.damage.default == 1600, 'ambush weapon stays unchanged')
local tanks = dofile('units/shared/chasis/ground/wheels/Tank.lua')
assert(tanks.ground_tank_day.maxdamage == 4000 and tanks.ground_tank_night.maxdamage == 4000)
assert(tanks.ground_tank_day.weapons[1].name == 'breachingcannon')
local turrets = dofile('units/shared/chasis/ground/turret/groundturret.lua')
assert(turrets.ground_turret_ssied.maxdamage == 50 and turrets.ground_turret_ssied.initcloaked)
assert(turrets.ground_turret_antiarmor.weapons[1].name == 'militaryantitank')
assert(weapons.militaryantitank.reloadtime == 12)
assert(dofile('units/shared/chasis/air/copter/air_copter_antiarmor.lua').air_copter_antiarmor.weapons[1].name == 'javelinrocket')
assert(turrets.ground_turret_sniper.weapons[1].name == 'slowsniperrifle')
assert(dofile('units/shared/Brehmerwall.lua').brehmerwall.blocking == true)
assert(contains(dofile('units/protagon/protagonSafehouse.lua').protagonsafehouse.buildoptions,
    'ground_walker_mg'), 'Protagon can cover early raids without an army base')

-- Test actual damage routing, including splash falloff supplied by the engine,
-- both wall types, non-wall targets and unchanged covert weapons.
gadget = {}; gadgetHandler = {IsSyncedCode = function() return true end}
UnitDefNames = {brehmerwall={id=1}, barricade={id=2}}
WeaponDefs = {}
local ids, nextID = {}, 10
for name, def in pairs(weapons) do
    ids[name] = nextID; WeaponDefs[nextID] = {customParams=def.customparams}; nextID=nextID+1
end
dofile('luarules/gadgets/game_military_wall_damage.lua')
local function damage(def, weapon, amount, paralyze)
    return gadget:UnitPreDamaged(100, def, 1, amount, paralyze or false, weapon)
end
for _, wall in ipairs({1,2}) do
    assert(damage(wall, ids.breachingcannon, 600) == 2400)
    assert(damage(wall, ids.breachingcannon, 60) == 240, 'retain splash falloff')
    assert(damage(wall, ids.supportmortar, 240) == 60)
    assert(math.abs(damage(wall, ids.covermachinegun, 12) - 0.6) < 0.00001)
    assert(damage(wall, 999, 1600) == 1600, 'unmodified stealth weapon')
end
assert(damage(3, ids.breachingcannon, 600) == 600, 'no anti-operative multiplier')
assert(damage(1, ids.breachingcannon, 60, true) == 60, 'paralysis not multiplied')
assert(math.ceil(10000 / damage(1, ids.breachingcannon, 600)) == 5)

-- Persisted firing exposure must survive transfer and gadget reload without
-- changing the cloak permission of an unfired Nimrod or any other unit.
local rules, cloaked, visible, shown = {}, {}, {}, {}
local defs = {[10]=7, [11]=7, [12]=8}
local team = {[10]=1, [11]=1, [12]=1}
UnitDefNames = {nimrod={id=7}}
CMD = {CLOAK=37382, INSERT=1, MOVE=10}
GG = {}
Spring = {
    GetUnitDefID=function(id) return defs[id] end,
    GetUnitRulesParam=function(id, key) return (rules[id] or {})[key] end,
    SetUnitRulesParam=function(id, key, value) rules[id]=rules[id] or {}; rules[id][key]=value end,
    SetUnitCloak=function(id, value) cloaked[id]=value end,
    SetUnitAlwaysVisible=function(id, value) visible[id]=value end,
    GetAllUnits=function() return {10,11,12} end,
    UnitScript={GetScriptEnv=function(id)
        return {showHideIcon=function(value) shown[id]=not value end}
    end, CallAsUnit=function(id, fn, ...) return fn(...) end},
}
gadget = {}; dofile('luarules/gadgets/game_nimrod_reveal.lua'); gadget:Initialize()
assert(gadget:AllowUnitCloak(10) and gadget:AllowUnitCloak(12))
GG.RevealNimrodOnFire(12); assert(not rules[12], 'only Nimrod is exposed')
GG.RevealNimrodOnFire(10)
assert(rules[10].nimrod_fired == 1 and visible[10] and shown[10] and cloaked[10] == false)
assert(not gadget:AllowUnitCloak(10) and gadget:AllowUnitCloak(11))
assert(not gadget:AllowCommand(10,7,1,CMD.CLOAK,{1}))
assert(gadget:AllowCommand(10,7,1,CMD.CLOAK,{0}))
assert(gadget:AllowCommand(10,7,1,CMD.MOVE,{}))
visible[10]=false; gadget:UnitGiven(10,7,2,1); assert(visible[10])
gadget:Shutdown(); gadget={}; dofile('luarules/gadgets/game_nimrod_reveal.lua'); gadget:Initialize()
assert(not gadget:AllowUnitCloak(10) and gadget:AllowUnitCloak(11), 'reload restores exposure')
gadget:UnitDestroyed(10); rules[10]=nil
assert(gadget:AllowUnitCloak(10), 'no stale exposure on recycled ID')

-- The mobile assembly must not bypass the faction menus or army-base gate.
local doctrine = dofile('luarules/configs/mobile_assembly_doctrine.lua')
UnitDefNames = {transportedassembly={id=1}}; UnitDefs = {[1]={buildOptions={}}}
nextID=2
for _, group in ipairs({'common','protagon','antagon'}) do
    for _, name in ipairs(doctrine[group]) do
        assert(not UnitDefNames[name], 'duplicate mobile menu entry')
        UnitDefNames[name]={id=nextID}
        UnitDefs[1].buildOptions[#UnitDefs[1].buildOptions+1]=nextID; nextID=nextID+1
    end
end
local disabled, sides = {}, {[1]='protagon', [2]='antagon', [3]='unknown'}
Spring.GetTeamInfo=function(id) return id,0,false,false,sides[id] end
Spring.GetUnitDefID=function(id) return id==100 and 1 or 99 end
Spring.GetUnitTeam=function() return 1 end
Spring.GetAllUnits=function() return {100} end
Spring.FindUnitCmdDesc=function(_, cmd) return -cmd end
Spring.EditUnitCmdDesc=function(_, idx, desc) disabled[idx]=desc.disabled end
gadget={}; dofile('luarules/gadgets/game_mobile_assembly_doctrine.lua'); gadget:Initialize()
local anti=UnitDefNames.civilian_truck_mg.id
local pro=UnitDefNames.ground_truck_mg.id
local common=UnitDefNames.ground_walker_mg.id
assert(disabled[anti] and not disabled[pro])
assert(not gadget:AllowCommand(100,1,1,-anti,{}))
assert(not gadget:AllowCommand(100,1,1,CMD.INSERT,{0,-anti,0}))
assert(gadget:AllowCommand(100,1,1,-pro,{}))
assert(not gadget:AllowUnitCreation(anti,100,1), 'queued forbidden production is rejected')
assert(gadget:AllowUnitCreation(anti,nil,1), 'scripted spawning is unaffected')
assert(not gadget:AllowUnitCreation(999,100,2), 'army-base aircraft unavailable')
assert(gadget:AllowUnitCreation(common,100,3), 'unknown side retains common equipment')
gadget:UnitGiven(100,1,2,1)
assert(not disabled[anti] and disabled[pro], 'capture changes the visible menu')
assert(gadget:AllowCommand(100,1,2,-anti,{}) and not gadget:AllowCommand(100,1,2,-pro,{}))
print('PASS: faction menus, weapon isolation, wall breaches, persistent Nimrod exposure, mobile capture/queue restrictions')
