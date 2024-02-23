function gadget:GetInfo()
    return {
        name = "Wildlife Behaviour Gadget",
        desc = "Coordinates wildlife ",
        author = "Picasso",
        date = "3rd of May 2010",
        license = "GPL3",
        layer = 1,
        version = 1,
        enabled = true
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
local animalMaxNumbers = getAnim
function gadget:GameFrame(frame)
    if frame > 0 and frame % 101 == 0 then
        checkRespawnAnimals()
    end
end

function checkRespawnAnimals()
 allUnitsCounter = --TODO GetAllUnitsCounted
    foreach(animalTypes,
            function(animalTypeDefID)
                -- we have more animals defined as max
                if getAnimalTypeNumbers(animalTypeDefID) > allUnitsCounter[animalTypeDefID] then
                    --spawn near citycenter
                    if GG.innerCityCenter  then
                        x,z = math.random(200, 1000)*randSign(), math.random(200, 1000)*randSign()
                        Spring.CreateUnit(animalTypeDefID, GG.innerCityCenter.x + x, GG.innerCityCenter.y, GG.innerCityCenter.z+z, 0, Spring.GetGaiaTeamID())      
                    end
                end
            end
            )
end

