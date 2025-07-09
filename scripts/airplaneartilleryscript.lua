include "createCorpse.lua"
include "lib_OS.lua"
include "lib_UnitScript.lua"
include "lib_Animation.lua"

TablesOfPiecesGroups = {}

function script.HitByWeapon(x, z, weaponDefID, damage) end


function script.Create()
    -- generatepiecesTableAndArrayCode(unitID)
    TablesOfPiecesGroups = getPieceTableByNameGroups(false, true)
    StartThread(revealUnfold)
end


Cartdrige = piece("Cartdrige")
Base = piece("Base")
Eye = piece("Eye")
Tail = piece("Tail")
Wing1 = piece("Wing1")
Wing2 = piece("Wing2")
Wing1Sub1 = piece("Wing1Sub1")
Wing2Sub1 = piece("Wing2Sub1")

function moveOnUp()
    Spring.MoveCtrl.Enable(unitID)
    x,y,z = Spring.GetUnitPosition(unitID)
    moveT(TablesOfPiecesGroups["Sabot"],y_axis, -1000, 200)
    spinRand(TablesOfPiecesGroups["Sabot"][1], 15, 50)
    spinRand(TablesOfPiecesGroups["Sabot"][2], 15, 50)
    speed =250
    for i=1, 2048, speed do
        Spring.MoveCtrl.SetPosition(unitID, x, y+i, z)
        if i > 1700 then
            speed = math.max(50, speed*0.97)
        end
        Sleep(33)
    end
    hideT(TablesOfPiecesGroups["Sabot"])
    Spring.MoveCtrl.Disable(unitID)
end

function revealUnfold()
    hideAll(unitID)
    setUnitNeverLand(unitID)
    showT(TablesOfPiecesGroups["Sabot"])
    Show(Cartdrige)
    waitTillComplete(unitID)
    moveOnUp()

    Sleep(500)
    Hide(Cartdrige)

    showT(TablesOfPiecesGroups["TailRotor"])
    Show(Base)
    Show(Eye)
    Turn(Tail, y_axis, math.rad(90), 15)
    Show(Tail)
    showT(TablesOfPiecesGroups["Wing"])
    Move(Wing1Sub1, y_axis, 326, 0)
    Move(Wing2Sub1, y_axis, 326, 0)
    Turn(Base, x_axis, math.rad(90), 15)
    Turn(Base, z_axis, math.rad(90), 15)
    Turn(Wing1, x_axis, math.rad(-80), 15)
    Turn(Wing2, x_axis, math.rad(80), 15)
    Show(Wing1Sub1)
    Show(Wing2Sub1)
    reset(Wing1Sub1,100)
    reset(Wing2Sub1,100)
    spinT(TablesOfPiecesGroups["TailRotor"], y_axis, math.rad(42))
end

function script.Killed(recentDamage, _)
    return 1
end



function script.StartMoving() end

function script.StopMoving() end

function script.Activate() return 1 end

function script.Deactivate() return 0 end


--- -aimining & fire weapon
function script.AimFromWeapon1() 
    return Base 
end

function script.QueryWeapon1() 
    return Base 
end
local spGetGameFrame = Spring.GetGameFrame
local spGetUnitWeaponTarget = Spring.GetUnitWeaponTarget
local spGetUnitPosition = Spring.GetUnitPosition
lastFrame = spGetGameFrame()
function script.AimWeapon1(Heading, pitch)
    if spGetGameFrame() - lastFrame > 10 then
        lastFrame = spGetGameFrame()
        x,y,z = spGetUnitPosition(unitID)
        coordinates = {}
       targetType, isUserTarget, values = spGetUnitWeaponTarget(  unitID,  1 )
       if targetType and targetType ~= 3 then
            if targetType  == 1 then
                coordinates[1], _, coordinates[3] = Spring.GetUnitPosition(values)
            else
                coordinates = values
            end

            if distance(x,0, z, coordinates[1], 0, coordinates[3]) < 25 then
                   return true
            end            
        end
    end
    return false
end

function script.FireWeapon1()
    resetT(TablesOfPiecesGroups["Wing"],180)
    WaitForTurns(TablesOfPiecesGroups["Wing"])
    Spring.DestroyUnit(unitID, true, false)
    return true
end