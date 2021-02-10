include "createCorpse.lua"
include "lib_OS.lua"
include "lib_UnitScript.lua"
include "lib_Animation.lua"
include "lib_Build.lua"

TablesOfPiecesGroups = {}

aimpiece = piece "aimpiece"
base = piece "base"
emitpiece = piece "emitpiece"
RadiatorCold = piece "RadiatorCold"
RadiatorHot = piece "RadiatorHot"
SIG_RADIATOR = 1

function hotRadiators()
    Show(RadiatorHot)
    Hide(RadiatorCold)
    Signal(SIG_RADIATOR)
    SetSignalMask(SIG_RADIATOR)
    Sleep(9000)
    Show(RadiatorCold)
    Hide(RadiatorHot)

end

function script.Create()
    Show(RadiatorCold)
    Hide(RadiatorHot)
    TablesOfPiecesGroups = getPieceTableByNameGroups(false, true)
    StartThread(updateMothership)
end

function updateMothership()
    while not recieveMessage(unitID) do Sleep(10) end

    parentID = recieveMessage(unitID)
    while isUnitAlive(parentID) == true do
        transferOrders(unitID, parentID)
        Sleep(100)
    end
end

function script.Killed(recentDamage, _)

    -- createCorpseCUnitGeneric(recentDamage)
    return 1
end

--- -aimining & fire weapon
function script.AimFromWeapon1() return emitpiece end

function script.QueryWeapon1() return aimpiece end

function script.AimWeapon1(Heading, pitch)
    -- aiming animation: instantly turn the gun towards the enemy

    WTurn(base, z_axis, Heading, math.pi)
    WTurn(aimpiece, x_axis, -pitch, math.pi)
    return true
end

function script.FireWeapon1()
    StartThread(hotRadiators)
    return true
end

function script.Activate() return 1 end

function script.Deactivate() return 0 end

