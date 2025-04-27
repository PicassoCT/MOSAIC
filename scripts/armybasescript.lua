include "createCorpse.lua"
include "lib_OS.lua"
include "lib_UnitScript.lua"
include "lib_Animation.lua"
--include "lib_Build.lua"

local TablesOfPiecesGroups = {}


function script.HitByWeapon(x, z, weaponDefID, damage) end
SIG_BLINK = 2

function script.Create()
    --echo(UnitDefs[unitDefID].name.."has placeholder script called")
    -- generatepiecesTableAndArrayCode(unitID)
    TablesOfPiecesGroups = getPieceTableByNameGroups(false, true)
    x,y,z = Spring.GetUnitPosition(unitID)
    --echo("{name = \"placeholder\", x = "..x..", z = "..z..", rot = 0, scale = 1.000000}")
    StartThread(blinkLights)
end
BLINK_PASSIVE = 2000
BLINK_ACTIVE = 1250
blinkTime= 2000

function blinkLights()
    Signal(SIG_BLINK)
    SetSignalMask(SIG_BLINK)
    while true do
        showT(TablesOfPiecesGroups["lightsOn"])
        hideT(TablesOfPiecesGroups["lightsOff"])
        Sleep(blinkTime)
        hideT(TablesOfPiecesGroups["lightsOn"])
        showT(TablesOfPiecesGroups["lightsOff"])
        Sleep(blinkTime)
    end
end

function script.Killed(recentDamage, _)

    -- createCorpseCUnitGeneric(recentDamage)
    return 1
end



function script.StartMoving() end

function script.StopMoving() end

function script.Activate() return 1 end

function script.Deactivate() return 0 end

function script.StartBuilding() blinkTime = BLINK_ACTIVE; SetUnitValue(COB.INBUILDSTANCE, 1) end

function script.StopBuilding() blinkTime = BLINK_PASSIVE SetUnitValue(COB.INBUILDSTANCE, 0) end


