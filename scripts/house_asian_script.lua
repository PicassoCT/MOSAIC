include "createCorpse.lua"
include "lib_OS.lua"
include "lib_UnitScript.lua"
include "lib_Animation.lua"

IDGroupsDirection = { 
    "u", --upright
    "l"} -- lengthwise

--include "lib_Build.lua"
local spGetUnitPosition = Spring.GetUnitPosition
local boolContinousFundamental = maRa() == maRa()
function getScriptName() return "house_asian_script.lua::" end

local TablesOfPiecesGroups = {}
decoPieceUsedOrientation = {}
factor = 35
heightoffset = 90
maxNrAttempts = 20

rotationOffset = 90
local pieceNr_pieceName =Spring.GetUnitPieceList ( unitID ) 
local pieceName_pieceNr = Spring.GetUnitPieceMap (unitID)
local cubeDim = {
    length = factor * 23,
    heigth = factor * 14.84 + heightoffset,
    roofHeigth = 50
}

local SIG_SUBANIMATIONS = 2

pieceCyclicOSTable = {
    ["PieceName"] = {
                    {"turn", y_axis, 49, 3},
                    {"move", x_axis, 49, 3, 500},
                    {"blink", 750 }
                    },      
}

supriseChances = {
    roof = 0.35,
    yard = 0.6,
    yardwall = 0.4,
    street = 0.5,
    powerpoles = 0.5,
    door = 0.6,
    windowwall = 0.7,
    streetwall = 0.5

}
decoChances = {
    roof = 0.2,
    yard = 0.1,
    yardwall = 0.4,
    street = 0.1,
    powerpoles = 0.5,
    door = 0.6,
    windowwall = 0.5,
    streetwall = 0.1
}

logoPieces = {
                [piece("Roof01")] = true, 
                [piece("Roof02")] = true,
                [piece("Roof03")] = true,
                [piece("Roof28")] = true
            }

MapPieceIDName = Spring.GetUnitPieceMap(unitID)
materialChoiceTable = {"Pod", "Industrial", "Trad", "Office"}
materialChoiceTableReverse = {pod= 1, industrial = 2, trad=3, office=4}

function initAllPieces()
    Signal(SIG_SUBANIMATIONS)
    for pieceName, set in pairs ( pieceCyclicOSTable) do
        startPieceOS(pieceName, SIG_SUBANIMATIONS)
    end
end

function getIDGroupsForType(buildingType, ID_DirectionsToFilter)
    allMatchingGroups = {}
	searchTerms= {}

    if ID_DirectionsToFilter then
		for i=1,#ID_DirectionsToFilter do
			searchTerms[#searchTerms +1] = ID_DirectionsToFilter[i]
		end
    end
    echo("Searching for ID Groups for type "..buildingType)
	for groupName,v in pairs(TablesOfPiecesGroups) do
		for i=1,#searchTerms do
		if buildingType and startsWith(string.lower(groupName), string.lower(searchTerms[i])) then
			if string.find(groupName, buildingType) and not string.find(groupName, "Sub")then
                echo("Adding id Group with name:"..groupName.." and ".. #v.." members")
				allMatchingGroups[groupName] = v
			end
		 end
		end
	end
	return allMatchingGroups
end

function hasUnitSequentialElements(id)
	return id % 2 == 0
end

function getDeterministicLengthwisePieceGroundIndex(unitID, level, deterministicPersistentCounter)

PieceGroupIndex = getDeterministicRandom(unitID + instanceIndex + level,  count(buildingGroups) - 1) + 1	
return PieceGroupIndex
end

deterministicPersistentCounter= 0
--TODO check buildingGroups has material Dimensions
--TODO check buildMaterials are used elsewhere and its flat
function isInPositionSequenceGetPieceID(roundNr, level)
	if not hasUnitSequentialElements(unitID) then return false end
	
	if not hasUnitSequentialElements(unitID) then return false end
    if not roundNr then echo("invalid roundnr "); return false end
	
	Direction = IDGroupsDirection[getDeterministicRandom(unitID, 1)+1]
	groupName = nil
	--upright
	if Direction == "u"  then
		if getDeterministicRandom(unitID+roundNr, 3) % 2 == 0 then return false end
		PieceGroupIndex = getDeterministicRandom(unitID  + roundNr,  #buildingGroupsUpright ) + 1

        for name, group in pairs(buildingGroupsUpright) do
            PieceGroupIndex = PieceGroupIndex -1
            if PieceGroupIndex == 0 then
                groupName = name
                break
            end
        end

        if groupName and buildingGroupsUpright[groupName][level] then
            return true, buildingGroupsUpright[groupName][level]
        else
            return false
        end
	end
	
	--lengthwise
	if Direction == "l"  then
        PieceGroupIndex = (getDeterministicRandom(unitID  + level + deterministicPersistentCounter,  #buildingGroupsLength) + 1 ) 
  
        for name, group in pairs(buildingGroupsLength) do
            PieceGroupIndex = PieceGroupIndex -1
            if PieceGroupIndex == 0 then
                groupName = name
                break
            end
        end
		
		if buildingGroupsLength[groupName][roundNr] and inToShowDict(buildingGroupsLength[groupName][roundNr]) then
			return false
		end
		
		-- existence
        if buildingGroupsLength[groupName][roundNr] then 
            return true, buildingGroupsLength[groupName][roundNr]
        else -- non existence
			deterministicPersistentCounter = deterministicPersistentCounter + 1
            return false
        end
	end

	return false
end

vtolDeco= {}
gx, gy, gz = spGetUnitPosition(unitID)
geoHash = (gx - (gx - math.floor(gx))) + (gy - (gy - math.floor(gy))) + (gz - (gz - math.floor(gz)))
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

pericodicRotationYPieces = {}
pericodicMovingZPieces = {}

GameConfig = getGameConfig()

function timeOfDay()
    WholeDay = GameConfig.daylength
    timeFrame = Spring.GetGameFrame() + (WholeDay * 0.25)
    return ((timeFrame % (WholeDay)) / (WholeDay))
end

BuildDeco = {}
buildingGroupsUpright = {}
buildingGroupsLength = {}

function script.Create()
    TablesOfPiecesGroups = getPieceTableByNameGroups(false, true)

    x, y, z = spGetUnitPosition(unitID)
    StartThread(removeFeaturesInCircle,x,z, GameConfig.houseSizeZ/2)

    math.randomseed(x + y + z)
    StartThread(buildHouse)

    vtolDeco = {
       --[TablesOfPiecesGroups["Roof"][1]]=TablesOfPiecesGroups["Roof"][1],
        --[TablesOfPiecesGroups["Roof"][2]]=TablesOfPiecesGroups["Roof"][2],
        --[TablesOfPiecesGroups["Roof"][3]]=TablesOfPiecesGroups["Roof"][3]
    }

    --BuildDeco = TablesOfPiecesGroups["BuildDeco"]

    StartThread(rotations)
end

function rotations()
    periodicFunc = function(p, v)
        while true do
            Sleep(500);
            dir = (v*randSign() ) or math.random(-45, 45);
            WTurn(p, y_axis, math.rad(dir), math.pi / 250);
        end
    end
    assert(pericodicRotationYPieces)
    for k, v in pairs(pericodicRotationYPieces) do
        StartThread(periodicFunc, k,v)
    end

    Sleep(500)  
    periodicMovementFunc = function(p, value)
        while true do
            Sleep(500);
            Move(p, _x_axis, math.rad(value), 5);
            WaitForMoves(p)
            Move(p, _x_axis, math.rad(0), 5);
            WaitForMoves(p)
        end
    end
    assert(pericodicMovingZPieces)
    for k, v in pairs(pericodicMovingZPieces) do
        StartThread(periodicMovementFunc, k, v)
    end
end

function showHoloWall()

    step = 6*4
    index = math.random(0,#TablesOfPiecesGroups["HoloTile"]/step)
    if maRa() == maRa() then
        for i=index * step,  (index+1) * step, 1 do
            if (maRa() == maRa()) ~= maRa() then
                Hide(TablesOfPiecesGroups["HoloTile"][i])
            else
                Show(TablesOfPiecesGroups["HoloTile"][i])
				addToShowTable( TablesOfPiecesGroups["HoloTile"][i])
            end
        end
        return    
    end
    showT(TablesOfPiecesGroups["HoloTile"],index * step, (index+1) * step)
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
    assert(T)
    for k, v in pairs(T) do
        if k and v then c = c + 1 end
        if c == dice then
            if bNotDelayd and bNotDelayd == true then
                Show(v)
            else
				addToShowTable(v)
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
        assert(T)
        for num, val in pairs(T) do 
			addToShowTable(val)
		end
        return val
    end
end

function getMaterialBaseNameOrDefault(materialName, mustInclude, mustExclude)
    AllCandiDates = {}
    MaterialCandiDates = {}
    pieceList = Spring.GetUnitPieceList(unitID)
    for nr = 1, #pieceList do
        name = pieceList[nr]
        if name then
            boolNope = false
            if mustInclude then
                for include=1, #mustInclude do
                    if mustInclude[include] and not string.find(name, mustInclude[include]) then
                        boolNope = true
                    end
                end
            end
            if mustExclude then
                for exclude=1, #mustExclude do
                    if mustExclude[exclude] and string.find(name, mustExclude[exclude]) then
                        boolNope = true
                    end
                end
            end

            if not boolNope then 
                table.insert(AllCandiDates, nr)
                if string.find(name, materialName) then
                    table.insert(MaterialCandiDates, nr)
                end 
            end
        end
    end
    if #MaterialCandiDates > 0 then
        return getSafeRandom(MaterialCandiDates, MaterialCandiDates[1])
    end

    return getSafeRandom(AllCandiDates, AllCandiDates[1])    
end

function showRegPiece(pID)
    Show(pID)
	addToShowTable(pID)
end

function selectBase(materialType) 
    basePiece = getMaterialBaseNameOrDefault(materialType, {"Base"}, {"Deco"})
    if basePiece then
        showRegPiece(basePiece)       
        echo("BasePiece: ".. getPieceName(unitID, basePiece))
    end
end

function selectBackYard(materialType) 
    yardDecoPice = getMaterialBaseNameOrDefault(materialType, {"Base", "Deco"}, {})

    echo("BaseDeco: "..toString(yardDecoPice))
    if yardDecoPice then
         showRegPiece(yardDecoPice)       
    end
end

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

    if boolRedo then
        return materialColourName[math.random(1,4)]
    end
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
    attempts = maxNrAttempts
    local Deco, nr = getRandomBuildMaterial(DecoMaterial, materialGroupName.."blockwall", xRealLoc, zRealLoc, level)
    while not Deco and attempts  > 0 do
        Deco, nr = getRandomBuildMaterial(DecoMaterial, materialGroupName.."blockwall", xRealLoc, zRealLoc, level)
        Sleep(1)
        attempts = attempts  - 1
    end

    if attempts  == 0 then
       echo("DecorateBlockWall: ran out of attempts")
        return DecoMaterial
    end

    if Deco then
        DecoMaterial = removeElementFromBuildMaterial(Deco, DecoMaterial)
        Move(Deco, _x_axis, xRealLoc, 0)
        Move(Deco, _y_axis, level * cubeDim.heigth + y_offset, 0)
        Move(Deco, _z_axis, zRealLoc, 0)
		addToShowTable(Deco)
        piecename = getPieceGroupName(Deco)
    end

    if TablesOfPiecesGroups[piecename .. nr .. "Sub"] then
        showOneOrAll(TablesOfPiecesGroups[piecename .. nr .. "Sub"])
    end

    return DecoMaterial, Deco
end

function getIDFromPieceName(name)
    nameSplit = split(name, "_")
    typeID =  string.sub(nameSplit[2], 1, 1)
    group = string.tonumber(string.sub(nameSplit[2],2))
    return typeID, group
end

local roundNrTable =
    {1,     2,      3,       4,     5,      6,
    20,     nil,     nil,   nil,    nil,    7,
    19,     nil,     nil,   nil,    nil,    8,
    18,     nil,     nil,   nil,    nil,    9,
    17,     nil,     nil,   nil,    nil,    10,
    16,     15,     14,     13,     12,     11,
    }
function convertIndexToRoundNr(groupIndex)    
    return roundNrTable[groupIndex]
end

function notString(boolHigan)
    if boolHigan == true then
        return ""
    end

    return " not "
end

function getRandomBuildMaterial(buildMaterial, name, index, x, z, level, context)
    --echo("Getting  Random Material")
    if not buildMaterial then
        echo(getScriptName() .. "getRandomBuildMaterial: Got no table "..name);
        return
    end
    if not type(buildMaterial) == "table" then
		echo( getScriptName() .. "getRandomBuildMaterial: Got not a table, got" ..   type(buildMaterial) .. "instead");
        return
    end
    total = count(buildMaterial)
    if total == 0 and #buildMaterial == 0 then
      echo(getScriptName() .. "getRandomBuildMaterial: Got a empty table "..name)
      return
    end

    assert(buildMaterial[1])
	--TODO Move to total seperate function, this thing is neither random nor connected with the buildMaterial handed to the function
    roundNr = convertIndexToRoundNr(index)
	isInRoundNr, piecenum = isInPositionSequenceGetPieceID(roundNr, level) 

	if isInRoundNr and piecenum and not AlreadyUsedPiece[piecenum] then
        if MapPieceIDName[piecenum] then
        echo("resorting to sequence for level " ..level.. "for material " ..name.. " with piece ".. toString(MapPieceIDName[piecenum]).." selected") 
        end
        AlreadyUsedPiece[piecenum] = true
       return piecenum, num
	end

    startIndex = getSafeRandom(buildMaterial, buildMaterial[1]) 

	for num, piecenum in pairs(buildMaterial) do
		startIndex = startIndex -1
	   if startIndex == 0 and not AlreadyUsedPiece[piecenum]  then
			AlreadyUsedPiece[piecenum] = true
			return piecenum, num
		end
	end
    --echo(" Returning nil in getRandomBuildMaterial in context".. toString(context)) 
   return
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
    if index == 1 or index == 6 or index == 31 or index == 36 then return 0 + rotationOffset end

    if index > 1 and index < 6 then return 270 + rotationOffset end

    if index > 31 and index < 36 then return 90 + rotationOffset end

    if (index % 6) == 0 then return 180 + rotationOffset end

    if (index % 6) == 1 then return 0 + rotationOffset end

    return 0 + rotationOffset
end

function getOutsideFacingRotationOfBlockFromPlan(index)

    if (index > 30 and index < 37) then
        if (index == 31) then return 270 - math.random(0, 1) * 90 + rotationOffset end

        if (index == 36) then return 270 + math.random(0, 1) * 90 + rotationOffset end

        return 270 + rotationOffset
    end

    if (index > 0 and index < 7) then
        if (index == 1) then return 90 + math.random(0, 1) * 90 + rotationOffset end

        if (index == 6) then return 90 - math.random(0, 1) * 90 + rotationOffset end

        return 90 + rotationOffset
    end

    if ((index % 6) == 1 and (index < 31 and index > 6)) then return 180 + rotationOffset end

    if ((index % 6) == 0 and (index < 31 and index > 6)) then return 0 + rotationOffset end

    return 0 + rotationOffset
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
    assert(arg)
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

function inToShowDict(element)
	return toShowDict[element]
end

toShowDict = {}
function addToShowTable(element)
	ToShowTable[#ToShowTable + 1] = element	
	toShowDict[element] = true
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
    if not mustContainTable then mustContainTable = {} end
    if not mustNotContainTable  then mustNotContainTable = {} end
    resultTable = {}
    echo(getScriptName()..toString(mustContainTable))
    echo(getScriptName()..toString(mustNotContainTable))

    materialColourName = string.lower(materialColourName)
    for nameUp,data in pairs(TablesOfPiecesGroups) do        
        local name = string.lower(nameUp)
        if  string.find(name, "sub") == nil and
            string.find(name, "spin")  == nil  then
            boolFullfilledConditions= true
            boolContainsMaterialName, boolContainsNoOtherName =  nameContainsMaterial(name, materialColourName)

            if boolContainsMaterialName == true or boolContainsNoOtherName == true then
                if mustContainTable then
                    for i=1, #mustContainTable do
                        if string.find(name, string.lower(mustContainTable[i])) == nil then
                            boolFullfilledConditions = false
                            break
                        end  
                    end
                end

                if  boolFullfilledConditions == true then
                    if mustNotContainTable then
                        for j=1, #mustNotContainTable do
                            if string.find(name, string.lower(mustNotContainTable[j])) then
                            boolFullfilledConditions = false
                            break
                            end
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
    echo("getMaterialElementsContaingNotContaining:"..materialColourName.." / "..toString(mustContainTable))
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

function buildDecorateGroundLvl(materialColourName)
    echo(getScriptName()..":buildDecorateLGroundLvl")

    local StreetDecoMaterial = getMaterialElementsContaingNotContaining(materialColourName, {"Street", "Floor", "Deco"}, {"Yard"})

    local yardMaterial = getMaterialElementsContaingNotContaining(materialColourName, {"Yard","Deco"})

    --echo("House_wester_nColour:"..materialColourName)
    local floorBuildMaterial = getMaterialElementsContaingNotContaining(materialColourName, {"Floor"}) 

    assert(floorBuildMaterial)
    assert(#floorBuildMaterial > 0)
    countElements = 0

    for i = 1, 37, 1 do
        Sleep(1)

        local index = i
        echo(getScriptName() .. "buildDecorateGroundLvl" .. i)
        rotation = getOutsideFacingRotationOfBlockFromPlan(index)
        partOfPlan, xLoc, zLoc = getLocationInPlan(index, materialColourName)

        xRealLoc, zRealLoc = -centerP.x + (xLoc * cubeDim.length), -centerP.z + (zLoc * cubeDim.length)
        local element = getRandomBuildMaterial(floorBuildMaterial, materialColourName, index, xLoc, zLoc,  0, "buildDecorateGroundLvl" )
        attempts = maxNrAttempts
        while not element  do
            element = getRandomBuildMaterial(floorBuildMaterial, materialColourName, index, xLoc, zLoc,  0, "buildDecorateGroundLvl" )
            attempts = attempts -1
        end

        if attempts == 0 then 
            echo(getScriptName() .. "buildDecorateGroundLvl: element selection failed for ".. materialColourName)
            return materialColourName
        end

        if element then
            countElements = countElements + 1
            floorBuildMaterial = removeElementFromBuildMaterial(element, floorBuildMaterial)
            Move(element, _x_axis, xRealLoc, 0)
            Move(element, _z_axis, zRealLoc, 0)
            rotation = getOutsideFacingRotationOfBlockFromPlan(index)
            Turn(element, 3, math.rad(rotation), 0)
            addToShowTable(element)
			echo("Placed GroundLevel element "..i)
            if countElements == 24 then
                return materialColourName
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
        end  

        if isBackYardWall(index) == true then
            -- BackYard
            if yardMaterial and count(yardMaterial) > 0 and  chancesAre(10) < decoChances.yard then
                rotation = getWallBackyardDeocrationRotation(index)
                yardMaterial, yardDeco = decorateBackYard(index, xLoc, zLoc, yardMaterial, 0)
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
    echo(getScriptName()..":buildDecorateLvl"..Level)
    Sleep(1)
    assert(buildMaterial)
    assert(type(buildMaterial)== "table")
    assert(Level)
    --assert(#buildMaterial >0 )

    --local WindowWallMaterial = getMaterialElementsContaingNotContaining(materialGroupName, {"Window", "Wall"}, {"Deco"})  
    --local WindowDecoMaterial = getMaterialElementsContaingNotContaining(materialGroupName, {"Window", "Deco"}, {})  
    local yardMaterial = getMaterialElementsContaingNotContaining(materialGroupName, {"Yard", "Wall"}, {})
    local streetWallMaterial = getMaterialElementsContaingNotContaining(materialGroupName, {"Street", "Wall"}, {})
	--assert(#WindowDecoMaterial > 0)
	--assert(#WindowWallMaterial  > 0)

	--assert(#streetWallMaterial > 0)

    if string.lower(materialGroupName) == string.lower("office") then
        WindowWallMaterial = {}
        WindowDecoMaterial = {}
        yardMaterial =  getMaterialElementsContaingNotContaining(materialGroupName, {"Yard", "Wall"}, {"Industrial"})
    end

    --echo(getScriptName() .. count(WindowWallMaterial) .. "|" .. count(yardMaterial) .. "|" .. count(streetWallMaterial))

    countElements = 0

    for i = 1, 37, 1 do
        Sleep(1)
        local index = i
        rotation = getOutsideFacingRotationOfBlockFromPlan(i)

        partOfPlan, xLoc, zLoc = getLocationInPlan(index, materialGroupName)
        xRealLoc, zRealLoc = xLoc, zLoc
        if partOfPlan then
            xRealLoc, zRealLoc = -centerP.x + (xLoc * cubeDim.length),
                                 -centerP.z + (zLoc * cubeDim.length)
            local element = getRandomBuildMaterial(buildMaterial, materialGroupName, index, xLoc, zLoc,  Level, "buildDecorateLvl" )
            attempts = maxNrAttempts
            while not element and attempts > 0 do
                element = getRandomBuildMaterial(buildMaterial, materialGroupName, index, xLoc, zLoc,  Level, "buildDecorateLvl" )
            end
            
            if attempts == 0 then 
                echo(getScriptName() .. "buildDecorateLvl: element selection failed for "..materialColourName)
                return materialColourName
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
				addToShowTable(element)
				
--[[                if chancesAre(10) < decoChances.windowwall then
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

                end--]]

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

                yardMaterial, yardWall = decorateBackYard(index, xLoc, zLoc, yardMaterial, Level)
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
    echo(getScriptName()..":decorateBackYard")
    assert(buildMaterial)
    assert(Level)

    countedElements = count(buildMaterial)
    if countedElements == 0 then return buildMaterial end

    local element, nr = getRandomBuildMaterial(buildMaterial, "yard", index, xLoc, zLoc, Level,"decorateBackYard" )
    attempts = maxNrAttempts


    while not element and attempts > 0 do
        element, nr = getRandomBuildMaterial(buildMaterial, "yard", index, xLoc, zLoc,  Level,"decorateBackYard" )
        Sleep(1)
        attempts = attempts -1
    end
    buildMaterial = removeElementFromBuildMaterial(element, buildMaterial)
    
    if attempts == 0 then 
        echo(getScriptName() .. "decorateBackYard: element selection failed for ".. toString(buildMaterial))
        return buildMaterial
    end

    -- rotation = math.random(0,4) *90
    xRealLoc, zRealLoc = -centerP.x + (xLoc * cubeDim.length),
                         -centerP.z + (zLoc * cubeDim.length)
    Move(element, _x_axis, xRealLoc, 0)
    Move(element, _z_axis, zRealLoc, 0)
    Move(element, _y_axis, Level * cubeDim.heigth, 0)

    pieceGroupName = getPieceGroupName(element)

    showSubsAnimateSpins(pieceGroupName, 1)
	addToShowTable(element)

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
		addToShowTable(pieceName_pieceNr[name..1])
    end
end

function getRotationFromPiece(pieceID)
    px,py,pz = Spring.GetUnitPiecePosDir(unitID, pieceID)
    ox,oy,oz = Spring.GetUnitPosition(unitID)
    tx, tz =  px-ox, pz-oz
  
    norm = math.max(math.abs(tx),math.abs(tz))
    tx,tz = tx/norm, (tz/norm)

    if tx >= 0.99  then
        return 0
    end

    if tx <= -0.99  then
        return 180
    end

    if tz >= 0.99 then
        return 90
    end  

    if tz <= -0.99 then
        return -90
    end

    return nil
end

function showSubsAnimateSpins(pieceGroupName, nr)
    if not nr then 
        echo("Subpiece nr not given")
        return 
    end
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

logoPiecesToHide = {}
pieceNameMap = Spring.GetUnitPieceList( unitID ) 
function addRoofDeocrate(Level, buildMaterial, materialColourName)
    echo(getScriptName()..":-->addRoofDeocrate")
    countElements = 0
    if materialColourName == "Office" and maRa() then
        decoChances.roof = 0.65 
    end
    assert(Level)

    roofMaterial = {}
    for name, group in pairs(TablesOfPiecesGroups) do
        if string.find(string.lower(name), "roof") and not string.find(string.lower(name), "sub")  then
            for i=1, #group do
                --echo("Add addRoofDeocrate: group"..name )
                roofMaterial[#roofMaterial+1] = group[i]
            end
        end
    end

    for i = 1, 37, 1 do
        local index = i
        partOfPlan, xLoc, zLoc = getLocationInPlan(index, materialColourName)
        if partOfPlan == true then
            xRealLoc, zRealLoc = -centerP.x + (xLoc * cubeDim.length),-centerP.z + (zLoc * cubeDim.length)

            local element, nr = getRandomBuildMaterial(roofMaterial, materialColourName, index, xLoc, zLoc, Level, " addRoofDeocrate") 
            attempts = maxNrAttempts
            while not element and attempts > 0 do
                element, nr = getRandomBuildMaterial(roofMaterial, materialColourName, index, xLoc, zLoc,   Level," addRoofDeocrate") 
                attempts = attempts - 1
            end

            if attempts == 0 then 
                echo(getScriptName() .. "decorateBackYard:roofMaterial element selection failed for "..materialColourName)
                return materialColourName
            end

            if element then
                rotation = getOutsideFacingRotationOfBlockFromPlan(i)
                countElements = countElements + 1
                buildMaterial = removeElementFromBuildMaterial(element,
                                                               roofMaterial)
                Move(element, _x_axis, xRealLoc, 0)
                Move(element, _z_axis, zRealLoc, 0)
                Move(element, _y_axis, Level * cubeDim.heigth - 0.5, 0)
                WaitForMoves(element)
                Turn(element, _z_axis, math.rad(rotation), 0)
				addToShowTable(element)
                decoPieceUsedOrientation[element] = getRotationFromPiece(element)

                if countElements == 24 then break end
                showSubsAnimateSpinsByPiecename(pieceNr_pieceName[element])
            end
        end
    end

    countElements = 0
    local decoMaterial = getMaterialElementsContaingNotContaining(materialColourName, {"Roof", "Deco"}, {})
    local T = foreach(decoMaterial, function(id) return pieceNr_pieceName[id] end)

    for i = 1, 37, 1 do
        local index = i
        partOfPlan, xLoc, zLoc = getLocationInPlan(i, materialColourName)
        if partOfPlan == true then
            xRealLoc, zRealLoc = -centerP.x + (xLoc * cubeDim.length),
                                 -centerP.z + (zLoc * cubeDim.length)
            local element, nr = getRandomBuildMaterial(decoMaterial, materialColourName, index, xLoc, zLoc, Level, "addRoofDeco") 
            attempts = maxNrAttempts
            while not element and attempts > 0 do
                element, nr = getRandomBuildMaterial(decoMaterial, materialColourName, index, xLoc, zLoc,  Level, "addRoofDeco") 
                attempts = attempts -1
            end

            if attempts == 0 then 
                echo(getScriptName() .. "decorateBackYard:roofDecoMaterials element selection failed for "..materialColourName)
                return materialColourName
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
                decoPieceUsedOrientation[element] = getRotationFromPiece(element)
                if not logoPiecesToHide[element] then
                    showSubsAnimateSpinsByPiecename(pieceNr_pieceName[element])
                end
				addToShowTable(element)
                
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


Icon = piece("Icon")

function buildAnimation()
   
    Show(Icon)
    while boolDoneShowing == false do Sleep(100) end
    Hide(Icon)
    Sleep(15000)
    while boolDoneShowing == false do Sleep(100) end
    showT(ToShowTable)
end

function buildBuilding()
    StartThread(buildAnimation)
    echo(getScriptName() .. "buildBuilding")
    if randChance(5) then
        showOne(TablesOfPiecesGroups["StandAlone"], true)
        boolDoneShowing = true
        return
    end
 
    --echo(getScriptName() .. "selectBase")
    materialColourName = selectGroundBuildMaterial()
    buildingGroupsUpright = getIDGroupsForType(materialColourName, {"ID_u", "ID_a"})
    buildingGroupsLength = getIDGroupsForType(materialColourName, {"ID_l","ID_a"})
    echo(getScriptName() .. "buildDecorateGroundLvl started")
    buildDecorateGroundLvl(materialColourName)
    echo("House_Asian: buildDecorateGroundLvl ended with ")

    echo(getScriptName() .. "selectBase")
    selectBase(materialColourName)
    echo(getScriptName() .. "selectBackYard")
    selectBackYard(materialColourName)
    

    local levelBuildMaterial =  getMaterialElementsContaingNotContaining(materialColourName, {}, {"Roof", "Floor", "Deco"})
    for i = 1, 2 do
        echo(getScriptName() .. "buildDecorateLvl start "..i)
        _, levelBuildMaterial = buildDecorateLvl(i, materialColourName, levelBuildMaterial)
        echo(getScriptName() .. "buildDecorateLvl ended")
    end

    materialTable = getMaterialElementsContaingNotContaining(materialColourName, {"Roof", "Deco"})
    if materialTable and count(materialTable) > 0 then
        echo(getScriptName() .. "addRoofDeocrate started")
        addRoofDeocrate(3, materialTable, materialColourName)
    end
    if randChance(25) then
        showHoloWall()
    end

    echo(getScriptName() .. "addRoofDeocrate ended")
    boolDoneShowing = true
end


function script.Activate() return 1 end

function script.Deactivate() return 0 end

function script.QueryBuildInfo() return center end

Spring.SetUnitNanoPieces(unitID, {center})


