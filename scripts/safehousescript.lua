include "lib_OS.lua"
include "lib_UnitScript.lua"
include "lib_Animation.lua"
include "lib_Build.lua"
include "lib_mosaic.lua"

TablesOfPiecesGroups = {}
boolSafeHouseActive= false

function script.HitByWeapon(x, z, weaponDefID, damage)
end

center = piece "center"
local safeHouseID

function script.Create()
    TablesOfPiecesGroups = getPieceTableByNameGroups(false, true)
	StartThread(houseAttach)
	StartThread(detectUpgrade)
end

CivilianTypeDefTable= getCivilianTypeTable(UnitDefs)
local houseDefID= CivilianTypeDefTable["house"]
GameConfig = getGameConfig()
gaiaTeamID = Spring.GetGaiaTeamID()

function houseAttach()
	waitTillComplete(unitID)
	process(
			getAllNearUnit(unitID, GameConfig.buildSafeHouseRange),
			function(id)
				if Spring.GetUnitDefID(id) == houseDefID and Spring.GetUnitTeam(id) == gaiaTeamID then
					return id
				end
			end,
			function(id)
				if not GG.houseHasSafeHouseTable then  GG.houseHasSafeHouseTable ={} end
				if not GG.houseHasSafeHouseTable[id] or doesUnitExistAlive(GG.houseHasSafeHouseTable[id] ) == false then 
					GG.houseHasSafeHouseTable[id] = unitID 
					safeHouseID= id
					
					Spring.UnitAttach(id, unitID, getUnitPieceByName(id, GameConfig.safeHousePieceName))
					Spring.Echo("SafehouseAttached")
					Spring.SetUnitNoSelect(unitID, true)	
					Sleep(GameConfig.delayTillSafeHouseEstablished)
					Spring.Echo("Safehouse Active")
					boolSafeHouseActive = true
					Spring.SetUnitNoSelect(unitID, false)
				end
			end
			)
end

safeHouseUpgradeTable= getSafeHouseUpgradeTypeTable(UnitDefs, Spring.GetUnitDefID(unitID))

function detectUpgrade()
	while true do 
		buildID = Spring.GetUnitIsBuilding(unitID)
		if buildID then
			buildDefID = Spring.GetUnitDefID(buildID)
			if safeHouseUpgradeTable[buildDefID] then
				waitTillComplete(buildID)
				id= transformUnitInto(unitID, buildDefID)
				GG.houseHasSafeHouseTable[safeHouseID] = id
				Spring.UnitAttach(safeHouseID, id, getUnitPieceByName(safeHouseID, GameConfig.safeHousePieceName))
				Spring.Echo("Upgrade Complete")
				Spring.DestroyUnit(buildID,true,true)
			end
		end
		Sleep(500)
	end
end

function script.Killed(recentDamage, _)
	Spring.Echo("Safehouse killed")
    return 1
end

function script.Activate()
    return 1
end

function script.Deactivate()

    return 0
end

function script.QueryBuildInfo()
    return center
end

Spring.SetUnitNanoPieces(unitID, { center })


function script.StartBuilding()

end