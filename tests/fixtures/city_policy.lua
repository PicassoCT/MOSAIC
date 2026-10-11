-- Use the real pure policy while existing adapter fixtures mock engine APIs.
return function(env)
    local policyEnv = setmetatable({MOSAIC_CONFIG_ONLY=true,
        VFS={Include=dofile}}, {__index=_G})
    local chunk
    if setfenv then chunk=assert(loadfile('scripts/lib_mosaic.lua'));setfenv(chunk,policyEnv)
    else chunk=assert(loadfile('scripts/lib_mosaic.lua','t',policyEnv)) end
    local policy = chunk()
    for _, name in ipairs({'getCityRuinConfig','getCityGeography',
        'getCityRuinCandidateTypeTable','getCityHouseSpawnTypeTable'}) do
        env[name] = policy[name]
    end
    return env
end
