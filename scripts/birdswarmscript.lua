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
    Hide(center)
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
    Spring.PlaySoundFile("sounds/animals/birdsFleeing.ogg")
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
fleeX, fleeZ = getNormalizedRandomVector(), getNormalizedRandomVector()
proOwnerId= nil
boolShotsFired = false
function setShotNearby(args)
    boolShotsFired = true
    shotNearby = shotNearby + args.value
    mx,my,mz = Spring.GetUnitPosition(unitID)
    fleeX, fleeZ = mx - args.x or 0, mz - args.z or 0
    norm = math.max(math.abs(fleeX), math.abs(fleeZ))
    fleeX = fleeX/norm
    fleeZ = fleeZ/norm
    if args.proOwnerID and doesUnitExistAlive(args.proOwnerId) then
        proOwnerId = args.proOwnerID
        Spring.AddUnitImpulse(unitID, 0, 0.1, 0)
        Command(proOwnerId, "guard")
    end
end


function moveControl()
    factor = 1.0
    Sleep(150)
    Spring.MoveCtrl.Enable(unitID,true) 
    minFleightHeight = 256
    x,y,z=Spring.GetUnitPosition(unitID)
    groundHeight = Spring.GetGroundHeight(x,z)
    riseFactor = 0
    rate = 1.0 /  (5*1000/30)
    while not boolShotsFired do
         Spring.MoveCtrl.SetPosition(unitID
            ,x + fleeX * factor
            ,groundHeight + mix( minFleightHeight + math.random(0,1)/100, 0, riseFactor)
            ,z + fleeZ * factor)
         Sleep(33)
         x,y,z=Spring.GetUnitPosition(unitID)
         groundHeight = Spring.GetGroundHeight(x,z)
         minFleightHeight = minFleightHeight + math.random(0,1)/100
         riseFactor = math.min(1.0, riseFactor + 0.006)
    end
     Spring.MoveCtrl.Disable(unitID) 
end
    

function script.Killed(recentDamage, maxHealth)
end