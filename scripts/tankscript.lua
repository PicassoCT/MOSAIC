include "createCorpse.lua"
include "lib_OS.lua"
include "lib_UnitScript.lua"
include "lib_Animation.lua"
include "lib_Build.lua"

TablesOfPiecesGroups = {}

function script.HitByWeapon(x, z, weaponDefID, damage) end

center = piece "Body1"
aimpiece = piece "Turret1"
Cannon1 = piece "Cannon1"
SIG_RESETAIM = 1
myDefID = Spring.GetUnitDefID(unitID)
myTeamID = Spring.GetUnitTeam(unitID)
gaiaTeamID = Spring.GetGaiaTeamID()
function script.Create()

    generatepiecesTableAndArrayCode(unitID)
    TablesOfPiecesGroups = getPieceTableByNameGroups(false, true)
    resetAll(unitID)
    if gaiaTeamID == myTeamID then
        Spring.SetUnitAlwaysVisble(unitID, true)
    end
end

function script.Killed(recentDamage, _)

    -- createCorpseCUnitGeneric(recentDamage)
    return 1
end

--- -aimining & fire weapon
function script.AimFromWeapon1() return aimpiece end

function script.QueryWeapon1() return Cannon1 end

boolNoLongerAiming = true

function noLongerAiming()
    Signal(SIG_RESETAIM)
    SetSignalMask(SIG_RESETAIM)
    boolNoLongerAiming = false
    Sleep(5000)
    boolNoLongerAiming = true
    StartThread(PlaySoundByUnitDefID, myDefID, "sounds/tank/rotate.ogg", 0.8,
                1000, 1)
    WTurn(aimpiece, 2, 0, 0.5)
    WTurn(Cannon1, 1, 0, 0.5)

end
function script.AimWeapon1(Heading, pitch)
    -- aiming animation: instantly turn the gun towards the enemy
    StartThread(PlaySoundByUnitDefID, myDefID, "sounds/tank/rotate.ogg", 1.0,
                1000, 1)
    StartThread(noLongerAiming)
    WTurn(aimpiece, 2, Heading, 0.7)
    WTurn(Cannon1, 1, -pitch, 0.7)
    return true
end

function script.FireWeapon1() return true end

function script.StartMoving()
    StartThread(PlaySoundByUnitDefID, myDefID, "sounds/tank/drive_4_30.ogg",
                1.0, 4500, 1)
end

function script.StopMoving() end

function script.Activate() return 1 end

function script.Deactivate() return 0 end

function script.QueryBuildInfo() return center end

Spring.SetUnitNanoPieces(unitID, {center})

