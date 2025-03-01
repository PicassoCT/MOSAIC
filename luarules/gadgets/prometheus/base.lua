-- Author: Tobi Vollebregt
-- License: GNU General Public License v2

--[[
This class is implemented as a single function returning a table with public
interface methods.  Private data is stored in the function's closure.

Public interface:

local BaseMgr = CreateBaseMgr(myTeamID, myAllyTeamID, Log)

function BaseMgr.GameFrame(f)
function BaseMgr.UnitCreated(unitID, unitDefID, unitTeam, builderID)
function BaseMgr.UnitFinished(unitID, unitDefID, unitTeam)
function BaseMgr.UnitDestroyed(unitID, unitDefID, unitTeam, attackerID, attackerDefID, attackerTeam)

Possible improvements:
- Give baseBuilders a GUARD order just after they are finished, so they don't
  wander off towards the enemy first, and then later come back to help building.
  (Take care of them blocking the factory in case they can assist building from
  inside the factory...)
- Rebuild destroyed buildings with higher priority then continuing on BO.
- Split base builder group in two groups when it becomes too big. This would
  allow it to truely expand exponentionally :-)
]]--

function CreateBaseMgr(myTeamID, myAllyTeamID, Log)

local BaseMgr = {}

local MIN_INT, MAX_INT = -2147483648, 2147483648
local MAX_SIMTIME = 30.0 * 60  -- 30 minutes
local METAL_PULL_PUSH_FACTOR = 10.0
local MAX_SQUAD_SIZE = 10.0
local MAX_E_STORAGE = 15000.0
local MAX_FLAG_CAPTURE_CAPACITY = 10.0 * 500
local MAX_LOS_CAPACITY = math.max(Game.mapSizeX, Game.mapSizeZ) / 10.0
local MAX_CONSTRUCTORS = 5.0
local MAX_UNIT_IN_FACTORIES = 5.0
local SCORE_RANDOMIZER = 0.05

-- If in 1 minute the building chain has not any progress, we are giving up and
-- starting a new one
local CHAIN_GIVING_UP_TIME = 1.0 * 60.0

-- speedups
local CMD_WAIT   = CMD.WAIT
local random, min, max = math.random, math.min, math.max
local GetUnitDefID       = Spring.GetUnitDefID
local GetGameSeconds     = Spring.GetGameSeconds
local GetUnitCommands    = Spring.GetUnitCommands
local GetFactoryCommands = Spring.GetFactoryCommands
local GetTeamResources   = Spring.GetTeamResources
local GetGameSeconds     = Spring.GetGameSeconds
local GetUnitRulesParam  = Spring.GetUnitRulesParam

-- Squads
local squadDefs = VFS.Include("LuaRules/Configs/squad_defs.lua")
local sortieDefs = VFS.Include("LuaRules/Configs/sortie_defs.lua")
for name, data in pairs(sortieDefs) do
    squadDefs[name] = {
        members = data.members
    }
end

-- tools
local buildsiteFinderModule = VFS.Include("LuaRules/Gadgets/prometheus/base/buildsite.lua")
local unit_chains = VFS.Include("LuaRules/Gadgets/prometheus/base/unit_reqs.lua")
local unit_scores = VFS.Include("LuaRules/Gadgets/prometheus/base/unit_score.lua")
local buildsiteFinder = buildsiteFinderModule.CreateBuildsiteFinder(myTeamID)

-- Base building capabilities
local myConstructors = {}     -- Units which may build the base
local myFactories = {}        -- Factories already available, with their queue
local myFactoriesScore = {}   -- Score associated to the factory
local myPackedFactories = {}  -- Packed factories, which shall unpack

local function doesUnitExistAlive(id)
    local valid = Spring.ValidUnitID(id)
    if valid == nil or valid == false then
        -- echo("doesUnitExistAlive::Invalid ID")
        return false
    end

    local dead = Spring.GetUnitIsDead(id)
    if dead == nil or dead == true then
        -- echo("doesUnitExistAlive::Dead Unit")
        return false
    end

    return true
end

local function count(T)
    if not T then return 0 end
    local index = 0
    for k, v in pairs(T) do if v then index = index + 1 end end
    return index
end

local function GetBuildingChains()
    local producers = {}

    for u, _ in pairs(myConstructors) do
        local defID = GetUnitDefID(u)
        if defID then
            if not producers[defID] then producers[defID] = {}; Log("Adding first producer of type "..UnitDefs[defID].name); end
            producers[defID][#producers[defID]+1] = u
        end
    end
    for u, _ in pairs(myFactories) do
       local defID = GetUnitDefID(u)
        if defID then 
            if not producers[defID] then producers[defID] = {}; Log("Adding first producer of type "..UnitDefs[defID].name); end
            producers[defID][#producers[defID]+1] = u
        end
    end

    local chains = {}
    for unitDefID, builders in pairs(producers) do
        if builders and builders[1] then
            local unitID = builders[1] 
            local builderCount = count(builders)
            if builderCount > 1 then 
                local dice = math.random(1,builderCount)
                local replacementBuilder = builders[dice] 
                if replacementBuilder and doesUnitExistAlive(replacementBuilder) == true then
                    unitID = replacementBuilder
                end
            end
            
            local subchains = unit_chains.GetBuildCriticalLines(unitDefID)
            for target, chain in pairs(subchains) do
                if (chains[target] == nil) or (chains[target].metal > chain.metal) then
                    chains[target] = {
                        builder = unitID,
                        metal = chain.metal,
                        units = chain.units,
                    }
                end
            end
        end
    end

    return chains
end

-- Chain of units to reach the target
local selected_chain = nil
local n_view, n_cap, n_constructor = 0, 0, 0
local gann = gadget.base_gann

local function __clamp(v, min_val, max_val)
    min_val = min_val ~= nil and min_val or -1
    max_val = max_val ~= nil and max_val or 1    
    return min(max(v, min_val), max_val)
end

local function __canBuild(builderDefID, unitDefID)
    if not UnitDefs[builderDefID] then return false end
    if not UnitDefs[builderDefID].buildOptions then return false end

    local children = UnitDefs[builderDefID].buildOptions
    for _, c in ipairs(children) do
        if c == unitDefID or (UnitDefs[c] and (UnitDefs[c].id == unitDefID)) then
            return true
        end
    end
    return false
end

local function GetAllBuilders(unitDefID)
    local builders = {}
    for u,_ in pairs(myConstructors) do
        if u and __canBuild(GetUnitDefID(u), unitDefID) then
            builders[#builders + 1] = u
        end
    end
    for u,_ in pairs(myFactories) do
        if u and __canBuild(GetUnitDefID(u), unitDefID) then
            builders[#builders + 1] = u
        end
    end
    return builders
end

local excluded_units_regex = {
   
}

local function ChainScore(target, chain)
    for _, regex in ipairs(excluded_units_regex) do
        if target:find(regex) ~= nil then
            return MIN_INT
        end
    end

    local unitDef = UnitDefNames[target]

    -- For the time being, ignore air and water units
    -- I do not know why, but some units like SWEVedettbat has
    -- unitDef.floatOnWater = false, so I am also asking for wiki_parser
    if unitDef.canFly or unitDef.floatOnWater or unitDef.customParams.wiki_parser == "boat" or unitDef.isHoveringAirUnit then
        return MIN_INT
    end

    local mCurr, mStor, mPull, mInco = Spring.GetTeamResources(myTeamID, "metal")
    local eCurr, eStor = Spring.GetTeamResources(myTeamID, "energy")
    if eStor < 1 then
        eStor = 1
    end

    local score = MIN_INT
    local base_gann_inputs = {
        sim_time = __clamp(Spring.GetGameSeconds() / MAX_SIMTIME),
        metal_curr = __clamp(mCurr / mStor),
        metal_push = __clamp(METAL_PULL_PUSH_FACTOR * mInco / 250.0),
        metal_pull = __clamp(METAL_PULL_PUSH_FACTOR * mPull / 250.0),
        energy_curr = __clamp(eCurr / eStor),
        energy_storage = __clamp(eStor / MAX_E_STORAGE),
        capturing_capacity = __clamp(n_cap / MAX_FLAG_CAPTURE_CAPACITY),
        los_capacity = __clamp(n_view / MAX_LOS_CAPACITY),
        construction_capacity = __clamp(n_constructor / MAX_CONSTRUCTORS),
        chain_cost = __clamp((chain.metal - unitDef.metalCost) / mStor),
        unit_cost = __clamp(unitDef.metalCost / mStor),
        unit_in_factories = __clamp(#GetAllBuilders(unitDef.id) / MAX_UNIT_IN_FACTORIES),
    }
    if squadDefs[unitDef.name] == nil then
        local firepower, accuracy, penetration, range = unit_scores.GetUnitWeaponsFeatures(unitDef)
        local armour = unit_scores.GetUnitArmour(unitDef)

        base_gann_inputs.squad_size = 1.0 / MAX_SQUAD_SIZE
        base_gann_inputs.unit_storage = __clamp(unitDef.energyStorage / 3000.0)
        base_gann_inputs.unit_is_constructor = unit_chains.IsConstructor(unitDef.id) and 1.0 or 0.0
        base_gann_inputs.unit_cap = __clamp((unitDef.customParams.flagcaprate or 0) / 10.0)
        base_gann_inputs.unit_view = __clamp(unitDef.losRadius / 1000.0 / MAX_SQUAD_SIZE)
        base_gann_inputs.unit_speed = __clamp(unitDef.speed / 20.0)
        base_gann_inputs.unit_armour = __clamp(armour / 200.0)
        base_gann_inputs.unit_firepower = __clamp(firepower / 1000.0)
        base_gann_inputs.unit_accuracy = __clamp(accuracy / 2000.0)
        base_gann_inputs.unit_penetration = __clamp(penetration / 200.0)
        base_gann_inputs.unit_range = __clamp(range / 15000.0)
    else
        base_gann_inputs.squad_size = 0.0
        base_gann_inputs.unit_storage = 0.0
        base_gann_inputs.unit_is_constructor = 0.0
        base_gann_inputs.unit_cap = 0.0
        base_gann_inputs.unit_view = 0.0
        base_gann_inputs.unit_speed = 0.0
        base_gann_inputs.unit_armour = 0.0
        base_gann_inputs.unit_firepower = 0.0
        base_gann_inputs.unit_accuracy = 0.0
        base_gann_inputs.unit_penetration = 0.0
        base_gann_inputs.unit_range = 0.0

        for _, member in ipairs(squadDefs[unitDef.name].members) do
            local udef = UnitDefNames[member]

            -- For the time being, ignore air units
            if udef.canFly or udef.floatOnWater or udef.isHoveringAirUnit then
                return MIN_INT
            end

            local firepower, accuracy, penetration, range = unit_scores.GetUnitWeaponsFeatures(udef)
            local armour = unit_scores.GetUnitArmour(udef)

            base_gann_inputs.squad_size = base_gann_inputs.squad_size + 1
            if unit_chains.IsConstructor(udef.id) then
                base_gann_inputs.unit_is_constructor = 1.0
            end

            base_gann_inputs.unit_storage = base_gann_inputs.unit_storage +
                    udef.energyStorage
            base_gann_inputs.unit_cap = base_gann_inputs.unit_cap +
                    (unitDef.customParams.flagcaprate or 0)
            base_gann_inputs.unit_view = base_gann_inputs.unit_view +
                    udef.losRadius
            base_gann_inputs.unit_speed = base_gann_inputs.unit_speed +
                    udef.speed
            base_gann_inputs.unit_firepower = base_gann_inputs.unit_firepower +
                    firepower
            base_gann_inputs.unit_accuracy = base_gann_inputs.unit_accuracy +
                    accuracy

            if armour > base_gann_inputs.unit_armour then
                base_gann_inputs.unit_armour = armour
            end
            if penetration > base_gann_inputs.unit_penetration then
                base_gann_inputs.unit_penetration = penetration
            end
            if range > base_gann_inputs.unit_range then
                base_gann_inputs.unit_range = range
            end

        end

        base_gann_inputs.unit_storage = base_gann_inputs.unit_storage / 3000.0
        base_gann_inputs.unit_cap = base_gann_inputs.unit_cap / 10.0

        base_gann_inputs.unit_speed = base_gann_inputs.unit_speed /
                (20.0 * base_gann_inputs.squad_size)
        base_gann_inputs.unit_firepower = base_gann_inputs.unit_firepower /
                (1000.0 * base_gann_inputs.squad_size)
        base_gann_inputs.unit_accuracy = base_gann_inputs.unit_accuracy /
                (2000.0 * base_gann_inputs.squad_size)
        base_gann_inputs.unit_storage = base_gann_inputs.unit_storage / 3000.0

        base_gann_inputs.unit_view = base_gann_inputs.unit_view /
                (1000.0 * MAX_SQUAD_SIZE)
        base_gann_inputs.unit_armour = base_gann_inputs.unit_armour / 200.0
        base_gann_inputs.unit_penetration = base_gann_inputs.unit_penetration / 200.0
        base_gann_inputs.unit_range = base_gann_inputs.unit_range / 15000.0

        base_gann_inputs.squad_size = base_gann_inputs.squad_size / MAX_SQUAD_SIZE
    end

    score = base_gann.Evaluate(myTeamID, base_gann_inputs).score +
            SCORE_RANDOMIZER * (2.0 * random() - 1.0)
    Log(unitDef.name .. " scored " .. tostring(score))
    return score
end

local function SelectNewBuildingChain()
    local chains = GetBuildingChains()
    local selected, score = nil, MIN_INT / 2
    for target, chain in pairs(chains) do
        local chain_score = ChainScore(target, chain)
       Log("Evaluated chain:"..score, chain)
        if chain_score > score then
            selected = chain
            score = chain_score
        end
    end
    return selected
end

-- Map of unitDefIDs (buildOption) to unitDefIDs (builders)
local baseBuildOptions = {}

local function updateBuildOptions(unitDefID)
    if unitDefID == nil then
        baseBuildOptions = {}
        local alreadyCheckedDefIDs = {}
        local uncheckedDict = {}
        local checkedDict = {}
      --prepare the unchecked Dictionary filling it with Constructors and Factorys
        for u,_ in pairs(myConstructors) do
	    local defID = GetUnitDefID(u)
            if defID then
                updateBuildOptions(defID)
            end
        end
        
        for u,_ in pairs(myFactories) do
       	    local defID = GetUnitDefID(u)
            if defID then
                updateBuildOptions(defID)
            end
        end
        return
    end

    for _,bo in ipairs(UnitDefs[unitDefID].buildOptions) do
        if not baseBuildOptions[bo] then
            Log("Base can now build ", UnitDefs[bo].humanName)
            baseBuildOptions[bo] = unitDefID
        end
    end
end

-- Building stuff
local currentBuildDefID     -- one unitDefID
local currentBuildID        -- one unitID
local currentBuilder        -- one unitID
local useClosestBuildSite = true

local function GetABuilder(unitDefID)
    local builder = nil

    local builder_udefid = baseBuildOptions[unitDefID]
    for u,_ in pairs(myConstructors) do
        if builder_udefid == GetUnitDefID(u) then
            builder = u
            break
        end
    end
    if builder ~= nil then
        for u,_ in pairs(myFactories) do
            if builder_udefid == GetUnitDefID(u) then
                builder = u
                break
            end
        end
    end
    
    return builder
end

local morphDefs = nil
local legitBuildOpts = VFS.Include("gamedata/builddefs.lua")

local function ResolveMorphingCmd(origDefID, destDefID)
   return -destDefID
end

local function StartChain()
    local target_udef = UnitDefNames[selected_chain.units[1]]
    assert(selected_chain.units[1])

    -- Let's try to use the already known builder
    local builder = selected_chain.builder
    if not Spring.ValidUnitID(builder) or Spring.GetUnitIsDead(builder) then
        builder = GetABuilder(target_udef.id)
    end

    if builder == nil then
            Log("StartChain: GoalUnit "..selected_chain.units[1].." has no builder")
        -- No way to fulfill the asked building chain. Let's the AI select
        -- another chain in the next GameFrame() call
        selected_chain = nil
        return
    end

  Log("StartChain: GoalUnit "..selected_chain.units[1].." assigned order")
    -- Ask all the constructors to aid the builder. This is also valid for
    -- factories, so the constructors may try to repair the factory if it is
    -- damaged by artillery
    for u,_ in pairs(myConstructors) do
        if u ~= builder then
            GiveOrderToUnit(u, CMD.GUARD, {builder}, {})
        end
    end

    -- How to build the unit depends mainly on the kind of builder
    local builderDefID = GetUnitDefID(builder)
    if unit_chains.IsConstructor(builderDefID) then
        local cmd = ResolveMorphingCmd(builderDefID, target_udef.id)
        if cmd == -target_udef.id then
            local x,y,z,facing = buildsiteFinder.FindBuildsite(builder, target_udef.id, useClosestBuildSite)
            if not x then
                Log("Could not find buildsite for " .. target_udef.humanName)
                -- Lets select a different chain
                selected_chain = nil
                return
            end

            Log("Queueing in place: ", target_udef.name, " [", x, ", ", y, ", ", z, "] ", facing)
            GiveOrderToUnit(builder, cmd, {x,y,z,facing}, {})
        else
            Log("Queueing unit morph: ", target_udef.name)
            GiveOrderToUnit(builder, cmd, {}, {})
        end
    elseif unit_chains.IsFactory(builderDefID) then
        local cmd = ResolveMorphingCmd(builderDefID, target_udef.id)
        if cmd == -target_udef.id then
            Log("Queueing in factory: ", target_udef.name)
        else
            Log("Queueing factory morph: ", target_udef.name)
        end
        GiveOrderToUnit(builder, cmd, {}, {})
        -- Regardless it is a morph or a proper unit, we are storing the
        -- unitDefID in the queue. If later on it is created as a unit to be
        -- built, we are then replacing the value by the unitID
        if myFactories[builder] == nil then
            myFactories[builder] = {}
        end
        myFactories[builder][#myFactories[builder] + 1] = -target_udef.id
        myFactoriesScore[builder] = MIN_INT  -- The first factory to wait if we are stalling
    elseif unit_chains.IsPackedFactory(builderDefID) then
        -- It is a packed factory, so we must find a place to unpack, move there
        -- the unit and ask to unpack
        myPackedFactories[builder] = target_udef.id
        local cmd = ResolveMorphingCmd(builderDefID, target_udef.id)
        local x,y,z,facing = buildsiteFinder.FindBuildsite(builder, target_udef.id, useClosestBuildSite)
        if not x then
            Log("Could not find buildsite for " .. target_udef.humanName)
            -- Lets select a different chain
            selected_chain = nil
            return
        end

        Log("Unpacking in place: ", target_udef.name, " [", x, ", ", y, ", ", z, "] ")
        GiveOrderToUnit(builder, CMD.MOVE, {x, y, z}, {})
        GiveOrderToUnit(builder, cmd, {}, {"shift"})
    else
        Log("Unhandled building chain link. Unit '", UnitDefs[builderDefID].name, "' is not neither a constructor, a factory or a packed factory")
        selected_chain = nil
        return
    end

    -- Set the starting time, to eventually give up at some point
    selected_chain.start_time = Spring.GetGameSeconds()

    currentBuildDefID = target_udef.id
    currentBuilder = builder
end

local function BuildBaseFinished()
    if not selected_chain then
        -- It may happens that AI is changing the target when the previous one
        -- is finishing, so selected_chain will be nil. Just ignore it.
        return
    end
    -- Upgrade the chain
    selected_chain.builder = currentBuildID
    table.remove(selected_chain.units, 1)
    -- Restart the state variables
    useClosestBuildSite = true
    currentBuildDefID = nil
    currentBuildID = nil
    currentBuilder = nil

    if #selected_chain.units > 0 then
        -- Continue the plan
        StartChain()
    else
        -- A new chain shall be selected
        selected_chain = nil
    end
end

local function BuildBaseInterrupted()
    -- enforce randomized next buildsite, instead of
    -- hopelessly trying again and again on same place
    useClosestBuildSite = false
    currentBuildDefID = nil
    currentBuildID = nil
    currentBuilder = nil
    if not selected_chain then return end
    selected_chain.retry = selected_chain.retry - 1
    if selected_chain.retry > 0 then
        StartChain()
    else
        -- No-way... Probably the factory is blocked...
        -- Let's look for a different project
        selected_chain = nil
    end
end

-- Factories handling
local unitBuiltBy = {}

local function IdleFactory(unitID)
    if not unitID then return end
    if not myFactories[unitID] then myFactories[unitID] = {} end

    if #myFactories[unitID] > 0 then
        Log("IdleFactory "..unitID.." still has work todo")
        -- We still have work to do...
        return
    end
    
    Log("IdleFactory "..unitID.." evaluates build options")
    -- Evaluate the build options
    local unitDefID = GetUnitDefID(unitID)
    if not unitDefID then return end
    
    local selected, cmd, score = nil, nil, MIN_INT / 2
    if UnitDefs[unitDefID].buildOptions then
        for _, optDefID in ipairs(UnitDefs[unitDefID].buildOptions) do
            local optDef = UnitDefs[optDefID]
            local optCmd = ResolveMorphingCmd(unitDefID, optDefID)
            -- Avoid here:
            --  * morphs
            --  * packed factories
            if optCmd == -optDefID and not unit_chains.is_morph_link(optDef.name) and not unit_chains.IsPackedFactory(optDefID) then
                local chain_phony = {metal=optDef.metalCost}
                local optName = optDef.name
                local chain_score = ChainScore(optName, chain_phony)
                if chain_score > score then
                    selected = optDefID
                    cmd = optCmd
                    score = chain_score
                end
            end
        end
    end

    if selected == nil then
        -- Nothing to do
        return        
    end

    Log("Queueing in idle factory: ", UnitDefs[unitDefID].name, UnitDefs[selected].name)
    GiveOrderToUnit(unitID, cmd, {}, {})

    -- For the time being, add the unitDefID to the queue. Later on, when the
    -- actual unit is created to be built, we are replacing this by the actual
    -- unitID
    myFactories[unitID][#myFactories[unitID] + 1] = -selected
    myFactoriesScore[unitID] = score
end

local teamDeployTarget = nil

local function getDeployTarget()
    if not teamDeployTarget then
        local x, _, z = Spring.GetTeamStartPosition(myTeamID)
        local rx, rz = 0.5 * Game.mapSizeX - x, 0.5 * Game.mapSizeZ - z
        if math.abs(rx) > math.abs(rz) then
            if rx > 0 then
                teamDeployTarget = {x = 0.95 * Game.mapSizeX,
                                    z = 0.5 * Game.mapSizeZ}
            else
                teamDeployTarget = {x = -0.95 * Game.mapSizeX,
                                    z = 0.5 * Game.mapSizeZ}
            end
        else
            if rz > 0 then
                teamDeployTarget = {x = 0.5 * Game.mapSizeX,
                                    z = 0.95 * Game.mapSizeZ}
            else
                teamDeployTarget = {x = 0.5 * Game.mapSizeX,
                                    z = -0.95 * Game.mapSizeZ}
            end
        end
        teamDeployTarget.y = Spring.GetGroundHeight(teamDeployTarget.x,
                                                    teamDeployTarget.z)
    end

    return {teamDeployTarget.x, teamDeployTarget.y, teamDeployTarget.z}
end

local function IdlePackedFactory(unitID)
    local unitDefID = GetUnitDefID(unitID)
    local unitDef = UnitDefs[unitDefID]
    local maxAmmo = unitDef.customParams.maxammo
    if maxAmmo ~= nil and GetUnitRulesParam(unitID, "ammo") < tonumber(maxAmmo) then
        Log("Waiting to deploy " .. unitDef.name)
        return
    end
    local targetDefID = myPackedFactories[unitID]
    if targetDefID == true then
        -- A target was not assigned yet, select a random one
        morphDefs = morphDefs or GG['morphHandler'].GetMorphDefs()
        local morphs = morphDefs[unitDefID]
        local opts = {}
        for _, morph in pairs(morphs) do
            opts[#opts + 1] = morph.into
        end
        if #opts == 1 then
            targetDefID = opts[1]
        else
            targetDefID = opts[math.random(#opts)]
        end
        myPackedFactories[unitID] = targetDefID
    end

    local cmd = ResolveMorphingCmd(unitDefID, targetDefID)
    local x,y,z,facing = buildsiteFinder.FindBuildsite(unitID, targetDefID, false)
    if not x then
        Log("Could not find buildsite for " .. UnitDefs[targetDefID].name)
        return
    end

    Log("Unpacking idle packed factory: ", UnitDefs[targetDefID].name, " [", x, ", ", y, ", ", z, "] ")
    GiveOrderToUnit(unitID, CMD.MOVE, {x, y, z}, {})
    GiveOrderToUnit(unitID, cmd, getDeployTarget(), {"shift"})
end

local function isBuilderIdle(unitID)
    if myFactories[unitID] ~= nil then
        local isIdle = (GetFactoryCommands(unitID, 0) or 0) == 0
        if isIdle then
            myFactories[unitID] = {}
        end
        return isIdle
    elseif myConstructors[unitID] ~= nil or myPackedFactories[unitID] ~= nil then
        return (GetUnitCommands(unitID, 0) or 0) == 0
    end

    return nil
end

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
--
--  The call-in routines
--

local is_gann_trained = false
local waiting_builders = {}
local is_waiting = {}

local function __checkWaitingState(u, shall_wait, GetCommands)
    local commands = GetCommands(u, 1)
    if not commands or not commands[1] then return end 
    local cmd = GetCommands(u, 1)[1]
    local is_cmd_wait = cmd ~= nil and cmd.id == CMD_WAIT
    if not shall_wait and is_cmd_wait then
        Log("Unit ", u, "(", UnitDefs[GetUnitDefID(u)].name, ") shall be active, but it is waiting")
        GiveOrderToUnit(u, CMD_WAIT, {}, {})
    elseif shall_wait and not is_cmd_wait then
        Log("Unit ", u, "(", UnitDefs[GetUnitDefID(u)].name, ") shall be waiting, but it is active")
        GiveOrderToUnit(u, CMD_WAIT, {}, {})
    end
end

local function checkUnitWaitingState(u, shall_wait)
    return __checkWaitingState(u, shall_wait, GetUnitCommands)
end

local function checkFactoryWaitingState(u, shall_wait)
    return __checkWaitingState(u, shall_wait, GetFactoryCommands)
end

function BaseMgr.GameFrame(f)
    if not is_gann_trained and (not gadget.IsTraining() or base_gann.GetScore(myTeamID) > 0.0) then
        is_gann_trained = true
    end
    if not is_gann_trained then
        local f = VFS.Include("LuaRules/Gadgets/prometheus/base/gann_train.lua")
        is_gann_trained = f(base_gann, myTeamID)
    end

    -- Check if the building chain is not progressing, so we must move to a new
    -- one
    if not currentBuildID and selected_chain and selected_chain.start_time then
        if GetGameSeconds() - selected_chain.start_time > CHAIN_GIVING_UP_TIME then
            selected_chain = nil
        end
    end

    if selected_chain == nil then
        selected_chain = SelectNewBuildingChain()
        if selected_chain then
            Log("Starting a new chain to reach " .. selected_chain.units[#selected_chain.units])
            selected_chain.retry = 3
            StartChain()
        else
            Log("No way I can build nothing new!!!")
        end
        return
    end

    if currentBuildDefID and isBuilderIdle(currentBuilder) then
        Log(UnitDefs[currentBuildDefID].humanName, " was finished/aborted, but neither UnitFinished nor UnitDestroyed was called")
        BuildBaseInterrupted()
    end

    for u, _ in pairs(myPackedFactories) do
        if isBuilderIdle(u) then
            IdlePackedFactory(u)
        end
    end

    for u, _ in pairs(myConstructors) do
        checkUnitWaitingState(u, is_waiting[u] == true)
    end
    for u,q in pairs(myFactories) do
        if u and q then
            checkFactoryWaitingState(u, is_waiting[u] == true)
            if #q == 0 then
                local udef = GetUnitDefID(u)
                if udef and UnitDefs[udef] then
                    Log("Factory " .. UnitDefs[GetUnitDefID(u)].name .. " hanged...")
                end
                IdleFactory(u)
            end
        end
    end

    local mCurr, mStor, mPull, mInco = GetTeamResources(myTeamID, "metal")
    if mCurr / mStor < 0.1 and mInco < mPull then
        -- We are stalling, put some units to wait
        if #waiting_builders == 0 then
            -- Let's start putting the constructors in waiting mode
            waiting_builders[1] = {}
            for u, _ in pairs(myConstructors) do
                GiveOrderToUnit(u, CMD_WAIT, {}, {})
                Log("Make to wait ", u, "(", UnitDefs[GetUnitDefID(u)].name, ")")
                waiting_builders[1][#(waiting_builders[1]) + 1] = u
                is_waiting[u] = true
            end
        else
            -- Look for the worst scored factory to ask it to wait
            local score, factory = MAX_INT, nil
            for u, s in pairs(myFactoriesScore) do
                if s < score then
                    score, factory = s, u
                end
            end
            if factory ~= nil then
                GiveOrderToUnit(factory, CMD_WAIT, {}, {})
            --    Log("Make to wait ", factory, "(", UnitDefs[GetUnitDefID(factory)].name, ")")
                waiting_builders[#waiting_builders + 1] = {factory}
                is_waiting[factory] = true
            end
        end
    elseif #waiting_builders > 0 then
        -- We are not stalling anymore, let a factory to start the work again
        for _, u in ipairs(waiting_builders[#(waiting_builders)]) do
            if is_waiting[u] ~= nil then  -- Maybe the unit was killed
                --Log("Back to job ", u, "(", UnitDefs[GetUnitDefID(u)].name, ")")
                is_waiting[u] = nil
                GiveOrderToUnit(u, CMD_WAIT, {}, {})
            end
        end
        waiting_builders[#waiting_builders] = nil
    else
        -- Just in case
        is_waiting = {}
    end
end

function BaseMgr.UnitCreated(unitID, unitDefID, unitTeam, builderID)
    buildsiteFinder.UnitCreated(unitID, unitDefID, unitTeam)

    if (not currentBuildID) and (unitDefID == currentBuildDefID) and (builderID == currentBuilder) then
        currentBuildID = unitID
    end

    if myFactories[builderID] ~= nil then
        unitBuiltBy[unitID] = builderID
        -- Replace the unitDefID in the queue by the actual unitID
        for i, udefid in ipairs(myFactories[builderID]) do
            if -udefid == unitDefID then
                myFactories[builderID][i] = unitID
                return
            end
        end
    end
end

function BaseMgr.UnitFinished(unitID, unitDefID, unitTeam)
    if (unitDefID == currentBuildDefID) and ((not currentBuildID) or (unitID == currentBuildID)) then
        Log("CurrentBuild finished")
        BuildBaseFinished()
    end

    if doesUnitExistAlive(unitID) == false then
      Log("Unit "..UnitDefs[unitDefID].name.." finnished is dead")
      unitBuiltBy[unitID] = nil
      return true
    end

    local factory = unitBuiltBy[unitID]
    
   if factory ~= nil and doesUnitExistAlive(factory) == true then
        unitBuiltBy[unitID] = nil
        if #myFactories[factory] > 0 then
            table.remove(myFactories[factory], 1)
        end
        IdleFactory(factory)
    end

    -- Upgrade the preferences indicators
    n_view = n_view + UnitDefs[unitDefID].losRadius / 1000.0
    n_cap = n_cap + (UnitDefs[unitDefID].customParams.flagcaprate or 0)

    -- Add the new constructors
    if unit_chains.IsConstructor(unitDefID) then
        n_constructor = n_constructor + 1
        myConstructors[unitID] = true
        updateBuildOptions(unitDefID)
        if currentBuilder then
            GiveOrderToUnit(unitID, CMD.GUARD, {currentBuilder}, {})
        end
        return true
    end

    if unit_chains.IsFactory(unitDefID) then
        Log("New factory: ", UnitDefs[unitDefID].name)
        updateBuildOptions(unitDefID)
        if myFactories[unitID] == nil then
            myFactories[unitID] = {}
        end
        assert(unitID)
        IdleFactory(unitID)
        return true 
    end

    if unit_chains.IsPackedFactory(unitDefID) or unit_chains.IsGunToDeploy(unitDefID) then
        Log("New packed unit: ", UnitDefs[unitDefID].name)
        myPackedFactories[unitID] = true
        return true
    end
end

function BaseMgr.UnitDestroyed(unitID, unitDefID, unitTeam, attackerID, attackerDefID, attackerTeam)
    buildsiteFinder.UnitDestroyed(unitID, unitDefID, unitTeam, attackerID, attackerDefID, attackerTeam)
    is_waiting[unitID] = nil

    if (currentBuildID ~= nil) and (unitID == currentBuildID) then
        Log("CurrentBuild destroyed")
        BuildBaseInterrupted()
    end

    local factory = unitBuiltBy[unitID]
    if factory ~= nil then
        unitBuiltBy[unitID] = nil
        if not myFactories[factory] then myFactories[factory] = {} end
        if #myFactories[factory] > 0 then
            table.remove(myFactories[factory], 1)
        end
        assert(factory)
        IdleFactory(factory)
    end

    -- Upgrade the preferences indicators
    n_view = n_view - UnitDefs[unitDefID].losRadius / 1000.0
    n_cap = n_cap + (UnitDefs[unitDefID].customParams.flagcaprate or 0)

    if unit_chains.IsConstructor(unitDefID) then
        n_constructor = n_constructor - 1
        myConstructors[unitID] = nil
        updateBuildOptions()
    end
    if unit_chains.IsFactory(unitDefID) then
        myFactories[unitID] = nil
       -- Spring.Echo("Unit "..UnitDefs[unitDefID].name.." destroyed")
        updateBuildOptions()
    end
    if unit_chains.IsPackedFactory(unitDefID) or unit_chains.IsGunToDeploy(unitDefID) then
        myPackedFactories[unitID] = nil
    end
end

return BaseMgr
end
