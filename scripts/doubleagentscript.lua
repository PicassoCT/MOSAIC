include "createCorpse.lua"
include "lib_OS.lua"
include "lib_UnitScript.lua"
include "lib_Animation.lua"
include "lib_Build.lua"

TablesOfPiecesGroups = {}


center = piece "Text001"
one = piece "One"
other = piece "Other"

if not center then echo("Unit of type"..UnitDefs[Spring.GetUnitDefID(unitID)].name .. " has no center") end

function script.Create()
    TablesOfPiecesGroups = getPieceTableByNameGroups(false, true)
    StartThread(animation)
    StartThread(onDeCloakNeverRecloak, unitID)
end

function animation()
	while true do
		Move(one,x_axis,40, 40 )
		Move(other,x_axis,-40, 40 )
		Sleep(500)
		WMove(one,x_axis,0, 40 )
		WMove(other,x_axis,0, 40 )
		Sleep(500)
	end
end


function script.Killed(recentDamage, _)
    return 1
end

function script.Activate()

    return 1
end

function script.Deactivate()
    return 0
end
