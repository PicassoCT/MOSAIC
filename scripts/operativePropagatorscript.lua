	Spring.Echo("script.Create-Operative")
include "lib_OS.lua"
include "lib_UnitScript.lua"
include "lib_Animation.lua"
include "lib_Build.lua"

TablesOfPiecesGroups = {}

function script.HitByWeapon(x, z, weaponDefID, damage)
end

center = piece "center"

function script.Create()
	Spring.Echo("script.Create-Operative")
    generatepiecesTableAndArrayCode(unitID)
    TablesOfPiecesGroups = getPieceTableByNameGroups(false, true)
end

function script.Killed(recentDamage, _)
	if doesUnitExistAlive(civilianID) == true then
		Spring.DestroyUnit(civilianID,true,true) 
	end
   return 1
end


--- -aimining & fire weapon
function script.AimFromWeapon1()
    return center
end



function script.QueryWeapon1()
    return center
end

function script.AimWeapon1(Heading, pitch)
    --aiming animation: instantly turn the gun towards the enemy

    return true
end


function script.FireWeapon1()

    return true
end



function script.StartMoving()
end

function script.StopMoving()
end
gaiaTeamID = Spring.GetGaiaTeamID()
local civilianID 

--EventStream Function
syncDecoyToAgent = function(evtID, frame, persPack, startFrame)
				--	only apply if Unit is still alive
				if Spring.GetUnitIsDead(persPack.unitID) == true then
					return nil, persPack
				end
				
				x,y,z = Spring.GetUnitPosition(persPack.unitID)
				
				if not persPack.currPos then
					persPack.currPos ={x=x,y=y,z=z}
					persPack.stuckCounter=0
				end
				
				if distance(x,y,z, persPack.currPos.x,persPack.currPos.y,persPack.currPos.z) < 100 then				
					persPack.stuckCounter=persPack.stuckCounter+1
				else
					persPack.currPos={x=x, y=y, z=z}
					persPack.stuckCounter=0
				end
						
				if persPack.stuckCounter > 5 then
					moveUnitToUnit(persPack.myID, persPack.syncedID, math.random(-10,10),0, math.random(-10,10))
					return nil, nil
				end

				transferOrders( persPack.syncedID, persPack.myID)
				
				return frame + 30 , persPack	
			end
		
		

function spawnDecoyCivilian()
--spawnDecoyCivilian
		x,y,z= Spring.GetUnitPosition(unitID)
		civilianID = Spring.CreateUnit("civilian" , x +randSign()*5, y, z +randSign()*5 , 1, gaiaTeamID)
		persPack = {myID= civilianID, syncedID= unitID }
		if civilianID then
			GG.EventStream:CreateEvent(
			syncDecoyToAgent,
			persPack,
			Spring.GetGameFrame()
			)
		end
-- setEvent

	return 0
end

if not GG.OperativesDiscovered then  GG.OperativesDiscovered={} end

function script.Activate()
	if not GG.OperativesDiscovered[unitID] then
        SetUnitValue(COB.WANT_CLOAK, 1)
		  Spring.GiveOrderToUnit(unitID, CMD.FIRE_STATE, {0}, {}) 
		  spawnDecoyCivilian()
		  return 1
   else
			return 0
	end
  
end

function script.Deactivate()
		SetUnitValue(COB.WANT_CLOAK, 0)
		Spring.GiveOrderToUnit(unitID, CMD.FIRE_STATE, {2}, {}) 
		if doesUnitExistAlive(civilianID) == true then
			Spring.DestroyUnit(civilianID,true,true)
		end
    return 0
end

function script.QueryBuildInfo()
    return center
end

Spring.SetUnitNanoPieces(unitID, { center })

