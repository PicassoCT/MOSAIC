-- The impact unit retains the original sound/lifetime role. The world-space
-- cloud continues cooling after this helper is removed.
include "lib_OS.lua"
include "lib_UnitScript.lua"
include "lib_Animation.lua"

local function impact()
    local x,y,z=Spring.GetUnitPosition(unitID)
    if GG.CloudVolume and x then GG.CloudVolume.Burst('impact',x,y,z) end
    Spring.PlaySoundFile("sounds/weapons/godrod/nuke.ogg",1)
    Sleep(3500)
    Spring.PlaySoundFile("sounds/weapons/godrod/nukular.wav",1)
    Spring.DestroyUnit(unitID,false,true)
end
function script.Create()
    Spring.SetUnitNeutral(unitID,true)
    Spring.SetUnitNoSelect(unitID,true)
    Spring.SetUnitNoDraw(unitID,true)
    StartThread(impact)
end
function script.Killed() return 1 end
