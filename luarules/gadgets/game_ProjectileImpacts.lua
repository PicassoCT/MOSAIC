function gadget:GetInfo()
    return {
        name = "Projectiles",
        desc = "This gadget handles projectileimpacts",
        author = "Picasso",
        date = "Sep. 2008",
        license = "GNU GPL, v2 or later",
        layer = 0,
        enabled = true
    }
end

if (gadgetHandler:IsSyncedCode()) then
    VFS.Include("scripts/lib_OS.lua")
    VFS.Include("scripts/lib_UnitScript.lua")
    VFS.Include("scripts/lib_Animation.lua")
    VFS.Include("scripts/lib_Build.lua")
    VFS.Include("scripts/lib_mosaic.lua")

    if not GG.AerosolAffectedCivilians then GG.AerosolAffectedCivilians = {} end
    local UnitDamageFuncT = {}
    local UnitDefNames = getUnitDefNames(UnitDefs)
    local GameConfig = getGameConfig()
    local civilianWalkingTypeTable = getCultureUnitModelTypes(
                                         GameConfig.instance.culture,
                                         "civilian", UnitDefs)
    local houseTypeTable = getCultureUnitModelTypes(GameConfig.instance.culture,
                                                    "house", UnitDefs)

turnCoatFactoryType = getTurnCoatFactoryType(UnitDefs)
    local spGetGameFrame = Spring.GetGameFrame
    local spGetUnitIsDead = Spring.GetUnitIsDead
    local spGetUnitDefID = Spring.GetUnitDefID
    local spGetUnitTeam = Spring.GetUnitTeam
    local spGetProjectileTeamID = Spring.GetProjectileTeamID
    local spGetProjectileDefID = Spring.GetProjectileDefID
    local spDestroyUnit = Spring.DestroyUnit
    local spSetUnitAlwaysVisible = Spring.SetUnitAlwaysVisible
    local spGiveOrderToUnit = Spring.GiveOrderToUnit
    local spGetTeamList = Spring.GetTeamList
    local spEcho = echo

    local GaiaTeamID = Spring.GetGaiaTeamID()
    local MobileInterrogateAbleType =
        getMobileInterrogateAbleTypeTable(UnitDefs)
    local RaidAbleType = getRaidAbleTypeTable(UnitDefs)

    local godRodMarkerWeaponDefID = WeaponDefNames["godrodmarkerweapon"].id
    Script.SetWatchWeapon(godRodMarkerWeaponDefID, true)  
    local impactorWeaponDefID = WeaponDefNames["godrod"].id
    Script.SetWatchWeapon(impactorWeaponDefID, true)
    local raidWeaponDefID = WeaponDefNames["raidarrest"].id
    Script.SetWatchWeapon(raidWeaponDefID, true)
    local stunpistoldWeaponDefID = WeaponDefNames["stunpistol"].id
    Script.SetWatchWeapon(stunpistoldWeaponDefID, true)
    local nimrodRailungDefID = WeaponDefNames["railgun"].id
    Script.SetWatchWeapon(nimrodRailungDefID, true)
    local molotowDefID = WeaponDefNames["molotow"].id
    Script.SetWatchWeapon(molotowDefID, true)

    local FireWeapons = {
        [molotowDefID] = true
    }
  
    function getWeapondefByName(name)
        return WeaponDefs[WeaponDefNames[name].id]
    end

    SSied_Def = getWeapondefByName("ssied")
    ak47_Def = getWeapondefByName("ak47")
    pistol_Def = getWeapondefByName("pistol")
    tankcannon_Def = getWeapondefByName("tankcannon")
    railgun_Def = getWeapondefByName("railgun")
    local stunContainerUnitTimePeriodInSeconds = 10.0

    if not GG.houseHasSafeHouseTable then GG.houseHasSafeHouseTable = {} end

    function gadget:Initialize()
        spEcho(GetInfo().name .. " Initialization started")
        if not GG.houseHasSafeHouseTable then
            GG.houseHasSafeHouseTable = {}
        end
        spEcho(GetInfo().name .. " Initialization ended")
    end

    local panicWeapons = {
        [WeaponDefNames["godrod"].id] = {damage = 1000, range = 2000},
        [WeaponDefNames["ssied"].id] = {damage = 500, range = SSied_Def.range},
        [WeaponDefNames["ak47"].id] = {damage = 100, range = ak47_Def.range},
        [WeaponDefNames["pistol"].id] = {damage = 75, range = pistol_Def.range},
        [WeaponDefNames["tankcannon"].id] = {
            damage = 250,
            range = tankcannon_Def.range
        },
        [WeaponDefNames["railgun"].id] = {
            damage = 300,
            range = railgun_Def.range
        }
    }
    --raidinitialization
      if not GG.raidStatus  then GG.raidStatus = {} end
      if not GG.HouseRaidIconMap  then GG.HouseRaidIconMap = {} end

    -- Watched Weapons Weapons
    for wId, wRange in pairs(panicWeapons) do
        Script.SetWatchWeapon(wId, true)
    end


    -- ===========Explosion Functions ====================================================
  local explosionFunc = {
    [impactorWeaponDefID] =  function(weaponDefID, px, py, pz, AttackerID)
            id = Spring.CreateUnit("impactor", px, py, pz, 1, GaiaTeamID)
            Spring.SetUnitBlocking(id, false)
    end
  }

    function makeHouseVisible(houseID)
        env = Spring.UnitScript.GetScriptEnv(houseID)
        if env and env.showHouse then
            Spring.UnitScript.CallAsUnit(houseID, env.showHouse)
        end
    end

    function molotowEventStream(weaponDefID, x, y, z)

            fireFunction = function(evtID, frame, persPack, startFrame)
            -- Setup
            if not persPack.startFrame then
                persPack.startFrame = spGetGameFrame()
            end

            if persPack.lifetimeFrames <= 0 then
                return 
            end
            
            function setInternalStateMachineToStarted(id)
                if civilianWalkingTypeTable[Spring.GetUnitDefID(id)] then
                    env = Spring.UnitScript.GetScriptEnv(id)
                    if env and env.setCivilianUnitInternalStateMode then
                        Spring.UnitScript.CallAsUnit(id,
                                                     env.setCivilianUnitInternalStateMode,
                                                     id,
                                                    "STARTED")
                    end
                end
            end
            
            additional = math.random(3, 9)
            addx = math.random(0, 4)
            xd = randSign()
            zd = randSign()
            addz = math.random(0, 4)
            local x,y,z = persPack.px, persPack.py, persPack.pz
            dx,dy,dz= Spring.GetGroundNormal(persPack.px, persPack.pz, true)
            Spring.SpawnCEG("flames", x + addx * xd, y + additional, z + addz * zd, dx, dy, dz, 50, 0)
            if maRa() == true then
                 Spring.SpawnCEG("vortflames", x + addx * xd, y + additional, z + addz * zd, 0, 1, 0, 50, 0)
            end

            process(getAllInCircle(persPack.px, persPack.pz, persPack.range),
                    function(id)
                        if id then
                            setInternalStateMachineToStarted(id)
                            setUnitOnFire(id, math.random(7500, 10000))
                        end
                    end
                    )

            persPack.lifetimeFrames = persPack.lifetimeFrames - persPack.updateIntervall
            return frame + persPack.updateIntervall, persPack
        end

        GG.EventStream:CreateEvent(fireFunction, {
                            -- persistance Pack
                            weaponDefID = weaponDefID,
                            updateIntervall = 9,
                            px = x,
                            py = y,
                            pz = z,
                            lifetimeFrames = 15*30,
                            range=50
                        }, Spring.GetGameFrame() + math.random(1,18)% 3 )
    end

    function gadget:Explosion(weaponDefID, px, py, pz, AttackerID)
        if explosionFunc[weaponDefID] then explosionFunc[weaponDefID](weaponDefID, px, py, pz, AttackerID) 
            return true
        end

        if FireWeapons[weaponDefID] then
            molotowEventStream(weaponDefID, px, py, pz)
        end
    end

    -- ===========UnitDamaged Functions ====================================================
    function currentlyInterrogationRunning(suspectID, interrogatorID)
        if not GG.InterrogationTable[suspectID] or
            not GG.InterrogationTable[suspectID][interrogatorID] then
            return false
        end

        if GG.InterrogationTable[suspectID][interrogatorID] and
            GG.InterrogationTable[suspectID][interrogatorID] == false then
            return false
        end

        return true
    end

    -----------------------------------------------------------------------------------------------------------------------
    -----------------------------------------------------------------------------------------------------------------------
    -- Interrogation
    -----------------------------------------------------------------------------------------------------------------------
    -----------------------------------------------------------------------------------------------------------------------
    -- victim -- interrogator -- boolInerrogationOngoing
    GG.InterrogationTable = {}
    local civilianWalkingTypeTable = getCultureUnitModelTypes(
                                         GameConfig.instance.culture,
                                         "civilian", UnitDefs)
    raidStates = getRaidStates()
    raidResultStates = getRaidResultStates()
    local innocentCivilianTypeTable = getPanicableCiviliansTypeTable(UnitDefs)

   raidEventStreamFunction = function(unitID, unitDefID, unitTeam, damage,
                                       paralyzer, weaponDefID, attackerID,
                                       attackerDefID, attackerTeam,
                                       iconUnitTypeName)

        spEcho("raidEventStream  Called")

        setRaidEndState =   function (persPack, boolDoesTargetExistAlive, boolDoesInterrogatorExistAlive)
                                    Spring.Echo("Raid: CleanUp ")
                                    GG.InterrogationTable[persPack.unitID] = nil

                                   
                                    if doesUnitExistAlive(persPack.unitID) == true then
                                        Spring.SetUnitNoSelect(persPack.unitID, false)
                                        makeHouseVisible(persPack.unitID)
                                    end

                                    --Stop Attacker form reintterogating the same building
                                    if doesUnitExistAlive(persPack.AttackerID) == true then
                                       Command(persPack.AttackerID, "stop")
                                    end



                                     GG.HouseRaidIconMap[persPack.unitID] = nil
                                end
                                

        if GG.InterrogationTable[unitID] == nil then
            GG.InterrogationTable[unitID] = {}
        end
        if GG.InterrogationTable[unitID][attackerID] == nil then
            GG.InterrogationTable[unitID][attackerID] = false
        end

        if GG.InterrogationTable[unitID][attackerID] == false then
            GG.InterrogationTable[unitID][attackerID] = true
            -- Stun
            raidFunction = function(persPack)
            spEcho("raidEventStream  Ongoing")

                -- check Target is still existing
                if false == doesUnitExistAlive(persPack.unitID) then
                    spEcho("failed check Target is still existing ")
                    GG.raidStatus[persPack.IconID].state = raidStates.Aborted
                    GG.raidStatus[persPack.IconID].boolInterogationComplete = true
                    setRaidEndState(persPack)
                    return true, persPack
                end

                -- check wether the interrogator is still alive
                if false == doesUnitExistAlive(persPack.interrogatorID) then
                    spEcho("failed   check wether the interrogator is still alive")
                    GG.raidStatus[persPack.IconID].state = raidStates.Aborted
                    GG.raidStatus[persPack.IconID].boolInterogationComplete = true
                    setRaidEndState(persPack)
                    return true, persPack
                end

                -- check distance is still okay
                if distanceUnitToUnit(persPack.interrogatorID, persPack.unitID) > GameConfig.InterrogationDistance then
                    spEcho("failed check distance is still okay5 ")
                    if doesUnitExistAlive(persPack.IconID) == true then
                    GG.raidStatus[persPack.IconID].state = raidStates.Aborted
                    GG.raidStatus[persPack.IconID].boolInterogationComplete = true
                    persPack.boolRaidHasEnded = true 
                end
                    setRaidEndState(persPack)
                    return true, persPack
                end
                
                -- check if the icon is still there
                if not persPack.IconID then
                    persPack.IconID = createUnitAtUnit(
                                          spGetUnitTeam(persPack.interrogatorID),--teamID
                                          iconUnitTypeName, --typeID
                                          persPack.unitID,  --otherID
                                          0,0,0,  -- ox, oy, oz
                                          nil, --parentID
                                          0)   --orientation 

                    if persPack.IconID then
                        if not GG.HouseRaidIconMap then GG.HouseRaidIconMap = {} end
                        Spring.Echo("Raid: Registering RaidIcon to map")
                        GG.HouseRaidIconMap[persPack.unitID] =  persPack.IconID

                        if GG.raidStatus[persPack.IconID] then  GG.raidStatus[persPack.IconID] = {} end
                        GG.raidStatus[persPack.IconID].boolInterogationComplete = false
                    else
                        spEcho("Raid: No IconID")
                        setRaidEndState(persPack)
                        return true, persPack
                    end
                end

                --Raid has ended
                if persPack.boolRaidHasEnded then return true, persPack end
                    local winningTeam = GG.raidStatus[persPack.IconID].winningTeam
                    local allTeams = spGetTeamList()

                --check 
                if GG.raidStatus[persPack.IconID].boolInterogationComplete == true then
                    local raidStateLocal = GG.raidStatus[persPack.IconID]
                    --Aborted or EmptyHouse
                    if  raidStateLocal.result == raidResultStates.HouseEmpty then
                        if  persPack.houseTypeTable[persPack.suspectDefID] then
                            spEcho("Raided empty house")
                            -- Propandapunishment for Unjust Raids & Interrogations: Remember Guantanamo
                            assert(persPack.attackerTeam)
                            GG.Bank:TransferToTeam(
                                -GameConfig.raid.interrogationPropagandaPrice,
                                persPack.attackerTeam, persPack.attackerID)
                            for i = 1, #allTeams, 1 do
                                if allTeams[i] ~= persPack.attackerTeam then
                                    GG.Bank:TransferToTeam(
                                        GameConfig.raid.interrogationPropagandaPrice,
                                        allTeams[i], persPack.unitID)
                                end
                            end
                        end
                        setRaidEndState(persPack)
                        persPack.boolRaidHasEnded = true
                        return true, persPack
                    end

                    if (raidStateLocal.state == raidStates.Aborted) or 
                        not allTeams or #allTeams <= 1 then 
                        -- Simulation mode
                        spEcho("Raid: Aborted ")
                        setRaidEndState(persPack)
                        persPack.boolRaidHasEnded = true
                        return true, persPack
                    end 

                    --wait for uplink completed (set by the icon)
                    if raidStateLocal.state == raidResultStates.VictoryStateSet then
                        spEcho("Raid was succesfull - childs of " .. persPack.unitID .. " are revealed")
                        unitTeam = spGetUnitTeam(persPack.unitID)
                        children = getChildrenOfUnit(unitTeam, persPack.unitID)
                        parent = getParentOfUnit(unitTeam, persPack.unitID)
                        GG.Bank:TransferToTeam(
                            GameConfig.raid.interrogationPropagandaPrice,
                            persPack.attackerTeam, persPack.attackerID)
                        registerRevealedUnitLocation(persPack.unitID)
                        for childID, v in pairs(children) do
                            if doesUnitExistAlive(childID) == true then
                                spGiveOrderToUnit(childID, CMD.CLOAK, {}, {})
                                GG.OperativesDiscovered[childID] = true
                                spSetUnitAlwaysVisible(childID, true)
                            end
                        end

                        if doesUnitExistAlive(parent) == true then
                            spGiveOrderToUnit(parent, CMD.CLOAK, {}, {})
                            GG.OperativesDiscovered[parent] = true
                            spSetUnitAlwaysVisible(parent, true)
                        end                    
                         
                        setRaidEndState(persPack)
                        persPack.boolRaidHasEnded = true
                    end
                end

         return false, persPack
        end
        
            spEcho("Starting Raid Event Stream")
            createStreamEvent(unitID, raidFunction, 31, {
                interrogatorID = attackerID,
                unitID = unitID,
                suspectDefID = unitDefID,
                attackerTeam = attackerTeam,
                attackerID = attackerID,
                houseTypeTable = houseTypeTable
            })
        end

        -- on Complete Raid/Interrogation
        -- Transfer Units into No Longer Cloakable table
        -- SetAlwaysVisible
        -- Set Uncloak
    end

   interrogationEventStreamFunction = function(unitID, unitDefID, unitTeam,
                                                damage, paralyzer, weaponDefID,
                                                attackerID, attackerDefID,
                                                attackerTeam, iconUnitTypeName)

        if GG.InterrogationTable[unitID] == nil then
            GG.InterrogationTable[unitID] = {}
        end
        if GG.InterrogationTable[unitID][attackerID] == nil then
            GG.InterrogationTable[unitID][attackerID] = false
        end

        if GG.InterrogationTable[unitID][attackerID] == false then
            GG.InterrogationTable[unitID][attackerID] = true

            -- Stun
            interrogationFunction = function(persPack)
            
                -- check Target is still existing
                if false == doesUnitExistAlive(persPack.unitID) then
                    GG.InterrogationTable[persPack.unitID] = nil
                    spEcho("Interogation: Target díed")
                   
                    if true == doesUnitExistAlive(persPack.interrogatorID) then
                        setSpeedEnv(persPack.interrogatorID, 1.0)
                    end

                    if persPack.IconID then
                        GG.raidStatus[persPack.IconID] = nil
                    end
                    return true, persPack
                end

                -- check wether the interrogator is still alive
                if false == doesUnitExistAlive(persPack.interrogatorID) then
                   GG.InterrogationTable[persPack.unitID] = nil
                    spEcho("Interrogation End: Interrogator died")
                    if persPack.IconID then
                        GG.raidStatus[persPack.IconID] = nil
                    end
                    return true, persPack
                end

                -- check distance is still okay
                if distanceUnitToUnit(persPack.interrogatorID, persPack.unitID) >
                    GameConfig.InterrogationDistance then
                    GG.InterrogationTable[persPack.unitID] = nil

                    spEcho("Interogation End: Interrogator distance to big ")
                    setSpeedEnv(persPack.interrogatorID, 1.0)
                    if persPack.IconID then
                        GG.raidStatus[persPack.IconID] = nil
                    end
                    return true, persPack
                end

                -- check if the icon is still there
                if not persPack.IconID then
                    spEcho("Creating InterrogationIcon")
                    persPack.IconID = createUnitAtUnit(
                                          spGetUnitTeam(persPack.interrogatorID),
                                          iconUnitTypeName, persPack.unitID, 0,
                                          0, 0, 0,
                                          persPack.unitID,
                                          1)
                    if not persPack.IconID then
                          spEcho("Creating InterrogationIcon failed")
                        return true, persPack
                    end
            
                    if not GG.raidStatus[persPack.IconID] then
                        GG.raidStatus[persPack.IconID] =
                            {
                                countDown =  (spGetGameFrame() - persPack.startFrame) / GameConfig.InterrogationTimeInFrames,
                                boolInterogationComplete = false,
                                winningTeam = nil
                            }
                    end
                end

                if GG.raidStatus[persPack.IconID].boolInterogationComplete == true then
                    spEcho("InterogationCompleted")
               
                    if not GG.raidStatus[persPack.IconID].winningTeam then
                        -- succesfull interrogation
                        local allTeams = spGetTeamList()
                        if not allTeams or #allTeams <= 1 then
                            -- Simulation mode
                            spEcho( "Interrogation: Aborting because no oponnent - sandbox or simulation mode")
                            GG.InterrogationTable[persPack.unitID] = nil
                            return true, persPack
                        end

                        -- of a innocent person / innocent house
                        if innocentCivilianTypeTable[persPack.suspectDefID] or
                            persPack.houseTypeTable[persPack.suspectDefID] then
                            spEcho("Interrogated innocent - paying the price")
                            -- Propandapunishment for Unjust Raids & Interrogations: Remember Guantanamo
                            assert(persPack.attackerTeam)
                            GG.Bank:TransferToTeam(
                                -GameConfig.raid.interrogationPropagandaPrice,
                                persPack.attackerTeam, persPack.attackerID)

                            for i = 1, #allTeams, 1 do
                                if allTeams[i] ~= persPack.attackerTeam then
                                    GG.Bank:TransferToTeam(
                                        GameConfig.raid.interrogationPropagandaPrice,
                                        allTeams[i], persPack.unitID)
                                end
                            end

                            GG.InterrogationTable[persPack.unitID] = nil
                            return true, persPack
                        end
                    end

                    spEcho("Interrogation was succesfull - childs of " ..
                               persPack.unitID .. " are revealed")
                    unitTeam = spGetUnitTeam(persPack.unitID)
                    children = getChildrenOfUnit(unitTeam, persPack.unitID)
                    parent = getParentOfUnit(unitTeam, persPack.unitID)
                    GG.Bank:TransferToTeam(
                        GameConfig.raid.interrogationPropagandaPrice,
                        persPack.attackerTeam, persPack.attackerID)
                        registerRevealedUnitLocation(persPack.unitID)

                    for childID, v in pairs(children) do
                        spEcho("Interrogation: Reavealing child " .. childID)
                        if doesUnitExistAlive(childID) == true then
                            spGiveOrderToUnit(childID, CMD.CLOAK, {}, {})
                            GG.OperativesDiscovered[childID] = true
                            spSetUnitAlwaysVisible(childID, true)
                        end
                    end

                    if doesUnitExistAlive(parent) == true then
                        spGiveOrderToUnit(parent, CMD.CLOAK, {}, {})
                        GG.OperativesDiscovered[parent] = true
                        spSetUnitAlwaysVisible(parent, true)
                    end

                    --if unit is a assembly, tranfer all produced units to other team
                    if turnCoatFactoryType[spGetUnitDefID(persPack.unitID)] then
                        setAssemblyProducedUnitsToTeam(assemblyID, Spring.GetUnitTeam(persPack.interrogatorID))
                    end

                    -- out of time to interrogate
                    spDestroyUnit(persPack.unitID, false, true)
                    spDestroyUnit(persPack.IconID, false, true)
                    GG.InterrogationTable[persPack.unitID][persPack.interrogatorID] =
                        nil
                    spEcho("Interrogation ended")

                    GG.raidStatus[persPack.IconID] = nil
                    GG.InterrogationTable[persPack.unitID] = nil
                    return true, persPack
                end

                return false, persPack
            end

            spEcho("Starting Interrogation Event Stream")
            createStreamEvent(unitID, interrogationFunction, 31, {
                interrogatorID = attackerID,
                unitID = unitID,
                suspectDefID = unitDefID,
                attackerTeam = attackerTeam,
                attackerID = attackerID,
                houseTypeTable = houseTypeTable
            })
        end

        -- on Complete Raid/Interrogation
        -- Transfer Units into No Longer Cloakable table
        -- SetAlwaysVisible
        -- Set Uncloak
    end

    UnitDamageFuncT[stunpistoldWeaponDefID] =
        function(unitID, unitDefID, unitTeam, damage, paralyzer, weaponDefID,
                 attackerID, attackerDefID, attackerTeam)
            -- stupidity edition
            if attackerID == unitID then
                spEcho("Interrogation:Aborted: attackerID == unitID")
                return damage
            end

            if unitID ~= attackerID then stunUnit(unitID, 2.0) end

            -- make disguise civilians transparent
            if civilianWalkingTypeTable[unitDefID] and
                GG.DisguiseCivilianFor[unitID] then
                stunUnit(unitID, stunContainerUnitTimePeriodInSeconds)
                unitID = GG.DisguiseCivilianFor[unitID]
                unitDefID = spGetUnitDefID(unitID)
                unitTeam = spGetUnitTeam(unitID)
            end

            if MobileInterrogateAbleType[unitDefID] and
                currentlyInterrogationRunning(unitID, attacker) == false then
                spEcho("Interrogation: Start with " .. UnitDefs[unitDefID].name)
                stunUnit(unitID, 2.0)
                setSpeedEnv(attackerID, 0.0)
                interrogationEventStreamFunction(unitID, unitDefID, unitTeam,
                                                 damage, paralyzer, weaponDefID,
                                                 attackerID, attackerDefID,
                                                 attackerTeam,
                                                 "interrogationIcon")
                return damage
            end
        end

    -----------------------------------------------------------------------------------------------------------------------
    -----------------------------------------------------------------------------------------------------------------------
    -- Raid
    -----------------------------------------------------------------------------------------------------------------------
    -----------------------------------------------------------------------------------------------------------------------

    UnitDamageFuncT[raidWeaponDefID] = function(unitID, unitDefID, unitTeam,
                                                damage, paralyzer, weaponDefID,
                                                attackerID, attackerDefID,
                                                attackerTeam)

        if not attackerID then
            attackerID = Spring.GetUnitLastAttacker(unitID)
        end

                -- stupidity edition
        if not attackerID then  spEcho("Raid: No valid attackerID derived"); return damage end
        if attackerID == unitID  then   spEcho("Raid:Aborted: attackerID == unitID"); return damage end

        -- make houses transparent
        if houseTypeTable[unitDefID] and GG.houseHasSafeHouseTable[unitID] then
            stunUnit(unitID, stunContainerUnitTimePeriodInSeconds)
            unitID = GG.houseHasSafeHouseTable[unitID]
            stunUnit(unitID, stunContainerUnitTimePeriodInSeconds)
            unitDefID = spGetUnitDefID(unitID)
            unitTeam = spGetUnitTeam(unitID)
        end

        -- Interrogation -- and not already Interrogated
        if (houseTypeTable[unitDefID] or RaidAbleType[unitDefID]) and
            currentlyInterrogationRunning(unitID, attacker) == false then
            spEcho("Raid of " .. UnitDefs[unitDefID].name.. " id: ".. unitID)
            stunUnit(unitID, 2.0)
            raidEventStreamFunction(unitID, unitDefID, unitTeam,
                                             damage, paralyzer, weaponDefID,
                                             attackerID, attackerDefID,
                                             attackerTeam, "raidicon")
            return damage
        end
    end

    UnitDamageFuncT[nimrodRailungDefID] =
        function(unitID, unitDefID)
            if houseTypeTable[unitDefID] then return 0 end
        end

    UnitDamageFuncT[godRodMarkerWeaponDefID] =   function(unitID, unitDefID, unitTeam,
                                                damage, paralyzer, weaponDefID,
                                                attackerID, attackerDefID,
                                                attackerTeam)

      
        gx,gy, gz = Spring.GetUnitPosition(attackerID)
        tx,ty, tz = Spring.GetUnitPosition(unitID)
        v = makeVector(tx - gx, ty - gy, tz - gz)
        v = normVector(v)
        
            local ImpactorParameter = {
                                pos = { gx, gy - 50, gz },
                               ["end"] = { tx, ty + 10, tz },
                                speed = { v.x, v.y, v.z },
                                owner = attackerID,
                                team = attackerTeam,
                                spread = { math.random(-5, 5), math.random(-5, 5), math.random(-5, 5) },
                                ttl = 4000,
                                error = { 0, 0, 0 },
                                maxRange = 600,
                                gravity = Game.gravity,
                                startAlpha = 1,
                                endAlpha = 1,
                                model = "GodRod.s3o",
                                cegTag = "impactor"
                            }

       projectileID =  Spring.SpawnProjectile(impactorWeaponDefID,ImpactorParameter)

    end

    function gadget:UnitDamaged(unitID, unitDefID, unitTeam, damage, paralyzer,
                                weaponDefID, projectileID, attackerID,
                                attackerDefID, attackerTeam)
 
        if UnitDamageFuncT[weaponDefID] then
            resultDamage = UnitDamageFuncT[weaponDefID](unitID, unitDefID,
                                                        unitTeam, damage,
                                                        paralyzer, weaponDefID,
                                                        attackerID,
                                                        attackerDefID,
                                                        attackerTeam)
            if resultDamage then return resultDamage end
        end

        if FireWeapons[weaponDefID] then
            setUnitOnFire(unitID, math.random(190, 1500))
        end
    end

    -- ===========Projectile Persistence Functions ====================================================
    local ProjectileCreatedFunc={}

    function startInternalBehaviourOfState(unitID, name, ...)
    local arg = arg;
    if (not arg) then
        arg = {...};
        arg.n = #arg
    end

    env = Spring.UnitScript.GetScriptEnv(unitID)
    if env and env.setOverrideAnimationState then
        Spring.UnitScript.CallAsUnit(unitID, 
                                     env[name],
                                     arg[1] or nil,
                                     arg[2] or nil,
                                     arg[3] or nil,
                                     arg[4] or nil
                                     )
    end
    end

    local NewUnitsInPanic = {}
    function gadget:ProjectileCreated(proID, proOwnerID, projWeaponDefID)
        if ProjectileCreatedFunc[projWeaponDefID] then 
            ProjectileCreatedFunc[projWeaponDefID](proID, proOwnerID, projWeaponDefID) 
        end

        if panicWeapons[projWeaponDefID] then
            process(getAllNearUnit(proOwnerID,
                                   panicWeapons[projWeaponDefID].range),
                    function(id)
                if spGetUnitTeam(id) == GaiaTeamID and
                    not GG.DisguiseCivilianFor[id] and
                    civilianWalkingTypeTable[spGetUnitDefID(id)] and
                    not GG.AerosolAffectedCivilians[id] then
                        startInternalBehaviourOfState(id,"startFleeing", proOwnerID)
                    return id
                end
            end)
        end

    end


    function handleFleeingCivilians(n)
        flightFunction = function(evtID, frame, persPack, startFrame)
            -- Setup
            if not GG.FleeingCivilians then GG.FleeingCivilians = {} end
            if not persPack.startFrame then
                persPack.startFrame = spGetGameFrame()
            end
            myID = persPack.unitID
            attackerID = persPack.attackerID
            boolIsDead = spGetUnitIsDead(myID)
            if boolIsDead  ~= nil or boolIsDead == true then
                GG.FleeingCivilians[myID] = nil
                return nil, persPack
            end

            if spGetUnitIsDead(attackerID) == true then
                return nil, persPack
            end

            if not GG.FleeingCivilians[myID] then
                GG.FleeingCivilians[myID] =
                    {
                        flighttime = persPack.flighttime,
                        startFrame = spGetGameFrame()
                    }
            end

            GG.FleeingCivilians[myID].flighttime =
                GG.FleeingCivilians[myID].flighttime - persPack.updateIntervall

            -- we have two panic events.. the older one has too die
            if GG.FleeingCivilians[myID].startFrame > persPack.startFrame then
                return nil, persPack
            end

            if GG.FleeingCivilians[myID].flighttime < 0 then
                return nil, persPack
            end

            runAwayFrom(myID, attackerID, persPack.civilianFleeDistance)

            return frame + persPack.updateIntervall, persPack
        end

        for id, data in pairs(NewUnitsInPanic) do
            if id then
                GG.EventStream:CreateEvent(flightFunction, {
                    -- persistance Pack
                    unitID = id,
                    attackerID = data.proOwnerID,
                    flighttime = data.flighttime,
                    updateIntervall = data.updateIntervall
                }, spGetGameFrame() + (id % 10))
            end
        end
        NewUnitsInPanic = {}
    end

    local projectileDestroyedFunctions = {}

    function gadget:ProjectileDestroyed(proID)
        defid = spGetProjectileDefID(proID)
        if projectileDestroyedFunctions[defID] then
            return projectileDestroyedFunctions[defID](proID, defID,
                                                       spGetProjectileTeamID(
                                                           proID))
        end
    end

    local GROUND = string.byte("g")
    local UNIT = string.byte("u")
    local FEATURE = string.byte("f")
    local PROJECTILE = string.byte("p")

    function getProjectileTargetXYZ(proID)
        targetTypeInt, target = Spring.GetProjectileTarget(proID)

        if targetTypeInt == GROUND then
            echo("ProjectileTarget:", target[1], target[2], target[3])
            return target[1], target[2], target[3], targetTypeInt, target
        end
        if targetTypeInt == UNIT then
            ux, uy, uz = Spring.GetUnitPosition(target)
            return ux, uy, uz, targetTypeInt, target
        end
        if targetTypeInt == FEATURE then
            fx, fy, fz = Spring.GetFeaturePosition(target)
            return fx, fy, fz, targetTypeInt, target
        end
        if targetTypeInt == PROJECTILE then
            px, py, pz = Spring.GetProjectilePosition(target)
            return px, py, pz, targetTypeInt, target
        end
    end
end