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

--Riesenrad
pieceLimits = {
    ["Office_Pod_BaseAddition"] = 2
}
pieceCyclicOSTable = {}

local spGetUnitPosition = Spring.GetUnitPosition
local boolContinousFundamental = maRa() == maRa()
function getScriptName() return "house_asian_script:: " end
function lecho(...)
	--toStringBuild = ""	
	--arg = {...};
	--arg.n = #arg
	--for k,v in pairs(arg) do
	--	toStringBuild = toStringBuild ..",".. toString(v)
	--end
  --
    --echo(getScriptName()..toStringBuild)
end
LevelPieces = {}
local TablesOfPiecesGroups = {}
decoPieceUsedOrientation = {}
factor = 35
heightoffset = 90
maxNrAttempts = 40

local buildingGroupsFloor = {Upright = {}, Length = {}}
local buildingGroupsLevel = {Upright = {}, Length = {}}
local buildingGroupsRoof = {Upright = {}, Length = {}}
center = piece "center"
Icon = piece("Icon")
ErrorIcon = piece("ErrorIcon")
	
rotationOffset = 90
local pieceNr_pieceName =Spring.GetUnitPieceList ( unitID ) 
local pieceName_pieceNr = Spring.GetUnitPieceMap (unitID)
local cubeDim = {
    length = factor * 22,
    heigth = factor * 14.44 + heightoffset,
    roofHeigth = 50
}

dayNightPieceNames = {}
local SIG_SUBANIMATIONS = 2



supriseChances = {
    roof = 0.35,
    yard = 0.6,
    yardWall = 0.4,
    street = 0.5,
    powerpoles = 0.5,
    door = 0.6,
    windowwall = 0.7,
    streetwall = 0.5
}

decoChances = {
    roof = 0.2,
    yard = 0.1,
    yardWall = 0.4,
    street = 0.1,
    powerpoles = 0.5,
    door = 0.6,
    windowwall = 0.5,
    streetwall = 0.1
}

holoPieces = {
                [piece("Office_Pod_Industrial_Roof10")] = true, 
                [piece("Office_Pod_Industrial_Roof2")] = true,
                [piece("Office_Pod_Industrial_Roof1")] = true,
                [piece("Roof77")] = true
            }

pieceID_NameMap = Spring.GetUnitPieceList(unitID)
materialChoiceTable = {"pod", "industrial", "trad", "office"}
materialChoiceTableReverse = {pod= 1, industrial = 2, trad=3, office=4}
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

local deterministicPersistentCounter= 0
local deterministicPersistentIndex= 1
local GameConfig = getGameConfig()
local lvlPlaced = {}
local roundNrTable =
    {1,     2,      3,       4,     5,      6,
    20,     nil,     nil,   nil,    nil,    7,
    19,     nil,     nil,   nil,    nil,    8,
    18,     nil,     nil,   nil,    nil,    9,
    17,     nil,     nil,   nil,    nil,    10,
    16,     15,     14,     13,     12,     11,
    }
--First instance initialisation
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
boolDoneShowing = false
boolHouseHidden = false
Spring.SetUnitNanoPieces(unitID, {center})

function isWithinPieceLimits(pieceID)
    name = pieceID_NameMap[pieceID]
    if not pieceLimits[name]  then return true end
    if not GG.house_asian_pieces_used then GG.house_asian_pieces_used  = {} end
    if not GG.house_asian_pieces_used[name] then GG.house_asian_pieces_used[name]  = 0 end

    if GG.house_asian_pieces_used[name] < pieceLimits[name] then
        GG.house_asian_pieces_used[name] = GG.house_asian_pieces_used[name] +1
        return true
    end
    return false
end

function factoryAnimation(spinPiece, upPiece, lavaContainer, moltenPiecesT)
	rotationArc= 180 / #moltenPiecesT
	containerOffsetValue = 9000 --TODO
    moltenMax = 8 
	while true do
		--starting
		if maRa()== maRa() then
			reset(spinPiece, 0)
			--Arriving molten metall containerAnimation
			startValue = randSign()* containerOffsetValue
			Move(lavaContainer,x_axis, startValue, 0)
			Show(lavaContainer)
			WMove(lavaContainer,x_axis, 0, 10)
			--Blobanimation
			--Giesserei
			for i=1, moltenMax do
				Show(upPiece)
				Move(upPiece, y_axis, -20, 0)
				WMove(upPiece, y_axis, 0, 5)
				Show(moltenPiecesT[i])
				Hide(upPiece)
				WTurn(spinPiece, y_axis, math.rad(i*rotationArc),10)
			end
		-- ending
			offset = math.rad(#moltenPiecesT*rotationArc)
			for i=1, moltenMax do
				--craneAnimation
				Hide(moltenPiecesT[i])
				WTurn(spinPiece, y_axis, math.rad(offset + i* rotationArc), 10)
			end
		end

	Sleep(500)
	end
end

function initAllPieces()
    pieceCyclicOSTable = {
   ["ID_a1_Office_Industrial_Pod_Wall3Sub1"] = {
                    {"turn", y_axis, 20, 3},
                    {"turn", y_axis, -20, 3},                 
                    },    
    ["ID_l100_Industrial_RoofBlock3Sub1"] = {
                    {"move", x_axis, 30, 3},
                    {"move", x_axis, -30, 3},                 
                    }, 
    ["ID_l100_Industrial_RooflBlock2"] = {
        {"func",factoryAnimation, piece("ID_l100_Industrial_RoofBlock2Spin1"), piece("ID_l100_Industrial_RoofBlock2Raise"),TablesOfPiecesGroups["ID_l100_Industrial_RoofBlock2Sub"]}
        }
                
    }

    Signal(SIG_SUBANIMATIONS)
    for pieceName, set in pairs (pieceCyclicOSTable) do
		if pieceName_pieceNr[pieceName] and toShowDict[pieceName_pieceNr[pieceName]] then
			startPieceOS(pieceName, SIG_SUBANIMATIONS, table.unpack(set))
		end
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
				--lecho("Did find forbidden".. keyword.." in "..groupNameLower)
				boolContainedForbidden = true
				break
			end
		end
		if boolContainedForbidden  == false  then  

        boolFoundAtLeastOne = false 
		for keyword,_ in pairs(MustContainAtLeastOneTerm) do
			if string.find(groupNameLower, keyword) then
				--lecho("Found optional ".. keyword.." in "..groupNameLower)
				boolFoundAtLeastOne = true
				break
			end
		end		
		if  boolFoundAtLeastOne == true  or #MustContainAtLeastOneTerm == 0 then  

		boolContainedAll = true
		for keyword,_ in pairs(MustContainAllSearchTerms) do
			if not string.find(groupNameLower, keyword) then
				--lecho("Did not find essential ".. keyword.." in "..groupNameLower)
				boolContainedAll = false
				break
			end
		end
		if  boolContainedAll == true then 

 		--lecho("Adding id Group with name:"..groupNameLower.." and ".. #v.." members")
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

function isInPositionSequenceGetPieceID(roundNr, level,materialType,  buildingGroups)
	if not hasUnitSequentialElements(unitID) then return false end
    if not roundNr then lecho("invalid roundNr "); return false end
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
			lecho("PieceGroupIndex:"..PieceGroupIndex)
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
			lecho("PieceGroupIndex:"..PieceGroupIndex)
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

function timeOfDay()
    WholeDay = GameConfig.daylength
    timeFrame = Spring.GetGameFrame() + (WholeDay * 0.25)
    return ((timeFrame % (WholeDay)) / (WholeDay))
end

function script.Create()
    TablesOfPiecesGroups = getPieceTableByNameGroups(false, true)
	assertPieceNamesUnique(unitID)
    x, y, z = spGetUnitPosition(unitID)
    StartThread(removeFeaturesInCircle,x,z, GameConfig.houseSizeZ/2)

    math.randomseed(x + y + z)
    StartThread(buildHouse)

    vtolDeco = {
        ["ID_l100_Industrial_RoofBlock1"] = TablesOfPiecesGroups["ID_l100_Industrial_RoofBlock1Sub"][27],
        ["Roof01"] = TablesOfPiecesGroups["Roof01Sub"][1],
        ["Roof05"] = TablesOfPiecesGroups["Roof05Sub"][1]     
    }

    StartThread(HoloGrams)	
end

function HoloGrams()
    while   boolDoneShowing == false do
        Sleep(100)
    end
    rest= (7 + math.random(1,7))*1000
    Sleep(rest)
    if maRa() == maRa() and not  isNearCityCenter(px,pz, GameConfig) then return end


    for logoPiece,v in pairs(holoPieces)do
        if contains(ToShowTable, logoPiece) then 
            if not decoPieceUsedOrientation[logoPiece] then lecho(unitID..":"..pieceID_NameMap[logoPiece].." has no value assigned to it") end
            StartThread(moveCtrlHologramToUnitPiece, unitID, "house_western_hologram_buisness", logoPiece, decoPieceUsedOrientation[logoPiece] )
            break
        end
    end

    px,py,pz = spGetUnitPosition(unitID)
    boolIsNearCityCenter, distanceToCenter = isNearCityCenter(px,pz, GameConfig)
    if getDeterministicCityOfSin(getCultureName(), Game)== true and boolIsNearCityCenter == true or mapOverideSinCity() then
        hostPiece =  nil
		for k,v in pairs(holoPieces) do
			if maRa() then
				hostPiece= k
			end
		end
		if not hostPiece then return end
		
        if maRa()== true and contains(ToShowTable, hostPiece) == true then
            if not decoPieceUsedOrientation[hostPiece] then lecho( unitID..":"..pieceID_NameMap[hostPiece].." has no value assigned to it") end
            StartThread(moveCtrlHologramToUnitPiece, unitID, "house_western_hologram_brothel", hostPiece, decoPieceUsedOrientation[hostPiece] )
        else 
            if contains(ToShowTable, hostPiece) == true then 
                StartThread(moveCtrlHologramToUnitPiece, unitID, "house_western_hologram_casino", hostPiece, decoPieceUsedOrientation[hostPiece] )
            end
        end
    end  
end

function turnPixelOff(pixel)
    if pixel then
	Turn(pixel, y_axis, math.rad(180),0)
    end
end

function HoloFlicker(tiles,alttiles)
    if not tiles or #tiles < 2 then return end
	holoDecoFunctions= {}
		--dead pixel
	holoDecoFunctions[#holoDecoFunctions+1]= function(tiles)
								one = math.random(1,#tiles)
                                if not tiles[one] then return end
                                tile =tiles[one]
                                if tile then
                                    for i=1,5 do
    								    turnPixelOff(tile)
    								    restTimeMs = 250*i
    								    Sleep(restTimeMs)
    								    reset(tile)
                                        Sleep(restTimeMs)
                                    end
                                        turnPixelOff(tile)
                                        restTimeMs = (math.random(1,100)/100)*10000
                                        Sleep(restTimeMs)
                                        for i=1, #tiles do
											reset(tiles[i])
										end
                                        Sleep(restTimeMs)
							     end	
                            end 

	--Send Pixel drifting upwards
	holoDecoFunctions[#holoDecoFunctions+1]= function(tiles)
								function moveUpardwsFlicker(tile)
									Show(tile)
									dist = math.random(100,250)
									Move(tile, y_axis,  dist, 25)	
									WaitForMoves(tile)
									Hide(tile)
									reset(tile)
								end
								for k, v in pairs(tiles) do
									StartThread(moveUpardwsFlicker, v)
								end
								Sleep(250)
								WaitForMoves(tiles)
								Sleep(10000)
							end
	--whole wall flicker dead
	holoDecoFunctions[#holoDecoFunctions+1]= function(tiles)
								for k, v in pairs(tiles) do
									turnPixelOff(v)
								end
								restTimeMs = (math.random(1,500)/100)*10000
								Sleep(restTimeMs)
								for i=1, #tiles do
									reset(tiles[i])
								end
							end	
	--short dead line
	holoDecoFunctions[#holoDecoFunctions+1]= function(tiles)
								for i=1,#tiles, 6 do
									for j=i, i+6 do
									   turnPixelOff(tiles[j])
									end						
									restTimeMs = (math.random(1,100)/100)*1000
									Sleep(restTimeMs)
									for j=i, i+6 do
									   reset(tiles[j])
									end									
								end
							end	
	--Hide one Tile
	holoDecoFunctions[#holoDecoFunctions+1] = function (tiles)
			dice = getDeterministicRandom(unitID, #tiles) +1
			tileFallingOff = tiles[dice]
            if tileFallingOff then
    			WMove(tileFallingOff,y_axis, -10, 100)
    			Hide(tileFallingOff)
    			restTime = math.random(1,100)*25000
    			Sleep(restTime)
    			reset(tileFallingOff)
    			Show(tileFallingOff)
            end
		end
	--scaleflair effect
	holoDecoFunctions[#holoDecoFunctions+1] = function (tiles)
			axis = y_axis
			for i=1, #tiles do
                factor = ((i%6)+1)/6
				fraction = factor* 45
				Move(tiles[i], z_axis, factor *-20 , 15)
				Turn(tiles[i], axis, math.rad(fraction), 5)
			end
			WaitForTurns(tiles)
			Sleep(5000)
			for i=1, #tiles do
                Move(tiles[i], z_axis, 0 , 15)
                Turn(tiles[i], axis,0, 5)
            end
			WaitForTurns(tiles)
            WaitForMoves(tiles)
		end
	--whole wall flicker dead
    holoDecoFunctions[#holoDecoFunctions+1]= function(tiles, alttiles)
                                for k, v in pairs(tiles) do
                                    turnPixelOff(v)                                    
                                end
                                WaitForTurns(tiles)                                
                                restTimeMs = (math.random(1,500)/100)*10000
                                Sleep(restTimeMs)
                                hideT(tiles)
                                for k, v in pairs(alttiles) do
                                    turnPixelOff(v)
                                end
                                showT(alttiles)
								for i=1, #alttiles do
									reset(alttiles[i])
								end
   
                                restTimeMs = (math.random(1,500)/100)*10000
                                Sleep(restTimeMs)
                                hideT(alttiles)
                                showT(tiles)
                              	for i=1, #tiles do
									reset(tiles[i])
								end
                            end 
	while true do
		Sleep(10000)
		for i=1, #tiles do
			reset(tiles[i])
		end
		showT(tiles)
		dice= math.random(1, #holoDecoFunctions)
		lecho("HololWallFunction"..dice)
        holoDecoFunctions[dice](tiles, alttiles)
	end
end

function showHoloWall()
	HoloPieces = {}
    AltHoloPieces = {}    
    hideT(TablesOfPiecesGroups["HoloTile"])
    step = 6*4
    hindex = math.random(0,(#TablesOfPiecesGroups["HoloTile"]/step)-1)
    althindex = math.random(0,(#TablesOfPiecesGroups["HoloTile"]/step)-1)
    if maRa() == maRa() then
            ai= althindex * step
        for i=hindex * step,  (hindex+1) * step, 1 do
            if TablesOfPiecesGroups["HoloTile"][i] then
                if (maRa() == maRa()) ~= maRa() then
                    Hide(TablesOfPiecesGroups["HoloTile"][i])
                else
					HoloPieces[#HoloPieces +1] = TablesOfPiecesGroups["HoloTile"][i]
                    if TablesOfPiecesGroups["HoloTile"][ai] then
                        AltHoloPieces[#AltHoloPieces +1] = TablesOfPiecesGroups["HoloTile"][ai]
                    end
                    Show(TablesOfPiecesGroups["HoloTile"][i])
    				addToShowTable( TablesOfPiecesGroups["HoloTile"][i], "showHoloWall", i)
                end
            end
            ai= ai+1
        end

		HoloFlicker(HoloPieces, AltHoloPieces)
        
    end
    --TODO the engine has a problem, right here and then. No error on erroneous access, just dead function and worser still, post processing shutd
	--showT(TablesOfPiecesGroups["HoloTile"],index * step, (index+1) * step)
end

function buildHouse()
    resetAll(unitID)
    hideAll(unitID)
    Sleep(1)
    buildBuilding()
    if randChance(25)  then
       Sleep(500)
       StartThread(showHoloWall)
    end
end

function absdiff(value, compval)
    if value < compval then return math.abs(compval - value) end
    return math.abs(value - compval)
end

function script.Killed(recentDamage, _)
	houseDestroyWithDestructionTable(LevelPieces, 49.81, unitID)
    return 1
end

function showOne(T)
    if not T then return end
    dice = math.random(1, count(T))
    c = 0
    assert(T)
    for k, v in pairs(T) do
        if k and v then c = c + 1 end
        if c == dice then
			addToShowTable(v, "showOne", k)
            return v
        end
    end
end

function showOneOrNone(T)
    if not T then return end
    if math.random(1, 100) > 50 then
        return showOne(T)
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
    while basePiece do
    if basePiece and isWithinPieceLimits(basePiece) then
        showRegPiece(basePiece)       
        lecho("BasePiece: ".. getPieceName(unitID, basePiece))
        return
    end
    basePiece = getMaterialBaseNameOrDefault(materialType, {"Base"}, {"Deco"})
    end
end

function selectBackYard(materialType) 
    yardDecoPice = getMaterialBaseNameOrDefault(materialType, {"Base", "Deco"}, {})

    lecho("BaseDeco: "..toString(yardDecoPice))
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
    if countedElements <= 0 then 
        return DecoMaterial, nil
    end

    y_offset = yoffset or 0
    attempts = maxNrAttempts
    local Deco, nr = getRandomBuildMaterial(DecoMaterial, materialGroupName, xRealLoc, zRealLoc, level)
    while not Deco and attempts  > 0 do
        Deco, nr = getRandomBuildMaterial(DecoMaterial, materialGroupName, xRealLoc, zRealLoc, level)
        Sleep(1)
        attempts = attempts  - 1
    end

    if attempts  == 0 then
       lecho("DecorateBlockWall: ran out of attempts")
        return DecoMaterial, nil
    end

    if Deco then
        DecoMaterial = removeElementFromBuildMaterial(Deco, DecoMaterial)
        Move(Deco, _x_axis, xRealLoc, 0)
        Move(Deco, _y_axis, level * cubeDim.heigth + y_offset, 0)
        Move(Deco, _z_axis, zRealLoc, 0)
		WaitForMoves(Deco)
		addToShowTable(Deco, xLoc, zLoc)
        piecename = getPieceGroupName(Deco)
        if piecename then
            showSubsAnimateSpinsByPiecename(piecename)
        end
    end



    return DecoMaterial, Deco
end

function getIDFromPieceName(name)
    nameSplit = split(name, "_")
    typeID =  string.sub(nameSplit[2], 1, 1)
    group = string.tonumber(string.sub(nameSplit[2],2))
    return typeID, group
end

function convertIndexToRoundNr(groupIndex)    
    return roundNrTable[groupIndex]
end

function getRandomBuildMaterial(buildMaterial, name, index, x, z, level, buildingGroups)

--[[    if buildingGroups then
        assert(type(buildingGroups)== "table")
    end--]]
    if not buildMaterial then
        lecho("getRandomBuildMateria: Got no table "..name);
        return
    end
    if not type(buildMaterial) == "table" then
		lecho( "getRandomBuildMateria: Got not a table, got" ..   type(buildMaterial) .. "instead");
        return
    end
    if count(buildMaterial) == 0 and #buildMaterial == 0 then
      lecho("getRandomBuildMateria: Got a empty table "..name)
      lecho( "No materials left for "..name.. " at level ".. toString(level))
      return
    end

	--TODO Move to total separate function, this thing is neither random nor connected with the buildMaterial handed to the function
    roundNr = convertIndexToRoundNr(index)
    if roundNr then
        --lecho("Derived ".. toString(roundNr).." from "..toString(index))
    	isInRoundNr, piecenum = isInPositionSequenceGetPieceID(roundNr, level, name, buildingGroups) 

    	if isInRoundNr and piecenum then
			assert(pieceID_NameMap[piecenum], "Found a invalid PieceID returned by sequence")
            lecho("stooping to sequence for level " ..level.. "for material " ..name.. " with piece ".. toString(pieceID_NameMap[piecenum]).." selected") 
           return piecenum
    	end
    end
	
	
	piecenum, num = getSafeRandom(buildMaterial, ErrorIcon) 
	if piecenum and not inToShowDict(piecenum)  then
		assert(pieceID_NameMap[piecenum], "Found a invalid PieceID returned randomized material")
		lecho("resorting to random piece for level " ..toString(level).. "for material " ..name.. " with piece ".. toString(pieceID_NameMap[piecenum]).." selected") 
		return piecenum, num
	end


    --lecho(" Returning nil in getRandomBuildMateria in context".. toString(context)) 
   return
end

-- x:0-6 z:0-6
function getLocationInPlan(index, materialColourName)
    if materialColourName == "office" and boolOpenBuilding and NotInPlanIndeces[index] then return false, math.huge, math.huge end

    if index < 7 then return true, (index - 1), 0 end

    if index > 30 and index < 37 then return true, ((index - 30) - 1), 5 end

    if (index % 6) == 1 and (index < 37 and index > 6) then
        return true, 0, math.floor((index - 1) / 6.0)
    end

    if (index % 6) == 0 and (index < 37 and index > 6) then
        return true, 5, math.floor((index - 1) / 6.0)
    end

    return false, math.huge, math.huge
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
    return getOutsideFacingRotationOfBlockFromPlan(index) + 180 + (math.random(-10,10) / 20)
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

function inToShowDict(element)
	return toShowDict[element] ~= nil
end

toShowDict = {}
function addToShowTable(element, indeX, indeY, addition, xLoc, zLoc)
    assert(element)
    assert(pieceID_NameMap[element])
	--lecho("Piece placed:"..toString(pieceID_NameMap[element]).." at ("..toString(indeX).."/"..toString(indeY)..") ".."("..toString(xLoc).."/"..toString(zLoc)..")".. toString(addition))
	ToShowTable[#ToShowTable + 1] = element	
	toShowDict[element] = true
end	

--Problem is sometimes pieces are shown- allocated that should be shown in place ?
--They are not moved, the gaps go unfilled, the shown parts have no sub or spins

function buildDecorateGroundLvl(materialColourName)
    lecho(":buildDecorateLGroundLvl")
    local yardMaterial = getNameFilteredTable({materialColourName}, {"Yard","Deco", "Floor"}, {})
    local StreetDecoMaterial = getNameFilteredTable({materialColourName}, { "Deco", "Floor", "Street"}, {})
    local floorBuildMaterial = getNameFilteredTable({}, {materialColourName}, {"Roof", "Deco", "Yard"}) 
    assertPieceDictValue(unitID, floorBuildMaterial, "GroundLvl:buildMaterial")
    assertPieceDictValue(unitID, StreetDecoMaterial, "GroundLvl:buildMaterial")
    assertPieceDictValue(unitID, yardMaterial, "GroundLvl:buildMaterial")
    for name, group in pairs(buildingGroupsFloor.Upright) do
    assertPieceDictValue(unitID, group, "GroundLvl:buildingGroupsFloor.Upright:"..name)
    end    
    for name, group in pairs(buildingGroupsFloor.Length) do
    assertPieceDictValue(unitID, group, "GroundLvl:buildingGroupsFloor.Length:"..name)
    end

    --lecho("floorBuildMaterial", floorBuildMaterial)
    countElements = 0

    for i = 1, 37, 1 do

        local index = i
        --lecho( "buildDecorateGroundLvl" .. i)
        rotation = getOutsideFacingRotationOfBlockFromPlan(index)
        partOfPlan, xLoc, zLoc = getLocationInPlan(index, materialColourName)
        if partOfPlan == true then 

            xRealLoc, zRealLoc = -centerP.x + (xLoc * cubeDim.length), -centerP.z + (zLoc * cubeDim.length)
            local element, nr = getRandomBuildMaterial(floorBuildMaterial, materialColourName, index, xLoc, zLoc,  0, buildingGroupsFloor)
            attempts = maxNrAttempts
            while  (not element  or  inToShowDict(element)) and attempts > 0 do
                element, nr = getRandomBuildMaterial(floorBuildMaterial, materialColourName, index, xLoc, zLoc,  0, buildingGroupsFloor )
                attempts = attempts -1
            end

            if attempts == 0 then 
                lecho( "buildDecorateGroundLvl: element selection failed for ".. materialColourName.. " at "..index, floorBuildMaterial, buildingGroupsFloor)
                return materialColourName
            end

            if element then
				assert(pieceID_NameMap[element], "element nr "..toString(element).." is not a valid piece")
                assert(type(xRealLoc)=="number")
                assert(type(zRealLoc)=="number")
       
                countElements = countElements + 1
                floorBuildMaterial = removeElementFromBuildMaterial(element, floorBuildMaterial)
                Move(element, _x_axis, xRealLoc, 0)
                Move(element, _z_axis, zRealLoc, 0)
				WaitForMoves(element)
                Sleep(1)
                rotation = getOutsideFacingRotationOfBlockFromPlan(i)

                assert(rotation)
                WTurn(element, 3, math.rad(rotation), 0)
				LevelPieces = houseAddDestructionTable(LevelPieces, 1, element)
                addToShowTable(element, xLoc, zLoc, i, xRealLoc, zRealLoc)
                lecho("Piece placed:"..toString(pieceID_NameMap[element]).." at ("..toString(xLoc).."/"..toString(zLoc)..") ".."("..toString(xRealLoc).."/"..toString(zRealLoc)..") at level".. toString(0))
    
                if( pieceNr_pieceName[element] ) then
                    showSubsAnimateSpinsByPiecename(pieceNr_pieceName[element]) 
                end                
                if countElements == 24 then
                    return materialColourName
                end 


                if chancesAre(10) < decoChances.street then
                    rotation = getOutsideFacingRotationOfBlockFromPlan(i)
                    assert(rotation)
                        StreetDecoMaterial, StreetDeco =   DecorateBlockWall(xRealLoc, zRealLoc, 0, StreetDecoMaterial, 0, materialColourName)
                        if StreetDeco then
                            Turn(StreetDeco, 3, math.rad(rotation), 0)
                            if( pieceNr_pieceName[StreetDeco] ) then
                                showSubsAnimateSpinsByPiecename(pieceNr_pieceName[StreetDeco]) 
                            end
                        end
                end
              
                if  isBackYardWall(i) == true then
                    -- BackYard
                    if yardMaterial and #yardMaterial > 0 and chancesAre(10) < decoChances.yard then
                        rotation = getWallBackyardDeocrationRotation(i) + math.random(-10,10)/10
    					assert(rotation)
                        yardMaterial, yardDeco = decorateBackYard(i, xLoc, zLoc, yardMaterial, 0, materialColourName)
                        if yardDeco then
                            Turn(yardDeco, _z_axis, math.rad(rotation), 0)
                        end
                    end
                end
            end
        end
    end

    return materialColourName
end

function chancesAre(outOfX) return (math.random(0, outOfX) / outOfX) end

function buildDecorateLvl(Level, materialGroupName, buildMaterial)
    lecho(":buildDecorateLvl"..Level.." for "..materialGroupName)
    Sleep(1)


    assert(type(buildMaterial)== "table")
    assertPieceDictValue(unitID, buildMaterial, "GroundLvl:buildMaterial")
    for name, group in pairs(buildingGroupsLevel.Upright) do
    assertPieceDictValue(unitID, group, "GroundLvl:buildingGroupsLevel.Upright:"..name)
    end    
    for name, group in pairs(buildingGroupsLevel.Length) do
    assertPieceDictValue(unitID, group, "GroundLvl:buildingGroupsLevel.Length:"..name)
    end
    assert(Level)
    lvlPlaced = {}

    local yardMaterial = getNameFilteredTable({}, {"Yard", "Deco"}, { "Floor", "Roof", "Base"}) -- TODO materialGroupName
    local streetWallDecoMaterial = getNameFilteredTable({}, {"Street", "Deco"}, { "Floor", "Roof", "Base"}) -- TODO materialGroupName

	--assert(#streetWallDecoMaterial > 0)

    if string.lower(materialGroupName) == "office" then
        yardMaterial = getNameFilteredTable( {materialGroupName},{"Yard", "Wall"}, {"trad","industrial"})
    end

    --lecho( count(WindowWallMaterial) .. "|" .. count(yardMaterial) .. "|" .. count(streetWallDecoMaterial))

    countElements = 0
    px,py,pz = spGetUnitPosition(unitID)
    boolIsNearCityCenter, distanceToCenter = isNearCityCenter(px,pz, GameConfig)

    for i = 1, 37, 1 do
        Sleep(1)
        local index = i
        rotation = getOutsideFacingRotationOfBlockFromPlan(i)

        partOfPlan, xLoc, zLoc = getLocationInPlan(index, materialGroupName)
        xRealLoc, zRealLoc = xLoc, zLoc
        if partOfPlan == true then
			assert(xRealLoc)
            xRealLoc, zRealLoc = -centerP.x + (xLoc * cubeDim.length), -centerP.z + (zLoc * cubeDim.length)
            local element = getRandomBuildMaterial(buildMaterial, materialGroupName, index, xLoc, zLoc,  Level, buildingGroupsLevel )
            attempts = maxNrAttempts
            while (not element  or  inToShowDict(element)) and attempts > 0 do
                element = getRandomBuildMaterial(buildMaterial, materialGroupName, index, xLoc, zLoc,  Level, buildingGroupsLevel)
                attempts = attempts-1
            end
            
            if attempts == 0 then 
                lecho( "buildDecorateLvl: element selection failed for "..materialColourName)
                return materialColourName
            end

            if element then
                if pieceNr_pieceName[element] then
                    showSubsAnimateSpinsByPiecename(pieceNr_pieceName[element])
                end
                countElements = countElements + 1
                buildMaterial = removeElementFromBuildMaterial(element, buildMaterial)
                Move(element, _x_axis, xRealLoc, 0)
                Move(element, _z_axis, zRealLoc, 0)
                Move(element, _y_axis, Level * cubeDim.heigth, 0)
                lvlPlaced[index] = element
                WaitForMoves(element)
				assert(rotation)
                WTurn(element, _z_axis, math.rad(rotation), 0)
                -- lecho("Adding Element to level"..Level)
				LevelPieces = houseAddDestructionTable(LevelPieces, Level + 1, element)
				addToShowTable(element, xLoc, zLoc, index, xRealLoc, zRealLoc)
				lecho("Piece placed:"..toString(pieceID_NameMap[element]).." at ("..toString(xLoc).."/"..toString(zLoc)..") ".."("..toString(xRealLoc).."/"..toString(zRealLoc)..") at level".. toString(Level))
                if countElements == 24 then
                    return materialGroupName, buildMaterial
                end          
			
                if (chancesAre(10) < decoChances.streetwall  or distanceToCenter < GameConfig.innerCityNeonStreet) then
                    assert(type(streetWallDecoMaterial) == "table")
                    assert(index)
                    assert(xRealLoc)
                    assert(zRealLoc)
                    assert(count(streetWallDecoMaterial) > 0)
                    assert(Level)
                    assert(streetWallDecoMaterial)

                    streetWallDecoMaterial, streetWallDeco = DecorateBlockWall(xRealLoc, zRealLoc, Level, streetWallDecoMaterial, 0, materialGroupName)
                    lecho("Decorating street walls with "..toString(pieceID_NameMap[streetWallDeco]))
                    if streetWallDeco then
    					rotation = getOutsideFacingRotationOfBlockFromPlan(index)
    					assert(rotation)
                        Turn(streetWallDeco, _z_axis, math.rad(rotation), 0)
                        if pieceNr_pieceName[streetWallDeco]then
                            showSubsAnimateSpinsByPiecename(pieceNr_pieceName[streetWallDeco])
                        end
                        addToShowTable(streetWallDeco, xLoc, zLoc)
                    end
                end
            end
        end

        if  isBackYardWall(index) == true then
            -- BackYard
            if chancesAre(10) < decoChances.yardWall and xLoc and zLoc then
                assert(type(yardMaterial) == "table")
                assert(index)

                assert(Level)
                assert(yardMaterial)

                yardMaterial, yardWall = decorateBackYard(index, xLoc, zLoc, yardMaterial, Level, materialGroupName)
                assert(type(yardMaterial) == "table")
             lecho("Decorating yard walls with "..toString(pieceID_NameMap[yardWall]))
                if yardWall then
                    rotation = getWallBackyardDeocrationRotation(index)
                    assert(rotation)
					WTurn(yardWall, _z_axis, math.rad(rotation), 0)
			
                    if pieceNr_pieceName[yardWall] then
                        showSubsAnimateSpinsByPiecename(pieceNr_pieceName[yardWall])
                    end
                end
            end
        end
    end
    Spring.Echo("Completed buildDecorateLvl")
   
    return materialGroupName, buildMaterial
end

function decorateBackYard(index, xLoc, zLoc, buildMaterial, Level, name)
    lecho(":decorateBackYard")  
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
   
    if attempts == 0 then 
        lecho( "decorateBackYard: element selection failed for ".. toString(buildMaterial))
        return buildMaterial
    end
	buildMaterial = removeElementFromBuildMaterial(element, buildMaterial)
    
    -- rotation = math.random(0,4) *90
    xRealLoc, zRealLoc = -centerP.x + (xLoc * cubeDim.length), -centerP.z + (zLoc * cubeDim.length)
    Move(element, _x_axis, xRealLoc, 0)
    Move(element, _z_axis, zRealLoc, 0)
    Move(element, _y_axis, Level * cubeDim.heigth, 0)
	WaitForMoves(element)
    showSubsAnimateSpinsByPiecename(pieceID_NameMap[element], 1)
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
        lecho("Subpiece nr not given")
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

function nightAndDay(dayNightPieceNameDict)
    while boolDoneShowing == false do Sleep(100) end

    while true do
        hours, minutes, seconds, percent = getDayTime()
        Sleep(5000)
        if hours > 19 then 
            for dayPieceName,nightPieceName in pairs(dayNightPieceNameDict) do
                randSleep= math.random(1,10)*1000
                Sleep(randSleep)
                if maRa() then
                if pieceName_pieceNr[dayPieceName] then Hide(pieceName_pieceNr[dayPieceName])else echo("No dayPieceName for"..dayPieceName)end
                if pieceName_pieceNr[nightPieceName] then Show(pieceName_pieceNr[nightPieceName]) else echo("No nightPieceName for"..nightPieceName)end
                end
            end

            while hours > 19 or hours < 6 do
                Sleep(5000)
                hours, minutes, seconds, percent = getDayTime()
            end
            for dayPieceName,nightPieceName in pairs(dayNightPieceNameDict) do
                randSleep= math.random(1,10)*1000
                Sleep(randSleep)
                if pieceName_pieceNr[dayPieceName] then Show(pieceName_pieceNr[dayPieceName])else echo("No dayPieceName for"..dayPieceName)end
                if pieceName_pieceNr[nightPieceName] then Hide(pieceName_pieceNr[nightPieceName]) else echo("No nightPieceName for"..nightPieceName)end
            end
        end
    end
end

function addRoofDeocrate(Level, buildMaterial, materialColourName)
	
    lecho(":-->addRoofDeocrate")
    countElements = 0
    if materialColourName == "pod" and maRa() then
        decoChances.roof = 0.65 
    end
    assert(Level)

    roofMaterial =  getNameFilteredTable({}, {"Roof"}, {"Deco", "Night"}) -- TODO materialGroupName

    for i = 1, 37, 1 do
        local index = i
        partOfPlan, xLoc, zLoc = getLocationInPlan(index, materialColourName)
        if partOfPlan == true then
            assert(xLoc)
            assert(zLoc)
            xRealLoc, zRealLoc = -centerP.x + (xLoc * cubeDim.length),-centerP.z + (zLoc * cubeDim.length)

            local element, nr = getRandomBuildMaterial(roofMaterial, materialColourName, index, xLoc, zLoc, Level) 
            attempts = maxNrAttempts
            while (not element or inToShowDict(element)) and attempts > 0 do
                element, nr = getRandomBuildMaterial(roofMaterial, materialColourName, index, xLoc, zLoc,   Level) 
                attempts = attempts - 1
            end

            if attempts == 0 then 
                lecho("decorateBackYard:roofMaterial element selection failed for "..materialColourName)
                return materialColourName
            end

            if element then
                rotation = getOutsideFacingRotationOfBlockFromPlan(i)
                countElements = countElements + 1
                buildMaterial = removeElementFromBuildMaterial(element, roofMaterial)
                if string.find(string.lower(pieceID_NameMap[element]), "day") then
                    dayNightPieceNames[pieceID_NameMap[element]] = replaceStr(pieceID_NameMap[element], "Day", "Night")
                end

                offset = 0
                --offset if one of the last level was not placed due to offset
                if not lvlPlaced[i] then
                    offset = -cubeDim.heigth 
                end
                Move(element, _x_axis, xRealLoc, 0)
                Move(element, _z_axis, zRealLoc, 0)
                Move(element, _y_axis, Level * cubeDim.heigth - 0.5 + offset, 0)
                WaitForMoves(element)
                WTurn(element, _z_axis, math.rad(rotation), 0)
				LevelPieces = houseAddDestructionTable(LevelPieces, #LevelPieces+1, element)
				addToShowTable(element, xLoc, zLoc)
                decoPieceUsedOrientation[element] = getRotationFromPiece(element)

                if countElements == 24 then break end
                if pieceNr_pieceName[element] then
                    showSubsAnimateSpinsByPiecename(pieceNr_pieceName[element])
                end
            end
        end
    end

    if count(dayNightPieceNames) > 0 then
        StartThread(nightAndDay, dayNightPieceNames)
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
                lecho( "decorateBackYard:roofDecoMaterials element selection failed for "..materialColourName)
                return materialColourName
            end

            if  (element and chancesAre(10) < decoChances.roof ) then
                rotation = getOutsideFacingRotationOfBlockFromPlan(i)
                countElements = countElements + 1
                decoMaterial = removeElementFromBuildMaterial(element,
                                                              decoMaterial)
                Move(element, _x_axis, xRealLoc, 0)
                Move(element, _z_axis, zRealLoc, 0)
                Move(element, _y_axis,
                     Level * cubeDim.heigth - 0.5 + cubeDim.roofHeigth, 0)
                WaitForMoves(element)
                WTurn(element, _z_axis, math.rad(rotation), 0)
                decoPieceUsedOrientation[element] = getRotationFromPiece(element)
                if pieceNr_pieceName[element] then
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

function showHouse() boolHouseHidden = false; showT(ToShowTable) end

function hideHouse() boolHouseHidden = true; hideT(ToShowTable) end

function buildAnimation()
   
    Show(Icon)
    while boolDoneShowing == false do Sleep(100) end
    Hide(Icon)
    while boolDoneShowing == false do Sleep(100) end
    showT(ToShowTable)
	    
	if randChance(25) then
       Sleep(500)
       showHoloWall()
    end
end

function buildBuilding()
    StartThread(buildAnimation)
    lecho( "buildBuilding")
    if randChance(5) then
        showOne(TablesOfPiecesGroups["StandAlone"], true)
        boolDoneShowing = true
        return
    end
 
    --lecho( "selectBase")
    materialColourName = selectGroundBuildMaterial()
    --materialColourName = "office"
    buildingGroupsFloor.Upright = getNameFilteredDictionary( {"ID_u", "ID_a"},  { materialColourName}, {"Roof", "Deco"})
	buildingGroupsLevel.Upright = getNameFilteredDictionary({"ID_u", "ID_a"},{materialColourName}, {"Floor", "Roof","Deco"})
    buildingGroupsFloor.Length = getNameFilteredDictionary( {"ID_l", "ID_a"},  { materialColourName}, {"Roof", "Deco"})
    buildingGroupsLevel.Length = getNameFilteredDictionary( {"ID_l", "ID_a"}, {materialColourName},{"Floor", "Roof", "Deco"})

    lecho( "buildDecorateGroundLvl started")
    buildDecorateGroundLvl(materialColourName)
    lecho("House_Asian: buildDecorateGroundLvl ended with ")

    lecho( "selectBase")
    selectBase(materialColourName)
    lecho( "selectBackYard")
    selectBackYard(materialColourName)    

    levelBuildMaterial = getNameFilteredTable({}, {materialColourName}, {"Floor","Roof", "Deco"})

    height = math.random(2,3)
	for i = 1, height do
        lecho( "buildDecorateLvl start "..i)
        assert(levelBuildMaterial, "no material table in" ..i.." for "..materialColourName)
        _, levelBuildMaterial = buildDecorateLvl(i, materialColourName, levelBuildMaterial)
        if not levelBuildMaterial then
            levelBuildMaterial = getNameFilteredTable({}, {materialColourName}, {"Roof", "Deco"})
        end
        lecho( "buildDecorateLvl ended")
    end

	materialTable = getNameFilteredTable({materialColourName}, {"Roof", "Deco"}, {"Floor","Base"})
    if materialTable and count(materialTable) > 0 then
        lecho( "addRoofDeocrate started")
        addRoofDeocrate(height + 1, materialTable, materialColourName)
    end

    lecho( "addRoofDeocrate ended")
    boolDoneShowing = true
    industrpiece = piece("ID_l100_Industrial_RooflBlock2")
    addToShowTable(industrpiece)
    showSubsAnimateSpinsByPiecename(pieceNr_pieceName[industrpiece])
	initAllPieces()
end

function script.Activate() return 1 end

function script.Deactivate() return 0 end

function script.QueryBuildInfo() return center end

function script.HitByWeapon(x, z, weaponDefID, damage) end


