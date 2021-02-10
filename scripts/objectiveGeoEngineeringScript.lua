include "createCorpse.lua"
include "lib_OS.lua"
include "lib_UnitScript.lua"
include "lib_Animation.lua"
include "lib_Build.lua"

TablesOfPiecesGroups = {}

function script.HitByWeapon(x, z, weaponDefID, damage) end
tether = piece "Object002"
blimp = piece "Capsule021"

function script.Create()
    TablesOfPiecesGroups = getPieceTableByNameGroups(false, true)
    StartThread(blinkLights)
    StartThread(turnWindSlow)
end
function turnWindSlow()
    while true do
        dx, dy, dz = Spring.GetWind()
        headRad = math.atan2(dx, dz)
        Turn(tether, y_axis, headRad + math.pi, 0.01)
        Turn(blimp, y_axis, -(headRad + math.pi), 0.01)
        Turn(blimp, x_axis, math.rad(-2 * randSign()), 0.01)
        Turn(blimp, z_axis, math.rad(-2 * randSign()), 0.01)
        WaitForTurns(tether, blimp)
        Sleep(100)
    end

end
function blinkLights()
    n = 1
    while true do
        n = n + 1 % 2
        for i = 1, #TablesOfPiecesGroups["BlinkyLight"], 1 do
            if i % 2 == 0 then
                Turn(TablesOfPiecesGroups["BlinkyLight"][i], z_axis,
                     math.rad(180 * n), 0)
            else
                Turn(TablesOfPiecesGroups["BlinkyLight"][i], z_axis,
                     math.rad(180 * (n + 1)), 0)
            end
        end
        Sleep(2500)
    end
end

function script.Killed(recentDamage, _) return 1 end

