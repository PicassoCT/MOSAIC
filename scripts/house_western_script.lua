include "createCorpse.lua"
include "lib_OS.lua"
include "lib_UnitScript.lua"
include "lib_Animation.lua"
--include "lib_Build.lua"
local spGetUnitPosition = Spring.GetUnitPosition

local grafitiMessages =  include('grafitiMessages.lua')

function getScriptName() return "house_western_script.lua::" end

local TablesOfPiecesGroups = {}
decoPieceUsedOrientation = {}
factor = 40
heightoffset = 90
local pieceNr_pieceName =Spring.GetUnitPieceList ( unitID ) 
local pieceName_pieceNr = Spring.GetUnitPieceMap (unitID)
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
    grafiti = 0.2

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
    grafiti = 0.6
}

logoPieces = {
                [piece("ClassicWhiteOffice_Roof_Deco05")] = true, 
                [piece("ClassicWhiteOffice_Roof_Deco01")] = true,
                [piece("ClassicWhiteOffice_Roof_Deco03")] = true
            }

materialChoiceTable = {"Classic", "Ghetto", "Office", "White"}
materialChoiceTableReverse = {classic= 1, ghetto = 2, office=3, white=4}

vtolDeco= {}
x, y, z = spGetUnitPosition(unitID)
geoHash = (x - (x - math.floor(x))) + (y - (y - math.floor(y))) +
              (z - (z - math.floor(z)))
-- Spring.Echo("House geohash:"..geoHash)
if geoHash % 3 == 1 then decoChances = supriseChances end
centerP = {x = (cubeDim.length / 2) * 5, z = (cubeDim.length / 2) * 5}
ToShowTable = {}

local _x_axis = 1
local _y_axis = 2
local _z_axis = 3

function script.HitByWeapon(x, z, weaponDefID, damage) end

AlreadyUsedPiece = {}
center = piece "center"
BasePillars = piece "BasePillar"

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

    x, y, z = spGetUnitPosition(unitID)
    StartThread(removeFeaturesInCircle,x,z, GameConfig.houseSizeZ/2)

    math.randomseed(x + y + z)
    StartThread(buildHouse)

        for i=1,5 do
            pericodicRotationYPieces[TablesOfPiecesGroups["_Street_Wall_Deco"..i.."Sub"][1]] = 42 *randSign()
        end

        for i=1,3 do
            pericodicRotationYPieces[TablesOfPiecesGroups["_StreetYard_Wall_Deco"..i.."Sub"][1]] = 42*randSign()
        end

    vtolDeco = {
        [TablesOfPiecesGroups["ClassicWhiteOffice_Roof_Deco"][1]]=TablesOfPiecesGroups["ClassicWhiteOffice_Roof_Deco1Sub"][1],
        [TablesOfPiecesGroups["ClassicWhiteOffice_Roof_Deco"][3]]=TablesOfPiecesGroups["ClassicWhiteOffice_Roof_Deco3Sub"][1],
        [TablesOfPiecesGroups["ClassicWhiteOffice_Roof_Deco"][5]]=TablesOfPiecesGroups["ClassicWhiteOffice_Roof_Deco5Sub"][1]
    }

    BuildDeco = TablesOfPiecesGroups["BuildDeco"]

    StartThread(rotations)
    StartThread(HoloGrams)
end

function rotations()
    periodicFunc = function(p, v)
        while true do
            Sleep(500);
            dir = (v*randSign() ) or math.random(-45, 45);
            WTurn(p, y_axis, math.rad(dir), math.pi / 250);
        end
    end
    for k, v in pairs(pericodicRotationYPieces) do

        StartThread(periodicFunc, k,v)
    end

    Sleep(500)
    clockPiece = piece("WhiteClassic_Street_Floor_Deco2")
    if contains(ToShowTable, clockPiece) then
        WTurn(TablesOfPiecesGroups["WhiteClassic_Street_Floor_Deco2Sub"][1], z_axis, math.rad(180), 0)
        showT(TablesOfPiecesGroups["WhiteClassic_Street_Floor_Deco2Sub"])
        Spin(TablesOfPiecesGroups["WhiteClassic_Street_Floor_Deco2Sub"][1], z_axis, math.rad(3), 10)
        Spin(TablesOfPiecesGroups["WhiteClassic_Street_Floor_Deco2Sub"][2], z_axis, math.rad(36), 10)
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

function HoloGrams()
    Sleep(15000)
    if maRa() == maRa() and not  isNearCityCenter(px,pz, GameConfig) then return end
    local flickerGroup = TablesOfPiecesGroups["BrothelFlicker"]
    local CasinoflickerGroup = TablesOfPiecesGroups["CasinoFlicker"]
    hideT(flickerGroup)
    hideT(CasinoflickerGroup)

    for logoPiece,v in pairs(logoPieces)do
        if contains(ToShowTable, logoPiece) then 
            if not decoPieceUsedOrientation[logoPiece] then echo(unitID..":"..pieceNameMap[logoPiece].." has no value assigned to it") end
            StartThread(moveCtrlHologramToUnitPiece, unitID, "house_western_hologram_buisness", logoPiece, decoPieceUsedOrientation[logoPiece])
            break
        end
    end

    --sexxxy time
    px,py,pz = spGetUnitPosition(unitID)
    if getDeterministicCityOfSin(getCultureName(), Game)== true and isNearCityCenter(px,pz, GameConfig) == true or mapOverideSinCity() then
        hostBrothelPiece = piece("WhiteOfficeGhetto_Roof_Deco2")   
        if maRa()== true and contains(ToShowTable, hostBrothelPiece) == true then
            if not decoPieceUsedOrientation[hostBrothelPiece] then echo( unitID..":"..pieceNameMap[hostBrothelPiece].." has no value assigned to it") end
            StartThread(moveCtrlHologramToUnitPiece, unitID, "house_western_hologram_brothel", hostBrothelPiece, decoPieceUsedOrientation[hostBrothelPiece])
        else
            hostCasinoPiece = piece("WhiteOfficeGhetto_Roof_Deco01")   
            if contains(ToShowTable, hostCasinoPiece) == true then 
                StartThread(moveCtrlHologramToUnitPiece, unitID, "house_western_hologram_casino", hostCasinoPiece, 0)
            end
        end
    end

  
end

officeWallElementsTable = {}
function mapOfficeWalls()
    for i = 1,5 do officeWallElementsTable[i] = {} end

    for k = 1, 12 do
        officeWallElementsTable[1][#officeWallElementsTable[1]+1] = TablesOfPiecesGroups["OfficeWallBlock"][k]
    end

    for k = 13, 25 do
        officeWallElementsTable[2][#officeWallElementsTable[2]+1] = TablesOfPiecesGroups["OfficeWallBlock"][k]
    end 

    for k = 26, 38 do
        officeWallElementsTable[3][#officeWallElementsTable[3]+1] = TablesOfPiecesGroups["OfficeWallBlock"][k]
    end  

    for k = 39, 52 do
        officeWallElementsTable[4][#officeWallElementsTable[4] + 1] = TablesOfPiecesGroups["OfficeWallBlock"][k]
    end  

    for k = 53, 60 do
        officeWallElementsTable[5][#officeWallElementsTable[5] + 1] = TablesOfPiecesGroups["OfficeWallBlock"][k]
    end
end

function getDeterministicOfficeWall(x,z)
    if #officeWallElementsTable == 0 then mapOfficeWalls() end

    officeWallIndex = ((math.ceil(x)+ math.ceil(z))% 5) +1

    for i=1, #officeWallElementsTable[officeWallIndex] do
        if officeWallElementsTable[officeWallIndex][i] then
            local retElement = officeWallElementsTable[officeWallIndex][i]
            officeWallElementsTable[officeWallIndex][i] = nil
            return retElement
        end
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
    local result = foreach(buildMaterial,
                           function(id) 
                                if id ~= element then 
                                    return id
                                end 
                            end
                           )
    return result
end

function selectGroundBuildMaterial()
    nice, x,y,z = getBuildingTypeHash(unitID, #materialChoiceTable)


    if getManualCivilianBuildingMaps(Game.mapName) then
        mapeDependenHouseTypes = getMapDependentHouseTypes(Game.mapName)    
        nice = math.random(3,4)
        return materialChoiceTable[nice]
    end

    if not nice then nice = 1 end
    return  materialChoiceTable[nice]
end

function getPieceGroupName(Deco)
    t = Spring.GetUnitPieceInfo(unitID, Deco)
    return t.name:gsub('%d+', '')
end

function trimZero(Deco)
    return Deco:gsub('0', '')
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

function getRandomBuildMaterial(buildMaterial, name, x, z)

    if not buildMaterial then
--        echo(getScriptName() .. "getRandomBuildMaterial: Got no table "..name);
        return
    end
    if not type(buildMaterial) == "table" then
   --[[     echo(
            getScriptName() .. "getRandomBuildMaterial: Got not a table, got" ..
                type(buildMaterial) .. "instead");--]]
        return
    end
    total = count(buildMaterial)
    if total == 0 and #buildMaterial == 0 then
     --   echo(getScriptName() .. "getRandomBuildMaterial: Got a empty table "..name)
        return
    end

    if  x and z and name == "Office"  then
        piecenum = getDeterministicOfficeWall(x,z)
        if (piecenum and not AlreadyUsedPiece[piecenum] ) then
            AlreadyUsedPiece[piecenum] = true
            return piecenum
        end
    else

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
--    Spring.Echo(getScriptName() .. "getRandomBuildMaterial: No Part selected ")
end

NotInPlanIndeces = {}
if maRa() == true then
    notindex = math.random(2,5)
    NotInPlanIndeces[notindex] = true 
    if maRa()== true then
        notindex = math.min(notindex+1,5)
        NotInPlanIndeces[notindex] = true 
    end
end

if maRa() == true then
    notindex=  math.random(32,35)
    NotInPlanIndeces[notindex] = true 
    if maRa()== false then
        notindex = math.min(notindex+1,35)
        NotInPlanIndeces[notindex] = true 
    end
end
    

boolOpenBuilding = maRa() == true

-- x:0-6 z:0-6
function getLocationInPlan(index, materialColourName)
    if materialColourName == "Office" and boolOpenBuilding and NotInPlanIndeces[index] then return false, 0,0 end

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
    if not name or name == "" then
        return true, true 
    end
    
    name = string.lower(name)
    materialColourName = string.lower(materialColourName)
    print(name)
    
    boolContainsMaterialName =  (string.find(name, materialColourName) ~= nil)
    boolContainsNoOtherName = true
    matColour ={"office", "ghetto", "classic", "white"}

    for i=1,#matColour do
        if not (matColour[i] == materialColourName) and string.find(name, matColour[i]) ~= nil then
          boolContainsNoOtherName = false
          break
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

                if boolContainsMaterialName == true or boolContainsNoOtherName == true then

                for i=1, #mustContainTable do
                    if string.find(name, string.lower(mustContainTable[i])) == nil then
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

    --echo("House_wester_nColour:"..materialColourName)
    local buildMaterial = getMaterialElementsContaingNotContaining(materialColourName, {"Block"}, {"Wall"}) 
    assert(buildMaterial)
    assert(#buildMaterial > 0)
    countElements = 0

    for i = 1, 37, 1 do
        Sleep(1)

        local index = i
        --echo(getScriptName() .. "buildDecorateGroundLvl" .. i)
        rotation = getOutsideFacingRotationOfBlockFromPlan(index)
        partOfPlan, xLoc, zLoc = getLocationInPlan(index, materialColourName)

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

                if boolHasGrafiti == true and chancesAre(10) > 0.9 then 
                    boolHasGrafiti = false
                    rotation = getOutsideFacingRotationOfBlockFromPlan(index)
                    addGrafiti(xRealLoc, zRealLoc, rotation ,  _y_axis)
                end

                if chancesAre(10) < decoChances.street then
                    rotation = getOutsideFacingRotationOfBlockFromPlan(index)
                    StreetDecoMaterial, StreetDeco =   DecorateBlockWall(xRealLoc, zRealLoc, 0,
                                          StreetDecoMaterial, 0, materialColourName)
                    if StreetDeco then
                        Turn(StreetDeco, 3, math.rad(rotation), 0)
                        showSubsAnimateSpinsByPiecename(pieceName_pieceNr[StreetDeco]) 
                    end
                end

                if chancesAre(10) < decoChances.door then
                    axis = _z_axis
                    DoorMaterial, Door = DecorateBlockWall(xRealLoc, zRealLoc, 0, DoorMaterial, 0 , materialColourName)
                   
                    if Door then
                        Turn(Door, axis, math.rad(rotation), 0)
                        showSubsAnimateSpinsByPiecename(pieceName_pieceNr[Door])
                        if chancesAre(10) < decoChances.door then
                        DoorDecoMaterial, DoorDeco =
                            DecorateBlockWall(xRealLoc, zRealLoc, 0,
                                              DoorDecoMaterial, 0, materialColourName)
                            if DoorDeco then
                                Turn(DoorDeco, axis, math.rad(rotation), 0)
                                showSubsAnimateSpinsByPiecename(pieceName_pieceNr[DoorDeco]) 
                            end
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
        WindowDecoMaterial = {}
        yardMaterial =  getMaterialElementsContaingNotContaining(materialGroupName, {"Yard", "Wall"}, {"Ghetto"})
    end

   -- echo(getScriptName() .. count(WindowWallMaterial) .. "|" ..
     --        count(yardMaterial) .. "|" .. count(streetWallMaterial))

    countElements = 0

    for i = 1, 37, 1 do
        Sleep(1)
        local index = i
        rotation = getOutsideFacingRotationOfBlockFromPlan(i)

        partOfPlan, xLoc, zLoc = getLocationInPlan(index, materialGroupName)
        xRealLoc, zRealLoc = xLoc, zLoc
        if partOfPlan == true then
            xRealLoc, zRealLoc = -centerP.x + (xLoc * cubeDim.length),
                                 -centerP.z + (zLoc * cubeDim.length)
            local element, nr = getRandomBuildMaterial(buildMaterial, materialGroupName, xLoc, zLoc)

            while not element do
                element, nr = getRandomBuildMaterial(buildMaterial, materialGroupName, xLoc, zLoc)
                Sleep(1)
            end

            if element then
                showSubsAnimateSpinsByPiecename(pieceNr_pieceName[element])

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
                    Turn(streetWallDeco, _z_axis, math.rad(rotation), 0)
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
    if not piecename then return end
    piecename = trimZero(piecename)

     nr = ""
    for i=string.len(piecename), 1, -1 do
        character =  string.sub(piecename, i, i)
        asciiByteValue = string.byte(character)
        if asciiByteValue > 47 and asciiByteValue <58 then
            nr = character..nr
        else
            pieceGroupName = string.sub(piecename,1, i)
            nr = tonumber(nr, 10)
            if string.len(pieceGroupName) > 0 and type(nr) == "number" then
             showSubsAnimateSpins(pieceGroupName, nr)
            end
        break
        end
    end
end

function showOneOrAllOfTablePieceGroup(name)
  if TablesOfPiecesGroups[name] then
        showOneOrAll(TablesOfPiecesGroups[name])
    elseif pieceName_pieceNr[name..1] then
        ToShowTable[#ToShowTable + 1] = pieceName_pieceNr[name..1]
    end
end

function getRotationFromPiece(pieceID)
    px,py,pz = Spring.GetUnitPiecePosDir(unitID, pieceID)
    tx, tz = x- px, z- pz
  
    norm = math.max(math.abs(tx),math.abs(tz))
    tx,tz = tx/norm, tz/norm

    if tx >= 1.0 then
        return 0
    end

    if tz >= 1.0 then
        return 90
    end

    if tx <= -1.0 then
        return 180
    end

    if tz <= -1.0 then
        return 270
    end

    return math.random(1,4) * 90
end

function showSubsAnimateSpins(pieceGroupName, nr)
    local subName = pieceGroupName .. nr .. "Sub"
  --  Spring.Echo("SubGroupName "..subName)
    showOneOrAllOfTablePieceGroup(subName)

    local spinName = pieceGroupName .. nr .. "Spin"
    showOneOrAllOfTablePieceGroup(spinName)
    showOneOrAllOfTablePieceGroup(spinName.."Sub")
   -- Spring.Echo("SpinGroupName "..spinName)
    direction = math.random(40,160) * randSign()

    if TablesOfPiecesGroups[spinName] then
        for i=1,#TablesOfPiecesGroups[spinName] do
            Spin(TablesOfPiecesGroups[spinName][i] , y_axis, math.rad(direction), math.pi)
        end
    elseif pieceName_pieceNr[spinName..1]  then
        Spin(pieceName_pieceNr[spinName] , y_axis, math.rad(direction), math.pi)
    end
end
logoPiecesToHide = {
                [piece("Office_Roof_Deco07")] = true, 
                [piece("Office_Roof_Deco02")] = true
            }
pieceNameMap = Spring.GetUnitPieceList( unitID ) 
function addRoofDeocrate(Level, buildMaterial, materialColourName)
    countElements = 0
    if materialColourName == "Office" and maRa() then
        decoChances.roof = 0.65 
    end

    for i = 1, 37, 1 do
        local index = i
        partOfPlan, xLoc, zLoc = getLocationInPlan(index, materialColourName)
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
                decoPieceUsedOrientation[element] = getRotationFromPiece(element)
                --echo(unitID..":Piece "..pieceNameMap[element].." has orientation vector ("..decoPieceUsedOrientation[element]..")")

                if countElements == 24 then break end
                showSubsAnimateSpinsByPiecename(pieceNr_pieceName[element])
            end
        end
    end

    countElements = 0
    local decoMaterial = getMaterialElementsContaingNotContaining(materialColourName, {"Roof", "Deco"}, {})
    local T = foreach(decoMaterial, function(id) return pieceNr_pieceName[id] end)
    --echo("addRoofDecorate:", T)


    for i = 1, 37, 1 do
        partOfPlan, xLoc, zLoc = getLocationInPlan(i, materialColourName)
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

                if not logoPiecesToHide[element] then
                    showSubsAnimateSpinsByPiecename(pieceNr_pieceName[element])
                end
            
                ToShowTable[#ToShowTable + 1] = element

                if vtolDeco[element] then 
                    minute=1--60
                    StartThread(vtolLoop, 
                        unitID, --unitID, 
                        vtolDeco[element],--plane,
                        math.random(1,4) * minute * 1000, --restTimeMs,
                        math.random(5,10) * minute * 1000, -- timeBetweenFlightsMs, 
                        3)--factor)
                end

                if countElements == 24 then return end
            end
        end
    end
end

boolDoneShowing = false
boolHouseHidden = false

function showHouse() boolHouseHidden = false; showT(ToShowTable) end

function hideHouse() boolHouseHidden = true; hideT(ToShowTable) end

Bucket1= piece("Bucket1")

function ropeLoop()
Sleep(10)

hideT(TablesOfPiecesGroups["Rope"])
Show(Bucket1)
    while boolDoneShowing == false do
         WaitForTurns(TablesOfPiecesGroups["BuildCrane"][1])
        for i=1,#TablesOfPiecesGroups["Rope"] do
            Show(TablesOfPiecesGroups["Rope"][i])
            WMove(Bucket1,_z_axis, -450*i, 200)
        end
        WaitForTurns(TablesOfPiecesGroups["BuildCrane"][1])

        for i=#TablesOfPiecesGroups["Rope"], 0, -1 do
            if TablesOfPiecesGroups["Rope"][i] then
                hideT(TablesOfPiecesGroups["Rope"])
                Show(TablesOfPiecesGroups["Rope"][i])
            end
            WMove(Bucket1,_z_axis, -450*i, 200)
        end
     Sleep(50)
    end
Hide(Bucket1)
hideT(TablesOfPiecesGroups["Rope"])
end

Icon = piece("Icon")

function buildAnimation()
   
    Show(Icon)
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
        Hide(Icon)
        return
    end
    StartThread(PlaySoundByUnitDefID, myDefID, "sounds/gCrubbleHeap/construction/construction"..math.random(1,7)..".ogg", 1.0, 20000, 3)
    Hide(Icon)
    StartThread(ropeLoop)
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
    
    foreach(TablesOfPiecesGroups["BuildCrane"], function(id)
        craneFunction = function(id)
            while true do
                target = math.random(-120, 120)
                WTurn(id, y_axis, math.rad(target), math.pi / 10)
                WaitForMoves(Bucket1)
                Sleep(500)
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
    --echo(getScriptName() .. "buildBuilding")
    StartThread(buildAnimation)
    --echo(getScriptName() .. "selectBase")
    selectBase()
    --echo(getScriptName() .. "selectBackYard")
    selectBackYard()
    --echo(getScriptName() .. "buildDecorateGroundLvl started")
    materialColourName = buildDecorateGroundLvl()
    --echo(getScriptName() .. "buildDecorateGroundLvl ended")

    local buildMaterial =  getMaterialElementsContaingNotContaining(materialColourName, {"Wall", "Block"}, {})
    for i = 1, 2 do
        --echo(getScriptName() .. "buildDecorateLvl start")
        _, buildMaterial = buildDecorateLvl(i,
                                            materialColourName,
                                            buildMaterial
                                            )
         --echo(getScriptName() .. "buildDecorateLvl ended")
    end
    --echo(getScriptName() .. "addRoofDeocrate started")
    addRoofDeocrate(3,      getMaterialElementsContaingNotContaining(materialColourName, {"Roof"}, {"Deco"}),        materialColourName)
    Show(BasePillars)
        --echo(getScriptName() .. "addRoofDeocrate ended")
    boolDoneShowing = true
end


function script.Activate() return 1 end

function script.Deactivate() return 0 end

function script.QueryBuildInfo() return center end

Spring.SetUnitNanoPieces(unitID, {center})

function addGrafiti(x,z, turnV,  axis)
    playerName = getRandomPlayerName()
    Move(TablesOfPiecesGroups["Ghetto_StreetYard_Floor_Deco"][11],1, x, 0)
    Move(TablesOfPiecesGroups["Ghetto_StreetYard_Floor_Deco"][11],2, 0, 0)
    Move(TablesOfPiecesGroups["Ghetto_StreetYard_Floor_Deco"][11],3, z, 0)
    boolTurnGraphiti = maRa()
    turnValue = turnV + 180*randSign() + 180 * randSign()
    Turn(TablesOfPiecesGroups["Ghetto_StreetYard_Floor_Deco"][11],3, math.rad(turnValue),0)
--[[    StartThread(spawnCegCyclicAtUnitPiece,unitID, TablesOfPiecesGroups["Ghetto_StreetYard_Floor_Deco"][11], "policelight", 1000)--]]
    myMessage = grafitiMessages[math.random(1,#grafitiMessages)]
    myMessage = string.gsub(myMessage, "Ü", playerName or "")
    --echo("Adding Grafiti with message:" ..myMessage)
    counter={}
    stringlength = string.len(myMessage)

    for i=1, stringlength do
        local letter = string.upper(string.sub(myMessage,i,i))
        if letter ~= " " then
            if not counter[letter] then 
                counter[letter] = 0 
            end            
            counter[letter] = counter[letter] + 1 

            if counter[letter] < 3 then 
                Turnfactor = math.atan((i/stringlength)*math.pi*2)
                if maRa() == true then
                    Turnfactor = math.sin((i/stringlength)*math.pi*2)
                elseif maRa() == true then
                    Turnfactor = math.cos((i/stringlength)*math.pi*2)
                end

                if TablesOfPiecesGroups["Graphiti_"..letter] and counter[letter] and TablesOfPiecesGroups["Graphiti_"..letter][counter[letter]] then
                pieceName = TablesOfPiecesGroups["Graphiti_"..letter][counter[letter]] 
                if pieceName then 
                    ToShowTable[#ToShowTable + 1] = pieceName
                    Show(pieceName)
                    Move(pieceName,axis, 70*(i-1), 0)
                    if i > 10 then
                     Move(pieceName,axis, 70*(i-10), 0)
                     Move(pieceName, 3, -100, 0)
                    end
                    if boolTurnGraphiti == true then
                        Turn(pieceName , 1, math.rad(Turnfactor*10),0)
                    end
                end
                end
            end
        end
    end
end
