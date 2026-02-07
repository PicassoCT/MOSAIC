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
    hideT(TablesOfPiecesGroups["Down"])
    hideT(TablesOfPiecesGroups["Slice1Sub"])
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
    foreach(TablesOfPiecesGroups["Arm"][armNr], function(ArmLow) Turn(ArmLow,armaxis, math.rad(90),2) end)
    foreach(TablesOfPiecesGroups["UpArm"][armNr], function(UpArm)   Turn(UpArm,armaxis, math.rad(-80),2) end)
    hideConstruction()
end

BridgeTemplate = {
{0,0,0,0,0,0,0,0},
{0,0,1,1,1,1,0,0},
{0,1,1,1,1,1,1,0},
{1,1,1,1,1,1,1,1},
{1,1,0,0,0,0,1,1},
{1,1,0,0,0,0,1,1},
{0,1,1,1,1,1,1,0},
{0,0,1,1,1,0,0,0},
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
{1,0,0,0,0,0,0,0},
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
  return { x1, z, x2, z, ix, iz },{  x2, z, x1, z, ix, iz}
end

RobotStartPositions = { 
    { 2 , 2 , 2 , 2 , 1 , 1 , 1 , 1 }, 
    { 2 , 2 , 2 , 2 , 1 , 1 , 1 , 1 }, 
    { 2 , 2 , 2 , 2 , 1 , 1 , 1 , 1 }, 
    { 2 , 2 , 2 , 2 , 1 , 1 , 1 , 1 }, 
    { 4,  4 , 4 , 4 , 3 , 3 , 3 , 3 }, 
    { 4,  4 , 4 , 4 , 3 , 3 , 3 , 3 }, 
    { 4,  4 , 4 , 4 , 3 , 3 , 3 , 3 }, 
    { 4,  4 , 4 , 4 , 3 , 3 , 3 , 3 }}





function getArmBeam(arm)
    BeamArmTable = {
    [1] =TablesOfPiecesGroups["WeldCraneBeam"][1],
    [2] =TablesOfPiecesGroups["WeldCraneBeam"][1],
    [3] =TablesOfPiecesGroups["WeldCraneBeam"][2],
    [4] =TablesOfPiecesGroups["WeldCraneBeam"][2],
    }
    return BeamArmTable[arm]
end

function AssignArm(ix, iz)
    return RobotStartPositions[ix][iz]
end


bridgeEnd = 6
bowStart  = 31
function selectTemplate(index)
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

function hideDebugPieces()
    for arm=1, 4 do 
        for iz = 1, 8 do
          for ix = 1, 8 do
            debugPiece= piece("debug"..arm.."_"..(modIndexFour(iz)).."_"..(modIndexFour(ix)))
            reset(debugPiece)
            Hide(debugPiece)
          end
        end
    end
end

function  moveDebugPieceToPos(arm, ix, scaleX, iz, scaleZ )
    debugPiece= piece("debug"..arm.."_"..math.abs(iz).."_"..math.abs(ix))
    Show(debugPiece)
    Move(debugPiece, z_axis, ix * scaleX)
    Move(debugPiece, beamaxis,  iz * scaleZ)
end

function modIndexFour(index)
    if index < 5 then return index end

    return (index % 4)
end
sliceStepHeight= 3.5
function GenerateContainerShipSlices(nr)
  params = {}
  local slices      = params.slices or nr
  local bridgeEnd   = params.bridgeSlices or 6
  local scaleX      = params.scaleX or sliceStepHeight
  local scaleZ      = params.scaleZ or sliceStepHeight
  local offsetScale = 15
  local Print       = {}

  for s = 1, slices do
    Print[s] = { {}, {}, {}, {} }

    local template = selectTemplate(s)

    for iz = 1, 8 do
      for ix = 1, 8 do
        --moveDebugPieceToPos(arm, modIndexFour(ix), scaleX, modIndexFour(iz), scaleZ )
        if template[ix][iz] == 1 then
            local arm = AssignArm(ix, iz)
            local lineForth = VoxelToLines(
                                        modIndexFour(ix), 
                                        modIndexFour(iz), 
                                        scaleX , 
                                        scaleZ )

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
        WaitForMoves(spark)
        if maRa() then
            Sleep(100)
        end
        Show(spark)
        Move(spark, x_axis, -math.random(-150,150),1250)  
        Move(spark, z_axis, -math.random(-150,150),1250)  
        Move(spark, y_axis, -math.random(2500,7500),1250)  
  end
  Sleep(500)
  WaitMoveHidesT(TablesOfPiecesGroups["Arm"..armNr.."Drop"])
  resetT(TablesOfPiecesGroups["Arm"..armNr.."Drop"])
end

function weldLights(signal, weld, weldAlt)
    Signal(signal)
    SetSignalMask(signal)
    Hide(weld)
    Hide(weldAlt)
    spot = weld
    for a= 1, 6 do
        if maRa() then
            spot = weld
        else
            spot = weldAlt
        end
        spinRand(spot, -8000, 8000)
        Show(spot)
        Sleep(125)
        if maRa() then Hide(spot) end
    end
end

beamaxis = y_axis
armaxis = z_axis
firstSliceCounter = 1
function buildUpFirstSlice()
    showT(TablesOfPiecesGroups["Slice1Sub"],1, math.min(firstSliceCounter,#TablesOfPiecesGroups["Slice1Sub"]))
    firstSliceCounter = firstSliceCounter + 1
end

function randomFoldArm(ArmUp, ArmLow, speed)
    val= math.random(-60, 60)
    Turn(ArmUp,armaxis, math.rad(val), speed)
    Turn(ArmLow,armaxis, math.rad(-val), speed)
    WaitForTurns(ArmLow, ArmUp)
end

function AnimateArmLines(armNr, beam, lines, slice, step)
  local n = #lines
  if n == 0 then echo("Arm nr:"..armNr.. " has no lines"); return end

  
  local weld = TablesOfPiecesGroups["WeldSpot"][armNr]
  local weldAlt = TablesOfPiecesGroups["WeldSpot"][armNr+4]
  local ArmLow = TablesOfPiecesGroups["Arm"][armNr]
  local ArmUp = TablesOfPiecesGroups["UpArm"][armNr]
  local Extruder = TablesOfPiecesGroups["Extruder"][armNr]
  local signal= 2^armNr

  while Spring.UnitScript.IsInMove(slice, x_axis)  do
      for _, L in ipairs(lines) do
          StartThread(weldLights, signal, weld, weldAlt)
          StartThread(EmitSparks, armNr)
          StartThread(randomFoldArm, ArmUp, ArmLow, 5)
          local x1,z1,x2,z2, ix, iz = L[1],L[2],L[3],L[4],L[5],L[6]
          moveDebugPieceToPos(armNr, ix, 3.5, iz, 3.5)
          for i=1, 2 do
              -- linear draw
              Move(Extruder, z_axis, x1, math.abs(x1))
              if armNr % 2 == 1 then
                Move(beam, beamaxis,  z1, math.abs(z1))      
              end
              WaitForMoves(Extruder, beam)

              StartThread(weldLights, signal, weld, weldAlt)
              StartThread(EmitSparks, armNr)
              StartThread(randomFoldArm, ArmUp, ArmLow, 5)
              
              Move(Extruder, z_axis, x2, math.abs(x2))
              if armNr % 2 == 1 then
                Move(beam, beamaxis,   z2, math.abs(z2))
              end
              WaitForMoves(Extruder, beam)
               if step == 1 then 
                buildUpFirstSlice()
               end
              Sleep(100)
          end
      end
     
  end
  Signal(signal)
  Turn(ArmLow, armaxis, math.rad(90),2)
  Turn(ArmUp, armaxis, math.rad(-80),2)
  Hide(weld)
  Hide(weldAlt)
end


function hideConstruction()
    hideT(ship)
    hideT(cool)
    hideT(slice)
    hideT(TablesOfPiecesGroups["Slice1Sub"])
end

travellDistancePrinter = 250 + (250*(1/37)) 

function piecePercent(step)
    factor = (step/totalNrOfSlices)
    return factor
end
curtain = piece("Curtain")

function turnSolarTowardsSun()
  turnTowardsSun(unitID, TablesOfPiecesGroups["SolarPanel"])
end

function updateCableBowAnimation(step)
      halfStep = math.floor(step/2)
      Move(Bow, x_axis, halfStep * -travellDistancePrinter)
      upIndexBlendOut = mapIndexToIndex(halfStep, math.min(totalNrOfSlices/2), #TablesOfPiecesGroups["Up"])
      hideT(TablesOfPiecesGroups["Up"])
      showT(TablesOfPiecesGroups["Up"], upIndexBlendOut, #TablesOfPiecesGroups["Up"] )

      hideT(TablesOfPiecesGroups["Down"])
      downIndexBlendIn = mapIndexToIndex(halfStep, math.min(totalNrOfSlices/2), #TablesOfPiecesGroups["Down"])
      showT(TablesOfPiecesGroups["Down"], 1, downIndexBlendIn)
end

Bow = piece("Bow")

function InstallerAnimation(step)

  --Move bow towards installercrane
  updateCableBowAnimation(step)
  animateInstallerRobotsForTime(step)
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

function moveHorizontalInstallerRobot( robotNr, beamDepth)
    local InstallBase = TablesOfPiecesGroups["InstallBase"][robotNr] 
    local InstallLow = TablesOfPiecesGroups["InstallLow"][robotNr] 
    local InstallUp = TablesOfPiecesGroups["InstallUp"][robotNr]  

    goal = math.random(0, 10) * (beamDepth-1)
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

function getHighestPointOfSlice(step)
    if not  sliceData[step] then return 0 end
    mySlice = sliceData[step]
    for x=1, #mySlice do
        for z =1, #mySlice[x] do
            if mySlice[x][z] == 1 then return x * sliceStepHeight end
        end 
    end
    return 0
end

InstallerBeamDepth = 0
InstallerBeamRange = 150
InstallBeam = piece("InstallBeam1")
function animateInstallerRobotsForTime(step)
    beamDepth = getHighestPointOfSlice(step)
    while Spring.UnitScript.IsInMove(Installer, x_axis)  do 
        StartThread(moveVerticalInstallerRobot, 1)
        StartThread(moveVerticalInstallerRobot, 2)
        
        Move(InstallBeam, y_axis, beamDepth, BeamTravellSpeed)
        StartThread(moveHorizontalInstallerRobot,3, beamDepth)
        StartThread(moveHorizontalInstallerRobot,4 , beamDepth)

        
        Sleep(5000)
    end
end

function updateInstallerCrane(step)
    globalStep= step
    if step > 0 then
    position = piecePercent(step) * -travellDistancePrinter
    Turn(curtain, z_axis, math.rad(-2), 0.1)
    WMove(Installer, x_axis, position, 0.5)
    Spin(curtain, y_axis, math.rad(0.1), 0.1)
    WTurn(curtain, z_axis, math.rad(0), 0.25)
    stopSpins(curtain)
    reset(curtain, 0.5)
    StartThread(InstallerAnimation, step)
    end
end

function updatePrinterCrane(step, speed, boolWait, slice, index)
    offset = 2
    position = (piecePercent(step) * -travellDistancePrinter) - offset
    hideT(TablesOfPiecesGroups["PowderLine"])
    powderLineIndex = mapIndexToIndex(step, totalNrOfSlices, #TablesOfPiecesGroups["PowderLine"])
    showT(TablesOfPiecesGroups["PowderLine"], 1,  powderLineIndex)
    Move(Printer, x_axis, position, speed)
    if boolWait then
        WMove(Printer, x_axis, position, speed)
    end 
    if slice then
        Hide(sice)
        Move(slice, x_axis, 6, 0)
        Show(slice)
        Move(slice, x_axis, 0, 0.125)
    end
    if index and sliceData[index] then
         local armCount = 4
          for arm = 1, armCount do
            local beam = getArmBeam(arm)
            StartThread(AnimateArmLines, arm, beam, sliceData[index][arm],  slice, step)
          end
    end
    if slice then
        WMove(slice, x_axis, 0, 0.125)
        hideT(TablesOfPiecesGroups["Arm1Drop"])
        hideT(TablesOfPiecesGroups["Arm2Drop"])
        hideT(TablesOfPiecesGroups["Arm3Drop"])
        hideT(TablesOfPiecesGroups["Arm4Drop"])
        hideT(TablesOfPiecesGroups["WeldSpot"])
    end
    WMove(Printer, x_axis, position, speed)
end
globalStep = 0
function printABoat()
    local step = 1
    local nrOfSlices = #slice
    local slicesHot = 3
    local coolDownSlices = 10

    -- initial state
    hideConstruction()
    updateInstallerCrane(0)

    updatePrinterCrane(0, 0.5, true )
    boolPrinting = true
    while step <= nrOfSlices do
        hideDebugPieces()
        updatePrinterCrane(step + 1, 0.125, false, slice[step], step)
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
    boolPrinting= false
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
    setup()
    StartThread(crane1Animation)
    StartThread(crane2Animation)
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

boolPrinting = true
CraneAnimationsRunning = {}
function crane1Animation()
    CraneAnimationsRunning[1]= true
    Crane1 = piece("Crane1")
    StackAPick = piece("StackAPick")
    Container = TablesOfPiecesGroups["StackA"]
    elevator =piece("ElevatorA")
    Hide(StackAPick)
    while true do

        hideT(Container)
        WMove(elevator, y_axis, -10, 0.5)
        Sleep(5000)
        showT(Container)
        Sleep(5000)
        WMove(elevator, y_axis, 0, 0.5)

        Sleep(5000)
        crane1Counter = 5
        while boolPrinting and crane1Counter > 0 do
            reset(StackAPick,0)
            WTurn(Crane1, y_axis, math.rad(0), 2)
            Show(StackAPick)
            Hide(Container[crane1Counter])
            WMove(StackAPick, y_axis, 10, 10)
            WTurn(Crane1, y_axis, math.rad(175), 2)
            WMove(StackAPick, y_axis, -35, 10)
            Sleep(7000)
            WMove(StackAPick, y_axis, 0, 30)
            WTurn(Crane1, y_axis, math.rad(90), 5)

            Sleep(100)
            crane1Counter= crane1Counter - 1
            for k=0, -2000, -100 do
                WMove(StackAPick, y_axis, k, math.abs(k))             
            end
            Hide(StackAPick)
        end
    end
    CraneAnimationsRunning[1]= false
end

sliceSize= 6
craneSpeed = 0.5
function crane2Animation()
    CraneAnimationsRunning[2]= true
    Crane = piece("Crane2")
    CraneC = piece("Crane3")
    StackBPick = TablesOfPiecesGroups["StackBPick"]
    ContainerC = TablesOfPiecesGroups["StackC"]
    ContainerB = TablesOfPiecesGroups["StackB"]
    ContainerMover = TablesOfPiecesGroups["StackBPick"][1]
    StackCPick = TablesOfPiecesGroups["StackCPick"]
    elevator = piece("ElevatorB")
    hideT(StackBPick)
    hideT(StackCPick)
    while true do
        WMove(elevator, y_axis, -10, 0.5)
        showT(Container)
        WMove(elevator, y_axis, 0, 0.5)
        Sleep(5000)
        craneCounter = 4
        while boolPrinting and craneCounter > 0 do
            StackPick= nil
            StackPlace= nil
            boolCombContainer = maRa()
            if boolCombContainer then
                StackPick = TablesOfPiecesGroups["StackB"][craneCounter]
                StackPlace = TablesOfPiecesGroups["RailContainerPlace"][1])
            else
                StackPick = TablesOfPiecesGroups["StackC"][craneCounter]
                StackPlace = TablesOfPiecesGroups["RailContainerPlace"][2]
            end

            WMove(ContainerMover, x_axis, 0, 10)
            pickAndPlace(Crane, StackPick, ContainerMover, Container[craneCounter], StackPlace,
                         -35, -10, 0, 5,  0.5, false)
           
            installerGoal = (globalStep - math.ceil(totalNrOfSlices*0.3))* sliceSize
            WMove(ContainerMover, x_axis, installerGoal, 10)
            hideT(TablesOfPiecesGroups["RailContainerPlace"])
            WTurn(CraneC, y_axis, math.rad(0), 4)
            craneCPickUp(boolCombContainer, StackCPick, CraneC)
            WMove(StackPick, y_axis, 50, 0.5)
            Sleep(7000)

            craneCounter = craneCounter-1
            Hide(StackPick)
        end
    end
    CraneAnimationsRunning[2] = false
end



function craneCPickUp(boolCombContainer, StackCPick, Crane )
    center = StackCPick[1]
    Turn(center, x_axis, math.rad(-90),0)
    if boolCombContainer then
        Show(StackCPick[1])
    else
        Show(StackCPick[2])
    end
    Move(center, y_axis, 150, 10)
    WTurn(center, x_axis, math.rad(0),0.5)
    WTurn(Crane, y_axis, math.rad(181), 1)
    Sleep(3000)
    hideT(StackCPick)
    Turn(Crane, y_axis, math.rad(0), 2)
end