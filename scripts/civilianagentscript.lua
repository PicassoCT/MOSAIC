
include "lib_OS.lua"
include "lib_UnitScript.lua"
include "lib_Animation.lua"
include "lib_Build.lua"
include "lib_mosaic.lua"

TablesOfPiecesGroups = {}

function script.HitByWeapon(x, z, weaponDefID, damage)
end

center = piece "center"
boolStarted= false

function script.Create()
    TablesOfPiecesGroups = getPieceTableByNameGroups(false, true)

end

	function delayedStart()

	spawnDecoyCivilian()
	end

function script.Killed(recentDamage, _)
	if doesUnitExistAlive(civilianID) == true then
		Spring.DestroyUnit(civilianID,true,true) 
	end
   return 1
end



function script.StartMoving()
end

function script.StopMoving()
end
gaiaTeamID = Spring.GetGaiaTeamID()
local civilianID 

		

function spawnDecoyCivilian()
--spawnDecoyCivilian
		Sleep(10)
		x,y,z= Spring.GetUnitPosition(unitID)

		civilianID = Spring.CreateUnit("civilian" , x +  randSign()*5 , y, z +  randSign()*5, 1, Spring.GetGaiaTeamID())
		transferUnitStatusToUnit(unitID,civilianID)
		Spring.SetUnitNoSelect(civilianID, true)
		Spring.SetUnitAlwaysVisible(civilianID, true)
		

			
			persPack = {myID= civilianID, syncedID= unitID, startFrame = Spring.GetGameFrame()+1 }
			
			GG.DisguiseCivilianFor[civilianID]= unitID
			
			if civilianID then
				GG.EventStream:CreateEvent(
				syncDecoyToAgent,
				persPack,
				Spring.GetGameFrame()
				)
			end


	return 0
end

if not GG.OperativesDiscovered then  GG.OperativesDiscovered={} end

function script.Activate()
	if not GG.OperativesDiscovered[unitID] then
        SetUnitValue(COB.WANT_CLOAK, 1)
		  Spring.GiveOrderToUnit(unitID, CMD.FIRE_STATE, {0}, {}) 
		  StartThread(spawnDecoyCivilian)
		  return 1
   else
			return 0
   end
  
end

function script.Deactivate()
		SetUnitValue(COB.WANT_CLOAK, 0)
		Spring.GiveOrderToUnit(unitID, CMD.FIRE_STATE, {2}, {}) 
		if civilianID and doesUnitExistAlive(civilianID) == true then
			Spring.DestroyUnit(civilianID,true,true)
		end
    return 0
end



function script.QueryBuildInfo()
    return center
end


function script.StopBuilding()

	SetUnitValue(COB.INBUILDSTANCE, 0)
end


function script.StartBuilding(heading, pitch)
	SetUnitValue(COB.INBUILDSTANCE, 1)
end



Spring.SetUnitNanoPieces(unitID, { center })

