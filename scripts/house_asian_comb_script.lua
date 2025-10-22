include "createCorpse.lua"
include "lib_OS.lua"
include "lib_UnitScript.lua"
include "lib_Animation.lua"
include "lib_physics.lua"
include "lib_mosaic.lua"

TablesOfPieceGroups = {}
GameConfig = getGameConfig()
local pieceNr_pieceName =Spring.GetUnitPieceList ( unitID ) 
local pieceName_pieceNr = Spring.GetUnitPieceMap (unitID)

local factor = 35
local heightoffset = 90   
local cubeDim = {
    length = factor * 22,
    heigth = factor * 14.44 + heightoffset,
    roofHeigth = 50
}
function script.HitByWeapon(x, z, weaponDefID, damage) end
x,y,z = nil, nil, nil
boolDoneShowing = false
RoofTopPieces = {}
base = nil
ToShowTable = {}
Icon =piece("Icon")

-- Returns a random integer between min and max (inclusive)
local function random_range(min, max)
    min = min or 0
    max = max or 1
    return math.floor(math.random() * (max - min + 1)) + min
end

function addToShowTables(tables)
    for i=1,#tables do
        addToShowTable(tables[i])
    end
    return tables
end

function addToShowTable(pieceID)
    ToShowTable[#ToShowTable +1]= pieceID
    return pieceID
end

function showSeveral(T)
    if not T then return end
    ToShow= {}
    for num, val in pairs(T) do 
        if random_range() == 1 then
           ToShow[#ToShow +1] = val
        end
    end

    for i=1, #ToShow do
        ToShowTable[#ToShowTable +1] = ToShow[i]
        Show(ToShow[i])
    end
    return ToShow
end
if not GG.CombsIndex then GG.CombIndex = 1 end
function showOne(T, bNotDelayd)
    if not T then return end
    dice = (GG.CombIndex  % count(T)) +1
    GG.CombIndex = dice
    c = 0
    for k, v in pairs(T) do
        if k and v then c = c + 1 end
        if c == dice then
            ToShowTable[#ToShowTable + 1] = v
            if bNotDelayd and bNotDelayd == true then
                Show(v)
            end
            return v
        end
    end
end

function showOneOrNone(T)
    if maRa() then return end
    showOne(T)
end

function showNoneOrMany(T)
    if maRa() then  return showOneOrNone(T) end
    for k, v in pairs(T) do        
        if maRa() then
            addToShowTable(v, "showOne", k)            
        end
    end
end


function showSubs(pieceGroupName)
    local subName = pieceGroupName .. "Sub"
  --  Spring.Echo("SubGroupName "..subName)
    if TablesOfPieceGroups[subName] then
        showNoneOrMany(TablesOfPieceGroups[subName])
    end
end

function buildHouse()
    resetAll(unitID)
    hideAll(unitID)
    Sleep(1)
    buildBuilding()
end

function buildAnimation()
    Show(Icon)
    while not boolDoneShowing do
        Sleep(1000)
    end
    Hide(Icon)
    waterPlateName = "PlateWater"
    StartThread(waterFalls, TablesOfPieceGroups[waterPlateName])
    waterBaseName = chasingWaterfalls[base]
    if chasingWaterfalls[base] and TablesOfPieceGroups[waterBaseName] then
        StartThread(waterFalls, TablesOfPieceGroups[waterBaseName])
    end
    showHouse()
end

boolHasWaterFalls = false
function waterFalls(waterfallT)
    while waterfallT do
        foreach(waterfallT,
            function (water)
                Show(water)
                val = math.random(0,1)*180
                Turn(water, x_axis, math.rad(randSign()*val),0)
                val = math.random(0,1)*180
                Turn(water, z_axis, math.rad(randSign()*val),0)
            end
            )
    Sleep(35)
    end
end

base1 = piece("base1")
base2 = piece("base2")
base3 = piece("base3")
Plate = piece("Plate")
chasingWaterfalls  = {
    [base1] = "base1Water",
    [base2] = "base2Water",
    [base3] = "base3Water",
    [Plate] = "PlateWater"
}

function buildBuilding()
    StartThread(buildAnimation)
    Sleep(1000)
    addToShowTable(Plate)
    base = addToShowTable(showOne(TablesOfPieceGroups["base"], true))
    showTSubSpins(base, TablesOfPieceGroups)
    if base == base1 then  
        showSeveral(TablesOfPieceGroups["ShowCombe"])   
        RoofTopPieces = TablesOfPieceGroups["RoofTopCircle"]
    end

    if base == base2 then RoofTopPieces = TablesOfPieceGroups["RoofTopSquare"] end
    if base == base3 then RoofTopPieces = TablesOfPieceGroups["RoofTopUpright"] end
    boolDoneShowing = true
end

function script.Create()
    TablesOfPieceGroups = getPieceTableByNameGroups(false, true)
    x, y, z = Spring.GetUnitPosition(unitID)
    StartThread(removeFeaturesInCircle,x,z, GameConfig.houseSizeZ/2) 
    math.randomseed(x + y + z)
    StartThread(buildHouse)
    StartThread(addGroundPlaceables)
end

PlaceableSimPos = piece("PlaceableSimPos")
garbageSimPlaceable =  {
    [piece("Placeable14")] = true,
    [piece("Placeable15")] = true,
    [piece("Placeable16")] = true,
    [piece("Placeable21")] = true
}

local orgPieceParams = {
        pieces = {
          {name="SimCan1", typ = "can", rotator= "SimCanRot1", mass=1.0, drag=0.9},
          {name="SimCan2", typ = "can", rotator= "SimCanRot2", mass=1.0, drag=0.9},
          {name="SimBox1", typ = "box", mass=2.5, drag=0.85},
          {name="SimPaper1", typ = "paper", mass=0.2, drag=0.95, lift=0.1}
        },
      params = 
      {
        GRAVITY = -0.15,
        FLOOR_Y = 0,
        BOUND = {minX=-1000, maxX=1000, minY=0, maxY=250, minZ=-1000, maxZ=1000}
      },
      PlaceableSimPos= piece("PlaceableSimPos")
    }

function addGroundPlaceables()
    Sleep(500)
    x,y,z = Spring.GetUnitPosition(unitID)
    globalHeightUnit = Spring.GetGroundHeight(x, z)
    placeAbles =  TablesOfPieceGroups["Placeable"]
    if not GG.SimPlaceableCounter then GG.SimPlaceableCounter = 0 end
    if placeAbles and count(placeAbles) > 0 then
        groundPiecesToPlace= math.random(1,5)
        randPlaceAbleID = ""
        while groundPiecesToPlace > 0 do
            randPlaceAbleID = getSafeRandom(placeAbles)     

            if randPlaceAbleID  then
                opx= math.random(cubeDim.length * 4, cubeDim.length * 7) * randSign()
                opz= math.random(cubeDim.length * 4, cubeDim.length * 7) * randSign()

                if garbageSimPlaceable[randPlaceAbleID] and GG.SimPlaceableCounter < 1 then
                    GG.SimPlaceableCounter = GG.SimPlaceableCounter +1
                    StartThread(runGarbageSim, orgPieceParams, opx, opz)
                end
                WMove(randPlaceAbleID,x_axis, opz, 0)
                WMove(randPlaceAbleID,z_axis, opx, 0)
                Sleep(1)
                x, y, z, _, _, _ = Spring.GetUnitPiecePosDir(unitID, randPlaceAbleID)
                myHeight = Spring.GetGroundHeight(x, z)
                if myHeight > 0 then
                    heightdifference =  myHeight -globalHeightUnit
                    WMove(randPlaceAbleID,y_axis, heightdifference, 0)
                    showSubs(pieceNr_pieceName[randPlaceAbleID])   
                    addToShowTable(randPlaceAbleID)
                    Show(randPlaceAbleID)    
                end
            end
            groundPiecesToPlace = groundPiecesToPlace - 1
        end 
    end
end

function script.Killed(recentDamage, _)
    return 1
end

function script.StartMoving() end

function script.StopMoving() end

function script.Activate() return 1 end

function script.Deactivate() return 0 end

function showHouse() boolHouseHidden = false; showT(ToShowTable) end

function hideHouse() boolHouseHidden = true; hideT(ToShowTable) end

boolDoneShowing = false
boolHouseHidden = false

function traceRayRooftop( vector_position, vector_direction)
    return GetRayIntersectPiecesPosition(unitID, RoofTop, vector_position, vector_direction)
end
 