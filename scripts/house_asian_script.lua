include "createCorpse.lua"
include "lib_OS.lua"
include "lib_UnitScript.lua"
include "lib_Animation.lua"
include "lib_debug.lua"

IDGroupsDirection = { 
    "u", --upright
    "l"} -- lengthwise


IDGroups_Trad_Office_Direction = { 
    "u", --upright
    "u", --upright
    "l"} -- lengthwise


--include "lib_Build.lua"
local spGetUnitPosition = Spring.GetUnitPosition
local boolContinousFundamental = maRa() == maRa()
function getScriptName() return "house_asian_script.lua::" end
function lecho(...)
    echo(getScriptName(), ...)
end

local TablesOfPiecesGroups = {}
decoPieceUsedOrientation = {}
factor = 35
heightoffset = 90
maxNrAttempts = 40

BuildDeco = {}

buildingGroupsFloor = {Upright = {}, Length = {}}
buildingGroupsLevel = {Upright = {}, Length = {}}
buildingGroupsRoof = {Upright = {}, Length = {}}

rotationOffset = 90
local pieceNr_pieceName =Spring.GetUnitPieceList ( unitID ) 
local pieceName_pieceNr = Spring.GetUnitPieceMap (unitID)
local cubeDim = {
    length = factor * 22,
    heigth = factor * 14.44 + heightoffset,
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

MapPieceIDName = Spring.GetUnitPieceList(unitID)
materialChoiceTable = {"pod", "industrial", "trad", "office"}
materialChoiceTableReverse = {pod= 1, industrial = 2, trad=3, office=4}

function initAllPieces()
    Signal(SIG_SUBANIMATIONS)
    for pieceName, set in pairs ( pieceCyclicOSTable) do
        startPieceOS(pieceName, SIG_SUBANIMATIONS)
    end
end
function getNameFilteredDictionary( MustContainOne, MustContainAll, MustContainNone)
    return getNameFilteredTableDict( MustContainOne, MustContainAll, MustContainNone, true)
end

function getNameFilteredTable( MustContainOne, MustContainAll, MustContainNone)
    return getNameFilteredTableDict( MustContainOne, MustContainAll, MustContainNone, false)
end


function getNameFilteredTableDict( MustContainOne, MustContainAll, MustContainNone, boolGetNameGroupedDict)
    if not MustContainOne then MustContainOne = {} end
    if not MustContainAll then MustContainAll = {} end
    if not MustContainNone then MustContainNone = {} end


    allMatchingGroups = {}
    MustContainAtLeastOneTerm = {}
	MustContainAllSearchTerms= {}
    MustNotContainSearchTerms= {}
    MustNotContainSearchTerms["sub"] = true
    MustNotContainSearchTerms["spin"] = true
    MustNotContainSearchTerms["base"] = true 
	
    for i=1, #MustContainOne do
        MustContainAtLeastOneTerm[string.lower(MustContainOne[i])] =  true
    end

    for i=1, #MustContainNone do
        MustNotContainSearchTerms[string.lower(MustContainNone[i])] =  true
    end

    for i=1,#MustContainAll do
		MustContainAllSearchTerms[string.lower(MustContainAll[i])] = true
	end

	for groupName, v in pairs(TablesOfPiecesGroups) do
        groupNameLower = string.lower(groupName)

		boolContainedForbidden = false 
		for keyword,_ in pairs(MustNotContainSearchTerms) do
			if string.find(groupNameLower, keyword) then
				--echo("Did find forbidden".. keyword.." in "..groupNameLower)
				boolContainedForbidden = true
				break
			end
		end
		if boolContainedForbidden  == false  then  

        boolFoundAtLeastOne = false 
		for keyword,_ in pairs(MustContainAtLeastOneTerm) do
			if string.find(groupNameLower, keyword) then
				--echo("Found optional ".. keyword.." in "..groupNameLower)
				boolFoundAtLeastOne = true
				break
			end
		end		
		if  boolFoundAtLeastOne == true  or #MustContainAtLeastOneTerm == 0 then  

		boolContainedAll = true
		for keyword,_ in pairs(MustContainAllSearchTerms) do
			if not string.find(groupNameLower, keyword) then
				--echo("Did not find essential ".. keyword.." in "..groupNameLower)
				boolContainedAll = false
				break
			end
		end
		if  boolContainedAll == true then 

 		--echo("Adding id Group with name:"..groupNameLower.." and ".. #v.." members")
        if boolGetNameGroupedDict == true then
			allMatchingGroups[groupName] = v    
		else
			for p=1, #v do
			allMatchingGroups[#allMatchingGroups + 1] = v[p]
			end
		end
        end; end;  end;
    end

	return allMatchingGroups
end


function hasUnitSequentialElements(id)
	return id % 2 == 0 or true
end

deterministicPersistentCounter= 0
deterministicPersistentIndex= 1
--TODO check buildingGroups has material Dimensions
--TODO check buildMaterials are used elsewhere and its flat

function isInPositionSequenceGetPieceID(roundNr, level,materialType,  buildingGroups)
	if not hasUnitSequentialElements(unitID) then return false end
    if not roundNr then echo("invalid roundNr "); return false end
	level= level +1
	Direction = IDGroupsDirection[(unitID % #IDGroupsDirection) +1]
    --materialType = "trad"
    if materialType == "office" or materialType == "trad" then
        Direction = IDGroups_Trad_Office_Direction[(unitID % #IDGroups_Trad_Office_Direction) +1]
    end
    
	groupName = nil
	--upright
	if buildingGroups then
		if Direction == "u"  then
			--if getDeterministicRandom(unitID+roundNr, 3) % 2 == 0 then return false end
			maxIDGroups = count(buildingGroups.Upright)
			assert(maxIDGroups > 1, toString(buildingGroups.Upright))
			PieceGroupIndex = getDeterministicRandom(unitID + roundNr, maxIDGroups) + 1
			groupName, group = getNthDictElement(buildingGroups.Upright, PieceGroupIndex)
			echo("PieceGroupIndex:"..PieceGroupIndex)
			if  not groupName or not group or not group[level] or inToShowDict(group[level]) then
				return false
			else
				return true, group[level]
			end
		end
		
		--lengthwise
		if Direction == "l"  then
			maxIDGroups = count(buildingGroups.Length)
			assert(maxIDGroups > 1)
			PieceGroupIndex = (getDeterministicRandom(unitID + deterministicPersistentCounter, maxIDGroups) + 1 ) 
			echo("PieceGroupIndex:"..PieceGroupIndex)
			groupName, group = getNthDictElement(buildingGroups.Length, PieceGroupIndex)
			
			if  not groupName or not group or not group[deterministicPersistentIndex] then
				deterministicPersistentCounter = deterministicPersistentCounter + 1
				deterministicPersistentIndex= 1
				return false
			end

			if group[deterministicPersistentIndex] and inToShowDict(group[deterministicPersistentIndex]) then
				deterministicPersistentIndex = deterministicPersistentIndex +1
				return false
			end

			-- existence
			if group[deterministicPersistentIndex] then 
				value =group[deterministicPersistentIndex]
				deterministicPersistentIndex = deterministicPersistentIndex +1
				return true, value, deterministicPersistentIndex
			end
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
    resetT(TablesOfPiecesGroups["HoloTile"])
    hideT(TablesOfPiecesGroups["HoloTile"])
    step = 6*4
    index = math.random(0,#TablesOfPiecesGroups["HoloTile"]/step)
    if maRa() == maRa() then
        for i=index * step,  (index+1) * step, 1 do
            if TablesOfPiecesGroups["HoloTile"][i] then
                if (maRa() == maRa()) ~= maRa() then
                    Hide(TablesOfPiecesGroups["HoloTile"][i])
                else
                    Show(TablesOfPiecesGroups["HoloTile"][i])
    				addToShowTable( TablesOfPiecesGroups["HoloTile"][i], "showHoloWall", i)
                end
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
				addToShowTable(v, "showOne", k)
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
			addToShowTable(val, "showOneOrAll", num)
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
						break
                    end
                end
            end
            if mustExclude  and not boolNope then
                for exclude=1, #mustExclude do
                    if mustExclude[exclude] and string.find(name, mustExclude[exclude]) then
                        boolNope = true
						break
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
        value, key = getSafeRandom(MaterialCandiDates, MaterialCandiDates[1])
        return value, key
    end

    value, key =  getSafeRandom(AllCandiDates, AllCandiDates[1])    
    return value, key
end

function showRegPiece(pID)
    Show(pID)
	addToShowTable(pID, "showRegPiece", pID)
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

    if not nice then nice = math.random(1,4) end

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
    local Deco, nr = getRandomBuildMaterial(DecoMaterial, materialGroupName, xRealLoc, zRealLoc, level)
    while not Deco and attempts  > 0 do
        Deco, nr = getRandomBuildMaterial(DecoMaterial, materialGroupName, xRealLoc, zRealLoc, level)
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
		addToShowTable(Deco, xLoc, zLoc)
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

function getRandomBuildMaterial(buildMaterial, name, index, x, z, level, buildingGroups)

--[[    if buildingGroups then
        assert(type(buildingGroups)== "table")
    end--]]
    if not buildMaterial then
        echo(getScriptName() .. "getRandomBuildMateria: Got no table "..name);
        return
    end
    if not type(buildMaterial) == "table" then
		echo( getScriptName() .. "getRandomBuildMateria: Got not a table, got" ..   type(buildMaterial) .. "instead");
        return
    end

    if count(buildMaterial) == 0 and #buildMaterial == 0 then
      echo(getScriptName() .. "getRandomBuildMateria: Got a empty table "..name)
      echo( "No materials left for "..name.. " at level ".. toString(level))
      return
    end

	--TODO Move to total separate function, this thing is neither random nor connected with the buildMaterial handed to the function
    roundNr = convertIndexToRoundNr(index)
    if roundNr then
        --echo("Derived ".. toString(roundNr).." from "..toString(index))
    	isInRoundNr, piecenum = isInPositionSequenceGetPieceID(roundNr, level, name, buildingGroups) 

    	if isInRoundNr and piecenum then
            echo("resorting to sequence for level " ..level.. "for material " ..name.. " with piece ".. toString(MapPieceIDName[piecenum]).." selected") 
           return piecenum
    	end
    end

    piecenum, num = getSafeRandom(buildMaterial, buildMaterial[1]) 
	if not inToShowDict(piecenum)  then
        echo("resorting to random piece for level " ..toString(level).. "for material " ..name.. " with piece ".. toString(MapPieceIDName[piecenum]).." selected") 
		return piecenum, num
	end

    --echo(" Returning nil in getRandomBuildMateria in context".. toString(context)) 
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
    

boolOpenBuilding = maRa()

-- x:0-6 z:0-6
function getLocationInPlan(index, materialColourName)
    if materialColourName == "office" and boolOpenBuilding and NotInPlanIndeces[index] then return false, 0,0 end

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


function inToShowDict(element)
	return toShowDict[element] ~= nil
end

toShowDict = {}
function addToShowTable(element, indeX, indeY, addition)
    assert(element)
    assert(MapPieceIDName[element])
	echo("Piece placed:"..toString(MapPieceIDName[element]).." at ("..toString(indeX).."/"..toString(indeY)..") ".. toString(addition))
	ToShowTable[#ToShowTable + 1] = element	
	toShowDict[element] = true
end	

function buildDecorateGroundLvl(materialColourName)
    echo(getScriptName()..":buildDecorateLGroundLvl")

    local yardMaterial = getNameFilteredTable({materialColourName}, {"Yard","Deco", "Floor"}, {})
    local StreetDecoMaterial = getNameFilteredTable({materialColourName}, { "Deco", "Floor", "Street"}, {})
    local floorBuildMaterial = getNameFilteredTable({}, {materialColourName}, {"Roof", "Deco", "Yard"}) 
    echo("floorBuildMaterial", floorBuildMaterial)
    countElements = 0

    for i = 1, 37, 1 do

        local index = i
        --echo(getScriptName() .. "buildDecorateGroundLvl" .. i)
        rotation = getOutsideFacingRotationOfBlockFromPlan(index)
        partOfPlan, xLoc, zLoc = getLocationInPlan(index, materialColourName)
        if partOfPlan == true then 

            xRealLoc, zRealLoc = -centerP.x + (xLoc * cubeDim.length), -centerP.z + (zLoc * cubeDim.length)
            local element = getRandomBuildMaterial(floorBuildMaterial, materialColourName, index, xLoc, zLoc,  0, buildingGroupsFloor)
            attempts = maxNrAttempts
            while  (not element  or  inToShowDict(element)) and attempts > 0 do
                element = getRandomBuildMaterial(floorBuildMaterial, materialColourName, index, xLoc, zLoc,  0, buildingGroupsFloor )
                attempts = attempts -1
            end

            if attempts == 0 then 
                echo(getScriptName() .. "buildDecorateGroundLvl: element selection failed for ".. materialColourName.. " at "..index)
                return materialColourName
            end

            if element then
                assert(xRealLoc)
                assert(zRealLoc)
                countElements = countElements + 1
                floorBuildMaterial = removeElementFromBuildMaterial(element, floorBuildMaterial)
                Move(element, _x_axis, xRealLoc, 0)
                Move(element, _z_axis, zRealLoc, 0)
                rotation = getOutsideFacingRotationOfBlockFromPlan(index)
                Turn(element, 3, math.rad(rotation), 0)
                addToShowTable(element, xLoc, zLoc, i)
    			echo("Placed GroundLevel element at "..i)
                showSubsAnimateSpinsByPiecename(pieceName_pieceNr[element]) 
                if countElements == 24 then
                    return materialColourName
                end        

                if chancesAre(10) < decoChances.street then
                    rotation = getOutsideFacingRotationOfBlockFromPlan(index)
                    StreetDecoMaterial, StreetDeco =   DecorateBlockWall(xRealLoc, zRealLoc, 0, StreetDecoMaterial, 0, materialColourName)
                    if StreetDeco then
                        Turn(StreetDeco, 3, math.rad(rotation), 0)
                        showSubsAnimateSpinsByPiecename(pieceName_pieceNr[StreetDeco]) 
                    end
                end
            end  

            if isBackYardWall(index) == true then
                -- BackYard
                if yardMaterial and #yardMaterial > 0 and chancesAre(10) < decoChances.yard then
                    rotation = getWallBackyardDeocrationRotation(index) + math.random(-10,10)/10
                    yardMaterial, yardDeco = decorateBackYard(index, xLoc, zLoc, yardMaterial, 0, materialColourName)
                    if yardDeco then
                        Turn(yardDeco, _z_axis, math.rad(rotation), 0)
                    end
                end
            end
        end
    end

    return materialColourName
end

function chancesAre(outOfX) return (math.random(0, outOfX) / outOfX) end

lvlPlaced = {}
function buildDecorateLvl(Level, materialGroupName, buildMaterial)
    echo(getScriptName()..":buildDecorateLvl"..Level.." for "..materialGroupName)
    Sleep(1)
    assert(buildMaterial, "no material table in" ..Level.." for "..materialGroupName)
    assert(type(buildMaterial)== "table")
    assert(Level)
    lvlPlaced = {}

    local yardMaterial = getNameFilteredTable({}, {"Yard", "Deco"}, { "Floor", "Roof", "Base"}) -- TODO materialGroupName
    local streetWallDecoMaterial = getNameFilteredTable({}, {"Street", "Deco"}, { "Floor", "Roof", "Base"}) -- TODO materialGroupName

	--assert(#streetWallDecoMaterial > 0)

    if string.lower(materialGroupName) == "office" then
        yardMaterial = getNameFilteredTable( {materialGroupName},{"Yard", "Wall"}, {"trad","industrial"})
    end

    --echo(getScriptName() .. count(WindowWallMaterial) .. "|" .. count(yardMaterial) .. "|" .. count(streetWallDecoMaterial))

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
            local element = getRandomBuildMaterial(buildMaterial, materialGroupName, index, xLoc, zLoc,  Level, buildingGroupsLevel )
            attempts = maxNrAttempts
            while (not element  or  inToShowDict(element)) and attempts > 0 do
                element = getRandomBuildMaterial(buildMaterial, materialGroupName, index, xLoc, zLoc,  Level, buildingGroupsLevel)
                attempts = attempts-1
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
                lvlPlaced[index] = element
                WaitForMoves(element)
                Turn(element, _z_axis, math.rad(rotation), 0)
                -- echo("Adding Element to level"..Level)
				addToShowTable(element, xLoc, zLoc) -- Todo Smart Argument grab, argument grab via NN the best available match.
				
                if countElements == 24 then
                    return materialGroupName, buildMaterial
                end
            end
			
            if chancesAre(10) < decoChances.streetwall  then
                assert(type(streetWallDecoMaterial) == "table")
                assert(index)
                assert(xRealLoc)
                assert(zRealLoc)
                assert(count(streetWallDecoMaterial) > 0)
                assert(Level)
                assert(streetWallDecoMaterial)

                streetWallDecoMaterial, streetWallDeco = DecorateBlockWall(xRealLoc, zRealLoc, Level, streetWallDecoMaterial, 0, materialGroupName)
                echo("Decorating street walls with "..toString(pieceID_NameMap[streetWallDeco]))
                if streetWallDeco then
                    rotation = getStreetWallDecoRotation(index)+ (math.random(-10,10) / 20)
                    Turn(streetWallDeco, _z_axis, math.rad(rotation), 0)
                    showSubsAnimateSpinsByPiecename(pieceNr_pieceName[streetWallDeco])
                    addToShowTable(streetWallDeco, xLoc, zLoc)
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

                yardMaterial, yardWall = decorateBackYard(index, xLoc, zLoc, yardMaterial, Level, materialGroupName)
                assert(type(yardMaterial) == "table")
             echo("Decorating yard walls with "..toString(pieceID_NameMap[yardWall]))
                if yardWall then
                    rotation = getWallBackyardDeocrationRotation(index)
                    Turn(yardWall, _z_axis, math.rad(rotation), 0)
                    showSubsAnimateSpinsByPiecename(pieceNr_pieceName[yardWall])
                end
            end
        end
    end
    Spring.Echo("Completed buildDecorateLvl")
   
    return materialGroupName, buildMaterial
end

function decorateBackYard(index, xLoc, zLoc, buildMaterial, Level, name)
    echo(getScriptName()..":decorateBackYard")  
    assert(buildMaterial)
    assert(Level)

    countedElements = count(buildMaterial)
    if countedElements == 0 then return buildMaterial end

    local element, nr = getRandomBuildMaterial(buildMaterial, name, index, xLoc, zLoc, Level)
    attempts = maxNrAttempts


    while (not element or inToShowDict(element)) and attempts > 0 do
        element, nr = getRandomBuildMaterial(buildMaterial, name, index, xLoc, zLoc, Level)
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
	addToShowTable(element, xLoc, zLoc)

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
		addToShowTable(pieceName_pieceNr[name..1], "showOneOrAllOfTablePieceGroup", name)
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
    if materialColourName == "pod" and maRa() then
        decoChances.roof = 0.65 
    end
    assert(Level)

    roofMaterial =  getNameFilteredTable({}, {"Roof"}, {"Deco"}) -- TODO materialGroupName

    for i = 1, 37, 1 do
        local index = i
        partOfPlan, xLoc, zLoc = getLocationInPlan(index, materialColourName)
        if partOfPlan == true then
            xRealLoc, zRealLoc = -centerP.x + (xLoc * cubeDim.length),-centerP.z + (zLoc * cubeDim.length)

            local element, nr = getRandomBuildMaterial(roofMaterial, materialColourName, index, xLoc, zLoc, Level) 
            attempts = maxNrAttempts
            while (not element or inToShowDict(element)) and attempts > 0 do
                element, nr = getRandomBuildMaterial(roofMaterial, materialColourName, index, xLoc, zLoc,   Level) 
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

                offset = 0
                --offset if one of the last level was not placed due to offset
                if not lvlPlaced[i] then
                    offset = -cubeDim.heigth 
                end
                Move(element, _x_axis, xRealLoc, 0)
                Move(element, _z_axis, zRealLoc, 0)
                Move(element, _y_axis, Level * cubeDim.heigth - 0.5 + offset, 0)
                WaitForMoves(element)
                Turn(element, _z_axis, math.rad(rotation), 0)
				addToShowTable(element, xLoc, zLoc)
                decoPieceUsedOrientation[element] = getRotationFromPiece(element)

                if countElements == 24 then break end
                showSubsAnimateSpinsByPiecename(pieceNr_pieceName[element])
            end
        end
    end

    countElements = 0
    local decoMaterial = getNameFilteredTable({materialColourName}, {"Roof", "Deco"}, {})
    local T = foreach(decoMaterial, function(id) return pieceNr_pieceName[id] end)

    for i = 1, 37, 1 do
        local index = i
        partOfPlan, xLoc, zLoc = getLocationInPlan(i, materialColourName)
        if partOfPlan == true then
            xRealLoc, zRealLoc = -centerP.x + (xLoc * cubeDim.length),
                                 -centerP.z + (zLoc * cubeDim.length)
            local element, nr = getRandomBuildMaterial(decoMaterial, materialColourName, index, xLoc, zLoc, Level) 
            attempts = maxNrAttempts
            while (not element or inToShowDict(element)) and attempts > 0 do
                element, nr = getRandomBuildMaterial(decoMaterial, materialColourName, index, xLoc, zLoc,  Level) 
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
				addToShowTable(element, xLoc, zLoc)
                
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
    --materialColourName = "office"
    buildingGroupsFloor.Upright = getNameFilteredDictionary( {"ID_u", "ID_a"},  { materialColourName}, {"Roof"})
	buildingGroupsLevel.Upright = getNameFilteredDictionary({"ID_u", "ID_a"},{materialColourName}, {"Floor", "Roof","Deco"})
    buildingGroupsFloor.Length = getNameFilteredDictionary( {"ID_l", "ID_a"},  { materialColourName}, {"Roof"})
    buildingGroupsLevel.Length = getNameFilteredDictionary( {"ID_l", "ID_a"}, {materialColourName},{"Floor", "Roof", "Deco"})
    echo("buildingGroupsFloor.Upright", buildingGroupsFloor.Upright)
    echo("buildingGroupsFloor.Length", buildingGroupsFloor.Length)
    echo("buildingGroupsLevel.Length", buildingGroupsLevel.Length)
    echo("buildingGroupsLevel.Upright", buildingGroupsLevel.Upright)

    echo(getScriptName() .. "buildDecorateGroundLvl started")
    buildDecorateGroundLvl(materialColourName)
    echo("House_Asian: buildDecorateGroundLvl ended with ")

    echo(getScriptName() .. "selectBase")
    selectBase(materialColourName)
    echo(getScriptName() .. "selectBackYard")
    selectBackYard(materialColourName)    

    local levelBuildMaterial = getNameFilteredTable({}, {materialColourName}, {"Floor","Roof", "Deco"})
    height = math.random(2,3)
	for i = 1, height do
        echo(getScriptName() .. "buildDecorateLvl start "..i)
        _, levelBuildMaterial = buildDecorateLvl(i, materialColourName, levelBuildMaterial)
        echo(getScriptName() .. "buildDecorateLvl ended")
    end

	materialTable = getNameFilteredTable({materialColourName}, {"Roof", "Deco"}, {"Floor","Base"})
    if materialTable and count(materialTable) > 0 then
        echo(getScriptName() .. "addRoofDeocrate started")
        addRoofDeocrate(height + 1, materialTable, materialColourName)
    end
    if randChance(25) then
        Sleep(50)
        showHoloWall()
    end

    echo(getScriptName() .. "addRoofDeocrate ended")
    boolDoneShowing = true
end


function script.Activate() return 1 end

function script.Deactivate() return 0 end

function script.QueryBuildInfo() return center end

Spring.SetUnitNanoPieces(unitID, {center})


