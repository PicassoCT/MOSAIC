function gadget:GetInfo()
    return {
        name = "Treason and Betrayal Gadget",
        desc = " who betrays whom, in the nth layer",
        author = "Picasso",
        date = "3rd of May 2010",
        license = "GPL3",
        layer = 1,
        version = 1,
        enabled = true
    }
end

if (gadgetHandler:IsSyncedCode()) then
    VFS.Include("scripts/lib_UnitScript.lua")
    VFS.Include("scripts/lib_mosaic.lua")

    local spGetUnitPosition = Spring.GetUnitPosition
    local spGetUnitDefID = Spring.GetUnitDefID
    local spGetUnitTeam = Spring.GetUnitTeam
    boolLocalDebugActive = false

    InterrogateableType =  getInterrogateAbleTypeTable(UnitDefs)
     operativeTypeTable = getOperativeTypeTable(UnitDefs)
     safeHouseTypeTable = getSafeHouseTypeTable(UnitDefs)
     houseTypeTable = getHouseTypeTable(UnitDefs)

    gaiaTeamID = Spring.GetGaiaTeamID()
    StartUnitsByTeam = {}
    function gadget:GameStart()    
         StartUnitsByTeam = {}
        allTeams = Spring.GetTeamList()
        for i=1, #allTeams do
            StartUnitsByTeam[allTeams[i]] = {}
        end
     assert(InterrogateableType[UnitDefNames["operativeinvestigator"].id])   
     assert(safeHouseTypeTable[UnitDefNames["antagonsafehouse"].id])   
	 if GameConfig.instance.culture == "arab" then
		assert(houseTypeTable[UnitDefNames["house_arab0"].id])  -- only valid if culture is active
	 end
	end


    function gadget:UnitCreated(unitid, unitdefid, unitTeam, father)
        if operativeTypeTable[unitdefid] and StartUnitsByTeam and #StartUnitsByTeam[unitTeam] == 0 then
            conditionalEcho(boolLocalDebugActive,"Registering Start Unit")
            registerParent(unitTeam, unitid)
            StartUnitsByTeam[unitTeam][1] = unitid
            return
        end

        if InterrogateableType[unitdefid] then
            --Spring.Echo("InterrogateableType created")
            if father and doesUnitExistAlive(father) then
                registerChild(unitTeam, father, unitid)
                conditionalEcho(boolLocalDebugActive,UnitDefs[unitdefid].name .. " created - child of "..father)
            else
                if operativeTypeTable[unitdefid] or safeHouseTypeTable[unitdefid] then
                    conditionalEcho(boolLocalDebugActive,"Registering random father")
                    -- registering random father
                    local father = nil
                    allUnitsSortedByDefID = Spring.GetTeamUnitsSorted(unitTeam)
 
                    if operativeTypeTable[unitdefid] then
                        for safehouseType, _ in pairs(safeHouseTypeTable) do
                            conditionalEcho(boolLocalDebugActive,"Iteratted operatives: "..UnitDefs[safehouseType].name)
                            local safeHousesOfTeam = allUnitsSortedByDefID[safehouseType]
                            if safeHousesOfTeam then
                               father =  getSafeRandom(safeHousesOfTeam)
                               assert(father)
                               break
                            end
                        end
                    else --assumed safehouse
                        for operatorType, _ in pairs(operativeTypeTable) do
                            local operatorsOfTeam = allUnitsSortedByDefID[operatorType]
                            if operatorsOfTeam then
                                conditionalEcho(boolLocalDebugActive, operatorsOfTeam)
                                father = getSafeRandom(operatorsOfTeam)
                                assert(father)
                               break
                            end
                        end
                    end
                  
                    if father then
                       conditionalEcho(boolLocalDebugActive,"Fatherless Unit "..unitid.." registered with random parent "..father)
                       registerChild(unitTeam, father, unitid)
                    end
                end
            end
        end
    end

    function getFairDropPointNear(unitDead, teamID)
        AllUnits =Spring.GetAllUnits()
        AllOperatives= {}
        AllHouses= {}

        foreach(AllUnits,
                    function(id)
                                defID = spGetUnitDefID(id)
                                if operativeTypeTable[defID] then
                                    AllOperatives[id] = id
                                end
                                if houseTypeTable[defID] then
                                     AllHouses[id] = id
                                end
                            end
                            )
               
       randHouse = randDict(AllHouses)

       maxdistance = 0
       hx,hy,hz = Spring.GetUnitPosition(randHouse)
       midpos= {x = hx, y = hy, z = hz}

       for id in pairs(AllOperatives) do
            for ad in pairs(AllOperatives) do
                if id ~= ad and spGetUnitTeam(id) ~= spGetUnitTeam(ad) then
                    if distanceUnitToUnit(id,ad) > maxdistance then
                        a = {}
                        b = {}
                        maxdistance =  distanceUnitToUnit(id,ad) 
                        a.x,a.y,a.z = spGetUnitPosition(id)
                        b.x,b.y,b.z = spGetUnitPosition(ad)
                        if a.x and b.x then
                        midpos.x, midpos.y, midpos.z = getMidPoint(a, b)
                        end
                    end
                end
            end
       end

       if maxdistance == 0 then
         x,y,z = Game.mapSizeX*(math.random(100,900)/1000), 0, Game.mapSizeZ*(math.random(100,900)/1000)
         return x,y,z
       end

        return midpos.x, midpos.y, midpos.z 
    end

    function gadget:UnitDestroyed(unitID, unitDefID, teamID, attackerID)
        if InterrogateableType[unitDefID]  then
            if attackerID and spGetUnitTeam(attackerID) == teamID then 
                x,y,z = getFairDropPointNear(unitID)
                copyID = Spring.CreateUnit("deaddropicon", teamID, x,y,z, 1 )
                transferHierarchy(teamID, originalID, copyID)
            else
                removeUnit(teamID, unitID) 
            end
        end         
    end

    function gadget:Initialize()
        --Spring.Echo(GetInfo().name .. " Initialization started ")
        if not GG.OperativesDiscovered then 
            GG.OperativesDiscovered = {} 
        end
        initalizeInheritanceManagement()
        --Spring.Echo(GetInfo().name .. " Initialization ended")
    end
end
