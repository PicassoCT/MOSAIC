include "createCorpse.lua"
include "lib_OS.lua"
include "lib_UnitScript.lua"
include "lib_Animation.lua"
--include "lib_Build.lua"

local TablesOfPiecesGroups = {}

function script.HitByWeapon(x, z, weaponDefID, damage) end

center = piece "center"
-- left = piece "left"
-- right = piece "right"
-- aimpiece = piece "aimpiece"
-- if not aimpiece then echo("Unit of type "..UnitDefs[Spring.GetUnitDefID(unitID)].name .. " has no aimpiece") end
if not center then
    echo("Unit of type" .. UnitDefs[Spring.GetUnitDefID(unitID)].name ..
             " has no center")
end
antline = {}

function script.Create()
    -- generatepiecesTableAndArrayCode(unitID)
    TablesOfPiecesGroups = getPieceTableByNameGroups(false, true)
    antline = TablesOfPiecesGroups["antline "]
    -- Spring.MoveCtrl.Enable(unitID,true)
    -- x,y,z =Spring.GetUnitPosition(unitID)
    -- Spring.MoveCtrl.SetPosition(unitID, x,y+500,z)
    StartThread(AnimationTest)
end
allDoneIndex = 0

function AnimationTest()
    Sleep(100)
    resetAll(unitID)
    hideT(antline)
    while true do
        randOffset = math.random(1, #antline)
        for index = 1, #antline do
            randPiece = ((index + randOffset) % #antline) + 1
            dist = math.random(75, 90)
            if antline[randPiece] then
                allDoneIndex = allDoneIndex + 1
                StartThread(queuedLineMove, antline[randPiece], index, dist,
                            dist / 5)
            end
        end
        while allDoneIndex > 0 do Sleep(100) end

    end

end

function queuedLineMove(piecename, nr, distance, speed)
    reset(piecename, 0)
    naptime = nr * (distance / speed) * 100
    Sleep(naptime)
    if maRa() == true then Show(piecename) end
    Move(piecename, z_axis, distance, speed)
    WMove(piecename, y_axis, -distance, speed)
    Hide(piecename)
    allDoneIndex = allDoneIndex - 1
end

function script.Killed(recentDamage, _)

    -- createCorpseCUnitGeneric(recentDamage)
    return 1
end

--- -aimining & fire weapon
-- function script.AimFromWeapon1()
-- return aimpiece
-- end

-- function script.QueryWeapon1()
-- return aimpiece
-- end

-- function script.AimWeapon1(Heading, pitch)
-- aiming animation: instantly turn the gun towards the enemy

-- return true
-- end

-- function script.FireWeapon1()

-- return true
-- end

function script.StartMoving() end

function script.StopMoving() end

function script.Activate() return 1 end

function script.Deactivate() return 0 end

-- function script.QueryBuildInfo()
-- return center
-- end

-- Spring.SetUnitNanoPieces(unitID, { center })

