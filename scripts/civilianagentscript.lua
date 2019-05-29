
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
	StartThread(cloakLoop)
end



function script.Killed(recentDamage, _)
	if doesUnitExistAlive(civilianID) == true then
		Spring.DestroyUnit(civilianID,true,true) 
	end
   return 1
end


local spGetUnitTeam = Spring.GetUnitTeam
local myTeamID = spGetUnitTeam(unitID)
local gaiaTeamID = Spring.GetGaiaTeamID()
local spGetUnitWeaponTarget = Spring.GetUnitWeaponTarget 
local loc_doesUnitExistAlive = doesUnitExistAlive

function allowTarget(weaponNumber)
	isGround, isUserTarget, targetID = spGetUnitWeaponTarget(unitID, weaponNumber)
	if isGround and isGround == 1  then
	
		if spGetUnitTeam(targetID) == gaiaTeamID then

			if GG.DisguiseCivilianFor[targetID] and spGetUnitTeam(GG.DisguiseCivilianFor[targetID]) == myTeamID then
		
			return false
			end
		end
	end
return true
end

SIG_PISTOL =1

function pistolAimFunction(weaponID, heading, pitch)
return  allowTarget(weaponID)
end


WeaponsTable = {}
function makeWeaponsTable()
    WeaponsTable[1] = { aimpiece = gun, emitpiece = gun, aimfunc = pistolAimFunction, firefunc = pistolFireFunction, signal = SIG_PISTOL }
end

function script.AimFromWeapon(weaponID)
    if WeaponsTable[weaponID] then
        return WeaponsTable[weaponID].aimpiece
    else
        return center
    end
end

function script.QueryWeapon(weaponID)
    if WeaponsTable[weaponID] then
        return WeaponsTable[weaponID].emitpiece
    else
        return center
    end
end

function script.AimWeapon(weaponID, heading, pitch)
    if WeaponsTable[weaponID] then
        if WeaponsTable[weaponID].aimfunc then
            return WeaponsTable[weaponID].aimfunc(weaponID, heading, pitch)
        else
            WTurn(WeaponsTable[weaponID].aimpiece, y_axis, heading, turretSpeed)
            WTurn(WeaponsTable[weaponID].aimpiece, x_axis, -pitch, turretSpeed)
            return true
        end
    end
    return false
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
				Spring.GetGameFrame() + 1
				)
			end


	return 0
end
boolStartDecloaking= false
boolStartCloaking= true

function cloakLoop()
	waitTillComplete(unitID)
	while true do 
	Sleep(100)
		if boolStartCloaking== true and not  GG.OperativesDiscovered[unitID]  then
			boolStartCloaking = false
			SetUnitValue(COB.WANT_CLOAK, 1)
			Spring.GiveOrderToUnit(unitID, CMD.FIRE_STATE, {0}, {}) 
			StartThread(spawnDecoyCivilian)

		end

		if boolStartDecloaking == true then
				boolStartDecloaking = false
				SetUnitValue(COB.WANT_CLOAK, 0)
				Spring.GiveOrderToUnit(unitID, CMD.FIRE_STATE, {2}, {}) 
				if civilianID and doesUnitExistAlive(civilianID) == true then
					Spring.DestroyUnit(civilianID,true,true)
				end


		end

	end
end


function script.Activate()
	boolStartCloaking = true
	return 1 
end

function script.Deactivate()
	boolStartDecloaking = true
    return 0
end

