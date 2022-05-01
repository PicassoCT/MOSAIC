
function widget:GetInfo()
	return {
		name      = "SafeHouseSelect",
		desc      = "Select Safehouses in Units",
		author    = "very_bad_soldier",
		date      = "August 1, 2008",
		license   = "GNU GPL v2",
		layer     = -10,
		enabled   = true,
		hidden    = true
	}
end

local floor               = math.floor
local abs									= math.abs
local udefTab							= UnitDefs

local spEcho                = Spring.Echo
local spGetUnitPosition     = Spring.GetUnitPosition
local spGetUnitBasePosition = Spring.GetUnitBasePosition
local spGetMyPlayerID       = Spring.GetMyPlayerID
local spGetPlayerInfo       = Spring.GetPlayerInfo
local spGetLocalTeamID			= Spring.GetLocalTeamID
local spGetUnitDefDimensions = Spring.GetUnitDefDimensions
local spSelectUnitMap				= Spring.SelectUnitMap
local spGetTeamColor 				= Spring.GetTeamColor
local spGetGroundHeight 		= Spring.GetGroundHeight
local spIsSphereInView  		= Spring.IsSphereInView
local spGetSpectatingState	= Spring.GetSpectatingState
local spGetGameSeconds			= Spring.GetGameSeconds
local spIsGUIHidden					= Spring.IsGUIHidden

local spGetUnitsInRectangle =Spring.GetUnitsInRectangle 
local spGetUnitDefID = Spring.GetUnitDefID
local spTraceScreenRay = Spring.TraceScreenRay
local sizeOfHouse = 256/2
local myTeamID = Spring.GetMyTeamID()
local civilianHousesTypeTable = {}
local civilianHousesName = {
	["house_western0"]=true,
	["house_arab0"]=true
}
local secretPluginsTypeTable = {}
local secretPluginsName= {
	["antagonsafehouse"]=true,
  ["protagonsafehouse"]=true,
  ["propagandaserver"]=true,
  ["assembly"]=true,
  ["hivemind"]=true,
  ["launcher"]=true,
  ["launcherstep"]=true,
  ["warheadfactory"]=true,
  ["nimrod"]=true
}


for id, data in pairs(udefTab) do
	if civilianHousesName[data.name] then civilianHousesTypeTable[id] = true end
	if secretPluginsName[data.name] then secretPluginsTypeTable[id] = true end
end

local function handleLeftClickRelease(mx,my, button)
	local LeftClick = 1
    if button == LeftClick then
      local targType, targID = spTraceScreenRay(mx, my, false, inMinimap)
      if targType == 'unit' then
      		local defID = spGetUnitDefID(targID)
      		if civilianHousesTypeTable[defID] then
      			local x,y,z = spGetUnitPosition(targID)
      			local xmin, zmin, xmax,  zmax, = x -sizeOfHouse, z- sizeOfHouse, x +sizeOfHouse, z +sizeOfHouse
      			local unitsInRect = spGetUnitsInRectangle( xmin, zmin, xmax,  zmax, myTeamID)
      			if unitsInRect and #unitsInRect then
      				for i=1, #unitsInRect do
      					local subUnitDefID = spGetUnitDefID(unitsInRect[i])
      					if secretPluginsTypeTable[subUnitDefID] then
      						--add to Group
      					end
      				end
      			end
      		end       
      end       
    end       
end

function widget:MouseRelease(mx, my,  button)
		handleLeftClickRelease(mx, my,  button)
end
