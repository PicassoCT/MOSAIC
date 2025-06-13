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
    Spring.SetUnitNoSelect(unitID, true)
    Spring.SetUnitBlocking(unitID, false)
    hideAll(unitID)
    TablesOfPiecesGroups = getPieceTableByNameGroups(false, true)
    buildShowUnit()
    StartThread(crisisModeWatcher)
end

function crisisModeWatcher()

	while true do
		Sleep(1000)
		if GG.GlobalGameState ~= "normal" then
			hideT(TablesOfPiecesGroups["Limo"])
			Show(Gate)

			while GG.GlobalGameState ~= "normal" do
				Sleep(3000)
			end
			Hide(Gate)
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

function showOne(T, bNotDelayd)
    if not T then return end
    dice = math.random(1, count(T))
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
  			if math.random(0,1) == 1 then
			   ToShow[#ToShow +1] = val
  			end
  		end

  	for i=1, #ToShow do
  		toShowTable[#toShowTable +1] = ToShow[i]
  		Show(ToShow[i])
  	end
  	return 
end

Gockelsockel = piece("BaseSub2")
Base = piece("Base")
Flag = piece("Flag")
Gate = piece("Gate")
function buildShowUnit()
	addToShowTable(Base)	
	addToShowTable(Flag)
	showSeveral("BaseSub")
	if maRa() then
		if  isInTable(TablesOfPiecesGroups["BaseSub"], Gockelsockel) then
			addToShowTable(showOne(TablesOfPiecesGroups["statue"]))
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