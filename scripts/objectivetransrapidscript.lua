include "createCorpse.lua"
include "lib_OS.lua"
include "lib_UnitScript.lua"
include "lib_Animation.lua"
include "lib_Build.lua"

TablesOfPiecesGroups = {}

function script.HitByWeapon(x, z, weaponDefID, damage) end
local trainAxis = x_axis
local maxDistanceTrain = 1320000
local trainspeed = 9000
center = piece"center"

function script.Create()
    TablesOfPiecesGroups = getPieceTableByNameGroups(false, true)
    hideT(TablesOfPiecesGroups["Tunnel1_"])
    hideT(TablesOfPiecesGroups["Tunnel2_"])
    hideT(TablesOfPiecesGroups["TunnelDetection"])
    hideT(TablesOfPiecesGroups["Train"])
    hideT(TablesOfPiecesGroups["Container"])

    StartThread(trainLoop, 1)
    StartThread(trainLoop, 2)
    rVal = math.random(0,360)
    Turn(center, y_axis, math.rad(rVal),0)
    StartThread(deployTunnels, 1)
    StartThread(deployTunnels, 2)
end

local boolOldState = false
    function detectRisingEdge(boolActive)
        boolResult = false
        if boolOldState == false and boolActive == true then
            boolResult = true
        end

        return boolResult
    end

    function detectFallingEdge(boolActive)
        boolResult = false
        if boolOldState == true and boolActive == false then
            boolResult = true
        end

        return boolResult
    end
function deployTunnels(nr)
detectionPiece = piece("TunnelDetection"..nr) 
tunnelIndex = 1
local xMax = Game.mapSizeX 
local zMax = Game.mapSizeZ 
for i = maxDistanceTrain, -maxDistanceTrain, -50 do
	WMove(detectionPiece,trainAxis, i, 0)
	boolAboveGround,x, z = isPieceAboveGround(unitID, detectionPiece,0)
    if x  <= 0 or x >= xMax or z <= 0 or z >= zMax then break end

	if detectRisingEdge(boolAboveGround) or detectFallingEdge(boolAboveGround) then
		tunnelIndexPiece = piece("Tunnel"..nr.."_"..tunnelIndex)
		if tunnelIndexPiece then
		tunnelIndex = tunnelIndex + 1
		WMove(tunnelIndexPiece, trainAxis, i, 0)
		Show(tunnelIndexPiece)
        if tunnelIndex == 6 then return end
		end
	end


	boolOldState = boolAboveGround
end
end

function buildTrain(nr)
    assert(TablesOfPiecesGroups["Train"][nr],nr)
	Show(TablesOfPiecesGroups["Train"][nr])
    indexStart, indexStop =1, 2
    if nr ==1 then 
        indexStart = 1
        indexStop = 4
    elseif nr == 2 then
        indexStart = 5
        indexStop = 8
    end

    for i=indexStart,indexStop do
        if maRa() == true then 
            Show(TablesOfPiecesGroups["Container"][i])
        end
    end

end

function hideTrain(nr)
    assert(TablesOfPiecesGroups["Train"][nr],nr)
	Hide(TablesOfPiecesGroups["Train"][nr])
        indexStart, indexStop =1, 2
    if nr ==1 then 
        indexStart = 1
        indexStop = 4
    elseif nr == 2 then
        indexStart = 5
        indexStop = 8
    end

    for i=indexStart,indexStop do
        
            Hide(TablesOfPiecesGroups["Container"][i])

    end
end

function trainLoop(nr)
	rSleepValue = math.random(1,100)*100
	Sleep(rSleepValue)
	local train = piece("Train"..nr)
	direction = randSign()
	
	while true do
		WMove(train, trainAxis, maxDistanceTrain*direction, 0)
		buildTrain(nr)
		WMove(train, trainAxis, 0, trainspeed)
		breakTime = math.random(0,10)*1000
		Sleep(breakTime)
        buildTrain(nr)
		WMove(train, trainAxis, maxDistanceTrain*direction*-1, trainspeed)
		hideTrain(nr)
		betweenInterval = math.random(1,5)*60*1000
		Sleep(betweenInterval)
	end
end


function script.Killed(recentDamage, _)
    return 1
end

function script.StartMoving() end

function script.StopMoving() end

function script.Activate() return 1 end

function script.Deactivate() return 0 end
