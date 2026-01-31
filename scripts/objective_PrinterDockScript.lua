include "createCorpse.lua"
include "lib_OS.lua"
include "lib_Animation.lua"
include "lib_UnitScript.lua"
include "lib_mosaic.lua"

Printer = piece("Printer")
Installer = piece("Installer")

center = piece("center")
Boat = piece("Boat")
SensorRotator = piece("SensorRotator")
BoatRotator = piece("BoatRotator")

totalPiece = nil
TablesOfPiecesGroups = nil
function script.HitByWeapon(x, z, weaponDefID, damage) end
sliceData = {}
function script.Create()
    resetAll(unitID)
    TablesOfPiecesGroups = getPieceTableByNameGroups(false, true)
    totalPiece = #TablesOfPiecesGroups["Ship"]
    ship  = TablesOfPiecesGroups["Ship"]
    cool  = TablesOfPiecesGroups["Cool"]
    slice = TablesOfPiecesGroups["Slice"]
    sliceData = GenerateContainerShipSlices(totalPiece)
    setup()
    StartThread(buildAnimation)
end

function setup()
    hideT(TablesOfPiecesGroups["WeldSpot"])
    hideT(TablesOfPiecesGroups["DeptSensor"])
    hideT(TablesOfPiecesGroups["Arm1Drop"])
    Hide(center)
    Hide(Boat)
    Hide( SensorRotator)
    Hide( BoatRotator)
    hideConstruction()
end

BridgeTemplate = {
{0,0,0,1,1,0,0,0},
{0,0,1,0,0,1,0,0},
{0,1,1,1,1,1,1,0},
{1,1,1,1,1,1,1,1},
{1,0,0,0,0,0,0,1},
{1,1,0,0,0,0,1,1},
{0,1,1,1,1,1,1,0},
{0,0,0,1,1,0,0,0},
}

HullTemplate = {
{0,0,0,0,0,0,0,0},
{0,0,0,0,0,0,0,0},
{0,0,0,0,0,0,0,0},
{1,1,1,1,1,1,1,1},
{1,0,0,0,0,0,0,1},
{1,1,0,0,0,0,1,1},
{0,1,1,1,1,1,1,0},
{0,0,0,1,1,0,0,0},
}

<<<<<<< HEAD
SlabTemplate = {
{0,0,0,0,0,0,0,0},
{0,0,0,0,0,0,0,0},
{0,0,0,0,0,0,0,0},
{1,1,1,1,1,1,1,1},
{1,1,1,1,1,1,1,1},
{1,1,1,1,1,1,1,1},
{0,1,1,1,1,1,1,0},
{0,0,0,1,1,0,0,0},
}


BowTemplate = {
{
{0,0,0,0,0,0,0,0},
{0,0,0,0,0,0,0,0},
{0,0,0,0,0,0,0,0},
{0,1,1,1,1,1,1,0},
{0,1,1,1,1,1,1,0},
{0,1,1,1,1,1,1,0},
{0,0,1,1,1,1,0,0},
{0,0,0,1,1,0,0,0},
},
{
{0,0,0,0,0,0,0,0},
{0,0,0,0,0,0,0,0},
{0,0,0,0,0,0,0,0},
{0,1,1,1,1,1,1,0},
{0,1,1,1,1,1,1,0},
{0,0,1,1,1,1,0,0},
{0,0,0,1,1,0,0,0},
{0,0,0,0,0,0,0,0},
},
{
{0,0,0,0,0,0,0,0},
{0,0,0,0,0,0,0,0},
{0,0,0,0,0,0,0,0},
{0,1,1,1,1,1,1,0},
{0,0,1,1,1,1,0,0},
{0,0,0,1,1,0,0,0},
{0,0,0,0,0,0,0,0},
{0,0,0,0,0,0,0,0},
},
{
{0,0,0,0,0,0,0,0},
{0,0,0,0,0,0,0,0},
{0,0,0,0,0,0,0,0},
{0,0,1,1,1,1,0,0},
{0,0,0,1,1,0,0,0},
{0,0,0,0,0,0,0,0},
{0,0,0,0,0,0,0,0},
{0,0,0,0,0,0,0,0},
},
{
{0,0,0,0,0,0,0,0},
{0,0,0,0,0,0,0,0},
{0,0,0,0,0,0,0,0},
{0,0,0,1,1,0,0,0},
{0,0,0,0,0,0,0,0},
{0,0,0,0,0,0,0,0},
{0,0,0,0,0,0,0,0},
{0,0,0,0,0,0,0,0},
},
}

function VoxelToLine(ix, iz, scaleX, scaleZ)
  local x1 = (ix - 4.5) * scaleX
  local x2 = x1 + scaleX
  local z  = (iz - 4.5) * scaleZ
  return { x1, z, x2, z },{ x1, z, x2, z },
end

RobotStartPositions = { 
    { 2 , 2 , 2 , 2 , 1, 1 , 1 , 1 }, 
    { 2 , 2 , 2 , 2 , 1, 1 , 1 , 1 }, 
    { 2 , 2 , 2 , 2 , 1, 1 , 1 , 1 }, 
    { 2 , 2 , 2 , 2 , 1, 1 , 1 , 1 }, 
    { 3 , 3 , 3 , 3 , 4, 4 , 4 , 4 }, 
    { 3 , 3 , 3 , 3 , 4, 4 , 4 , 4 }, 
    { 3 , 3 , 3 , 3 , 4, 4 , 4 , 4 }, 
    { 3 , 3 , 3 , 3 , 4, 4 , 4 , 4 }}

function AssignArm(ix, iz)
  local bestArm, bestDist = 1, math.huge

  for z=1,8 do
    for x=1,8 do
      return RobotStartPositions[z][x]
    end
  end
  assert(false)
end

function GetArmOffset(arm)
  if arm == 2 then return 0, 0 end
  if arm == 1 then return 4, 0 end
  if arm == 3 then return 0, 4 end
  if arm == 4 then return 4, 4 end
end

bridgeEnd = 6
bowStart  = 31
function selecTemplate(index)
    --bridge
    if index < bridgeEnd then return BridgeTemplate end
    -- shipHull
    if index < bowStart then
        if index % 5 == 0 then return SlabTemplate end
        return HullTemplate
    end
    --shipbow
    percent=  math.ceil(index-bowStart)
    return BowTemplate[clamp(1, percent, #BowTemplate)]
end

function GenerateContainerShipSlices(nr)
  params = {}
  local slices      = params.slices or nr

  local bridgeEnd   = params.bridgeSlices or 6
  local scaleX      = params.scaleX or 10.0
  local scaleZ      = params.scaleZ or 10.0
  local sliceStep   = params.sliceStep or 350.0

  local Print = {}

  for s = 1, slices do
    Print[s] = { {}, {}, {}, {} }

    local template = selecTemplate(s)

    for iz = 1, 8 do
      for ix = 1, 8 do
        if template[iz][ix] == 1 then
          local arm = AssignArm(ix, iz)
          ox, oz = GetArmOffset(arm)
          local line = VoxelToLine(ix-ox, iz-oz, scaleX, scaleZ)
          table.insert(Print[s][arm], line)
        end
      end
    end
  end
  return Print
end

function EmitSparks(armNr)
  spark = TablesOfPiecesGroups["Arm"..armNr.."Drop"][math.random(1,4)]
  reset(spark,0)  
  spinRand(spark, -42, 42)
  Move(spark, x_axis, math.random(-120,120),60)
  Move(spark, y_axis, math.random(-120,120),60)
  Move(spark, z_axis, math.random(-120,120),60)
  Show(spark)
  WaitForMoves(spark)
  Hide(spark)
  stopSpins(spark)
  reset(spark,0)
end

function AnimateRobotsPrintingSlice(sliceNr, sliceDataSlice, timeMs)
  local armCount = 4
  local timePerArm = timeMs / 2

  for arm = 1, armCount do
    index = math.ceil(arm/2)
    beam = TablesOfPiecesGroups["WeldCraneBeam"][index]
    StartThread(AnimateArmLines, arm, beam, sliceDataSlice[arm], timePerArm)
  end
end

function weldLights(signal, weld)
    Signal(signal)
    randSpin(weld, -10, 10)
    SetSignalMask(signal)
    Show(weld)
    Sleep(100)
    Hide(weld)
end
beamaxis = y_axis
armaxis = x_axis

function randomFoldArm(ArmUp, ArmLow, speed)
    val= math.random(-60,60)
    Turn(ArmUp,armaxis, math.rad(val), speed)
    Turn(ArmLow,armaxis, math.rad(-val), speed)
    WaitForTurns(ArmLow, ArmUp)
end
function AnimateArmLines(armNr, beam, lines, timeMs)
  local n = #lines
  if n == 0 then return end

  local segTime = timeMs / n
  local weld = TablesOfPiecesGroups["WeldSpot"][armNr]
  ArmLow = TablesOfPiecesGroups["Arm"][armNr]
  ArmUp = TablesOfPiecesGroups["UpArm"][armNr]
  Extruder = TablesOfPiecesGroups["Extruder"][armNr]
  signal= 2^armNr

  for _, L in ipairs(lines) do
    StartThread(weldLights, signal, weld)
    StartThread(EmitSparks, armNr)
    StartThread(randomFoldArm, ArmUp, ArmLow, 25)
    local x1,z1,x2,z2 = L[1],L[2],L[3],L[4]

    -- linear draw
    Move(Extruder, z_axis, x1, segTime*0.5)
    Move(beam, beamaxis, z1, segTime*0.5)
    
    WaitForMoves(Extruder, beam)
    StartThread(weldLights, signal, weld)
    StartThread(EmitSparks, armNr)
    StartThread(randomFoldArm, ArmUp, ArmLow, 25)
    
    Move(Extruder, z_axis, x2, segTime)
    Move(beam, beamaxis, z2, segTime)
    waitForMovesForTime(segTime, Extruder, beam)
    Sleep(100)
  end
  reset(beam, 2)
  Turn(ArmLow,armaxis, math.rad(90),2)
  Turn(ArmUp,armaxis, math.rad(80),2)

  Signal(signal)
  Hide(weld)
end


function hideConstruction()
    hideT(ship)
    hideT(cool)
    hideT(slice)
end

travellDistancePrinter = 250

function piecePercent(step)
    factor = (step/totalPiece)
    return factor
end
curtain = piece("Curtain")
function InstallerAnimation()


end
function updateInstallerCrane(step)
    position = piecePercent(step) * -travellDistancePrinter
    Turn(curtain, x_axis, math.rad(-2), 0.1)
    WMove(Installer, x_axis, position, 0.5)
    Spin(curtain, y_axis, math.rad(0.1), 0.1)
    WTurn(curtain, x_axis, math.rad(0), 0.25)
    stopSpins(curtain)
    reset(curtain)
    StartThread(InstallerAnimation)
end

function updatePrinterCrane(step, slice, index)
    position = piecePercent(step) * -travellDistancePrinter
    WMove(Printer, x_axis, position, 0.5)
    if slice then
        Hide(sice)
        Move(slice, x_axis, 6, 0)
        Show(slice)
        Move(slice, x_axis, 0, 0.125)
    end
    if index and sliceData[index] then
        AnimateRobotsPrintingSlice(step, sliceData[index], travellDistancePrinter/0.125)
    end
    if slice then
        WMove(slice, x_axis, 0, 0.125)
    end
end

function printABoat()
    local step = 1
    local nrOfSlices = #slice
    local slicesHot = 3
    local coolDownSlices = 10

    -- initial state
    hideConstruction()
    updateInstallerCrane(0)
    updatePrinterCrane(1)
    
    while step <= nrOfSlices do
        updatePrinterCrane(step + 2, slice[step], step)
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

        updateInstallerCrane(math.max(0, step-10))
        step = step + 1        
    end

    -- safety pass: ensure final ship is visible
    reset(Printer, 1)
    reset(Installer, 1.1)
    hideT(slice)
    hideT(cool)
    hideT(ship)
    Show(Boat)
end


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
    foreach(TableOfPiecesGroups["Sensors"],
        function(id)
          _,_,_,gh = isPieceAboveGround(id)
          if gh > 0 then boolAllBelowWaters= false end
        end
        )
    return boolAllBelowWaters
end

function resetBoat()
Hide(Boat)
reset(Boat)
reset(shipRotator)
reset(sensorRotator)

end
function turnToSeaAndFade(degree)
Turn(Boat, y_axis, math.rad(90), 2)
WTurn(shipRotator, y_axis, math.rad(math.max(0, degree-15)), 1)
Turn(Boat, y_axis, math.rad(0), 3)
WTurn(shipRotator, y_axis, math.rad(degree), 1)
WMove(Boat, x_axis, 1000, 30)
WMove(Boat, x_axis, 2000, 60)
WMove(Boat, x_axis, 3000, 120)
resetBoat()
end

function boatTakingToSea()
  --Turn right side
  -- Drive in circle.. check with probes for high seas
  for i=1, 360, 10 do
    WTurn(sensorRotator, y_axis, math.rad(i), 0.1)
    boolIsOpenWaters = openWatersAtNextRotation()
        if boolIsOpenWaters then     
          turnToSeaAndFade(i)
          return
        end
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
