-- gamedata/unit_script_header.lua already provides the animation API and axes.
-- There is no scripts/constants.lua in MOSAIC; do not log a spurious load error.

local base = piece("base")
local lowerarm = piece("lowerarm")
local upperarm = piece("upperarm")
local head = piece("head")
local bulb = piece("bulb")

local function signedStep(step, span)
    local width = span * 2 + 1
    return ((unitID * 97 + step * 53) % width) - span
end

local function settlePose()
    Turn(lowerarm, x_axis, math.rad(-11), math.rad(90))
    Turn(upperarm, x_axis, math.rad(18), math.rad(90))
    Turn(head, x_axis, math.rad(-12), math.rad(120))
end

local function hop()
    -- Compress, spring upward, then settle. This moves the whole articulated
    -- model without changing the unit's simulation position.
    Move(base, y_axis, -1.5, 24)
    Turn(lowerarm, x_axis, math.rad(-18), math.rad(130))
    Turn(upperarm, x_axis, math.rad(28), math.rad(130))
    Sleep(110)

    Move(base, y_axis, 9, 58)
    Turn(lowerarm, x_axis, math.rad(-5), math.rad(180))
    Turn(upperarm, x_axis, math.rad(10), math.rad(180))
    Sleep(185)

    Move(base, y_axis, 0, 46)
    settlePose()
    Sleep(260)
end

local function idle()
    local step = 0
    settlePose()
    while true do
        step = step + 1
        Turn(head, y_axis, math.rad(signedStep(step, 58)), math.rad(105))
        Turn(head, x_axis, math.rad(-12 + signedStep(step + 11, 14)), math.rad(75))
        Sleep(620 + ((unitID * 31 + step * 97) % 420))
        if step % 2 == 0 then
            hop()
        end
    end
end

function script.Create()
    StartThread(idle)
end

function script.HitByWeapon(x, z, weaponDefID, damage)
    return damage
end

function script.Killed(recentDamage, maxHealth)
    return 0
end

function script.StartMoving() end
function script.StopMoving() end
function script.Activate() return 1 end
function script.Deactivate() return 0 end
