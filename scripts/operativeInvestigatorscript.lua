
include "lib_OS.lua"
include "lib_UnitScript.lua"
include "lib_Animation.lua"
include "lib_Build.lua"
include "lib_mosaic.lua"

TablesOfPiecesGroups = {}

function script.HitByWeapon(x, z, weaponDefID, damage)
end

center = piece "center"
gun = piece "gun"


if not GG.OperativesDiscovered then  GG.OperativesDiscovered={} end

function script.Create()
	makeWeaponsTable()
	GG.OperativesDiscovered[unitID] = nil

    -- generatepiecesTableAndArrayCode(unitID)
    TablesOfPiecesGroups = getPieceTableByNameGroups(false, true)
	StartThread(cloakLoop)
	StartThread(raidReactor)
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

local civilianID 


function spawnDecoyCivilian()
--spawnDecoyCivilian
		Sleep(10)	

		x,y,z= Spring.GetUnitPosition(unitID)
		civilianID = Spring.CreateUnit("civilian" , x + randSign()*5 , y, z+ randSign()*5 , 1, Spring.GetGaiaTeamID())
		transferUnitStatusToUnit(unitID,civilianID)
		Spring.SetUnitNoSelect(civilianID, true)
		Spring.SetUnitAlwaysVisible(civilianID, true)

			persPack = {myID= civilianID, syncedID= unitID, startFrame = Spring.GetGameFrame()+1 }
			GG.DisguiseCivilianFor[civilianID]= unitID
			
			if civilianID then
				GG.EventStream:CreateEvent(
				syncDecoyToAgent,
				persPack,
				Spring.GetGameFrame()+1
				)

			end

	return 0
end


boolStartDecloaking= false
boolStartCloaking= true

function cloakLoop()
	Sleep(100)
	waitTillComplete(unitID)
	Sleep(100)
	while true do 

		if boolStartCloaking== true and not  GG.OperativesDiscovered[unitID]  then
			boolStartCloaking = false
			setSpeedEnv(unitID, 0.35)
			Spring.Echo("Hide "..UnitDefs[Spring.GetUnitDefID(unitID)].name)			
			SetUnitValue(COB.WANT_CLOAK, 1)
			Spring.GiveOrderToUnit(unitID, CMD.FIRE_STATE, {0}, {}) 
			boolCloaked=true
			StartThread(spawnDecoyCivilian)
		end
		Sleep(100)
		if boolStartDecloaking == true then
			boolStartDecloaking= false
			setSpeedEnv(unitID, 1.0)
			Spring.Echo("Show "..UnitDefs[Spring.GetUnitDefID(unitID)].name)
			SetUnitValue(COB.WANT_CLOAK, 0)
			Spring.GiveOrderToUnit(unitID, CMD.FIRE_STATE, {1}, {}) 
			boolCloaked= false
			if civilianID and doesUnitExistAlive(civilianID) == true then
				Spring.DestroyUnit(civilianID, true, true)
			end
		end
		Sleep(100)
	end
end

boolCloaked = false
function script.Activate()
	boolStartCloaking = true
	return 1
  
end

function script.Deactivate()
	boolStartDecloaking= true
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



Spring.SetUnitNanoPieces(unitID, { gun })
gameConfig = getGameConfig()
 raidDownTime = gameConfig.agentConfig.raidWeaponDownTimeInSeconds * 1000
local raidComRange = gameConfig.agentConfig.raidComRange
myRaidDownTime = raidDownTime
local scanSatDefID = UnitDefNames["sattelitescan"].id
local raidBonusFactorSatellite=  gameConfig.agentConfig.raidBonusFactorSatellite

function raidReactor()
	myTeam = Spring.GetUnitTeam(unitID)
	while true do
		Sleep(100)
		boolComSatelliteNearby= false
		process(getAllNearUnit(unitID, raidComRange),
				function (id)
					if myTeam == Spring.GetUnitTeam(id) and Spring.GetUnitDefID(id) == scanSatDefID then
						myRaidDownTime= math.max( -100, myRaidDownTime - 100* raidBonusFactorSatellite)
						boolComSatelliteNearby = true
					end				
				end
				)

		myRaidDownTime= math.max( -100, myRaidDownTime - 100)

	end
end

function raidReloadComplete()
	return myRaidDownTime < 0
end


function raidAimFunction(weaponID, heading, pitch)
return raidReloadComplete()
end

function pistolAimFunction(weaponID, heading, pitch)
return true
end

function gunAimFunction(weaponID, heading, pitch)
return boolCloaked
end

function raidFireFunction(weaponID, heading, pitch)
Spring.Echo("raidAimFunction")
boolRecharge = raidDownTime
return true
end

function pistolFireFunction(weaponID, heading, pitch)
Spring.Echo("pistolFireFunction")
return true
end



SIG_RAID = 1
SIG_PISTOL = 2
SIG_GUN = 4

WeaponsTable = {}
function makeWeaponsTable()
    WeaponsTable[1] = { aimpiece = gun, emitpiece = gun, aimfunc = raidAimFunction, firefunc = raidFireFunction, signal = SIG_RAID }
    WeaponsTable[2] = { aimpiece = gun, emitpiece = gun, aimfunc = pistolAimFunction, firefunc = pistolFireFunction, signal = SIG_PISTOL}
end


function turretReseter()
    while true do
        Sleep(1000)
        for i = 1, #WeaponsTable do
			if WeaponsTable[i].coolDownTimer then
				if WeaponsTable[i].coolDownTimer > 0 then
					WeaponsTable[i].coolDownTimer = math.max(WeaponsTable[i].coolDownTimer - 1000, 0)

				elseif WeaponsTable[i].coolDownTimer <= 0 then
					tP(WeaponsTable[i].emitpiece, -90, 0, 0, 0)
					WeaponsTable[i].coolDownTimer = -1
				end
			end
        end
    end
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