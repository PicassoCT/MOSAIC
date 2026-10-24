-- Run from the repository root with Lua 5.1+ or texlua. Load the real definition
-- inheritance code, Human/Civilian base classes and all three concrete units.
local function loadEnv(path, env)
    if setfenv then
        local chunk = assert(loadfile(path)); setfenv(chunk, env); return chunk()
    end
    return assert(loadfile(path, 't', env))()
end

-- Engine-provided helpers are fixtures; the game's inheritance is not copied.
local function lowerkeys(t)
    local keys = {}
    for key in pairs(t) do keys[#keys + 1] = key end
    for _, key in ipairs(keys) do
        local value = t[key]
        if type(value) == 'table' then lowerkeys(value) end
        if type(key) == 'string' and key:lower() ~= key then
            t[key:lower()] = value; t[key] = nil
        end
    end
    return t
end
local env = setmetatable({Spring={GetModOptions=function() return {} end,
    Echo=function() end, Log=function() end}}, {__index=_G})
env._G=env
env.VFS={ZIP=1, Include=function(path)
    if path == 'gamedata/VFSUtils.lua' then
        env.RecursiveFileSearch=function(directory)
            return directory == 'baseclasses/units' and {'baseclasses/units/Human.lua'} or {}
        end
        return
    end
    if path == 'gamedata/system.lua' then return {lowerkeys=lowerkeys} end
    if path == 'gamedata/sidedata.lua' then return {} end
    return loadEnv(path, env)
end}
loadEnv('gamedata/unitdefs_pre.lua', env)
local baseline = loadEnv('units/neutral/civilian_western/Civilian_western1.lua', env).civilian_western1
local sources = {
    {name='civilian_worker_western', path='units/neutral/civilian_western/Civilian_worker_western.lua',
        culture='western', sex='male', role='maintenance'},
    {name='civilian_courier_asian', path='units/neutral/civilian_asian/Civilian_courier_asian.lua',
        culture='asian', sex='female', role='courier'},
}
for _, source in ipairs(sources) do
    local def = assert(loadEnv(source.path, env)[source.name])
    assert(def.objectname == source.name .. '.dae', 'model reference mismatch')
    assert(def.buildpic == source.name .. '.png', 'unit picture reference mismatch')
    assert(def.script == 'civilianscript.lua', 'occupational unit bypassed the shared civilian script')
    for _, key in ipairs({'movementclass','maxdamage','acceleration','brakerate','turnrate',
        'maxvelocity','canmove','canguard','canpatrol','canstop','canattack','firestate',
        'category','collisionvolumetype','collisionvolumescales','usepiececollisionvolumes',
        'mass','corpse','icontype'}) do
        assert(def[key] == baseline[key], source.name .. ': changed ordinary civilian ' .. key)
    end
    -- Preserve arming/anarchy support inherited by ordinary civilians. Empty
    -- weapon overrides would silently remove an existing civilian capability.
    assert(#def.weapons == #baseline.weapons and #def.weapons == 2)
    for index, weapon in ipairs(baseline.weapons) do
        assert(def.weapons[index].name == weapon.name, 'lost inherited civilian weapon')
        assert(def.weapons[index].onlytargetcategory == weapon.onlytargetcategory)
    end
    assert(def.customparams.baseclass == 'Civilian', 'shadow/selection classification lost')
    assert(def.customparams.normaltex == 'unittextures/civ_occupations_normal.png')
    assert(def.customparams.civilian_culture == source.culture)
    assert(def.customparams.civilian_gender == source.sex)
    assert(def.customparams.civilian_role == source.role)
end
print('PASS: occupational definitions retain native civilian movement, shared script, collision and existing behavior')
