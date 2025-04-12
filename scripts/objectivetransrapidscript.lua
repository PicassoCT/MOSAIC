include "createCorpse.lua"
include "lib_OS.lua"
include "lib_UnitScript.lua"
include "lib_Animation.lua"


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
gaiaTeamId = Spring.GetGaiaTeamID()

function script.Create()
    TablesOfPiecesGroups = getPieceTableByNameGroups(false, true)
    hideAll(unitID)
    StartThread(setup)
end

semaphore= 0

function airPortConnection()
    x,y,z =Spring.GetUnitPosition(unitID)
    airPortDefId = UnitDefNames["objective_airport"].id
    allAirPorts = Spring.GetTeamUnitsByDefs ( gaiaTeamId, airPortDefId)
    if count(allAirPorts) > 0 then
        ax,ay,az = Spring.GetUnitPosition(allAirPorts[1])
        rDeg = math.atan2(x-ax,z-az)
        ninetyDeg = math.pi/2
        assert(center)
        WTurn(center, y_axis, rDeg + ninetyDeg ,0)
        echo("objective_transrapid is airport connected")
    else
        rVal = math.random(0, 360)
        WTurn(center, y_axis, math.rad(rVal),0)
    end
end


function setup()
    airPortConnection()
    Sleep(10)
    Show(center)
    StartThread(trainLoop, 1)
    StartThread(trainLoop, 2)

 
    StartThread(deployTrack, 25, -25,  rail1,  TablesOfPiecesGroups["Rail1Sub"] , sub1, piece("EndPoint1"))
    StartThread(deployTrack, 25, -25,  rail2,  TablesOfPiecesGroups["Rail2Sub"] , sub2, piece("EndPoint2"))
    StartThread(trainLoop)
    foreach(TablesOfPiecesGroups["Add"],
            function(id)
                if maRa() then Show(id) end
            end
            )
end

function deployTrack( upStart, downEnd, railP, Pillars, detectorPiece, endPoint)
    assert(railP)
    assert(detectorPiece)
    assert(endPoint)
    assert(Pillars)
    upValue = 25

    upDownAxis =  z_axis
    smallestDiffYet = math.huge
    degDiff = 0
    assert(railP)
    WTurn(railP, upDownAxis, math.rad(upStart), 0)
    Hide(endPoint)
    Hide(detectionPiece)
    Show(railP)
    for i= upStart, downEnd, -1 do
       WTurn(railP, upDownAxis, math.rad(i), 0)
       boolIsVisible, diff = isStationVisible(endPoint, detectorPiece)
       if boolIsVisible and  diff >= 0 and diff < smallestDiffYet then
        smallestDiffYet = diff
        degDiff = i
       end
   end
    WTurn(railP, upDownAxis, math.rad(degDiff), 0)
    boolIsVisible, diff = isStationVisible(endPoint, detectorPiece)
    if boolIsVisible then     
               
            WTurn(endPoint, upDownAxis, math.rad(-degDiff), 0)
            foreach(Pillars,
                    function(id)
                        Show(id)
                        assert(id)
                        if id then
                            WTurn(id, upDownAxis, math.rad(-degDiff), 0)
                        end
                    end
                    )
            Show(endPoint)
    end

    semaphore= semaphore +1
end

function isAboveGround(pieceName)
    x,y,z = Spring.GetUnitPiecePosDir(unitID, pieceName)
    gh = Spring.GetGroundHeight(x,z)
    boolUnderground =  gh + 10 > y or gh < 0
    return boolUnderground, x,y,z
end


function isStationVisible( EndPiece, DetectorPiece)
    boolUnderground,x,y,z =  isAboveGround(DetectorPiece)
    groundHeight = Spring.GetGroundHeight(x,z)
    boolOutsideMap = (x > Game.mapSizeX or x <= 0) or  (z > Game.mapSizeZ or z <= 0)
    return boolUnderground or boolOutsideMap, y - groundHeight
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

--
function deployTunnels(detectionPiece, dirSign, tunnelTable)
    boolOldState = false
    Sleep(50)
    Hide(detectionPiece)
    hideT(tunnelTable)
    tunnelIndex = 1
    local xMax = Game.mapSizeX 
    local zMax = Game.mapSizeZ 
    Hide(detectionPiece)
        for distanceTunnel = 0, maxDistanceTrain* dirSign, 32* dirSign do
        	WMove(detectionPiece,trainAxis, distanceTunnel, 0)
        	boolAboveGround,x, z = isPieceAboveGround(unitID, detectionPiece, 0)
            if not (not x or not z or  x  <= 0 or x >= xMax or z <= 0 or z >= zMax) then
            --Spring.Echo("Checking tunnel "..nr.." for"..distanceTunnel)
            	if detectRisingEdge(boolAboveGround) or detectFallingEdge(boolAboveGround) then
                    tunnelIndex, boolOutOfTunnel = deployTunnel(tunnelTable, tunnelIndex, distanceTunnel)
                    if boolOutOfTunnel then return end                    
            	end
            end
        	boolOldState = boolAboveGround
        end
end

function buildTrain(nr)
    Show(TablesOfPiecesGroups["Train"][nr])
    showT(TablesOfPiecesGroups["Train"..nr.."Sub"])
    return TablesOfPiecesGroups["Train"][nr]
end

function hideTrain(nr)
    Hide(TablesOfPiecesGroups["Train"][nr])
    reset(TablesOfPiecesGroups["Train"][nr], 0)
    hideT(TablesOfPiecesGroups["Train"..nr.."Sub"])        
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

function back(direction)
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
    while (semaphore < 2) do Sleep(100) end
    deployTunnels(piece("TunnelDetectionPlus") , 1, TablesOfPiecesGroups["TunnelPlus"])    
    deployTunnels(piece("TunnelDetectionMinus") , -1, TablesOfPiecesGroups["TunnelMinus"])   
    direction = randSign()
    StartThread(back, direction)
    StartThread(forth, direction)
end

function script.Killed(recentDamage, _)
    return 1
end
