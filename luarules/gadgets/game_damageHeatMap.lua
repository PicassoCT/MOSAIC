function gadget:GetInfo()
    return {name='City Area State', desc='Shared expiring danger and conflict metadata',
        author='MOSAIC', date='2026', license='GPL3', layer=100, enabled=true}
end
if not gadgetHandler:IsSyncedCode() then return false end
local config = VFS.Include('luarules/configs/city_area.lua')
local newState = VFS.Include('luarules/gadgets/include/city_area_state.lua')
local watched, lastShot = {}, {}

function gadget:Initialize()
    GG.CityAreaState = newState(config, Game.mapSizeX, Game.mapSizeZ, Spring.GetGameFrame)
    GG.DamageHeatMap = GG.CityAreaState
    for id, def in pairs(WeaponDefs) do
        -- Utility weapons (raids, markers, etc.) must not keep a district at war.
        if def.damages and (def.damages[0] or def.damages.default or 0) > 1 then
            watched[id] = true
            Script.SetWatchWeapon(id, true)
        end
    end
end
function gadget:UnitDamaged(id, def, team, damage)
    if not damage or damage <= 0 then return end
    local x, _, z = Spring.GetUnitPosition(id)
    if x then GG.CityAreaState:ReportIncident(x, z, damage) end
end
function gadget:ProjectileCreated(projectile, owner, weapon)
    if not watched[weapon] or not owner then return end
    local frame = Spring.GetGameFrame()
    if frame < (lastShot[owner] or -1) then return end
    lastShot[owner] = frame + 15
    local x, _, z = Spring.GetUnitPosition(owner)
    if x then GG.CityAreaState:ReportIncident(x, z, 0) end
end
function gadget:Explosion(weapon, x, y, z)
    if watched[weapon] then
        GG.CityAreaState:ReportIncident(x, z, 0, math.max(config.dangerRadius, WeaponDefs[weapon].damageAreaOfEffect or 0))
    end
    return false
end
function gadget:UnitDestroyed(id) lastShot[id] = nil end
function gadget:GameFrame(frame)
    if frame % 30 == 0 then GG.CityAreaState:Update() end
end
