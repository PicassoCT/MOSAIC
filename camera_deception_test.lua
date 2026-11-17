-- Run through the external MOSAIC runner. No engine required.
local path = 'luarules/gadgets/game_camera_deception.lua'
local config = dofile('scripts/lib_camera_deception.lua')
local function world()
    local w = {units = {}, frame = 0, queries = 0, allScans = 0, writes = 0}
    Game = {gameSpeed = 30, mapSizeX = 10000, mapSizeZ = 10000}
    UnitDefs = {
        [1] = {losRadius = 100},
        [2] = {customParams = {baseclass = 'Abstract'}},
        [3] = {customParams = {baseclass = 'Abstract'}},
        [4] = {},
        [5] = {modCategories = {notarget = true}},
    }
    UnitDefNames = {spycam = {id = 1}, icon_cameradeception = {id = 2},
        icon_emc = {id = 3}, ground_walker_mg = {id = 4}}
    local function allied(a, b) return a == b or (a == 2 and b == 3) or (a == 3 and b == 2) end
    Spring = {
        GetGaiaTeamID = function() return 0 end,
        GetAllUnits = function()
            w.allScans = w.allScans + 1
            local ids = {}; for id in pairs(w.units) do ids[#ids + 1] = id end
            table.sort(ids); return ids
        end,
        GetUnitDefID = function(id) return w.units[id] and w.units[id].def end,
        GetUnitTeam = function(id) return w.units[id] and w.units[id].team end,
        AreTeamsAllied = allied,
        GetUnitPosition = function(id) local u = assert(w.units[id]); return u.x, u.y, u.z end,
        GetUnitHeading = function(id) return w.units[id].heading or 0 end,
        GetUnitPieceMap = function() return {Eye = 1} end,
        GetUnitPieceMatrix = function(id)
            local yaw = w.units[id].yaw or 0
            return math.sin(yaw), 0, math.cos(yaw)
        end,
        GetUnitVectors = function(id)
            local h = (w.units[id].heading or 0) * math.pi / 32768
            return {math.sin(h), 0, math.cos(h)}, {0, 1, 0}, {-math.cos(h), 0, math.sin(h)}
        end,
        GetUnitIsStunned = function(id) local u = w.units[id]; return u.stunned, false, u.inBuild end,
        GetUnitRulesParam = function(id, key) return w.units[id] and w.units[id].rules[key] end,
        SetUnitRulesParam = function(id, key, value, visibility)
            assert(visibility.allied and not visibility.public, 'camera feed leaked')
            w.writes = w.writes + 1; w.units[id].rules[key] = value
        end,
        GetUnitsInCylinder = function(x, z, radius)
            w.queries = w.queries + 1
            assert(radius <= 180, 'unbounded spatial query')
            local ids = {}
            for id, u in pairs(w.units) do
                if (u.x - x)^2 + (u.z - z)^2 <= radius^2 then ids[#ids + 1] = id end
            end
            table.sort(ids); return ids
        end,
        GetGameFrame = function() return w.frame end,
    }
    VFS = {Include = dofile}
    SendToUnsynced = function() end
    gadgetHandler = {IsSyncedCode = function() return true end}
    function w:load()
        gadget = {}; dofile(path); self.gadget = gadget; gadget:Initialize()
    end
    function w:add(id, def, team, x, z)
        self.units[id] = {def = def, team = team, x = x or 1000, y = 0,
            z = z or 1000, rules = {}}
        self.gadget:UnitCreated(id, def)
        return self.units[id]
    end
    function w:kill(id)
        self.gadget:UnitDestroyed(id); self.units[id] = nil
    end
    function w:tick(count)
        for _ = 1, count or 15 do self.frame = self.frame + 1; self.gadget:GameFrame(self.frame) end
    end
    function w:state(id) return self.units[id].rules.camera_deception_team end
    function w:suppressed(id) return self.units[id].rules.camera_deception_suppressed == 1 end
    w:load(); return w
end

local w = world()
local camera = w:add(10, 1, 2)
local source = w:add(20, 2, 1, 1181)
w:tick(); assert(w:state(10) == nil, 'infection crossed range boundary')
source.x = 1180; w:tick(); assert(w:state(10) == 1 and not w:suppressed(10))
local writes = w.writes; w:tick(); assert(w.writes == writes, 'unchanged state was republished')
source.x = 1181; w:tick(); assert(w:state(10) == -1, 'feed survived outside broadcast range')
source.x = 1180; w:tick(); assert(w:state(10) == 1, 'returning carrier failed to restore feed')
source.stunned = true; w:tick(); assert(w:state(10) == -1, 'disabled carrier kept broadcasting')
source.stunned = false; w:tick(); assert(w:state(10) == 1)
source.team = 3; w:tick(); assert(w:state(10) == -1, 'captured allied carrier kept hostile feed')
source.team = 1; w:tick(); assert(w:state(10) == 1)
w:kill(20); w:tick(150); assert(w:state(10) == -1, 'dead carrier left active feed')
camera.rules.camera_deception_team = 1 -- Legacy saved state without a live carrier.
w:load(); w:tick(); assert(w:state(10) == -1, 'reload resurrected unpowered feed')
source = w:add(20, 2, 1, 1180); w:tick(); assert(w:state(10) == 1)
w:load(); w:tick(); assert(w:state(10) == 1, 'reload lost nearby carrier coverage')

local soldier = w:add(30, 4, 2, 1000, 1050)
w:tick(); assert(w:suppressed(10), 'enemy physical presence did not dissolve contacts')
soldier.z = 950; w:tick(); assert(not w:suppressed(10), 'unit behind lens dissolved contacts')
soldier.z = 1101; w:tick(); assert(not w:suppressed(10), 'out-of-range presence dissolved contacts')
soldier.z = 1050; soldier.x = 1050; w:tick(); assert(not w:suppressed(10), 'outside cone dissolved contacts')
soldier.x = 1000; soldier.y = 1000; w:tick(); assert(not w:suppressed(10), 'orbital object dissolved contacts')
soldier.y = 0; soldier.team = 1; w:tick(); assert(not w:suppressed(10), 'friendly presence dissolved contacts')
soldier.team = 0; w:tick(); assert(not w:suppressed(10), 'civilian presence dissolved contacts')
soldier.team = 2; soldier.def = 5; w:tick(); assert(not w:suppressed(10), 'software dissolved contacts')
soldier.def = 4; camera.heading = 32768; w:tick(); assert(not w:suppressed(10), 'camera heading ignored')
camera.heading = 0; w:tick(); assert(w:suppressed(10))
w:kill(30); w:tick(); assert(not w:suppressed(10) and w:state(10) == 1, 'contacts failed to return')

local ecm = w:add(40, 3, 1, 1050)
w:tick(); assert(w:state(10) == 1, 'own ECM cleansed enemy camera')
ecm.team = 3; ecm.x = 1101; w:tick(); assert(w:state(10) == 1, 'ECM exceeded radius')
ecm.x = 1100; ecm.stunned = true; w:tick(); assert(w:state(10) == 1, 'stunned ECM cleansed camera')
ecm.stunned = false; w:tick(); assert(w:state(10) == -1, 'allied defensive ECM failed to clean camera')
source = w:add(21, 2, 1, 1050)
w:tick(); assert(w:state(10) == -1, 'ECM allowed immediate reinfection')
w:kill(40); w:tick(); assert(w:state(10) == 1, 'new exposure after ECM left failed')
w:kill(10); camera = w:add(10, 1, 2); w:kill(20); w:kill(21); w:tick()
assert(w:state(10) == nil, 'destroyed camera infection reused with unit ID')

w = world(); camera = w:add(10, 1, 2); source = w:add(20, 2, 3)
w:tick(); assert(w:state(10) == nil, 'allied camera infected')
source.team = 1; source.inBuild = true; w:tick(); assert(w:state(10) == nil)
source.inBuild = false; source.stunned = true; w:tick(); assert(w:state(10) == nil)
source.stunned = false; camera.inBuild = true; w:tick(); assert(w:state(10) == nil)
camera.inBuild = false; w:add(19, 2, 4); w:tick(); assert(w:state(10) == 4, 'carrier tie not deterministic')
camera.team = 3; w:tick(); assert(w:state(10) == 4, 'ordinary capture erased infection')

-- Coverage follows the moving carrier, and overlapping carriers provide backup.
w = world(); w:add(10, 1, 2, 1000); w:add(11, 1, 2, 2000)
source = w:add(20, 2, 1, 1050); w:tick()
assert(w:state(10) == 1 and w:state(11) == nil)
source.x = 2050; w:tick()
assert(w:state(10) == -1 and w:state(11) == 1, 'deception did not follow carrier')
local backup = w:add(21, 2, 1, 2050); w:tick()
w:kill(20); w:tick(); assert(w:state(11) == 1, 'lost feed despite another nearby carrier')
backup.x = 3000; w:tick(); assert(w:state(11) == -1, 'last carrier departure left feed')

-- Cost depends on nearby entities and active sources/infections, not world size.
w = world(); w:add(10, 1, 2); w:add(20, 2, 1, 1050)
for id = 100, 1099 do w:add(id, 4, 2, 9000, 9000) end
local scans = w.allScans
w:tick(14); assert(w.queries == 0, 'ran spatial scans between update ticks')
w:tick(1); assert(w.queries == 2, 'expected one source query and one infected camera query')
w:tick(15); assert(w.queries == 4 and w.allScans == scans, 'full-world scan in hot path')
w:kill(20); local queries = w.queries; w:tick(); assert(w.queries == queries, 'uncovered camera still scanned')
assert(w:state(10) == -1)
w:kill(10); queries = w.queries; w:tick(); assert(w.queries == queries)

-- Every generated contact stays in the same cone used by the simulation.
local poseWorld = world()
local pose = poseWorld:add(10, 1, 2)
local fx, fz = config.Direction(10, 1)
assert(math.abs(fx) < 0.0001 and math.abs(fz - 1) < 0.0001)
pose.yaw = math.pi / 2
fx, fz = config.Direction(10, 1)
assert(math.abs(fx - 1) < 0.0001 and math.abs(fz) < 0.0001, 'animated lens rotation ignored')
pose.heading = 16384
fx, fz = config.Direction(10, 1)
assert(math.abs(fx) < 0.0001 and math.abs(fz + 1) < 0.0001, 'unit and lens rotation not composed')
for frame = 0, 2000, 7 do
    for angle = 0, 6, 0.5 do
        local fx, fz = math.sin(angle), math.cos(angle)
        for index = 1, config.contactCount do
            local x, z = config.Contact(10, index, frame, 100, fx, fz)
            assert(config.InCone(x, z, fx, fz, 100), 'generated contact escaped cone')
        end
    end
end

-- Exercise rendering visibility, suppression and camera lifecycle with real code.
w = world(); camera = w:add(10, 1, 2); w:add(20, 2, 1, 1050); w:tick()
local myTeam, draws, fullView, inLos = 2, 0, false, true
local actions = {}
gadgetHandler = {IsSyncedCode = function() return false end,
    AddSyncAction = function(_, name, fn) actions[name] = fn end,
    RemoveSyncAction = function(_, name) actions[name] = nil end}
Spring.GetFrameTimeOffset = function() return 0 end
Spring.GetSpectatingState = function() return false, fullView end
Spring.GetMyTeamID = function() return myTeam end
Spring.IsSphereInView = function() return true end
Spring.GetGroundHeight = function() return 0 end
Spring.IsPosInLos = function() return inLos end
gl = setmetatable({UnitShape = function(_, team) assert(team == 1); draws = draws + 1 end},
    {__index = function() return function() end end})
gadget = {}; dofile(path); local visual = gadget; visual:Initialize(); visual:GameFrame(15)
visual:DrawWorld(); assert(draws == 3, 'camera owner missing false contacts')
myTeam = 1; visual:DrawWorld(); assert(draws == 3, 'attacker saw victim-only contacts')
myTeam = 4; visual:DrawWorld(); assert(draws == 3, 'third party saw victim-only contacts')
myTeam = 3; visual:DrawWorld(); assert(draws == 6, 'camera ally missing shared feed')
camera.rules.camera_deception_suppressed = 1; visual:DrawWorld(); assert(draws == 6)
camera.rules.camera_deception_suppressed = 0; inLos = false
visual:DrawWorld(); assert(draws == 6, 'contacts rendered beyond current sight')
inLos = true; w.units[20].x = 9000; w:tick()
visual:DrawWorld(); assert(draws == 6, 'cached contacts rendered after carrier left')
w.units[20].x = 1050; w:tick(); visual:GameFrame(w.frame)
visual:DrawWorld(); assert(draws == 9, 'returning carrier failed to restore rendered contacts')
actions.camera_deception_remove(nil, 10); visual:DrawWorld(); assert(draws == 9)
visual:Shutdown(); assert(next(actions) == nil)

-- Real definition inheritance and both production menus must expose an unarmed carrier.
local function read(file)
    local f = assert(io.open(file)); local s = f:read('*a'); f:close(); return s
end
function lowerkeys(t)
    local normalized = {}
    for key, value in pairs(t) do
        if type(value) == 'table' then lowerkeys(value) end
        normalized[type(key) == 'string' and key:lower() or key] = value
    end
    for key in pairs(t) do t[key] = nil end
    for key, value in pairs(normalized) do t[key] = value end
    return t
end
Spring.GetModOptions = function() return {} end
VFS.Include = function(file)
    if file == 'gamedata/VFSUtils.lua' then return end
    if file == 'gamedata/system.lua' then return {lowerkeys = lowerkeys} end
    if file == 'gamedata/sidedata.lua' then return {{shortName = 'protagon'}, {shortName = 'antagon'}} end
    return dofile(file)
end
local pre = read('gamedata/unitdefs_pre.lua')
assert((loadstring or load)(pre:sub(1, assert(pre:find('local sharedEnv =', 1, true)) - 1)))()
Abstract = dofile('baseclasses/units/Abstract.lua').Abstract
Building = dofile('baseclasses/units/Buildings.lua').Building
local icons = dofile('units/shared/abstracts/Icons.lua')
local carrier = icons.icon_cameradeception
assert(carrier and carrier.canmove and not carrier.canattack and not carrier.onoffable)
assert(next(carrier.weapons) == nil, 'carrier inherited ECM marker weapon')
assert(icons.icon_emc.weapons[1], 'new carrier altered original ECM definition')
assert(carrier.script == 'cameradeceptionscript.lua')
for _, builder in pairs(dofile('units/shared/house_expansions/hivemind.lua')) do
    local found = false
    for _, name in ipairs(builder.buildoptions) do if name == 'icon_cameradeception' then found = true end end
    assert(found, 'missing production menu entry')
end
print('camera deception: live proximity, ECM, temporary dissolution, geometry, privacy and bounded queries PASS')
