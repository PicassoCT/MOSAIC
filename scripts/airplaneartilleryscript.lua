include "createCorpse.lua"
include "lib_OS.lua"
include "lib_UnitScript.lua"
include "lib_Animation.lua"

TablesOfPiecesGroups = {}
myDefID = Spring.GetUnitDefID(unitID)
function script.HitByWeapon(x, z, weaponDefID, damage) end


function script.Create()
    echo(UnitDefs[myDefID].name.."has placeholder script called")
    -- generatepiecesTableAndArrayCode(unitID)
    TablesOfPiecesGroups = getPieceTableByNameGroups(false, true)
    StartThread(revealUnfold)
end

Projectile = piece("Projectile")
Cartdrige = piece("Cartdrige")
Base = piece("Base")
Eye = piece("Eye")
Tail = piece("Tail")
Wing1 = piece("Wing1")
Wing2 = piece("Wing2")
Wing1Sub1 = piece("Wing1Sub1")
Wing2Sub1 = piece("Wing2Sub1")

function revealUnfold()
    hideAll(unitID)
    showT(TablesOfPiecesGroups["Sabot"])
    Show(Cartdrige)
    waitTillComplete(unitID)
    Sleep(100)
    Hide(Cartdrige)
    hideT(TablesOfPiecesGroups["Sabot"])
    explodeT(TablesOfPiecesGroups["Sabot"])
    showT(TablesOfPiecesGroups["TailRotor"])
    Show(Base)
    Show(Eye)
    Turn(Tail, y_axis, math.rad(90), 15)
    Show(Tail)
    Show(Wing1)
    Show(Wing2)
    showT(TablesOfPiecesGroups["Wing"])
    Move(Wing1Sub1, y_axis, 50, 0)
    Move(Wing2Sub1, y_axis, 50, 0)
    Turn(Base, x_axis, math.rad(90), 15)
    Turn(Wing1, z_axis, math.rad(90), 15)
    Turn(Wing2, z_axis, math.rad(-90), 15)
    Show(Wing1Sub1)
    Show(Wing2Sub1)
    reset(Wing1Sub1,15)
    reset(Wing2Sub1,15)
    spinT(TablesOfPiecesGroups["TailRotor"], y_axis, math.rad(42))
end

function script.Killed(recentDamage, _)

    -- createCorpseCUnitGeneric(recentDamage)
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


function script.AimWeapon1(Heading, pitch)
    resetT(TablesOfPiecesGroups["Wing"],45)
    WaitForTurns(TablesOfPiecesGroups["Wing"])
    return true
end

function script.FireWeapon1()
    Spring.DestroyUnit(unitID, true, false)
    return true
end