include "lib_radiance_emitters.lua"

local facades = piece("facades")

function script.Create()
    Spring.SetUnitAlwaysVisible(unitID, true)
    -- Reuse the authored atlas illumination mask, never the normal map or the
    -- whole diffuse image. Static buildings require no polling/animation thread.
    SetRadiancePiece(facades, true, "material")
end

function script.Killed()
    SetRadiancePiece(facades, false)
    -- game_objective owns destruction markers, rewards and restoration.
    return 0
end
