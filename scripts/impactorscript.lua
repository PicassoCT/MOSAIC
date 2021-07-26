include "lib_OS.lua"
include "lib_UnitScript.lua"
include "lib_Animation.lua"
--include "lib_Build.lua"

local spiralCenter = piece "spiralCenter"
local fireSpiral1 = piece "fireSpiral1"
local fireSpiral2 = piece "fireSpiral2"
local fireSpiral3 = piece "fireSpiral3"
local shockwaveemit = piece "shockwaveEmit"
local shockwavecenter = piece "shockwavecenter"
local fireFx1 = piece "fireFx1"
local fireFx2 = piece "fireFx2"
local fireFx3 = piece "fireFx3"
local exploEmit = piece "exploEmit"
local centcolumnFxEmit1 = piece "centcolumnFxEmit1"
local centcolumnFxEmit2 = piece "centcolumnFxEmit2"
local centcolumnFxEmit3 = piece "centcolumnFxEmit3"

--local ffrotator=piece"ffrotator"
--local centerFireFx = piece "centerFireFx"
local center = piece "center"
local groupcenter = piece "groupcenter"
local ringRotator = piece "ringRotator"
local ringEmit1 = piece "ringEmit1"
local ringEmit2 = piece "ringEmit2"
local ringEmit3 = piece "ringEmit3"
local ringEmit4 = piece "ringEmit4"

ringCenter = piece "ringCenter"
suckINemit2 = piece "suckINemit2"
gdEmit = piece "gdEmit"
SIG_DIRT = 2
explosionTotalTime = 9000



function shockwave()
    x, y, z = Spring.GetUnitPosition(unitID)
    Spring.SpawnCEG("jsunwave", x, y + 10, z, 0, 1, 0, 60)
    local splEmitSfx = EmitSfx
    for i = 1, 12, 1 do
        splEmitSfx(spiralCenter, 1025)
        splEmitSfx(spiralCenter, 1025)
        splEmitSfx(spiralCenter, 1025)
        splEmitSfx(spiralCenter, 1025)
        Time = i * 10
        Sleep(Time)
    end
end


function haveSoundArround()

    Spring.PlaySoundFile("sounds/weapons/godrod/nuke.ogg", 1)
    Sleep(3500)
    Spring.PlaySoundFile("sounds/weapons/godrod/nukular.wav", 1)
end


function script.Killed(recentDamage, maxHealth)
    return 1
end




function threadMill()
        StartThread(shockwave)
        x, y, z = Spring.GetUnitPosition(unitID)
        Spring.SpawnCEG("nukebigland", x, y + 15, z, math.random(-1, 1), math.random(0.1, 1), math.random(-1, 1), 60)
        haveSoundArround()
        Spring.DestroyUnit(unitID, false, true)
end

function script.Create()
    Spring.SetUnitNeutral(unitID, true)
    Spring.SetUnitNoSelect(unitID, true)

    Hide(spiralCenter)
    Hide(fireSpiral1)
    Hide(fireSpiral2)
    Hide(shockwaveemit)
    Hide(shockwavecenter)
    Hide(fireFx1)
    Hide(fireFx2)
    Hide(fireFx3)

    Hide(center)
    Hide(groupcenter)
    Hide(ringRotator)
    Hide(ringEmit1)
    Hide(ringEmit2)
    Hide(ringEmit3)
    Hide(ringEmit4)
    StartThread(threadMill)
    spawnCegNearUnitGround(unitID,"pressurewave" )
end