-- Run from the game root: lua tests/mortar_fragments_test.lua
local function normalize(value)
    if type(value) ~= 'table' then return value end
    local result = {}
    for key, item in pairs(value) do
        result[type(key) == 'string' and key:lower() or key] = normalize(item)
    end
    return result
end
lowerkeys = normalize
VFS = {Include = function(path) return dofile(path) end}
local mortar = dofile('weapons/mortar.lua').mortar
local support = dofile('weapons/military_support.lua').supportmortar
local fragments = dofile('weapons/mortar_fragment.lua')
local definitions = {mortar, support, fragments.mortarfragment, fragments.supportmortarfragment}
WeaponDefs, WeaponDefNames = {}, {}
local names = {'mortar', 'supportmortar', 'mortarfragment', 'supportmortarfragment'}
for id, def in ipairs(definitions) do
    WeaponDefNames[names[id]] = {id = id}
    WeaponDefs[id] = {customParams = def.customparams}
end
assert(mortar.damage.default == 1 and support.damage.default == 240, 'retain parent damage')
assert(mortar.areaofeffect == 3 and support.areaofeffect == 120, 'retain parent splash')
local effects = dofile('gamedata/explosions/mortar_burst.lua')
for _, def in ipairs(definitions) do
    assert(effects[def.explosiongenerator:match('custom:(.*)')], 'missing explosion effect')
end
for _, def in pairs(fragments) do
    assert(def.collidefriendly and def.collidefeature and not def.noselfdamage)
    assert(not def.customparams.mortar_fragment_weapon, 'fragment must not split again')
    assert(def.customparams.no_projectile_vfx == 1, 'avoid per-fragment light/ribbon work')
end
for _, effect in pairs(effects) do
    for _, emitter in pairs(effect) do
        if type(emitter) == 'table' and emitter.properties then
            local name = emitter.properties.texture
            local found
            for _, ext in ipairs({'.png', '.tga'}) do
                local f = io.open('bitmaps/ProjectileTextures/' .. name .. ext, 'rb')
                if f then f:close(); found = true end
            end
            assert(found, 'missing texture: ' .. name)
            assert(not emitter.properties.alwaysvisible, 'must respect LOS')
        end
    end
end
local sound = assert(io.open(support.soundhit, 'rb')); sound:close()

local spawned, watched, teams, ownerTeams = {}, {}, {[100] = 3}, {[7] = 5}
Spring = {
    GetProjectileTeamID = function(id) return teams[id] end,
    GetUnitTeam = function(id) return ownerTeams[id] end,
    GetGaiaTeamID = function() return 0 end,
    SpawnProjectile = function(def, params)
        spawned[#spawned + 1] = {def = def, params = params}
        return #spawned + 1000
    end,
}
Script = {SetWatchWeapon = function(id, enabled) watched[id] = enabled end}
Game = {gameSpeed = 30, gravity = 130}
gadgetHandler = {IsSyncedCode = function() return true end}
gadget = {}
dofile('luarules/gadgets/game_mortar_fragments.lua')
gadget:Initialize()
assert(watched[1] and watched[2] and not watched[3] and not watched[4])
assert(#gadget:Explosion_GetWantedWeaponDef() == 2)
gadget:ProjectileCreated(100, 7, 2)
-- Neither a dead launcher nor its later allegiance may retag an in-flight shell.
teams[100], ownerTeams[7] = nil, nil
math.randomseed(123)
assert(gadget:Explosion(2, 20, 10, 30, 7, 100) == false, 'must retain parent CEG')
assert(#spawned == 16)
local quadrants = {}
for _, shot in ipairs(spawned) do
    local p = shot.params
    assert(shot.def == 4 and p.team == 3 and p.owner == 7)
    assert(p.pos[1] == 20 and p.pos[2] == 12 and p.pos[3] == 30)
    local vx, vy, vz = p.speed[1], p.speed[2], p.speed[3]
    local speed = math.sqrt(vx*vx + vy*vy + vz*vz)
    assert(speed >= 4 and speed <= 6 and vy > 0)
    assert(p.ttl == 30 and math.abs(p.gravity + 130/900) < 1e-9)
    assert(speed * p.ttl <= 180, 'fragment lifetime must bound horizontal reach')
    assert(vy + p.ttl * p.gravity < 0, 'fragments must arc down before expiring')
    quadrants[(vx >= 0 and 'e' or 'w') .. (vz >= 0 and 'n' or 's')] = true
    gadget:Explosion(shot.def, 0, 0, 0, 7, 1001)
end
assert(quadrants.en and quadrants.es and quadrants.wn and quadrants.ws)
assert(#spawned == 16, 'fragment hits recursively generated more projectiles')
gadget:Explosion(999, 0, 0, 0, 7, 100)
assert(#spawned == 16, 'unrelated weapon generated fragments')
gadget:ProjectileDestroyed(100)
ownerTeams[7] = 9
gadget:Explosion(1, 0, 0, 0, 7, 100)
assert(#spawned == 32 and spawned[17].def == 3 and spawned[17].params.team == 9,
    'destroyed projectile retained stale allegiance')
-- Reload fallback can recover the team from an already flying projectile.
teams[101] = 6
gadget:Explosion(2, 0, -20, 0, nil, 101)
assert(spawned[33].params.team == 6 and spawned[33].params.owner == -1)
assert(spawned[33].params.pos[2] == -18, 'underwater impacts must not teleport to surface')
gadget:Explosion(2, 0, 0, 0, nil, nil)
assert(spawned[49].params.team == 0, 'ownerless fallback must use Gaia')

-- The new damage source must use the existing wall mitigation path.
UnitDefNames = {brehmerwall = {id = 8}, barricade = {id = 9}}
gadget = {}
dofile('luarules/gadgets/game_military_wall_damage.lua')
assert(gadget:UnitPreDamaged(1, 8, 3, 12, false, 4) == 3)
assert(gadget:UnitPreDamaged(1, 10, 3, 12, false, 4) == 12)
gadgetHandler.IsSyncedCode = function() return false end
gadget = {}
dofile('luarules/gadgets/game_mortar_fragments.lua')
assert(gadget.Explosion == nil, 'unsynced code must not create damaging projectiles')
print('PASS: mortar effects/assets, radial ballistics, damage routing, ownership, cleanup, recursion and sync isolation')
