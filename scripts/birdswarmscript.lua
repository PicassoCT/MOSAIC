include "lib_UnitScript.lua"

center= piece"center"


TablesOfPiecesGroups = {}
--> returns a randomized Signum


visiblePieces= {}
spinAxis = y_axis
buildingHeigth = 200
function script.Create()
    TablesOfPiecesGroups = getPieceTableByNameGroups(false, true)
    --Spin(center,spinAxis,math.rad(42),0)
    Move(center,y_axis, buildingHeigth,0)

    boolIsGull = UnitDefs[unitDefID].name == "gullswarm"
    StartThread(moveControl)    
    hideT(TablesOfPiecesGroups["Gull"])
    boolAtLeastOne = true
    if boolIsGull then
        for k,v in pairs(TablesOfPiecesGroups["Gull"]) do
            Spin(v, spinAxis, math.rad(42)* (-1)^(k+1))
            if boolAtLeastOne or math.random(0,1)== 1 then
                visiblePieces[#visiblePieces +1] = v
                Show(v)
                boolAtLeastOne = false
            end
        end
        else
        for k,v in pairs(TablesOfPiecesGroups["Gull"]) do
            Spin(v, spinAxis, math.rad(42)* (-1)^(k+1))
            if boolAtLeastOne or math.random(0,1)== 1 then
                visiblePieces[#visiblePieces +1] = v
                Show(v)
                boolAtLeastOne = false
            end
        end
    end
    Spring.SetUnitAlwaysVisible(unitID, true)
    Spring.SetUnitNoSelect(unitID,true)
    StartThread(lifeTime, unitID, 30000, true, false)
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
    upValue= 0
    while true do
     Spring.MoveCtrl.SetPosition(unitID, x +timeBasedOffset()*xsignum, y+ upValue ,z +timeBasedOffset()*zsignum)
     upValue = math.min(100, upValue +0.1)
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





function script.Killed(recentDamage, maxHealth)
    
end