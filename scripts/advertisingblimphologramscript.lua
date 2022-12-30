include "createCorpse.lua"
include "lib_OS.lua"
include "lib_UnitScript.lua"
include "lib_Animation.lua"
include "lib_mosaic.lua"

TablesOfPiecesGroups = {}
myDefID = Spring.GetUnitDefID(unitID)
gaiaTeamID = Spring.GetGaiaTeamID()
BrothelSpin= piece("BrothelSpin")
CasinoSpin= piece("CasinoSpin")
Joy = piece("Joy")
JoyRide = piece("JoyRide")
local boolDebugScript = true

offset = 80

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

function showOneOrNone(T)
    if not T then return end
    if math.random(1, 100) > 50 then
        return showOne(T, true)
    else
        return
    end
end



function script.Create()
    --echo(UnitDefs[myDefID].name.."has placeholder script called")
    Spring.SetUnitAlwaysVisible(unitID, true)
    Spring.SetUnitNoSelect(unitID, true)
    Spring.SetUnitBlocking(unitID, false)
     TablesOfPiecesGroups = getPieceTableByNameGroups(false, true)
     StartThread(HoloGrams)
     Hide(BrothelSpin)
     Hide(CasinoSpin)

end

function HoloGrams()    
    local brothelFlickerGroup = TablesOfPiecesGroups["BrothelFlicker"]
    local CasinoflickerGroup = TablesOfPiecesGroups["CasinoFlicker"]
    local JoyFlickerGroup = {}

    JoyFlickerGroup[#JoyFlickerGroup+1] = Joy
    JoyFlickerGroup[#JoyFlickerGroup+1] = JoyRide
    hideT(brothelFlickerGroup)
    hideT(CasinoflickerGroup)
    hideT(JoyFlickerGroup)
    hideT(TablesOfPiecesGroups["JoySpin"])

    Sleep(15000)
    --sexxxy time
    px,py,pz = Spring.GetUnitPosition(unitID)
    if maRa() then
        StartThread(flickerScript, brothelFlickerGroup, 5, 250, 4, true)
    else
        StartThread(flickerScript, JoyFlickerGroup, 5, 250, 4, true)
        StartThread(JoyAnimation)
    end
    val = math.random(5, 12)*randSign()
    Move(BrothelSpin, z_axis, -offset,0)
    Spin(BrothelSpin, z_axis, math.rad(val), 0.1)
    StartThread(flickerScript, CasinoflickerGroup, 5, 250, 4, true)
    val = math.random(5, 12)*randSign()
    Move(CasinoSpin, z_axis, -offset,0)
    Spin(CasinoSpin, z_axis,  math.rad(val), 0.1)
end



function JoyAnimation()
    offsetValue = -70
    turnVal= -17
    animStepTime = 1000
    JoySpinOrigin = TablesOfPiecesGroups["JoySpin"][1]

    while true do

        hours, minutes, seconds, percent = getDayTime()
        if boolDebugScript or (hours > 17 or hours < 7) then
            Spin(JoySpinOrigin, z_axis, math.rad(17*3), 0)
            Show(JoySpinOrigin)
            Sleep(2000)

            scalar = 0.125*0.5*0.1
            for i=2, #TablesOfPiecesGroups["JoySpin"] do
                offset = i* offsetValue
                Show(TablesOfPiecesGroups["JoySpin"][i])
                rootDistance = i* 70 * 2
                Move(JoySpinOrigin, z_axis, rootDistance,speed(rootDistance, animStepTime*scalar))
                Move(TablesOfPiecesGroups["JoySpin"][i],z_axis, offsetValue, speed(offsetValue, animStepTime*scalar))
                Turn(TablesOfPiecesGroups["JoySpin"][i],z_axis, math.rad(turnVal), speed(turnVal, animStepTime))

                WaitForTurns(TablesOfPiecesGroups["JoySpin"][i])
                WaitForMoves(TablesOfPiecesGroups["JoySpin"][i])
            end
            WaitForMoves(JoySpinOrigin)
        end

        hideT(TablesOfPiecesGroups["JoySpin"])
        for i=1, #TablesOfPiecesGroups["JoySpin"] do
            reset(TablesOfPiecesGroups["JoySpin"][i],0)
        end
        StopSpin(JoySpinOrigin,z_axis,0)
        WaitForTurns(TablesOfPiecesGroups["JoySpin"])
        WaitForMoves(TablesOfPiecesGroups["JoySpin"])   
        DownDist = -70* #TablesOfPiecesGroups["JoySpin"] * 2
        WMove(JoySpinOrigin,z_axis, DownDist, 0)
        Sleep(10)
    end
end


function flickerScript(flickerGroup,  errorDrift, timeoutMs, maxInterval, boolDayLightSavings)
    assert(flickerGroup)
    local fGroup = flickerGroup

    flickerIntervall = math.ceil(1000/25)
    
    while true do
        hideT(fGroup)
        --assertRangeConsistency(fGroup, "flickerGroup")
        Sleep(500)
        hours, minutes, seconds, percent = getDayTime()
        if boolDebugScript or (hours > 17 or hours < 7) then
            theOneToShowT= {}
            for x=1,math.random(1,3) do
                theOneToShowT[#theOneToShowT+1] = fGroup[math.random(1,#fGroup)]
            end

            for i=1,(3000/flickerIntervall) do
                if i % 2 == 0 then  showT(theOneToShowT) else hideT(theOneToShowT) end
                if maRa()==maRa() then showT(theOneToShowT) end 
                for ax=1,3 do
                    moveT(fGroup, ax, math.random(-1*errorDrift,errorDrift),100)
                end
                Sleep(flickerIntervall)
            end
            hideT(theOneToShowT)
        end
        breakTime = math.random(1,maxInterval)*timeoutMs
        Sleep(breakTime)
    end
end


function script.Activate() return 1 end

function script.Deactivate() return 0 end

