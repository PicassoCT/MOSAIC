include "createCorpse.lua"
include "lib_OS.lua"
include "lib_UnitScript.lua"
include "lib_Animation.lua"
--include "lib_Build.lua"

local TablesOfPiecesGroups = {}
SIG_DELAYEDSTOP = 1
ammoCapacity = 500

function script.HitByWeapon(x, z, weaponDefID, damage) end
boolStationary = true
center = piece "center"
EmitPiece = piece "EmitPiece"
myDefID = Spring.GetUnitDefID(unitID)

function script.Create()
    TablesOfPiecesGroups = getPieceTableByNameGroups(false, true)

    --Spring.MoveCtrl.SetAirMoveTypeData(unitID, "attackSafetyDistance", 100 )
    setUnitNeverLand(unitID, true)
   foreach(TablesOfPiecesGroups["Rotator"],
            function(id) 
                StartThread(randShow, id) 
            end
            ) 
end
standardSpeed = math.pi / 10
upAxisRotation = 2
rightAxis= 3
function turnDownAndUp( rVal, id, downValue, downSpeed, upValue, upSpeed)
    Turn(id, upAxisRotation, math.rad(rVal),standardSpeed)
    Turn(id, rightAxis, math.rad(downValue),downSpeed)
    Show(id)
    WaitForTurns(id)
    Turn(id, rightAxis, math.rad(upValue),upSpeed)
end

SignAge= 1

function randShow(id) 

    while true do
        rVal = math.random(1, 360)
       
        if boolStationary == true then            
            turnDownAndUp(rVal, id, math.random(-15, -10),0, math.random(0, 10), standardSpeed)
        else   
            turnDownAndUp(rVal, id, math.random(-90, -45),0, math.random(-5, 0), standardSpeed)
        end     
        WaitForTurns(id)
        Hide(id)
        reset(id)
        Sleep(10)

    end
end


function script.Killed(recentDamage, _)
    -- createCorpseCUnitGeneric(recentDamage)
    return 1
end

--- -aimining & fire weapon
function script.AimFromWeapon1() return center end

function script.QueryWeapon1() return center end

function script.AimWeapon1(Heading, pitch)
    WTurn(center,y_axis, Heading, math.pi)
    WTurn(center,x_axis, pitch, math.pi)
    -- aiming animation: instantly turn the gun towards the enemy
    return true
end

function script.FireWeapon1() 
    ammoCapacity = ammoCapacity -5
    if ammoCapacity < 0 then Spring.DestroyUnit(unitID, true, false) end
    return true 
end


function script.StartMoving()
    boolStationary = false
end


function script.StopMoving() 
    boolStationary = true
end

function script.Activate() return 1 end

function script.Deactivate() return 0 end

function script.QueryBuildInfo() return center end

Spring.SetUnitNanoPieces(unitID, {center})

