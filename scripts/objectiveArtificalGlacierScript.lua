include "createCorpse.lua"
include "lib_OS.lua"
include "lib_UnitScript.lua"
include "lib_Animation.lua"
include "lib_Build.lua"
include "lib_mosaic.lua"

TablesOfPiecesGroups = {}
BasePlate = piece "BasePlate"
Irrigation1 = piece "Irrigation1"
GameConfig = getGameConfig()
gaiaTeamID = Spring.GetGaiaTeamID()
local houseTypeTable = getCultureUnitModelNames(GameConfig.instance.culture,
                                                "house", UnitDefs)
--assert(houseTypeTable)
Piston = piece"Piston"
PistonHeigth = 6500
hours, minutes, seconds, percentage = getDayTime()

function trackEnergyConsumption()
    while true do
            hours, minutes, seconds, percentage = getDayTime()
            if percent < 0.5 then percent = 1-0.5 end
            result = (1.0 - percent)*-1
            result = result*PistonHeigth
            WMove(Piston,z_axis, result, 100.1)

        Sleep(1000)
    end
end

function script.Create()
    Spring.SetUnitBlocking(unitID,false)
    TablesOfPiecesGroups = getPieceTableByNameGroups(false, true)

    resetAll(unitID)
    Spin(piece("Logo"), z_axis, math.rad(42), 0)
    hideT(TablesOfPiecesGroups["HyperLoop"])
    Hide(Irrigation1)

    StartThread(deployPipes)
    StartThread(dependingOnDayTimeFoldUnfold)
    StartThread(trackEnergyConsumption)
end

boolUnfolded = false
function dependingOnDayTimeFoldUnfold()
    heading = Spring.GetUnitHeading(unitID)/16384
    Sleep(10)
    hours, minutes, seconds, percentage = getDayTime()
    while true do
        if hours > 5 and hours < 20 and boolUnfolded == false then
            boolUnfolded = true
            unfold()
        end

        if hours > 19 and boolUnfolded == true then
            fold()
            degree = (0.25 * 180) -  heading* 90
            WTurn(BasePlate, y_axis, math.rad(degree), math.pi / 500)
            boolUnfolded = false
        end

        if percentage > 0.25 and percentage < 0.70 then
            percentage = (percentage - 0.25) / 0.5
            degree = (percentage * 180) +  heading* 90
            Turn(BasePlate, y_axis, math.rad(degree), math.pi / 5000)
        end

    Sleep(1000)
    end
end

function unfold()
    WTurn(TablesOfPiecesGroups["Solar"][4], x_axis, math.rad(-181 ), 1)
    WTurn(TablesOfPiecesGroups["Solar"][4], x_axis, math.rad(-181 + 45), 1)
    WTurn(TablesOfPiecesGroups["Solar"][3], x_axis, math.rad(181), 1)
    WTurn(TablesOfPiecesGroups["Solar"][3], x_axis, math.rad(181 + 45), 1)
    WTurn(TablesOfPiecesGroups["Solar"][2], z_axis, math.rad(-181), 1)
    WTurn(TablesOfPiecesGroups["Solar"][1], z_axis, math.rad(181), 1)
    Turn(TablesOfPiecesGroups["Solar3Ext"][1], z_axis, math.rad(179), 1)
    Turn(TablesOfPiecesGroups["Solar4Ext"][1], z_axis, math.rad(179), 1)
    WaitForTurns(TablesOfPiecesGroups["Solar3Ext"][1], TablesOfPiecesGroups["Solar4Ext"][1])
    Turn(TablesOfPiecesGroups["Solar3Ext"][2], z_axis, math.rad(-179), 1)
    Turn(TablesOfPiecesGroups["Solar4Ext"][2], z_axis, math.rad(-179), 1)
    WaitForTurns(TablesOfPiecesGroups["Solar3Ext"][2], TablesOfPiecesGroups["Solar4Ext"][2])
end

function fold()
    Turn(TablesOfPiecesGroups["Solar4Ext"][2], z_axis, math.rad(0), 1)
    Turn(TablesOfPiecesGroups["Solar3Ext"][2], z_axis, math.rad(0), 1)
    WaitForTurns(TablesOfPiecesGroups["Solar3Ext"][2], TablesOfPiecesGroups["Solar4Ext"][2])
    Turn(TablesOfPiecesGroups["Solar3Ext"][1], z_axis, math.rad(0), 1)
    Turn(TablesOfPiecesGroups["Solar4Ext"][1], z_axis, math.rad(0), 1)
    WaitForTurns(TablesOfPiecesGroups["Solar3Ext"][1], TablesOfPiecesGroups["Solar4Ext"][1])
    WTurn(TablesOfPiecesGroups["Solar"][1], z_axis, math.rad(0), 1)
    WTurn(TablesOfPiecesGroups["Solar"][2], z_axis, math.rad(0), 1)
    WTurn(TablesOfPiecesGroups["Solar"][3], x_axis, math.rad(0), 1)
    WTurn(TablesOfPiecesGroups["Solar"][3], x_axis, math.rad(0), 1)
    WTurn(TablesOfPiecesGroups["Solar"][4], x_axis, math.rad(0), 1)
    WTurn(TablesOfPiecesGroups["Solar"][4], x_axis, math.rad(0), 1)
end

function script.Killed(recentDamage, _) return 1 end

function outsideMap(pieces)
    assert(pieces)
    x, y, z = Spring.GetUnitPiecePosDir(unitID, pieces)
    if x < 0 or x > Game.mapSizeX or z < 0 or z > Game.mapSizeZ then
        return true
    end
    return false
end

function deployPipes()
    Sleep(5000)
    forInterval(1, #TablesOfPiecesGroups["HyperLoop"], Irrigation1, 1)
end

function isLevel(x,y,z)
    offSet ={}
    total =0
    for o=1,3 do
        for i=1,3 do
            total= total+1
            offSet[total] ={}
            if o== 1 then
                offSet[total].x = 1
            elseif o == 2 then
                offSet[total].x = 0
            elseif o == 3 then
                offSet[total].x = -1
            end

             if i == 1 then
                offSet[total].z = 1
            elseif i == 2 then
                offSet[total].z = 0
            elseif i == 3 then
                offSet[total].z = -1
            end
        end
    end

    minHeight = math.huge
    maxHeight = -math.huge
    for i=1, #offSet do
        height = Spring.GetGroundHeight(x + offSet[i].x * 300, y, z+ offSet[i].z * 300)
        minHeight = math.min(minHeight,height)
        maxHeight = math.max(maxHeight,height)
    end

    difference = math.abs(maxHeight - minHeight)

    return difference < 50, difference
end


function forInterval(start, stop, irrigation, nr)
    offset = 5
    discoverSign = randSign()
    rotationValue = (math.random(-8 * nr, 8 * nr) + nr) * 45
    attempts = 0
    goodPlaceToFarm = false
    mostLevel = {}
    while (goodPlaceToFarm == false and attempts < 10) do
        WTurn(TablesOfPiecesGroups["HyperLoop"][start], y_axis, math.rad(rotationValue), 0)
        rotationValue = rotationValue + 45 * discoverSign
        attempts = attempts + 1
        Sleep(1)

        x, y, z = Spring.GetUnitPiecePosDir(unitID, irrigation)
        HousesHousesHouses = process(
                getAllInCircle(x, z, 450), 
            function(id)
            if houseTypeTable[Spring.GetUnitDefID(id)] then return id end
            end
            )
        boolIsLevel, levelValue = isLevel(x,y,z)
        mostLevel[rotationValue] = levelValue
        goodPlaceToFarm = outsideMap(irrigation) == false and count(HousesHousesHouses) == 0 and boolIsLevel == true
    end

    if attempts >= 10 then
       -- echo("objectiveArtificalGlacierScript.lua:: Over 10 Attempts")
        smallestDiff = math.huge
        rotations = math.random(1,360)
        for rot, val in pairs(mostLevel) do
            if val < smallestDiff then 
                smallestDiff = val
                rotations = rot
            end 
        end
         WTurn(TablesOfPiecesGroups["HyperLoop"][start], y_axis, math.rad(rotations), 0)
    end

    accumulateddeg = 0
    showTable = {}
    for i = start, stop do
        if i ~= stop and TablesOfPiecesGroups["HyperLoop"][i + 1] then
            nextElement = TablesOfPiecesGroups["HyperLoop"][i + 1]
        else
            nextElement = irrigation
        end

        boolIsAboveGround = false
        val = 0
        counter = 0
        while boolIsAboveGround == false and counter < 25 do
            x, y, z = Spring.GetUnitPiecePosDir(unitID, nextElement)
            gh = Spring.GetGroundHeight(x, z)
            counter = counter + 1

            if y > gh + offset then
                val = val - 1
                accumulateddeg = accumulateddeg - 1
            elseif y < gh + offset then
                val = val + 1
                accumulateddeg = accumulateddeg + 1
            end

            if (x < 0 or x > Game.mapSizeX or z < 0 or z > Game.mapSizeZ) ==
                false then showTable[#showTable + 1] = nextElement end

            WTurn(TablesOfPiecesGroups["HyperLoop"][i], x_axis, math.rad(val), 0)
        end
    end

    accumulateddeg = accumulateddeg * -1
    WTurn(irrigation, x_axis, math.rad(accumulateddeg), 0)
    showT(showTable)
    x, y, z = Spring.GetUnitPiecePosDir(unitID, Irrigation1)
    GG.UnitsToSpawn:PushCreateUnit("objective_irrigationfarming", x, y, z,
                                   math.random(1, 4), gaiaTeamID)
    hideSensors(1)
end

function hideSensors(nr)
    Hide(Irrigation1)
end
