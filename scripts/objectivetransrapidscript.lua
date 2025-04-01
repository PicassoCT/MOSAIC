include "createCorpse.lua"
include "lib_OS.lua"
include "lib_UnitScript.lua"
include "lib_Animation.lua"
--include "lib_Build.lua"

local TablesOfPiecesGroups = {}

function script.HitByWeapon(x, z, weaponDefID, damage) end
local trainAxis = x_axis
local maxDistanceTrain = 120000
local trainspeed = 9000
center = piece"center"
rail1 = piece"rail1"
rail2 = piece"rail2"
sub1 = piece"sub1"
sub2 = piece"sub2"

function script.Create()
    TablesOfPiecesGroups = getPieceTableByNameGroups(false, true)
    hideAll(unitID)
    StartThread(setup)
end

function setup()
    Sleep(10)
    StartThread(trainLoop, 1)
    StartThread(trainLoop, 2)
    rVal = math.random(0, 360)
    WTurn(center, y_axis, math.rad(rVal),0)
    StartThread(deployTrack, -1 , rail1,  TablesOfPiecesGroups["Rail1Sub"] , sub1)
    StartThread(deployTrack, 1 , rail2,  TablesOfPiecesGroups["Rail2Sub"] , sub2)

end



function validTrackPart( EndPiece, DetectorPiece)
    Hide(DetectorPiece)
    Hide(EndPiece)
    x,y,z = Spring.GetUnitPiecePosDir(unitID, DetectorPiece)
    gh = Spring.GetGroundHeight(x,z)

    boolUnderground =  gh +10 > y
    boolOutsideMap = (x > Game.mapSizeX or x <= 0) or  (z > Game.mapSizeZ or z <= 0)
    return boolUnderground or boolOutsideMap
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

    tunnelMultiple = 5

function deployTunnels(nr, tunnelTable)
    boolOldState = false
    Sleep(nr)

    detectionPiece = piece("TunnelDetection"..nr) 
    tunnelIndex = 1
    local xMax = Game.mapSizeX 
    local zMax = Game.mapSizeZ 
    Hide(detectionPiece)
        for distanceTunnel = maxDistanceTrain, -1*maxDistanceTrain, -32 do
        	WMove(detectionPiece,trainAxis, distanceTunnel, 0)
        	boolAboveGround,x, z = isPieceAboveGround(unitID, detectionPiece, 0)
            if not (not x or not z or  x  <= 0 or x >= xMax or z <= 0 or z >= zMax) then
            --Spring.Echo("Checking tunnel "..nr.." for"..distanceTunnel)
            	if detectRisingEdge(boolAboveGround) or detectFallingEdge(boolAboveGround) then
            		tunnelIndexPiece = tunnelTable[tunnelIndex]
            		if tunnelIndexPiece then
                		WMove(tunnelIndexPiece, trainAxis, distanceTunnel, 0)
                		Show(tunnelIndexPiece)
                        tunnelIndex = tunnelIndex + 1
                        if tunnelIndex > #tunnelTable then
                         return 
                        end
            		end
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

	while true do
        direction = randSign()
        WMove(train, trainAxis, maxDistanceTrain*direction, 0)
		buildTrain(nr)
		WMove(train, trainAxis, 0, trainspeed)
		breakTime = math.random(0,10)*1000
		Sleep(breakTime)
        buildTrain(nr)
    	WMove(train, trainAxis, maxDistanceTrain*direction*-1, trainspeed)
        hideTrain(nr)
		betweenInterval = math.random(0,3)*60*1000+1
		Sleep(betweenInterval)
	end
end


function script.Killed(recentDamage, _)
    return 1
end
