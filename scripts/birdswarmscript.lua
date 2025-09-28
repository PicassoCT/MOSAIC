include "lib_UnitScript.lua"
include "lib_OS.lua"

center= piece"center"


TablesOfPiecesGroups = {}
--> returns a randomized Signum


visiblePieces= {}
spinAxis = y_axis
buildingHeigth = 200
function script.Create()
    TablesOfPiecesGroups = getPieceTableByNameGroups(false, true)
    --Spin(center,spinAxis,math.rad(42),0)
    Move(center,spinAxis, buildingHeigth,0)

    boolIsGull = UnitDefs[unitDefID].name == "gullswarm"
    StartThread(moveControl)    
    hideT(TablesOfPiecesGroups["Gull"])
    hideT(TablesOfPiecesGroups["Raven"])
    name = "Gull"
    if boolIsGull == false then  name = "Raven" end
    boolAtLeastOne = true

    for k,v in pairs(TablesOfPiecesGroups[name]) do
        Spin(v, spinAxis, math.rad(22)* (-1)^(k))
        if boolAtLeastOne or math.random(0,1)== 1 then
            visiblePieces[#visiblePieces +1] = v
            Show(v)
            boolAtLeastOne = false
        end
    end
   
    Spring.SetUnitAlwaysVisible(unitID, true)
    Spring.SetUnitNoSelect(unitID,true)
    StartThread(iterrativeLifeTime, unitID, true, false)
end

function iterrativeLifeTime(unitID,  boolReclaimed, boolSelfdestroyed, finalizeFunction)
    boolReclaimed, boolSelfdestroyed = boolReclaimed or false, boolSelfdestroyed or false
    while shotNearby > 0 do
        Sleep(1000)
        shotNearby = shotNearby -1000
    end
    if finalizeFunction then finalizeFunction() end
    Spring.DestroyUnit(unitID, boolReclaimed, boolSelfdestroyed)
end

shotNearby= 30000
fleeX, fleeZ = 0,0
function setShotNearby(args)
    shotNearby = shotNearby + args.value
    mx,my,mz = Spring.GetUnitPosition(unitID)
    fleeX, fleeZ = mx - args.x or 0, mz - args.z or 0
    norm = math.max(math.abs(fleeX), math.abs(fleeZ))
    fleeX = fleeX/norm
    fleeZ = fleeZ/norm
end

function timeBasedOffset()
    return math.sin((((Spring.GetGameFrame() % 15000)/15000)*2*math.pi) -math.pi) * 500
end

function moveControl()
    factor = 3.0
    Spring.MoveCtrl.Enable(unitID,true)
    xsignum= randSign()
    zsignum= randSign()
    x,y,z=Spring.GetUnitPosition(unitID)
    upValue= 0
    while true do
         Spring.MoveCtrl.SetPosition(unitID
            ,x + timeBasedOffset()*xsignum + fleeX * factor, y+ upValue 
            ,z +timeBasedOffset()*zsignum + fleeZ * factor)
         upValue = math.min(100, upValue +0.1)
         Sleep(100)
    end
end
    

function script.Killed(recentDamage, maxHealth)
end