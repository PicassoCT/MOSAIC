-- Run through run.sh against the game checkout with Lua 5.1+.
-- Actual synced gadget: Antagon-only capture, native command acceptance,
-- mixed weapons, car/arena lifecycle, cleanup and speed composition.
local function check(value, message) assert(value, message) end
local function eq(a, b, message)
    assert(a == b, message .. ': ' .. tostring(a) .. ' ~= ' .. tostring(b))
end
local function near(a, b, message)
    assert(math.abs(a - b) < 1e-7, message .. ': ' .. tostring(a) .. ' ~= ' .. tostring(b))
end
local function world()
    local w = {money = {}, transfers = {}, queries = 0, units = {}, frame = 0, registered = {}, watched = {}, destroyed = {}, attached = 0,
        detached = 0, stopped = {}, interrupted = {}, teams = {
            [0] = {side = ''}, [1] = {side = 'antagon'}, [2] = {side = 'Protagon'},
            [3] = {side = 'antagon'}, [4] = {side = 'protagon', ally = 1},
            [5] = {side = '', start = 4}, [6] = {side = '', start = 1},
            [7] = {side = 'unknown'},
        }}
    w.config = dofile('luarules/configs/human_shield.lua')
    w.config.witnessChancePercent = 0
    for team in pairs(w.teams) do w.money[team] = 10000 end
    CMD = {STOP = 0, INSERT = 1, MOVE = 10, ATTACK = 20, AREA_ATTACK = 21, DGUN = 105, CLOAK = 95,
        FIRE_STATE = 45, REPAIR = 40, RECLAIM = 90, RESURRECT = 125, CAPTURE = 130,
        RESTORE = 110, GUARD = 25, PATROL = 15, FIGHT = 16, OPT_INTERNAL = 8, OPT_SHIFT = 32}
    CMDTYPE = {ICON = 0, ICON_UNIT = 12}
    Game = {gameSpeed = 30, mapSizeX = 8192, mapSizeZ = 8192}
    GG = {DisguiseCivilianFor = {}, InterrogationTable = {}, CloseCombatInvolved = {}, CivilianUnitInternalLogicActive = {}}
    function getGameConfig() return {civilians = {panic = {fleeDistance = 300}, activityStates = {started = 'STARTED', ended = 'ENDED'}}, espionage = {raids = {revealedGraphLifetimeFrames = 9000}}} end
    function getParentOfUnit(team, id)
        for parent, children in pairs(GG.InheritanceTable[team]) do if children[id] then return parent end end
    end
    UnitDefNames = {operativepropagator = {id = 1}, civilian_arab0 = {id = 2},
        truck = {id = 3}, operativeinvestigator = {id = 4}, operativeasset = {id = 5},
        air_plane_sniper = {id = 6}, air_parachut = {id = 7}, closecombatarena = {id = 8},
        meleeoperative = {id = 9}}
    WeaponDefNames = {stunpistol = {id = 10}, pistol = {id = 11},
        sniperrifle = {id = 12}, slowsniperrifle = {id = 13}, closecombat = {id = 14}}
    WeaponDefs = {[10] = {}, [11] = {}, [12] = {}, [13] = {}, [14] = {}}
    UnitDefs = {
        [1] = {name = 'operativepropagator', speed = 66, weapons = {{weaponDef = 10}}},
        [2] = {name = 'civilian_arab0', speed = 36, weapons = {{weaponDef = 11}}},
        [3] = {name = 'truck', speed = 100, weapons = {}},
        [4] = {name = 'operativeinvestigator', speed = 66, weapons = {{weaponDef = 10}}},
        [5] = {name = 'operativeasset', speed = 66, weapons = {{weaponDef = 11}, {weaponDef = 12}}},
        [6] = {name = 'air_plane_sniper', speed = 100, weapons = {{weaponDef = 13}}},
        [7] = {name = 'air_parachut', speed = 20, weapons = {}},
        [8] = {name = 'closecombatarena', speed = 0, weapons = {}},
        [9] = {name = 'meleeoperative', speed = 66, weapons = {{weaponDef = 11}, {weaponDef = 14}}},
    }
    function w:add(id, def, team, x)
        self.units[id] = {def = def, team = team, x = x or 0, y = 0, z = 0,
            rules = {}, descs = {}, blocking = {true, true, true, false, true, false, true},
            noSelect = false, capturable = true, speed = 1, hp = 100, built = 1,
            pieces = {center = 1, hostagePoint = 2}, pose = false, shieldReady = true,
            weaponStates = {}}
        for number in ipairs(UnitDefs[def].weapons or {}) do
            self.units[id].weaponStates[number] = {salvoLeft=0,reloadFrame=123}
        end
        if self.gadget then self.gadget:UnitCreated(id, def) end
        return self.units[id]
    end
    function w:all()
        local ids = {}; for id in pairs(self.units) do ids[#ids + 1] = id end
        table.sort(ids); return ids
    end
    function w:commands(id)
        local unit=self.units[id]
        return unit.commands or (unit.command and {unit.command}) or {}
    end
    Spring = {
        GetGaiaTeamID = function() return 0 end,
        GetAllUnits = function() return w:all() end,
        GetTeamList = function() local ids = {}; for id in pairs(w.teams) do ids[#ids+1] = id end; return ids end,
        GetTeamResources = function(team, resource) eq(resource, 'metal', 'upkeep uses money'); return w.money[team] end,
        UseTeamResource = function(team, resource, amount)
            eq(resource, 'metal', 'supply is not charged')
            if w.failPayment or w.money[team] < amount then return false end
            w.money[team] = w.money[team] - amount; return true
        end,
        AddTeamResource = function(team, resource, amount)
            eq(resource, 'metal', 'opponents receive money')
            w.money[team] = w.money[team] + amount
            w.transfers[#w.transfers+1] = {team=team, amount=amount}
        end,
        GetUnitsInCylinder = function(x, z, radius, team)
            w.queries = w.queries + 1
            eq(radius, 300, 'witness search is local')
            local ids = {}
            for _, id in ipairs(w:all()) do
                local u = w.units[id]
                if u.team == team and (u.x-x)^2 + (u.z-z)^2 <= radius^2 then ids[#ids+1] = id end
            end
            return ids
        end,
        GetUnitDefID = function(id) return w.units[id] and w.units[id].def end,
        GetUnitTeam = function(id) return w.units[id] and w.units[id].team end,
        GetUnitAllyTeam = function(id) return w.units[id].team end,
        GetTeamInfo = function(id)
            local team = w.teams[id]; return id, 0, team and team.dead or false, false, team and team.side, id
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
        GetUnitIsBuilding = function(id) return w.units[id] and w.units[id].building end,
        GetUnitWeaponState = function(id,number,key)
            local state=w.units[id].weaponStates[number]
            return key and state[key] or state
        end,
        SetUnitWeaponState = function(id,number,values)
            local state=assert(w.units[id].weaponStates[number],'only actual weapons may be changed')
            for key,value in pairs(values) do state[key]=value end
        end,
        GetUnitVelocity = function(id)
            local u = w.units[id]; return u.vx or 0, u.vy or 0, u.vz or 0, u.velocity or 0
        end,
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
        GetUnitCurrentCommand = function(id)
            local command = w:commands(id)[1]
            if command then return command.id, command.options or {}, command.tag, unpack(command.params) end
        end,
        GetCommandQueue = function(id) return w:commands(id) end,
        GetUnitCommands = function(id) return w:commands(id) end,
        SetUnitMoveGoal = function(id, x, y, z, radius) w.units[id].goal = {x, y, z, radius} end,
        ClearUnitGoal = function(id) w.units[id].goal = nil end,
        GiveOrderToUnit = function(id, cmd) if cmd == CMD.STOP then w.stopped[id] = true end end,
        UnitAttach = function(carrier, civilian, piece, force)
            eq(piece, GG.DisguiseCivilianFor[10] == civilian and 0 or 2, 'visible body uses hostagePoint; hidden identity uses native invisible slot'); check(force, 'forced Lua attachment')
            w.attached = w.attached + 1
            if not w.failAttach and w.failAttachUnit ~= civilian then w.units[civilian].transporter = carrier end
        end,
        UnitDetach = function(id) w.detached = w.detached + 1; w.units[id].transporter = nil end,
        DestroyUnit = function(id, selfDestruct, reclaimed, attacker)
            w.destroyed[#w.destroyed + 1] = {id=id, selfDestruct=selfDestruct,
                reclaimed=reclaimed, attacker=attacker, held=GG.HumanShield.IsHostage(id)}
            w.units[id].dead = true
            if w.gadget then w.gadget:UnitDestroyed(id, w.units[id].def, w.units[id].team, attacker) end
        end,
        FindUnitCmdDesc = function(id, cmd) return w.units[id].descs[cmd] and cmd end,
        InsertUnitCmdDesc = function(id, desc) w.units[id].descs[desc.id] = desc end,
        RemoveUnitCmdDesc = function(id, cmd) w.units[id].descs[cmd] = nil end,
        EditUnitCmdDesc = function(id, cmd, desc)
            for key, value in pairs(desc) do w.units[id].descs[cmd][key] = value end
        end,
        UnitScript = {},
    }
    Spring.UnitScript.GetScriptEnv = function(id)
        local u = w.units[id]; if not u or u.noScript then return nil end
        return {
            startFleeing = function(carrier)
                u.fleeingFrom = carrier
                GG.CivilianUnitInternalLogicActive[id] = {state='STARTED', behaviour='fleeing'}
                return true
            end,
            startFilmingHostage = function(carrier, duration)
                if u.rejectFilming then return false end
                u.filmTarget, u.filmPending, u.filmDuration = carrier, true, duration
                w.stopped[id] = true
                GG.CivilianUnitInternalLogicActive[id] = {state='STARTED', behaviour='filming'}
                return true
            end,
            isFilmingHostage = function(carrier, pending)
                local state = GG.CivilianUnitInternalLogicActive[id]
                return u.filmTarget == carrier and (u.filmingActive or (pending and u.filmPending))
                    and state and state.state == 'STARTED' and state.behaviour == 'filming'
            end,
            stopFilmingHostage = function()
                u.filmTarget, u.filmPending, u.filmingActive = nil, nil, nil
            end,
            canUseHumanShield = function() return u.shieldReady end,
            canBeHumanShield = function() return u.capturable end,
            setHumanShieldCarrier = function(carrier, reason)
                if u.rejectCapture and carrier then return false end
                u.heldBy = carrier
                if not carrier then u.releaseReason = reason end
                return true
            end,
            setHumanShieldActive = function(active) u.pose = active end,
        }
    end
    Spring.UnitScript.CallAsUnit = function(id, fn, ...) return fn(...) end
    GG.CivilianLife = {Interrupt = function(_, id) w.interrupted[id] = true; GG.CivilianUnitInternalLogicActive[id] = nil end}
    function getCultureUnitModelTypes(culture, kind)
        eq(culture, 'international', 'all authored civilian cultures are eligible')
        if kind == 'truck' then return {[3] = true} end
        eq(kind, 'civilian', 'walking civilians only'); return {[2] = true}
    end
    function setSpeedEnv(id, factor)
        w.units[id].speed = GG.HumanShield and GG.HumanShield.AdjustSpeed(id, factor) or factor
    end
    VFS = {Include = function(path)
        if path == 'scripts/lib_UnitScript.lua' or path == 'scripts/lib_mosaic.lua' then return end
        if path == 'luarules/configs/human_shield.lua' then return w.config end
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
    w:add(31, 7, 0, 20)
    w:add(32, 8, 0, 20)
    w:add(33, 9, 2)
    gadget = {}; dofile('luarules/gadgets/game_operative_human_shield.lua')
    w.gadget = gadget; gadget:Initialize(); w.api = GG.HumanShield
    function w:order(id, cmd, params, options)
        local u = self.units[id]
        return self.gadget:AllowCommand(id, u.def, u.team, cmd, params or {}, options or {})
    end
    function w:issue(id, cmd, params, options, engineResult)
        local u = self.units[id]
        params, options = params or {}, options or {}
        if not self:order(id, cmd, params, options) then return false end
        self.commandTag = (self.commandTag or 0) + 1
        -- The native UnitCommand call-in runs before command-AI validation and
        -- queue insertion. A callback alone is not evidence the order survived.
        if self.gadget.UnitCommand then
            self.gadget:UnitCommand(id, u.def, u.team, cmd, params, options, self.commandTag)
        end
        if engineResult == 'reject' then return false end
        if cmd == CMD.CLOAK or cmd == CMD.FIRE_STATE then return true end
        local installedCmd, installedParams, installedOptions = cmd, params, options
        if cmd == CMD.INSERT then
            installedCmd, installedParams, installedOptions = params[2], {}, {coded=params[3]}
            for index=4,#params do installedParams[#installedParams+1]=params[index] end
        end
        local queue=self:commands(id)
        if engineResult == 'cancel' then
            local retained={}
            for _,old in ipairs(queue) do
                if old.id~=installedCmd then retained[#retained+1]=old end
            end
            u.commands, u.command=retained,nil
            return true
        end
        installedParams=self.nextInstalledParams or installedParams
        self.nextInstalledParams=nil
        local installed={id=installedCmd,params=installedParams,options=installedOptions,tag=self.commandTag}
        local shifted=options.shift or (options.coded and options.coded % (CMD.OPT_SHIFT*2)>=CMD.OPT_SHIFT)
        if cmd==CMD.INSERT or shifted then
            local appended={}
            for _,old in ipairs(queue) do appended[#appended+1]=old end
            appended[#appended+1]=installed
            u.commands=appended
        else
            u.commands={installed}
        end
        u.command=nil
        return true
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
    function w:tick(frames)
        for _ = 1, frames or 5 do
            self.frame = self.frame + 1; self.gadget:GameFrame(self.frame)
        end
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
check(w:order(1, TAKE, {10}), 'decoys accept capture orders exactly like innocent hostages')
GG.DisguiseCivilianFor[10] = nil
w.units[1].stunned = true; check(not w:order(1, TAKE, {10}), 'stunned carrier cannot acquire protection'); w.units[1].stunned = nil
GG.InterrogationTable[1] = {[20] = true}
check(not w:order(1, TAKE, {10}), 'already detained carrier cannot grab a civilian')
GG.InterrogationTable[1] = nil
GG.InterrogationTable[20] = {[1] = true}
check(not w:order(1, TAKE, {10}), 'an active interrogator cannot capture after replacing its attack command')
GG.InterrogationTable[20][1] = false
check(w:order(1, TAKE, {10}), 'completed interrogation entries do not permanently disable capture')
GG.InterrogationTable[20] = nil
w.units[1].rules.betrayal_pending = 1
check(not w:order(1, TAKE, {10}), 'betrayal cannot be bypassed by taking a hostage')
w.units[1].rules.betrayal_pending = nil

-- A unit definition is shared across factions. Its current owning faction and
-- live activity, rather than the definition's directory, grant this ability.
check(w.units[23].descs[TAKE] and not w.units[21].descs[TAKE],
    'only the Antagon-owned Asset receives Human Shield')
for _, team in ipairs({0, 2, 5, 7}) do
    local unit = w:add(40, 1, team)
    check(not unit.descs[TAKE] and not unit.descs[RELEASE], 'ineligible faction has no shield controls')
    check(not w:order(40, TAKE, {10}), 'forged capture rejected for ineligible faction')
end
w:add(40, 5, 6)
check(w.units[40].descs[TAKE] and w:order(40, TAKE, {10}),
    'Antagon startUnit fallback also grants shared Asset ability')
w.units[1].pieces.hostagePoint = nil
check(not w:order(1, TAKE, {10}), 'missing authored hostagePoint rejects capture without center fallback')
w.units[1].pieces.hostagePoint = 2
w.units[1].shieldReady = false
check(not w:order(1, TAKE, {10}), 'private script activity may veto capture')
w.units[1].shieldReady = true
w.units[1].building = 30
check(not w:order(1, TAKE, {10}), 'engine build activity independently vetoes capture')
w.units[1].building = nil

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
check(w.api.BlockShot(1, 1, 20) and w.api.BlockShot(1, 1, nil),
    'carrier cannot fire at a unit or ground while holding a hostage')
check(w:order(1, CMD.FIRE_STATE, {2}) and w.api.HasShield(1),
    'aim and fire-state controls retain the hostage without firing')
check(not w.api.BlockShot(23, 1, 1), 'Antagon pistol still fires')
local allowed, priority = w.gadget:AllowWeaponTarget(20, 1, 1, 10, 37)
check(not allowed and priority == 37, 'automatic targeting preserves priority while rejecting target')
check(w.gadget:AllowWeaponTarget(21, 1, 2, 12, 37), 'automatic sniper targeting permitted')
check(w.gadget:AllowWeaponTarget(33, 1, 2, 14, 37), 'incoming melee can initiate the hostage escape transition')
check(not w.gadget:AllowWeaponTarget(33, 1, 1, 11, 37), 'melee-capable attacker still cannot use its pistol')
check(w:order(33, CMD.ATTACK, {1}), 'a melee-capable unit can receive an explicit melee approach order')
check(w.api.BlockShot(33, 1, 1) and not w.api.BlockShot(33, 2, 1),
    'per-shot protection admits only the contact weapon of a mixed melee attacker')
check(not w.api.IsProtected(1, 2, 14), 'projectile impact dispatcher can reach the close-combat callback')
check(w.gadget:UnitPreDamaged(1, 1, 1, 1, false, 14, 500, 33, 9, 2) == nil,
    'native damage hook does not cancel the contact that starts melee')
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
w.units[1].weaponStates[1].salvoLeft=4
w:execute(1, TAKE, {10})
check(not w.api.HasShield(1) and not w.api.IsHostage(10), 'failed native attachment grants no protection')
check(not w.units[10].noSelect and w.units[10].heldBy == nil, 'failed attachment restores civilian state')
near(w.units[1].speed, 1, 'failed attachment leaves normal speed')
eq(w.units[1].weaponStates[1].salvoLeft,4,'failed capture does not cancel an unrelated weapon burst')
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
    if event == 'UnitTaken' then w.gadget:UnitGiven(1, 1, 2, 1) end
    check(not w.units[1].descs[TAKE] and not w.units[1].descs[RELEASE],
        event .. ' removes Antagon-only commands after a Protagon transfer')
    check(not w:order(1, TAKE, {10}), event .. ' does not leave a forged capture route')
    w = world(); w:capture(1, 10); w.units[10].team = 3
    w.gadget[event](w.gadget, 10, 2, 0, 3)
    check(not w.api.HasShield(1) and not w.api.IsHostage(10), event .. ' frees transferred captive')
end
w = world(); w.units[21].team = 1; w.gadget:UnitGiven(21, 5, 1, 2)
check(w.units[21].descs[TAKE], 'an Asset acquired by Antagon gains the ability')
w:capture(21, 10)
check(w.api.BlockShot(21, 1, 20) and w.api.BlockShot(21, 2, 20)
    and w.api.BlockShot(21, 2, nil), 'a carrier cannot fire even its sniper at unit or ground targets')
w.api.Release(21)
check(not w.api.BlockShot(21, 1, 20) and not w.api.BlockShot(21, 2, nil),
    'ordinary Asset firing resumes after release')
w=world()
w.units[23].weaponStates[1]={salvoLeft=4,reloadFrame=600,stockpileQueued=3}
w.units[23].weaponStates[2]={salvoLeft=2,reloadFrame=700,stockpileQueued=5}
w:capture(23,10)
for number,reload in ipairs({600,700}) do
    local weapon=w.units[23].weaponStates[number]
    eq(weapon.salvoLeft,0,'capture cancels already-started burst rounds that bypass BlockShot')
    eq(weapon.reloadFrame,reload,'capture preserves weapon reload debt')
    eq(weapon.stockpileQueued,number==1 and 3 or 5,'capture does not refund or consume other weapon state')
end
w.api.Release(23)
check(w.units[23].weaponStates[1].salvoLeft==0 and w.units[23].weaponStates[2].salvoLeft==0,
    'release never restarts a cancelled pre-hostage burst')

local incompatibleActivities = {
    script = function(unit) unit.shieldReady = false end,
    construction = function(unit) unit.building = 30 end,
    stunned = function(unit) unit.stunned = true end,
    closeCombat = function() GG.CloseCombatInvolved[1] = true end,
    interrogation = function() GG.InterrogationTable[1] = {[20] = true} end,
    interrogator = function() GG.InterrogationTable[20] = {[1] = true} end,
    faction = function(unit) unit.team = 2 end,
    rooftop = function(unit) unit.rules.asset_rooftop = 1 end,
}
for name, begin in pairs(incompatibleActivities) do
    w = world(); w:capture(1, 10); begin(w.units[1]); w:tick()
    check(not w.api.HasShield(1) and not w.api.IsHostage(10),
        'live ' .. name .. ' activity ends an existing shield')
    check(not w.units[10].dead and not w.units[10].transporter,
        'incompatible ' .. name .. ' activity releases the hostage safely')
    near(w.units[1].speed, 1, 'incompatible ' .. name .. ' activity restores speed')
    if name == 'closeCombat' then
        eq(w.units[10].releaseReason, 'melee', 'close combat requests the liberated civilian panic escape')
    end
end

for _, command in ipairs({-3, CMD.REPAIR, CMD.RECLAIM, CMD.RESTORE,
        CMD.RESURRECT, CMD.CAPTURE, CMD_INVESTIGATE, CMD_ASSET_ROOFTOP}) do
    w = world(); w.units[1].command = {id=command,params={30},tag=1}
    check(not w:order(1, TAKE, {10}), 'active incompatible work cannot start Human Shield: ' .. command)
    w.units[1].command = nil; w:capture(1, 10)
    w:issue(1, command, {30}); w:tick()
    check(not w.api.HasShield(1) and not w.units[10].dead,
        'starting incompatible work safely releases captive: ' .. command)
end

local explicitFireOrders = {
    {CMD.ATTACK, {20}},
    {CMD.ATTACK, {50, 0, 50}},
    {CMD.DGUN, {20}},
    {CMD.DGUN, {50, 0, 50}},
    {CMD.AREA_ATTACK, {50, 0, 50, 30}},
    {CMD.ATTACK, {20}, {shift=true, coded=CMD.OPT_SHIFT}},
    {CMD.INSERT, {0, CMD.ATTACK, 0, 20}},
    {CMD.INSERT, {1, CMD.DGUN, CMD.OPT_SHIFT, 50, 0, 50}},
}
for index, order in ipairs(explicitFireOrders) do
    w = world(); w:capture(1, 10)
    check(w:order(1, order[1], order[2], order[3]), 'valid fire command accepted: ' .. index)
    check(w.api.HasShield(1) and not w.units[10].dead and #w.destroyed == 0,
        'AllowCommand is a pure veto stage, not a premature hostage execution: ' .. index)
    check(w:issue(1, order[1], order[2], order[3]), 'engine accepts explicit fire order: ' .. index)
    check(w.api.HasShield(1) and not w.units[10].dead,
        'UnitCommand alone cannot prove the native command was queued: ' .. index)
    w:tick(1)
    check(w.units[10].dead and not w.api.HasShield(1) and not w.api.IsHostage(10),
        'accepted explicit fire kills the hostage and ends shielding: ' .. index)
    eq(#w.destroyed, 1, 'one accepted fire order kills only the held civilian')
    local death=w.destroyed[1]
    check(death.id == 10 and death.attacker == 1 and death.held,
        'hostage dies while still owned by shield lifecycle and attributed to its carrier')
    check(death.selfDestruct == false and death.reclaimed == false,
        'explicit fire uses the real civilian death path, not silent removal')
    near(w.units[1].speed, 1, 'fire command restores operative movement')
    check(not w.api.BlockShot(1, 1, 20), 'the operative can fire only after the hostage has died')
end
for _, params in ipairs({{}, {9999}, {'20'}, {50,0}, {0/0,0,0}, {math.huge,0,0}}) do
    w = world(); w:capture(1, 10)
    check(not w:issue(1, CMD.ATTACK, params), 'malformed fire command is rejected')
    w:tick()
    check(w.api.HasShield(1) and not w.units[10].dead, 'malformed command cannot kill a captive')
end
for index, order in ipairs({
        {CMD.ATTACK,{20},{internal=true}},
        {CMD.ATTACK,{20},{coded=CMD.OPT_INTERNAL}},
        {CMD.INSERT,{0,CMD.ATTACK,CMD.OPT_INTERNAL,20}},
        {CMD.INSERT,{0,CMD.ATTACK,0,20},{internal=true}},
        {CMD.INSERT,{0,CMD.ATTACK,0,20},{coded=CMD.OPT_INTERNAL}},
        {CMD.FIGHT,{50,0,50}},
        {CMD.FIRE_STATE,{2}},
        {CMD.MOVE,{50,0,50}},
    }) do
    w = world(); w:capture(1, 10)
    check(w:issue(1, order[1], order[2], order[3]), 'non-fire or internal order remains accepted')
    w:tick()
    check(w.api.HasShield(1) and not w.units[10].dead,
        'aim/fire stance, movement and internal AI commands do not execute a hostage: ' .. index)
    check(w.api.BlockShot(1, 1, 20), 'ordinary automatic or internally targeted firing remains blocked')
end
w = world(); w:issue(1, CMD.ATTACK, {20}); w:capture(1, 10)
w:tick()
check(w.api.HasShield(1) and w.api.BlockShot(1,1,20) and not w.units[10].dead,
    'an attack ordered before capture cannot execute the newly acquired hostage')

for _, order in ipairs({
        {CMD.ATTACK,{-1000,0,50}},
        {CMD.DGUN,{20}},
        {CMD.INSERT,{999999,CMD.ATTACK,0,20}},
    }) do
    w=world(); w:capture(1,10)
    w:issue(1,order[1],order[2],{},'reject'); w:tick()
    check(w.api.HasShield(1) and not w.units[10].dead and #w.destroyed==0,
        'off-map, unsupported or invalid-insert native rejection must not execute a hostage')
end
w=world(); w:issue(1,CMD.ATTACK,{20}); w:capture(1,10)
w:issue(1,CMD.ATTACK,{20},{shift=true,coded=CMD.OPT_SHIFT},'cancel'); w:tick()
check(w.api.HasShield(1) and not w.units[10].dead,
    'shift-click cancellation of an old queued attack is not a new fire order')
w=world(); w:issue(1,CMD.ATTACK,{20}); w:capture(1,10)
w:issue(1,CMD.ATTACK,{20},{shift=true,coded=CMD.OPT_SHIFT},'reject'); w:tick()
check(w.api.HasShield(1) and not w.units[10].dead,
    'an old matching queue tag cannot satisfy a rejected new fire order')
w=world(); w:capture(1,10); w.nextInstalledParams={50,27,50}
w:issue(1,CMD.ATTACK,{50,0,50}); w:tick()
check(w.units[10].dead and not w.api.HasShield(1),
    'native adjustment of ground Y does not disguise a genuinely new fire order')
w=world(); w:capture(1,10); w:issue(1,CMD.ATTACK,{20})
w.api.Release(1); w:capture(1,10); w:tick()
check(w.api.HasShield(1) and not w.units[10].dead,
    'release cancels pending fire evidence so it cannot execute a recaptured hostage')
w = world(); w:capture(1, 10); w:issue(1, CMD.CLOAK, {1})
check(not w.api.HasShield(1) and not w.units[10].dead,
    'explicitly requesting cloak safely releases the hostage')
w = world(); w:capture(1, 10); w.units[1].dead = true; w.gadget:UnitDestroyed(1)
check(not w.api.IsHostage(10) and not w.units[10].transporter and not w.units[10].dead, 'carrier death releases living civilian')
w = world(); w:capture(1, 10); w.units[10].dead = true; w.gadget:UnitDestroyed(10)
check(not w.api.HasShield(1) and not w.api.IsHostage(10), 'hostage death removes protection')
check(not w.units[10].transporter, 'dying hostage is detached before death cleanup finishes')
near(w.units[1].speed, 1, 'hostage death restores movement')
w = world(); w:capture(1, 10); w.units[10].transporter = nil; w:tick()
check(not w.api.IsHostage(10), 'unexpected engine detachment clears stale state')
w = world(); w:capture(1, 10); w.units[1].transporter = 31; w:tick()
check(not w.api.IsHostage(10), 'boarding a parachute frees captive')
w = world(); w:capture(1, 10); w.units[1].transporter = 30
w.gadget:UnitLoaded(1, 1, 1, 30, 0); w:tick()
check(w.api.HasShield(1) and w.units[10].transporter == 1,
    'boarding an approved road car preserves the nested captive attachment')
check(w.api.IsTransportAllowed(1) and not w.api.IsProtected(30, 2, 11),
    'the car is allowed transport but receives no hostage protection')
check(w:order(20, CMD.ATTACK, {30}) and not w.api.BlockShot(20, 1, 30),
    'ordinary Protagon weapons can attack the occupied car')
check(w.gadget:UnitPreDamaged(30, 3, 0, 100, false, 11, 500, 20, 4, 2) == nil,
    'car damage passes through unchanged')
w.units[30].transporter = 31; w:tick()
check(not w.api.HasShield(1), 'a road car in another transport cannot bypass the parachute restriction')
w = world(); w:capture(1, 10); w.units[1].transporter = 31
w.gadget:UnitLoaded(1, 1, 1, 31, 0)
check(not w.api.HasShield(1), 'illegal boarding releases immediately without waiting for GameFrame')
for _, event in ipairs({'UnitLoaded','UnitStunned'}) do
    w=world(); w:capture(1,10); w.units[1].transporter=32
    if event=='UnitLoaded' then w.gadget:UnitLoaded(1,1,1,32,0)
    else w.gadget:UnitStunned(1,1,1,true) end
    check(not w.api.HasShield(1) and not w.units[10].dead and w.units[10].releaseReason=='melee',
        event .. ' recognizes close-combat arena before the script/GG flag is set and triggers escape')
end
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

-- Load the final unit definition: a duplicate category key used to erase the
-- engine targeting category even when the Lua melee whitelist admitted it.
local humanBase = {}
function humanBase:New(values) return setmetatable(values or {}, {__index = self}) end
local propagatorDefs = execute(read('units/antagon/OperativePropagator.lua'), {
    Human = humanBase, lowerkeys = function(defs) return defs end,
})
check((' ' .. propagatorDefs.operativepropagator.category .. ' '):find(' CLOSECOMBATABLE ', 1, true),
    'the final Propagator definition remains targetable by enemy close-combat weapons')

-- Drive the production impact dispatcher, arena setup and operative callback
-- together. Only native arena/model operations are mocked here.
w = world(); w:capture(1, 10)
local callbackEnv = {
    unitID = 1, CLOSE_COMBAT_SIGHTED = 0.1,
    releaseHumanShield = function(reason) w.api.Release(1, reason) end,
    setViewRadius = function() end,
}
execute(assert(read('scripts/operativePropagatorScript.lua'):match(
    '(function isNowInCloseCombat%([^)]*%)[%s%S]-\nend)')), callbackEnv)
local originalScriptEnv = Spring.UnitScript.GetScriptEnv
local arenaParticipants
Spring.UnitScript.GetScriptEnv = function(id)
    if id == 1 then return callbackEnv end
    if id == 32 then return {addCloseCombatants = function(attacker, victim)
        arenaParticipants = {attacker, victim}
    end} end
    return originalScriptEnv(id)
end
Spring.GetUnitRotation = function() return 0, 0, 0 end
Spring.SetUnitRotation = function() end
Spring.CreateUnit = function(name)
    eq(name, 'closecombatarena', 'melee creates the existing arena type')
    return 32
end
local projectileSource = read('luarules/gadgets/game_ProjectileImpacts.lua')
local meleeEnv = {
    GG = GG, Spring = Spring, GaiaTeamID = 0, gadget = {},
    spGetUnitTeam = Spring.GetUnitTeam,
    UnitDamageFuncT = {}, closeCombatWeaponDefID = 14,
    isCloseCombatCapabaleType = {[1] = true, [9] = true},
    makeDisguiseUnitTransparent = function(id, defID) return id, defID end,
    doesUnitExistAlive = function(id) return w.units[id] and not w.units[id].dead end,
    currentlyInterrogationRunning = function() return false end,
    isInterrogatingAttacker = function() return false end,
    RaidExternalAbort = {}, FireWeapons = {},
}
execute(section(projectileSource, '    local function humanShieldProtects(', '    local MobileInterrogateAbleType')
    .. section(projectileSource, '    function initiateCloseCombat(', '    function isEngagedInAnotherRaidAlready(')
    .. section(projectileSource, '    UnitDamageFuncT[closeCombatWeaponDefID]', '    UnitDamageFuncT[nimrodRailungDefID]')
    .. section(projectileSource, '    function gadget:UnitDamaged(', '    -- ===========Projectile Persistence Functions'), meleeEnv)
meleeEnv.gadget:UnitDamaged(1, 1, 1, 1, false, 14, 999, 33, 9, 2)
check(arenaParticipants and arenaParticipants[1] == 33 and arenaParticipants[2] == 1,
    'Protagon close-combat contact reaches the existing arena dispatch')
check(not w.api.HasShield(1) and not w.units[10].dead and not w.units[10].transporter,
    'the production operative melee callback immediately frees the living hostage')
eq(w.units[10].releaseReason, 'melee', 'the real melee path selects civilian escape behaviour')

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

print('PASS: Antagon-only Human Shield, authored anchor, native queued-fire proof, internal/rejected/cancelled order safety, burst cancellation, vulnerable cars, melee escape, mixed sniper protection, speed and ownership lifecycles')


-- Holding costs are prorated, conserved transfers; empty teams retain protection.
w = world(); w.teams[5].dead=true; w.teams[6].dead=true; w.teams[7].dead=true
w:capture(1,10)
for _=1,6 do w:tick(5) end
near(w.money[1],9960,'one second costs 40 total')
near(w.money[2],10020,'first enemy receives half')
near(w.money[3],10020,'hostile Antagon also receives half')
near(w.money[4],10000,'ally receives nothing')
near(w.money[0],10000,'Gaia receives nothing')
near(w.money[5],10000,'dead team receives nothing')
w.frame=w.frame+3; w.api.Release(1)
near(w.money[1],9956,'release settles a partial second')
w:tick(30); near(w.money[1],9956,'released hostage costs nothing')
w:tick(2); w:capture(1,10); w.money[1]=3; local enemyBefore=w.money[2]+w.money[3]
w:tick(5)
near(w.money[1],0,'partial funds are drained without debt')
near(w.money[2]+w.money[3],enemyBefore+3,'no money created from insufficient funds')
check(w.api.HasShield(1),'poor team retains shield')
w:tick(30); near(w.money[2]+w.money[3],enemyBefore+3,'empty team creates no payout')
w.money[1]=100; w.failPayment=true; w:tick(30)
near(w.money[1],100,'failed debit retains funds')
near(w.money[2]+w.money[3],enemyBefore+3,'failed debit creates no reward')
w.failPayment=false; w:tick(30); near(w.money[1],60,'new income is charged without old debt')
w.teams[3].ally=1; local reward=w.money[2]; w:tick(30)
near(w.money[2],reward+40,'live alliances update recipients')

w=world(); w.units[11].x=40; w:capture(1,10); w:capture(2,11); w:tick(30)
near(w.money[1],9920,'two held hostages cost twice as much')
w.units[1].team=3; w.frame=w.frame+3; w.gadget:UnitTaken(1)
near(w.money[1],9916,'ownership transition settles original payer')
near(w.money[3],10016.8,'new owner receives its share instead of being debited for the old hold')
check(not w.api.HasShield(1),'ownership transition still releases hostage')

-- Filming has one multiplier, begins only after the phone animation starts,
-- and stops on interruption, range departure, capture, death or release.
w=world(); w.config.witnessChancePercent=100
local witness=w:add(40,2,0,100)
local busyWitness=w:add(41,2,0,120)
GG.CivilianUnitInternalLogicActive[41]='STARTED'
w:capture(1,10); eq(witness.fleeingFrom,1,'nearby witness first flees')
check(not busyWitness.fleeingFrom,'legacy busy activity is not interrupted')
w:tick(30); eq(witness.filmTarget,1,'fleeing civilian stops to film this hold')
check(w.stopped[40] and w.api.IsWitness(40),'pending filming owns movement')
eq(w.units[1].rules.human_shield_cost_per_second,40,'pending animation is not billed as filming')
witness.filmPending=nil; witness.filmingActive=true; w:tick(5)
eq(w.units[1].rules.human_shield_cost_per_second,80,'actual filming doubles rate')
local money=w.money[1]; w:tick(30); near(w.money[1],money-80,'filmed second costs exactly 80')
local count=w.queries; w:tick(30); eq(w.queries,count,'active witness needs no repeated area scan')
witness.x=301; w:tick(5)
eq(w.units[1].rules.human_shield_cost_per_second,40,'leaving range restores base rate')
check(not w.api.IsWitness(40) and not witness.filmTarget,'out-of-range witness cleaned up')
witness.x=100; GG.CivilianUnitInternalLogicActive[40]={state='STARTED',behaviour='filming'}
w:tick(30); eq(w.units[1].rules.human_shield_cost_per_second,40,'unrelated filming is not billed')
GG.CivilianUnitInternalLogicActive[40]={state='STARTED',behaviour='fleeing'}
w:tick(30); witness.filmPending=nil; witness.filmingActive=true; w:tick(5)
eq(w.units[1].rules.human_shield_cost_per_second,80,'new filming can resume')
GG.CivilianUnitInternalLogicActive[40]={state='STARTED',behaviour='fleeing'}
w:tick(5); eq(w.units[1].rules.human_shield_cost_per_second,40,'interrupted filming stops surcharge')
w:tick(30); witness.filmPending=nil; witness.filmingActive=true; w:tick(5)
w.api.Release(1)
check(not w.api.IsWitness(40) and not witness.filmTarget,'release stops filming')
eq(w.units[1].rules.human_shield_cost_per_second,0,'release clears advertised upkeep')

w=world(); w.config.witnessChancePercent=100; w.units[11].x=100
w.units[11].transporter=30; w:capture(1,10); w:tick(30)
check(not w.units[11].filmTarget,'passengers cannot witness')
check(not w.api.CanWitness(10,1),'hostage cannot film their own capture')
w.units[11].transporter=nil; GG.DisguiseCivilianFor[11]=2
check(not w.api.CanWitness(11,1),'disguise body cannot film')
GG.DisguiseCivilianFor[11]=nil; w.units[11].stunned=true
check(not w.api.CanWitness(11,1),'stunned civilian cannot film')
w.units[11].stunned=nil; w.units[11].capturable=false
check(not w.api.CanWitness(11,1),'armed or influenced civilian cannot film')
print('PASS: hostage money rates, conserved enemy payouts, poverty, fractional release, witnesses and bounded searches')

-- Poisonous hostages: test the actual gadget, including both attachment lifecycles.
local function decoyWorld()
    local w = world()
    GG.DisguiseCivilianFor[10] = 20
    GG.InheritanceTable = {
        [1] = {[2] = {[1] = true}, [1] = {[23] = true}},
        [2] = {[21] = {[20] = true}, [20] = {[22] = true}},
    }
    return w
end
w = decoyWorld()
w.units[20].weaponStates[1].salvoLeft = 4
w:capture(1,10)
eq(w.units[20].transporter,1,'underlying operative is restrained with the visible captive')
check(w.api.IsHostage(10) and w.api.IsHostage(20),'both identities resolve as the same hostage')
check(not w:order(20,CMD.MOVE,{700,0,700}),'hidden captive cannot walk away')
check(not w:order(20,CMD.INSERT,{0,CMD.ATTACK,0,1}),'insert cannot bypass captive restraint')
check(w.api.BlockShot(20,1,1),'hidden captive cannot fire an existing target')
eq(w.units[20].weaponStates[1].salvoLeft,0,'existing salvo cancelled on capture')
check(w.api.IsProtected(20,2,11) and w.api.IsProtected(10,2,11),'both captive identities inherit ordinary protection')
check(not w.api.IsProtected(20,2,12) and not w.api.IsProtected(10,2,12),'snipers still bypass protection')
eq(w.units[1].rules.human_shield_hostage,10,'public hostage ID remains the civilian')
check(next(w.units[20].rules)==nil,'no hidden identity parameter is published')
local disclosure=GG.RevealedLocations[1]
check(disclosure.revealedUnits[2] and not disclosure.revealedUnits[21]
    and not disclosure.revealedUnits[22] and not disclosure.revealedUnits[20]
    and not disclosure.revealedUnits[23],
    'only captor boss is disclosed, never captive recruiter or either network children')
eq(disclosure.teamID,1,'disclosed network belongs to the captor team')
eq(disclosure.endFrame,9000,'existing intelligence lifetime reused')
w:tick(30)
eq(#GG.RevealedLocations,1,'holding does not duplicate disclosure')
near(w.money[1],9960,'decoy charges the same ordinary upkeep')
w.api.Release(1)
check(not w.api.IsHostage(20) and not w.units[20].transporter and not w.units[10].transporter,'release frees both bodies')
check(w.units[20].blocking[1] and w.units[10].blocking[1],'blocking restored for both bodies')
check(w:order(20,CMD.MOVE,{700,0,700}),'released operative accepts orders again')
eq(GG.RevealedLocations[1],disclosure,'release does not erase intelligence')

w=decoyWorld(); w.failAttachUnit=20
w:execute(1,TAKE,{10})
check(not w.api.HasShield(1) and not w.api.IsHostage(10) and not w.api.IsHostage(20),'failed hidden attachment rolls back both identities')
check(not w.units[10].transporter and not GG.RevealedLocations,'failed capture neither holds nor reveals')
w=decoyWorld(); w.failAttach=true; w:execute(1,TAKE,{10})
check(not GG.RevealedLocations and not w.api.IsHostage(20),'failed first attachment has no hidden side effects')
w=decoyWorld(); w.units[10].rejectCapture=true; w:execute(1,TAKE,{10})
check(not GG.RevealedLocations,'script veto cannot disclose secrets')
w=decoyWorld(); w.units[2].dead=true; w:capture(1,10)
check(not GG.RevealedLocations,'dead captor boss cannot fall back to living captive recruiter')
w=decoyWorld(); GG.InheritanceTable[1]={}; w:capture(1,10)
check(not GG.RevealedLocations,'missing captor boss cannot disclose captive recruiter')
w=decoyWorld(); GG.InheritanceTable[2]=nil; w:capture(1,10)
check(GG.RevealedLocations[1].revealedUnits[2],'captive needs no recruiter to expose the captor boss')
w=decoyWorld(); GG.InheritanceTable=nil; w:capture(1,10)
check(not GG.RevealedLocations,'unrecruited operative is still capturable')
w=world(); GG.InheritanceTable={[1]={[2]={[1]=true}}}; w:capture(1,10)
check(not GG.RevealedLocations,'ordinary civilian does not expose even a captor with a boss')

for _, killed in ipairs({10,20}) do
    w=decoyWorld(); w:capture(1,10); Spring.DestroyUnit(killed,false,false,21)
    check(w.units[10].dead and w.units[20].dead,'death of either body kills the same captive identity')
    eq(#w.destroyed,2,'counterpart death is not recursive or duplicated')
    check(not w.api.HasShield(1) and not w.api.IsHostage(20),'death clears hostage ownership')
    eq(#GG.RevealedLocations,1,'sniping cannot undo already disclosed recruiter')
end
w=decoyWorld(); w:capture(1,10); w.api.Release(1,'melee')
check(w.units[20].goal and not w.units[20].transporter,'melee escape moves the underlying operative too')
w=decoyWorld(); w:capture(1,10); w.gadget:UnitTaken(20)
check(not w.api.HasShield(1) and not w.units[10].transporter,'team transfer frees both identities')
w=decoyWorld(); w:capture(1,10); GG.DisguiseCivilianFor[10]=nil; w:tick(5)
check(not w.api.HasShield(1) and not w.units[20].transporter,'broken identity link releases cleanly')
w=decoyWorld(); w:capture(1,10); w.gadget:Shutdown()
check(not w.units[10].transporter and not w.units[20].transporter,'shutdown detaches both identities')
print('PASS: decoy capture, hidden restraint, recruiter-only disclosure, sniper/death persistence and release rollback')

w=decoyWorld(); w:capture(1,10); Spring.DestroyUnit(1,false,false,21)
check(not w.units[10].dead and not w.units[20].dead,'captor death preserves both living captive bodies')
check(not w.units[10].transporter and not w.units[20].transporter,'captor death detaches both bodies')
w=decoyWorld(); w:capture(1,10); w:issue(1,CMD.ATTACK,{21}); w:tick(5)
check(w.units[10].dead and w.units[20].dead,'accepted execution order kills the operative behind the captive')
eq(w.destroyed[2].attacker,1,'execution keeps attacker attribution on the underlying operative')
eq(#GG.RevealedLocations,1,'execution cannot retract the recruiter disclosure')
