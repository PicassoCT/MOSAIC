function gadget:GetInfo()
    return {
        name = "Projectiles",
        desc = "This gadget handles projectileimpacts",
        author = "",
        date = "Sep. 2008",
        license = "GNU GPL, v2 or later",
        layer = 0,
        enabled = true,
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
	local civilianWalkingTypeTable = getCultureUnitModelTypes(GameConfig.instance.culture, "civilian", UnitDefs)
	GaiaTeamID = Spring.GetGaiaTeamID()

    local raidWeaponDefID = WeaponDefNames["raidarrest"].id
    local stunpistoldWeaponDefID = WeaponDefNames["stunpistol"].id
	
	function getWeapondefByName(name)
		return WeaponDefs[WeaponDefNames[name].id]
	end
	
	SSied_Def = getWeapondefByName("ssied")
	ak47_Def = getWeapondefByName("ak47")
	pistol_Def = getWeapondefByName("pistol")
	tankcannon_Def = getWeapondefByName("tankcannon")
	railgun_Def = getWeapondefByName("railgun")
	
	if not  GG.houseHasSafeHouseTable then  GG.houseHasSafeHouseTable = {} end
	function gadget:Initialize()
		if not  GG.houseHasSafeHouseTable then  GG.houseHasSafeHouseTable = {} end
	
	end
	

	
panicWeapons = {
		[WeaponDefNames["ssied"].id] = {damage = 500 ,range = SSied_Def.range},
		[WeaponDefNames["ak47"].id] = {damage = 100 ,range = ak47_Def.range},
		[WeaponDefNames["pistol"].id] ={damage =  75 ,range = pistol_Def.range},
		[WeaponDefNames["tankcannon"].id] ={ damage = 250 ,range = tankcannon_Def.range},
		[WeaponDefNames["railgun"].id] = {damage = 300 ,range = railgun_Def.range},
	}

	
	
    --Watched Weapons Weapons
	for wId, wRange in pairs(panicWeapons) do
	   Script.SetWatchWeapon(wId, true)
	end

    Script.SetWatchWeapon(raidWeaponDefID, true)
    Script.SetWatchWeapon(stunpistoldWeaponDefID, true)
	
    exampleDefID = -1
    InterrogateAbleType = getInterrogateAbleTypeTable(UnitDefs)

    --units To be exempted from instantly lethal force


    function ShockWaveRippleOutwards(x, z, force, speed, range)
        -- get all units in range
        if not GG.ShockWaves then GG.ShockWaves = {} end
        local OtherWaves = GG.ShockWaves
        assert(range)
        T = getAllInCircle(x, z, range)

        for i = 1, #T do
            ex, ey, ez = Spring.GetUnitPosition(T[i])

            dist = distance(x, z, ex, ez)
            const = force / dist

            if not OtherWaves[math.ceil(dist / speed)] then OtherWaves[math.ceil(dist / speed)] = {} end
            myT = { id = T[i], impulse = { x = 0, y = const, z = 0 } }
            table.insert(OtherWaves[math.ceil(dist / speed)], myT)
        end
        GG.ShockWaves = OtherWaves
    end



    local explosionFunc = {
        -- [exampleDefID] = function(weaponDefID, px, py, pz, AttackerID)

        -- end
        }

    function gadget:Explosion(weaponDefID, px, py, pz, AttackerID)

        if explosionFunc[weaponDefID] then explosionFunc[weaponDefID](weaponDefID, px, py, pz, AttackerID)
            return true
        end

    end

    --===========UnitDamaged Functions ====================================================
    --victim -- interrogator -- boolInerrogationOngoing
    InterrogationTable={}
    local civilianWalkingTypeTable = getCultureUnitModelTypes(GameConfig.instance.culture, "civilian", UnitDefs)

    interrogationEventStreamFunction = function(unitID, unitDefID, unitTeam, damage, paralyzer, weaponDefID, attackerID, attackerDefID, attackerTeam, iconUnitTypeName)
        Spring.Echo("caught 1")
        if not InterrogationTable[unitID] then InterrogationTable[unitID] ={} end
        if not InterrogationTable[unitID][attackerID] then InterrogationTable[unitID][attackerID] = false end

        if  InterrogationTable[unitID][attackerID] == false then
            Spring.Echo("caught 2")
            --Stun
            interrogationFunction = function( persPack)
                --check Unit existing
                if false == doesUnitExistAlive(persPack.unitID) then
                    InterrogationTable[persPack.unitID][persPack.interrogatorID] = false
                    Spring.Echo("caught 3 ")
                    if  true == doesUnitExistAlive(persPack.interrogatorID) then
                        setSpeedEnv(persPack.interrogatorID, 1.0)
                    end
                    if persPack.IconId then
                        GG.raidIconPercentage[persPack.IconId] = nil
                    end
                    return true, persPack
                end

				--check wether the interrogator is still there
                if false == doesUnitExistAlive(persPack.interrogatorID) then
                    InterrogationTable[persPack.unitID][persPack.interrogatorID] = false
                    Spring.Echo("caught 4")
                    if persPack.IconId then
                        GG.raidIconPercentage[persPack.IconId] = nil
                    end
                    return true, persPack
                end

                -- check distance is still okay
                if distanceUnitToUnit(persPack.interrogatorID, persPack.unitID) > GameConfig.InterrogationDistance then
                    InterrogationTable[persPack.unitID][persPack.interrogatorID] = false
                    Spring.Echo("caught 5 ")
                    setSpeedEnv(persPack.interrogatorID, 1.0)
                    if persPack.IconId then
                        GG.raidIconPercentage[persPack.IconId] = nil
                    end
                    return true, persPack
                end

				--check if the icon is still there
                if not persPack.IconId then
                    persPack.IconId = createUnitAtUnit(Spring.GetUnitTeam(persPack.interrogatorID), iconUnitTypeName , persPack.unitID, 0, 0, 0)
                    if not GG.raidIconPercentage then  GG.raidIconPercentage = {} end
                    if not GG.raidIconPercentage[persPack.IconId] then  GG.raidIconPercentage[persPack.IconId] = 0 end
                end
                --update the icons  ercentage
                GG.raidIconPercentage[persPack.IconId] = (Spring.GetGameFrame() - persPack.startFrame) / GameConfig.InterrogationTimeInFrames
                Spring.Echo("Raid running " .. (persPack.startFrame + GameConfig.InterrogationTimeInFrames )- Spring.GetGameFrame()   )

                if persPack.startFrame + GameConfig.InterrogationTimeInFrames < Spring.GetGameFrame() then
                    --succesfull interrogation
                    Spring.Echo("Raid was succesfull - childs of "..persPack.unitID .." are revealed")
                    children = getChildrenOfUnit(Spring.GetUnitTeam(persPack.unitID),persPack.unitID)
                    parent = getParentOfUnit(Spring.GetUnitTeam(persPack.unitID),persPack.unitID)
                    Spring.Echo(" caught 6 ")
                    for childID, v in pairs(children) do
                        if doesUnitExistAlive(childID) == true then
                            Spring.GiveOrderToUnit(childID, CMD.CLOAK, {},{})
                            GG.OperativesDiscovered[childID] = true
                            Spring.SetUnitAlwaysVisible(childID, true)
                        end
                    end


                    if doesUnitExistAlive(parent) == true then
                        Spring.GiveOrderToUnit(parent, CMD.CLOAK, {},{})
                        GG.OperativesDiscovered[parent] = true
                        Spring.SetUnitAlwaysVisible(parent, true)

                    end

                    Spring.DestroyUnit(persPack.unitID, false, true)
                    InterrogationTable[persPack.unitID][persPack.interrogatorID] = false
                    Spring.Echo("caught 7")
                    setSpeedEnv(persPack.interrogatorID, 1.0)
                    GG.raidIconPercentage[persPack.IconId] = nil
                    return true, persPack
                end


                return false, persPack
            end

            Spring.Echo("Starting Interrogation Event Stream")
            createStreamEvent(unitID, interrogationFunction, 31,  {interrogatorID = attackerID, unitID= unitID})
        end

        --on Complete Raid/Interrogation
        --Transfer Units into No Longer Cloakable table
        -- SetAlwaysVisible
        -- Set Uncloak

    end

    UnitDamageFuncT[stunpistoldWeaponDefID] = function(unitID, unitDefID, unitTeam, damage, paralyzer, weaponDefID, attackerID, attackerDefID, attackerTeam)
        Spring.Echo("Stunning unit".. unitID)
        if unitID ~= attackerID then
            stunUnit(unitID, 2.0)
        end



    end

	local houseTypeTable = getCultureUnitModelTypes(GameConfig.instance.culture, "house", UnitDefs)
    InterrogateAbleType = getInterrogateAbleTypeTable(UnitDefs)
	local stunContainerUnitTimePeriodInSeconds = 10.0
	local allTeams = Spring.GetTeamList()

    UnitDamageFuncT[raidWeaponDefID] = function(unitID, unitDefID, unitTeam, damage, paralyzer, weaponDefID, attackerID, attackerDefID, attackerTeam)
        Spring.Echo("Raid/Interrogatable Weapon fired upon"..UnitDefs[unitDefID].name)
		
	--stupidity edition
	if attackerID == unitID then return damage end
     
	 --make disguise civilians transparent
	 if civilianWalkingTypeTable[unitDefID] and  GG.DisguiseCivilianFor[unitID] then
		stunUnit(unitID, stunContainerUnitTimePeriodInSeconds)
		unitID= GG.DisguiseCivilianFor[unitID]
		unitDefID = Spring.GetUnitDefID(unitID)
		unitTeam = Spring.GetUnitTeam(unitID)
	 end
	 
	 --make houses transparent
	 if houseTypeTable[unitDefID] and GG.houseHasSafeHouseTable[unitID] then
		stunUnit(unitID, stunContainerUnitTimePeriodInSeconds)
		unitID = GG.houseHasSafeHouseTable[unitID]
		unitDefID = Spring.GetUnitDefID(unitID)
		unitTeam = Spring.GetUnitTeam(unitID)
	 end
	 
	--stupidity edition
	if attackerID == unitID then return damage end
     
	 
	 --Interrogation
	 if InterrogateAbleType[unitDefID]   then
        Spring.Echo("Interrogation/Raid of "..UnitDefs[unitDefID].name)
        stunUnit(GG.DisguiseCivilianFor[unitID], 2.0)
        setSpeedEnv(attackerID, 0.0)
        interrogationEventStreamFunction(unitID, unitDefID, unitTeam, damage, paralyzer, weaponDefID, attackerID, attackerDefID, attackerTeam, "interrogationIcon")       
		return damage
	 end
	 
	 -- Propandapunishment for Unjust Raids & Interrogations: Remember Guantanamo
	 assert(attackerTeam)
	 GG.Bank:TransferToTeam(-GameConfig.RaidInterrogationPropgandaPrice, attackerTeam, attackerID )
	 for i=1,#allTeams,1  do
		 if allTeams[i] ~= attackerTeam then
			GG.Bank:TransferToTeam(GameConfig.RaidInterrogationPropgandaPrice, allTeams[i], unitID )
		 end
	 end
		
	
		
    end

   
    function gadget:UnitDamaged(unitID, unitDefID, unitTeam, damage, paralyzer, weaponDefID, projectileID, attackerID, attackerDefID, attackerTeam)
        if UnitDamageFuncT[weaponDefID] then
            resultDamage = UnitDamageFuncT[weaponDefID](unitID, unitDefID, unitTeam, damage, paralyzer, weaponDefID,  attackerID, attackerDefID, attackerTeam)
            if resultDamage then return resultDamage end
        end
    end

    --===========Projectile Persistence Functions ====================================================
   local  NewUnitsInPanic={}
    function gadget:ProjectileCreated(proID, proOwnerID, projWeaponDefID)
		
		if panicWeapons[projWeaponDefID] then
			T=process(getAllNearUnit(proOwnerID, panicWeapons[projWeaponDefID].range),
			function(id)
				if Spring.GetUnitTeam(id) == GaiaTeamID and not GG.DisguiseCivilianFor[id] and civilianWalkingTypeTable[Spring.GetUnitDefID(id)] then
					if civilianWalkingTypeTable[Spring.GetUnitDefID(id)] and not GG.DisguiseCivilianFor[id] and not GG.AerosolAffectedCivilians[id] then
						NewUnitsInPanic[id]={
											proOwnerID= proOwnerID,
											flighttime = (panicWeapons[projWeaponDefID].damage*panicWeapons[projWeaponDefID].range)/30, 
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
				if not GG.FleeingCivilians then GG.FleeingCivilians ={} end
				if not persPack.startFrame then persPack.startFrame = Spring.GetGameFrame() end
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
				
			
				if not GG.FleeingCivilians[myID] then GG.FleeingCivilians[myID] = {flighttime = persPack.flighttime, startFrame = Spring.GetGameFrame()} end
				
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
								{--persistance Pack
									unitID = id ,
									attackerID =data.proOwnerID,
									flighttime =data.flighttime,
									updateIntervall = data.updateIntervall
								},
								Spring.GetGameFrame() + (id % 10)
								)
		
				end
			end
			NewUnitsInPanic ={}
		
		end
	end


    GROUND= string.byte('g')
    UNIT=   string.byte('u')
    FEATURE=   string.byte('f')
    PROJECTILE=   string.byte('p')

    projectileDestroyedFunctions = {
        -- [c4WeaponDefID] = function (projID, defID, teamID)

        -- x,y,z= getProjectileTargetXYZ(proID)

        -- Spring.CreateUnit("ground_station_ssied",x,y,z, 1, teamID)


        -- end


        }
    function gadget:ProjectileDestroyed(proID)
        defid= Spring.GetProjectileDefID(proID)
        if projectileDestroyedFunctions[defID] then
            return projectileDestroyedFunctions[defID] (proID, defID, Spring.GetProjectileTeamID (proID))
        end


    end




    function getProjectileTargetXYZ(proID)
        targetTypeInt, target = Spring.GetProjectileTarget(proID)

        if targetTypeInt == GROUND then
            echo("ProjectileTarget:",target[1], target[2], target[3])
            return target[1], target[2], target[3]
        end
        if targetTypeInt == UNIT then
            ux,uy,uz = Spring.GetUnitPosition(target)
            return ux,uy,uz
        end
        if targetTypeInt == FEATURE then
            fx,fy,fz = Spring.GetFeaturePosition(target)
            return fx, fy, fz
        end
        if targetTypeInt == PROJECTILE then
            px,py,pz = Spring.GetProjectilePosition(target)
            return px,py,pz
        end
    end


    function gadget:ShieldPreDamaged(proID, proOwnerID, shieldEmitterWeaponNum, shieldCarrierUnitID, bounceProjectile,startx, starty, startz, hitx, hity, hitz)

        return false
    end
end
