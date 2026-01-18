include "createCorpse.lua"
include "lib_OS.lua"
include "lib_UnitScript.lua"
include "lib_mosaic.lua"


TablesOfPiecesGroups = {}
function script.HitByWeapon(x, z, weaponDefID, damage) end

function script.Create()
    TablesOfPiecesGroups = getPieceTableByNameGroups(false, true)
    StartThread(buildAnimation)
end

function printABoat()

end

function OpenDoors()

end

function CloseDoors()
  resetT(TableOf

function LeaveAnimation()
  Show(Boat)
  OpenDoors()
  WMove(ModelRotator, x_axis, BOAT_OUTSIDE_DISTANCE, 10)
  CloseDoors()
  WTurn(ModelRotator, 2, math.rad(90), 1)
  
end

function openWatersAtNextRotation()
  boolAllBelowWaters = true
  foreach(TableOfPiecesGroups["Sensors"),
    function(id)
      _,_,_,gh = isPieceAboveGround(id)
      if gh > 0 then boolAllBelowWaters= false end
    end
  return boolAllBelowWaters
end

function boatTakingToSea()
  --Turn right side

  -- Drive in circle.. check with probes for high seas
  for i=1, 360, 10 do
    WTurn(shipRotator, y_axis, math.rad(i), 0.1)
    boolIsOpenWaters = openWatersAtNextRotation()
    if boolIsOpenWaters then     
      turnToSeeAndFade(i)
      return
    end
end

function buildAnimation()
   while true do
    printABoat()
    LeaveAnimation()
    StartThread(boatTakingToSea)  
    Sleep(1000)
  end
end

function script.Killed(recentDamage, _)
    return 1
end



function script.StartMoving() end

function script.StopMoving() end

function script.Activate() return 1 end

function script.Deactivate() return 0 end
