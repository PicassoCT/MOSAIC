
uprotor = piece "uprotor"
lowrotor = piece "lowrotor"

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

lifeTimeMS = 1*60*1000
function lifeSpan()
    SetSignalMask(SIG_LIFETIME)
    Signal(SIG_LIFETIME)
    while lifeTimeMS >0 do
        Sleep(1000)
        lifeTimeMS = lifeTimeMS -1000
    end
    Spring.DestroyUnit(unitID, true, false)
end

function deployScoutletts()
    Spin(uprotor, y_axis, 9522, 350)
    Spin(lowrotor, y_axis, -9522, 350)
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

