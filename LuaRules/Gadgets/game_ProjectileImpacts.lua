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

    local UnitDamageFuncT = {}
    local UnitDefNames = getUnitDefNames(UnitDefs)

    gameConfig = getGameConfig()
    --1 unitid
    --2 counter
    --3 orgBuildSpeed
    --local stunTime=9
    --local selectRange=300
    --local totalTime=9000

    raidWeaponDefID = WeaponDefNames["raidarrest"].id
    stunpistoldWeaponDefID = WeaponDefNames["stunpistol"].id
    --Centrail Weapons

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
    civilianDefID = UnitDefNames["civilian"].id

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

                if false == doesUnitExistAlive(persPack.interrogatorID) then
                    InterrogationTable[persPack.unitID][persPack.interrogatorID] = false
                    Spring.Echo("caught 4")
                    if persPack.IconId then
                        GG.raidIconPercentage[persPack.IconId] = nil
                    end
                    return true, persPack
                end

                -- check distance is still okay
                if distanceUnitToUnit(persPack.interrogatorID, persPack.unitID) > gameConfig.InterrogationDistance then
                    InterrogationTable[persPack.unitID][persPack.interrogatorID] = false
                    Spring.Echo("caught 5 ")
                    setSpeedEnv(persPack.interrogatorID, 1.0)
                    if persPack.IconId then
                        GG.raidIconPercentage[persPack.IconId] = nil
                    end
                    return true, persPack
                end

                if not persPack.IconId then
                    persPack.IconId = createUnitAtUnit(Spring.GetUnitTeam(persPack.interrogatorID), iconUnitTypeName , persPack.unitID, 0, 0, 0)
                    if not GG.raidIconPercentage then  GG.raidIconPercentage = {} end
                    if not GG.raidIconPercentage[persPack.IconId] then  GG.raidIconPercentage[persPack.IconId] = 0 end
                end
                --update the icons percentage
                GG.raidIconPercentage[persPack.IconId] = (Spring.GetGameFrame() - persPack.startFrame) / gameConfig.InterrogationTimeInFrames
                Spring.Echo("Raid running " .. (persPack.startFrame + gameConfig.InterrogationTimeInFrames )- Spring.GetGameFrame()   )

                if persPack.startFrame + gameConfig.InterrogationTimeInFrames < Spring.GetGameFrame() then
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

    houseDefID = UnitDefNames["house"].id
    InterrogateAbleType = getInterrogateAbleTypeTable(UnitDefs)
    raidTable= getRaidAbleTypeTable(UnitDefs)


    UnitDamageFuncT[raidWeaponDefID] = function(unitID, unitDefID, unitTeam, damage, paralyzer, weaponDefID, attackerID, attackerDefID, attackerTeam)
        Spring.Echo("Raid Weapon fired upon"..UnitDefs[unitDefID].name)
        if InterrogateAbleType[unitDefID] or  unitDefID == houseDefID  then
		 Spring.Echo("RInterrogateable Unit fired  ")
            if raidTable[unitDefID] or  unitDefID == houseDefID then
                Spring.Echo("Raid Weapon Fired")
                if unitDefID == houseDefID and GG.houseHasSafeHouseTable and GG.houseHasSafeHouseTable[unitID] then
                    Spring.Echo("Raid 1")
                    unitID = GG.houseHasSafeHouseTable[unitID]
                end

                if InterrogateAbleType[Spring.GetUnitDefID(unitID)] then
                    Spring.Echo("Raid 2")
                    stunUnit(unitID, 2.0)
                    setSpeedEnv(attackerID, 0.0)
                    interrogationEventStreamFunction(unitID, unitDefID, unitTeam, damage, paralyzer, weaponDefID, attackerID, attackerDefID, attackerTeam, "raidIcon")	
				end
				return damage	
            else
                Spring.Echo("Interrogation 1")
                if unitDefID == civilianDefID and GG.DisguiseCivilianFor[unitID] then
                    Spring.Echo("Interrogation 21")
                    stunUnit(GG.DisguiseCivilianFor[unitID], 2.0)
                    setSpeedEnv(attackerID, 0.0)
                    Spring.Echo("Interrogation 31")
                    interrogationEventStreamFunction(GG.DisguiseCivilianFor[unitID], unitDefID, unitTeam, damage, paralyzer, weaponDefID, attackerID, attackerDefID, attackerTeam, "interrogationIcon")
                else
                    Spring.Echo("Interrogation 22")
                    stunUnit(unitID, 2.0)
                    setSpeedEnv(attackerID, 0.0)
                    Spring.Echo("Interrogation 32")
                    interrogationEventStreamFunction(unitID, unitDefID, unitTeam, damage, paralyzer, weaponDefID, attackerID, attackerDefID, attackerTeam, "interrogationIcon")
                end
				return damage
            end
        end
    end





    GG.exploAmmoBlowTable ={}
    function addChainExplosion(unitID, damage, weaponDefID, cegName, NumberOfExplosions, delayMin, delayMax )

        if not GG.exploAmmoBlowTable[unitID] then
            GG.exploAmmoBlowTable[unitID] = {number=0,id= unitID}
        end

        GG.exploAmmoBlowTable[unitID].number = GG.exploAmmoBlowTable[unitID].number + NumberOfExplosions

        persPack = {startFrame = Spring.GetGameFrame()}
        for i=1,NumberOfExplosions do
            persPack[#persPack + 1] = math.random(delayMin, delayMax)
        end
        persPack.ListOfPieces= getPieceTable(unitID)

        --Start Chain Explosion EventStream
        eventFunction = function(id, frame, persPack)
            nextFrame = frame + 1
            if persPack then
                if persPack.unitID then
                    --check
                    boolDead = Spring.GetUnitIsDead(persPack.unitID)

                    if boolDead and boolDead == true then
                        return
                    end

                    if not persPack.startFrame then
                        persPack.startFrame = frame
                    end

                    if not persPack[1] then
                        return
                    end

                    if persPack.startFrame then
                        nextFrame = persPack.startFrame + persPack[1]
                        table.remove(persPack,1)
                    end
                    val= math.random(1,#persPack.ListOfPieces)
                    shakeUnitPieceRelative(persPack.unitID, persPack.ListOfPieces[val],math.random(-25,25),50 )
                    Spring.AddUnitDamage(persPack.unitID, 15)

                end
            end
            return nextFrame, persPack
        end

        GG.EventStream:CreateEvent(eventFunction, persPack, Spring.GetGameFrame() + 1)
    end

    function gadget:UnitDamaged(unitID, unitDefID, unitTeam, damage, paralyzer, weaponDefID, projectileID, attackerID, attackerDefID, attackerTeam)

        if UnitDamageFuncT[weaponDefID] then
            resultDamage = UnitDamageFuncT[weaponDefID](unitID, unitDefID, unitTeam, damage, paralyzer, weaponDefID,  attackerID, attackerDefID, attackerTeam)
            if resultDamage then return resultDamage end
        end

    end

    --===========Projectile Persistence Functions ====================================================


    function gadget:ProjectileCreated(proID, proOwnerID, projWeaponDefID)


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
