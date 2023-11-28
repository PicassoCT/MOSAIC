include "createCorpse.lua"
include "lib_OS.lua"
include "lib_UnitScript.lua"
include "lib_Animation.lua"
--include "lib_Build.lua"

TablesOfPiecesGroups = {}
myDefID = Spring.GetUnitDefID(unitID)
function script.HitByWeapon(x, z, weaponDefID, damage) end

attachPoint = piece("attachPoint")
Icon = piece("Icon")
function script.Create()
    TablesOfPiecesGroups = getPieceTableByNameGroups(false, true)
    Hide(attachPoint)
end


function script.Killed(recentDamage, _)

    -- createCorpseCUnitGeneric(recentDamage)
    return 1
end

function script.TransportPickup(passengerID)
    if passengerID then
       Spring.UnitAttach(unitID, passengerID, attachPoint)
    end
end

function script.Activate() return 1 end

function script.Deactivate() return 0 end

function script.TransportDrop(passengerID, x, y, z)
        Spring.UnitDetach(passengerID)
end