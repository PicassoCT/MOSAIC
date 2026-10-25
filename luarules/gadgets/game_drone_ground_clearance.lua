function gadget:GetInfo()
    return {
        name = "Drone projectile ground clearance",
        desc = "Keeps guided mine drones above terrain without replacing missile guidance",
        author = "MOSAIC contributors",
        license = "GPL3",
        layer = 0,
        enabled = true,
    }
end

if not gadgetHandler:IsSyncedCode() then return end

local weapons, projectiles = {}, {}
local square = Game.squareSize or 8
for id, def in pairs(WeaponDefs) do
    local cp = def.customParams or {}
    local clearance = tonumber(cp.drone_ground_clearance)
    local step = tonumber(cp.drone_terrain_step)
    if clearance and clearance > 0 and step and step > 0 then
        weapons[id] = {clearance = clearance, step = step}
    end
end

local function keepAboveGround(id, cfg)
    local x, y, z = Spring.GetProjectilePosition(id)
    if not x then projectiles[id] = nil; return end
    -- GameFrame precedes native missile motion. Bound the entire next step,
    -- including its vertical dance, and the model's radius. Sampling all
    -- enclosing heightmap vertices also covers ridges between the endpoints.
    local radius = cfg.step + cfg.clearance
    local highest = 0 -- also keep non-water drones above the water surface
    for gx = math.floor((x-radius)/square)*square, math.ceil((x+radius)/square)*square, square do
        for gz = math.floor((z-radius)/square)*square, math.ceil((z+radius)/square)*square, square do
            highest = math.max(highest, Spring.GetGroundHeight(gx, gz))
        end
    end
    local floor = highest + cfg.clearance + cfg.step
    if y < floor then Spring.SetProjectilePosition(id, x, floor, z) end
end

function gadget:Initialize()
    for id in pairs(weapons) do Script.SetWatchWeapon(id, true) end
    -- Reconnect already flying drones after a LuaRules reload.
    for _, id in ipairs(Spring.GetProjectilesInRectangle(0, 0, Game.mapSizeX, Game.mapSizeZ, false, true) or {}) do
        local cfg = weapons[Spring.GetProjectileDefID(id)]
        if cfg then projectiles[id] = cfg; keepAboveGround(id, cfg) end
    end
end

function gadget:ProjectileCreated(id, owner, weapon)
    local cfg = weapons[weapon]
    if not cfg then return end
    projectiles[id] = cfg
    keepAboveGround(id, cfg)
end

function gadget:ProjectileDestroyed(id)
    projectiles[id] = nil
end

function gadget:GameFrame()
    for id, cfg in pairs(projectiles) do keepAboveGround(id, cfg) end
end
