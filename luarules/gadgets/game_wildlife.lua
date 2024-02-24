function gadget:GetInfo()
    return {
        name = "Wildlife Behaviour Gadget",
        desc = "Coordinates wildlife ",
        author = "Picasso",
        date = "3rd of May 2010",
        license = "GPL3",
        layer = 2,
        version = 1,
        enabled = false
    }
end

if (not gadgetHandler:IsSyncedCode()) then return false end

VFS.Include("scripts/lib_UnitScript.lua")
VFS.Include("scripts/lib_mosaic.lua")
VFS.Include("scripts/lib_staticstring.lua")

local GameConfig = getGameConfig()
--if not Game.version then Game.version = GameConfig.instance.Version end
local spGetUnitPosition = Spring.GetUnitPosition
local spGetUnitDefID = Spring.GetUnitDefID
local spGetUnitTeam = Spring.GetUnitTeam
local spGetUnitHealth = Spring.GetUnitHealth
local spGetGameFrame = Spring.GetGameFrame
local spGetGroundHeight = Spring.GetGroundHeight
local spGetUnitNearestAlly = Spring.GetUnitNearestAlly

local spSetUnitAlwaysVisible = Spring.SetUnitAlwaysVisible
local spSetUnitNoSelect = Spring.SetUnitNoSelect
local spRequestPath = Spring.RequestPath
local spCreateUnit = Spring.CreateUnit
local spDestroyUnit = Spring.DestroyUnit
local animalTypes = getAnimalTypeTables(UnitDefs)
local animalMaxNumbers = getAnimalTypeNumbers(UnitDefs)
local gaiaTeamID = Spring.GetGaiaTeamID()

function checkRespawnAnimals()
    local allUnitsCounter = Spring.GetTeamUnitsCounts(gaiaTeamID)
    foreach( animalTypes,
            function(animalTypeDefID)
                -- we have more animals defined as max
                if allUnitsCounter[animalTypeDefID] and allUnitsCounter[animalTypeDefID] < animalMaxNumbers[animalTypeDefID]  then
                    --spawn near citycenter
                    if GG.innerCityCenter then
                        x,z =  GG.innerCityCenter.x +math.random(200, 1000)*randSign(),  GG.innerCityCenter.z + math.random(200, 1000)*randSign()
                        Spring.CreateUnit(animalTypeDefID, x, spGetGroundHeight(x,z), z, math.random(1,4), gaiaTeamID)      
                    end
                end
            end
            )
end

function gadget:GameFrame(frame)
    if frame > 0 and frame % 101 == 0 then
        checkRespawnAnimals()
    end
end

