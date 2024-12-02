include "lib_UnitScript.lua"
include "lib_mosaic.lua"

uprotor = piece "uprotor"
lowrotor = piece "lowrotor"
center = piece "Scoutlett"

local SIG_SCOUTLET = 2

function script.Create()    
end

function script.Killed(recentDamage, _)
    return 1
end

--- -aimining & fire weapon

boolMovedAtLeastOnce= false
function script.StartMoving()
    boolMovedAtLeastOnce= true
end
SIG_LIFETIME =1

startLifeTime = 1*60*1000
lifeTimeMS = startLifeTime
function lifeSpan()
    SetSignalMask(SIG_LIFETIME)
    Signal(SIG_LIFETIME)
    while lifeTimeMS >0 do
        Sleep(1000)
        lifeTimeMS = lifeTimeMS -1000
        updateProgressBar(math.max(0,lifeTimeMS/startLifeTime))
    end
    Spring.DestroyUnit(unitID, true, false)
end

function deployScoutletts()
    Spin(uprotor, y_axis, 9522, 350)
    Spin(lowrotor, y_axis, -9522, 350)
end

function updateProgressBar(status)
    Description= "LifeTimeRemaining:"
    Description = string.rep("|",  status * 20)  
    Spring.SetUnitTooltip(unitID, Description)
end


function script.StopMoving()
end

function script.Activate() 
    deployScoutletts()
    if boolMovedAtLeastOnce == true then
     StartThread(lifeSpan)
    end
    return 1 
end

function script.Deactivate() 
    StopSpin(uprotor, y_axis, 1)
    StopSpin(lowrotor, y_axis, 1)
    Signal(SIG_LIFETIME)

    return 0 
end



function script.AimFromWeapon(weaponID)
    return center
end

function script.QueryWeapon(weaponID)
    return center
end

function script.FireWeapon(weaponID)
    return true
end


function script.AimWeapon(weaponID, heading, pitch)
    return true
end
