include "createCorpse.lua"
include "lib_OS.lua"
include "lib_UnitScript.lua"
include "lib_Animation.lua"
include "lib_Build.lua"

TablesOfPiecesGroups = {}


center = piece "center"

if not aimpiece then echo("Unit of type "..UnitDefs[Spring.GetUnitDefID(unitID)].name .. " has no aimpiece") end
if not center then echo("Unit of type"..UnitDefs[Spring.GetUnitDefID(unitID)].name .. " has no center") end
boolStartIt= false
id = unitID
function externAttach(ad)
	Spring.UnitAttach(unitID, ad, center)
	id = ad
	boolStartIt = true
end

function threadStarter()
	while boolStartIt== false do
		Sleep(1)
	end
	setUnitHeadingFromUnit(unitID, id)
	StartThread(mortallyDependant, id, unitID, 15, false, true)
end

function script.Create()
    TablesOfPiecesGroups = getPieceTableByNameGroups(false, true)
	StartThread(threadStarter)
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
