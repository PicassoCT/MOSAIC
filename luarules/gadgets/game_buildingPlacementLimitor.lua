function gadget:GetInfo()
    return {
        name = "Safehouse Building Limitator",
        desc = "",
        author = "",
        date = "3rd of May 2010",
        license = "Free",
        layer = 0,
        version = 1,
        enabled = true
    }
end

if (not gadgetHandler:IsSyncedCode()) then return end
VFS.Include("scripts/lib_UnitScript.lua")
VFS.Include("scripts/lib_mosaic.lua")

safeHouseTypeTable = getSafeHouseTypeTable(UnitDefs)
areaDenyMapResolution = 16
SAFEHOUSEBUILDING = 9
areaDenyMap = {}
GameConfig = getGameConfig()
local houseTypeTable = getCultureUnitModelNames_Dict_DefIDName(GameConfig.instance.culture,
                                                "house", UnitDefs)

local xMax = Game.mapSizeX / areaDenyMapResolution
local zMax = Game.mapSizeZ / areaDenyMapResolution

function setAroundPoint(x, z, valueToSet, halfSize)
    for rx = math.max(1, x - (halfSize)), math.min(xMax - 1, x + halfSize) do
        for rz = math.max(1, z - (halfSize)), math.min(zMax - 1, z + halfSize) do
            Spring.SetSquareBuildingMask(rx, rz, valueToSet)
        end
    end
end

function gadget:Initialize()
    mapSizeX, mapSizeZ = Game.mapSizeX / areaDenyMapResolution,
                         Game.mapSizeZ / areaDenyMapResolution
    areaDenyMap = makeTable(0, mapSizeX, mapSizeZ)
    -- Spring.Echo("Mapsize:"..mapSizeX.."/"..mapSizeZ)
    for x = 1, mapSizeX do
        for z = 1, mapSizeZ do
            if x > 0 and z > 0 and x < Game.mapSizeX / areaDenyMapResolution and
                z < Game.mapSizeZ / areaDenyMapResolution then
                Spring.SetSquareBuildingMask(x, z, 1)
            end
        end
    end
end

function gadget:UnitDestroyed(unitID, unitDefID, teamID, attackerID)
    if houseTypeTable[unitDefID] then
        x, y, z = Spring.GetUnitPosition(unitID)
        if x then setAroundPoint(x * 0.0625, z * 0.0625, 1, 4) end
    end
end

function gadget:UnitCreated(unitID, unitDefID)
    if houseTypeTable[unitDefID] then
        x, y, z = Spring.GetUnitPosition(unitID)

        if x then
            setAroundPoint(x * 0.0625, z * 0.0625, SAFEHOUSEBUILDING, 4)
        end
    end
end

