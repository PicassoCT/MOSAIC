-- Run from the repository root: lua5.1 tests/icarus_lifecycle_test.lua
local path = "luarules/gadgets/unit_icarus_lifecycle.lua"

local function fixture()
    local w = {units={}, projectiles={}, calls={}, watched={}, context=nil,
        projectileReads=0, ownerReads=0}
    local e = setmetatable({}, {__index=_G})
    e.UnitDefNames = {air_plane_artillery={id=9}}
    e.WeaponDefNames = {icarusglidebomb={id=4}}
    e.gadgetHandler = {IsSyncedCode=function() return true end}
    e.Script = {SetWatchWeapon=function(id, enabled)
        assert(id==4 and enabled==true, "shared weapon watch must only be enabled")
        w.watched[#w.watched+1]={id,enabled}
    end}
    local function forbidden() error("lifecycle relay must not poll, move, order, or destroy") end
    e.Spring = {
        GetUnitDefID=function(id) return w.units[id] and w.units[id].def end,
        GetUnitRulesParam=function(id, key)
            assert(key=="icarus_released")
            return w.units[id] and w.units[id].released
        end,
        GetProjectileDefID=function(id)
            w.projectileReads=w.projectileReads+1
            return w.projectiles[id] and w.projectiles[id].weapon
        end,
        GetProjectileOwnerID=function(id)
            w.ownerReads=w.ownerReads+1
            return w.projectiles[id] and w.projectiles[id].owner
        end,
        GetAllUnits=forbidden, GetProjectilesInRectangle=forbidden,
        GetUnitCommands=forbidden, GetUnitCurrentCommand=forbidden,
        GiveOrderToUnit=forbidden, DestroyUnit=forbidden, DeleteProjectile=forbidden,
        SetUnitPosition=forbidden, SetUnitVelocity=forbidden,
        MoveCtrl=setmetatable({}, {__index=function() return forbidden end}),
        UnitScript={
            GetScriptEnv=function(id) return w.units[id] and w.units[id].env end,
            CallAsUnit=function(id, fn, ...)
                local prior=w.context; w.context=id
                fn(...)
                w.context=prior
            end,
        },
    }
    function w:addUnit(id, def)
        local u={def=def or 9, env={}}
        self.units[id]=u
        for _,name in ipairs({"IcarusProjectileCreated", "IcarusProjectileDestroyed", "IcarusCommandChanged"}) do
            u.env[name]=function(projectileID)
                assert(w.context==id, "callback must run in the owner's unit-script context")
                w.calls[#w.calls+1]={id=id,name=name,projectile=projectileID}
                if name=="IcarusProjectileCreated" then u.released=1 end
            end
        end
        return u
    end
    function w:reload()
        if e.gadget and e.gadget.Shutdown then e.gadget:Shutdown() end
        e.gadget={}
        local chunk=assert(loadfile(path)); setfenv(chunk,e); chunk()
        self.gadget=e.gadget
        assert(not self.gadget.GameFrame, "relay must have no recurring update")
        self.gadget:Initialize()
    end
    function w:create(id, owner, weapon, missingDefinition)
        self.projectiles[id]={owner=owner,weapon=weapon or 4}
        local eventWeapon=weapon or 4
        if missingDefinition then eventWeapon=nil end
        self.gadget:ProjectileCreated(id,owner,eventWeapon)
    end
    function w:destroy(id)
        -- The target engine keeps the projectile readable through this event.
        self.gadget:ProjectileDestroyed(id)
        self.projectiles[id]=nil
    end
    w.env=e; w:reload(); return w
end

local w=fixture(); local a=w:addUnit(7); w:addUnit(8,10)
assert(#w.watched==1 and #w.calls==0)
w:create(101,7,4)
assert(#w.calls==1 and w.calls[1].name=="IcarusProjectileCreated"
    and w.calls[1].projectile==101 and a.released==1)
local reads=w.projectileReads
w:destroy(101)
assert(#w.calls==2 and w.calls[2].name=="IcarusProjectileDestroyed"
    and w.projectileReads==reads and w.ownerReads==0,
    "ordinary destruction must use the recorded owner without a lookup")
w:destroy(101)
assert(#w.calls==2, "deleted projectile must not be relayed twice")

-- Only the Icarus weapon belonging to an Icarus unit is eligible.
w:create(102,7,5); w:create(103,8,4); w:create(104,nil,4); w:create(105,99,4)
for _,id in ipairs({102,103,104,105}) do w:destroy(id) end
assert(#w.calls==2, "unrelated weapon/owner reached an Icarus handler")
reads=w.projectileReads
w:create(106,7,4,true)
assert(#w.calls==3 and w.calls[3].projectile==106, "legacy missing weapon definition must be resolved")
assert(w.projectileReads==reads+1)
w:destroy(106)
assert(#w.calls==4)

-- The engine notification precedes queue mutation. The relay forwards it
-- without reading commands; the production script owns deferred refresh.
for _,event in ipairs({"UnitCommand","UnitCmdDone","UnitIdle"}) do
    local before=#w.calls
    w.gadget[event](w.gadget,8,10)
    w.gadget[event](w.gadget,99,10)
    assert(#w.calls==before)
    w.gadget[event](w.gadget,7,9)
    assert(#w.calls==before+1 and w.calls[#w.calls].name=="IcarusCommandChanged")
end
w.gadget:UnitIdle(7)
assert(w.calls[#w.calls].name=="IcarusCommandChanged", "missing definition should resolve the live unit")

-- Creation installs ownership before calling the script: synchronous owner
-- removal from inside that handler must clear the map and leave the bomb.
local removed=w:addUnit(11)
removed.env.IcarusProjectileCreated=function(id)
    assert(w.context==11 and id==107)
    w.gadget:UnitDestroyed(11)
    w.units[11]=nil
end
local before=#w.calls
w:create(107,11,4)
assert(w.projectiles[107], "owner removal must not delete a falling projectile")
w:destroy(107)
assert(#w.calls==before, "removed owner retained a stale event mapping")

-- Destruction clears ownership before notifying the script. Recursive engine
-- notifications and synchronous unit removal cannot double-call the handler.
local reentrant=w:addUnit(12)
local ends=0
reentrant.env.IcarusProjectileDestroyed=function(id)
    assert(w.context==12 and id==108)
    ends=ends+1
    w.gadget:ProjectileDestroyed(id)
    w.gadget:UnitDestroyed(12)
    w.units[12]=nil
end
w:create(108,12,4); w:destroy(108)
assert(ends==1)

-- Reload recovery is event-only. It neither scans the world nor replays
-- creation; destruction recovers an already released carrier while readable.
w:create(109,7,4)
before=#w.calls; w:reload()
assert(#w.calls==before and #w.watched==2, "reload replayed release or disabled shared watch")
w:destroy(109)
assert(#w.calls==before+1 and w.calls[#w.calls].name=="IcarusProjectileDestroyed")
local unreleased=w:addUnit(13)
w.projectiles[110]={owner=13,weapon=4}
before=#w.calls; w:destroy(110)
assert(#w.calls==before and not unreleased.released, "reload recovery accepted an unreleased owner")

-- Missing script handlers are legitimate during script load/destruction.
local absent=w:addUnit(14); absent.env={}
w:create(111,14,4); w:destroy(111); w.gadget:UnitIdle(14,9)
assert(#w.calls==before)

print("PASS: Icarus-only event relay; synchronous mapping and removal; command notifications without polling; owner removal preserves bombs; event-only reload recovery; no movement or recurring update")
