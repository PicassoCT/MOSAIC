include "createCorpse.lua"
include "lib_OS.lua"
include "lib_UnitScript.lua"
include "lib_Animation.lua"
--include "lib_Build.lua"

TablesOfPiecesGroups = {}


local myDefID = Spring.GetUnitDefID(unitID)
local myTeamID = Spring.GetUnitTeam(unitID)
local GameConfig = getGameConfig()
local center = piece "TurretBase"
local Turret = piece "TurretHead"
local aimpiece = piece "AimPiece"
local aimingFrom = aimpiece
local firingFrom = aimpiece
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
end

function projectileLaunch(i)
    id = launchProjT[i]
    flyid = flyingProjT[i]
    Show(id)
    WMove(id,y_axis, 500, 500*3)
    Hide(id)
    Show(flyid)
    tx= math.random(45,90)
    Turn(flyid,x_axis, math.rad(tx), 0.35)
    for i=100, 1500, 150 do
        Move(flyid,y_axis, i, i)
        Sleep(100)
    end
    turnPieceRandDir(flyid,0.5)
end

function launchAnimation()
    factor = 2.0
    Signal(SIG_LAUNCHANIMATION)
    SetSignalMask(SIG_LAUNCHANIMATION)
    boolLaunchAnimationStarted = true
    boolLaunchAnimationCompleted= false
    for i=1, #launchProjT do
        StartThread(projectileLaunch, i)
        Sleep(250)
    end
    WaitForMoves(launchProjT)
    Sleep(10)
    WaitForMoves(flyingProjT)
    boolLaunchAnimationCompleted = true
end

currentLaunchState = "ready"
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
        boolFireRequest = false
        return "ready"
    end

   launchStateMachine["launching"] = function(frame, oldState, persPack)
        if oldState == "ready" then
            StartThread(launchAnimation)
        end
        if boolFireRequest == false then
            persPack.launchingCounter = persPack.launchingCounter + 1
        end

        if boolFireRequest == true and boolLaunchAnimationCompleted == true then
            return "fire"
        end

        if  persPack.launchingCounter > 50 and boolLaunchAnimationCompleted == true then
            Signal(SIG_LAUNCHANIMATION)

            return "ready"
        end

        boolFireRequest = false
        return "launching"
    end

    launchStateMachine["fire"] = function (frame, oldState, persPack)
        hideT(launchProjT)
        hideT(flyingProjT)
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
    persPack = {}
    while true do
        newState = launchStateMachine[currentLaunchState](Spring.GetGameFrame(), oldState, persPack)
       -- echo("Launchstatemachine:"..currentLaunchState.."/"..oldState)
        oldState = currentLaunchState
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
    boolFireRequest= true
    return currentLaunchState == "fire"
end

function script.FireWeapon1()
    currentLaunchState = "reloading"
    return true
end

function script.Activate() return 1 end

function script.Deactivate() return 0 end

