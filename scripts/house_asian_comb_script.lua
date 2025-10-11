include "createCorpse.lua"
include "lib_OS.lua"
include "lib_UnitScript.lua"
include "lib_Animation.lua"
include "lib_mosaic.lua"

TablesOfPiecesGroups = {}
GameConfig = getGameConfig()
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
    dice = (GG.CombIndex  % 3) +1
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
    StartThread(waterFalls, TablesOfPiecesGroups[waterPlateName])
    waterBaseName = chasingWaterfalls[base]
    if chasingWaterfalls[base] and TablesOfPiecesGroups[waterBaseName] then
        StartThread(waterFalls, TablesOfPiecesGroups[waterBaseName])
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
    base = addToShowTable(showOne(TablesOfPiecesGroups["base"], true))
    showTSubSpins(base, TablesOfPiecesGroups)
    if base == base1 then  
        showSeveral(TablesOfPiecesGroups["ShowCombe"])   
        RoofTopPieces = TablesOfPiecesGroups["RoofTopCircle"]
    end

    if base == base2 then RoofTopPieces = TablesOfPiecesGroups["RoofTopSquare"] end
    if base == base3 then RoofTopPieces = TablesOfPiecesGroups["RoofTopUpright"] end
    boolDoneShowing = true
end

function script.Create()
    TablesOfPiecesGroups = getPieceTableByNameGroups(false, true)
    x, y, z = Spring.GetUnitPosition(unitID)
    StartThread(removeFeaturesInCircle,x,z, GameConfig.houseSizeZ/2) 
    math.randomseed(x + y + z)
    StartThread(buildHouse)
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
 