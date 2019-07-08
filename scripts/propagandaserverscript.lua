include "createCorpse.lua"
include "lib_OS.lua"
include "lib_UnitScript.lua"
include "lib_Animation.lua"
include "lib_Build.lua"

TablesOfPiecesGroups = {}


Icon = piece "Icon"


function script.Create()
    team = Spring.GetUnitTeam(unitID)
	if not GG.Propgandaservers then  GG.Propgandaservers ={} end
	if not GG.Propgandaservers[team] then  GG.Propgandaservers[team]  =0 end
	GG.Propgandaservers[team] = GG.Propgandaservers[team] +1
	
    TablesOfPiecesGroups = getPieceTableByNameGroups(false, true)
	

	StartThread(cloakLoop)
	StartThread(delayedSpinStart)
end

function delayedSpinStart()
	
	for i=1 , 4 do
	factor = math.random(1,15)
	Spin(TablesOfPiecesGroups["Propeller"][i], y_axis, factor,-1*factor)
	randOhm = math.random(250,2500)
	Sleep(randOhm)
	end
end

function script.Killed(recentDamage, _)
	GG.Propgandaservers[team]  = math.max(0,GG.Propgandaservers[team] -1)

    return 1
end

boolCloaked = false
function cloakLoop()
	while true do

		if  boolCloaked == true then
			hideAll(unitID)
			Show(Icon)
		else
		showAll(unitID)
		Hide(Icon)
		
		end

		Sleep(500)
	end

end

