include "createCorpse.lua"
include "lib_OS.lua"
include "lib_UnitScript.lua"
include "lib_Animation.lua"
include "lib_Build.lua"

function getScriptName() return "house_europe_script.lua::" end

TablesOfPiecesGroups = {}
factor = 40
heightoffset = 90
local pieceNr_pieceName =Spring.GetUnitPieceList ( unitID ) 
local cubeDim = {
    length = factor * 14.4 * 1.45,
    heigth = factor * 14.84 + heightoffset,
    roofHeigth = 700
}
supriseChances = {
    roof = 0.5,
    yard = 0.6,
    yardwall = 0.4,
    street = 0.5,
    powerpoles = 0.5,
    door = 0.6,
    windowwall = 0.7,
    streetwall = 0.5,
    grafiti = 0.1

}
decoChances = {
    roof = 0.2,
    yard = 0.1,
    yardwall = 0.4,
    street = 0.1,
    powerpoles = 0.5,
    door = 0.6,
    windowwall = 0.5,
    streetwall = 0.1,
    grafiti = 0.3
}

logoPiece = piece("Office_Roof_Deco07")
materialChoiceTable = {"Classic", "Ghetto", "Office", "White"}

vtolDeco= {}
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

GameConfig = getGameConfig()

function timeOfDay()
    WholeDay = GameConfig.daylength
    timeFrame = Spring.GetGameFrame() + (WholeDay * 0.25)
    return ((timeFrame % (WholeDay)) / (WholeDay))
end

BuildDeco = {}

function script.Create()
    TablesOfPiecesGroups = getPieceTableByNameGroups(false, true)
    x, y, z = Spring.GetUnitPosition(unitID)
    math.randomseed(x + y + z)
    StartThread(buildHouse)

        for i=1,5 do
            pericodicRotationYPieces[TablesOfPiecesGroups["_Street_Wall_Deco"..i.."Sub"][1]] = 42
        end

        for i=1,3 do
            pericodicRotationYPieces[TablesOfPiecesGroups["_StreetYard_Wall_Deco"..i.."Sub"][1]] = 42
        end

    vtolDeco = {
        [TablesOfPiecesGroups["ClassicWhiteOffice_Roof_Deco"][1]]=TablesOfPiecesGroups["ClassicWhiteOffice_Roof_Deco1Sub"][1],
        [TablesOfPiecesGroups["ClassicWhiteOffice_Roof_Deco"][3]]=TablesOfPiecesGroups["ClassicWhiteOffice_Roof_Deco3Sub"][1],
        [TablesOfPiecesGroups["ClassicWhiteOffice_Roof_Deco"][5]]=TablesOfPiecesGroups["ClassicWhiteOffice_Roof_Deco5Sub"][1]
    }

    BuildDeco = TablesOfPiecesGroups["BuildDeco"]

    StartThread(rotations)
end

function rotations()


    periodicFunc = function(p, v)
        while true do
            Sleep(500);
            dir = (v*randSign() ) or math.random(-45, 45);
            WTurn(p, _y_axis, math.rad(dir), math.pi / 250);
        end
    end
    for k, v in pairs(pericodicRotationYPieces) do

        StartThread(periodicFunc, k,v)
    end

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
end

function absdiff(value, compval)
    if value < compval then return math.abs(compval - value) end
    return math.abs(value - compval)
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
        for num, val in pairs(T) do 

            ToShowTable[#ToShowTable + 1] = val end
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
    x, y, z = Spring.GetUnitPosition(unitID)
    x, z = math.ceil(x / 1000), math.ceil(z / 1000)
    nice = ((x + z) % (#materialChoiceTable) + 1)
    if not nice then nice = 1 end
    return  materialChoiceTable[nice]
end

function getPieceGroupName(Deco)
    t = Spring.GetUnitPieceInfo(unitID, Deco)
    return t.name:gsub('%d+', '')
end

function DecorateBlockWall(xRealLoc, zRealLoc, level, DecoMaterial, yoffset, materialGroupName)
    countedElements = count(DecoMaterial)
    piecename = ""
    materialGroupName = materialGroupName or "GroupNameUndefined"
    if countedElements <= 0 then return DecoMaterial end

    y_offset = yoffset or 0
    attempts = 0
    local Deco, nr = getRandomBuildMaterial(DecoMaterial, materialGroupName.."blockwall")
    while not Deco and attempts < countedElements do
        Deco, nr = getRandomBuildMaterial(DecoMaterial, materialGroupName.."blockwall")
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

function getRandomBuildMaterial(buildMaterial, name)

    if not buildMaterial then
        echo(getScriptName() .. "getRandomBuildMaterial: Got no table "..name);
        return
    end
    if not type(buildMaterial) == "table" then
        echo(
            getScriptName() .. "getRandomBuildMaterial: Got not a table, got" ..
                type(buildMaterial) .. "instead");
        return
    end
    total = count(buildMaterial)
    if total == 0 and #buildMaterial == 0 then
        echo(getScriptName() .. "getRandomBuildMaterial: Got a empty table "..name)
        return
    end

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
    Spring.Echo(getScriptName() .. "getRandomBuildMaterial: No Part selected ")
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

function nameContainsMaterial(name, materialColourName)
    if not name or name == "" then return true, true end
    boolContainsMaterialName =  (string.find(name, materialColourName) ~= nil)
    boolContainsNoOtherName = true
    local matColour ={
            ["office"]  = true,
            ["white"]   = true,
            ["classic"] = true,
            ["ghetto"]  = true
        }

    matColour[string.lower(materialColourName)] = false
    for k,v in pairs(matColour) do
        if v == true then
         if string.find(name, k) then boolContainsNoOtherName = false end
        end
    end
 
    return boolContainsMaterialName, boolContainsNoOtherName
end

function getMaterialElementsContaingNotContaining(materialColourName, mustContainTable, mustNotContainTable)
    local resultTable = {}
    for nameUp,data in pairs(TablesOfPiecesGroups) do
        local name = string.lower(nameUp)
        if   string.find(name, "sub") == nil and
              string.find(name, "spin")  == nil  then
                boolFullfilledConditions= true
                boolContainsMaterialName, boolContainsNoOtherName =  nameContainsMaterial(name, materialColourName)

                if boolContainsMaterialName or boolContainsNoOtherName then

                for i=1, #mustContainTable do
                    if not string.find(name, string.lower(mustContainTable[i])) then
                        boolFullfilledConditions = false
                        break
                    end  
                end

                if boolFullfilledConditions == true then
                    for j=1, #mustNotContainTable do
                        if string.find(name, string.lower(mustNotContainTable[j])) then
                        boolFullfilledConditions = false
                        break
                        end
                    end

                    if boolFullfilledConditions == true then
                        if type(TablesOfPiecesGroups[nameUp]) == "table" then
                            for h=1, #TablesOfPiecesGroups[nameUp] do
                                resultTable[#resultTable + 1] = TablesOfPiecesGroups[nameUp][h]
                            end
                        else
                          resultTable[#resultTable + 1] = TablesOfPiecesGroups[nameUp]
                        end
                    end
                end
                end
        end
    end
    return resultTable
end

function searchElasticWithoutMaterial(forbiddenMaterial, ...)
    local arg = arg;
    if (not arg) then arg = {...} end
    resulT = {}
    for _, searchterm in pairs(arg) do
        for k, v in pairs(TablesOfPiecesGroups) do
            if string.find(string.lower(k), string.lower(searchterm)) and
                string.find(string.lower(k), "sub") == nil and
                string.find(string.lower(k), "_ncl1_") == nil then
                boolContainsForbiddenWords = false
                for nr, term in pairs(forbiddenMaterial) do
                    if string.find(string.lower(k), string.lower(term)) then
                        boolContainsForbiddenWords = true
                    end              
                end

                if boolContainsForbiddenWords == true then break end

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


function buildDecorateGroundLvl()
    Sleep(1)
    local materialColourName = selectGroundBuildMaterial()
    local StreetDecoMaterial = getMaterialElementsContaingNotContaining(materialColourName, {"Street", "Floor", "Deco"}, {"Door"})
    local DoorMaterial =  getMaterialElementsContaingNotContaining(materialColourName, {"Door"}, {"Deco"})
    local DoorDecoMaterial = getMaterialElementsContaingNotContaining(materialColourName, {"Door","Deco"}, {})
    local yardMaterial = getMaterialElementsContaingNotContaining(materialColourName, {"Yard","Floor", "Deco"}, {"Door"})


    boolHasGrafiti = materialColourName ~= "Office" and chancesAre(10) < decoChances.grafiti or materialColourName == "Ghetto"

    echo("House_europe_Colour:"..materialColourName)
    local buildMaterial = getMaterialElementsContaingNotContaining(materialColourName, {"Block"}, {"Wall"}) 
    assert(buildMaterial)
    assert(#buildMaterial > 0)
    countElements = 0

    for i = 1, 37, 1 do
        Sleep(1)

        local index = i
        echo(getScriptName() .. "buildDecorateGroundLvl" .. i)
        rotation = getOutsideFacingRotationOfBlockFromPlan(index)
        partOfPlan, xLoc, zLoc = getLocationInPlan(index)

        if partOfPlan == true then
            xRealLoc, zRealLoc = -centerP.x + (xLoc * cubeDim.length),
                                 -centerP.z + (zLoc * cubeDim.length)
            local element, nr = getRandomBuildMaterial(buildMaterial, materialColourName )

            while not element do
                element, nr = getRandomBuildMaterial(buildMaterial, materialColourName)

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

                if boolHasGrafiti and chancesAre(10) < 0.5 then 
                    boolHasGrafiti = false
                    addGrafiti(xRealLoc, zRealLoc, math.random(1,4)*90,  _y_axis)
                end

                if chancesAre(10) < decoChances.street then
                    rotation = getOutsideFacingRotationOfBlockFromPlan(index)
                    StreetDecoMaterial, StreetDeco =   DecorateBlockWall(xRealLoc, zRealLoc, 0,
                                          StreetDecoMaterial, 0, materialColourName)
                    if StreetDeco then
                        Turn(StreetDeco, 3, math.rad(rotation), 0)
                    end
                end

                if chancesAre(10) < decoChances.door then
                    axis = _z_axis
                    DoorMaterial, Door = DecorateBlockWall(xRealLoc, zRealLoc, 0, DoorMaterial, 0 , materialColourName)
                    Turn(Door, axis, math.rad(rotation), 0)
                    if chancesAre(10) < decoChances.door then
                        DoorDecoMaterial, DoorDeco =
                            DecorateBlockWall(xRealLoc, zRealLoc, 0,
                                              DoorDecoMaterial, 0, materialColourName)
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
    assert(buildMaterial)
    assert(type(buildMaterial)== "table")
    --assert(#buildMaterial >0 )

    local WindowWallMaterial = getMaterialElementsContaingNotContaining(materialGroupName, {"Window", "Wall"}, {"Deco"})  
    local WindowDecoMaterial = getMaterialElementsContaingNotContaining(materialGroupName, {"Window", "Deco"}, {})  
    local yardMaterial = getMaterialElementsContaingNotContaining(materialGroupName, {"Yard", "Wall"}, {})
    local streetWallMaterial = getMaterialElementsContaingNotContaining(materialGroupName, {"Street", "Wall"}, {})

    if string.lower(materialGroupName) == string.lower("office") then
        WindowWallMaterial = {}
        yardMaterial =  getMaterialElementsContaingNotContaining(materialGroupName, {"Yard", "Wall"}, {"Ghetto"})
    end

    echo(getScriptName() .. count(WindowWallMaterial) .. "|" ..
             count(yardMaterial) .. "|" .. count(streetWallMaterial))

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
            local element, nr = getRandomBuildMaterial(buildMaterial, materialGroupName)

            while not element do
                element, nr = getRandomBuildMaterial(buildMaterial, materialGroupName)
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
 WindowWallMaterial, Window =    DecorateBlockWall(xRealLoc, zRealLoc, Level,  WindowWallMaterial, 0, materialGroupName)
                    if Window then
                        Turn(Window, _z_axis, math.rad(rotation), 0)
                        showSubsAnimateSpinsByPiecename(pieceNr_pieceName[Window])
                    end
                if chancesAre(10) < decoChances.windowwall then
 WindowDecoMaterial, WindowDeco =    DecorateBlockWall(xRealLoc, zRealLoc, Level,  WindowDecoMaterial, 0, materialGroupName)
                    if WindowDeco then
                      Turn(WindowDeco, _z_axis, math.rad(rotation), 0)
                      showSubsAnimateSpinsByPiecename(pieceNr_pieceName[WindowDeco])
                    end

                end

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
                -- assert(count(streetWallMaterial) > 0)
                assert(Level)
                assert(streetWallMaterial)

                streetWallMaterial, streetWallDeco =
                    DecorateBlockWall(xRealLoc, zRealLoc, Level,
                                      streetWallMaterial, 0, materialGroupName)

                if streetWallDeco then
                    rotation = getStreetWallDecoRotation(index)
                    Turn(streetWallDeco, _y_axis, math.rad(rotation), 0)
                    showSubsAnimateSpinsByPiecename(pieceNr_pieceName[streetWallDeco])
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
                    showSubsAnimateSpinsByPiecename(pieceNr_pieceName[yardWall])
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

    local element, nr = getRandomBuildMaterial(buildMaterial, "backyard")
    attempts = 0
    while not element and attempts < countedElements do
        element, nr = getRandomBuildMaterial(buildMaterial, "backyard")
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

    showSubsAnimateSpins(pieceGroupName, nr)

    ToShowTable[#ToShowTable + 1] = element

    return buildMaterial, element
end

function showSubsAnimateSpinsByPiecename(piecename)
     nr = ""
    for i=string.len(piecename), 1, -1 do
        character =  string.sub(piecename, i, i)
        asciiByteValue = string.byte(character)
        if asciiByteValue > 47 and asciiByteValue <58 then
            nr = character..nr
        else
            pieceGroupName = string.sub(piecename,1, i)
            nr = tonumber(nr)
            if string.len(pieceGroupName) > 0 and type(nr) == "number" then
             print(pieceGroupName, nr)
             showSubsAnimateSpins(pieceGroupName, nr)
            end

        break
        end
    end
end

function showSubsAnimateSpins(pieceGroupName, nr)

    if TablesOfPiecesGroups[pieceGroupName .. nr .. "Sub"] then
        showOneOrAll(TablesOfPiecesGroups[pieceGroupName .. nr .. "Sub"])
    end

   if TablesOfPiecesGroups[pieceGroupName .. nr .. "Spin"] then
        showOneOrAll(TablesOfPiecesGroups[pieceGroupName .. nr .. "Spin"])
        direction = math.random(40,160) * randSign()
        Spin(TablesOfPiecesGroups[pieceGroupName .. nr .. "Spin"][1] , y_axis, math.rad(direction), math.pi)
    end
end

function addRoofDeocrate(Level, buildMaterial, materialColourName)
    ----echo(">>>>>>>>>>>>>>>> addRoofDeocrate START ")
    countElements = 0
    if materialColourName == "Office" then
        decoChances.roof = 0.65 
    end

    for i = 1, 37, 1 do
        local index = i
        partOfPlan, xLoc, zLoc = getLocationInPlan(index)
        if partOfPlan == true then
            xRealLoc, zRealLoc = -centerP.x + (xLoc * cubeDim.length),
                                 -centerP.z + (zLoc * cubeDim.length)
            local element, nr = getRandomBuildMaterial(buildMaterial, materialColourName.."roof")
            while not element do
                element, nr = getRandomBuildMaterial(buildMaterial, materialColourName.."roof")
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

                showSubsAnimateSpins(materialColourName.."Roof", nr)
            end
        end
    end

    countElements = 0
    local decoMaterial =   getMaterialElementsContaingNotContaining(materialColourName, {"Roof", "Deco"}, {})

    for i = 1, 37, 1 do
        partOfPlan, xLoc, zLoc = getLocationInPlan(i)
        if partOfPlan == true then
            xRealLoc, zRealLoc = -centerP.x + (xLoc * cubeDim.length),
                                 -centerP.z + (zLoc * cubeDim.length)
            local element, nr = getRandomBuildMaterial(decoMaterial, materialColourName.."RoofDeco")
            while not element do
                element, nr = getRandomBuildMaterial(decoMaterial, materialColourName.."RoofDeco")
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

                if element ~= logoPiece then
                    showSubsAnimateSpins(getPieceGroupName(element), nr)
                else
                    logo = showOne(TablesOfPiecesGroups["Office_Roof_Deco7Spin"])
                    Spin(logo,_z_axis, math.rad(5),0)
                end
            
                ToShowTable[#ToShowTable + 1] = element

                if vtolDeco[element] then
                    StartThread(vtolLoop, vtolDeco[element])
                end

                if countElements == 24 then return end
            end
        end
    end
   -- --echo(">>>>>>>>>>>>>>>> addRoofDeocrate END ")
end

boolDoneShowing = false

function showHouse() showT(ToShowTable) end

function hideHouse() hideT(ToShowTable) end

Bucket1= piece("Bucket1")
function ropeLoop()
Sleep(10)

hideT(TablesOfPiecesGroups["Rope"])
Show(Bucket1)
    while boolDoneShowing == false do
        for i=1,#TablesOfPiecesGroups["Rope"] do
            Show(TablesOfPiecesGroups["Rope"][i])
            WMove(Bucket1,_z_axis, -450*i, 200)
        end

        Sleep(500)
        for i=#TablesOfPiecesGroups["Rope"], 0, -1 do
            if TablesOfPiecesGroups["Rope"][i] then
                Show(TablesOfPiecesGroups["Rope"][i])
            end
            WMove(Bucket1,_z_axis, -450*i, 200)
        end
    Sleep(500)
    end
Hide(Bucket1)
hideT(TablesOfPiecesGroups["Rope"])
end

function buildAnimation()
    StartThread(ropeLoop)

    for i=1, #TablesOfPiecesGroups["BuildDeco"] do
        if maRa() == true then
            Show(TablesOfPiecesGroups["BuildDeco"][i])
        end
    end

    local builT = TablesOfPiecesGroups["Build"]
    axis = _z_axis

    if Spring.GetGameSeconds() < 10 then
        hideT(builT)
        hideT(TablesOfPiecesGroups["Build01Sub"])
        hideT(TablesOfPiecesGroups["BuildCrane"])

        while boolDoneShowing == false do Sleep(100) end
        showT(ToShowTable)
        hideT(TablesOfPiecesGroups["BuildDeco"])
        Hide(Bucket1)
        hideT(TablesOfPiecesGroups["Rope"])
        return
    end

    local builT = TablesOfPiecesGroups["Build"]

    for i = 1, 3 do 
        WMove(builT[i], axis, i * -2000/3, 0) 
    end

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
        Move(builT[i], axis, i * -cubeDim.heigth * 10, 3 * math.pi)
    end

    moveSyncInTimeT(TablesOfPiecesGroups["Build01Sub"], 0, -3200, 0, 8000)
    moveSyncInTimeT(TablesOfPiecesGroups["BuildCrane"], 0, -3200, 0, 8000)
    Sleep(1000)
    hideT(TablesOfPiecesGroups["BuildCrane"])
     Hide(Bucket1)
     hideT(TablesOfPiecesGroups["Rope"])
    Sleep(7000)
    WaitForMoves(TablesOfPiecesGroups["Build01Sub"])
    WaitForMoves(builT)
    hideT(builT)
    hideT(TablesOfPiecesGroups["Build01Sub"])
    hideT(TablesOfPiecesGroups["BuildCrane"])
    hideT(TablesOfPiecesGroups["BuildDeco"])
end

function buildBuilding()
    echo(getScriptName() .. "buildBuilding")
    StartThread(buildAnimation)
    echo(getScriptName() .. "selectBase")
    selectBase()
    echo(getScriptName() .. "selectBackYard")
    selectBackYard()
    echo(getScriptName() .. "buildDecorateGroundLvl started")
    materialColourName = buildDecorateGroundLvl()
    echo(getScriptName() .. "buildDecorateGroundLvl ended")

    local buildMaterial =  getMaterialElementsContaingNotContaining(materialColourName, {"Wall", "Block"}, {})
    for i = 1, 2 do
        echo(getScriptName() .. "buildDecorateLvl start")
        _, buildMaterial = buildDecorateLvl(i,
                                            materialColourName,
                                            buildMaterial
                                            )
         echo(getScriptName() .. "buildDecorateLvl ended")
    end
    echo(getScriptName() .. "addRoofDeocrate started")
    addRoofDeocrate(3, 
        getMaterialElementsContaingNotContaining(materialColourName, {"Roof"}, {"Deco"}),
         materialColourName)
        echo(getScriptName() .. "addRoofDeocrate ended")
    boolDoneShowing = true
end


function script.Activate() return 1 end

function script.Deactivate() return 0 end

function script.QueryBuildInfo() return center end

Spring.SetUnitNanoPieces(unitID, {center})

grafitiMessages={
    "ACAB",
    "FUK DA POLICE",
    "DICKBUT",
    "CRIBS",
    "BLOODS",
    "DRUGS",
    "NO SPRAYERS",
    "SPRING IS DEAD",
    "NO GODS",
    "RACYSSM",
    "ULTRAS",
    "PEACE",
    "LOVE",
    "ANNA",
    "ALLAH",
    "VHITE POWDER",
    "NO SEX",
    "RAPES OF WRATH",
    "BUGS",
    "DO UR PART",
    "ENCRASZ LE INFAM",
    "LA PUTA",
    "PLAYERZ SUCK",
    "PIG FUCKERS",
    "GIB SNITCHES",
    "VIVA LA REVOLUTION",
    "PROTAGON SUX",
    "ANTAGON WINS",
    "ENDS",
    "BEAST",
    "VR FLIGHT",
    "A CITY FOR A",
    "PENIS",

}

function addGrafiti(x,z, turnV,  axis)
    mP(TablesOfPiecesGroups["Ghetto_StreetYard_Floor_Deco"][11],x,0,z, 0)
    turnValue = turnV + 180*randSign() + 180*randSign()
    Turn(TablesOfPiecesGroups["Ghetto_StreetYard_Floor_Deco"][11],y_axis, math.rad(turnValue),0)

    myMessage = grafitiMessages[math.random(1,#grafitiMessages)]
    counter={}
    for i=1, string.len(myMessage) do
        local letter = string.sub(myMessage,i,i)
        if letter ~= " " then
            if not counter[letter] then 
                counter[letter] = 0 
            end            
            counter[letter] = counter[letter] + 1 

            if counter[letter] < 3 then 

                if TablesOfPiecesGroups["Graphiti_"..letter][counter[letter]] then
                pieceName = TablesOfPiecesGroups["Graphiti_"..letter][counter[letter]] 
                if pieceName then
                    Show(pieceName)
                    Move(pieceName,axis, 50*(i-1), 0)
                end
                end
            end
        end
    end
end
