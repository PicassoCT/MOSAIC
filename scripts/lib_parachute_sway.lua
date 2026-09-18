-- Pure animation math for air_parachut.dae. Its step parent maps local +Z
-- to model up and local +Y to model -Z. Angles are script Y-X-Z Euler.
local M = {}
local sin, cos, sqrt = math.sin, math.cos, math.sqrt
local function limit(x, z, maximum)
    local length = sqrt(x*x + z*z)
    if length > maximum then return x*maximum/length, z*maximum/length end
    return x, z
end

function M.wind(x, z, maximum)
    if maximum <= 0 then return 0, 0 end
    return limit(x/maximum, z/maximum, 1)
end

function M.pose(time, index, count, flowX, flowZ)
    -- Golden-angle spacing covers every element, including the final partial ring.
    local azimuth = (index-1)*2.399963229728653
    local phase = azimuth + (index%7)*0.37
    local curl = 0.12 + 0.14*sin(time*1.1-phase)
                       + 0.045*sin(time*2.3+phase*1.7)
    local a = azimuth + 0.035*sin(time*0.7+phase)
    local leanX, leanZ = limit(flowX, flowZ, 1)
    leanX, leanZ = leanX*0.18, leanZ*0.18
    -- Ry(leanX) Rx(leanZ) Rz(azimuth) Rx(curl), then decompose Y-X-Z.
    -- Compose in the model's actual vertical frame before extracting script angles.
    local ca, sa, cb, sb = cos(a), sin(a), cos(curl), sin(curl)
    local cx, sx, cz, sz = cos(leanX), sin(leanX), cos(leanZ), sin(leanZ)
    local m21 = cz*sa
    local m22 = cz*ca*cb-sz*sb
    local m23 = -cz*ca*sb-sz*cb
    local q33 = -sz*ca*sb+cz*cb
    local m13 = cx*sa*sb+sx*q33
    local m33 = -sx*sa*sb+cx*q33
    local pitch = math.asin(math.max(-1, math.min(1, -m23)))
    return pitch, math.atan2(m13, m33), math.atan2(m21, m22)
end

return M
