include "createCorpse.lua"
include "lib_OS.lua"
include "lib_UnitScript.lua"
include "lib_Animation.lua"
include "lib_Build.lua"

TablesOfPiecesGroups = {}

function script.Create()
    generatepiecesTableAndArrayCode(unitID)
    TablesOfPiecesGroups = getPieceTableByNameGroups(false, true)
	StartThread(launchMotion)
end

function launchMotion()
	maxTotalInterceptPossibleTime= 10*30
	totalInterceptPossibleTime= maxTotalInterceptPossibleTime
	maxHeigth = 2048
	x,y,z = Spring.GetUnitPosition(unitID)
	Spring.MoveCtrl.Enable(unitID, true)
	offset = 0
	
	while totalInterceptPossibleTime > 0 do
		offset = math.sin((math.pi/2) * (1- (totalInterceptPossibleTime/maxTotalInterceptPossibleTime)))*maxHeigth
		Spring.MoveCtrl.SetPosition(unitID, x,y+ offset,z)
		totalInterceptPossibleTime=totalInterceptPossibleTime-1
		Sleep(1)
	end
	
	while true  do
		Spring.MoveCtrl.SetPosition(unitID, x,y+ maxHeigth,z)
		Sleep(1)
	end
end

function script.Killed(recentDamage, _)
    return 1
end


