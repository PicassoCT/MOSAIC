include "createCorpse.lua"
include "lib_OS.lua"
include "lib_mosaic.lua"
include "lib_staticstring.lua"
include "lib_UnitScript.lua"
include "lib_Animation.lua"
--include "lib_Build.lua"

TablesOfPiecesGroups = {}
myDefID = Spring.GetUnitDefID(unitID)
function script.HitByWeapon(x, z, weaponDefID, damage) end
 

isArcology = false
function script.Create()
    px,py,pz = Spring.GetUnitPosition(unitID)
    isArcology =    isNearCityCenter(px, pz, GameConfig) and randChance(50) or  randChance(10)

    TablesOfPiecesGroups = getPieceTableByNameGroups(false, true)
    hideAll(unitID)
    buildBuilding()
end

function showOneDeterministic(T, index)
    if not T then return end
    dice = (index % #T) + 1
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

myShownMainPiece = nil
toShowDict = {}
ToShowTable = {}

function addToShowTable(element)
    ToShowTable[#ToShowTable + 1] = element 
    toShowDict[element] = true
end 

function buildBuilding()
    if isArcology then
        myShownMainPiece = showOne(TablesOfPiecesGroups["Arcology"], true)
    else
        myShownMainPiece = showOne(TablesOfPiecesGroups["Project"], true)
    end
    addToShowTable(myShownMainPiece)

    if  myShownMainPiece == TablesOfPiecesGroups["Project"][1] or 
        myShownMainPiece == TablesOfPiecesGroups["Project"][2]  then
        blockNumber = showOneDeterministic(TablesOfPiecesGroups["StandAloneLights"], unitID)
        addToShowTable(blockNumber)
    end
    setArcologyName(unitID, Arcology[myShownMainPiece], isArcology)
    boolDoneShowing = true
    return
end
boolHouseHidden = false

function showHouse() boolHouseHidden = false; showT(ToShowTable) end

function hideHouse() boolHouseHidden = true; hideT(ToShowTable) end

function script.Killed(recentDamage, _)
    return 1
end

function script.StartMoving() end

function script.StopMoving() end

function script.Activate() return 1 end

function script.Deactivate() return 0 end



