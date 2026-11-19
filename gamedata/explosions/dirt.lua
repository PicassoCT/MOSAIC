local effects = {
    ["dirt"] = {
        dirtg = {
            air = true,
            class = [[CSimpleParticleSystem]],
            count = 1,
            ground = true,
            properties = {
                airdrag = 0.7,
                alwaysvisible = true,
                colormap = [[0.25 0.20 0.10 1.0 0 0 0 0.0]],
                directional = true,
                emitrot = 90,
                emitrotspread = 0,
                emitvector = [[0, 1, 0]],
                gravity = [[0, 0.3 r0.3, 0]],
                numparticles = 4,
                particlelife = 15,
                particlelifespread = 20,
                particlesize = [[12 r4]],
                particlesizespread = 10,
                particlespeed = 1,
                particlespeedspread = 6,
                pos = [[r-0.5 r0.5, 1 r2, r-0.5 r0.5]],
                sizegrowth = 1.2,
                sizemod = 1.0,
                texture = [[new_dirta]],
                useairlos = false
            }
        },
        dirtw = {
            class = [[CSimpleParticleSystem]],
            count = 1,
            water = true,
            properties = {
                airdrag = 0.7,
                alwaysvisible = true,
                colormap = [[1 1 1 0.5  0.5 0.5 1 0.8 0 0 0 0.0]],
                directional = true,
                emitrot = 90,
                emitrotspread = 0,
                emitvector = [[0, 1, 0]],
                gravity = [[0, 0.3 r0.3, 0]],
                numparticles = 10,
                particlelife = 15,
                particlelifespread = 20,
                particlesize = [[7 r4]],
                particlesizespread = 2,
                particlespeed = 1,
                particlespeedspread = 6,
                pos = [[r-0.5 r0.5, 1 r2, r-0.5 r0.5]],
                sizegrowth = -0.2,
                sizemod = 1.0,
                texture = [[new_dirta]],
                useairlos = false
            }
        }
    }
}

-- Human foot scuffs use the existing dirt/water effect at one eighth scale.
-- The normal dirt effect remains unchanged for vehicles and larger impacts.
local lengthFields = {
    particlesize=true, particlesizespread=true, particlespeed=true,
    particlespeedspread=true, gravity=true, pos=true, sizegrowth=true,
}
local footstep = {}
for name, component in pairs(effects.dirt) do
    local copy = {}
    for key, value in pairs(component) do copy[key] = value end
    copy.properties = {}
    for key, value in pairs(component.properties) do
        if lengthFields[key] then
            if type(value) == 'number' then value = value * .125
            else value = value:gsub('[%-+]?%d*%.?%d+', function(n) return tostring(tonumber(n)*.125) end) end
        end
        copy.properties[key] = value
    end
    footstep[name] = copy
end
effects.melee_footstep = footstep
return effects
