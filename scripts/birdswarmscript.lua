--most simple unit script
--allows the unit to be created & killed
include "lib_caeserea.lua"

center= piece"center"
eagle= piece"eagle"
eaglePiece= nil
TablesOfPiecesGroups = {}
--> returns a randomized Signum
function randSign()
    if math.random(0, 1) == 1 then return 1 else return -1 end
end
visiblePieces= {}
function script.Create()
TablesOfPiecesGroups = makePiecesTablesByNameGroups(false, true)
    Turn(center, 2, math.rad(unitID*math.pi))
    Spin(center,2,math.rad(42),0)
    Move(center,2,150,0)
    StartThread(circleAltering) 
    StartThread(moveControl)    
    hideT(TablesOfPiecesGroups["Gull"])
    boolAtLeastOne = true
    for k,v in pairs(TablesOfPiecesGroups["Gull"]) do
        Spin(v, y_axis, math.rad(42)* (-1)^k)
        if boolAtLeastOne or math.random(0,1)== 1 then
            visiblePieces[#visiblePieces +1] = v
            Show(v)
            boolAtLeastOne = false
        end
    end

    Spring.SetUnitNoSelect(unitID,true)
end

shotNearby= 0
function setShotNearby(value)
    shotNearby = shotNearby + value
end

function timeBasedOffset()
return math.sin((((Spring.GetGameFrame() % 15000)/15000)*2*math.pi) -math.pi) * 500
end

function moveControl()
Spring.MoveCtrl.Enable(unitID,true)
xsignum= randSign()
zsignum= randSign()
x,y,z=Spring.GetUnitPosition(unitID)
    while true do
     Spring.MoveCtrl.SetPosition(unitID, x +timeBasedOffset()*xsignum, y+ 100 ,z +timeBasedOffset()*zsignum)
    Sleep(100)
    end

end
    
local function getDayTime(frame)
    local DAYLENGTH = 28800
    local morningOffset = (DAYLENGTH / 2)
    local Frame = (frame + morningOffset) % DAYLENGTH
    local percent = Frame / DAYLENGTH
    local hours = math.floor((Frame / DAYLENGTH) * 24)
    local minutes = math.ceil((((Frame / DAYLENGTH) * 24) - hours) * 60)
    local seconds = 60 - ((24 * 60 * 60 - (hours * 60 * 60) - (minutes * 60)) % 60)
    return hours, minutes, seconds, percent 
end

--TODO: Add looking out for the sound of shots

local function isMorningOrEvening(frame)
    local hours, _, _, percent = getDayTime(frame)         
    return (hours > 17 and hours < 20) or (hours > 5 and hours < 8), percent
end

function circleAltering()
    value=150
    sign= -1
    while true do
        rand= math.random(25,100)
        value=value+ sign
        Move(center,2,value,1)
        if value < 150 or value > 400 then sign= sign *-1 end
        Move(eagle,x_axis,rand,3)
        Sleep(50000)
        if isMorningOrEvening(Spring.GetGameFrame()) or shotNearby > 0 then
            for k,v in pairs(visiblePieces) do
                Show(v)
            end
            while (isMorningOrEvening(Spring.GetGameFrame())) or shotNearby >0  do
                Sleep(5000)
                shotNearby = shotNearby-5000
            end
            for k,v in pairs(visiblePieces) do
             Hide(v)
            end
        end
    end
end

function script.Killed(recentDamage, maxHealth)
    
end