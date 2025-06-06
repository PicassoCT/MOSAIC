include "createCorpse.lua"
include "lib_OS.lua"
include "lib_UnitScript.lua"
include "lib_Animation.lua"
--include "lib_Build.lua"

local TablesOfPiecesGroups = {}

local myTeamID = Spring.GetUnitTeam(unitID)
local GameConfig = getGameConfig()
local center = piece "TurretBase"
local Turret = piece "TurretHead"
local aimpiece = piece "AimPiece"
local firepiece = piece "FirePiece"
local aimingFrom = aimpiece
local firingFrom = firepiece
local launchProjT
local flyingProjT
boolLaunchAnimationStarted = false
boolLaunchAnimationCompleted = false
currentLaunchState = "ready"
SIG_LAUNCHANIMATION = 1
function script.Create()
    resetAll(unitID)
    Spin(Turret,y_axis, math.rad(42),0)
    Hide(aimpiece)
    TablesOfPiecesGroups = getPieceTableByNameGroups(false, true)
    launchProjT = TablesOfPiecesGroups["DroneMineLaunchProjFolded"]
    flyingProjT = TablesOfPiecesGroups["DroneMineLaunchProjUnfolded"]
    StartThread(launchStateMachineThread)
    Turn(Turret, x_axis, math.rad(40),0)
end

function projectileLaunch(i, factor)
    id = launchProjT[i]
    flyid = flyingProjT[i]
    Show(id)
    WMove(id,y_axis, 500, 500*factor)
    Hide(id)
    Show(flyid)
    for i=100, 1500, 150 do
        Move(flyid,y_axis, i, factor)
        Sleep(100)
    end
    turnPieceRandDir(flyid, 0.5)
end

function launchAnimation()
	allLaunched = false
    factor = 5.0
    for i=1, #launchProjT do
        StartThread(projectileLaunch, i,factor)
        Sleep(250)
    end
    WaitForMoves(launchProjT)
    Sleep(10)
    WaitForMoves(flyingProjT)
	allLaunched = true
end

currentLaunchState = "ready"
allLaunched = false
function launchStateMachineThread()
           hideT(launchProjT)
           hideT(flyingProjT)
           resetT(launchProjT)
           resetT(flyingProjT)
           for i=1, #launchProjT do
            id = launchProjT[i]
            Move(id, y_axis, -100, 0)
            Show(id)
            WMove(id, y_axis, 0, 100)            
           end
    launchStateMachine = {}
    launchStateMachine["ready"] =   function (frame, oldState, persPack)
        persPack.launchingCounter = 0
        resetT(launchProjT, 150)
        resetT(flyingProjT, 150)
        if boolFireRequest then
            return "launching"
        end
        return "ready"
    end

   launchStateMachine["launching"] = function(frame, oldState, persPack)
        if oldState == "ready" then
            launchAnimation()
			while not allLaunched do
				Sleep(50)
			end
			allLaunched = false
			hideT(launchProjT)
			hideT(flyingProjT)
            boolFireRequest = false
            return "fire"
        end



        return "launching"
    end

    launchStateMachine["fire"] = function (frame, oldState, persPack)
        return "fire"
    end

    launchStateMachine["reloading"] = function(frame, oldState, persPack)
        boolFireRequest =false
        if oldState == "fire" then   
            persPack.startFrame = frame
            return "reloading" 
        end

        if frame > persPack.startFrame + 30 then
           hideT(launchProjT)
           hideT(flyingProjT)
           resetT(launchProjT)
           resetT(flyingProjT)
           for i=1, #launchProjT do
            id = launchProjT[i]
            Move(id, y_axis, -100, 0)
            Show(id)
            WMove(id, y_axis, 0, 100)            
           end
        return "ready"
        end
    return reloading
    end

    oldState = "ready"
    currentLaunchState= "ready"
    persPack = {}
    while true do
        oldState = currentLaunchState
		newState = launchStateMachine[currentLaunchState](Spring.GetGameFrame(), oldState, persPack)
       -- echo("Launchstatemachine:"..currentLaunchState.."/"..oldState)
        currentLaunchState = newState
        Sleep(100)
    end
end

function script.HitByWeapon(x, z, weaponDefID, damage) return damage end

function script.Killed(recentDamage, _)
    return 1
end

--- -aimining & fire weapon
function script.AimFromWeapon1() return firingFrom end

function script.QueryWeapon1() return firingFrom end

function script.AimWeapon1(Heading, pitch)
    Turn(Turret, y_axis, math.rad(40),0)
    WTurn(Turret, x_axis, Heading,0)
    boolFireRequest= true
    return currentLaunchState == "fire"
end

function script.FireWeapon1()
    currentLaunchState = "reloading"
    return true
end

function script.Activate() return 1 end

function script.Deactivate() return 0 end

