include "createCorpse.lua"
include "lib_OS.lua"
include "lib_mosaic.lua"
include "lib_UnitScript.lua"


TablesOfPiecesGroups = {}
myDefID = Spring.GetUnitDefID(unitID)
function script.HitByWeapon(x, z, weaponDefID, damage) end
 

function setArcologyProjectsName(id, isArcology)
name= {"Mega Haven"," Skybound Complex","Giga Gardens"," Horizon Sprawl",
"Echelon Tower","Macropolis","Stratos Heights", "Panorama City","Prime Hive",
"Vastara","Infinite Plaza","Titanium Reach"," Grand Nexus","Skyline Citadel",
" Ultra Blocks","Terra Enclave","Nimbus Crown","Omega District","Echo City","Solaris Compound",
"Evergrove Heights","Sunfield Towers","Greenhollow Expanse","Willow Horizon","Eden Nest",
" Cedar Reach"," Maple Spire","Timber Path Haven","Lakeview Pinnacle","Rosemary Stretch",
," Oasis Rise"," Briar Canopy"," Silverleaf Plateau","Fernspire Peaks","Juniper Valley",
"Forest Haven","Mistvale Ridge","Heatherview Crest"," Riverbend Sprawl","Sunbluff Terrace",
"Kowloon 2", "Oz.ean. Views", "Arcos Sancti", "Arcology", "Withering Heights", "Riverside Rebuild"}
if not isArcology then
    description =  {
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
    "Sector 7 lockdown after rogue anti-socials",
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
    "Bio-lab quarantine ‘a wellness initiative’" }
      Spring.SetUnitTooltip(id, name..":"..description)
  else
    description  = {
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
    Spring.SetUnitTooltip(id, name..":"..description)

  end
end

isArcology = false
function script.Create()
   

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


function addGroundPlaceables(materialName)
    x,y,z = Spring.GetUnitPosition(unitID)
    globalHeightUnit = Spring.GetGroundHeight(x, z)
    placeAbles =  getNameFilteredTable( {},  { "Placeable"}, {})
    if placeAbles and count(placeAbles) > 0 then
        groundPiecesToPlace= math.random(1,5)
        randPlaceAbleID = ""
            while groundPiecesToPlace > 0 do

                randPlaceAbleID = getSafeRandom(placeAbles)         
                if randPlaceAbleID and not inToShowDict(randPlaceAbleID) then
                    opx= math.random(cubeDim.length*4, cubeDim.length*7)*randSign()
                    opz= math.random(cubeDim.length*4, cubeDim.length*7)*randSign()
                    WMove(randPlaceAbleID,3, opz, 0)
                    WMove(randPlaceAbleID,1, opx, 0)
                    Sleep(1)
                    x, y, z, _, _, _ = Spring.GetUnitPiecePosDir(unitID, randPlaceAbleID)
                    myHeight = Spring.GetGroundHeight(x, z)
                    heightdifference = math.abs(globalHeightUnit - myHeight)
                    if myHeight < globalHeightUnit then heightdifference = -heightdifference end


                    addToShowTable(randPlaceAbleID)
                    Show(randPlaceAbleID)    
                end 
            
                groundPiecesToPlace = groundPiecesToPlace -1
            end 
    end
end


function buildBuilding()
    Sleep(500)
    px,py,pz = Spring.GetUnitPosition(unitID)
    isArcology =    isNearCityCenter(px, pz, GameConfig) and randChance(50) or  randChance(10)
    isDualProjectOrMix=  randChance(10)
    if isArcology then
        myShownMainPiece = showOne(TablesOfPiecesGroups["Arcology"], true)
        addToShowTable(myShownMainPiece)
        
    else
        myShownMainPiece = showOne(TablesOfPiecesGroups["Project"], true)
        addToShowTable(myShownMainPiece)
    end
        if isDualProjectOrMix then
            myShownMainPiece = showOne(TablesOfPiecesGroups["Project"], true)
            addToShowTable(myShownMainPiece)
        end

    if  myShownMainPiece == TablesOfPiecesGroups["Project"][1] or 
        myShownMainPiece == TablesOfPiecesGroups["Project"][2]  then
        blockNumber = showOneDeterministic(TablesOfPiecesGroups["StandAloneLights"], unitID)
        addToShowTable(blockNumber)
    end
    setArcologyProjectsName(unitID,  isArcology)
    addGroundPlaceables()
    boolDoneShowing = true
    showHouse()
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


