include "createCorpse.lua"
include "lib_OS.lua"
include "lib_UnitScript.lua"
include "lib_Animation.lua"

local TablesOfPiecesGroups = {}
local SIG_SUBANIMATIONS = 2
local Industrial_Floor1 = piece("Industrial_Floor1")

function script.HitByWeapon(x, z, weaponDefID, damage) end

oilrigAnimationT = 
    {   func="func", 
        arg= {
                method = oilrigAnimation, 
                jack1 =  piece("Industrial_Floor1Sub1"),
                jack2 = piece("Industrial_Floor1Sub5"),
                piston1 =  piece("Industrial_Floor1Sub2"),
                piston2 = piece("Industrial_Floor1Sub6"),
                swing1 =  piece("Industrial_Floor1Sub3"),
                swing2 =  piece("Industrial_Floor1Sub7"),
                crank1 =  piece("Industrial_Floor1Sub4"),
                crank2 =  piece("Industrial_Floor1Sub8")                       
            }
    }

function script.Create()
    TablesOfPiecesGroups = getPieceTableByNameGroups(false, true)
    StartThread(oilrigAnimation, oilrigAnimationT.arg)  
    StartThread(drillAnimation)
end

function oilrigAnimation(set)  
    SetSignalMask(SIG_SUBANIMATIONS)
    jack1 = set.jack1 
    jack2 = set.jack2      
    piston1 = set.piston1  
    piston2 = set.piston2  
    swing1 = set.swing1    
    swing2 = set.swing2    
    crank1 = set.crank1    
    crank2 = set.crank2    
    Show(jack1)
    Show(jack2)
    Show(piston1)
    Show(piston2)
    Show(swing1)
    Show(swing2)
    Show(crank1)
    Show(crank2)
    Spin(swing1,z_axis, math.rad(360/4),0)
    Spin(crank1,z_axis, math.rad(-360/4),0)
    Spin(swing2,z_axis, math.rad(-360/4),0)
    Spin(crank2,z_axis, math.rad(360/4),0)
    while true do
        Turn(jack2, z_axis, math.rad(-28),math.rad(28)/2)
        Turn(jack1, z_axis, math.rad(28),math.rad(28)/2)
        Move(piston2,y_axis, 22, 5)    
        Move(piston1,y_axis, 22, 5)

        Sleep(2000)
        Turn(jack1, z_axis, math.rad(0),math.rad(28)/2)
        Turn(jack2, z_axis, math.rad(0),math.rad(28)/2)  
        Move(piston1,y_axis, 0, 5)      
        Move(piston2,y_axis, 0, 5)
        Sleep(2000)
    end
end


    ArmAxis = 3
    Slideaxis = z_axis
    function toPipeStorage(boolPick)
        if boolPick then
            Hide(TransportedPipe)
        else
            Show(TransportedPipe)
        end
        WMove(Slide, Slideaxis, -400, 128)
        Turn(RobotArm, ArmAxis, math.rad(150), 2.5)
        WTurn(Rotor, x_axis, math.rad(90),1.0)
        WTurn(RobotArm, ArmAxis, math.rad(179), 2.5)

        if boolPick then
            Move(TransportedPipe,y_axis, heightOfPipe, 0)
            Show(TransportedPipe)
            WMove(TransportedPipe,y_axis, 0, 50)            
        else
            WMove(TransportedPipe,y_axis, heightOfPipe, 50)
            Hide(TransportedPipe)
        end         
    end

    function clampPipes(index, T)
        return math.min(#T, math.max(index, 1))
    end


    HeadPipe= piece("Pipe1")

    heightOfPipe = 350
    function DrillMovement(boolDrillDown, index)
        reverseIndex = clampPipes(#TablesOfPiecesGroups["Pipe"] - index, TablesOfPiecesGroups["Pipe"])
        Spin(Drill, y_axis, math.rad(42), 0.1)
        if boolDrillDown then
            Show(TablesOfPiecesGroups["Pipe"][reverseIndex])    
            Move(Drill, y_axis, -heightOfPipe, 30)      
        else
            WMove(Drill, y_axis, 0, 0)
        end

        Move(HeadPipe, y_axis, -heightOfPipe*index, 30) 
      
        if boolDrillDown then    
            WMove(Drill, y_axis, -heightOfPipe, 30)
            Move(Drill, y_axis, 0, 30)      
        else
            WMove(Drill, y_axis, 0, 30)
            Hide(TablesOfPiecesGroups["Pipe"][index])
        end
    end


    function toDrill(boolPlace, index)
        if boolPlace then
            Show(TransportedPipe)
        else
            Hide(TransportedPipe)
        end
        WTurn(RobotArm, ArmAxis, math.rad(150), 2.5)
        Turn(Rotor, x_axis, math.rad(0),1.0)
        Move(Slide, Slideaxis, 0, 128)
        WTurn(RobotArm, ArmAxis, math.rad(0), 2.5)
        if boolPlace then
           
            Show(TablesOfPiecesGroups["Pipe"][index])
            Sleep(500)
            WMove(Slide, Slideaxis, -50, 128)
            Hide(TransportedPipe)
            WMove(Drill, y_axis, 0, 30)
            DrillMovement(boolPlace, index)
        else
            DrillMovement(boolPlace, index)
            Show(TransportedPipe)
            WMove(Slide, Slideaxis, -400, 128)           
        end
    end
    
    function drillDown(index)
        toPipeStorage(true)
        toDrill(true, index)
    end

    function retractDrill(index)
        toDrill(false, index)
        toPipeStorage(false)
    end

boolDrillDown = true
RobotArm = piece("RobotArm")
Rotor = piece("Rotor")
Crane = piece("Crane")
Slide = piece("Slide")
TransportedPipe = piece("TransportedPipe")
Drill = piece("Drill")
function drillAnimation()

    Show(RobotArm)
    Show(Drill)
    Show(Crane)
    Show(Slide)
    Hide(TransportedPipe)
    
    while true do  
        val = math.random(-90, 90)
        Turn(Crane, y_axis, math.rad(val), 0.05)
        hideT(TablesOfPiecesGroups["Pipe"])     
        if boolDrillDown == true then
            for i = #TablesOfPiecesGroups["Pipe"], 1, -1 do
                drillDown(i)
            end
        else
            showT(TablesOfPiecesGroups["Pipe"])
            for i =1, #TablesOfPiecesGroups["Pipe"] do
                retractDrill(i)                
            end
        end    
        boolDrillDown = not boolDrillDown
        Sleep(1000)
    end
end

function script.Killed(recentDamage, _)

    -- createCorpseCUnitGeneric(recentDamage)
    return 1
end



function script.StartMoving() end

function script.StopMoving() end

function script.Activate() return 1 end

function script.Deactivate() return 0 end

-- function script.QueryBuildInfo()
-- return center
-- end

-- Spring.SetUnitNanoPieces(unitID, { center })

