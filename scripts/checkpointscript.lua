include "createCorpse.lua"
include "lib_UnitScript.lua"
include "lib_mosaic.lua"
--Changes within this file are not displayed
TablesOfPiecesGroups = {}
function script.HitByWeapon(x, z, weaponDefID, damage)
end

-- center = piece "center"
-- left = piece "left"
-- right = piece "right"
-- aimpiece = piece "aimpiece"
SIG_LIGHT = 1
local myTeamID = Spring.GetUnitTeam(unitID)

function hideShowLamps(stage)
	Signal(SIG_LIGHT)
	SetSignalMask(SIG_LIGHT)

	hideT(TablesOfPiecesGroups["Lamp"])
	if stage == "off" then
		Show(TablesOfPiecesGroups["Lamp"][1])	
		Show(TablesOfPiecesGroups["Lamp"][6])	
	elseif stage == "good" then
		Show(TablesOfPiecesGroups["Lamp"][2])	
		Show(TablesOfPiecesGroups["Lamp"][4])	
	elseif stage == "bad" then
		Show(TablesOfPiecesGroups["Lamp"][5])	
		Show(TablesOfPiecesGroups["Lamp"][3])	
	end

	Sleep(3000)
	hideT(TablesOfPiecesGroups["Lamp"])
	Show(TablesOfPiecesGroups["Lamp"][1])	
	Show(TablesOfPiecesGroups["Lamp"][6])	
end

function script.Create()
	Spring.SetUnitBlocking(unitID, false)
    TablesOfPiecesGroups = getPieceTableByNameGroups(false, true)
    StartThread(hideShowLamps,"off")
    StartThread(revelioThread)
end

boolActive = true
function revelioThread()
	Sleep(100)
	waitTillComplete(unitID)

	local spGetUnitTeam = Spring.GetUnitTeam
	local spGetUnitDefID = Spring.GetUnitDefID
	local cachedNonInterest={}
	local gameConfig = getGameConfig()
	local civilianTypeTable = getCivilianTypeTable(UnitDefs)

	local gaiaTeamID = Spring.GetGaiaTeamID()
	local houseTypeTable = getHouseTypeTable(UnitDefs, getCultureName())

	local spGetGameFrame = Spring.GetGameFrame
	if not GG.DisguiseCivilianFor then GG.DisguiseCivilianFor = {} end

	while true do
			if boolActive == true then
			foreach(
				 getAllNearUnit(unitID, gameConfig.checkPointRevealRange),
				 function(id)
				 	if id == unitID then return end

				 	if not cachedNonInterest[id] or cachedNonInterest[id] + 30*30 < Spring.GetGameFrame() then 
				 		return id 
				 	end
				 end,
				 function(id) 	
				 	if spGetUnitTeam(id) == myTeamID then
				 		cachedNonInterest[id] = spGetGameFrame()
				 		return
				 	end
				 	return id
				 end,
				 function(id)
				 	if not GG.DisguiseCivilianFor then GG.DisguiseCivilianFor = {} end
					 if GG.DisguiseCivilianFor[id] and spGetUnitTeam(GG.DisguiseCivilianFor[id]) == myTeamID then
					 	return
					 end
					return id
				 end,
				 function(id)
				 	defID = spGetUnitDefID(id)
				 	if  not hasFunding(myTeamId, gameConfig.checkPointPropagandaCost, "m") then return end

				 	if houseTypeTable[defID] then return end
				 
				 	if defID and civilianTypeTable[defID] then
				 		--if DisguiseCivilianFor	
				 		if GG.DisguiseCivilianFor[id]  then -- Disguised Unit 
   							StartThread(hideShowLamps,"bad")
				 			disguisedUnitID = GG.DisguiseCivilianFor[id] --make transparent
 							if not GG.OperativesDiscovered then  GG.OperativesDiscovered = {} end
 							GG.OperativesDiscovered[disguisedUnitID] = true
 							cachedNonInterest[id] = spGetGameFrame()
				 		else --pay a annoyanceFine
				 				StartThread(hideShowLamps,"good")
				 			sparedTeams = {[gaiaTeamID] = true }
							transferFromTeamToAllTeamsExceptAtUnit(id, 
								 myTeamID,
								 gameConfig.checkPointPropagandaCost, 
								sparedTeams
								 )
							cachedNonInterest[id] = spGetGameFrame()
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
	boolActive = true
    return 1
end

function script.Deactivate()
	boolActive = false
    return 0
end
