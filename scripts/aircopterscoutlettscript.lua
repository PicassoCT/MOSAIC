include "createCorpse.lua"
include "lib_OS.lua"
include "lib_UnitScript.lua"
include "lib_Animation.lua"

TablesOfPiecesGroups = {}
uprotor = piece "uprotor"
lowrotor = piece "lowrotor"

local SIG_SCOUTLET = 2

function script.Create()    
    TablesOfPiecesGroups = getPieceTableByNameGroups(false, true)

end

function script.Killed(recentDamage, _)
    return 1
end

--- -aimining & fire weapon


function script.StartMoving()
end


function deployScoutletts()
    Spin(uprotor, y_axis, 9522, 350)
    Spin(lowrotor, y_axis, -9522, 350)
end

function script.StopMoving()
end

function script.Activate() 
    deployScoutletts()
    StartThread(lifeTime, 1*60*1000)
    return 1 
end

function script.Deactivate() 
    StopSpin(uprotor, y_axis, 1)
    StopSpin(lowrotor, y_axis, 1)
    return 0 
end

