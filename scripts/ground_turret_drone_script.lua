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
local Turret = piece "Torso"
local aimpiece = piece "DroneMineLaunchProj"
local aimingFrom = aimpiece
local firingFrom = aimpiece

function script.Create()
    resetAll(unitID)
    Hide(aimpiece)
    TablesOfPiecesGroups = getPieceTableByNameGroups(false, true)
end

function script.HitByWeapon(x, z, weaponDefID, damage) return damage end

function script.Killed(recentDamage, _)
    return 1
end

--- -aimining & fire weapon
function script.AimFromWeapon1() return firingFrom end

function script.QueryWeapon1() return firingFrom end

function script.AimWeapon1(Heading, pitch)
    Show(firingFrom)
    WMove(firingFrom,y_axis, 10, 20)
    return true,
end

function script.FireWeapon1()
    Hide(firingFrom)
    reset(firingFrom)
    return true
end


function script.Activate() return 1 end

function script.Deactivate() return 0 end

