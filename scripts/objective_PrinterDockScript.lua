include "createCorpse.lua"
include "lib_OS.lua"
include "lib_UnitScript.lua"
include "lib_mosaic.lua"

--[[
Cool01
Cool02
Cool03
Cool04
Cool05
Cool06
Cool07
Cool08
Cool09
Cool10
Cool11
Cool12
Cool13
Cool14
Cool15
Cool16
Cool17
Cool18
Cool19
Cool20
Cool21
Cool22
Cool23
Cool24
Cool25
Cool26
Cool27
Cool28
Cool29
Cool30
Cool31
Cool32
Cool33
Cool34
Cool35
Crane1
Crane2
  StackBPick
Crane3
  Object012
Dock
  DockDoor1
  DockDoor2
  Down002
  Down003
  Down004
  Down005
  Down006
  Down007
  Down1
  PowderLine002
  PowderLine003
  PowderLine004
  PowderLine005
  PowderLine006
  PowderLine007
  PowderLine008
  PowderLine009
  PowderLine010
  PowderLine011
  PowderLine012
  PowderLine013
  PowderLine014
  PowderLine015
  PowderLine016
  PowderLine017
  PowderLine018
  PowderLine019
  PowderLine020
  PowderLine1
  RailContainerPlace1
  RailContainerPlace2
  StackC01
  StackC02
  StackC03
  StackC04
Installer
  Bow
    DownBow
    Up002
    Up003
    Up004
    Up005
    Up006
    Up1
  Curtain
  HorizontalBeam1
    InstallBase01
      InstallUp1
        InstallLow1
          InstallTool1
  HorizontalBeam2
    InstallBase02
      InstallUp2
        InstallLow2
          InstallTool2
  InstallBeam1
    InstallBase03
      InstallUp3
        InstallLow3
          InstallTool3
    InstallBase04
      InstallUp4
        InstallLow4
          InstallTool4
  InstallerStack01
  InstallerStack02
  InstallerStack03
  InstallerStack04
  Up007
PowderLineRotator
Printer
  WeldCraneBeam1
    Extruder002
      Arm002
        UpArm002
          Weld001
            Arm1Drop005
            Arm1Drop006
            Arm1Drop007
            Arm1Drop008
            Circle002
            WeldSpot002
    Extruder1
      Arm1
        UpArm1
          Weld
            Arm1Drop002
            Arm1Drop003
            Arm1Drop004
            Arm1Drop1
            Circle001
            WeldSpot1
  WeldCraneBeam2
    Extruder003
      Arm003
        UpArm003
          Weld003
            Arm1Drop012
            Arm1Drop013
            Arm1Drop014
            Arm1Drop015
            Circle004
            WeldSpot003
    Extruder004
      Arm004
        UpArm004
          Weld002
            Arm1Drop009
            Arm1Drop010
            Arm1Drop011
            Arm1Drop016
            Circle003
            WeldSpot004
Ship01
  Propeller
  Ship02
  Ship03
  Ship04
  Ship05
  Ship06
  Ship07
  Ship08
  Ship09
  Ship10
  Ship11
  Ship12
  Ship13
  Ship14
  Ship15
  Ship16
  Ship17
  Ship18
  Ship19
  Ship20
  Ship21
  Ship22
  Ship23
  Ship24
  Ship25
  Ship26
  Ship27
  Ship28
  Ship29
  Ship30
  Ship31
  Ship32
  Ship33
  Ship34
  Ship35
Slice009
Slice037
Slice1
Slice10
Slice11
Slice12
Slice13
Slice14
Slice15
Slice16
Slice17
Slice18
Slice19
Slice2
Slice23
Slice24
Slice25
Slice26
Slice27
Slice28
Slice29
Slice3
Slice30
Slice31
Slice32
Slice33
Slice34
Slice35
Slice36
Slice36_ncl1_1
Slice4
Slice5
Slice6
Slice7
Slice8
SolarPanel01
SolarPanel02
SolarPanel03
SolarPanel04
SolarPanel05
SolarPanel06
SolarPanel07
SolarPanel08
SolarPanel09
SolarPanel10
SolarPanel11
SolarPanel12
SolarPanel13
SolarPanel14
SolarPanel15
SolarPanel16
SolarPanel17
SolarPanel18
SolarPanel19
SolarPanel20
SolarPanel21
SolarPanel22
SolarPanel23
SolarPanel24
StackA01
StackA02
StackA03
StackA04
StackA05
StackA06
StackAPick
StackB01
StackB02
StackB03
StackB04
StackB05


]]


Boat = piece("Boat")
TablesOfPiecesGroups = {}
function script.HitByWeapon(x, z, weaponDefID, damage) end

function script.Create()
    TablesOfPiecesGroups = getPieceTableByNameGroups(false, true)
    StartThread(buildAnimation)
end
function hideConstruction()
    hideT(ship)
    hideT(cool)
    hideT(slice)
end

travellDistancePrinter = 210
totalPiece = #TablesOfPiecesGroups["Ship"]
function piecePercent(step)
    factor = (step/totalPiece)
    return factor
end
function InstallerAnimation()

end
function updateInstallerCrane(step)
    position = piecePercent(step)*travellDistancePrinter
    Move(Installer, x_axis, position, 0.5)
    StartThread(InstallerAnimation)
end

function PrinterAnimation()

end

function updatePrinterCrane(step)
    position = piecePercent(step)*travellDistancePrinter
    Move(Installer, x_axis, position, 0.5)
    StartThread(PrinterAnimation)
end

function printABoat()
    local step = 1

    local ship  = TablesOfPiecesGroups["Ship"]
    local cool  = TablesOfPiecesGroups["Cool"]
    local slice = TablesOfPiecesGroups["Slice"]

    local nrOfSlices = #slice
    local slicesHot = 3
    local coolDownSlices = 10

    -- initial state
    hideConstruction()
    updateInstallerCrane(0)
    updatePrinterCrane(0)
    
    while step <= nrOfSlices do

        -- 1. HOT slice (current print head position)
        if slice[step] then
            Show(slice[step])
        end

        -- 2. Move older hot slices into cooled state
        local coolIndex = step - slicesHot
        if coolIndex >= 1 and slice[coolIndex] then
            Hide(slice[coolIndex])
            if cool[coolIndex] then
                Show(cool[coolIndex])
            end
        end

        -- 3. Finalize cooled slices into ship geometry
        local shipIndex = step - slicesHot - coolDownSlices
        if shipIndex >= 1 then
            if cool[shipIndex] then
                Hide(cool[shipIndex])
            end
            if ship[shipIndex] then
                Show(ship[shipIndex])
            end
        end

        Sleep(10000)
        step = step + 1
        updateInstallerCrane(step)
        updatePrinterCrane(step)
    end

    -- safety pass: ensure final ship is visible
    reset(Printer, 1)
    reset(Installer, 1.1)
    hideT(slice)
    hideT(cool)
    hideT(ship)
    Show(Boat)
end
Printer = piece("Printer")
Installer = piece("Installer")

function OpenDoors()
    Move(center, y_axis, -250, 10)
    WMove(Boat, y_axis, 250, 10)
    Turn(TablesOfPiecesGroups["DockDoor"][1],y_axis, math.rad(90), 1)
    Turn(TablesOfPiecesGroups["DockDoor"][2],y_axis, math.rad(-90), 1)
    WaitForTurns(TablesOfPiecesGroups["DockDoor"])
end

function CloseDoors()
  resetT(TablesOfPiecesGroups["DockDoor"], 0.1)
  WaitForTurns(TablesOfPiecesGroups["DockDoor"])
  Move(center, y_axis, 0, 10)
end

BOAT_OUTSIDE_DISTANCE= 12000
function LeaveAnimation()
  OpenDoors()
  WMove(Boat, x_axis, BOAT_OUTSIDE_DISTANCE, 120)
  CloseDoors()
  WTurn(Boat, 2, math.rad(90), 1)
  --detectorLoop
  
end

function openWatersAtNextRotation()
  boolAllBelowWaters = true
  foreach(TableOfPiecesGroups["Sensors"]),
    function(id)
      _,_,_,gh = isPieceAboveGround(id)
      if gh > 0 then boolAllBelowWaters= false end
    end
    )
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
