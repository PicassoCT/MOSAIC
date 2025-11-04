include "createCorpse.lua"
include "lib_OS.lua"
include "lib_mosaic.lua"
include "lib_physics.lua"
include "lib_UnitScript.lua"

local TablesOfPieceGroups = {}
local boolDebug = false

local GameConfig = getGameConfig()
local factor = 35
local heightoffset = 90   
local rotationOffset = 90
local gaiaTeamID = Spring.GetGaiaTeamID()
local pieceNr_pieceName =Spring.GetUnitPieceList(unitID) 
local pieceName_pieceNr = Spring.GetUnitPieceMap(unitID)
local pieceToShow = nil
local toShowDict = {}
local ToShowTable = {}
local ArcoT= {}
local ProjectT = {}
local Mega = {}
local isArcology = false
local isProject = UnitDefs[unitDefID].name =="Project"
local Icon = piece("Icon")
local cubeDim = {
    length = factor * 22,
    heigth = factor * 14.44 + heightoffset,
    roofHeigth = 50
}

local RoofTopPieces ={}
function registerRooftopSubPieces(pieceToShow)
    name = pieceNr_pieceName[pieceToShow].."Roof"
    if TablesOfPieceGroups[name] then
        for nr,id in pairs(TablesOfPieceGroups[name]) do
            RoofTopPieces[#RoofTopPieces +1] = id
        end
    end
end

function setArcologyProjectsName(id, isArcology)
    px, py, pz = Spring.GetUnitPosition(id)

    local names = {
        "Mega Haven",
        "Skybound Complex",
        "Giga Gardens",
        " Horizon Sprawl",
        "Echelon Tower",
        "Macropolis",
        "Stratos Heights",
        "Panorama City",
        "Prime Hive",
        "Vastara",
        "Infinite Plaza",
        "Titanium Reach",
        "Grand Nexus",
        "Skyline Citadel",
        "Ultra Blocks",
        "Terra Enclave",
        "Nimbus Crown",
        "Omega District",
        "Echo City",
        "Solaris Compound",
        "Evergrove Heights",
        "Sunfield Towers",
        "Greenhollow Expanse",
        "Willow Horizon",
        "Eden Nest",
        "Cedar Reach",
        "Maple Spire",
        "Timber Path Haven",
        "Lakeview Pinnacle",
        "Rosemary Stretch",
        "Oasis Rise",
        "Briar Canopy",
        "Silverleaf Plateau",
        "Fernspire Peaks",
        "Juniper Valley",
        "Forest Haven",
        "Mistvale Ridge",
        "Heatherview Crest",
        " Riverbend Sprawl",
        "Sunbluff Terrace",
        "Kowloon 2",
        "Oz.ean. Views",
        "Arcos Sancti",
        "Arcology",
        "Withering Heights",
        "Riverside Rebuild",
        "Todos Santos"
    }
    local descriptions = {}
    boolDoneShowing = false
    boolHouseHidden = false
    Icon = piece("Icon")

    if not isArcology then
        descriptions = {
            "Breathe fresh air, indoors only",
            "Vibrant green spaces, at a distance",
            "Sunshine guaranteed, through tinted glass",
            "Nature-inspired, steel-strong and secure",
            "Experience community, in private cubicles",
            "Escape the world, forever",
            "Live freely, in designated zones",
            "Skylights for all, high above",
            "Boundless views, art in concrete",
            "Luxury living, tightly monitored",
            "Eco-friendly concrete and recycled air",
            "Embrace nature, digitally rendered",
            "Your sanctuary, under constant care",
            "Reimagined countryside, vertical and walled",
            "Feel alive, but stay indoors",
            "Green spaces, seen from windows",
            "Open-air feel, indoors and safe",
            "Privacy assured, limited daylight",
            "Thriving community, curated interactions only",
            "Rediscover nature, in holographic parks",
            "Sector "..math.random(1,10).." lockdown after rogue anti-socials",
            "Neon District curfew extended again",
            "Unlicensed clones found in Sublevel 5",
            "Black Market implants spike in sales",
            "Cyber-hack wave hits Lower Spire",
            "Gang tensions rise in Neon Alley",
            "Firefight erupts over rooftop territories",
            "Unauthorized drones swarm Market Plaza",
            "Police outnumbered in Suburb 13",
            "Data-thefts surge across Core Blocks",
            "Synthetic trade sweeps through Red Zone",
            "Augment gangs clash over power cells",
            "Spire 22 hacked by vigilante groups",
            "Rogue android sightings in Old Metro",
            "Curfew violators flood Checkpoint A",
            "Memory heist reported in Hub Sector",
            "Energy riots spread in West Hive",
            "Biotech labs breached in Sector 9",
            "Illegal VR dens raid gone wrong",
            "Corp enforcers attacked by data thieves",
            "All reports of smog are exaggerated",
            "Unauthorized lights in Sector 12 ‘harmless’",
            "Noise detected in Sublevel? Just machinery!",
            "Power outages ‘routine maintenance only’",
            "Drone sightings completely under control",
            "Safety barriers purely precautionary measures",
            "Reports of android malfunctions unfounded",
            "Spire evacuations part of safety drills",
            "Rising noise is ‘neighborhood vibrancy’",
            "Extended curfew purely ‘for residents’ comfort’",
            "Security patrols increased for community joy",
            "Lower levels’ blackout ‘a festive surprise’",
            "Market lockdown ‘merely crowd control’",
            "Unauthorized shadows ‘just lighting effects’",
            "Drone squads ‘just optimizing airspace’",
            "Heat spikes in alleys ‘routine’",
            "Enhanced surveillance ‘for residents’ safety’",
            "Hologram glitches ‘due to upgrades’",
            "Increased curfews ‘to enhance nightlife’",
            "Bio-lab quarantine ‘a wellness initiativ"
        }
    else
        descriptions = {
            "Live safely, away from the chaos",
            "True peace, beyond the city’s noise",
            "Experience harmony, shielded from disorder",
            "Your sanctuary, far from the unrest",
            "Security guaranteed, beyond urban turmoil",
            "Breathe easy, in our sealed paradise",
            "Escape the streets, live in safety",
            "Perfect harmony, free from outside threats",
            "Your safe haven, isolated and secure",
            "Enjoy life, untouched by outer dangers",
            "Where the air is safe to breathe",
            "Safety you can trust, always enclosed",
            "Your oasis, far from the city’s reach",
            "Stay protected, where chaos can’t touch",
            "The world outside fades away here",
            "Built to last, shielded from everything",
            "Luxury living, safe and sound inside",
            "The refuge you deserve from the outside",
            "An untouched world, within strong walls",
            "Find true serenity, sealed from chaos",
            "Where calm prevails, and walls protect",
            "Enjoy the calm, beyond the outer risks",
            "Feel safe, far from the unpredictable",
            "A guarded paradise amidst a stormy world",
            "Insulated luxury, against outer mayhem",
            "Protected living, away from the unknown",
            "Here, security is our highest standard",
            "Discover safety, without a worry",
            "Built to withstand, sheltering you always",
            "Your escape, fortified and serene",
            "Life uninterrupted, beyond external threats",
            "Embrace safety, with every passing day",
            "A world within a world, just for you",
            "Feel secure, where others can’t reach",
            "Peace and quiet, sealed and protected",
            "Reclaim tranquility, away from the city",
            "Enclosed comfort, outside world-free",
            "Safety-first living, beyond outer borders",
            "Stay worry-free, inside our safe zone",
            "Protected, comfortable, and free of worry"
        }
       
    end
        name = names[(math.floor(px + py)% #names) +1] 
        description = descriptions[(math.floor(px + py + pz)% #descriptions) + 1] 
        Spring.SetUnitTooltip(id,  name .. ": " .. description )
end



function addToShowTable(element)
    ToShowTable[#ToShowTable + 1] = element
    toShowDict[element] = true
end


function initilization()
    ArcoT =  TablesOfPieceGroups["Arcology"]
    ProjectT =  TablesOfPieceGroups["Project"]
end

function filterOutMegaBuilding()
    ArcoT =  foreach(TablesOfPieceGroups["Arcology"], 
                    function (id)
                        if not Mega[id] then return id end
                    end)            

    ProjectT =  foreach(TablesOfPieceGroups["Project"], 
                    function (id)
                        if not Mega[id] then return id end
                    end)

    ProjectT[#ProjectT +1] = TablesOfPieceGroups["Project"][3]
    ProjectT[#ProjectT +1] = TablesOfPieceGroups["Project"][4]
    ProjectT[#ProjectT +1] = TablesOfPieceGroups["Project"][5]
end

if not GG.MegaBuildingCount then GG.MegaBuildingCount = 0 end


megaHeightDefinition = 2700
function fillMegaTable()
    foreach(TablesOfPieceGroups["Arcology"],
        function(id)
            pieceInfo = Spring.GetUnitPieceInfo ( unitID, id) 
            dim = {
                x= pieceInfo.max[1] - pieceInfo.min[1],
                y= pieceInfo.max[2] - pieceInfo.min[2],
                z= pieceInfo.max[3] - pieceInfo.min[3],

            }

            if dim.z > megaHeightDefinition then
                Mega[id] = true
            end
        end
        )

    foreach(TablesOfPieceGroups["Project"],
        function(id)
            pieceInfo = Spring.GetUnitPieceInfo ( unitID, id) 
            dim = {
                x= pieceInfo.max[1] - pieceInfo.min[1],
                y= pieceInfo.max[2] - pieceInfo.min[2],
                z= pieceInfo.max[3] - pieceInfo.min[3],
            }
            if dim.z > megaHeightDefinition then
                Mega[id] = true
            end
        end
        )
end

local pieceName_pieceNr = Spring.GetUnitPieceMap (unitID)
function script.Create()
    TablesOfPieceGroups = getPieceTableByNameGroups(false, true)

    fillMegaTable()
    ArcoT = TablesOfPieceGroups["Arcology"]
    ProjectT = TablesOfPieceGroups["Project"]
  
    StartThread(buildBuilding)
    StartThread(addGroundPlaceables)
end

function showOneDeterministic(T, index)
    if not T then
        echo("House arcology failed with no table")
        return
    end
    dice = (index % count(T)) + 1
    c = 0
    assert(T)
    for k, v in ipairs(T) do
        if k and v then
            c = c + 1
        end
        if c == dice then
            addToShowTable(v, "showOne", k)
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

function showOne(T)
    if not T then
        return
    end
    dice = math.random(1, count(T))
    c = 0
    assert(T)
    for k, v in pairs(T) do
        if k and v then
            c = c + 1
        end
        if c == dice then
            addToShowTable(v, "showOne", k)
            return v
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
PlaceableSimPos = piece("PlaceableSimPos")
local garbageSimPlaceable =  {
    [piece("Placeable046")] = true,
    [piece("Placeable045")] = true,
    [piece("Placeable44")] = true,
    [piece("Placeable043")] = true,
    [piece("Placeable42")] = true
}

local orgPieceParams = 
{
  pieces = {
          {name="SimCan1", typ = "can", spinner = "SimCanSpinner1", rotator= "SimCanRot1", mass=1.0, drag=0.9},
          {name="SimCan2", typ = "can", spinner = "SimCanSpinner2", rotator= "SimCanRot2", mass=1.0, drag=0.9},
          {name="SimBox1", typ = "box", mass=2.5, drag=0.85},
          {name="SimPaper1", typ = "paper", mass=0.2, drag=0.95, lift=0.1}
        },
      params = 
      {
        GRAVITY = -0.15,
        FLOOR_Y = 0,
        BOUND = {minX=-500, maxX=500, minY=0, maxY=250, minZ=-500, maxZ=500}
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
 stat                    StartThread(runGarbageSim, orgPieceParams, opx, opz)
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

if not GG.GlobalPieceCounterArcology then GG.GlobalPieceCounterArcology = {} end

function findLowestPieceInTableFromWithSuggestion(suggestedIndex, Table)
    suggestedPiece =  getNthDictElement(Table, suggestedIndex)
    assert(suggestedPiece, toString(suggestedIndex).." "..toString(Table))
    for k,v in pairs(Table) do
        if not  GG.GlobalPieceCounterArcology[v] then
           GG.GlobalPieceCounterArcology[v] = 0
        end
    end

    lowestFoundKey, lowestFoundValue = suggestedPiece, math.huge
    for k,v in pairs(GG.GlobalPieceCounterArcology ) do
        if k and v and GG.GlobalPieceCounterArcology[k] and v < lowestFoundValue then --TODO fix me
            lowestFoundKey, lowestFoundValue = k, v
        end
    end

    if not GG.GlobalPieceCounterArcology[lowestFoundKey] then GG.GlobalPieceCounterArcology[lowestFoundKey] = 0 end
    GG.GlobalPieceCounterArcology[lowestFoundKey] = GG.GlobalPieceCounterArcology[lowestFoundKey] + 1

    return lowestFoundKey
end

local pieceList = Spring.GetUnitPieceList(unitID)
function pieceToShowLightBlink(pieceToShow)
    pieceName = pieceList[pieceToShow]
    if pieceName then
        lightName = pieceName.."Light"
        if TablesOfPieceGroups[lightName] then
            StartThread(lightPost, lightName, math.random(2,5)*500)
        end
    end
end

function lightPost(name, blinkTime)

    while true do
        Show(TablesOfPieceGroups[name][1])
        Hide(TablesOfPieceGroups[name][2])
        Sleep(blinkTime)
        Show(TablesOfPieceGroups[name][2])
        Hide(TablesOfPieceGroups[name][1])
        Sleep(blinkTime)
    end
end

boolBuildingShadowIsGameRelevant = false
function buildBuilding()
    hideAll(unitID)
    Show(Icon)
    StartThread(buildAnimation)
    initilization()
    Sleep(3000)
    px, py, pz = Spring.GetUnitPosition(unitID)
    boolBuildingShadowIsGameRelevant = ViewShadowGameRelevant(px, pz, boolDebug) 
    --echo("Building "..unitID.." ViewShadowGameRelevant ".. toString(ViewShadowGameRelevant(px,pz)))
    if  boolBuildingShadowIsGameRelevant or GG.MegaBuildingCount > GameConfig.MegaBuildingMax  then
        filterOutMegaBuilding()
    end
    assert(count(ArcoT) > 1)
    assert(count(ProjectT) > 1)

    isArcology = (isNearCityCenter(px, pz, GameConfig) or isMapControlledBuildingPlacement()) and getDermenisticChance(unitID, 20) 
    isArcology = isArcology and not isProject
                    
    unitHash = getDeterministicStationaryUnitHash(unitID)
    uniqueSleepMs = unitHash % 1000
    restSleep = 6000 - uniqueSleepMs
    Sleep(uniqueSleepMs)
    mapHash = getDetermenisticMapHash(Game)
    
    hash = math.ceil(unitHash) + math.ceil(mapHash)
    --echo("Standalone hash"..toString(unitHash).. "/ "..toString(mapHash).."/"..toString(hash))
    isDualProjectOrMix = randChance(10)
    if isArcology  then
        pieceToShow = findLowestPieceInTableFromWithSuggestion( (hash % count(ArcoT)) + 1, ArcoT)
        if Mega[pieceToShow] then     GG.MegaBuildingCount = GG.MegaBuildingCount  +1 end
        addToShowTable(pieceToShow)
        showTSubSpins(pieceToShow, TablesOfPieceGroups, maRa, 1)
        registerRooftopSubPieces(pieceToShow)
        pieceToShowLightBlink(pieceToShow)
    else --Project
        pieceToShow = findLowestPieceInTableFromWithSuggestion((hash % count(ProjectT)) + 1, ProjectT)
        if Mega[pieceToShow] then     GG.MegaBuildingCount = GG.MegaBuildingCount  +1 end
        addToShowTable(pieceToShow)
        showTSubSpins(pieceToShow, TablesOfPieceGroups, maRa, 2)
        registerRooftopSubPieces(pieceToShow)
        pieceToShowLightBlink(pieceToShow)
    end
    if isDualProjectOrMix then
        pieceToShow = findLowestPieceInTableFromWithSuggestion((hash  % count(ProjectT)) + 1 , ProjectT)
        
        if not Mega[pieceToShow] then
            showTSubSpins(pieceToShow, TablesOfPieceGroups, maRa, 1)
            registerRooftopSubPieces(pieceToShow)
            addToShowTable(pieceToShow)
            pieceToShowLightBlink(pieceToShow)
        end     
    end

    if pieceToShow == TablesOfPieceGroups["Project"][1] or pieceToShow == TablesOfPieceGroups["Project"][2] then
        blockNumber = showOne(TablesOfPieceGroups["StandAloneLights"], unitID)
        if blockNumber then
            addToShowTable(blockNumber)
        end
    end
    setArcologyProjectsName(unitID, isArcology)
    if toShowDict[TablesOfPieceGroups["Arcology"][8]] then
            StartThread(placeElevators, TablesOfPieceGroups, 200, 20, toShowDict)
    end
    Sleep(restSleep)
    boolDoneShowing = true
    showHouse()
    Hide(Icon)
    return
end





boolHouseHidden = false
function showHouse()
    boolHouseHidden = false
    showT(ToShowTable)
end

function hideHouse()
    boolHouseHidden = true
    hideT(ToShowTable)
end

function buildAnimation()
    while boolDoneShowing == false do Sleep(100) end
    showT(ToShowTable)   
end

function script.Killed(recentDamage, _)
    return 1
end

function script.StartMoving()
end

function script.StopMoving()
end

function script.Activate()
    return 1
end

function script.Deactivate()
    return 0
end

function traceRayRooftop(  vector_position, vector_direction)
    return  GetRayIntersectPiecesPosition(unitID, RoofTopPieces, vector_position, vector_direction)
end
