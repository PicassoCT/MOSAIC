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
rail1 = piece"Rail1"
rail2 = piece"Rail2"
sub1 = piece"Sub1"
sub2 = piece"Sub2"

function script.Create()
    TablesOfPiecesGroups = getPieceTableByNameGroups(false, true)
    hideAll(unitID)
    StartThread(setup)
end

countUp= 0

function setup()
    Sleep(10)
    StartThread(trainLoop, 1)
    StartThread(trainLoop, 2)
    rVal = math.random(0, 360)
    WTurn(center, y_axis, math.rad(rVal),0)
    StartThread(deployTrack, -1 , rail1,  TablesOfPiecesGroups["Rail1Sub"] , sub1, EndPoint1)
    StartThread(deployTrack, 1 , rail2,  TablesOfPiecesGroups["Rail2Sub"] , sub2, EndPoint2)
    StartThread(trainLoop)
    foreach(TableOfPiecesGroups["Add"],
            function(id)
                if maRa() then Show(id) end
            end
            )
end

function deployTrack( directionSign, railP, Pillars, detectorPiece, endPoint)
    upValue = 25
    lastValue = upVal*directionSign
    WTurn(railP, x_axis, math.rad(upVal*directionSign), 0)
    boolValidStart = validTrackPart(endPoint, DetectorPiece)
    assert(boolValidStart)
    Hide(endPoint)

    for i= upVal*directionSign, upValue, -1* directionSign do
       WTurn(railP, x_axis, math.rad(i), 0)
       boolAboveGround = validTrackPart(endPoint, DetectorPiece)
       if not boolAboveGround then 
            endvalue =i - (1*directionSign)
            WTurn(railP, x_axis, math.rad(endvalue), 0)
            WTurn(endPoint, x_axis, math.rad(-endvalue), 0)
            foreach(Pillars,
                    function(id)
                        Show(id)
                        WTurn(id, x_axis, math.rad(-endvalue), 0)
                    end
                    )
            Show(endPoint)
            break
       end
       Sleep(1)
       lastValue = i
    end
    Show(railP)
    countUp= countUp +1
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

function deployTunnel(tunnelTable, tunnelIndex, distanceTunnel)
    tunnelIndexPiece = tunnelTable[tunnelIndex]
                    if tunnelIndexPiece then
                        WMove(tunnelIndexPiece, trainAxis, distanceTunnel, 0)
                        Show(tunnelIndexPiece)
                        tunnelIndex = tunnelIndex + 1
                    end
    return tunnelIndex, tunnelIndex > #tunnelTable
end

function deployTunnels(nr, dirSign)
    boolOldState = false
    Sleep(nr)
    tunnelTableA= TablesOfPiecesGroups["Tunnel"..nr.."_"]
    tunnelTableB= TablesOfPiecesGroups["Tunnel"..nr.."_"]

    detectionPiece = piece("TunnelDetection"..nr) 
    tunnelIndexA = 1
    tunnelIndexB = 1
    local xMax = Game.mapSizeX 
    local zMax = Game.mapSizeZ 
    Hide(detectionPiece)
        for distanceTunnel = 0, maxDistanceTrain* dirSign, 32* dirSign do
        	WMove(detectionPiece,trainAxis, distanceTunnel, 0)
        	boolAboveGround,x, z = isPieceAboveGround(unitID, detectionPiece, 0)
            if not (not x or not z or  x  <= 0 or x >= xMax or z <= 0 or z >= zMax) then
            --Spring.Echo("Checking tunnel "..nr.." for"..distanceTunnel)
            	if detectRisingEdge(boolAboveGround) or detectFallingEdge(boolAboveGround) then
                    tunnelIndeA, boolOutOfTunnel = deployTunnel(tunnelTableA, tunnelIndexA, distanceTunnel)
                    tunnelIndexB, boolOutOfTunnel = deployTunnel(tunnelTableB, tunnelIndexB, distanceTunnel)
                    if boolOutOfTunnel  then return end                    
            	end
            end
        	boolOldState = boolAboveGround
        end
end

function buildTrain(nr)
    assert(TablesOfPiecesGroups["Train"][nr],nr)
    Show(TablesOfPiecesGroups["Train"][nr])
    showT(TablesOfPiecesGroups["Train"..nr.."sub"])
    return TablesOfPiecesGroups["Train"][nr]
end

function hideTrain(nr)
    assert(TablesOfPiecesGroups["Train"][nr],nr)
	Hide(TablesOfPiecesGroups["Train"][nr])
    reset(TablesOfPiecesGroups["Train"][nr], 0)
    hideT(TablesOfPiecesGroups["Train"..nr.."sub"])        
end

function forth(direction)
    while true do        
        train = buildTrain(3)
        WMove(train, trainAxis, maxDistanceTrain*direction, 0)
        WMove(train, trainAxis, 0, trainspeed)    
        breakTime = math.random(0,10)*1000
        Sleep(breakTime)
        hideTrain(3)
        train = buildTrain(1)
        WMove(train, trainAxis, maxDistanceTrain*direction*-1, trainspeed)
        hideTrain(1)
    end
end

function forth(direction)
    while true do        
        train = buildTrain(2)
        WMove(train, trainAxis,  maxDistanceTrain*direction*-1, 0)
        WMove(train, trainAxis, 0, trainspeed)    
        breakTime = math.random(0,10)*1000
        Sleep(breakTime)
        hideTrain(2)
        train = buildTrain(4)
        WMove(train, trainAxis,maxDistanceTrain*direction, trainspeed)
        hideTrain(4)
    end
end


function trainLoop()
    while (countUp < 2) do Sleep(100) end
    deployTunnels(1, 1)    
    deployTunnels(3, -1)   
    direction = randSign()
	StartThread(back, direction)
    StartThread(forth, direction)
end


function script.Killed(recentDamage, _)
    return 1
end
