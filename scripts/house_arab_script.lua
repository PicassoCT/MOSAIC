include "createCorpse.lua"
include "lib_OS.lua"
include "lib_UnitScript.lua"
include "lib_Animation.lua"
include "lib_Build.lua"
include "lib_mosaic.lua"

local myDefID = Spring.GetUnitDefID(unitID)
TablesOfPiecesGroups = {}
local cubeDim = {
    length = 14.4 * 1.45,
    heigth = 13.65 * 0.75 * 1.45,
    roofHeigth = 2
}
supriseChances = {
    roof = 0.5,
    yard = 0.6,
    yardwall = 0.4,
    street = 0.5,
    powerpoles = 0.5,
    door = 0.6,
    windowwall = 0.7,
    streetwall = 0.5
}
boringChances = {
    roof = 0.2,
    yard = 0.1,
    yardwall = 0.4,
    street = 0.1,
    powerpoles = 0.5,
    door = 0.6,
    windowwall = 0.5,
    streetwall = 0.1
}

agrarianFeatureTypeTable = getAgrarianAreaFeatureUnits(UnitDefs)
decoChances = boringChances
x, y, z = Spring.GetUnitPosition(unitID)
geoHash = (x - (x - math.floor(x))) + (y - (y - math.floor(y))) +
              (z - (z - math.floor(z)))
-- Spring.Echo("House geohash:"..geoHash)
if geoHash % 3 == 1 then decoChances = supriseChances end
centerP = {x = (cubeDim.length / 2) * 5, z = (cubeDim.length / 2) * 5}
ToShowTable = {}

_x_axis = 1
_y_axis = 2
_z_axis = 3

function script.HitByWeapon(x, z, weaponDefID, damage) end

AlreadyUsedPiece = {}
center = piece "center"

pericodicRotationYPieces = {}
pericodicMovingZPieces = {}
spinYPieces = {}
GameConfig = getGameConfig()

function timeOfDay()

    WholeDay = GameConfig.daylength
    timeFrame = Spring.GetGameFrame() + (WholeDay * 0.25)
    -- echo(getDayTime(timeFrame%WholeDay, WholeDay))
    return ((timeFrame % (WholeDay)) / (WholeDay))
end

function script.Create()
    TablesOfPiecesGroups = getPieceTableByNameGroups(false, true)
    x, y, z = Spring.GetUnitPosition(unitID)
    math.randomseed(x + y + z)
    StartThread(buildHouse)

    spinYPieces = {
        TablesOfPiecesGroups["StreetDeco29Sub"][1],
        TablesOfPiecesGroups["RoofDeco32Sub"][1],
        TablesOfPiecesGroups["RoofDeco33Sub"][1],
        TablesOfPiecesGroups["RoofDeco38Sub"][1],
        TablesOfPiecesGroups["RoofDeco30Sub"][1],
        TablesOfPiecesGroups["RoofDeco31Sub"][1]
    }

    pericodicRotationYPieces = {
        [TablesOfPiecesGroups["StreetWallDeco4Sub"][1]] = false,
        [TablesOfPiecesGroups["StreetWallDeco13Sub"][1]] = false,
        [TablesOfPiecesGroups["StreetWallDeco12Sub"][1]] = false,
        [TablesOfPiecesGroups["StreetWallDeco10Sub"][1]] = false,
        [TablesOfPiecesGroups["StreetWallDeco11Sub"][1]] = false,
        [TablesOfPiecesGroups["StreetWallDeco3Sub"][1]] = false,
        [TablesOfPiecesGroups["StreetWallDeco5Sub"][1]] = false
    }
    windsolar = {
        [TablesOfPiecesGroups["RoofDeco"][4]] = false,
        [TablesOfPiecesGroups["RoofDeco"][6]] = false,
        [TablesOfPiecesGroups["RoofDeco"][5]] = false
    }

    pericodicMovingZPieces = {
        [TablesOfPiecesGroups["RoofDeco29Sub"][1]] = 5000,
        [TablesOfPiecesGroups["RoofDeco54Sub"][1]] = 5000,
        [TablesOfPiecesGroups["RoofDeco55Sub"][1]] = 5000,
        [TablesOfPiecesGroups["RoofDeco56Sub"][1]] = 5000
    }

    StartThread(rotations)
    StartThread(decorateCity)
end

function rotations()
    process(spinYPieces, function(id)
        direction = 42 * randSign()
        Spin(id, y_axis, math.rad(direction), math.pi)

    end)

    periodicFunc = function(p)
        while true do
            Sleep(500);
            dir = math.random(-45, 45);
            WTurn(p, _y_axis, math.rad(dir), math.pi / 250);
        end
    end
    for k, v in pairs(pericodicRotationYPieces) do

        StartThread(periodicFunc, k)
    end

    windfunc = function(p)
        while true do
            Sleep(1000)
            percentage = timeOfDay()
            if percentage > 0.25 and percentage < 0.75 then
                percentage = (percentage - 0.25) / 0.5
                degree = (percentage * 180) + math.random(-10, 10)
                Turn(p, _z_axis, math.rad(degree), math.pi / 100)
            else
                TurnTowardsWind(p, math.pi / 100, math.random(-10, 10))
            end
            WaitForTurns(p)
        end
    end

    for k, v in pairs(windsolar) do StartThread(windfunc, k) end
    Sleep(500)
    clockPiece = piece("StreetDeco06")
    if contains(ToShowTable, clockPiece) then
        WTurn(TablesOfPiecesGroups["StreetDeco6Sub"][1], z_axis, math.rad(180),
              0)
        showT(TablesOfPiecesGroups["StreetDeco6Sub"])
        Spin(TablesOfPiecesGroups["StreetDeco6Sub"][1], z_axis, math.rad(3), 10)
        Spin(TablesOfPiecesGroups["StreetDeco6Sub"][2], z_axis, math.rad(36), 10)
    end

    periodicMovementFunc = function(p, value)
        while true do
            Sleep(500);
            Move(p, _x_axis, math.rad(value), 5);
            WaitForMoves(p)
            Move(p, _x_axis, math.rad(0), 5);
            WaitForMoves(p)
        end
    end

    for k, v in pairs(pericodicMovingZPieces) do
        StartThread(periodicMovementFunc, k, v)

    end

end

function buildHouse()
    resetAll(unitID)
    hideAll(unitID)
    Sleep(1)

    buildBuilding()
    StartThread(showPowerPoles)
end

function absdiff(value, compval)
    if value < compval then return math.abs(compval - value) end
    return math.abs(value - compval)
end

function showPowerPoles()
    Sleep(1000)
    if chancesAre(10) < decoChances.powerpoles then return end

    -- Turn till detecting another house
    local spGetUnitDefID = Spring.GetUnitDefID
    local houseTypeTable = getCultureUnitModelTypes(GameConfig.instance.culture,
                                                    "house", UnitDefs)

    local resultDeg

    teamID = Spring.GetUnitTeam(unitID)
    boolBreakOuter = false
    startHeigth = getUnitGroundHeigth(unitID)

    start = math.random(0, 360)
    for i = start, start + 360, 6 do
        WTurn(TablesOfPiecesGroups["PowerPole"][1], z_axis, math.rad(i), 0)
        Sleep(1)
        for p = 1, #TablesOfPiecesGroups["PowerPole"], 1 do
            x, _, z = Spring.GetUnitPiecePosDir(unitID,
                                                TablesOfPiecesGroups["PowerPole"][p])

            if x then
                unitsNearPole = getAllInCircle(x, z, 90, unitID, teamID)
                boolFinishFunction = false
                process(unitsNearPole, function(id)
                    -- found a 
                    if id and id ~= unitID and
                        houseTypeTable[spGetUnitDefID(id)] then
                        for l = 1, p do
                            pieceID = TablesOfPiecesGroups["PowerPole"][l]

                            thisHeigth = getGroundHeigthAtPiece(unitID, pieceID)
                            diff = absdiff(startHeigth, thisHeigth)
                            if diff < 100 and
                                isPieceAboveGround(unitID, pieceID) == true then
                                Show(pieceID)
                            else
                                boolFinishFunction = true
                                break
                            end
                        end
                        boolFinishFunction = true
                    end
                end)
                if boolFinishFunction == true then return end
            end
        end
    end

end

function script.Killed(recentDamage, _)
    -- createCorpseCUnitGeneric(recentDamage)
    return 1
end

function showOne(T, bNotDelayd)
    if not T then return end
    dice = math.random(1, count(T))
    c = 0
    for k, v in pairs(T) do
        if k and v then c = c + 1 end
        if c == dice then
            if bNotDelayd and bNotDelayd == true then
                Show(v)
            else
                ToShowTable[#ToShowTable + 1] = v
            end
            return v
        end
    end
end

function showOneOrNone(T)
    if not T then return end
    if math.random(1, 100) > 50 then
        return showOne(T, true)
    else
        return
    end
end

function showOneOrAll(T)
    if not T then return end
    if chancesAre(10) > 0.5 then
        return showOne(T)
    else
        for num, val in pairs(T) do ToShowTable[#ToShowTable + 1] = val end
        return
    end
end

function selectBase() showOne(TablesOfPiecesGroups["base"], true) end

function selectBackYard() showOneOrNone(TablesOfPiecesGroups["back"]) end

function removeElementFromBuildMaterial(element, buildMaterial)

    local result = process(buildMaterial,
                           function(id) if id ~= element then return id end end)
    return result
end

function selectGroundBuildMaterial()
    diceTable = {"", "Brown", "White", "Red"}
    x, y, z = Spring.GetUnitPosition(unitID)
    x, z = math.ceil(x / 1000), math.ceil(z / 1000)
    nice = ((x + z) % (#diceTable) + 1)
    if not nice then nice = 1 end
    dice = diceTable[nice]

    return dice
end

function decorateCity()
    Sleep(1000)
    marketResearch()

end

local gaiaTeamID = Spring.GetGaiaTeamID()
function marketResearch()
    if not GG.HouseDecoration_Arab_MarketCounter then  GG.HouseDecoration_Arab_MarketCounter = 0 end
    if  GG.HouseDecoration_Arab_MarketCounter > 2 then return end
   
    x,y,z = Spring.GetUnitPosition(unitID)
    housesNearby = 0
    process(getAllInCircle(x,z, 400),
        function(id)
            if Spring.GetUnitDefID(id) == myDefID and id ~= unitID then
                housesNearby = housesNearby +1
            end
        end
        )

    if housesNearby > 4 then
         GG.HouseDecoration_Arab_MarketCounter =  GG.HouseDecoration_Arab_MarketCounter +1
         minDeg =math.random (0,360)
         maxDeg = minDeg + 120
        for i=1, math.random(3,6) do
            createUnitInCircleAroundUnit(unitID,"marketstand_arab", math.random(200,500), minDeg, maxDeg)
        end
    end

    if not GG.HouseDecoration_Arab_FarmDecoration then  GG.HouseDecoration_Arab_FarmDecoration = 0 end
    if  GG.HouseDecoration_Arab_MarketCounter > 5 then return end

    if housesNearby < 2 then
    GG.HouseDecoration_Arab_FarmDecoration =  GG.HouseDecoration_Arab_FarmDecoration +1
         minDeg =math.random (0,360)
         maxDeg = minDeg + 120
        for i=1, math.random(2,5) do
            if maRa()== true then
             createUnitInCircleAroundUnit(unitID,"tree_arab0", math.random(200,500), minDeg, maxDeg)
            else
             createUnitInCircleAroundUnit(unitID,"tree_arab1", math.random(200,500), minDeg, maxDeg)
            end
        end
    end
end

    function createUnitInCircleAroundUnit(id, typeToCreateDefID, distanceToMove,  minDeg, maxDeg)
        px,py,pz = Spring.GetUnitPosition(id)
        degs= math.random(minDeg, maxDeg)
        rx,rz = Rotate(0,distanceToMove, math.rad(degs))

        px, pz = px + rx, pz +rz
        gh= Spring.GetGroundHeight(px,pz)
        if gh > 10 and absDistance(gh,py)  < 30 then
            GG.UnitsToSpawn:PushCreateUnit(typeToCreateDefID, px, gh, pz, math.random(0,4), gaiaTeamID)
        end
    end

function getPieceGroupName(Deco)
    t = Spring.GetUnitPieceInfo(unitID, Deco)

    return t.name:gsub('%d+', '')
end

function DecorateBlockWall(xRealLoc, zRealLoc, level, DecoMaterial, yoffset)
    countedElements = count(DecoMaterial)
    piecename = ""
    if countedElements <= 0 then return DecoMaterial end

    y_offset = yoffset or 0
    attempts = 0
    local Deco, nr = getRandomBuildMaterial(DecoMaterial)
    while not Deco and attempts < countedElements do
        Deco, nr = getRandomBuildMaterial(DecoMaterial)
        Sleep(1)
        attempts = attempts + 1
    end

    if attempts >= countedElements then return DecoMaterial end

    if Deco then
        DecoMaterial = removeElementFromBuildMaterial(Deco, DecoMaterial)
        Move(Deco, _x_axis, xRealLoc, 0)
        Move(Deco, _y_axis, level * cubeDim.heigth + y_offset, 0)
        Move(Deco, _z_axis, zRealLoc, 0)

        ToShowTable[#ToShowTable + 1] = Deco
        piecename = getPieceGroupName(Deco)
    end

    if TablesOfPiecesGroups[piecename .. nr .. "Sub"] then
        showOneOrAll(TablesOfPiecesGroups[piecename .. nr .. "Sub"])
    end

    return DecoMaterial, Deco
end

function getRandomBuildMaterial(buildMaterial)

    if not buildMaterial then return end
    if not type(buildMaterial) == "table" then return end
    total = count(buildMaterial)
    if total == 0 then return end

    dice = math.random(1, total)
    total = 0
    for num, piecenum in pairs(buildMaterial) do
        if (not AlreadyUsedPiece[piecenum] and type(num) == "number" and
            type(piecenum) == "number") then
            total = total + 1
            if total == dice then
                AlreadyUsedPiece[piecenum] = true
                return piecenum, num
            end
        end
    end
end

-- x:0-6 z:0-6
function getLocationInPlan(index)

    if index < 7 then return true, (index - 1), 0 end

    if index > 30 and index < 37 then return true, ((index - 30) - 1), 5 end

    if (index % 6) == 1 and (index < 37 and index > 6) then
        return true, 0, math.floor((index - 1) / 6.0)
    end

    if (index % 6) == 0 and (index < 37 and index > 6) then
        return true, 5, math.floor((index - 1) / 6.0)
    end

    return false, 0, 0
end

function isBackYardWall(index)
    if index == 1 or index == 6 or index == 31 or index == 36 then
        return false
    end

    if index > 1 and index < 6 then return true end

    if index > 31 and index < 36 then return true end

    if (index % 6) == 0 or (index % 6) == 1 and not (index > 31 and index < 36) and
        not (index > 1 and index < 6) then return true end

    return false
end

function getWallBackyardDeocrationRotation(index)
    if index == 1 or index == 6 or index == 31 or index == 36 then return 0 end

    if index > 1 and index < 6 then return 270 end

    if index > 31 and index < 36 then return 90 end

    if (index % 6) == 0 then return 180 end

    if (index % 6) == 1 then return 0 end

    return 0
end

function getOutsideFacingRotationOfBlockFromPlan(index)

    if (index > 30 and index < 37) then
        if (index == 31) then return 270 - math.random(0, 1) * 90 end

        if (index == 36) then return 270 + math.random(0, 1) * 90 end

        return 270
    end

    if (index > 0 and index < 7) then
        if (index == 1) then return 90 + math.random(0, 1) * 90 end

        if (index == 6) then return 90 - math.random(0, 1) * 90 end

        return 90
    end

    if ((index % 6) == 1 and (index < 31 and index > 6)) then return 180 end

    if ((index % 6) == 0 and (index < 31 and index > 6)) then return 0 end

    return 0
end

function getStreetWallDecoRotation(index)
    offset = 180

    if (index > 30 and index < 37) then
        if (index == 31) then return offset + 90 - math.random(0, 1) * 90 end

        if (index == 36) then return offset + 90 + math.random(0, 1) * 90 end

        return offset + 90
    end

    if (index > 0 and index < 7) then
        if (index == 1) then return offset + 270 + math.random(0, 1) * 90 end

        if (index == 6) then return offset + 270 - math.random(0, 1) * 90 end

        return offset + 270
    end

    if ((index % 6) == 1 and (index < 31 and index > 6)) then
        return offset + 0
    end

    if ((index % 6) == 0 and (index < 31 and index > 6)) then
        return offset + 180
    end

    return offset
end

function getElasticTable(...)
    local arg = arg;
    if (not arg) then arg = {...} end
    resulT = {}
    for _, searchterm in pairs(arg) do
        for k, v in pairs(TablesOfPiecesGroups) do
            if string.find(string.lower(k), string.lower(searchterm)) and
                string.find(string.lower(k), "sub") == nil and
                string.find(string.lower(k), "_ncl1_") == nil then
                if TablesOfPiecesGroups[k] then
                    for num, piecenum in pairs(TablesOfPiecesGroups[k]) do
                        resulT[#resulT + 1] = piecenum
                    end
                end
            end
        end
    end

    return resulT
end

function getElasticTableDebugCopy(...)
    local arg = arg;
    if (not arg) then arg = {...} end
    resulT = {}
    for k, searchterm in pairs(arg) do
        if type(searchterm) == "string" then
            for k, v in pairs(TablesOfPiecesGroups) do
                s = "Searching for " .. string.lower(searchterm) .. " in " ..
                        string.lower(k)
                if string.find(string.lower(k), string.lower(searchterm)) and
                    string.find(string.lower(k), "sub") == nil and
                    string.find(string.lower(k), "_ncl1_") == nil then
                    -- Spring.Echo (s.." with succes")
                    if TablesOfPiecesGroups[k] then
                        for num, piecenum in pairs(TablesOfPiecesGroups[k]) do
                            -- Spring.Echo("Adding "..k.." "..num)
                            resulT[#resulT + 1] = piecenum
                        end
                    end
                else
                    Spring.Echo(s .. " failing")
                end
            end
        end
    end
    return resulT
end

function buildDecorateGroundLvl()
    Sleep(1)

    local StreetDecoMaterial = getElasticTable("Street")
    local DoorMaterial = TablesOfPiecesGroups["Door"]
    local DoorDecoMaterial = TablesOfPiecesGroups["DoorDeco"]
    local yardMaterial = getElasticTable("Yard")

    materialColourName = selectGroundBuildMaterial()
    materialGroupName = materialColourName .. "FloorBlock"
    buildMaterial = TablesOfPiecesGroups[materialGroupName]

    countElements = 0

    for i = 1, 37, 1 do
        Sleep(1)

        local index = i
        rotation = getOutsideFacingRotationOfBlockFromPlan(index)
        partOfPlan, xLoc, zLoc = getLocationInPlan(index)

        if partOfPlan == true then
            xRealLoc, zRealLoc = -centerP.x + (xLoc * cubeDim.length),
                                 -centerP.z + (zLoc * cubeDim.length)
            local element, nr = getRandomBuildMaterial(buildMaterial)
            while not element do
                element, nr = getRandomBuildMaterial(buildMaterial)
                Sleep(1)
            end

            if element then

                countElements = countElements + 1
                buildMaterial = removeElementFromBuildMaterial(element,
                                                               buildMaterial)
                Move(element, _x_axis, xRealLoc, 0)
                Move(element, _z_axis, zRealLoc, 0)
                ToShowTable[#ToShowTable + 1] = element

                if countElements == 24 then
                    return materialColourName
                end

                if chancesAre(10) < decoChances.street then
                    rotation = getOutsideFacingRotationOfBlockFromPlan(index)
                    StreetDecoMaterial, StreetDeco =
                        DecorateBlockWall(xRealLoc, zRealLoc, 0,
                                          StreetDecoMaterial, 0)
                    Turn(StreetDeco, 3, math.rad(rotation), 0)

                end

                if chancesAre(10) < decoChances.door then
                    axis = _z_axis
                    DoorMaterial, Door =
                        DecorateBlockWall(xRealLoc, zRealLoc, 0, DoorMaterial, 0)
                    Turn(Door, axis, math.rad(rotation), 0)
                    if chancesAre(10) < decoChances.door then
                        DoorDecoMaterial, DoorDeco =
                            DecorateBlockWall(xRealLoc, zRealLoc, 0,
                                              DoorDecoMaterial)
                        if DoorDeco then
                            Turn(DoorDeco, axis, math.rad(rotation), 0)
                        end
                    end
                end
            end

        end

        if isBackYardWall(index) == true then
            -- BackYard

            if chancesAre(10) < decoChances.yard then
                rotation = getWallBackyardDeocrationRotation(index)
                yardMaterial, yardDeco =
                    decorateBackYard(index, xLoc, zLoc, yardMaterial, 0)
                if yardDeco then
                    Turn(yardDeco, _z_axis, math.rad(rotation), 0)
                end
            end
        end
    end

    return materialColourName
end

function chancesAre(outOfX) return (math.random(0, outOfX) / outOfX) end

function buildDecorateLvl(Level, materialGroupName, buildMaterial)
    Sleep(1)
    local WindowWallMaterial = getElasticTable("Window") -- getElasticTable( "Window")--"Wall",
    local yardMaterial = getElasticTable("YardWall")
    local streetWallMaterial = getElasticTable("StreetWall")

    countElements = 0

    for i = 1, 37, 1 do
        Sleep(1)
        local index = i
        rotation = getOutsideFacingRotationOfBlockFromPlan(i)

        partOfPlan, xLoc, zLoc = getLocationInPlan(index)
        xRealLoc, zRealLoc = xLoc, zLoc
        if partOfPlan == true then
            xRealLoc, zRealLoc = -centerP.x + (xLoc * cubeDim.length),
                                 -centerP.z + (zLoc * cubeDim.length)
            local element, nr = getRandomBuildMaterial(buildMaterial)
            while not element do
                element, nr = getRandomBuildMaterial(buildMaterial)
                Sleep(1)
            end

            if element then

                countElements = countElements + 1
                buildMaterial = removeElementFromBuildMaterial(element,
                                                               buildMaterial)
                Move(element, _x_axis, xRealLoc, 0)
                Move(element, _z_axis, zRealLoc, 0)
                Move(element, _y_axis, Level * cubeDim.heigth, 0)
                WaitForMoves(element)
                Turn(element, _z_axis, math.rad(rotation), 0)
                -- echo("Adding Element to level"..Level)
                ToShowTable[#ToShowTable + 1] = element

                if chancesAre(10) < decoChances.windowwall then
                    rotation = getOutsideFacingRotationOfBlockFromPlan(index)
                    -- echo("Adding Window decoration to"..Level)
                    WindowWallMaterial, WindowDeco =
                        DecorateBlockWall(xRealLoc, zRealLoc, Level,
                                          WindowWallMaterial, 0)
                    Turn(WindowDeco, _z_axis, math.rad(rotation), 0)
                end

                if countElements == 24 then
                    return materialGroupName, buildMaterial
                end
            end

            if chancesAre(10) < decoChances.streetwall and
                count(streetWallMaterial) > 0 then
                assert(type(streetWallMaterial) == "table")
                assert(index)
                assert(xRealLoc)
                assert(zRealLoc)
                --	assert(count(streetWallMaterial) > 0)
                assert(Level)
                assert(streetWallMaterial)

                streetWallMaterial, streetWallDeco =
                    DecorateBlockWall(xRealLoc, zRealLoc, Level,
                                      streetWallMaterial, 0)

                if streetWallDeco then
                    rotation = getStreetWallDecoRotation(index)
                    Turn(streetWallDeco, _y_axis, math.rad(rotation), 0)
                end
            end

        end

        if isBackYardWall(index) == true then
            -- BackYard

            if chancesAre(10) < decoChances.yard and xLoc and zLoc then
                assert(type(yardMaterial) == "table")
                assert(index)

                assert(Level)
                assert(yardMaterial)

                yardMaterial, yardWall =
                    decorateBackYard(index, xLoc, zLoc, yardMaterial, Level)
                assert(type(yardMaterial) == "table")

                if yardWall then
                    rotation = getWallBackyardDeocrationRotation(index)
                    Turn(yardWall, _z_axis, math.rad(rotation), 0)
                end
            end
        end

    end
    -- Spring.Echo("Completed buildDecorateLvl")

    return materialGroupName, buildMaterial
end

function decorateBackYard(index, xLoc, zLoc, buildMaterial, Level)
    countedElements = count(buildMaterial)
    if countedElements == 0 then return buildMaterial end

    local element, nr = getRandomBuildMaterial(buildMaterial)
    attempts = 0
    while not element and attempts < countedElements do
        element, nr = getRandomBuildMaterial(buildMaterial)
        Sleep(1)
        attempts = attempts + 1
    end

    if attempts >= countedElements then return buildMaterial end

    buildMaterial = removeElementFromBuildMaterial(element, buildMaterial)

    -- rotation = math.random(0,4) *90
    xRealLoc, zRealLoc = -centerP.x + (xLoc * cubeDim.length),
                         -centerP.z + (zLoc * cubeDim.length)
    Move(element, _x_axis, xRealLoc, 0)
    Move(element, _z_axis, zRealLoc, 0)
    Move(element, _y_axis, Level * cubeDim.heigth, 0)

    pieceGroupName = getPieceGroupName(element)

    if TablesOfPiecesGroups[pieceGroupName .. nr .. "Sub"] then
        showOneOrAll(TablesOfPiecesGroups[pieceGroupName .. nr .. "Sub"])
    end

    ToShowTable[#ToShowTable + 1] = element

    return buildMaterial, element
end

function addRoofDeocrate(Level, buildMaterial)
    countElements = 0

    for i = 1, 37, 1 do
        local index = i
        partOfPlan, xLoc, zLoc = getLocationInPlan(index)
        if partOfPlan == true then
            xRealLoc, zRealLoc = -centerP.x + (xLoc * cubeDim.length),
                                 -centerP.z + (zLoc * cubeDim.length)
            local element, nr = getRandomBuildMaterial(buildMaterial)
            while not element do
                element, nr = getRandomBuildMaterial(buildMaterial)
                Sleep(1)
            end

            if element then
                rotation = getOutsideFacingRotationOfBlockFromPlan(i)
                countElements = countElements + 1
                buildMaterial = removeElementFromBuildMaterial(element,
                                                               buildMaterial)
                Move(element, _x_axis, xRealLoc, 0)
                Move(element, _z_axis, zRealLoc, 0)
                Move(element, _y_axis, Level * cubeDim.heigth - 0.5, 0)
                WaitForMoves(element)
                Turn(element, _z_axis, math.rad(rotation), 0)
                ToShowTable[#ToShowTable + 1] = element
                if countElements == 24 then break end
            end
        end
    end

    countElements = 0
    local decoMaterial = TablesOfPiecesGroups["RoofDeco"]
    for i = 1, 37, 1 do
        partOfPlan, xLoc, zLoc = getLocationInPlan(i)
        if partOfPlan == true then
            xRealLoc, zRealLoc = -centerP.x + (xLoc * cubeDim.length),
                                 -centerP.z + (zLoc * cubeDim.length)
            local element, nr = getRandomBuildMaterial(decoMaterial)
            while not element do
                element, nr = getRandomBuildMaterial(decoMaterial)
                Sleep(1)
            end

            if element and chancesAre(10) < decoChances.roof then
                rotation = getOutsideFacingRotationOfBlockFromPlan(i)
                countElements = countElements + 1
                decoMaterial = removeElementFromBuildMaterial(element,
                                                              decoMaterial)
                Move(element, _x_axis, xRealLoc, 0)
                Move(element, _z_axis, zRealLoc, 0)
                Move(element, _y_axis,
                     Level * cubeDim.heigth - 0.5 + cubeDim.roofHeigth, 0)
                WaitForMoves(element)
                Turn(element, _z_axis, math.rad(rotation), 0)
                piecename = getPieceGroupName(element)
                if TablesOfPiecesGroups[piecename .. nr .. "Sub"] then
                    showOneOrAll(TablesOfPiecesGroups[piecename .. nr .. "Sub"])
                end
                --

                ToShowTable[#ToShowTable + 1] = element
                if countElements == 24 then return end
            end
        end
    end
end

boolDoneShowing = false

function showHouse() showT(ToShowTable) end

function hideHouse() hideT(ToShowTable) end

function buildAnimation()
    local builT = TablesOfPiecesGroups["Build"]
    axis = _y_axis

    if Spring.GetGameSeconds() < 10 then
        hideT(builT)
        hideT(TablesOfPiecesGroups["Build01Sub"])
        hideT(TablesOfPiecesGroups["BuildCrane"])
        while boolDoneShowing == false do Sleep(100) end
        showT(ToShowTable)

        return
    end

    local builT = TablesOfPiecesGroups["Build"]
    axis = _y_axis
    for i = 1, 3 do WMove(builT[i], axis, i * -cubeDim.heigth * 2, 0) end
    moveT(TablesOfPiecesGroups["Build01Sub"], axis, -60, 0)

    WaitForMoves(TablesOfPiecesGroups["Build01Sub"])
    WaitForMoves(builT)
    showT(builT)
    showT(TablesOfPiecesGroups["Build01Sub"])
    showT(TablesOfPiecesGroups["BuildCrane"])

    moveSyncInTimeT(builT, 0, 0, 0, 5000)
    moveSyncInTimeT(TablesOfPiecesGroups["Build01Sub"], 0, 0, 0, 5000)

    process(TablesOfPiecesGroups["BuildCrane"], function(id)
        craneFunction = function(id)
            while true do
                target = math.random(-120, 120)
                WTurn(id, y_axis, math.rad(target), math.pi / 10)
                Sleep(1000)
            end
        end

        StartThread(craneFunction, id)
    end)

    Sleep(15000)
    while boolDoneShowing == false do Sleep(100) end
    showT(ToShowTable)

    for i = 1, 3 do
        Move(builT[i], _y_axis, i * -cubeDim.heigth * 10, 3 * math.pi)
    end
    moveSyncInTimeT(TablesOfPiecesGroups["Build01Sub"], 0, 0, -1000, 8000)
    moveSyncInTimeT(TablesOfPiecesGroups["BuildCrane"], 0, 0, -1000, 8000)
    Sleep(1000)
    hideT(TablesOfPiecesGroups["BuildCrane"])
    Sleep(7000)
    WaitForMoves(TablesOfPiecesGroups["Build01Sub"])
    WaitForMoves(builT)
    hideT(builT)
    hideT(TablesOfPiecesGroups["Build01Sub"])
    hideT(TablesOfPiecesGroups["BuildCrane"])
end

function buildBuilding()
    StartThread(buildAnimation)
    selectBase()
    selectBackYard()

    materialColourName = buildDecorateGroundLvl()

    buildMaterial = TablesOfPiecesGroups[materialColourName .. "WallBlock"]
    for i = 1, 2 do
        _, buildMaterial = buildDecorateLvl(i,
                                            materialColourName .. "WallBlock",
                                            buildMaterial)
    end

    addRoofDeocrate(3, TablesOfPiecesGroups[materialColourName .. "Roof"])
    boolDoneShowing = true
end

function script.StartMoving() end

function script.StopMoving() end

function script.Activate() return 1 end

function script.Deactivate() return 0 end

function script.QueryBuildInfo() return center end

Spring.SetUnitNanoPieces(unitID, {center})

