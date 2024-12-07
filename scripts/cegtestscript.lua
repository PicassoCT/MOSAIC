include "createCorpse.lua"
include "lib_OS.lua"
include "lib_UnitScript.lua"
include "lib_Animation.lua"
--include "lib_Build.lua"

local TablesOfPiecesGroups = {}
myDefID = Spring.GetUnitDefID(unitID)
function script.HitByWeapon(x, z, weaponDefID, damage) end

cegToTestName = "nuclearexplosionbig"
seconds = 3

function script.Create()
    echo("cegtest unit deployed: Running ceg:"..cegToTestName.." every n seconds:"..seconds)
    x,y,z = Spring.GetUnitPosition(unitID)
    echo("{name = \"placeholder\", x = "..x..", z = "..z..", rot = 0, scale = 1.000000}")
    hideAll(unitID)
    TablesOfPiecesGroups = getPieceTableByNameGroups(false, true)
    StartThread(CegTest)
 end

 function CegTest()
    while true do
        Sleep(seconds * 1000)
        spawnCegAtUnit(unitID, cegToTestName, 0, 25,  0)
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

