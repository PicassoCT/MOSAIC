include "createCorpse.lua"
include "lib_OS.lua"
include "lib_UnitScript.lua"
include "lib_Animation.lua"
include "lib_Build.lua"

TablesOfPiecesGroups = {}

function script.HitByWeapon(x, z, weaponDefID, damage) end

center = piece "center001"
Turret = piece "Turret"
aimpiece = Turret
SIG_GUARDMODE = 1

function script.Create()
    resetAll(unitID)
    Hide(aimpiece)
    TablesOfPiecesGroups = getPieceTableByNameGroups(false, true)
    StartThread(uncloakWhenTransported)
end

function uncloakWhenTransported()
    while true do
        transporterID = Spring.GetUnitTransporter(unitID)
        if transporterID then Spring.SetUnitCloak(unitID, false) end

        Sleep(100)
    end
end

function script.Killed(recentDamage, _)
    EmitSfx(center,1024)
    EmitSfx(center,1025)
    transporterID = Spring.GetUnitTransporter(unitID)
    if transporterID and doesUnitExistAlive(transporterID) == true then
        Spring.DestroyUnit(transporterID, false, true)
    end
    -- createCorpseCUnitGeneric(recentDamage)
    return 1
end

--- -aimining & fire weapon
function script.AimFromWeapon1() return Turret end

function script.QueryWeapon1() return center end

function script.AimWeapon1(Heading, pitch) return true end

function script.FireWeapon1() return true end

function script.StartMoving() end

function script.StopMoving() end

function script.Activate() return 1 end

function script.Deactivate() return 0 end
