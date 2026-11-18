-- Run through run.sh against the game checkout with Lua 5.1+.
-- Actual synced gadget: explicit target capture, mixed weapons, interception,
-- changing faction/ownership, cleanup and composition with other speed changes.
local function check(value, message) assert(value, message) end
local function eq(a, b, message)
    assert(a == b, message .. ': ' .. tostring(a) .. ' ~= ' .. tostring(b))
end
local function near(a, b, message)
    assert(math.abs(a - b) < 1e-7, message .. ': ' .. tostring(a) .. ' ~= ' .. tostring(b))
end
local function world()
    local w = {units = {}, frame = 0, registered = {}, watched = {}, attached = 0,
        detached = 0, stopped = {}, interrupted = {}, teams = {
            [0] = {side = ''}, [1] = {side = 'antagon'}, [2] = {side = 'Protagon'},
            [3] = {side = 'antagon'}, [4] = {side = 'protagon', ally = 1},
            [5] = {side = '', start = 4}, [6] = {side = '', start = 1},
        }}
    CMD = {STOP = 0, INSERT = 1, MOVE = 10, ATTACK = 20, DGUN = 105, CLOAK = 95}
    CMDTYPE = {ICON = 0, ICON_UNIT = 12}
    Game = {gameSpeed = 30, mapSizeX = 8192, mapSizeZ = 8192}
    GG = {DisguiseCivilianFor = {}, InterrogationTable = {}, CloseCombatInvolved = {}}
    UnitDefNames = {operativepropagator = {id = 1}, civilian_arab0 = {id = 2},
        truck = {id = 3}, operativeinvestigator = {id = 4}, operativeasset = {id = 5},
        air_plane_sniper = {id = 6}}
    WeaponDefNames = {stunpistol = {id = 10}, pistol = {id = 11},
        sniperrifle = {id = 12}, slowsniperrifle = {id = 13}}
    WeaponDefs = {[10] = {}, [11] = {}, [12] = {}, [13] = {}}
    UnitDefs = {
        [1] = {name = 'operativepropagator', speed = 66, weapons = {{weaponDef = 10}}},
        [2] = {name = 'civilian_arab0', speed = 36, weapons = {{weaponDef = 11}}},
        [3] = {name = 'truck', speed = 100, weapons = {}},
        [4] = {name = 'operativeinvestigator', speed = 66, weapons = {{weaponDef = 10}}},
        [5] = {name = 'operativeasset', speed = 66, weapons = {{weaponDef = 11}, {weaponDef = 12}}},
        [6] = {name = 'air_plane_sniper', speed = 100, weapons = {{weaponDef = 13}}},
    }
    function w:add(id, def, team, x)
        self.units[id] = {def = def, team = team, x = x or 0, y = 0, z = 0,
            rules = {}, descs = {}, blocking = {true, true, true, false, true, false, true},
            noSelect = false, capturable = true, speed = 1, hp = 100, built = 1,
            pieces = {center = 1}, pose = false}
        if self.gadget then self.gadget:UnitCreated(id, def) end
        return self.units[id]
    end
    function w:all()
        local ids = {}; for id in pairs(self.units) do ids[#ids + 1] = id end
        table.sort(ids); return ids
    end
    Spring = {
        GetGaiaTeamID = function() return 0 end,
        GetAllUnits = function() return w:all() end,
        GetUnitDefID = function(id) return w.units[id] and w.units[id].def end,
        GetUnitTeam = function(id) return w.units[id] and w.units[id].team end,
        GetUnitAllyTeam = function(id) return w.units[id].team end,
        GetTeamInfo = function(id)
            local team = w.teams[id]; return id, 0, false, false, team and team.side, id
        end,
        GetTeamRulesParam = function(id, key) return w.teams[id] and w.teams[id].start end,
        GetTeamUnits = function(team)
            local ids = {}; for _, id in ipairs(w:all()) do if w.units[id].team == team then ids[#ids + 1] = id end end
            return ids
        end,
        AreTeamsAllied = function(a, b)
            local aa, bb = w.teams[a] and w.teams[a].ally or a, w.teams[b] and w.teams[b].ally or b
            return aa == bb
        end,
        ValidUnitID = function(id) return w.units[id] ~= nil end,
        GetUnitIsDead = function(id) return w.units[id] and w.units[id].dead end,
        GetUnitIsStunned = function(id) local u = w.units[id]; return u.stunned, false, u.built < 1 end,
        GetUnitHealth = function(id) local u = w.units[id]; return u.hp, 100, 0, 0, u.built end,
        GetUnitTransporter = function(id) return w.units[id] and w.units[id].transporter end,
        GetUnitLosState = function(id) return {los = not w.units[id].hidden} end,
        GetUnitPosition = function(id) local u = w.units[id]; if u then return u.x, u.y, u.z end end,
        SetUnitPosition = function(id, x, z) local u = w.units[id]; u.x, u.y, u.z = x, 0, z end,
        GetGroundHeight = function() return 0 end,
        GetUnitNoSelect = function() error('GetUnitNoSelect is not available to synced gadgets') end,
        SetUnitNoSelect = function() error('hostage acquisition must preserve existing selection state') end,
        GetUnitBlocking = function(id) return unpack(w.units[id].blocking) end,
        SetUnitBlocking = function(id, ...) w.units[id].blocking = {...} end,
        GetUnitPieceMap = function(id) return w.units[id].pieces end,
        GetUnitRulesParam = function(id, key) return w.units[id] and w.units[id].rules[key] end,
        SetUnitRulesParam = function(id, key, value) w.units[id].rules[key] = value end,
        GetUnitIsCloaked = function(id) return w.units[id].cloaked end,
        SetUnitCloak = function(id, value) w.units[id].cloaked = value end,
        GetGameFrame = function() return w.frame end,
        SetUnitMoveGoal = function(id, x, y, z, radius) w.units[id].goal = {x, y, z, radius} end,
        ClearUnitGoal = function(id) w.units[id].goal = nil end,
        GiveOrderToUnit = function(id, cmd) if cmd == CMD.STOP then w.stopped[id] = true end end,
        UnitAttach = function(carrier, civilian, piece, force)
            eq(piece, 1, 'attachment uses carrier center'); check(force, 'forced Lua attachment')
            w.attached = w.attached + 1
            if not w.failAttach then w.units[civilian].transporter = carrier end
        end,
        UnitDetach = function(id) w.detached = w.detached + 1; w.units[id].transporter = nil end,
        FindUnitCmdDesc = function(id, cmd) return w.units[id].descs[cmd] and cmd end,
        InsertUnitCmdDesc = function(id, desc) w.units[id].descs[desc.id] = desc end,
        EditUnitCmdDesc = function(id, cmd, desc)
            for key, value in pairs(desc) do w.units[id].descs[cmd][key] = value end
        end,
        UnitScript = {},
    }
    Spring.UnitScript.GetScriptEnv = function(id)
        local u = w.units[id]; if not u or u.noScript then return nil end
        return {
            canBeHumanShield = function() return u.capturable end,
            setHumanShieldCarrier = function(carrier)
                if u.rejectCapture and carrier then return false end
                u.heldBy = carrier
                return true
            end,
            setHumanShieldActive = function(active) u.pose = active end,
        }
    end
    Spring.UnitScript.CallAsUnit = function(id, fn, ...) return fn(...) end
    GG.CivilianLife = {Interrupt = function(_, id) w.interrupted[id] = true end}
    function getCultureUnitModelTypes(culture, kind)
        eq(culture, 'international', 'all authored civilian cultures are eligible')
        eq(kind, 'civilian', 'walking civilians only'); return {[2] = true}
    end
    function setSpeedEnv(id, factor)
        w.units[id].speed = GG.HumanShield and GG.HumanShield.AdjustSpeed(id, factor) or factor
    end
    VFS = {Include = function(path)
        if path == 'scripts/lib_UnitScript.lua' or path == 'scripts/lib_mosaic.lua' then return end
        return dofile(path)
    end}
    Script = {SetWatchAllowTarget = function(id, value) w.watched[id] = value end}
    gadgetHandler = {IsSyncedCode = function() return true end,
        RegisterCMDID = function(_, id) w.registered[id] = true end,
        RemoveCallIn = function(_, name)
            eq(name, 'AllowWeaponTarget', 'only targeting filter is toggled'); w.targetFiltering = false
        end,
        UpdateCallIn = function(_, name)
            eq(name, 'AllowWeaponTarget', 'only targeting filter is toggled'); w.targetFiltering = true
        end}
    w:add(1, 1, 1); w:add(2, 1, 1); w:add(10, 2, 0, 40); w:add(11, 2, 0, 400)
    w:add(20, 4, 2); w:add(21, 5, 2); w:add(22, 6, 2); w:add(23, 5, 3)
    w:add(24, 4, 4); w:add(25, 4, 5); w:add(26, 4, 6); w:add(30, 3, 0, 20)
    gadget = {}; dofile('luarules/gadgets/game_operative_human_shield.lua')
    w.gadget = gadget; gadget:Initialize(); w.api = GG.HumanShield
    function w:order(id, cmd, params)
        local u = self.units[id]
        return self.gadget:AllowCommand(id, u.def, u.team, cmd, params or {}, {})
    end
    function w:execute(id, cmd, params)
        local u = self.units[id]
        return self.gadget:CommandFallback(id, u.def, u.team, cmd, params or {}, {})
    end
    function w:capture(id, civilian)
        check(self:order(id, CMD_HUMAN_SHIELD, {civilian}), 'capture order accepted')
        local used, done = self:execute(id, CMD_HUMAN_SHIELD, {civilian})
        check(used and done and self.api.HasShield(id), 'capture completed')
    end
    function w:tick()
        self.frame = self.frame + 5; self.gadget:GameFrame(self.frame)
    end
    return w
end

local w = world()
local TAKE, RELEASE = CMD_HUMAN_SHIELD, CMD_RELEASE_HUMAN_SHIELD
check(w.registered[TAKE] and w.registered[RELEASE], 'both custom commands registered')
check(w.units[1].descs[TAKE] and w.units[1].descs[RELEASE], 'Propagator has commands')
check(not next(w.units[20].descs), 'Investigator does not receive hostage ability')
check(w.units[1].descs[RELEASE].hidden and not w.units[1].descs[TAKE].hidden, 'initial command state')
check(not w.targetFiltering and next(w.watched) == nil, 'no global targeting work before any hostage exists')
check(not w:order(20, TAKE, {10}), 'other operatives cannot take hostages')
check(not w:order(1, TAKE, {30}), 'vehicles are not civilians')
check(not w:order(1, TAKE, {0/0}) and not w:order(1, TAKE, {'10'}), 'malformed target IDs rejected')
check(not w:order(1, TAKE, {}) and not w:order(1, TAKE, {10, 11}), 'only one explicit target accepted')
check(not w:order(1, CMD.INSERT, {0, TAKE}), 'malformed inserted commands rejected')
check(not w:order(20, CMD.INSERT, {0, TAKE, 0, 10}), 'insert cannot grant the ability to another unit')
local civilian = w.units[10]
for key, value in pairs({hidden = true, stunned = true, transporter = 30, dead = true, noScript = true}) do
    civilian[key] = value
    check(not w:order(1, TAKE, {10}), 'ineligible civilian: ' .. key)
    civilian[key] = nil
end
civilian.team = 3; check(not w:order(1, TAKE, {10}), 'player-owned civilians excluded'); civilian.team = 0
civilian.capturable = false; check(not w:order(1, TAKE, {10}), 'civilian script may veto capture'); civilian.capturable = true
GG.DisguiseCivilianFor[10] = 20
check(not w:order(1, TAKE, {10}), 'disguised operatives are not innocent hostages')
GG.DisguiseCivilianFor[10] = nil
w.units[1].stunned = true; check(not w:order(1, TAKE, {10}), 'stunned carrier cannot acquire protection'); w.units[1].stunned = nil
GG.InterrogationTable[1] = {[20] = true}
check(not w:order(1, TAKE, {10}), 'already detained carrier cannot grab a civilian')
GG.InterrogationTable[1] = nil
w.units[1].rules.betrayal_pending = 1
check(not w:order(1, TAKE, {10}), 'betrayal cannot be bypassed by taking a hostage')
w.units[1].rules.betrayal_pending = nil

check(w:order(1, TAKE, {11}), 'distant explicit civilian accepted for approach')
local used, done = w:execute(1, TAKE, {11})
check(used and not done and not w.api.HasShield(1), 'approach grants no early protection')
eq(w.units[1].goal[1], 400, 'approach follows the chosen civilian')
w.units[11].x = 450; w:execute(1, TAKE, {11}); eq(w.units[1].goal[1], 450, 'moving target remains exact target')
w.units[11].hidden = true
used, done = w:execute(1, TAKE, {11})
check(used and done and not w.units[1].goal and w.attached == 0, 'lost LOS cancels without substitution')
w.units[11].hidden = nil
w.units[1].cloaked = true; w:capture(1, 10)
check(w.targetFiltering, 'capture enables automatic target filtering')
for id in pairs(WeaponDefs) do check(w.watched[id], 'active hostage watches each weapon') end
check(w.api.IsHostage(10) and civilian.transporter == 1 and civilian.heldBy == 1, 'civilian physically attached')
check(not civilian.noSelect and not civilian.blocking[2], 'held civilian retains selection state and cannot intercept sniper shots')
check(w.stopped[10] and w.interrupted[10], 'ordinary civilian activity relinquishes movement')
check(not w.units[1].cloaked and w.units[1].pose, 'carrier visibly reveals the hostage')
near(w.units[1].speed, 0.6, 'movement penalty')
check(w.units[1].descs[TAKE].hidden and not w.units[1].descs[RELEASE].hidden, 'release replaces take command')
check(not w:order(2, TAKE, {10}) and not w:order(1, TAKE, {11}), 'one captive and one carrier')
check(not w:order(10, CMD.MOVE, {1, 0, 1}), 'city and player orders cannot move attached civilian')

for _, team in ipairs({2, 5}) do
    check(w.api.IsProtected(1, team, 10), 'Protagon stun blocked including missing-side starter fallback')
    check(w.api.IsProtected(1, team), 'interrogation blocked independently of weapon')
    check(w.api.IsProtected(10, team, 11), 'the hostage is covered by the same firing restraint')
    check(not w.api.IsProtected(1, team, 12) and not w.api.IsProtected(1, team, 13), 'both sniper weapons allowed')
end
for _, team in ipairs({0, 1, 3, 4, 6}) do
    check(not w.api.IsProtected(1, team, 11), 'Gaia, allies and other factions keep ordinary damage')
end
check(not w.api.IsProtected(1, nil, 11), 'unattributed damage is not silently erased')
check(w.api.BlockShot(21, 1, 1), 'mixed sniper unit pistol cannot bypass firing block')
check(not w.api.BlockShot(21, 2, 1), 'mixed sniper unit sniper still fires')
check(not w.api.BlockShot(22, 1, 1), 'sniper aircraft still fires')
check(w.api.BlockShot(10, 1, 20), 'captive cannot fire weapons while held')
check(not w.api.BlockShot(23, 1, 1), 'Antagon pistol still fires')
local allowed, priority = w.gadget:AllowWeaponTarget(20, 1, 1, 10, 37)
check(not allowed and priority == 37, 'automatic targeting preserves priority while rejecting target')
check(w.gadget:AllowWeaponTarget(21, 1, 2, 12, 37), 'automatic sniper targeting permitted')
check(not w:order(20, CMD.ATTACK, {1}), 'new non-sniper direct attack rejected')
check(w:order(21, CMD.ATTACK, {1}), 'mixed unit may receive sniper target')
check(not w:order(21, CMD_INVESTIGATE, {1}), 'sniper ownership cannot permit interrogation')
check(not w:order(20, CMD.INSERT, {0, CMD.ATTACK, 0, 1}), 'inserted direct attacks also rejected')
check(not w:order(21, CMD.INSERT, {0, CMD_INVESTIGATE, 0, 1}), 'inserted interrogation also rejected')
check(w:order(20, CMD.MOVE, {10, 0, 10}), 'unrelated movement remains available')
local damage, impulse = w.gadget:UnitPreDamaged(1, 1, 1, 100, true, 10, 500, 20, 4, nil)
check(damage == 0 and impulse == 0, 'incoming Protagon impact loses damage and push impulse')
check(w.gadget:UnitPreDamaged(1, 1, 1, 580, false, 12, 500, 21, 5, 2) == nil, 'sniper damage retains engine behavior')
check(w.gadget:UnitPreDamaged(1, 1, 1, 100, false, 11, 500, 23, 5, 3) == nil, 'other factions retain engine damage')
setSpeedEnv(1, 0.5); near(w.units[1].speed, 0.3, 'other slow effects compose with hostage penalty')
check(w:order(1, RELEASE), 'release command accepted')
w:execute(1, RELEASE)
check(not w.targetFiltering, 'last release disables automatic target filtering')
check(not w.api.HasShield(1) and not w.api.IsHostage(10) and not civilian.transporter, 'release removes protection and attachment')
check(not civilian.noSelect and civilian.blocking[1] and civilian.blocking[2] and not civilian.blocking[4], 'release restores exact selection/collision state')
check(civilian.heldBy == nil and not w.units[1].pose, 'both actors leave hostage poses')
near(w.units[1].speed, 0.5, 'release preserves the independent speed modifier')
check(w:order(20, CMD.ATTACK, {1}) and w:order(10, CMD.MOVE, {1, 0, 1}), 'ordinary commands resume')
eq(w.detached, 1, 'release detaches once')
w.api.Release(1); w.gadget:UnitDestroyed(10); eq(w.detached, 1, 'repeated cleanup is idempotent')

w = world(); w.failAttach = true
w:execute(1, TAKE, {10})
check(not w.api.HasShield(1) and not w.api.IsHostage(10), 'failed native attachment grants no protection')
check(not w.units[10].noSelect and w.units[10].heldBy == nil, 'failed attachment restores civilian state')
near(w.units[1].speed, 1, 'failed attachment leaves normal speed')
w.failAttach = false; w.units[10].rejectCapture = true
w:execute(1, TAKE, {10}); check(not w.api.HasShield(1), 'script refusal grants no protection')

w = world(); w.units[11].x = 40
w:capture(1, 10); w:capture(2, 11); w.api.Release(1)
check(w.targetFiltering and w.api.HasShield(2), 'remaining hostage keeps target filtering enabled')
w.api.Release(2); check(not w.targetFiltering, 'last of multiple hostages disables target filtering')

for _, event in ipairs({'UnitTaken', 'UnitGiven'}) do
    w = world(); w:capture(1, 10); w.units[1].team = 2
    w.gadget[event](w.gadget, 1, 1, 1, 2)
    check(not w.api.HasShield(1) and not w.api.IsHostage(10), event .. ' frees captive after carrier transfer')
    near(w.units[1].speed, 1, event .. ' restores speed')
    w = world(); w:capture(1, 10); w.units[10].team = 3
    w.gadget[event](w.gadget, 10, 2, 0, 3)
    check(not w.api.HasShield(1) and not w.api.IsHostage(10), event .. ' frees transferred captive')
end
w = world(); w:capture(1, 10); w.units[1].dead = true; w.gadget:UnitDestroyed(1)
check(not w.api.IsHostage(10) and not w.units[10].transporter and not w.units[10].dead, 'carrier death releases living civilian')
w = world(); w:capture(1, 10); w.units[10].dead = true; w.gadget:UnitDestroyed(10)
check(not w.api.HasShield(1) and not w.api.IsHostage(10), 'hostage death removes protection')
check(not w.units[10].transporter, 'dying hostage is detached before death cleanup finishes')
near(w.units[1].speed, 1, 'hostage death restores movement')
w = world(); w:capture(1, 10); w.units[10].transporter = nil; w:tick()
check(not w.api.IsHostage(10), 'unexpected engine detachment clears stale state')
w = world(); w:capture(1, 10); w.units[1].transporter = 30; w:tick()
check(not w.api.IsHostage(10), 'boarding a transport frees captive')
w = world(); w:capture(1, 10); w.units[1].cloaked = true; w:tick()
check(not w.units[1].cloaked, 'forced cloak cannot conceal active hostage')
w.gadget:Shutdown()
check(GG.HumanShield == nil and not w.units[10].transporter, 'shutdown releases hostage and clears public API')

-- Load the actual framework wrapper. Build it before capture to model an attack
-- already queued, then change protection while the same callin remains installed.
local function read(path)
    local file = assert(io.open(path)); local text = file:read('*a'); file:close()
    return text:gsub('\r\n', '\n')
end
local function section(text, first, following)
    local a = assert(text:find(first, 1, true), first)
    local b = assert(text:find(following, a + #first, true), following)
    return text:sub(a, b - 1)
end
local function execute(text, env)
    setmetatable(env, {__index = _G})
    if setfenv then return setfenv(assert(loadstring(text)), env)() end
    return assert(load(text, 'human shield framework', 't', env))()
end
w = world()
local originalCalls = 0
local callins = {BlockShot = function(weapon, target, userTarget)
    originalCalls = originalCalls + 1
    eq(target, 1, 'original BlockShot target preserved')
    return userTarget
end}
local wrapper = section(read('luarules/gadgets/unit_script.lua'),
    '    -- A queued or explicit target bypasses AllowWeaponTarget.',
    '    -- Wrap certain callins in a thread and/or safety net.')
execute(wrapper, {ud = UnitDefs[5], callins = callins, unitID = 21, GG = GG})
check(not callins.BlockShot(1, 1, false), 'normal queued attack reaches original firing policy')
eq(originalCalls, 1, 'original policy invoked once')
w:capture(1, 10)
check(callins.BlockShot(1, 1, false), 'already queued pistol attack stops after hostage acquisition')
eq(originalCalls, 1, 'blocked shot never invokes original side effects')
check(callins.BlockShot(2, 1, true), 'sniper still honors original veto')
check(not callins.BlockShot(2, 1, false), 'sniper retains original permission')
eq(originalCalls, 3, 'sniper invokes original policy with exact arguments')
local defaultCallins = {}
execute(wrapper, {ud = UnitDefs[4], callins = defaultCallins, unitID = 20, GG = GG})
check(defaultCallins.BlockShot(1, 1), 'units without their own BlockShot still obey hostage rule')
w.gadget:Shutdown()
check(not defaultCallins.BlockShot(1, 1), 'absent ability retains ordinary default firing behavior')
check(callins.BlockShot(1, 1, true), 'absent ability retains original weapon veto')

-- Exercise both real speed setters, including their engine fixed-point output.
w = world(); w:capture(1, 10)
local speedValue
Spring.UnitScript.SetUnitValue = function(key, value)
    eq(key, 123, 'correct engine speed field'); speedValue = value
end
local speedEnv = {Spring = Spring, GG = GG, UnitDefs = UnitDefs, COB = {MAX_SPEED = 123},
    SetUnitValue = Spring.UnitScript.SetUnitValue}
execute(section(read('scripts/lib_UnitScript.lua'), 'function setSpeedEnv(', 'function isUnitFlying('), speedEnv)
speedEnv.setSpeedEnv(1, 0.5)
eq(speedValue, math.ceil(66 * 0.3 * 2184.53), 'external setter composes its base factor exactly once')
speedEnv.setSpeedIntern(1, 0.25)
eq(speedValue, math.ceil(66 * 0.15 * 2184.53), 'internal setter composes its base factor exactly once')
speedEnv.setSpeedEnv(2, 0.5)
eq(speedValue, math.ceil(66 * 0.5 * 2184.53), 'unaffected operative speed unchanged')
w.api.Release(1)
near(w.units[1].speed, 0.25, 'release restores last independent speed request from real setters')

print('PASS: Human Shield capture, exact approach target, eligibility, factions/allies, mixed sniper weapons, direct/inserted/queued attacks, real BlockShot delegation, impact protection, real speed setters and release lifecycles')
