include "createCorpse.lua"
include "lib_OS.lua"
include "lib_UnitScript.lua"
include "lib_Animation.lua"
include "lib_Build.lua"
include "lib_mosaic.lua"
skyscrape = piece"skyscrape"
center = piece "center"

TablesOfPiecesGroups ={}
function script.Killed()
end

function script.Create()
 TablesOfPiecesGroups = getPieceTableByNameGroups(false, true)
 randHide(TablesOfPiecesGroups["scrapHeap"])
 if math.random(0,1)==1 then Hide(skyscrape) end
    StartThread(waitForAnEnd)
end

function waitForAnEnd()
	WMove(center,z_axis, -67, 0.1)
    Spring.DestroyUnit(unitID, true, false)
end