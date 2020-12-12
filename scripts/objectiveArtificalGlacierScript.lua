include "createCorpse.lua"
include "lib_OS.lua"
include "lib_UnitScript.lua"
include "lib_Animation.lua"
include "lib_Build.lua"

TablesOfPiecesGroups = {}

function script.HitByWeapon(x, z, weaponDefID, damage)
end

-- center = piece "center"
-- left = piece "left"
-- right = piece "right"
-- aimpiece = piece "aimpiece"
if not aimpiece then echo("Unit of type "..UnitDefs[Spring.GetUnitDefID(unitID)].name .. " has no aimpiece") end
if not center then echo("Unit of type"..UnitDefs[Spring.GetUnitDefID(unitID)].name .. " has no center") end

function script.Create()
    -- generatepiecesTableAndArrayCode(unitID)
    TablesOfPiecesGroups = getPieceTableByNameGroups(false, true)

    	resetAll(unitID)
    	WTurn(TablesOfPiecesGroups["Solar"][4],x_axis,math.rad(-181),1)
    	WTurn(TablesOfPiecesGroups["Solar"][4],x_axis,math.rad(-120),1)
    	WTurn(TablesOfPiecesGroups["Solar"][3],x_axis,math.rad(181),1)
    	WTurn(TablesOfPiecesGroups["Solar"][3],x_axis,math.rad(145),1)
    	WTurn(TablesOfPiecesGroups["Solar"][2],z_axis,math.rad(-189),1)
    	WTurn(TablesOfPiecesGroups["Solar"][2],z_axis,math.rad(-145),1)

    	WTurn(TablesOfPiecesGroups["Solar"][1],z_axis,math.rad(181),1)
    	WTurn(TablesOfPiecesGroups["Solar"][1],z_axis,math.rad(270),1)
  
end


function script.Killed(recentDamage, _)

    --createCorpseCUnitGeneric(recentDamage)
    return 1
end


function script.StartMoving()
end

function script.StopMoving()
end

function script.Activate()

    return 1
end

function script.Deactivate()

    return 0
end

-- function script.QueryBuildInfo()
    -- return center
-- end

-- Spring.SetUnitNanoPieces(unitID, { center })

