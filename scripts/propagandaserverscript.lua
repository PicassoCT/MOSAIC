include "createCorpse.lua"
include "lib_OS.lua"
include "lib_UnitScript.lua"
include "lib_Animation.lua"
include "lib_Build.lua"

TablesOfPiecesGroups = {}


center = piece "center"


function script.Create()
    team = Spring.GetUnitTeam(unitID)
	if not GG.Propgandaservers then  GG.Propgandaservers ={} end
	if not GG.Propgandaservers[team] then  GG.Propgandaservers[team]  =0 end
	GG.Propgandaservers[team] = GG.Propgandaservers[team] +1
	
    TablesOfPiecesGroups = getPieceTableByNameGroups(false, true)
end

function script.Killed(recentDamage, _)
	GG.Propgandaservers[team]  = math.max(0,GG.Propgandaservers[team] -1)

    return 1
end

