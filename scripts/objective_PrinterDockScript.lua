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

totalNrOfSlices = nil
TablesOfPiecesGroups = nil
function script.HitByWeapon(x, z, weaponDefID, damage) end
sliceData = {}
function script.Create()
    resetAll(unitID)
    TablesOfPiecesGroups = getPieceTableByNameGroups(false, true)
    StartThread(turnSolarTowardsSun)
    totalNrOfSlices = #TablesOfPiecesGroups["Ship"]
    ship  = TablesOfPiecesGroups["Ship"]
    cool  = TablesOfPiecesGroups["Cool"]
    slice = TablesOfPiecesGroups["Slice"]
    sliceData = GenerateContainerShipSlices(totalNrOfSlices)
    setup()
    StartThread(buildAnimation)
end

function setup()
    hideT(TablesOfPiecesGroups["WeldSpot"])
    hideT(TablesOfPiecesGroups["DeptSensor"])
    hideT(TablesOfPiecesGroups["Arm1Drop"])
    hideT(TablesOfPiecesGroups["Arm2Drop"])
    hideT(TablesOfPiecesGroups["Arm3Drop"])
    hideT(TablesOfPiecesGroups["Arm4Drop"])
    Hide(center)
    Hide(Boat)
    Hide( SensorRotator)
    Hide( BoatRotator)
    hideConstruction()
end

BridgeTemplate = {
{0,0,0,0,0,0,0,0},
{0,0,1,1,1,1,0,0},
{0,1,1,1,1,1,1,0},
{1,1,1,1,1,1,1,1},
{1,0,0,1,1,0,0,1},
{1,1,0,1,1,0,1,1},
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

SlabTemplate = {
{0,0,0,0,0,0,0,0},
{0,0,0,0,0,0,0,0},
{0,0,0,0,0,0,0,0},
{1,1,1,1,1,1,1,1},
{1,1,1,1,1,1,1,1},
{1,1,1,1,1,1,1,1},
{0,1,1,1,1,1,1,0},
{0,0,0,1,1,0,0,0}
}

Slabs = {10, 11, 15, 16, 20, 21, 25, 26}

BowTemplate = {
{
{0,0,0,0,0,0,0,0},
{0,0,0,0,0,0,0,0},
{0,0,0,0,0,0,0,0},
{0,1,1,1,1,1,1,0},
{0,1,1,1,1,1,1,0},
{0,1,1,1,1,1,1,0},
{0,0,1,1,1,1,0,0},
{0,0,0,1,1,0,0,0}
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

function VoxelToLines(ix, iz, scaleX, scaleZ)
  local x1 = (ix -1) * scaleX
  local x2 = x1 + scaleX
  local z  = (iz -1) * scaleZ
  return { x1, z, x2, z },{  x2, z, x1, z, }
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

BeamArmTable = {
    {2,1},
    {3,4},
}

function getArmBeam(arm)
    for beamNr, armT in pairs(BeamArmTable) do
        if isInTable(armT, arm) then return piece("HorizontalBeam"..beamNr) end
    end
end

function AssignArm(ix, iz)
    return RobotStartPositions[ix][iz]
end


bridgeEnd = 6
bowStart  = 31
function selecTemplate(index)
    --bridge
    if index < bridgeEnd then return BridgeTemplate end
    -- shipHull
    if index < bowStart then
        if isInTable(Slabs, index) then return SlabTemplate end
        return HullTemplate
    end
    --shipbow
    percent=  math.ceil(index-bowStart)
    return BowTemplate[clamp(percent, 1,  #BowTemplate)]
end

function  moveDebugPieceToPos(arm, ix, scaleX, iz, scaleZ )
    debugPiece= piece("debug"..arm.."_"..iz.."_"..ix)
    Move(debugPiece, armaxis, -ix * scaleX)
    Move(debugPiece, beamaxis, -iz * scaleZ)
    Show(debugPiece)
end

function modIndexFour(index)
    if index < 5 then return index end

    index = index -4 
    return index
end

function GenerateContainerShipSlices(nr)
  params = {}
  local slices      = params.slices or nr
  local bridgeEnd   = params.bridgeSlices or 6
  local scaleX      = params.scaleX or 5.0
  local scaleZ      = params.scaleZ or 5.0
  local sliceStep   = params.sliceStep or 350.0
  local offsetScale = 15
  local Print       = {}

  for s = 1, slices do
    Print[s] = { {}, {}, {}, {} }

    local template = selecTemplate(s)

    for iz = 1, 8 do
      for ix = 1, 8 do
        local arm = AssignArm(ix, iz)
        moveDebugPieceToPos(arm, modIndexFour(ix), scaleX, modIndexFour(iz), scaleZ )
        if template[ix][iz] == 1 then
          local lineForth = VoxelToLines(-modIndexFour(ix), -modIndexFour(iz), scaleX*30, scaleZ*30)
          table.insert(Print[s][arm], lineForth)        
        end
      end
    end
  end
  return Print
end

function EmitSparks(armNr)
  hideT(TablesOfPiecesGroups["Arm"..armNr.."Drop"])
  for i=1,4 do
      spark = TablesOfPiecesGroups["Arm"..armNr.."Drop"][i]
      reset(spark,0)  
      rval = math.random(-10, 10)
      Turn(spark, x_axis, math.rad(rval),0)
      Move(spark, y_axis, math.random(250,1200),750)  
      Show(spark)
      Hide(spark)
      reset(spark,0)
  end
  WaitForMoves(TablesOfPiecesGroups["Arm"..armNr.."Drop"])
  hideT(TablesOfPiecesGroups["Arm"..armNr.."Drop"])
  resetT(TablesOfPiecesGroups["Arm"..armNr.."Drop"])
end

function AnimateRobotsPrintingSlice(sliceNr, sliceDataSlice,  slice)
  local armCount = 4
  for arm = 1, armCount do
    beam = getArmBeam(arm)
    StartThread(AnimateArmLines, arm, beam, sliceDataSlice[arm],  slice)
  end
end

function weldLights(signal, weld, weldAlt)
    Signal(signal)
    SetSignalMask(signal)
    Hide(weld)
    Hide(weldAlt)
    spot = weld
    for a=1, 6 do
        if maRa() then
            spot = weld
        else
            spot = weldAlt
        end
        Show(spot)
        Sleep(250)
        Hide(spot)
    end
end

beamaxis = y_axis
armaxis = z_axis

function randomFoldArm(ArmUp, ArmLow, speed)
    val= math.random(-60, 60)
    Turn(ArmUp,armaxis, math.rad(val), speed)
    Turn(ArmLow,armaxis, math.rad(-val), speed)
    WaitForTurns(ArmLow, ArmUp)
end

function AnimateArmLines(armNr, beam, lines, slice)
  local n = #lines
  if n == 0 then echo("Arm nr:"..armNr.. " has no lines"); return end

  
  local weld = TablesOfPiecesGroups["WeldSpot"][armNr]
  local weldAlt = TablesOfPiecesGroups["WeldSpot"][armNr+4]
  ArmLow = TablesOfPiecesGroups["Arm"][armNr]
  ArmUp = TablesOfPiecesGroups["UpArm"][armNr]
  Extruder = TablesOfPiecesGroups["Extruder"][armNr]
  signal= 2^armNr
  while Spring.UnitScript.IsInMove(slice, x_axis)  do
      for _, L in ipairs(lines) do
          StartThread(weldLights, signal, weld, weldAlt)
          StartThread(EmitSparks, armNr)
          StartThread(randomFoldArm, ArmUp, ArmLow, 5)
          local x1,z1,x2,z2 = L[1],L[2],L[3],L[4]

          for i=1, 2 do

          -- linear draw
          Move(Extruder, z_axis, x1, math.abs(x1))
          Move(beam, beamaxis, z1, math.abs(z1))      
          WaitForMoves(Extruder, beam)

          StartThread(weldLights, signal, weld, weldAlt)
          StartThread(EmitSparks, armNr)
          StartThread(randomFoldArm, ArmUp, ArmLow, 5)
          
          Move(Extruder, z_axis, x2, math.abs(x2))
          Move(beam, beamaxis, z2, math.abs(z2))
          WaitForMoves(Extruder, beam)
          Sleep(100)
          end
      end
  end
  reset(beam, 2)
  Signal(signal)
  Turn(ArmLow,armaxis, math.rad(90),2)
  Turn(ArmUp,armaxis, math.rad(-80),2)

  Signal(signal)
  Hide(weld)
  Hide(weldAlt)
end


function hideConstruction()
    hideT(ship)
    hideT(cool)
    hideT(slice)
end

travellDistancePrinter = 250

function piecePercent(step)
    factor = (step/totalNrOfSlices)
    return factor
end
curtain = piece("Curtain")

function turnSolarTowardsSun()
  turnTowardsSun(unitID, TablesOfPiecesGroups["SolarPanel"])
end

Bow = piece("Bow")
InstallerAnimationMs = 6000
function InstallerAnimation(step)
  halfStep = math.ceil(step/2)
  --Move bow towards installercrane
  Move(Bow, x_axis, halfStep * -travellDistancePrinter)
  upIndexBlendOut = mapIndexToIndex(halfStep, math.min(totalNrOfSlices/2), #TablesOfPiecesGroups["Up"])
  hideT(TablesOfPiecesGroups["Up"])
  showT(TablesOfPiecesGroups["Up"], 1, #TablesOfPiecesGroups["Up"] - upIndexBlendOut)

  hideT(TablesOfPiecesGroups["Down"])
  downIndexBlendIn = mapIndexToIndex(halfStep, math.min(totalNrOfSlices/2), #TablesOfPiecesGroups["Down"])
  showT(TablesOfPiecesGroups["Down"], 1, downIndexBlendIn)
  animateInstallerRobotsForTime(InstallerAnimationMs)
end

BaseDepth = {}
BeamTravellSpeed = 15
function moveVerticalInstallerRobot( robotNr)
    local Base = TablesOfPiecesGroups["HorizontalBeam"][robotNr]
    local InstallBase = TablesOfPiecesGroups["InstallBase"][robotNr] 
    local InstallLow = TablesOfPiecesGroups["InstallLow"][robotNr] 
    local InstallUp = TablesOfPiecesGroups["InstallUp"][robotNr]  

    armGoal = math.random( InstallerBeamDepth, InstallerBeamRange)
    BaseDepth[robotNr] = armGoal
    WMove(Base, y_axis, -armGoal, BeamTravellSpeed)
    rotVal = math.random( -90, 90)
    Turn(InstallBase, z_axis, math.rad(rotVal), 0.5)
    adaptVal = math.random(-45,45)
    Turn(InstallLow, z_axis, math.rad(adaptVal), 0.5)
    Turn(InstallUp, z_axis, math.rad(-adaptVal), 0.5)
    WaitForTurns(InstallBase, InstallLow, InstallUp)
    Sleep(1500)
        Turn(InstallLow, z_axis, math.rad(0), 0.5)
        Turn(InstallUp, z_axis, math.rad(0), 0.5)
    Sleep(3000)
        adaptVal = math.random(60,70)*randSign()
    Turn(InstallLow, z_axis, math.rad(adaptVal), 0.5)
    Turn(InstallUp, z_axis, math.rad(-2*adaptVal), 0.5)
    WaitForTurns(InstallBase, InstallLow, InstallUp)
end

function moveHorizontalInstallerRobot( robotNr)
    local InstallBase = TablesOfPiecesGroups["InstallBase"][robotNr] 
    local InstallLow = TablesOfPiecesGroups["InstallLow"][robotNr] 
    local InstallUp = TablesOfPiecesGroups["InstallUp"][robotNr]  

    goal = math.random(0, 10) * randSign()
    Move(InstallBase, z_axis, goal, 5 )
    adaptVal = math.random(-45,45)
    Turn(InstallLow, x_axis, math.rad(adaptVal), 0.5)
    Turn(InstallUp, x_axis, math.rad(-adaptVal), 0.5)
    Move(InstallBase, z_axis, goal, 5 )
    WaitForTurns(InstallBase, InstallLow, InstallUp)

    Sleep(1500)
    Turn(InstallLow, x_axis, math.rad(0), 0.5)
    Turn(InstallUp, x_axis, math.rad(0), 0.5)
    
    Sleep(3000)
    adaptVal = math.random(60,70)*randSign()
    Turn(InstallLow, x_axis, math.rad(adaptVal), 0.5)
    Turn(InstallUp, x_axis, math.rad(-2*adaptVal), 0.5)
    WaitForTurns(InstallBase, InstallLow, InstallUp)
end

InstallerBeamDepth = 0
InstallerBeamRange = 150
InstallBeam = piece("InstallBeam1")
function animateInstallerRobotsForTime(timeInMs)
    while timeInMs > 0 do 
        StartThread(moveVerticalInstallerRobot, 1)
        StartThread(moveVerticalInstallerRobot, 2)
        robotMinDepth = getInTable(BaseDepth, math.min)
        beamDepth = math.random(0, robotMinDepth )
        Move(InstallBeam, y_axis, -beamDepth, BeamTravellSpeed)
        StartThread(moveHorizontalInstallerRobot,3)
        StartThread(moveHorizontalInstallerRobot,4)
        WMove(InstallBeam, y_axis, -beamDepth, BeamTravellSpeed)
        timeInMs = timeInMs - 3000
        Sleep(3000)
    end
end

function updateInstallerCrane(step)
    position = piecePercent(step) * -travellDistancePrinter
    Turn(curtain, x_axis, math.rad(-2), 0.1)
    WMove(Installer, x_axis, position, 0.5)
    Spin(curtain, y_axis, math.rad(0.1), 0.1)
    WTurn(curtain, x_axis, math.rad(0), 0.25)
    stopSpins(curtain)
    reset(curtain)
    StartThread(InstallerAnimation, step)
end

function updatePrinterCrane(step, slice, index)

    position = piecePercent(step) * -travellDistancePrinter
    showT(TablesOfPiecesGroups["PowderLine"])
    powderLineIndex = mapIndexToIndex(step, totalNrOfSlices, #TablesOfPiecesGroups["PowderLine"])
    hideT(TablesOfPiecesGroups["PowderLine"], powderLineIndex, math.min(powderLineIndex + 2, #TablesOfPiecesGroups["PowderLine"]))
    WMove(Printer, x_axis, position, 0.5)
    if slice then
        Hide(sice)
        Move(slice, x_axis, 6, 0)
        Show(slice)
        Move(slice, x_axis, 0, 0.125)
    end
    if index and sliceData[index] then
        AnimateRobotsPrintingSlice(step, sliceData[index], slice)
    end
    if slice then
        WMove(slice, x_axis, 0, 0.125)
        hideT(TablesOfPiecesGroups["Arm1Drop"])
        hideT(TablesOfPiecesGroups["Arm2Drop"])
        hideT(TablesOfPiecesGroups["Arm3Drop"])
        hideT(TablesOfPiecesGroups["Arm4Drop"])
        hideT(TablesOfPiecesGroups["WeldSpot"])

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
    updatePrinterCrane(0)
    
    while step <= nrOfSlices do
        updatePrinterCrane(step + 1, slice[step], step)
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
    foreach(TablesOfPiecesGroups["Sensors"],
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
