include "createCorpse.lua"
include "lib_OS.lua"
include "lib_UnitScript.lua"
include "lib_Animation.lua"
include "lib_staticstring.lua"
include "lib_mosaic.lua"



toShowTable = {}
TablesOfPiecesGroups = {}
mapHash = getDetermenisticMapHash(Game)
unitHash = getDeterministicUnitHash(unitID)

-- Create a deterministic PRNG

    -- Constants for LCG (Numerical Recipes)
local a = 1664525
local c = 1013904223
local m = 2^32

local state = mapHash + unitHash

-- Returns a "random" float between 0 and 1
local function random()
    state = (a * state + c) % m
    return state / m
end

-- Returns a random integer between min and max (inclusive)
local function random_range(min, max)
    min = min or 0
    max = max or 1
    return math.floor(random() * (max - min + 1)) + min
end

 

function showSubs(pieceID)
   local pieceName = getUnitPieceName(unitID, pieceID)
   subSpinPieceName = pieceName.."Sub"    
   if TableOfPiecesGroups[subSpinPieceName] then  
    hideT(TableOfPiecesGroups[subSpinPieceName] )              
    for i=1, #TableOfPiecesGroups[subSpinPieceName] do
        subPiece = TableOfPiecesGroups[subSpinPieceName][i]
        Show(subPiece)
        addToShowTable(spinPiece)
    end
   end
end

function script.Create()
    --echo(UnitDefs[unitDefID].name.."has placeholder script called")
    Spring.SetUnitAlwaysVisible(unitID, true)
    --Spring.SetUnitNoSelect(unitID, true)
    Spring.SetUnitBlocking(unitID, false)
    hideAll(unitID)
    TablesOfPiecesGroups = getPieceTableByNameGroups(false, true)
    buildShowUnit()
    foolTip = "Presidential palace of ".. generateRidiculousTitle()
    Spring.SetUnitTooltip(unitID, foolTip)
    StartThread(crisisModeWatcher)
end

Wire = piece("Wire")

function crisisModeWatcher()
    BodyGuards = TablesOfPiecesGroups["BodyGuard"]
	while true do
		Sleep(1000)
		if GG.GlobalGameState ~= "normal" then
			hideT(TablesOfPiecesGroups["Limo"])
			Show(Gate)
            Show(Wire)
            
            addToShowTable(showSeveral(BodyGuards))
            showT(BodyGuards)
            if statue then WTurn(statue, x_axis, math.rad(110), 25) end
			while GG.GlobalGameState ~= "normal" do
				Sleep(3000)
                foreach(BodyGuards,
                    function(id)
                        Show(id)
                        val = math.random(2,7)*randSign()
                        Spin(id,y_axis, math.rad(val), 0)
                    end)
			end
            reset(statue, 0)
			Hide(Gate)
            Hide(Wire)
            hideT(BodyGuards)
			foreach(
				toShowTable,
				function(id)
					Show(id)
				end
			)
		end
		Sleep(5000)
	end
end
function addToShowTables(tables)
    for i=1,#tables do
        addToShowTable(tables[i])
    end
    return tables
end


function addToShowTable(pieceID)
	Show(pieceID)
	toShowTable[#toShowTable +1]= pieceID
    return pieceID
end


function generateRidiculousTitle()
    GameConfig = getGameConfig()
    country = getCountryByCulture(GameConfig.instance.culture ,mapHash)

    -- Tables of possible title components
    local honorifics = {
        "His Excellency", "Her Excellency", "The Glorious", "The Eternal", "Most Serene", "Supreme", "Omnipotent", "Grand", "Transcendent", "Illustrious", "Beloved by billions"
    }
    
    local leadershipTitles = {
        "President", "Emperor", "Empress", "Supreme Leader", "Conqueror", "Protector", "Divine Guide", "Father of the Nation", "Master of the People", "Commander of the Faithful"
    }
    
    local divineTitles = {
        "Shadow of the Almighty", "Sword of Justice", "Voice of Destiny", "Hand of Providence", "Chosen of the Heavens", "Anointed One"
    }
    
    local academicTitles = {
        "Doctor of Laws", "Professor of Revolutionary Science", "Master of Philosophy", "Doctor of Eternal Wisdom", "Grand Strategist", "Patron of the Arts and Sciences"
    }
    
    local militaryTitles = {
        "Marshal of " .. country, "Supreme Commander of the Armed Forces", "Generalissimo", "Warlord of " .. country, "High Admiral of the Great Fleet"
    }
    
    local poeticSuffixes = {
        "Light of the People", "Bringer of Glory", "Conqueror of the Ages", "Architect of the Future", "Pillar of Civilization", "Beacon of Humanity", "Guardian of Eternal Peace"
    }
    

    -- Generate the title
    local title = table.concat({
        honorifics[random_range(1,#honorifics)],
        leadershipTitles[random_range(1,#leadershipTitles)],
        divineTitles[random_range(1,#divineTitles)],
        academicTitles[random_range(1,#academicTitles)],
        militaryTitles[random_range(1,#militaryTitles)],
        poeticSuffixes[random_range(1,#poeticSuffixes)]
    }, ", ")
    
    -- Add the "name" part
    local surName, familyName = getDeterministicCultureNames(unitID, UnitDefs, GameConfig.instance.culture, true, true)
    local nameParts = {"I", "the Great", "Magnificent", "Invincible", "Unifier of " .. country, "the Wise", "Vanquisher of Enemies"}
    local name = "— " .. (country .. "s Supreme Sovereign " .. nameParts[random_range(1,#nameParts)]).." "..surName.." "..familyName.. "\n"
    
    return title .. " " .. name
end




function showOne(T, bNotDelayd)
    if not T then return end
    dice = random_range(1, count(T))
    c = 0
    for k, v in pairs(T) do
        if k and v then c = c + 1 end
        if c == dice then           
            Show(v)
            return v
        end
    end
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
  		toShowTable[#toShowTable +1] = ToShow[i]
  		Show(ToShow[i])
  	end
  	return ToShow
end

Gockelsockel = piece("BaseSub2")
Base = piece("Base")
Flag = piece("Flag")
Gate = piece("Gate")
statue= nil
function buildShowUnit()
	addToShowTable(Base)	
	addToShowTable(Flag)
	baseSubs= showSeveral(TablesOfPiecesGroups["BaseSub"])
    addToShowTables(baseSubs)
	if  isInTable(baseSubs, Gockelsockel) then
	  statue = addToShowTable(showOne(TablesOfPiecesGroups["Statue"]))
	end

	addToShowTable(showOne(TablesOfPiecesGroups["Street"]))
	addToShowTable(showOne(TablesOfPiecesGroups["Park"]))
	addToShowTable(showOne(TablesOfPiecesGroups["Post1Flag"]))
	addToShowTable(showOne(TablesOfPiecesGroups["Post2Flag"]))
	addToShowTable(showOne(TablesOfPiecesGroups["Post3Flag"]))
	addToShowTable(showOne(TablesOfPiecesGroups["Palast"]))
	addToShowTables(showSeveral(TablesOfPiecesGroups["PalastDeco"]))
	addToShowTables(showSeveral(TablesOfPiecesGroups["Limo"]))
end