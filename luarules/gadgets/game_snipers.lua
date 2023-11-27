function gadget:GetInfo()
    return {
        name = "Sniper Gadget",
        desc = "Handles Sniper behaviour",
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

local UnitDefNames = getUnitDefNames(UnitDefs)

local sniperIconDefID = UnitDefNames["sniperrifleicon"].id
local sniperIcons = {}

function getParent(childID)

end

function SetUnitPosition(operativeID)
		x,y, z = Spring.GetUnitPosition(operativeID)
		y= y + gameConfig.houseSizeY
		Spring.MoveCtrl.Enable(operativeID)
		Spring.MoveCtrl.SetPosition(operativeID, x, y, z)
end

function gadget:UnitFinished(unitID, unitDefID)
	if unitDefID == sniperIconDefID then
		parentID =  getParent(unitID)
		sniperIcons[unitID] = parentID
		setSpeedEnv(parentID, 0.0)
	end
end

function hasMoveCommand(operativeID)
	return false
end

function handleCloseCombatHouseInterrogated(operativeID)
--TODO
end

function gadget:GameFrame(frame)
	if count(sniperIcons) > 0 then
		for iconID, operativeID in pairs(sniper do
			if existsAlive(iconID) and existsAlive(operativeID) then
				if hasMoveCommand(operativeID) or handleCloseCombatHouseInterrogated then --TODO otherDisruptions then
					--destroy Icon
					Spring.DestroyUnit(iconID,false, true)
					--resume ordinary unit physics
					Spring.MoveCtrl.Disable(operativeID)
					sniperIcons[iconID] = nil
				end
			end
		--move Operator up, allow it to walk on the roof, expand view, activate rifle
		-- check Move Commands, on Move Command, destroy Icon, remove Unit
		
	end    
end


