function gadget:GetInfo()
    return {
        name = "Mortar fragmentation",
        desc = "Throws short-lived ballistic shrapnel from mortar impacts",
        author = "MOSAIC contributors",
        license = "GPL3",
        layer = 0,
        enabled = true,
    }
end

if not gadgetHandler:IsSyncedCode() then return end

local fragmentWeapons, wanted = {}, {}
local projectileTeams = {}
local fps = Game.gameSpeed or 30
local count = 16
for id, def in pairs(WeaponDefs) do
    local name = (def.customParams or {}).mortar_fragment_weapon
    local fragment = name and WeaponDefNames[name]
    if fragment then
        fragmentWeapons[id] = fragment.id
        wanted[#wanted + 1] = id
    end
end
table.sort(wanted)

function gadget:Initialize()
    for _, id in ipairs(wanted) do Script.SetWatchWeapon(id, true) end
end

function gadget:Explosion_GetWantedWeaponDef() return wanted end

function gadget:ProjectileCreated(id, ownerID, weaponID)
    if fragmentWeapons[weaponID] then
        -- Keep allegiance even if the launcher dies or changes team in flight.
        projectileTeams[id] = Spring.GetProjectileTeamID(id)
    end
end

function gadget:ProjectileDestroyed(id)
    projectileTeams[id] = nil
end

function gadget:Explosion(weaponID, x, y, z, ownerID, projectileID)
    local fragment = fragmentWeapons[weaponID]
    if not fragment then return end
    local team = projectileID and projectileTeams[projectileID]
    if team == nil and projectileID then team = Spring.GetProjectileTeamID(projectileID) end
    if team == nil and ownerID and ownerID >= 0 then team = Spring.GetUnitTeam(ownerID) end
    team = team or Spring.GetGaiaTeamID()

    -- Speeds and gravity passed to SpawnProjectile are in units per frame.
    -- A jittered radial fan makes each burst different without leaving large
    -- accidental gaps. Low fragments sweep outward; higher ones visibly arc.
    local phase = math.random() * 2 * math.pi
    for i = 1, count do
        local angle = phase + (i - 1 + math.random() * 0.7) * 2 * math.pi / count
        local elevation = 0.12 + math.random() * 0.55
        local speed = (120 + math.random() * 60) / fps
        local horizontal = math.cos(elevation) * speed
        Spring.SpawnProjectile(fragment, {
            pos = {x, y + 2, z},
            speed = {math.cos(angle) * horizontal, math.sin(elevation) * speed,
                math.sin(angle) * horizontal},
            owner = ownerID or -1,
            team = team,
            ttl = fps,
            gravity = -Game.gravity / (fps * fps),
        })
    end
    -- Do not suppress the parent explosion's CEG or normal area damage.
    return false
end
