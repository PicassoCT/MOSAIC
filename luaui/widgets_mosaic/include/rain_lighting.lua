-- Bind borrowed radiance textures. No allocation, copying, unit scan or ownership.
return function(shader)
    local loc = {}
    for _, name in ipairs({'rainLightActive','rainLocalActive','rainMapSize','rainLightHeight',
        'rainLocalOrigin','rainLocalSpan','rainLightIntensity','rainLightStrength','glitterTime'}) do
        loc[name] = gl.GetUniformLocation(shader,name)
    end
    return function(enabled)
        local field = enabled and WG.GetRainRadiance and WG.GetRainRadiance()
        local active = field and field.texture and field.occupancy
        local detail = active and field.detail
        gl.Uniform(loc.rainLightActive,active and 1 or 0)
        gl.Uniform(loc.rainLocalActive,detail and 1 or 0)
        gl.Uniform(loc.glitterTime,Spring.GetGameSeconds())
        for slot=10,13 do gl.Texture(slot,false) end
        if not active then return end
        gl.Texture(10,field.texture); gl.Texture(11,field.occupancy)
        gl.Texture(12,detail and detail.texture or field.texture)
        gl.Texture(13,detail and detail.occupancy or field.occupancy)
        gl.Uniform(loc.rainMapSize,Game.mapSizeX,Game.mapSizeZ)
        gl.Uniform(loc.rainLightHeight,field.bottom,field.top)
        gl.Uniform(loc.rainLightIntensity,field.intensity)
        gl.Uniform(loc.rainLightStrength,field.strength)
        gl.Uniform(loc.rainLocalOrigin,detail and detail.domain.x or 0,detail and detail.domain.z or 0)
        gl.Uniform(loc.rainLocalSpan,detail and detail.domain.span or 1)
    end
end
