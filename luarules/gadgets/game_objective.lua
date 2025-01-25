function gadget:GetInfo()
    return {
        name = "Objectives",
        desc = "Spawns objectives - hands out rewards for protecting or destroying them",
        author = "Pircossa",
        date = "2.2.2009",
        license = "GPL2.1",
        layer = 50,
        enabled = true
    }
end

VFS.Include("scripts/lib_OS.lua")
VFS.Include("scripts/lib_UnitScript.lua")
VFS.Include("scripts/lib_Animation.lua")
--VFS.Include("scripts/lib_Build.lua")
VFS.Include("scripts/lib_mosaic.lua")

-- SYNCED
if (gadgetHandler:IsSyncedCode()) then
    local gaiaTeamID = Spring.GetGaiaTeamID()
    local objectiveTypes = getObjectiveTypes(UnitDefs)
    local deadObjectiveTypes = getDeadObjectiveType(UnitDefs)

    GG.Objectives = {}
    GG.DeadObjectives = {}
    local GameConfig = getGameConfig()

    boolInit = false
    function gadget:Initialize() 
        boolInit = true 
        echo("Using map controlled objective spawn: "..toString(useMapControlledObjectiveSpawn())) 
    end

    function useMapControlledObjectiveSpawn()
        return getManualObjectiveSpawnMapNames(Game.mapName)      
    end

    function defaultInit()
    mapCenter = {x = Game.mapSizeX / 2, z = Game.mapSizeZ / 2}

        oz = math.min(Game.mapSizeX, Game.mapSizeZ) - math.random(500, 1000)
        ox = Game.mapSizeX / 2
        rval = math.random(7, 20) * randSign()
        k = 1
        for i = 1, 2 do
            x, z = ox - mapCenter.x, oz - mapCenter.z
            if x then
                rx, rz = Rotate(x, z, math.rad(k * 180 + 90 + rval))
                k = k + 1
                rx, rz = rx + mapCenter.x, rz + mapCenter.z
                h = Spring.GetGroundHeight(rx, rz)
                if h then
                    filteredObjectives = {}
                    if h > 5 then
                        for id, medium in pairs(objectiveTypes) do
                            if medium == "land" then
                                filteredObjectives[id] = id
                            end
                        end

                    else
                        for id, medium in pairs(objectiveTypes) do
                            if medium == "water" then
                                filteredObjectives[id] = id
                            end
                        end
                    end
                    key, element = randDict(filteredObjectives)
                    id = Spring.CreateUnit(element, rx, h, rz, 1, gaiaTeamID)
                    if id then
                        Spring.SetUnitAlwaysVisible(id, true)
                    end
                end
            end
        end
        boolInit = false
    end

    function onBoolInit()
        if useMapControlledObjectiveSpawn() == true then
            detectMapControlledPlacementComplete()
            boolInit = (GG.MapCompletedBuildingPlacement and GG.MapCompletedBuildingPlacement == true)
        else
            defaultInit()
        end    
    end

    function getProProtagon(nr)
        return nr % 2 == 0
    end  

    function setProConDescription(id, boolProProtagon)
        toolTip = Spring.GetUnitTooltip ( id ) 
        if boolProProtagon == true then
            toolTip = toolTip.."<Objective> Antagon must destroy /Protagon must defend"
        else
            toolTip = toolTip.."<Objective> Protagon must destroy /Antagon must defend"
        end
        Spring.SetUnitTooltip(id, toolTip)
    end    

    function setDeadDescription(id, boolProProtagon)
        toolTip = Spring.GetUnitTooltip ( id ) 
        if boolProProtagon == true then
            toolTip = toolTip.."<Dead Objective> Antagon must attack to restore /Protagon must prevent"
        else
            toolTip = toolTip.."<Dead Objective> Protagon must attack to restore /Antagon must prevent"
        end
        Spring.SetUnitTooltip(id, toolTip)
    end

    function gadget:UnitCreated(UnitID, unitDefID)
        uDefID = Spring.GetUnitDefID(UnitID)
        if objectiveTypes[uDefID] and Spring.GetUnitTeam(UnitID) == gaiaTeamID  then
            x, y, z = Spring.GetUnitPosition(UnitID)
            GG.Objectives[UnitID] = {x = x, y = y, z = z, uid= UnitID, defID = uDefID, boolProProtagon = getProProtagon(count(Objectives)) }
            assert(GG.Objectives[UnitID].defID)
            setProConDescription(UnitID, GG.Objectives[UnitID].boolProProtagon)
            Spring.SetUnitAlwaysVisible(UnitID, true)
        end
    end

    function gadget:UnitDestroyed(UnitID)
        uDefID = Spring.GetUnitDefID(UnitID)
        uTeamID = Spring.GetUnitTeam(UnitID)

        if objectiveTypes[uDefID] and GG.Objectives[UnitID] and uTeamID == gaiaTeamID then
            iconID = Spring.CreateUnit ("destroyedobjectiveicon", GG.Objectives[UnitID].x,GG.Objectives[UnitID].y, GG.Objectives[UnitID].z,0, gaiaTeamID)
            GG.DeadObjectives[iconID] = {}
            GG.DeadObjectives[iconID].x =  GG.Objectives[UnitID].x
            GG.DeadObjectives[iconID].y =  GG.Objectives[UnitID].y
            GG.DeadObjectives[iconID].z =  GG.Objectives[UnitID].z
            GG.DeadObjectives[iconID].uid =  iconID
            GG.DeadObjectives[iconID].defID =  GG.Objectives[UnitID].defID
            assert(Objectives[UnitID].defID)
            assert(GG.DeadObjectives[iconID].defID)
            GG.DeadObjectives[iconID].boolProProtagon =  not GG.Objectives[UnitID].boolProProtagon

            setDeadDescription(iconID,   GG.DeadObjectives[iconID].boolProProtagon)
            GG.Objectives[UnitID] = nil
            return
        end

        if deadObjectiveTypes[uDefID] and uTeamID == gaiaTeamID and GG.DeadObjectives[UnitID]  then
            --recreate the objective
            GG.UnitsToSpawn:PushCreateUnit( GG.DeadObjectives[UnitID].defID, 
                                            GG.DeadObjectives[UnitID].x, 
                                            GG.DeadObjectives[UnitID].y, 
                                            GG.DeadObjectives[UnitID].z, 
                                            0, 
                                            gaiaTeamID)
            GG.DeadObjectives[UnitID] = nil
            return 
        end
    end

    colourRed = {r = 255, g = 0, b = 0}
    colourBlue = {r = 0, g = 0, b = 255}
    antagonT = getAllTeamsOfType("antagon", UnitDefs)
    protagonT = getAllTeamsOfType("protagon", UnitDefs)
    function gadget:GameFrame(f)
        if boolInit == true then onBoolInit(); return; end

        if f % GameConfig.Objectives.RewardCyle == 0 then

            local Objectives = GG.Objectives
            for id, types in pairs(Objectives) do
                if types then
                    if types.boolProProtagon == true then
                        --	Spring.Echo("Objectives to Protagon")
                        if doesUnitExistAlive(id) == true then
                            for tid, _ in pairs(protagonT) do
                                GG.Bank:TransferToTeam(GameConfig.Objectives.Reward,
                                                       tid, id, colourBlue)
                            end
                        end
                    else
                        if doesUnitExistAlive(id) == true then
                            for tid, _ in pairs(antagonT) do
                                GG.Bank:TransferToTeam(GameConfig.Objectives.Reward, tid,
                                                       id, colourBlue)
                            end
                        end
                    end
                end
            end
            local DeadObjectives = GG.DeadObjectives
            for id, types in pairs(DeadObjectives) do
                if types then
                    if types.boolProProtagon == true then
                        --  Spring.Echo("Objectives to Protagon")
                        if doesUnitExistAlive(id) == true then
                            for tid, _ in pairs(protagonT) do
                                GG.Bank:TransferToTeam(GameConfig.Objectives.Reward,
                                                       tid, id, colourBlue)
                            end
                        end
                    else
                        if doesUnitExistAlive(id) == true then
                            for tid, _ in pairs(antagonT) do
                                GG.Bank:TransferToTeam(GameConfig.Objectives.Reward, tid,
                                                       id, colourBlue)
                            end
                        end
                    end
                end
            end
        end
    end -- fn
end -- sync
