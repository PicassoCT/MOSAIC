-- Geometry-less roof lamps and a world-size gate for house street furniture.
-- Keep both attached to the actual piece transform, including imported scale.
local M = {placeableMinSize = 32}
local placeableSizes = {}
local function geometry(unitID, pieceID)
    local info = Spring.GetUnitPieceInfo(unitID, pieceID)
    local matrix = {Spring.GetUnitPieceMatrix(unitID, pieceID)}
    if not info or info.isEmpty or not info.min or not info.max or not matrix[16] then return end
    return info, matrix
end

function M.PlaceableEligible(unitID, pieceID)
    local defID = Spring.GetUnitDefID(unitID)
    local key = defID..':'..pieceID
    if placeableSizes[key] then return placeableSizes[key] >= M.placeableMinSize end
    local info, m = geometry(unitID, pieceID)
    if not info then return false end
    local longest = 0
    for axis = 1, 3 do
        local i = (axis - 1) * 4
        local scale = math.sqrt(m[i+1]^2 + m[i+2]^2 + m[i+3]^2)
        longest = math.max(longest, (info.max[axis] - info.min[axis]) * scale)
    end
    placeableSizes[key] = longest
    return longest >= M.placeableMinSize
end

function M.PlaceablesVisible(unitID)
    if Spring.GetUnitNoDraw(unitID) or Spring.GetUnitIsCloaked(unitID) then return false end
    local _, fullView = Spring.GetSpectatingState()
    local los = fullView or Spring.GetUnitLosState(unitID)
    return fullView or (los and los.los) or false
end

function M.RoofLamp(unitID, pieceID, preset)
    if preset ~= 'outpost_roof' then return end
    local info, m = geometry(unitID, pieceID)
    if not info then return end
    local x,y,z = Spring.GetUnitPiecePosDir(unitID, pieceID)
    local front,up,right = Spring.GetUnitVectors(unitID)
    if not x or not front or not up or not right then return end
    local function transform(a,b,c)
        local px,py,pz = m[1]*a+m[5]*b+m[9]*c,
            m[2]*a+m[6]*b+m[10]*c, m[3]*a+m[7]*b+m[11]*c
        return -right[1]*px+up[1]*py+front[1]*pz,
            -right[2]*px+up[2]*py+front[2]*pz,
            -right[3]*px+up[3]*py+front[3]*pz
    end
    local center, topAxis, vertical, sign = {}, 1, -1, 1
    for axis = 1, 3 do
        center[axis] = (info.min[axis] + info.max[axis]) * .5
        local a,b,c = axis==1 and 1 or 0, axis==2 and 1 or 0, axis==3 and 1 or 0
        local dx,dy,dz = transform(a,b,c)
        local length = math.sqrt(dx*dx+dy*dy+dz*dz)
        local alignment = length > 0 and math.abs(dy)/length or 0
        if alignment > vertical then topAxis,vertical,sign = axis,alignment,dy>=0 and 1 or -1 end
    end
    center[topAxis] = sign>0 and info.max[topAxis] or info.min[topAxis]
    local ox,oy,oz = transform(unpack(center))
    return {x=x+ox, y=y+oy+3, z=z+oz, radius=8, color={1,.84,.58}, strength=2}
end

function M.DrawLamp(source)
    -- drawNeonPieces uses a top-down world view; do not inherit the unit matrix.
    gl.PushMatrix()
    gl.LoadIdentity()
    gl.Rotate(-90,1,0,0)
    gl.BeginEnd(GL.TRIANGLES, function()
        local x,y,z,r = source.x,source.y,source.z,source.radius
        gl.Vertex(x-r,y,z-r); gl.Vertex(x+r,y,z-r); gl.Vertex(x+r,y,z+r)
        gl.Vertex(x-r,y,z-r); gl.Vertex(x+r,y,z+r); gl.Vertex(x-r,y,z+r)
    end)
    gl.PopMatrix()
end
return M
