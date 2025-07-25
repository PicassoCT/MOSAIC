-- Enables Lua unit scripts by including the gadget from springcontent.sdz
-- Uncomment to override the directory which is scanned for *.lua unit scripts.
UNITSCRIPT_DIR = "scripts/"

function gadget:GetInfo()
    return {
        name = "Lua unit script framework",
        desc = "Manages Lua unit scripts",
        author = "Tobi Vollebregt",
        date = "2 September 2009",
        license = "GPL v2",
        layer = 0,
        enabled = true --  loaded by default?
    }
end

if (not gadgetHandler:IsSyncedCode()) then return false end

local bool_GadgetDebug = true -- GG.BoolDebug or false
if bool_GadgetDebug == true then
    Spring.Echo("unit_script.lua: bool_GadgetDebug active")
end
if not GG.BoolDebug then GG.BoolDebug = bool_GadgetDebug end
-- This lists all callins which may be wrapped in a coroutine (thread).
-- The ones which should not be thread-wrapped are commented out.
-- Create, Killed, AimWeapon and AimShield callins are always wrapped.
local thread_wrap = {
    -- "StartMoving",
    -- "StopMoving",
    "Activate", "Deactivate", -- "WindChanged",
    -- "ExtractionRateChanged",
    "RockUnit", -- "HitByWeapon",
    -- "MoveRate",
    -- "setSFXoccupy",
    -- "QueryLandingPad",
    "Falling", "Landed", "BeginTransport", -- "QueryTransport",
    "TransportPickup", "StartUnload", "EndTransport", "TransportDrop",
    "StartBuilding", "StopBuilding", -- "QueryNanoPiece",
    -- "QueryBuildInfo",
    -- "QueryWeapon",
    -- "AimFromWeapon",
    "FireWeapon"
    -- "EndBurst",
    -- "Shot",
    -- "BlockShot",
    -- "TargetWeight",
}

local weapon_funcs = {
    "QueryWeapon", "AimFromWeapon", "AimWeapon", "AimShield", "FireWeapon",
    "Shot", "EndBurst", "BlockShot", "TargetWeight"
}

local default_return_values = {
    QueryWeapon = -1,
    AimFromWeapon = -1,
    AimWeapon = false,
    AimShield = false,
    BlockShot = false,
    TargetWeight = 1
}

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

-- Localize often used methods.
local pairs = pairs
local table_remove = table.remove

local co_create = coroutine.create
local co_resume = coroutine.resume
local co_yield = coroutine.yield
local co_running = coroutine.running

local bit_and = math.bit_and
local floor = math.floor

local sp_GetGameFrame = Spring.GetGameFrame
local sp_GetUnitWeaponState = Spring.GetUnitWeaponState
local sp_SetUnitWeaponState = Spring.SetUnitWeaponState
local sp_SetUnitShieldState = Spring.SetUnitShieldState

-- Keep local reference to engine's CallAsUnit/WaitForMove/WaitForTurn,
-- as we overwrite them with (safer) framework version later on.
local sp_CallAsUnit = Spring.UnitScript.CallAsUnit
local sp_WaitForMove = Spring.UnitScript.WaitForMove
local sp_WaitForTurn = Spring.UnitScript.WaitForTurn
local sp_SetPieceVisibility = Spring.UnitScript.SetPieceVisibility
local sp_SetDeathScriptFinished = Spring.UnitScript.SetDeathScriptFinished
local sp_Turn = Spring.UnitScript.Turn

local LUA_WEAPON_MIN_INDEX = 1
local LUA_WEAPON_MAX_INDEX = LUA_WEAPON_MIN_INDEX + 31

local UNITSCRIPT_DIR = (UNITSCRIPT_DIR or "scripts/"):lower()
local VFSMODE = VFS.ZIP_ONLY
if (Spring.IsDevLuaEnabled()) then VFSMODE = VFS.RAW_ONLY end

-- needed here too, and gadget handler doesn't expose it

VFS.Include('luarules/system.lua', nil, VFSMODE)
VFS.Include('gamedata/VFSUtils.lua', nil, VFSMODE)

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

--[[
Data structure to administrate the threads of each managed unit.
We store a set of all threads for each unit, and in two separate tables
the threads which are waiting for a turn or move animation to finish.

The 'thread' stored in waitingForMove/waitingForTurn/sleepers is the table
wrapping the actual coroutine object.  This way the signal_mask etc. is
available too.

The threads table is a weak table.  This saves us from having to manually clean
up dead threads: any thread which is not sleeping or waiting is in none of
(sleepers,waitingForMove,waitingForTurn) => it is only in the threads table
=> garbage collector will harvest it because the table is weak.

Beware the threads are indexed by thread (coroutine), so careless
iteration of threads WILL cause desync!

Format: {
        [unitID] = {
                env = {},  -- the unit's environment table
                waitingForMove = { [piece*3+axis] = thread, ... },
                waitingForTurn = { [piece*3+axis] = thread, ... },
                threads = {
                        [thread] = {
                                thread = thread,      -- the coroutine object
                                signal_mask = object, -- see Signal/SetSignalMask
                                unitID = number,      -- 'owner' of the thread
                                onerror = function,   -- called after thread died due to an error
                        },
                        ...
                },
        },
}
--]]
local units = {} 

-- this keeps track of the unit that is active (ie.
-- running a script) at the time a callin triggers
--
-- the _current_ active unit (ID) is always at the
-- top of the stack (index #activeUnitStack)
local activeUnitStack = {}

local function PushActiveUnitID(unitID)
    activeUnitStack[#activeUnitStack + 1] = unitID
end
local function PopActiveUnitID() activeUnitStack[#activeUnitStack] = nil end
local function GetActiveUnitID() return activeUnitStack[#activeUnitStack] end
local function GetActiveUnit() return units[GetActiveUnitID()] end

--[[
This is the bed, it stores all the sleeping threads,
indexed by the frame in which they need to be woken up.

Format: {
        [framenum] = { [1] = thread1, [2] = thread2, ... },
}

(inner tables are in order the calls to Sleep were made)
--]]
local sleepers = {}
local section = 'unit_script.lua'

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

-- Helper for Destroy and Signal.
-- NOTE:
--   Must not change the relative order of all other elements!
--   Also must not break the #-operator, so removal must leave
--   no holes --> uses table.remove() instead of tab[i] = nil.
local function RemoveTableElement(tab, item)
    local n = #tab
    for i = 1, n do
        if (tab[i] == item) then
            table_remove(tab, i)
            return
        end
    end
end

-- This is put in every script to clean up if the script gets destroyed.
local function Destroy()
    local activeUnit = GetActiveUnit()

    if (activeUnit ~= nil) then
        for _, thread in pairs(activeUnit.threads) do
            if thread.container then
                RemoveTableElement(thread.container, thread)
            end
        end
        units[activeUnit.unitID] = nil
    end
end

-- Pcalls thread.onerror, if present.
local function RunOnError(thread)
    local fun = thread.onerror
    if fun then
        local good, err = pcall(fun, err)
        if (not good) then
            Spring.Log(section, LOG.ERROR, "error in error handler: " .. err)
        end
    end
end

-- Helper for AnimFinished, StartThread and gadget:GameFrame.
-- Resumes a sleeping or waiting thread; displays any errors.
local function WakeUp(thread, ...)
    thread.container = nil
    local co = thread.thread
    local good, err = co_resume(co, ...)
    if (not good) then
        Spring.Log(gadget:GetInfo().name, LOG.ERROR, err)

        --  Spring.Log(gadget:GetInfo().name, LOG.ERROR, debug.traceback(co))
        RunOnError(thread)
    end
end

-- Helper for MoveFinished and TurnFinished
local function AnimFinished(waitingForAnim, piece, axis)
    local index = piece * 3 + axis
    local wthreads = waitingForAnim[index]
    local wthread = nil

    if wthreads then
        waitingForAnim[index] = {}

        while (#wthreads > 0) do
            wthread = wthreads[#wthreads]
            wthreads[#wthreads] = nil

            WakeUp(wthread)
        end
    end
end

-- MoveFinished and TurnFinished are put in every script by the framework.
-- They resume the threads which were waiting for the move/turn.
local function MoveFinished(piece, axis)
    local activeUnit = GetActiveUnit()
    local activeAnim = activeUnit.waitingForMove
    return AnimFinished(activeAnim, piece, axis)
end

local function TurnFinished(piece, axis)
    local activeUnit = GetActiveUnit()
    local activeAnim = activeUnit.waitingForTurn
    return AnimFinished(activeAnim, piece, axis)
end

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

-- overwrites engine's CallAsUnit
function Spring.UnitScript.CallAsUnit(unitID, fun, ...)
    PushActiveUnitID(unitID)
    assert(unitID)
    local ret = {sp_CallAsUnit(unitID, fun, ...)}
    PopActiveUnitID()

    return unpack(ret)
end

local function CallAsUnitNoReturn(unitID, fun, ...)
    PushActiveUnitID(unitID)
    sp_CallAsUnit(unitID, fun, ...)
    PopActiveUnitID()
end

-- Helper for WaitForMove and WaitForTurn
-- Unsafe, because it does not check whether the animation to wait for actually exists.
local function WaitForAnim(threads, waitingForAnim, piece, axis)
    local index = piece * 3 + axis
    local wthreads = waitingForAnim[index]
    if (not wthreads) then
        wthreads = {}
        waitingForAnim[index] = wthreads
    end
    local thread = threads[co_running() or error("not in a thread", 2)]
    wthreads[#wthreads + 1] = thread
    thread.container = wthreads
    -- yield the running thread:
    -- it will be resumed once the wait finished (in AnimFinished).
    co_yield()
end

-- overwrites engine's WaitForMove
function Spring.UnitScript.WaitForMove(piece, axis)
    if not piece then
        activeUnit = GetActiveUnit()
        local ud = UnitDefs[Spring.GetUnitDefID(activeUnit.unitID)]
        Spring.Log(gadget:GetInfo().name, LOG.ERROR,
                   "Unit " .. ud.name .. " has error in a waitformove ")

    end

    if sp_WaitForMove(piece, axis) then
        local activeUnit = GetActiveUnit()
        return WaitForAnim(activeUnit.threads, activeUnit.waitingForMove, piece,
                           axis)
    end
end

-- overwrites engine's WaitForTurn
function Spring.UnitScript.WaitForTurn(piece, axis)

    if sp_WaitForTurn(piece, axis) then
        local activeUnit = GetActiveUnit()
        return WaitForAnim(activeUnit.threads, activeUnit.waitingForTurn, piece,
                           axis)
    end
end

function Spring.UnitScript.Sleep(milliseconds)
    if not milliseconds then
        local activeUnit = GetActiveUnit() or
                               error("Active Unit with nil sleep", 2)
        local ud = UnitDefs[Spring.GetUnitDefID(activeUnit.unitID)]
        Spring.Log(gadget:GetInfo().name, LOG.WARNING,
                   "UnitDef: " .. ud.name .. "has a nil  Sleep")
    end

    local n = floor(milliseconds / 33)
    if (n <= 0) then n = 1 end
    n = n + sp_GetGameFrame()
    local zzz = sleepers[n]
    if (not zzz) then
        zzz = {}
        sleepers[n] = zzz
    end

    local activeUnit = GetActiveUnit() or
                           error("[Sleep] no active unit on stack?", 2)
    local activeThread = activeUnit.threads[co_running() or
                             error("[Sleep] not in a thread?", 2)]
    if not activeThread then
        local ud = UnitDefs[Spring.GetUnitDefID(activeUnit.unitID)]
        Spring.Log(gadget:GetInfo().name, LOG.WARNING,
                   "UnitDef: " .. ud.name .. " has a unthreaded Sleep")
    end

    zzz[#zzz + 1] = activeThread
    activeThread.container = zzz
    -- yield the running thread:
    -- it will be resumed in frame #n (in gadget:GameFrame).
    co_yield()
end

function Spring.UnitScript.StartThread(fun, ...)
    -- DEBUG
    if (not fun) then
        error(
            "Error in UnitScript::Spring.UnitScript.StartThread - First Argument of StartThread is not a function ",
            2)
    end
    local activeUnit = GetActiveUnit()
    local co = co_create(fun)
    -- signal_mask is inherited from current thread, if any
    local thd = co_running() and activeUnit.threads[co_running()]
    local sigmask = thd and thd.signal_mask or 0
    local thread = {
        thread = co,
        signal_mask = sigmask,
        unitID = activeUnit.unitID
    }

    -- add the new thread to activeUnit's registry
    activeUnit.threads[co] = thread

    -- COB doesn't start thread immediately: it only sets up stack and
    -- pushes parameters on it for first time the thread is scheduled.
    -- Here it is easier however to start thread immediately, so we don't need
    -- to remember the parameters for the first co_resume call somewhere.
    -- I think in practice the difference in behavior isn't an issue.
    return WakeUp(thread, ...)
end

local function SetOnError(fun)
    local activeUnit = GetActiveUnit()
    local activeThread = activeUnit.threads[co_running()]
    if activeThread then activeThread.onerror = fun end
end

function Spring.UnitScript.SetSignalMask(mask)


    local activeUnit = GetActiveUnit()
    local activeThread = activeUnit.threads[co_running() or
                             error("[SetSignalMask] not in a thread", 2)]
    if (activeThread.signal_mask_set) then
        local ud = UnitDefs[Spring.GetUnitDefID(activeUnit.unitID)]
        x, y, z = Spring.GetUnitPosition(activeUnit.unitID)
        Spring.Log(gadget:GetInfo().name, LOG.WARNING,
                   "Warning: Spring.UnitScript.SetSignalMask called second time for the same thread (possible lack of StartThread?)")
        Spring.Log(gadget:GetInfo().name, LOG.WARNING,
                   "UnitDef: " .. ud.name .. " Old mask: " ..
                       activeThread.signal_mask .. " New mask: " .. mask)
        --    Spring.Log(gadget:GetInfo().name, LOG.WARNING, "@ Position: x= "..x.."  |  z= "..z)               
    end
    activeThread.signal_mask = mask
end

function Spring.UnitScript.Signal(mask)
    local activeUnit = GetActiveUnit()

    -- beware, unsynced loop order
    -- (doesn't matter here as long as all threads get removed)
    if type(mask) == "number" then
        for _, thread in pairs(activeUnit.threads) do
            local signal_mask = thread.signal_mask
            if signal_mask and (bit_and(signal_mask, mask) ~= 0 and thread.container) then
                RemoveTableElement(thread.container, thread)
            end
        end
    else
        for _, thread in pairs(activeUnit.threads) do
            if (thread.signal_mask == mask and thread.container) then
                RemoveTableElement(thread.container, thread)
            end
        end
    end
end

function Spring.UnitScript.Hide(piece)
    if not piece then
        local activeUnit = GetActiveUnit()
        local defID = Spring.GetUnitDefID(activeUnit.unitID)
        Spring.Echo("Invalid PieceNumber in "..UnitDefs[defID].name)
        return
    end

    --local pieceType = type(piece)
    --if pieceType ~= "number" then
    --    local activeUnit = GetActiveUnit()
    --    local unitType =type(activeUnit)
    --    Spring.Echo("Active Unit is of type:".. unitType)
    --    if unitType == "table" then
    --        for k,v in pairs(activeUnit) do
    --            Spring.Echo("Key: "..k.. " -> ".. tostring(v))
    --            if k == "unitID" then
    --                local defID = Spring.GetUnitDefID(v)
    --                Spring.Echo("Faulty hide in unittype:"..defID)
    --            end
    --        end
    --    else
    --        local defID = Spring.GetUnitDefID(activeUnit)
    --        local name = UnitDefs[defID].name
    --        Spring.Echo("Hide Piece has not a number in "..name.."- got "..pieceType, piece)      
    --    end
    --end 
   
    return sp_SetPieceVisibility(piece, false)
end

function Spring.UnitScript.Show(piece)

    if bool_GadgetDebug == true and piece and type(piece) ~= "number" and
       type(piece) ~= "function" then
        local activeUnit = GetActiveUnit()
        local defID = Spring.GetUnitDefID(activeUnit.unitID)
        Spring.Echo("Invalid PieceNumber in show in  "..UnitDefs[defID].name)
        Spring.Echo("PieceNumber not a number " .. piece .. " - got " ..type(piece) .. " with value " .. piece .. " instead")
    end
    if bool_GadgetDebug == true and (not piece) then
       error("Error: Piece  not handed as argument", 2)
    end

    return sp_SetPieceVisibility(piece, true)
end

-- may be useful to other gadgets
function Spring.UnitScript.GetScriptEnv(unitID)
    local unit = units[unitID]
    if unit then return unit.env end
    return nil
end

function Spring.UnitScript.GetLongestReloadTime(unitID)
    local longest = 0
    for i = LUA_WEAPON_MIN_INDEX, LUA_WEAPON_MAX_INDEX do
        local reloadTime = sp_GetUnitWeaponState(unitID, i, "reloadTime")
        if (not reloadTime) then break end
        if (reloadTime > longest) then longest = reloadTime end
    end
    return 1000 * longest
end

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

local scriptHeader = VFS.LoadFile("gamedata/unit_script_header.lua", VFSMODE)

-- Newlines (and comments) are stripped to not change line numbers in stacktraces.
scriptHeader = scriptHeader:gsub("%-%-[^\r\n]*", ""):gsub("[\r\n]", " ")

--[[
Dictionary mapping script name (without path or extension) to a Lua chunk which
returns a new closure (read; instance) of this unitscript.

Format: {
        [unitID] = chunk,
}
--]]
local scripts = {}

-- Creates a new prototype environment for a unit script.
-- This environment is used as prototype for the unit script instances.
-- (To save on time copying and space for a copy for each and every unit.)
local prototypeEnv
do
    local script = {}
    for k, v in pairs(System) do script[k] = v end
    -- script._G = _G  -- the global table. (Update: _G points to unit environment now)
    script.GG = GG -- the shared table (shared with gadgets!)
    prototypeEnv = script
end

local function Basename(filename) return filename:match("[^\\/:]*$") or filename end

local function LoadChunk(filename)
    local text = VFS.LoadFile(filename, VFSMODE)
    -- Spring.Echo("Loading File:: "..filename)
    if (text == nil) then
        Spring.Log(gadget:GetInfo().name, LOG.ERROR,
                   "Failed to load: " .. filename)
        return nil
    end
    local chunk, err = loadstring(scriptHeader .. text, filename)
    if (chunk == nil) then
        Spring.Log(gadget:GetInfo().name, LOG.ERROR, "Failed to load: " ..
                       Basename(filename) .. "  (" .. err .. ")")
        return nil
    else
        -- Spring.Echo("Completed Loading File: "..filename)
    end
    return chunk
end

local function LoadScript(scriptName, filename)
    local chunk = LoadChunk(filename)
    scripts[scriptName] = chunk
    return chunk
end

function gadget:Initialize()
    Spring.Echo(GetInfo().name .. " Initialization started")
    Spring.Echo(string.format("Loading gadget: %-18s  <%s>", ghInfo.name,
                              ghInfo.basename))

    -- This initialization code has following properties:
    --  * all used scripts are loaded => early syntax error detection
    --  * unused scripts aren't loaded
    --  * files can be arbitrarily ordered in subdirs (like defs)
    --  * exact path doesn't need to be specified
    --  * exact path can be specified to resolve ambiguous basenames
    --  * engine default scriptName (with .cob extension) works

    -- Recursively collect files below UNITSCRIPT_DIR.
    local scriptFiles = {}
    for _, filename in ipairs(RecursiveFileSearch(UNITSCRIPT_DIR, "*.lua",
                                                  VFSMODE)) do
        local basename = Basename(filename)
        scriptFiles[filename] = filename -- for exact match
        scriptFiles[basename] = filename -- for basename match
    end

    -- Go through all UnitDefs and load scripts.
    -- Names are tested in following order:
    --  * exact match
    --  * basename match
    --  * exact match where .cob->.lua
    --  * basename match where .cob->.lua
    for i = 1, #UnitDefs do
        local unitDef = UnitDefs[i]
        if (unitDef and not scripts[unitDef.scriptName]) then
            local fn = UNITSCRIPT_DIR .. unitDef.scriptName:lower()
            local bn = Basename(fn)
            local cfn = fn:gsub("%.cob$", "%.lua")
            local cbn = bn:gsub("%.cob$", "%.lua")
            local filename = scriptFiles[fn] or scriptFiles[bn] or
                                 scriptFiles[cfn] or scriptFiles[cbn]
            if filename then
                Spring.Echo("  Loading unit script: " .. filename)
                LoadScript(unitDef.scriptName, filename)
            end
        end
    end

    -- Fake UnitCreated events for existing units. (for '/luarules reload')
    local allUnits = Spring.GetAllUnits()
    for i = 1, #allUnits do
        local unitID = allUnits[i]
        gadget:UnitCreated(unitID, Spring.GetUnitDefID(unitID))
    end
    Spring.Echo(GetInfo().name .. " Initialization ended")
end

--------------------------------------------------------------------------------

local StartThread = Spring.UnitScript.StartThread

local function Wrap_AimWeapon(unitID, callins)
    local AimWeapon = callins["AimWeapon"]
    if (not AimWeapon) then return end

    -- SetUnitShieldState wants true or false, while
    -- SetUnitWeaponState wants 1.0 or 0.0, niiice =)
    -- NOTE:
    --   the LuaSynced* API functions all EXPECT 1-based arguments
    --   the LuaUnitScript::*Weapon* callins all SUPPLY 1-based arguments
    --
    --   therefore on the Lua side all weapon indices are ASSUMED to be
    --   1-based and if LuaConfig::LUA_WEAPON_BASE_INDEX is changed to 0
    --   no Lua code should need to be updated  

    local function AimWeaponThread(weaponNum, heading, pitch)
        local bAimReady = AimWeapon(weaponNum, heading, pitch) or false
        local fAimReady = (bAimReady and 1.0) or 0.0

        return sp_SetUnitWeaponState(unitID, weaponNum, "aimReady", fAimReady)
    end

    callins["AimWeapon"] = function(weaponNum, heading, pitch)
        return StartThread(AimWeaponThread, weaponNum, heading, pitch)
    end
end

local function Wrap_AimShield(unitID, callins)
    local AimShield = callins["AimShield"]
    if (not AimShield) then return end
    -- SetUnitShieldState wants true or false, while
    -- SetUnitWeaponState wants 1 or 0, niiice =)
    local function AimShieldThread(weaponNum)
        local enabled = AimShield(weaponNum) and true or false
        return sp_SetUnitShieldState(unitID, weaponNum, enabled)
    end

    callins["AimShield"] = function(weaponNum)
        return StartThread(AimShieldThread, weaponNum)
    end
end

local function Wrap_Killed(unitID, callins)
    local Killed = callins["Killed"]
    if (not Killed) then return end

    local function KilledThread(recentDamage, maxHealth)
        -- It is *very* important the sp_SetDeathScriptFinished is executed, even on error.
        SetOnError(sp_SetDeathScriptFinished)
        local wreckLevel = Killed(recentDamage, maxHealth)
        sp_SetDeathScriptFinished(wreckLevel)
    end

    callins["Killed"] = function(recentDamage, maxHealth)
        StartThread(KilledThread, recentDamage, maxHealth)
        return -- no return value signals Spring to wait for SetDeathScriptFinished call.
    end
end

local function Wrap(callins, name)
    local fun = callins[name]
    if (not fun) then return end

    callins[name] = function(...) return StartThread(fun, ...) end
end

--------------------------------------------------------------------------------

--[[
Storage for MemoizedInclude.
Format: { [filename] = chunk }
--]]
local include_cache = {}

-- core of include() function for unit scripts
local function ScriptInclude(filename)
    -- Spring.Echo("  Loading include: " .. UNITSCRIPT_DIR .. filename)
    local chunk = LoadChunk(UNITSCRIPT_DIR .. filename)
    if chunk then
        include_cache[filename] = chunk
        return chunk
    end
end

-- memoize it so we don't need to decompress and parse the .lua file everytime..
local function MemoizedInclude(filename, env)
    local chunk = include_cache[filename] or ScriptInclude(filename)
    if chunk then
        -- overwrite environment so it access environment of current unit
        setfenv(chunk, env)
        return chunk()
    end
end

--------------------------------------------------------------------------------

function gadget:UnitCreated(unitID, unitDefID, unitTeamID, parentID)
    local ud = UnitDefs[unitDefID]
    local chunk = scripts[ud.scriptName]
    if (not chunk) then return end

    -- Global variables in the script are still per unit.
    -- Set up a new environment that is an instance of the prototype
    -- environment, so we don't need to copy all globals for every unit.

    -- This means of course, that global variable accesses are a bit more
    -- expensive inside unit scripts, but this can be worked around easily
    -- by localizing the necessary globals.

    local pieces = Spring.GetUnitPieceMap(unitID)
    local env = {
        fatherID = parentID,
        unitID = unitID,
        unitDefID = unitDefID,
        script = {} -- will store the callins
    }

    -- easy self-referencing (Note: use of _G differs from _G in gadgets & widgets)
    env._G = env

    env.include = function(f) return MemoizedInclude(f, env) end

    env.piece = function(...)

        local p = {}
        for _, name in ipairs {...} do

            if pieces[name] == nil then
                --	Spring.Echo("Piece "..name.." not found in unittype: "..getUnitTypeName(unitDefID))
                error("piece not found: " .. tostring(name), 2)
            else
                p[#p + 1] = pieces[name] or
                                error("piece not found: " .. tostring(name), 2)
            end
        end
        return unpack(p)
    end

    setmetatable(env, {__index = prototypeEnv})
    setfenv(chunk, env)

    -- Execute the chunk. This puts the callins in env.script
    CallAsUnitNoReturn(unitID, chunk)
    local callins = env.script

    -- Add framework callins.
    callins.MoveFinished = MoveFinished
    callins.TurnFinished = TurnFinished
    callins.Destroy = Destroy

    -- AimWeapon/AimShield is required for a functional weapon/shield,
    -- so it doesn't hurt to not check other weapons.
    if ((not callins.AimWeapon and callins.AimWeapon1) or
        (not callins.AimShield and callins.AimShield1)) then
        for j = 1, #weapon_funcs do
            local name = weapon_funcs[j]
            local dispatch = {}
            local n = 0
            for i = 1, #ud.weapons do
                local fun = callins[name .. i]
                if fun then
                    dispatch[i] = fun
                    n = n + 1
                end
            end
            if (n == #ud.weapons) then
                -- optimized case
                callins[name] = function(w, ...)
                    return dispatch[w](...)
                end
            elseif (n > 0) then
                -- needed for QueryWeapon / AimFromWeapon to return -1
                -- while AimWeapon / AimShield should return false, etc.
                local ret = default_return_values[name]
                callins[name] = function(w, ...)
                    local fun = dispatch[w]
                    if fun then return fun(...) end
                    return ret
                end
            end
        end
    end

    -- Wrap certain callins in a thread and/or safety net.
    for i = 1, #thread_wrap do Wrap(callins, thread_wrap[i]) end
    Wrap_AimWeapon(unitID, callins)
    Wrap_AimShield(unitID, callins)
    Wrap_Killed(unitID, callins)

    -- Wrap everything so activeUnit get's set properly.
    for k, v in pairs(callins) do
        local fun = callins[k]

        callins[k] = function(...)
            PushActiveUnitID(unitID)
            ret = fun(...)
            PopActiveUnitID()

            return ret
        end
    end

    -- Register the callins with Spring.
    Spring.UnitScript.CreateScript(unitID, callins)

    -- Register (must be last: it shouldn't be done in case of error.)
    units[unitID] = {
        env = env,
        unitID = unitID,
        waitingForMove = {},
        waitingForTurn = {},
        threads = setmetatable({}, {__mode = "kv"}) -- weak table
    }

    -- Now it's safe to start a thread which will run Create().
    -- (Spring doesn't run it, and if it did, it would do so too early to be useful.)
    if callins.Create then
        CallAsUnitNoReturn(unitID, StartThread, callins.Create)
    end
end

local memory_tracker = {
    tracked_tables = {},
    history_depth = 3 -- how many past measurements to check for constant growth
}

function gadget:GameFrame()
    local n = sp_GetGameFrame()
    local zzz = sleepers[n]

    if zzz then
        sleepers[n] = nil

        -- Wake up the lazy bastards for this frame (in reverse order).
        -- NOTE:
        --   1. during WakeUp() a thread t1 might Signal (kill) another thread t2
        --   2. t2 might also be registered in sleepers[n] and not yet woken up
        --   3. if so, t1's signal would cause t2 to be removed from sleepers[n]
        --      via Signal --> RemoveTableElement
        --   4. therefore we cannot use the "for i = 1, #zzz" pattern since the
        --      container size/contents might change while we are iterating over
        --      it (and a Lua for-loop range expression is only evaluated once)
        while (#zzz > 0) do
            local sleeper = zzz[#zzz]
            local unitID = sleeper.unitID

            zzz[#zzz] = nil
           -- Spring.Echo("Entering Unit of type "..UnitDefs[Spring.GetUnitDefID(unitID)].name)
            PushActiveUnitID(unitID)
            sp_CallAsUnit(unitID, WakeUp, sleeper)
            PopActiveUnitID()
        end
    end
    if bool_GadgetDebug then
        --memory_tracker:track("GG", GG)
    end
end

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

-- Helper to deep-size a table
local function sizeof(obj, seen)
    if type(obj) ~= "table" then
        return 0
    end
    seen = seen or {}
    if seen[obj] then
        return 0
    end
    seen[obj] = true

    local size = 0
    for k, v in pairs(obj) do
        size = size + sizeof(k, seen)
        size = size + sizeof(v, seen)
    end

    size = size + 40 -- base table overhead
    return size
end

-- Helper: get size breakdown per key
local function sizeof_keys(tbl)
    local sizes = {}
    for k, v in pairs(tbl) do
        if type(v) == "table" then
            sizes[k] = sizeof(v)
        else
            sizes[k] = 0
        end
    end
    return sizes
end

-- Check if measurements are constantly growing
local function is_constantly_increasing(history)
    for i = 2, #history do
        if history[i] <= history[i-1] then
            return false
        end
    end
    return true
end

function memory_tracker:track(name, tbl)
    local current_size = sizeof(tbl)
    local info = self.tracked_tables[name]

    if not info then
        info = { history = {}, last_sizes = {} }
        self.tracked_tables[name] = info
    end

    table.insert(info.history, current_size)
    if #info.history > self.history_depth then
        table.remove(info.history, 1)
    end

    -- Only act if we have enough history
    if #info.history == self.history_depth then
        if is_constantly_increasing(info.history) then
            Spring.Echo(string.format("[ALERT] %s is constantly growing!", name))
            Spring.Echo( string.format("  Previous sizes: %s", table.concat(info.history, " -> ")))
            Spring.Echo( string.format("  Current total size: %d bytes", current_size))

            -- Try to find the growing part
            local current_key_sizes = sizeof_keys(tbl)
            local last_key_sizes = info.last_sizes
            local biggest_growth = nil
            local biggest_growth_amount = -math.huge
            for k, sz in pairs(current_key_sizes) do
                local last_sz = last_key_sizes[k] or 0
                local growth = sz - last_sz
                if growth > biggest_growth_amount then
                    biggest_growth = k
                    biggest_growth_amount = growth
                end
            end

            if biggest_growth then
                Spring.Echo(string.format("  Most suspicious growth: key '%s' (+%d bytes)", tostring(biggest_growth), biggest_growth_amount))
            else
                Spring.Echo("  No suspicious growth detected at key level.")
            end
        end
    end

    -- Update last key sizes
    info.last_sizes = sizeof_keys(tbl)
end

function memory_tracker:untrack(name)
    self.tracked_tables[name] = nil
end

function memory_tracker:list()
    Spring.Echo("Currently tracked tables:")
    for name, info in pairs(self.tracked_tables) do
        local latest = info.history[#info.history] or 0
        Spring.Echo(string.format("  %s -> %d bytes", name, latest))
    end
end