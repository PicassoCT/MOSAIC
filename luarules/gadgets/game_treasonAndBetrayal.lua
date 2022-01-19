function gadget:GetInfo()
    return {
        name = "Treason and Betrayal Gadget",
        desc = " who betrays whom, in the nth layer",
        author = "Picasso",
        date = "3rd of May 2010",
        license = "GPL3",
        layer = 3,
        version = 1,
        enabled = true
    }
end

if (gadgetHandler:IsSyncedCode()) then
    VFS.Include("scripts/lib_OS.lua")
    VFS.Include("scripts/lib_UnitScript.lua")
    VFS.Include("scripts/lib_Animation.lua")
    VFS.Include("scripts/lib_Build.lua")
    VFS.Include("scripts/lib_mosaic.lua")

    local spGetPosition = Spring.GetUnitPosition
    local spGetUnitDefID = Spring.GetUnitDefID
    local spGetUnitTeam = Spring.GetUnitTeam

    UnitDefNames = getUnitDefNames(UnitDefs)
    GameConfig = getGameConfig()

    MobileCivilianDefIds = getMobileCivilianDefIDTypeTable(UnitDefs)
    InterrogateableType = getInterrogateAbleTypeTable(UnitDefs)
    operativeTypeTable = getOperativeTypeTable(UnitDefs)
    reruitmentDefID = UnitDefNames["recruitcivilian"].id

    gaiaTeamID = Spring.GetGaiaTeamID()

    function gadget:UnitCreated(unitid, unitdefid, unitTeam, father)

        if InterrogateableType[unitdefid] then
            -- Spring.Echo("UnitCreated of InterrogateableType")
            if father and doesUnitExistAlive(father) then
                registerChild(unitTeam, father, unitid)
                if operativeTypeTable[unitdefid] then
                 --   Spring.Echo("operativeType Unit created - child of "..father)
                end
            else
                registerFather(unitTeam, unitid)
                if operativeTypeTable[unitdefid] then
                  --  Spring.Echo("Interrogatable Unit created - fatherless")
                end
            end

        end
    end

    function getFairDropPointNear(unitDead, teamID)
       AllOperatives  =  process(Spring.GetAllUnits(),
                        function(id)
                                    if operativeTypeTable[spGetUnitDefID(id)] then
                                        return id
                                    end
                                end
                                )
       maxdistance = 0
       midpos= {x = 0, y = 0, z = 0}

       for id in pairs(AllOperatives) do
            for ad in pairs(AllOperatives) do
                if id ~= ad and spGetUnitTeam(id) ~= spGetUnitTeam(ad) then
                    if distanceUnitToUnit(id,ad) > maxdistance then
                        maxdistance =  distanceUnitToUnit(id,ad) 
                        a.x,a.y,a.z = spGetUnitPosition(id)
                        b.x,b.y,b.z = spGetUnitPosition(ad)
                        midpos.x, midpos.y, midpos.z = getMidPoint(a, b)
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
            if attackerID and spGetUnitTeam(attackerID) ~= teamID then 
                x,y,z = getFairDropPointNear(unitID)
                copyID = Spring.CreateUnit("deaddropicon", teamID, x,y,z, 1 )
                transferHierarchy(teamID, originalID, copyID)
            else
                removeUnit(teamID, unitID) 
            end
        end         
    end

    function gadget:Initialize()
        Spring.Echo(GetInfo().name .. " Initialization ended")
        if not GG.OperativesDiscovered then 
            GG.OperativesDiscovered = {} 
        end
        initalizeInheritanceManagement()
        Spring.Echo(GetInfo().name .. " Initialization started")
    end
end
