include "createCorpse.lua"
include "lib_OS.lua"
include "lib_UnitScript.lua"
include "lib_Animation.lua"
--include "lib_Build.lua"

TablesOfPiecesGroups = {}
function script.HitByWeapon(x, z, weaponDefID, damage) end

function script.Create()
    Hide(RocketPod)
    Hide(bodyFly)
    TablesOfPiecesGroups = getPieceTableByNameGroups(false, true)
end

function script.Killed(recentDamage, _)
    return 1
end

function script.StartMoving() 
    WTurn(Canopy, x_axis, math.rad(0), 15)
    Show(bodyFly)
    Hide(bodyLand)
    Hide(Canopy)
end

bodyLand = piece("bodyLand")
bodyFly = piece("bodyFly")
Canopy = piece("Canopy")
RocketPod = piece("RocketPod")
function script.StopMoving() 
    Show(Canopy)
    Hide(bodyFly)
    Show(bodyLand)
    Turn(Canopy, x_axis, math.rad(50), 15)
end

function script.Activate() return 1 end

function script.Deactivate() return 0 end

--- -aimining & fire weapon
function script.AimFromWeapon1() 
    return RocketPod 
end

function script.QueryWeapon1() 
    return RocketPod 
end

function script.AimWeapon1(Heading, pitch)
    return true
end

function script.FireWeapon1()
    return true
end

function script.AimFromWeapon2() 
    return RocketPod 
end

function script.QueryWeapon2() 
    return RocketPod 
end


function script.AimWeapon2(Heading, pitch)
    return true
end

function script.FireWeapon2() 
    return true end