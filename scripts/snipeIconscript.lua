include "createCorpse.lua"
include "lib_OS.lua"
include "lib_UnitScript.lua"
include "lib_Animation.lua"
--include "lib_Build.lua"


local myTeam = Spring.GetUnitTeam(unitID)
local myParent = nil
TablesOfPiecesGroups = {}

function script.HitByWeapon(x, z, weaponDefID, damage) end

center = piece "base"
-- Turret = piece "triangleTurret"
triangle = {}
Turrets = {}
turretTriangle = nil
function script.Create()
    -- generatepiecesTableAndArrayCode(unitID)
    TablesOfPiecesGroups = getPieceTableByNameGroups(false, true)
    -- setSpeedToZero, allow for rotation
    hideAll(unitID)
    triangle = TablesOfPiecesGroups["Tris"]
    Turrets = TablesOfPiecesGroups["Turret"]

    turretTriangle = triangle[1]
    setSpeedEnv(unitID, 0.0)
    -- TriangleTest used to poll geometry every second without affecting gameplay.
    -- Resolution now queries the cone only when a round actually resolves.
    StartThread(DelayedRegister)

end

function DelayedRegister()
    while not GG.DisplayedSniperIconParent or
        not GG.DisplayedSniperIconParent[unitID] do
        Sleep(100)
    end

    myParent = GG.DisplayedSniperIconParent[unitID]

    local teamID = Spring.GetUnitTeam(unitID) or 0
    local colourIndex = ((1 + teamID) % 2) + 1
    if Turrets[colourIndex] then
        Show(Turrets[colourIndex])
    end
end

function getUnitsInTriangle()
    if type(triangle) ~= "table" or #triangle < 3 then
        return {}
    end

    local maxRange = 85
    local worldPos = {}
    local x, _, z = Spring.GetUnitPosition(unitID)
    if not x then return {} end

    for i = 1, 3 do
        local px, _, pz = Spring.GetUnitPiecePosDir(unitID, triangle[i])
        if not px then return {} end
        worldPos[i] = {x = px, z = pz}
    end

    return foreach(
        getAllInCircle(x, z, maxRange, unitID),
        function(id)
            if Spring.GetUnitDefID(id) == unitDefID then
                return id
            end
        end,
        function(id)
            local px, _, pz = Spring.GetUnitPosition(id)
            if px and pointWithinTriangle(
                worldPos[1].x, worldPos[1].z,
                worldPos[2].x, worldPos[2].z,
                worldPos[3].x, worldPos[3].z,
                px, pz
            ) then
                return id
            end
        end
    ) or {}
end

function script.Killed(recentDamage, _)
    return 1
end

-- - -aimining & fire weapon
function script.AimFromWeapon1() return center end

function script.QueryWeapon1() return center end

function script.AimWeapon1(Heading, pitch)
    local targetType = Spring.GetUnitWeaponTarget(unitID, 1)
    if not targetType then
        return false
    end

    if targetType == 2 and center then
        WTurn(center, y_axis, -math.pi + Heading, 0)
    end

    return false
end

function script.FireWeapon1() return true end

function script.Activate() return 1 end

function script.Deactivate() return 0 end

