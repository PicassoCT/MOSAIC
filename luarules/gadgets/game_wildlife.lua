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


function gadget:GameFrame(frame)
end

function gadget:Initialize()
    -- if a map with animals
        -- get location of animal
            --spawn the animal
                -- ocassionally check wether still alive
end
