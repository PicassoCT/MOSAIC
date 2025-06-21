include "createCorpse.lua"
include "lib_OS.lua"
include "lib_UnitScript.lua"
include "lib_Animation.lua"
include "lib_mosaic.lua"



toShowTable = {}
TablesOfPiecesGroups = {}

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

			while GG.GlobalGameState ~= "normal" do
				Sleep(3000)
                foreach(BodyGuards,
                function(id)
                    Show(id)
                    val = math.random(2,7)*randSign()
                    Spin(id,y_axis, math.rad(val), 0)
                end)
			end
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

function addToShowTable(pieceID)
	Show(pieceID)
	toShowTable[#toShowTable +1]= pieceID
end

-- Create a deterministic PRNG
local function create_rng(seed)
    -- Constants for LCG (Numerical Recipes)
    local a = 1664525
    local c = 1013904223
    local m = 2^32

    local state = seed or 1

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

    return {
        random = random,
        random_range = random_range,
    }
end

detRandom = create_rng(getBuildingTypeHash(unitID, 42))


function showOne(T, bNotDelayd)
    if not T then return end
    dice = detRandom.random_range(1, count(T))
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
  			if detRandom.random_range(0,1) == 1 then
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
function buildShowUnit()
	addToShowTable(Base)	
	addToShowTable(Flag)
	baseSubs= showSeveral(TablesOfPiecesGroups["BaseSub"])
	if detRandom.random() == 1 then
		if  isInTable(baseSubs, Gockelsockel) then
			addToShowTable(showOne(TablesOfPiecesGroups["Statue"]))
		end
	end
	addToShowTable(showOne(TablesOfPiecesGroups["Street"]))
	addToShowTable(showOne(TablesOfPiecesGroups["Park"]))
	addToShowTable(showOne(TablesOfPiecesGroups["Post1Flag"]))
	addToShowTable(showOne(TablesOfPiecesGroups["Post2Flag"]))
	addToShowTable(showOne(TablesOfPiecesGroups["Post3Flag"]))
	addToShowTable(showOne(TablesOfPiecesGroups["Palast"]))
	showSeveral(TablesOfPiecesGroups["PalastDeco"])
	showSeveral(TablesOfPiecesGroups["Limo"])
end