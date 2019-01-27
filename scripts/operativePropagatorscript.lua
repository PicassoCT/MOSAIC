	Spring.Echo("script.Create-Operative")
include "lib_OS.lua"
include "lib_UnitScript.lua"
include "lib_Animation.lua"
include "lib_Build.lua"

TablesOfPiecesGroups = {}

function script.HitByWeapon(x, z, weaponDefID, damage)
end

center = piece "center"


if not GG.OperativesDiscovered then  GG.OperativesDiscovered={} end

function script.Create()

	GG.OperativesDiscovered[unitID] = nil

    -- generatepiecesTableAndArrayCode(unitID)
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

local civilianID 


function spawnDecoyCivilian()
--spawnDecoyCivilian
		Sleep(10)	

		x,y,z= Spring.GetUnitPosition(unitID)
		civilianID = Spring.CreateUnit("civilian" , x + 5 , y, z , 1, Spring.GetGaiaTeamID())
		transferUnitStatusToUnit(unitID,civilianID)
		Spring.SetUnitNoSelect(civilianID, true)
		Spring.SetUnitAlwaysVisible(civilianID, true)
	
--EventStream Function
syncDecoyToAgent = function(evtID, frame, persPack, startFrame)
				--	only apply if Unit is still alive
				if doesUnitExistAlive(persPack.myID) == false  then
					return nil, persPack
				end
				
				if doesUnitExistAlive(persPack.syncedID) == false  then
					return nil, persPack
				end
				
				--sync Health
				transferUnitStatusToUnit(persPack.myID, persPack.syncedID)
				
				x,y,z = Spring.GetUnitPosition(persPack.syncedID)
				mx,my,mz = Spring.GetUnitPosition(persPack.myID)
				if not x then 
					return nil, persPack 
				end
				
				if not persPack.oldSyncedPos then persPack.oldSyncedPos ={x=x,y=y,z=z} end
				-- Test Synced Unit Stopped
				
				if distance ( persPack.oldSyncedPos.x, persPack.oldSyncedPos.y,persPack.oldSyncedPos.z, x,y, z) < 5 then
					-- Unit has stopped, test wether we are near it
					if distance(mx,my,mz,x, y, z) < 25 then
						Command(persPack.myID, "stop")
						return frame + 30, persPack 
					end
				end
				--update old Pos
				persPack.oldSyncedPos ={x=x,y=y,z=z}
				
				
				if not persPack.currPos then
					persPack.currPos ={x=mx,y=my,z=mz}
					persPack.stuckCounter=0
				end
				
				if distance(mx,my,mz, persPack.currPos.x,persPack.currPos.y,persPack.currPos.z) < 50 then				
					persPack.stuckCounter=persPack.stuckCounter+1
				else
					persPack.currPos={x=mx, y=my, z=mz}
					persPack.stuckCounter=0
				end
						
				if persPack.stuckCounter > 5 then
					moveUnitToUnit(persPack.myID, persPack.syncedID, math.random(-10,10),0, math.random(-10,10))
				end

				transferOrders( persPack.syncedID, persPack.myID)
				
				return frame + 30 , persPack	
			end
			
			persPack = {myID= civilianID, syncedID= unitID, startFrame = Spring.GetGameFrame()+1 }
			
			
			if civilianID then
				GG.EventStream:CreateEvent(
				syncDecoyToAgent,
				persPack,
				Spring.GetGameFrame()+1
				)

			end

	return 0
end

function script.Activate()
	setSpeedEnv(unitID, 0.35)
	Spring.Echo("Activate "..unitID)
	if not GG.OperativesDiscovered[unitID] then
        SetUnitValue(COB.WANT_CLOAK, 1)
		  Spring.GiveOrderToUnit(unitID, CMD.FIRE_STATE, {0}, {}) 
		  StartThread(spawnDecoyCivilian)
		  return 1
   else
		Spring.Echo("Operative ".. unitID.." is discovered")
			return 0
   end
  
end

function script.Deactivate()
	setSpeedEnv(unitID, 1.0)
	Spring.Echo("Deactivate "..unitID)
		SetUnitValue(COB.WANT_CLOAK, 0)
		Spring.GiveOrderToUnit(unitID, CMD.FIRE_STATE, {2}, {}) 
		if civilianID and doesUnitExistAlive(civilianID) == true then
			Spring.DestroyUnit(civilianID, true, true)
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

