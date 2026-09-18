include "createCorpse.lua"
include "lib_OS.lua"
include "lib_UnitScript.lua"
include "lib_Animation.lua"
--include "lib_Build.lua"

-- One bomb per sortie. The existing Armybase services aircraft in a local
-- holding circle; there is no runway / landing-pad system in this game.
local bombLoaded = true
local SERVICE_RADIUS = 300
local REARM_SECONDS = 15

local function setBombLoaded(loaded)
    bombLoaded = loaded
    Spring.SetUnitRulesParam(unitID, "f35_bomb_loaded", loaded and 1 or 0,
        {allied = true})
end

local function usableBase(id)
    if not Spring.ValidUnitID(id) or Spring.GetUnitIsDead(id) then return false end
    if Spring.GetUnitTeam(id) ~= Spring.GetUnitTeam(unitID) then return false end
    if Spring.GetUnitDefID(id) ~= UnitDefNames.armybase.id then return false end
    local _, _, _, _, progress = Spring.GetUnitHealth(id)
    return progress == 1 and not Spring.GetUnitIsStunned(id)
end

local function nearestBase()
    local x, _, z = Spring.GetUnitPosition(unitID)
    local best, distance
    for _, id in ipairs(Spring.GetTeamUnitsByDefs(Spring.GetUnitTeam(unitID),
            UnitDefNames.armybase.id) or {}) do
        if usableBase(id) then
            local bx, _, bz = Spring.GetUnitPosition(id)
            local d = (x-bx)^2 + (z-bz)^2
            if not distance or d < distance then best, distance = id, d end
        end
    end
    return best
end

local function rearmBomb()
    -- Issue orders outside the weapon callback.
    Sleep(1)
    local base, serviced = nil, 0
    while not bombLoaded do
        if not base or not usableBase(base) then
            base, serviced = nearestBase(), 0
            if base then Spring.GiveOrderToUnit(unitID, CMD.GUARD, {base}, {}) end
        end
        if base then
            local x, _, z = Spring.GetUnitPosition(unitID)
            local bx, _, bz = Spring.GetUnitPosition(base)
            if (x-bx)^2 + (z-bz)^2 <= SERVICE_RADIUS^2 then
                serviced = serviced + 1
            else
                serviced = 0
            end
        end
        Sleep(1000)
        -- Recheck the base after the wait: capture/destruction cancels service.
        if base and usableBase(base) and serviced >= REARM_SECONDS then
            local x, _, z = Spring.GetUnitPosition(unitID)
            local bx, _, bz = Spring.GetUnitPosition(base)
            if (x-bx)^2 + (z-bz)^2 <= SERVICE_RADIUS^2 then
                setBombLoaded(true)
            end
        end
    end
end

TablesOfPiecesGroups = {}
function script.HitByWeapon(x, z, weaponDefID, damage) end

function script.Create()
    setBombLoaded(Spring.GetUnitRulesParam(unitID, "f35_bomb_loaded") ~= 0)
    if not bombLoaded then StartThread(rearmBomb) end
    Hide(RocketPod)
    Hide(bodyFly)
    TablesOfPiecesGroups = getPieceTableByNameGroups(false, true)
end

function script.Killed(recentDamage, _)
    return 1
end
function landReady()
    WTurn(Canopy, x_axis, math.rad(0), 5)
    Show(bodyFly)
    Hide(bodyLand)
    Hide(Canopy)
end
function script.StartMoving() 
    StartThread(landReady)
end

bodyLand = piece("bodyLand")
bodyFly = piece("bodyFly")
Canopy = piece("Canopy")
RocketPod = piece("RocketPod")
function startReady()
    Show(Canopy)
    Hide(bodyFly)
    Show(bodyLand)
    Turn(Canopy, x_axis, math.rad(-50), 5)
    end
function script.StopMoving() 
    StartThread(startReady)
end

function script.Activate() return 1 end

function script.Deactivate() return 0 end

--- -aimining & fire weapon
function script.AimFromWeapon1() 
    return RocketPod 
end

function script.QueryWeapon1() 
    return RocketPod 
end

function script.AimWeapon1(Heading, pitch)
    return true
end

function script.FireWeapon1()
    return true
end

function script.AimFromWeapon2() 
    return RocketPod 
end

function script.QueryWeapon2() 
    return RocketPod 
end


function script.AimWeapon2(Heading, pitch)
    return bombLoaded
end

function script.BlockShot2()
    return not bombLoaded
end

function script.FireWeapon2()
    if bombLoaded then
        setBombLoaded(false)
        StartThread(rearmBomb)
    end
    return true
end
