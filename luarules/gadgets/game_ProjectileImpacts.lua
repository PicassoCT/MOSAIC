function gadget:GetInfo()
    return {
        name = "Projectiles",
        desc = "This gadget handles projectileimpacts",
        author = "",
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

    if not GG.AerosolAffectedCivilians then
        GG.AerosolAffectedCivilians = {}
    end
    local UnitDamageFuncT = {}
    local UnitDefNames = getUnitDefNames(UnitDefs)
    local GameConfig = getGameConfig()
    local civilianWalkingTypeTable = getCultureUnitModelTypes(GameConfig.instance.culture, "civilian", UnitDefs)
    local houseTypeTable = getCultureUnitModelTypes(GameConfig.instance.culture, "house", UnitDefs)

    GaiaTeamID = Spring.GetGaiaTeamID()

    local raidWeaponDefID = WeaponDefNames["raidarrest"].id
	Script.SetWatchWeapon(raidWeaponDefID, true)
    local stunpistoldWeaponDefID = WeaponDefNames["stunpistol"].id
    Script.SetWatchWeapon(stunpistoldWeaponDefID, true)
	
    function getWeapondefByName(name)
        return WeaponDefs[WeaponDefNames[name].id]
    end

    SSied_Def = getWeapondefByName("ssied")
    ak47_Def = getWeapondefByName("ak47")
    pistol_Def = getWeapondefByName("pistol")
    tankcannon_Def = getWeapondefByName("tankcannon")
    railgun_Def = getWeapondefByName("railgun")
    local stunContainerUnitTimePeriodInSeconds = 10.0

    if not GG.houseHasSafeHouseTable then
        GG.houseHasSafeHouseTable = {}
    end
    function gadget:Initialize()
        Spring.Echo(GetInfo().name .. " Initialization started")
        if not GG.houseHasSafeHouseTable then
            GG.houseHasSafeHouseTable = {}
        end
        Spring.Echo(GetInfo().name .. " Initialization ended")
    end

    panicWeapons = {
        [WeaponDefNames["ssied"].id] = {damage = 500, range = SSied_Def.range},
        [WeaponDefNames["ak47"].id] = {damage = 100, range = ak47_Def.range},
        [WeaponDefNames["pistol"].id] = {damage = 75, range = pistol_Def.range},
        [WeaponDefNames["tankcannon"].id] = {damage = 250, range = tankcannon_Def.range},
        [WeaponDefNames["railgun"].id] = {damage = 300, range = railgun_Def.range}
    }

    --Watched Weapons Weapons
    for wId, wRange in pairs(panicWeapons) do
        Script.SetWatchWeapon(wId, true)
    end



    exampleDefID = -1
    MobileInterrogateAbleType = getMobileInterrogateAbleTypeTable(UnitDefs)
    RaidAbleType = getRaidAbleTypeTable(UnitDefs)
    --units To be exempted from instantly lethal force

    local explosionFunc = {}

    function gadget:Explosion(weaponDefID, px, py, pz, AttackerID)
        if explosionFunc[weaponDefID] then
            explosionFunc[weaponDefID](weaponDefID, px, py, pz, AttackerID)
            return true
        end
    end

    --===========UnitDamaged Functions ====================================================
    function currentlyInterrogationRunning(suspectID, interrogatorID)
        if not GG.InterrogationTable[suspectID] or not GG.InterrogationTable[suspectID][interrogatorID] then
            return false
        end

        if
            GG.InterrogationTable[suspectID][interrogatorID] and
                GG.InterrogationTable[suspectID][interrogatorID] == false
         then
            return false
        end

        return true
    end

    -----------------------------------------------------------------------------------------------------------------------
    -----------------------------------------------------------------------------------------------------------------------
    -- Interrogation
    -----------------------------------------------------------------------------------------------------------------------
    -----------------------------------------------------------------------------------------------------------------------
    --victim -- interrogator -- boolInerrogationOngoing
    GG.InterrogationTable = {}
    local civilianWalkingTypeTable = getCultureUnitModelTypes(GameConfig.instance.culture, "civilian", UnitDefs)
    raidStates = getRaidStates()
    local innocentCivilianTypeTable = getPanicableCiviliansTypeTable(UnitDefs)

    raidEventStreamFunction = function(
        unitID,
        unitDefID,
        unitTeam,
        damage,
        paralyzer,
        weaponDefID,
        attackerID,
        attackerDefID,
        attackerTeam,
        iconUnitTypeName)
        Spring.Echo("caught 1")

        if GG.InterrogationTable[unitID] == nil then
            GG.InterrogationTable[unitID] = {}
        end
        if GG.InterrogationTable[unitID][attackerID] == nil then
            GG.InterrogationTable[unitID][attackerID] = false
        end

        if GG.InterrogationTable[unitID][attackerID] == false then
            GG.InterrogationTable[unitID][attackerID] = true

            Spring.Echo("caught 2")
            --Stun
            interrogationFunction = function(persPack)
                --check Target is still existing
                if false == doesUnitExistAlive(persPack.unitID) then
                    GG.InterrogationTable[persPack.unitID][persPack.interrogatorID] = false
                    Spring.Echo("caught 3 ")
                    if true == doesUnitExistAlive(persPack.interrogatorID) then
                        setSpeedEnv(persPack.interrogatorID, 1.0)
                    end

                    return true, persPack
                end

                --check wether the interrogator is still alive
                if false == doesUnitExistAlive(persPack.interrogatorID) then
                    GG.InterrogationTable[persPack.unitID][persPack.interrogatorID] = false
                    Spring.Echo("caught 4")

                    return true, persPack
                end

                -- check distance is still okay
                if distanceUnitToUnit(persPack.interrogatorID, persPack.unitID) > GameConfig.InterrogationDistance then
                    GG.InterrogationTable[persPack.unitID][persPack.interrogatorID] = false
                    Spring.Echo("caught 5 ")
                    setSpeedEnv(persPack.interrogatorID, 1.0)

                    return true, persPack
                end

                --check if the icon is still there
                if not persPack.IconId then
                    persPack.IconId =
                        createUnitAtUnit(
                        Spring.GetUnitTeam(persPack.interrogatorID),
                        iconUnitTypeName,
                        persPack.unitID,
                        0,
                        0,
                        0
                    )
                end

                if GG.RaidState and GG.RaidState[persPack.IconId] and GG.RaidState[persPack.IconId] ~= raidstate.OnGoing then
                    if GG.RaidState[persPack.IconId] == raidstate.AggressorWins then
                        --succesfull interrogation
                        local allTeams = Spring.GetTeamList()
                        if not allTeams or #allTeams <= 1 then
                            --Simulation mode
                            Spring.Echo("Aborting because no oponnent - sandbox or simulation mode")
                            Spring.DestroyUnit(persPack.IconId, true, true)
                            return true, persPack
                        end
                        --of a innocent person / innocent house
                        if
                            innocentCivilianTypeTable[persPack.suspectDefID] or
                                persPack.houseTypeTable[persPack.suspectDefID]
                         then
                            Spring.Echo("Interrogated innocent civilian")
                            -- Propandapunishment for Unjust Raids & Interrogations: Remember Guantanamo
                            assert(persPack.attackerTeam)
                            GG.Bank:TransferToTeam(
                                -GameConfig.RaidInterrogationPropgandaPrice,
                                persPack.attackerTeam,
                                persPack.attackerID
                            )
                            for i = 1, #allTeams, 1 do
                                if allTeams[i] ~= persPack.attackerTeam then
                                    GG.Bank:TransferToTeam(
                                        GameConfig.RaidInterrogationPropgandaPrice,
                                        allTeams[i],
                                        persPack.unitID
                                    )
                                end
                            end

                            Spring.DestroyUnit(persPack.IconId, true, true)
                            return true, persPack
                        end

                        Spring.Echo("Raid was succesfull - childs of " .. persPack.unitID .. " are revealed")
                        children = getChildrenOfUnit(Spring.GetUnitTeam(persPack.unitID), persPack.unitID)
                        parent = getParentOfUnit(Spring.GetUnitTeam(persPack.unitID), persPack.unitID)
                        GG.Bank:TransferToTeam(
                            GameConfig.RaidInterrogationPropgandaPrice,
                            persPack.attackerTeam,
                            persPack.attackerID
                        )
                        Spring.Echo(" caught 6 ")
                        for childID, v in pairs(children) do
                            if doesUnitExistAlive(childID) == true then
                                Spring.GiveOrderToUnit(childID, CMD.CLOAK, {}, {})
                                GG.OperativesDiscovered[childID] = true
                                Spring.SetUnitAlwaysVisible(childID, true)
                            end
                        end

                        if doesUnitExistAlive(parent) == true then
                            Spring.GiveOrderToUnit(parent, CMD.CLOAK, {}, {})
                            GG.OperativesDiscovered[parent] = true
                            Spring.SetUnitAlwaysVisible(parent, true)
                        end
                    end
                end

                return false, persPack
            end

            Spring.Echo("Starting Raid Event Stream")
            createStreamEvent(
                unitID,
                raidEventStreamFunction,
                31,
                {
                    interrogatorID = attackerID,
                    unitID = unitID,
                    suspectDefID = unitDefID,
                    attackerTeam = attackerTeam,
                    attackerID = attackerID,
                    houseTypeTable = houseTypeTable
                }
            )
        end

        --on Complete Raid/Interrogation
        --Transfer Units into No Longer Cloakable table
        -- SetAlwaysVisible
        -- Set Uncloak
    end


    interrogationEventStreamFunction = function(
        unitID,
        unitDefID,
        unitTeam,
        damage,
        paralyzer,
        weaponDefID,
        attackerID,
        attackerDefID,
        attackerTeam,
        iconUnitTypeName)

        if GG.InterrogationTable[unitID] == nil then
            GG.InterrogationTable[unitID] = {}
        end
        if GG.InterrogationTable[unitID][attackerID] == nil then
            GG.InterrogationTable[unitID][attackerID] = false
        end

        if GG.InterrogationTable[unitID][attackerID] == false then
            GG.InterrogationTable[unitID][attackerID] = true

    
            --Stun
            interrogationFunction = function(persPack)
                --check Target is still existing
                if false == doesUnitExistAlive(persPack.unitID) then
                    GG.InterrogationTable[persPack.unitID][persPack.interrogatorID] = false
                    Spring.Echo("Interrrogation: Target díed")
                    if true == doesUnitExistAlive(persPack.interrogatorID) then
                        setSpeedEnv(persPack.interrogatorID, 1.0)
                    end
                    if persPack.IconId then
                        GG.raidIconDone[persPack.IconId] = nil
                    end
                    return true, persPack
                end

                --check wether the interrogator is still alive
                if false == doesUnitExistAlive(persPack.interrogatorID) then
                    GG.InterrogationTable[persPack.unitID][persPack.interrogatorID] = false
                    Spring.Echo("Interrrogation End: Interrogator died")
                    if persPack.IconId then
                        GG.raidIconDone[persPack.IconId] = nil
                    end
                    return true, persPack
                end

                -- check distance is still okay
                if distanceUnitToUnit(persPack.interrogatorID, persPack.unitID) > GameConfig.InterrogationDistance then
                    GG.InterrogationTable[persPack.unitID][persPack.interrogatorID] = false
                    Spring.Echo("Interrrogation End: Interrogator distance to big ")
                    setSpeedEnv(persPack.interrogatorID, 1.0)
                    if persPack.IconId then
                        GG.raidIconDone[persPack.IconId] = nil
                    end
                    return true, persPack
                end

                --check if the icon is still there
                if not persPack.IconId then
                    persPack.IconId =
                        createUnitAtUnit(
                        Spring.GetUnitTeam(persPack.interrogatorID),
                        iconUnitTypeName,
                        persPack.unitID,
                        0,
                        0,
                        0
                    )
                    if not GG.raidIconDone then
                        GG.raidIconDone = {}
                    end
                    if not GG.raidIconDone[persPack.IconId] then
                        GG.raidIconDone[persPack.IconId] = {
                            boolInterogationComplete = false,
                            winningTeam = nil                      }
                    end
                end

                --update the icons  percentage
                GG.raidIconDone[persPack.IconId].countDown =
                    (Spring.GetGameFrame() - persPack.startFrame) / GameConfig.InterrogationTimeInFrames
           

                if GG.raidIconDone[persPack.IconId].boolInterogationComplete == true then

                    if not GG.raidIconDone[persPack.IconId].winningTeam then
                        --succesfull interrogation
                        local allTeams = Spring.GetTeamList()
                        if not allTeams or #allTeams <= 1 then
                            --Simulation mode
                            Spring.Echo("Interrogation: Aborting because no oponnent - sandbox or simulation mode")
                            Spring.DestroyUnit(persPack.IconId, true, true)
                            return true, persPack
                        end
                        
                        --of a innocent person / innocent house
                        if
                            innocentCivilianTypeTable[persPack.suspectDefID] or
                                persPack.houseTypeTable[persPack.suspectDefID]
                         then
                            Spring.Echo("Interrogated innocent - paying the price")
                            -- Propandapunishment for Unjust Raids & Interrogations: Remember Guantanamo
                            assert(persPack.attackerTeam)
                            GG.Bank:TransferToTeam(
                                -GameConfig.RaidInterrogationPropgandaPrice,
                                persPack.attackerTeam,
                                persPack.attackerID
                            )
    						
                            for i = 1, #allTeams, 1 do
                                if allTeams[i] ~= persPack.attackerTeam then
                                    GG.Bank:TransferToTeam(
                                        GameConfig.RaidInterrogationPropgandaPrice,
                                        allTeams[i],
                                        persPack.unitID
                                    )
                                end
                            end

                            Spring.DestroyUnit(persPack.IconId, true, true)
                            return true, persPack
                        end
                    end

                        Spring.Echo("Interrogation: Raid was succesfull - childs of " .. persPack.unitID .. " are revealed")
                        children = getChildrenOfUnit(Spring.GetUnitTeam(persPack.unitID), persPack.unitID)
                        parent = getParentOfUnit(Spring.GetUnitTeam(persPack.unitID), persPack.unitID)
                        GG.Bank:TransferToTeam(
                            GameConfig.RaidInterrogationPropgandaPrice,
                            persPack.attackerTeam,
                            persPack.attackerID
                        )
                     
                        for childID, v in pairs(children) do
                               Spring.Echo("Interrogation: Reavealing child "..childID)
                            if doesUnitExistAlive(childID) == true then
                                Spring.GiveOrderToUnit(childID, CMD.CLOAK, {}, {})
                                GG.OperativesDiscovered[childID] = true
                                Spring.SetUnitAlwaysVisible(childID, true)
                            end
                        end

                        if doesUnitExistAlive(parent) == true then
                            Spring.GiveOrderToUnit(parent, CMD.CLOAK, {}, {})
                            GG.OperativesDiscovered[parent] = true
                            Spring.SetUnitAlwaysVisible(parent, true)
                        end

                    --out of time to interrogate
                    Spring.DestroyUnit(persPack.unitID, false, true)
                    Spring.DestroyUnit(persPack.IconId, false, true)
                    GG.InterrogationTable[persPack.unitID][persPack.interrogatorID] = nil
                    Spring.Echo("Interrogation: Raid ended")
                    setSpeedEnv(persPack.interrogatorID, 1.0)
                    GG.raidIconDone[persPack.IconId] = nil
                    return true, persPack
                end

                return false, persPack
            end

            Spring.Echo("Starting Interrogation Event Stream")
            createStreamEvent(
                unitID,
                interrogationFunction,
                31,
                {
                    interrogatorID = attackerID,
                    unitID = unitID,
                    suspectDefID = unitDefID,
                    attackerTeam = attackerTeam,
                    attackerID = attackerID,
                    houseTypeTable = houseTypeTable
                }
            )
        end

        --on Complete Raid/Interrogation
        --Transfer Units into No Longer Cloakable table
        -- SetAlwaysVisible
        -- Set Uncloak
    end

    UnitDamageFuncT[stunpistoldWeaponDefID] = function(
        unitID,
        unitDefID,
        unitTeam,
        damage,
        paralyzer,
        weaponDefID,
        attackerID,
        attackerDefID,
        attackerTeam)
        --stupidity edition
        if attackerID == unitID then
            Spring.Echo("Interrogation:Aborted: attackerID == unitID")
            return damage
        end

        Spring.Echo("Stunning unit" .. unitID)
        if unitID ~= attackerID then
            stunUnit(unitID, 2.0)
        end

        --make disguise civilians transparent
        if civilianWalkingTypeTable[unitDefID] and GG.DisguiseCivilianFor[unitID] then
            stunUnit(unitID, stunContainerUnitTimePeriodInSeconds)
            unitID = GG.DisguiseCivilianFor[unitID]
            unitDefID = Spring.GetUnitDefID(unitID)
            unitTeam = Spring.GetUnitTeam(unitID)
        end

        if MobileInterrogateAbleType[unitDefID] and currentlyInterrogationRunning(unitID, attacker) == false then
            Spring.Echo("Interrogation: Start with " .. UnitDefs[unitDefID].name)
            stunUnit(unitID, 2.0)
            setSpeedEnv(attackerID, 0.0)
            interrogationEventStreamFunction(
                unitID,
                unitDefID,
                unitTeam,
                damage,
                paralyzer,
                weaponDefID,
                attackerID,
                attackerDefID,
                attackerTeam,
                "interrogationIcon"
            )
            return damage
        end
    end

    -----------------------------------------------------------------------------------------------------------------------
    -----------------------------------------------------------------------------------------------------------------------
    -- Raid
    -----------------------------------------------------------------------------------------------------------------------
    -----------------------------------------------------------------------------------------------------------------------

    UnitDamageFuncT[raidWeaponDefID] = function(
        unitID,
        unitDefID,
        unitTeam,
        damage,
        paralyzer,
        weaponDefID,
        attackerID,
        attackerDefID,
        attackerTeam)
        Spring.Echo("Raid/Interrogatable Weapon fired upon " .. UnitDefs[unitDefID].name)

        --stupidity edition
        if attackerID == unitID then
            Spring.Echo("Raid Aborted")
            return damage
        end

        --make houses transparent
        if houseTypeTable[unitDefID] and GG.houseHasSafeHouseTable[unitID] then
            stunUnit(unitID, stunContainerUnitTimePeriodInSeconds)
            unitID = GG.houseHasSafeHouseTable[unitID]
            stunUnit(unitID, stunContainerUnitTimePeriodInSeconds)
            unitDefID = Spring.GetUnitDefID(unitID)
            unitTeam = Spring.GetUnitTeam(unitID)
        end

        --stupidity edition
        if attackerID == unitID then
            return damage
        end

        --Interrogation -- and not already Interrogated
        if
            (houseTypeTable[unitDefID] or RaidAbleType[unitDefID]) and
                currentlyInterrogationRunning(unitID, attacker) == false
         then
            Spring.Echo("Raid of " .. UnitDefs[unitDefID].name)
            stunUnit(unitID, 2.0)
            setSpeedEnv(attackerID, 0.0)
            interrogationEventStreamFunction(
                unitID,
                unitDefID,
                unitTeam,
                damage,
                paralyzer,
                weaponDefID,
                attackerID,
                attackerDefID,
                attackerTeam,
                "raidicon"
            )
            return damage
        end
    end

    function gadget:UnitDamaged(
        unitID,
        unitDefID,
        unitTeam,
        damage,
        paralyzer,
        weaponDefID,
        projectileID,
        attackerID,
        attackerDefID,
        attackerTeam)
        if UnitDamageFuncT[weaponDefID] then
            resultDamage =
                UnitDamageFuncT[weaponDefID](
                unitID,
                unitDefID,
                unitTeam,
                damage,
                paralyzer,
                weaponDefID,
                attackerID,
                attackerDefID,
                attackerTeam
            )
            if resultDamage then
                return resultDamage
            end
        end
    end

    --===========Projectile Persistence Functions ====================================================
    local NewUnitsInPanic = {}
    function gadget:ProjectileCreated(proID, proOwnerID, projWeaponDefID)
        if panicWeapons[projWeaponDefID] then
            T =
                process(
                getAllNearUnit(proOwnerID, panicWeapons[projWeaponDefID].range),
                function(id)
                    if
                        Spring.GetUnitTeam(id) == GaiaTeamID and not GG.DisguiseCivilianFor[id] and
                            civilianWalkingTypeTable[Spring.GetUnitDefID(id)]
                     then
                        if
                            civilianWalkingTypeTable[Spring.GetUnitDefID(id)] and not GG.DisguiseCivilianFor[id] and
                                not GG.AerosolAffectedCivilians[id]
                         then
                            NewUnitsInPanic[id] = {
                                proOwnerID = proOwnerID,
                                flighttime = (panicWeapons[projWeaponDefID].damage * panicWeapons[projWeaponDefID].range) /
                                    30,
                                updateIntervall = 33
                            }
                            return id
                        end
                    end
                end
            )
        end
    end

    function gadget:GameFrame(n)
        if n % 33 == 0 and count(NewUnitsInPanic) > 0 then
            flightFunction = function(evtID, frame, persPack, startFrame)
                --Setup
                if not GG.FleeingCivilians then
                    GG.FleeingCivilians = {}
                end
                if not persPack.startFrame then
                    persPack.startFrame = Spring.GetGameFrame()
                end
                myID = persPack.unitID
                attackerID = persPack.attackerID
                boolIsDead = Spring.GetUnitIsDead(myID)
                if not boolIsDead or boolIsDead == true then
                    GG.FleeingCivilians[myID] = nil
                    return nil, persPack
                end

                if Spring.GetUnitIsDead(attackerID) == true then
                    return nil, persPack
                end

                if not GG.FleeingCivilians[myID] then
                    GG.FleeingCivilians[myID] = {flighttime = persPack.flighttime, startFrame = Spring.GetGameFrame()}
                end

                GG.FleeingCivilians[myID].flighttime = GG.FleeingCivilians[myID].flighttime - persPack.updateIntervall

                --we have two panic events.. the older one has too die
                if GG.FleeingCivilians[myID].startFrame > persPack.startFrame then
                    return nil, persPack
                end

                if GG.FleeingCivilians[myID] < 0 then
                    return nil, persPack
                end

                runAwayFrom(myID, attackerID, persPack.civilianFleeDistance)

                return frame + persPack.updateIntervall, persPack
            end

            for id, data in pairs(NewUnitsInPanic) do
                if id then
                    GG.EventStream:CreateEvent(
                        flightFunction,
                        {
                            --persistance Pack
                            unitID = id,
                            attackerID = data.proOwnerID,
                            flighttime = data.flighttime,
                            updateIntervall = data.updateIntervall
                        },
                        Spring.GetGameFrame() + (id % 10)
                    )
                end
            end
            NewUnitsInPanic = {}
        end
    end

    GROUND = string.byte("g")
    UNIT = string.byte("u")
    FEATURE = string.byte("f")
    PROJECTILE = string.byte("p")

    projectileDestroyedFunctions = {}

    function gadget:ProjectileDestroyed(proID)
        defid = Spring.GetProjectileDefID(proID)
        if projectileDestroyedFunctions[defID] then
            return projectileDestroyedFunctions[defID](proID, defID, Spring.GetProjectileTeamID(proID))
        end
    end

    function getProjectileTargetXYZ(proID)
        targetTypeInt, target = Spring.GetProjectileTarget(proID)

        if targetTypeInt == GROUND then
            echo("ProjectileTarget:", target[1], target[2], target[3])
            return target[1], target[2], target[3]
        end
        if targetTypeInt == UNIT then
            ux, uy, uz = Spring.GetUnitPosition(target)
            return ux, uy, uz
        end
        if targetTypeInt == FEATURE then
            fx, fy, fz = Spring.GetFeaturePosition(target)
            return fx, fy, fz
        end
        if targetTypeInt == PROJECTILE then
            px, py, pz = Spring.GetProjectilePosition(target)
            return px, py, pz
        end
    end

    function gadget:ShieldPreDamaged(
        proID,
        proOwnerID,
        shieldEmitterWeaponNum,
        shieldCarrierUnitID,
        bounceProjectile,
        startx,
        starty,
        startz,
        hitx,
        hity,
        hitz)
        return false
    end
end
