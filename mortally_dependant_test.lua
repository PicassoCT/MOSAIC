-- Load the gadget without unit-script globals, as in its own engine environment.
gadget = {}
gadgetHandler = {IsSyncedCode = function() return true end}
GG = {}
doesUnitExistAlive = nil

local units = {
    [20] = {dead = false},
    [21] = {dead = true},
    [22] = {}, -- The engine cannot determine this unit's alive state.
    [30] = {dead = false},
}
local destroyed = {}
Spring = {
    ValidUnitID = function(id) return units[id] ~= nil end,
    GetUnitIsDead = function(id)
        assert(units[id], "invalid IDs must be rejected before querying state")
        return units[id].dead
    end,
    DestroyUnit = function(id, selfDestruct, reclaimed)
        assert(units[id] and units[id].dead == false, "destroy only live units")
        destroyed[#destroyed + 1] = {id, selfDestruct, reclaimed}
        units[id].dead = true
        gadget:UnitDestroyed(id)
    end,
}

dofile("luarules/gadgets/game_mortallyDependant.lua")
assert(doesUnitExistAlive == nil, "the helper must remain local to the gadget")
GG.mortallyDependant[10] = {
    {id = 20, boolSelfDestruct = false, boolReclaimed = true},
    {id = 21}, -- Already dead.
    {id = 22}, -- Unknown alive state.
    {id = 99}, -- Invalid ID.
    {}, -- Missing ID.
}
GG.houseHasSafeHouseTable[10] = 30
gadget:UnitDestroyed(10)
assert(#destroyed == 2, "both the live dependent and safehouse must be destroyed")
assert(destroyed[1][1] == 20 and destroyed[1][2] == false and destroyed[1][3] == true)
assert(destroyed[2][1] == 30 and destroyed[2][2] == true and destroyed[2][3] == false)
assert(GG.mortallyDependant[10] == nil)
assert(GG.houseHasSafeHouseTable[10] == nil)
gadget:UnitDestroyed(10)
assert(#destroyed == 2, "consumed dependencies must not be destroyed again")

for _, id in ipairs({21, 22, 99}) do
    GG.houseHasSafeHouseTable[11] = id
    gadget:UnitDestroyed(11)
end
assert(#destroyed == 2, "dead or invalid safehouses must be skipped")
print("PASS: mortal dependencies and safehouses work without unit-script globals")
