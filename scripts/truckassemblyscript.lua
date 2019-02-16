include "createCorpse.lua"
include "lib_OS.lua"
include "lib_UnitScript.lua"
include "lib_Animation.lua"
include "lib_Build.lua"

TablesOfPiecesGroups = {}


center = piece "center"


function script.Create()
    TablesOfPiecesGroups = getPieceTableByNameGroups(false, true)
end

function script.Killed(recentDamage, _)
    createCorpseCUnitGeneric(recentDamage)
    return 1
end




function script.Activate()

    return 1
end

function script.Deactivate()

    return 0
end

-- Signals for moving
SIG_FOLD=2
SIG_MOVE=4
SIG_RESET=8
SIG_UNFOLD=16
SIG_BREATH=32
SIG_UPGRADE=64
SIG_STOP=128



local boolAllreadyDead=false
local boolAllreadyStarted=false
local boolMurdered=true
local mexID = -666
SIG_RESET=1


function UpdateUnitPosition(ParentID, UnitID, attach)
	local px, py, pz, _, _, _ = Spring.GetUnitPiecePosDir(ParentID, attach)
	local rx, ry, rz = Spring.GetUnitPieceRotation(ParentID, attach)
	Spring.MoveCtrl.SetPhysics(UnitID, px, py, pz+4, 0, 0, 0, rx, ry, rz)
end

function GetUnitPieceRotation(unitID, piece)
	local rx, ry, rz = Spring.UnitScript.CallAsUnit(unitID, spGetPieceRotation, piece)
	local Heading = Spring.GetUnitHeading(unitID) --COB format
	local dy = rad(Heading / 182)
	return rx, dy + ry, rz
end

factoryID=nil
----aimining & fire weapon
function newFactory ()
	if GG.Factorys == nil then GG.Factorys={} end
	
	local x,y,z = Spring.GetUnitPosition(unitID)
	teamID = Spring.GetUnitTeam (unitID)
	
	factoryID = Spring.CreateUnit ("transportedassembly", x,y+ 40,z+ 20, 0, teamID) 
	GG.Factorys[factoryID]={}
	GG.Factorys[factoryID][1]= unitID 
	GG.Factorys[factoryID][2]= false
	Spring.SetUnitNoSelect(unitID,true)
	Spring.MoveCtrl.Enable(factoryID,true) 
	Spring.SetUnitNeutral(factoryID,true)
	Spring.SetUnitBlocking (factoryID,false,false)
	
end


boolBuilding=false
function updateBoolisBuilding()
	while GG.Factorys== nil or GG.Factorys[factoryID]== nil do
		Sleep(150)
	end
	
	while true do
		if GG.Factorys[factoryID][2]==true then
			
			boolBuilding=true
		else 
			
			boolBuilding=false
		end
		
		
		Sleep(500)
	end
	
end

function workInProgress()
	while factoryID == nil do
		Sleep(250)
	end
	

	buildID=nil
	buildIDofOld=nil
	counter=0
	while(true)do
		
		if factoryID and Spring.ValidUnitID(factoryID)== true then
			
			buildID=Spring.GetUnitIsBuilding(factoryID)
			if buildID and buildID ~= buildIDofOld then
		
				counter=counter+1
				if counter >35 then 	Spring.DestroyUnit(unitID,true,false) end

				boolBuilding=true
				Spring.SetUnitNoDraw(buildID,true)
				buildProgress=0
	
				while buildProgress and buildProgress < 1 do
		
					health,maxHealth,paralyzeDamage,captureProgress,buildProgress=Spring.GetUnitHealth(buildID)
	
					Sleep(150)
				end
				
				if buildID ~=nil then
					buildIDofOld=buildID	
					buildID=nil
				end	
				
				if buildID == nil and buildIDofOld ~= nil and Spring.ValidUnitID(buildIDofOld)==true then				
					Spring.SetUnitNoDraw(buildIDofOld,false)

					buildIDofOld=nil
					
				end		
			end
		end
		Sleep(120)
	end
	boolBuilding=false
end



function moveFactory ()
	local spGetUnitPosition=Spring.GetUnitPosition
	local spMovCtrlSetPos=Spring.MoveCtrl.SetPosition
	local spValidUnitID=Spring.ValidUnitID
	local LGetUnitPieceRotation=GetUnitPieceRotation
	local LUpdateUnitPosition=UpdateUnitPosition
	
	while (true) do
		if (not spValidUnitID (factoryID)) then newFactory () end
		local x,y,z = spGetUnitPosition (unitID)	 
		spMovCtrlSetPos(factoryID, x, y+ 50, z+ 2)
		Sleep(50)
	end
end



boolMoving=false
function delayedStop()
	Signal(SIG_STOP)
	SetSignalMask(SIG_STOP)
	Sleep(400)
	boolMoving= false

end

function script.StartMoving()
	boolMoving= true
end
function script.StopMoving()

	StartThread(delayedStop)
	
	
end


function script.Killed(recentDamage, maxHealth)
	
	if Spring.ValidUnitID(factoryID)== true then
		GG.UnitsToKill:PushKillUnit(factoryID,true,true)
	end
	
	return 0
end
--Buildi

function script.Activate()
	
	return 1
end

function script.Deactivate()
	
	return 0
end

boolLaunch=false
function launchBuilding(delayTime)
	boolLaunch=true
end

--Laun

function script.Create()
	
	Spring.SetUnitNoSelect(unitID,true)
	x,y,z=Spring.GetUnitPosition(unitID)
	Spring.SetUnitMoveGoal(unitID,x-20,y,z)

	
	StartThread(workInProgress)	
	StartThread(moveFactory)
	StartThread(updateBoolisBuilding)	

end