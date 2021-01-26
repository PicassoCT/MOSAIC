include "createCorpse.lua"
include "lib_OS.lua"
include "lib_UnitScript.lua"
include "lib_Animation.lua"
include "lib_Build.lua"

TablesOfPiecesGroups = {}

function script.HitByWeapon(x, z, weaponDefID, damage)
end

-- center = piece "center"
-- left = piece "left"
-- right = piece "right"
-- aimpiece = piece "aimpiece"
SIG_LIGHT = 1
if not aimpiece then echo("Unit of type "..UnitDefs[Spring.GetUnitDefID(unitID)].name .. " has no aimpiece") end
if not center then echo("Unit of type"..UnitDefs[Spring.GetUnitDefID(unitID)].name .. " has no center") end

function hideShowLamps(stage)
	Signal(SIG_LIGHT)
	SetSignalMask(SIG_LIGHT)

	hideT(TablesOfPiecesGroups["Lamp"])
	if stage == "off" then
		Show(TablesOfPiecesGroups["Lamp"][1])	
		Show(TablesOfPiecesGroups["Lamp"][4])	
	elseif stage = "good" then
		Show(TablesOfPiecesGroups["Lamp"][2])	
		Show(TablesOfPiecesGroups["Lamp"][5])	
	elseif stage == "bad" then
		Show(TablesOfPiecesGroups["Lamp"][3])	
		Show(TablesOfPiecesGroups["Lamp"][6])	
	end
	Sleep(3000)
	hideT(TablesOfPiecesGroups["Lamp"])
	Show(TablesOfPiecesGroups["Lamp"][1])	
	Show(TablesOfPiecesGroups["Lamp"][4])	
end

function script.Create()
    TablesOfPiecesGroups = getPieceTableByNameGroups(false, true)
    StartThread(revelioThread)
end

boolActive = true
function revelioThread()
 StartThread(hideShowLamps,"off")
local cachedNonInterest={}
gaiaTeamID = Spring.GetGaiaTeamID()
if not GGG.DisguiseCivilianFor then GG.DisguiseCivilianFor = {} end

	while true do
			if boolActive == true then
			process(
				 getAllNearUnit(unitID, gameConfig.checkPointRevealRange),
				 function(id)
				 	if not cachedNonInterest[id] then return id end
				 end,
				 function(id)
				 	if spGetUnitTeam(id) ~= myTeamID then
				 		return id
				 	else
						cachedNonInterest[id] = true
				 	end
				 end,
				 function(id)
				 	defID = spGetUnitDefID(id)
				 	if defID and civilianTypeTable[defID] then
				 		--if DisguiseCivilianFor	
				 		if GG.DisguiseCivilianFor[id] then -- Disguised Unit
				 			disguisedUnitID = GG.DisguiseCivilianFor[id] --make transparent
 							if not GG.OperativesDiscovered then  GG.OperativesDiscovered = {} end
 							 GG.OperativesDiscovered[disguisedUnitID] = true
 							 StartThread(hideShowLamps,"good")
				 		else --pay a annoyanceFine
							transferFromTeamToAllTeamsExceptAtUnit(id, 
								 myTeamID,
								 gameConfig.checkPointPropagandaCost, 
								 {
								 	[gaiaTeamID] = true
								 }
								 )
							 StartThread(hideShowLamps,"bad")
				 		end
				 	end
				 end

				)
			end
		Sleep(250)
	end
end

function script.Killed(recentDamage, _)
    return 1
end


function script.Activate()
    return 1
end

function script.Deactivate()
    return 0
end
