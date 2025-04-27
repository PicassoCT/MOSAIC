include "createCorpse.lua"
include "lib_OS.lua"
include "lib_UnitScript.lua"
include "lib_Animation.lua"
--include "lib_Build.lua"

local TablesOfPiecesGroups = {}

function script.HitByWeapon(x, z, weaponDefID, damage) end

cegToTestName = {"depressol","tollwutox","orgyanyl","wanderlost"}
seconds = 3

function script.Create()
    echo("cegtest unit deployed: Running ceg:"..toString(cegToTestName).." every n seconds:"..seconds)
    x,y,z = Spring.GetUnitPosition(unitID)
    echo("{name = \"placeholder\", x = "..x..", z = "..z..", rot = 0, scale = 1.000000}")
    hideAll(unitID)
    TablesOfPiecesGroups = getPieceTableByNameGroups(false, true)
    StartThread(CegTest)
 end

 function CegTest()
    while true do
        for i=1, #cegToTestName do
            Sleep(seconds * 1000)
            spawnCegAtUnit(unitID, cegToTestName[i], 0, 25,  0)
        end
        echo("cegtest:Execute")
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

-- function script.QueryBuildInfo()
-- return center
-- end

-- Spring.SetUnitNanoPieces(unitID, { center })

