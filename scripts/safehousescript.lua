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
nano = piece "nano"
local safeHouseID

function script.Create()
    TablesOfPiecesGroups = getPieceTableByNameGroups(false, true)
	StartThread(houseAttach)
	
end



CivilianTypeDefTable= getCivilianTypeTable(UnitDefs)
local houseDefID= CivilianTypeDefTable["house"]
GameConfig = getGameConfig()
gaiaTeamID = Spring.GetGaiaTeamID()

function houseAttach()
	Sleep(100)
	waitTillComplete(unitID)
	Spring.Echo("Safehouse completed")
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
					-- Spring.SetUnitNoSelect(unitID, true)	
					-- stunUnit(unitID,GameConfig.delayTillSafeHouseEstablished/1000)
					-- Sleep(GameConfig.delayTillSafeHouseEstablished)

					-- Spring.SetUnitNoSelect(unitID, false)
					StartThread(detectUpgrade)
				end
			end
			)
end

safeHouseUpgradeTable= getSafeHouseUpgradeTypeTable(UnitDefs, Spring.GetUnitDefID(unitID))

function detectUpgrade()
	while true do 
		Spring.Echo("Detect Upgrade")
		buildID = Spring.GetUnitIsBuilding(unitID)
		if buildID then
		Spring.Echo("buildID found Upgrade")
			buildDefID = Spring.GetUnitDefID(buildID)
			if safeHouseUpgradeTable[buildDefID] then
				waitTillComplete(buildID)
				
				GG.houseHasSafeHouseTable[safeHouseID] = buildID
				Spring.UnitAttach(safeHouseID, buildID, getUnitPieceByName(safeHouseID, GameConfig.safeHousePieceName))
				Spring.Echo("Upgrade Complete")
				Spring.DestroyUnit(unitID,false,true)
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

    SetUnitValue(COB.YARD_OPEN, 1)

    SetUnitValue(COB.BUGGER_OFF, 1)

    SetUnitValue(COB.INBUILDSTANCE, 1)
    return 1
end

function script.Deactivate()
    SetUnitValue(COB.YARD_OPEN, 0)

    SetUnitValue(COB.BUGGER_OFF, 0)

    SetUnitValue(COB.INBUILDSTANCE, 0)
    return 0
end

function script.QueryBuildInfo()
    return center
end

Spring.SetUnitNanoPieces(unitID, { nano })


function script.StartBuilding()

end


function script.StopBuilding()

end