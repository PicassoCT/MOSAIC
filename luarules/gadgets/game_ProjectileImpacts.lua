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
    VFS.Include("scripts/lib_mosaic.lua")

    if not GG.AerosolAffectedCivilians then GG.AerosolAffectedCivilians = {} end
    --boolDebugProjectile = false
    local UnitDamageFuncT = {}
    local UnitDefNames = getUnitDefNames(UnitDefs)
    local GameConfig = getGameConfig()
    local civilianWalkingTypeTable = getCultureUnitModelTypes(
                                         GameConfig.instance.culture,
                                         "civilian", UnitDefs)
    local loudLongRangeWeaponTypes = getLoudLongRangeWeaponTypes(WeaponDefs)
    
    local isCloseCombatCapabaleType = getCloseCombatAbleTypes(UnitDefs)
    local houseTypeTable = getCultureUnitModelTypes(GameConfig.instance.culture,
                                                    "house", UnitDefs)

    local turnCoatFactoryType = getTurnCoatFactoryType(UnitDefs)

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
    local spSpawnCEG = Spring.SpawnCEG
    local spEcho =  Spring.Echo 
    local GaiaTeamID = Spring.GetGaiaTeamID()
    local MobileInterrogateAbleType = getMobileInterrogateAbleTypeTable(UnitDefs)
    if GameConfig.instance.culture == "arabic" then
        assert(MobileInterrogateAbleType[UnitDefNames["civilian_arab0"].id] ~= nil)
    end
    local RaidAbleType = getRaidAbleTypeTable(UnitDefs)
    -- Set Watch Weapon
    local targetLaserWeaponDefID = WeaponDefNames["targetlaser"].id
    Script.SetWatchWeapon(targetLaserWeaponDefID, true)  
    local closeCombatWeaponDefID = WeaponDefNames["closecombat"].id
    Script.SetWatchWeapon(closeCombatWeaponDefID, true)  
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
    local antiscoutlettWeaponDefID = WeaponDefNames["antiairkamikaze"].id
    Script.SetWatchWeapon(antiscoutlettWeaponDefID, true)   

    local FireWeapons = {
        [molotowDefID] = true
    }
   
    RaidExternalAbort = {}

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
        conditionalEcho(boolDebugProjectile,GetInfo().name .. " Initialization started")
        if not GG.houseHasSafeHouseTable then
            GG.houseHasSafeHouseTable = {}
        end 
        if not GG.InterrogationTable then
            GG.InterrogationTable = {}
        end
    
     --raidinitialization
      if not GG.raidStatus  then GG.raidStatus = {} end
      if not GG.HouseRaidIconMap  then GG.HouseRaidIconMap = {} end

        --conditionalEcho(boolDebugProjectile,GetInfo().name .. " Initialization ended")
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


    -- Watched Weapons Weapons
    for wId, wRange in pairs(panicWeapons) do
        Script.SetWatchWeapon(wId, true)
    end



    -- ===========Explosion Functions ====================================================


  local explosionFunc = {
  
    [impactorWeaponDefID] =  function(weaponDefID, px, py, pz, AttackerID)
            id = Spring.CreateUnit("impactor", px, py, pz, 1, GaiaTeamID)
            Spring.SetUnitBlocking(id, false)
    end,
    [antiscoutlettWeaponDefID] =  function(weaponDefID, px, py, pz, AttackerID)
        if doesUnitExistAlive(AttackerID) then
            Spring.DestroyUnit(AttackerID, false, true)
            return true
        end
    end
  }

    function makeHouseVisible(houseID)
        env = Spring.UnitScript.GetScriptEnv(houseID)
        if env and env.showHouse then
            Spring.UnitScript.CallAsUnit(houseID, env.showHouse)
        end
    end

    moltowSmokeCegs= {
        "glowsmoke",
        "vehsmokepillar"
           }

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
            spSpawnCEG("flames", x + addx * xd, y + additional, z + addz * zd, dx, dy, dz, 50, 0)
            if maRa() == true then
                 spSpawnCEG("vortflames", x + addx * xd, y + additional, z + addz * zd, 0, 1, 0, 50, 0)
                   if maRa() == true then 
                       spSpawnCEG(moltowSmokeCegs[math.random(1,#moltowSmokeCegs)], x + addx * xd, y + additional, z + addz * zd, 0, 1, 0, 50, 0)
                   end
            end

            foreach(getAllInCircle(persPack.px, persPack.pz, persPack.range),
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

    function gadget:Explosion(weaponDefID, px, py, pz, AttackerID, projectileID)
 
        if explosionFunc[weaponDefID] then explosionFunc[weaponDefID](weaponDefID, px, py, pz, AttackerID, projectileID) 
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

    GG.CloseCombatInvolved = {}
    function initiateCloseCombat(DamagedUnitID, AttackerID)
        --echo("No Attacker"); 
        if not DamagedUnitID or not AttackerID then 
            return 
        end

        --echo("Self attack"); 
        if DamagedUnitID == AttackerID then 
            return 
        end
        
        if not doesUnitExistAlive(DamagedUnitID) or not doesUnitExistAlive(AttackerID) then
           -- echo("Unit is dead - no close combat")
            return 
        end

        --no interrogation running
        if currentlyInterrogationRunning(AttackerID, DamagedUnitID) or  currentlyInterrogationRunning(DamagedUnitID,AttackerID) then
            return 
        end 

        --make sure none of the two is alreay in Closed Combat
        if  GG.CloseCombatInvolved[DamagedUnitID] or GG.CloseCombatInvolved[AttackerID] then return end

        local px,py,pz = Spring.GetUnitPosition(DamagedUnitID)

        --create closeCombatArena
        arenaID = Spring.CreateUnit("closecombatarena", px,py,pz, 0, GaiaTeamID)
        rx,ry,rz = Spring.GetUnitRotation(DamagedUnitID)
        Spring.SetUnitRotation(arenaID, rx, ry, rz)
        GG.CloseCombatInvolved[DamagedUnitID] = arenaID
        GG.CloseCombatInvolved[AttackerID] = arenaID
        
        env = Spring.UnitScript.GetScriptEnv(arenaID)        
        if env and env.addCloseCombatants then
            Spring.UnitScript.CallAsUnit(arenaID, env.addCloseCombatants,  AttackerID, DamagedUnitID)
        end     

        --call into both to inform about - nolonger disguised, engaged in close combat
        env = Spring.UnitScript.GetScriptEnv(AttackerID)        
        if env and env.isNowInCloseCombat then
            Spring.UnitScript.CallAsUnit(AttackerID, env.isNowInCloseCombat,  arenaID)
        end
        env = Spring.UnitScript.GetScriptEnv(DamagedUnitID)       
        if env and env.isNowInCloseCombat then
            Spring.UnitScript.CallAsUnit(DamagedUnitID, env.isNowInCloseCombat,  arenaID)
        end
    end

    -----------------------------------------------------------------------------------------------------------------------
    -----------------------------------------------------------------------------------------------------------------------
    -- Interrogation
    -----------------------------------------------------------------------------------------------------------------------
    -----------------------------------------------------------------------------------------------------------------------
    function isEngagedInAnotherRaidAlready(attackerID, currentVictimID)
        local InterrogationTable =  GG.InterrogationTable 
        for victimID, raiders in pairs(InterrogationTable) do
            if victimID ~= currentVictimID then
                for raiderID, boolActive in pairs(raiders) do
                    if raiderID == attackerID and boolActive then  return true end
                end
            end
        end
        return false
    end

    function isInterrogatingAttacker(possibleAttackerID)
        local InterrogationTable =  GG.InterrogationTable
        for victim, attackerTable in pairs( GG.InterrogationTable) do
            if attackerTable then
                for attackerID, boolActive in pairs( attackerTable) do
                    if attackerID == possibleAttackerID and boolActive then return true end
                end
            end
        end
        return false
    end


    -- victim -- interrogator -- boolInerrogationOngoing

    local civilianWalkingTypeTable = getCultureUnitModelTypes(
                                         GameConfig.instance.culture,
                                         "civilian", UnitDefs)
    raidStates = getRaidStates()
    raidResultStates = getRaidResultStates()
    local innocentCivilianTypeTable = getPanicableCiviliansTypeTable(UnitDefs)

   raidEventStreamFunction = function(raidedSafeHouseOrHouse_ID, unitDefID, unitTeam, damage,
                                       paralyzer, weaponDefID, attackerID,
                                       attackerDefID, attackerTeam,
                                       iconUnitTypeName, civilianHouseID)
        boolRaidedEmptyHouse = (raidedSafeHouseOrHouse_ID == civilianHouseID )

        conditionalEcho(boolDebugProjectile,"Raid: EventStream  Called")

        postRaidCleanup =   function (persPack, boolDoesTargetExistAlive, boolDoesInterrogatorExistAlive)
                                   conditionalEcho(boolDebugProjectile,"Raid: CleanUp ")

                                    if doesUnitExistAlive(persPack.civilianHouseID) == true then
                                        Spring.SetUnitHealth (persPack.civilianHouseID, {paralyze= 0})
                                        Spring.SetUnitNoSelect(persPack.civilianHouseID, false)
                                        makeHouseVisible(persPack.civilianHouseID)
                                    end

                                    --Stop Attacker form reintterogating the same building
                                    if doesUnitExistAlive(persPack.AttackerID) == true then
                                       Command(persPack.AttackerID, "stop")
                                    end  

                                    if persPack.basePlateID and doesUnitExistAlive(persPack.basePlateID) then
                                       Spring.DestroyUnit(persPack.basePlateID, false, true)
                                    end

                                    if persPack.IconID and doesUnitExistAlive(persPack.IconID) == true then
                                        Spring.DestroyUnit(persPack.IconID, false, true)
                                         GG.raidStatus[persPack.IconID] = nil
                                    end

                                    GG.InterrogationTable[persPack.raidedSafeHouseOrHouse_ID] = nil
                                    GG.HouseRaidIconMap[persPack.civilianHouseID] = nil
                                end
                                

        if GG.InterrogationTable[raidedSafeHouseOrHouse_ID] == nil then
            GG.InterrogationTable[raidedSafeHouseOrHouse_ID] = {}
        else
            --check if there are previous raids active
            for raiders, boolRaidOngoing in pairs(GG.InterrogationTable[raidedSafeHouseOrHouse_ID]) do
                if boolRaidOngoing == true then
                    conditionalEcho(boolDebugProjectile, "Raid: House already has raid ongoing aborting")
                    return
                end
            end
        end
        
        if GG.InterrogationTable[raidedSafeHouseOrHouse_ID][attackerID] == nil then
            GG.InterrogationTable[raidedSafeHouseOrHouse_ID][attackerID] = false
        end

        --check if the attacker is not already engaged in another raid
        if isEngagedInAnotherRaidAlready(attackerID, raidedSafeHouseOrHouse_ID) == true then
            conditionalEcho(boolDebugProjectile,"Raid: raidEventStream Aborted, previous Raid in Progress"..raidedSafeHouseOrHouse_ID)
            return true, persPack
        end

        if GG.InterrogationTable[raidedSafeHouseOrHouse_ID][attackerID] == false then
            GG.InterrogationTable[raidedSafeHouseOrHouse_ID][attackerID] = true
            -- Stun
            raidFunction = function(persPack)
            boolDebugProjectile = true
           -- conditionalEcho(boolDebugProjectile,"raidEventStream  Ongoing")

                -- check Target is still existing
                if false == doesUnitExistAlive(persPack.raidedSafeHouseOrHouse_ID) then
                    conditionalEcho(boolDebugProjectile,"Raid: failed check Target is still existing ")
                    GG.raidStatus[persPack.IconID].state = raidStates.Aborted
                    GG.raidStatus[persPack.IconID].boolInterogationComplete = true
                    postRaidCleanup(persPack)
                    return true, persPack
                end

                -- check wether the interrogator is still alive
                if false == doesUnitExistAlive(persPack.interrogatorID) then
                    conditionalEcho(boolDebugProjectile,"Raid: failed   check wether the interrogator is still alive")
                    GG.raidStatus[persPack.IconID].state = raidStates.Aborted
                    GG.raidStatus[persPack.IconID].boolInterogationComplete = true
                    postRaidCleanup(persPack)
                    return true, persPack
                end

                -- check distance is still okay
                if distanceUnitToUnit(persPack.interrogatorID, persPack.raidedSafeHouseOrHouse_ID) > GameConfig.RaidDistance then
                    conditionalEcho(boolDebugProjectile,"Raid: failed check distance is still okay5 ")
                    if doesUnitExistAlive(persPack.IconID) == true then
                    GG.raidStatus[persPack.IconID].state = raidStates.Aborted
                    GG.raidStatus[persPack.IconID].boolInterogationComplete = true
                    persPack.boolRaidHasEnded = true 
                end
                    postRaidCleanup(persPack)
                    return true, persPack
                end
                
                --Raid has ended
                if persPack.boolRaidHasEnded == true then 
                    return true, persPack 
                end
                
                -- check if the icon is still there
                if not persPack.IconID then
                  
                    persPack.IconID = createUnitAtUnit(
                                          spGetUnitTeam(persPack.interrogatorID),--teamID
                                          iconUnitTypeName, --typeID
                                          persPack.civilianHouseID,  --otherID
                                          0,0,0,  -- ox, oy, oz
                                          0)   --orientation 
                    conditionalEcho(boolDebugProjectile, "Raid: create Icon "..  persPack.IconID  .." at Unit "..persPack.civilianHouseID)

                    if persPack.IconID then
                        GG.HouseRaidIconMap[persPack.civilianHouseID] =  persPack.IconID
                        persPack.basePlateID = createUnitAtUnit(
                                          spGetUnitTeam(persPack.IconID),--teamID
                                          "raidiconbaseplate", --typeID
                                          persPack.civilianHouseID,  --otherID
                                          0,0,0,  -- ox, oy, oz
                                          0)   --orientation 
                        conditionalEcho(boolDebugProjectile,"Raid: create BaseplateIcon "..persPack.basePlateID .." at "..persPack.civilianHouseID )      
                        GG.myParent[persPack.basePlateID] = persPack.IconID

                        conditionalEcho(boolDebugProjectile,"Raid: Registering RaidIcon to raidedSafeHouseOrHouse_ID "..persPack.raidedSafeHouseOrHouse_ID )

                        assert(GG.HouseRaidIconMap[persPack.civilianHouseID])

                        if GG.raidStatus[persPack.IconID] then  GG.raidStatus[persPack.IconID] = {} end
                        GG.raidStatus[persPack.IconID].boolInterogationComplete = false
                    else
                        conditionalEcho(boolDebugProjectile,"Raid: No IconID")
                        postRaidCleanup(persPack)
                        return true, persPack
                    end
                end
  
                --check 
                if GG.raidStatus[persPack.IconID].boolAnimationComplete  then

                    local allTeams = spGetTeamList()
                    local raidStateLocal = GG.raidStatus[persPack.IconID]
                    --echo("Animation completed")
                    --Aborted or EmptyHouse
                    if raidStateLocal.result == raidResultStates.HouseEmpty or persPack.boolRaidedEmptyHouse then
                        if  persPack.houseTypeTable[persPack.suspectDefID] then
                            conditionalEcho(boolDebugProjectile,"Raided empty house")
                            -- Propandapunishment for Unjust Raids & Interrogations: Remember Guantanamo
                            assert(persPack.attackerTeam)
                            GG.Bank:TransferToTeam(
                                -GameConfig.raid.interrogationPropagandaPrice,
                                persPack.attackerTeam, persPack.attackerID)
                            for i = 1, #allTeams, 1 do
                                if allTeams[i] ~= persPack.attackerTeam then
                                    GG.Bank:TransferToTeam(
                                        GameConfig.raid.interrogationPropagandaPrice,
                                        allTeams[i], persPack.raidedSafeHouseOrHouse_ID)
                                end
                            end
                        end
                        postRaidCleanup(persPack)
                        persPack.boolRaidHasEnded = true
                        return true, persPack
                    end


                    if (raidStateLocal.state == raidStates.Aborted) or 
                        not allTeams or #allTeams <= 1 then 
                        -- Simulation mode
                        conditionalEcho(boolDebugProjectile,"Raid: Aborted ")
                        postRaidCleanup(persPack)
                        persPack.boolRaidHasEnded = true
                        return true, persPack
                    end 

                    --wait for uplink completed (set by the icon)
                    if raidStateLocal.state == raidStates.VictoryStateSet and
                        raidStateLocal.result == raidResultStates.AggressorWins       
                        then
                        conditionalEcho(boolDebugProjectile,"Raid: was succesfull - childs of " .. persPack.raidedSafeHouseOrHouse_ID .. " are revealed")
                        unitTeam = spGetUnitTeam(persPack.raidedSafeHouseOrHouse_ID)
                        children = getChildrenOfUnit(unitTeam, persPack.raidedSafeHouseOrHouse_ID)
                        parent = getParentOfUnit(unitTeam, persPack.raidedSafeHouseOrHouse_ID)
                        GG.Bank:TransferToTeam(
                            GameConfig.raid.interrogationPropagandaPrice,
                            persPack.attackerTeam, persPack.attackerID)
                        registerRevealedUnitLocation(persPack.raidedSafeHouseOrHouse_ID)
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
                        Spring.DestroyUnit(persPack.raidedSafeHouseOrHouse_ID, false, true)
                        postRaidCleanup(persPack)
                        persPack.boolRaidHasEnded = true
                        return true, persPack
                    end
                end

         return false, persPack
        end
        
            echo("Starting Raid Event Stream")
            createStreamEvent(raidedSafeHouseOrHouse_ID, raidFunction, 31, {
                interrogatorID = attackerID,
                raidedSafeHouseOrHouse_ID = raidedSafeHouseOrHouse_ID,
                suspectDefID = unitDefID,
                attackerTeam = attackerTeam,
                attackerID = attackerID,
                houseTypeTable = houseTypeTable,
                civilianHouseID = civilianHouseID,
                boolRaidedEmptyHouse = boolRaidedEmptyHouse
            })
        end

        -- on Complete Raid/Interrogation
        -- Transfer Units into No Longer Cloakable table
        -- SetAlwaysVisible
        -- Set Uncloak
    end

    function postInterrogationCleanUp(victimID, interrogatorID, iconID)
        if interrogatorID and doesUnitExistAlive(interrogatorID) then
           setSpeedEnv(interrogatorID, 1.0)
        end  

        if victimID and doesUnitExistAlive(victimID) then
            Spring.SetUnitHealth (victimID, {paralyze= 0})
           setSpeedEnv(victimID, 1.0)
           updateInterrogatedStatus(victimID, false)
        end

        if iconID and doesUnitExistAlive(iconID) then
            GG.raidStatus[iconID] = nil
            Spring.DestroyUnit(iconID, true, false)
        end

        GG.InterrogationTable[victimID] = nil
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

         --check if the attacker is not already engaged in another raid
        if isEngagedInAnotherRaidAlready(attackerID, unitID) == true then
            --conditionalEcho(boolDebugProjectile,"Interogation: raidEventStream Aborted, previous Raid in Progress"..unitID)
            return true, persPack
        end

        if GG.InterrogationTable[unitID][attackerID] == false then
            GG.InterrogationTable[unitID][attackerID] = true

            -- Stun
            interrogationFunction = function(persPack)
          
                -- check Target is still existing
                if false == doesUnitExistAlive(persPack.unitID) then
                    --conditionalEcho(boolDebugProjectile,"Interogation End: Target died")
                    postInterrogationCleanUp(persPack.unitID, persPack.interrogatorID, persPack.IconID)
                    return true, persPack
                end

                -- check wether the interrogator is still alive
                if false == doesUnitExistAlive(persPack.interrogatorID) then
                    --conditionalEcho(boolDebugProjectile,"Interrogation End: Interrogator died")
                    postInterrogationCleanUp(persPack.unitID, persPack.interrogatorID, persPack.IconID)
                    return true, persPack
                end

                -- check for external abort
                if RaidExternalAbort[persPack.interrogatorID] == true then                    
                    --conditionalEcho(boolDebugProjectile,"Interrogation End: Interrogator was shot at")
                    RaidExternalAbort[persPack.interrogatorID] = nil                    
                    postInterrogationCleanUp(persPack.unitID, persPack.interrogatorID, persPack.IconID)
                    return true, persPack
                end

                -- check distance is still okay
                if distanceUnitToUnit(persPack.interrogatorID, persPack.unitID) >
                    GameConfig.InterrogationDistance then
                    --conditionalEcho(boolDebugProjectile,"Interogation End: Interrogator distance to big ")
                    postInterrogationCleanUp(persPack.unitID, persPack.interrogatorID, persPack.IconID)                        
                    return true, persPack
                end

                -- check if the icon is still there
                if not persPack.IconID then
                    --conditionalEcho(boolDebugProjectile,"createUnitAtUnit ".."game_ProjectileImpacts.lua")      
                    persPack.IconID = createUnitAtUnit(
                                          spGetUnitTeam(persPack.interrogatorID),
                                          iconUnitTypeName, 
                                          persPack.unitID,
                                          0, 0, 0,
                                          nil,
                                          1)                         
                    
                    if not persPack.IconID then
                          --conditionalEcho(boolDebugProjectile,"Creating InterrogationIcon failed")
                        updateInterrogatedStatus(persPack.unitID, false)
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
                    --conditionalEcho(boolDebugProjectile,"InterogationCompleted")
               
                    if not GG.raidStatus[persPack.IconID].winningTeam then
                        -- succesfull interrogation
                        local allTeams = spGetTeamList()
                        if not allTeams or #allTeams <= 1 then
                            -- Simulation mode
                            --conditionalEcho(boolDebugProjectile, "Interrogation: Aborting because no oponnent - sandbox or simulation mode")
                            postInterrogationCleanUp(persPack.unitID, persPack.interrogatorID, persPack.IconID)        
                            return true, persPack
                        end

                        -- of a innocent person / innocent house
                        if innocentCivilianTypeTable[persPack.suspectDefID] or
                            persPack.houseTypeTable[persPack.suspectDefID] then
                            --conditionalEcho(boolDebugProjectile,"Interrogated innocent - paying the price")
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

                            Command(persPack.interrogatorID, "stop", {"shift"})
                            Command(persPack.interrogatorID, "stop", {})
                            say("Innocent", 2500, { r = 1.0, g = 0.0, b = 0.0 }, { r = 1.0, g = 0.0, b = 0.0 }, "", persPack.unitID)
                            postInterrogationCleanUp(persPack.unitID, persPack.interrogatorID, persPack.IconID)     
                            return true, persPack
                        end
                    end

                    --conditionalEcho(boolDebugProjectile,"Interrogation was succesfull - childs of " .. persPack.unitID .. " are revealed")
                    unitTeam = spGetUnitTeam(persPack.unitID)
                    local children = getChildrenOfUnit(unitTeam, persPack.unitID)
                    local parent = getParentOfUnit(unitTeam, persPack.unitID)
                   -- if not children then conditionalEcho(boolDebugProjectile,"Unit "..persPack.unitID.. " has no children") end
                   -- if not parent then conditionalEcho(boolDebugProjectile,"Unit "..persPack.unitID.. " has no parent") end
                    GG.Bank:TransferToTeam(
                        GameConfig.raid.interrogationPropagandaPrice,
                        persPack.attackerTeam, persPack.attackerID)
                        registerRevealedUnitLocation(persPack.unitID)

                    for childID, v in pairs(children) do
                        --conditionalEcho(boolDebugProjectile,"Interrogation: Reavealing child " .. childID)
                        if doesUnitExistAlive(childID) == true then
                            spGiveOrderToUnit(childID, CMD.CLOAK, {}, {})
                            GG.OperativesDiscovered[childID] = true
                            spSetUnitAlwaysVisible(childID, true)
                        end
                    end

                    if doesUnitExistAlive(parent) == true then
                        --conditionalEcho(boolDebugProjectile,"Interrogation: Reavealing parent " .. parent)
                        spGiveOrderToUnit(parent, CMD.CLOAK, {}, {})
                        GG.OperativesDiscovered[parent] = true
                        spSetUnitAlwaysVisible(parent, true)
                    end

                    --if unit is a assembly, tranfer all produced units to other team
                    if turnCoatFactoryType[spGetUnitDefID(persPack.unitID)] then
                        setAssemblyProducedUnitsToTeam(assemblyID, Spring.GetUnitTeam(persPack.interrogatorID))
                    end

                    -- out of time to interrogate
                    for disguiseID, agentID in pairs(GG.DisguiseCivilianFor) do
                        if persPack.unitID == agentID then
                            spDestroyUnit(disguiseID, false, true)
                            GG.DisguiseCivilianFor[disguiseID] = nil
                        end
                    end
                   
                    spDestroyUnit(persPack.unitID, false, true)
                    spDestroyUnit(persPack.IconID, false, true)
                    GG.InterrogationTable[persPack.unitID][persPack.interrogatorID] =  nil
                    --conditionalEcho(boolDebugProjectile,"Interrogation ended successfuly")

                    postInterrogationCleanUp(persPack.unitID, persPack.interrogatorID, persPack.IconID)     
                    return true, persPack
                end

                return false, persPack
            end

            --conditionalEcho(boolDebugProjectile,"Starting Interrogation Event Stream")
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
                 attackerID, attackerDefID, attackerTeam,projectileID)
            -- stupidity edition
            conditionalEcho(boolDebugProjectile,"Hit by interrogation weapon")
            if attackerID == unitID then
                --conditionalEcho(boolDebugProjectile,"Interrogation:Aborted: attackerID == unitID")
                return damage
            end

            -- stupidity edition same team
            if attackerTeam == unitTeam then
                --conditionalEcho(boolDebugProjectile,"Interrogation:Aborted: attackerTeam == unitTeam")
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
                currentlyInterrogationRunning(unitID, attackerID) == false and
                attackerID ~= unitID then
                --conditionalEcho(boolDebugProjectile,"Interrogation: Start with " .. UnitDefs[unitDefID].name.."->"..unitID)
                stunUnit(unitID, stunContainerUnitTimePeriodInSeconds)
                setSpeedEnv(attackerID, 0.0)
                RaidExternalAbort[attackerID] = false
                updateInterrogatedStatus(unitID, true)
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
    filterUnitDamageEvents = {}
    UnitDamageFuncT[raidWeaponDefID] = function(unitID, unitDefID, unitTeam,
                                                damage, paralyzer, weaponDefID,
                                                attackerID, attackerDefID,
                                                attackerTeam,projectileID)

        echo("Raid: Raid weapon hits "..unitID .. " a ".. UnitDefs[unitDefID].name)
        if not attackerID then
            attackerID = Spring.GetUnitLastAttacker(unitID)
        end

        -- stupidity edition
        if not attackerID then  conditionalEcho(boolDebugProjectile,"Raid: No valid attackerID derived"); return damage end
        if attackerID == unitID  then   conditionalEcho(boolDebugProjectile,"Raid:Aborted: attackerID == unitID"); return damage end
        houseID = unitID

        if not houseTypeTable[unitDefID] then
            echo("Raid: Hit not a house type. Aborted")
            return
        end

        filterUnitDamageEvents, boolFileredOut =  filterEventsUniqueByTime(filterUnitDamageEvents,""..houseID.."_"..unitID, 100*30 )
        if boolFileredOut then return end

        -- make houses transparent if they have a safehouse
        if  GG.houseHasSafeHouseTable[unitID] then
            stunUnit(unitID, stunContainerUnitTimePeriodInSeconds)
            oldID = unitID
            unitID = GG.houseHasSafeHouseTable[unitID]
            echo("Raided Unit ".. oldID.." is now:"..unitID)
            stunUnit(unitID, stunContainerUnitTimePeriodInSeconds)
            unitDefID = spGetUnitDefID(unitID)
            unitTeam = spGetUnitTeam(unitID)
        end


        -- Interrogation -- and not already Interrogated
        if ( RaidAbleType[unitDefID]) and
            currentlyInterrogationRunning(unitID, attacker) == false then
            conditionalEcho(boolDebugProjectile,"Raid of " .. UnitDefs[unitDefID].name.. " id: ".. unitID)
            stunUnit(unitID, 2.0)
            raidEventStreamFunction(unitID, unitDefID, unitTeam,
                                             damage, paralyzer, weaponDefID,
                                             attackerID, attackerDefID,
                                             attackerTeam, 
                                             "icon_raid", 
                                             houseID)
            return damage
        end
    end

    function makeDisguiseUnitTransparent(unitID, unitDefID)
        if civilianWalkingTypeTable[unitDefID] then
            if GG.DisguiseCivilianFor then
                id =   GG.DisguiseCivilianFor[unitID]
                if id then
                    if doesUnitExistAlive(id) == true then
                          return id, spGetUnitDefID(id)
                    end
                end
            end
        end
        return unitID, unitDefID
    end

    UnitDamageFuncT[closeCombatWeaponDefID] = function(unitID, unitDefID, unitTeam,
        damage, paralyzer, weaponDefID,
        attackerID, attackerDefID,
        attackerTeam,projectileID)

        if unitID == attackerID then return 0 end

        if GG.DisguiseCivilianFor[unitID] and GG.DisguiseCivilianFor[unitID] == attackerID then
            return 0
        end

        unitID, unitDefID = makeDisguiseUnitTransparent(unitID, unitDefID)

        if isCloseCombatCapabaleType[unitDefID] and isCloseCombatCapabaleType[attackerDefID] then
            initiateCloseCombat(unitID, attackerID)
        end
    end

    UnitDamageFuncT[nimrodRailungDefID] = function(unitID, unitDefID, unitTeam,
                                                damage, paralyzer, weaponDefID,
                                                attackerID, attackerDefID,
                                                attackerTeam,projectileID)

                                            if houseTypeTable[unitDefID] then return 0 end
                                        end

    UnitDamageFuncT[godRodMarkerWeaponDefID] =   function(unitID, unitDefID, unitTeam,
                                                damage, paralyzer, weaponDefID,
                                                attackerID, attackerDefID,
                                                attackerTeam,projectileID)

    end

    
    function gadget:UnitDamaged(unitID, unitDefID, unitTeam, damage, paralyzer,
                                weaponDefID, projectileID, attackerID,
                                attackerDefID, attackerTeam)
        if weaponDefID and WeaponDef and WeaponDef[weaponDefID] then
            conditionalEcho(boolDebugProjectile,"UnitDamaged called with weapon"..WeaponDef[weaponDefID].name)
        end

        --If Interrogator abort running interrogation 
        if isInterrogatingAttacker(unitID) and not (GG.InterrogationTable[attackerID] and GG.InterrogationTable[attackerID][unitID]) then
            RaidExternalAbort[unitID] = true
            return damage
        end

        if UnitDamageFuncT[weaponDefID] then
            resultDamage = UnitDamageFuncT[weaponDefID](unitID, unitDefID,
                                                        unitTeam, damage,
                                                        paralyzer, weaponDefID,
                                                        attackerID,
                                                        attackerDefID,
                                                        attackerTeam,
                                                        projectileID)
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

    function updateInterrogatedStatus(unitID, boolInterrogatedExternally)
        env = Spring.UnitScript.GetScriptEnv(unitID)
        if env and env.setBoolInterrogatedExternally then
            Spring.UnitScript.CallAsUnit(unitID,  env.setBoolInterrogatedExternally, boolInterrogatedExternally)
        end
    end

    local NewUnitsInPanic = {}

    function gadget:ProjectileCreated(proID, proOwnerID, projWeaponDefID)

        if ProjectileCreatedFunc[projWeaponDefID] then 
            ProjectileCreatedFunc[projWeaponDefID](proID, proOwnerID, projWeaponDefID) 
        end


        if panicWeapons[projWeaponDefID] then
            foreach(getAllNearUnit(proOwnerID,
                                   panicWeapons[projWeaponDefID].range,
                                   GaiaTeamID),
                    function(id)
                        if  civilianWalkingTypeTable[spGetUnitDefID(id)] and
                            GG.GlobalGameState == "normal" and
                            not GG.DisguiseCivilianFor[id] and                       
                            not GG.AerosolAffectedCivilians[id] then
                                startInternalBehaviourOfState(id,"startFleeing", proOwnerID)
                                echo("Send fleeing by panic weapons fired ")
                            return id
                        end
            end)
        end
        if loudLongRangeWeaponTypes[projWeaponDefID] then
            distToOwner = math.huge
            nearest = proOwnerID
            gameFrame = spGetGameFrame()
            allUnitsNearby = foreach(  getAllNearUnit(proID, 1024, gaiaTeamID),
                        function(id)
                            defID= spGetUnitDefID(id)
                            if houseTypeTable[defID]then
                                return id
                            end
                        end,
                        function(id)
                            if not civilianBuildingBirdTimer[id] then return id end
                            if civilianBuildingBirdTimer[id].frame < gameFrame + coolDownTimerCrowsInFramethen then return id end
                        end,
                        function(id)
                            newDistance= distUnitToUnit(id, projOwnerID) 
                            if newDistance < distToOwner then
                                nearest = id
                                distToOwner= newDistance
                            end
                        end
                        )
            if nearest ~= projOwnerID then
                civilianBuildingBirdTimer[nearest] = {frame = gameFrame, boolIsAtSea = isBuildingNearSea(nearest)}
                if civilianBuildingBirdTimer[nearest].boolIsAtSea then
                    createUnitAtUnit(gaiaTeamID, "gullswarm", nearest)
                else
                    createUnitAtUnit(gaiaTeamID, "ravenswarm", nearest)
                end
            end
        end
    end
    coolDownTimerCrowsInFrame = 8*60*30
    civilianBuildingBirdTimer = {}

    function isBuildingNearSea(buildingId)
        x,y,z = spGetUnitPosition(buildingId)
        local TestAreaDimension = 768
        min, max = getExtremasInArea(x -TestAreaDimension, z-TestAreaDimension, x +TestAreaDimension, z+ TestAreaDimension, (TestAreaDimension*2)/3)
        return min <= 1 and max < 50
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
         --   echo("ProjectileTarget:", target[1], target[2], target[3])
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

    local oldGameState= "normal"
    function DeActivateLoudLongRangeWeaponDefs (boolActivate)
        for k,v in pairs(loudLongRangeWeaponTypes) do
            Script.SetWatchWeapon(k, boolActivate)  
        end
    end

    function gadget:GameFrame(frame)
        if frame % 90 == 0 then
            local gameState = GG.GlobalGameState 
            if oldGameState ~= gameState then
                DeActivateLoudLongRangeWeaponDefs(gameState == "normal" )
                oldGameState = gameState
            end
        end
    end
end

