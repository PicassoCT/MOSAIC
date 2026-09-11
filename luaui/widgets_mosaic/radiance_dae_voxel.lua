-- Lightweight COLLADA geometry reader and conservative surface voxelizer.
--
-- The DAE supplies the piece-local mesh vertices. Recoil supplies the current
-- cumulative model-space piece matrix, so authored node transforms, DAE unit
-- scale and script animation are all taken from the same transform path the
-- engine uses to render the piece.

local M = {}
local modelCache = {}

local function xmlAttribute(attributes, name)
    return attributes:match(name .. '%s*=%s*"([^"]*)"')
        or attributes:match(name .. "%s*=%s*'([^']*)'")
end

local function normalizeName(name)
    return (name or ""):lower():gsub("[^%w]", "")
end

local function numberList(text)
    local values = {}
    for token in (text or ""):gmatch("%S+") do
        local value = tonumber(token)
        if value ~= nil then
            values[#values + 1] = value
        end
    end
    return values
end

local function parsePositionSource(geometryBody)
    local positionSource

    for _, verticesBody in geometryBody:gmatch("<vertices%s+([^>]-)>(.-)</vertices>") do
        for inputAttributes in verticesBody:gmatch("<input%s+([^>]-)/?>") do
            if xmlAttribute(inputAttributes, "semantic") == "POSITION" then
                positionSource = xmlAttribute(inputAttributes, "source")
                if positionSource then
                    positionSource = positionSource:gsub("^#", "")
                    break
                end
            end
        end
        if positionSource then break end
    end

    if not positionSource then
        for sourceAttributes in geometryBody:gmatch("<source%s+([^>]-)>") do
            local sourceID = xmlAttribute(sourceAttributes, "id")
            if sourceID and sourceID:upper():find("POSITION", 1, true) then
                positionSource = sourceID
                break
            end
        end
    end

    if not positionSource then return nil end

    for sourceAttributes, sourceBody in geometryBody:gmatch("<source%s+([^>]-)>(.-)</source>") do
        if xmlAttribute(sourceAttributes, "id") == positionSource then
            local floatArray = sourceBody:match("<float_array[^>]*>(.-)</float_array>")
            if not floatArray then return nil end

            local stride = tonumber(sourceBody:match("<accessor[^>]-stride%s*=%s*\"(%d+)\"")) or 3
            local sourceValues = numberList(floatArray)
            local vertices = {}
            for i = 1, #sourceValues, stride do
                local x, y, z = sourceValues[i], sourceValues[i + 1], sourceValues[i + 2]
                if x and y and z then
                    vertices[#vertices + 1] = x
                    vertices[#vertices + 1] = y
                    vertices[#vertices + 1] = z
                end
            end
            return vertices
        end
    end
end

local function primitiveLayout(body)
    local vertexOffset
    local stride = 0

    for inputAttributes in body:gmatch("<input%s+([^>]-)/?>") do
        local semantic = xmlAttribute(inputAttributes, "semantic")
        local offset = tonumber(xmlAttribute(inputAttributes, "offset")) or 0
        stride = math.max(stride, offset + 1)
        if semantic == "VERTEX" or semantic == "POSITION" then
            vertexOffset = offset
        end
    end

    return vertexOffset, math.max(1, stride)
end

local function appendTrianglesFromTriangles(geometryBody, triangles)
    for _, body in geometryBody:gmatch("<triangles([^>]*)>(.-)</triangles>") do
        local vertexOffset, stride = primitiveLayout(body)
        local p = body:match("<p[^>]*>(.-)</p>")
        if vertexOffset and p then
            local indices = numberList(p)
            for i = 1, #indices - stride * 2, stride * 3 do
                local a = indices[i + vertexOffset]
                local b = indices[i + stride + vertexOffset]
                local c = indices[i + stride * 2 + vertexOffset]
                if a and b and c then
                    triangles[#triangles + 1] = a + 1
                    triangles[#triangles + 1] = b + 1
                    triangles[#triangles + 1] = c + 1
                end
            end
        end
    end
end

local function appendTrianglesFromPolylist(geometryBody, triangles)
    for _, body in geometryBody:gmatch("<polylist([^>]*)>(.-)</polylist>") do
        local vertexOffset, stride = primitiveLayout(body)
        local p = body:match("<p[^>]*>(.-)</p>")
        local vcountText = body:match("<vcount[^>]*>(.-)</vcount>")
        if vertexOffset and p and vcountText then
            local indices = numberList(p)
            local counts = numberList(vcountText)
            local cursor = 1
            for _, count in ipairs(counts) do
                local polygon = {}
                for vertex = 0, count - 1 do
                    local index = indices[cursor + vertex * stride + vertexOffset]
                    if index then polygon[#polygon + 1] = index + 1 end
                end
                for vertex = 2, #polygon - 1 do
                    triangles[#triangles + 1] = polygon[1]
                    triangles[#triangles + 1] = polygon[vertex]
                    triangles[#triangles + 1] = polygon[vertex + 1]
                end
                cursor = cursor + count * stride
            end
        end
    end
end

local function parseDae(xml, path)
    local model = {
        path = path,
        unitMeter = tonumber(xml:match("<unit[^>]-meter%s*=%s*\"([%+%-%.%deE]+)\"")) or 1,
        geometries = {},
        pieceGeometries = {},
    }

    for geometryAttributes, geometryBody in xml:gmatch("<geometry%s+([^>]-)>(.-)</geometry>") do
        local geometryID = xmlAttribute(geometryAttributes, "id")
        if geometryID then
            local vertices = parsePositionSource(geometryBody)
            if vertices and #vertices >= 9 then
                local triangles = {}
                appendTrianglesFromTriangles(geometryBody, triangles)
                appendTrianglesFromPolylist(geometryBody, triangles)
                model.geometries[geometryID] = {
                    vertices = vertices,
                    triangles = triangles,
                }
            end
        end
    end

    -- Associate visual-scene nodes with their mesh geometry. A stack is used so
    -- nested piece nodes are handled without trying to parse XML recursively.
    local nodeStack = {}
    local searchPos = 1
    while true do
        local startPos, endPos, closing, tag, attributes =
            xml:find("<(%/?)([%w_:%-]+)([^>]*)>", searchPos)
        if not startPos then break end
        searchPos = endPos + 1
        tag = tag:lower()

        if closing == "" and tag == "node" then
            local node = {
                aliases = {
                    xmlAttribute(attributes, "name"),
                    xmlAttribute(attributes, "id"),
                    xmlAttribute(attributes, "sid"),
                },
                geometries = {},
            }
            nodeStack[#nodeStack + 1] = node

        elseif closing == "" and tag == "instance_geometry" then
            local node = nodeStack[#nodeStack]
            local url = xmlAttribute(attributes, "url")
            if node and url then
                node.geometries[#node.geometries + 1] = url:gsub("^#", "")
            end

        elseif closing == "/" and tag == "node" then
            local node = nodeStack[#nodeStack]
            nodeStack[#nodeStack] = nil
            if node and #node.geometries > 0 then
                for _, alias in ipairs(node.aliases) do
                    local key = normalizeName(alias)
                    if key ~= "" then
                        model.pieceGeometries[key] = node.geometries
                    end
                end
            end
        end
    end

    return model
end

local function modelCandidates(unitDefID)
    local unitDef = UnitDefs[unitDefID]
    if not unitDef then return {} end

    local candidates, seen = {}, {}
    local function add(name)
        if type(name) ~= "string" or name == "" then return end
        local names = {name}
        if not name:lower():match("%.dae$") then
            names[#names + 1] = name .. ".dae"
        end
        for _, candidate in ipairs(names) do
            if not candidate:find("/", 1, true) then
                candidate = "objects3d/" .. candidate
            end
            if not seen[candidate] then
                seen[candidate] = true
                candidates[#candidates + 1] = candidate
            end
        end
    end

    add(unitDef.model and unitDef.model.name)
    add(unitDef.modelname)
    return candidates
end

local function getDaeModel(unitDefID)
    local candidates = modelCandidates(unitDefID)
    for _, path in ipairs(candidates) do
        if modelCache[path] ~= false then
            if modelCache[path] then return modelCache[path] end
            local xml = VFS.LoadFile(path)
            if xml then
                local model = parseDae(xml, path)
                modelCache[path] = model
                return model
            end
            modelCache[path] = false
        end
    end
    return nil, "DAE file not found"
end

local function transformPieceVertex(matrix, x, y, z)
    -- Spring.GetUnitPieceMatrix is returned in OpenGL/column-major order.
    return matrix[1] * x + matrix[5] * y + matrix[9]  * z + matrix[13],
           matrix[2] * x + matrix[6] * y + matrix[10] * z + matrix[14],
           matrix[3] * x + matrix[7] * y + matrix[11] * z + matrix[15]
end

local function pointSegmentDistanceSq(px, py, pz, ax, ay, az, bx, by, bz)
    local abx, aby, abz = bx - ax, by - ay, bz - az
    local apx, apy, apz = px - ax, py - ay, pz - az
    local denom = abx * abx + aby * aby + abz * abz
    local t = denom > 1e-12 and (apx * abx + apy * aby + apz * abz) / denom or 0
    t = math.max(0, math.min(1, t))
    local dx = px - (ax + abx * t)
    local dy = py - (ay + aby * t)
    local dz = pz - (az + abz * t)
    return dx * dx + dy * dy + dz * dz
end

local function pointTriangleDistanceSq(px, py, pz, ax, ay, az, bx, by, bz, cx, cy, cz)
    local abx, aby, abz = bx - ax, by - ay, bz - az
    local acx, acy, acz = cx - ax, cy - ay, cz - az
    local apx, apy, apz = px - ax, py - ay, pz - az
    local d1 = abx * apx + aby * apy + abz * apz
    local d2 = acx * apx + acy * apy + acz * apz
    if d1 <= 0 and d2 <= 0 then
        return apx * apx + apy * apy + apz * apz
    end

    local bpx, bpy, bpz = px - bx, py - by, pz - bz
    local d3 = abx * bpx + aby * bpy + abz * bpz
    local d4 = acx * bpx + acy * bpy + acz * bpz
    if d3 >= 0 and d4 <= d3 then
        return bpx * bpx + bpy * bpy + bpz * bpz
    end

    local vc = d1 * d4 - d3 * d2
    if vc <= 0 and d1 >= 0 and d3 <= 0 then
        local v = d1 / (d1 - d3)
        local dx, dy, dz = apx - abx * v, apy - aby * v, apz - abz * v
        return dx * dx + dy * dy + dz * dz
    end

    local cpx, cpy, cpz = px - cx, py - cy, pz - cz
    local d5 = abx * cpx + aby * cpy + abz * cpz
    local d6 = acx * cpx + acy * cpy + acz * cpz
    if d6 >= 0 and d5 <= d6 then
        return cpx * cpx + cpy * cpy + cpz * cpz
    end

    local vb = d5 * d2 - d1 * d6
    if vb <= 0 and d2 >= 0 and d6 <= 0 then
        local w = d2 / (d2 - d6)
        local dx, dy, dz = apx - acx * w, apy - acy * w, apz - acz * w
        return dx * dx + dy * dy + dz * dz
    end

    local va = d3 * d6 - d5 * d4
    if va <= 0 and (d4 - d3) >= 0 and (d5 - d6) >= 0 then
        local denom = (d4 - d3) + (d5 - d6)
        local w = denom ~= 0 and (d4 - d3) / denom or 0
        local ex, ey, ez = cx - bx, cy - by, cz - bz
        local dx, dy, dz = bpx - ex * w, bpy - ey * w, bpz - ez * w
        return dx * dx + dy * dy + dz * dz
    end

    local denom = va + vb + vc
    if math.abs(denom) < 1e-12 then
        return math.min(
            pointSegmentDistanceSq(px, py, pz, ax, ay, az, bx, by, bz),
            pointSegmentDistanceSq(px, py, pz, bx, by, bz, cx, cy, cz),
            pointSegmentDistanceSq(px, py, pz, cx, cy, cz, ax, ay, az)
        )
    end

    local inv = 1 / denom
    local v, w = vb * inv, vc * inv
    local qx = ax + abx * v + acx * w
    local qy = ay + aby * v + acy * w
    local qz = az + abz * v + acz * w
    local dx, dy, dz = px - qx, py - qy, pz - qz
    return dx * dx + dy * dy + dz * dz
end

local function makeVoxelMarker(voxelSize, maxVoxels)
    local occupied = {}
    local count = 0
    local truncated = false
    local half = voxelSize * 0.5
    local maxDistanceSq = half * half * 3.0

    local function mark(ix, iy, iz)
        local key = ix .. ":" .. iy .. ":" .. iz
        if occupied[key] then return true end
        if count >= maxVoxels then
            truncated = true
            return false
        end
        occupied[key] = {ix = ix, iy = iy, iz = iz}
        count = count + 1
        return true
    end

    local function rasterTriangle(ax, ay, az, bx, by, bz, cx, cy, cz)
        local minIx = math.floor((math.min(ax, bx, cx) - half) / voxelSize)
        local maxIx = math.floor((math.max(ax, bx, cx) + half) / voxelSize)
        local minIy = math.floor((math.min(ay, by, cy) - half) / voxelSize)
        local maxIy = math.floor((math.max(ay, by, cy) + half) / voxelSize)
        local minIz = math.floor((math.min(az, bz, cz) - half) / voxelSize)
        local maxIz = math.floor((math.max(az, bz, cz) + half) / voxelSize)

        for ix = minIx, maxIx do
            local px = (ix + 0.5) * voxelSize
            for iy = minIy, maxIy do
                local py = (iy + 0.5) * voxelSize
                for iz = minIz, maxIz do
                    local pz = (iz + 0.5) * voxelSize
                    if pointTriangleDistanceSq(
                        px, py, pz,
                        ax, ay, az, bx, by, bz, cx, cy, cz
                    ) <= maxDistanceSq then
                        if not mark(ix, iy, iz) then return false end
                    end
                end
            end
        end
        return true
    end

    return occupied, rasterTriangle, function() return count, truncated end
end

local function transformGeometry(geometry, matrix)
    local source = geometry.vertices
    local transformed = {}
    for i = 1, #source, 3 do
        local x, y, z = transformPieceVertex(matrix, source[i], source[i + 1], source[i + 2])
        local vertexIndex = math.floor((i - 1) / 3) + 1
        transformed[vertexIndex] = {x, y, z}
    end
    return transformed
end

local function modelToWorld(unitID, x, y, z)
    local ux, uy, uz = Spring.GetUnitBasePosition(unitID)
    local front, up, right = Spring.GetUnitVectors(unitID)
    if not ux or not front or not up or not right then return nil end

    -- Recoil's object transform is composed from -right, up, front.
    return ux - right[1] * x + up[1] * y + front[1] * z,
           uy - right[2] * x + up[2] * y + front[2] * z,
           uz - right[3] * x + up[3] * y + front[3] * z
end

function M.BuildUnitVoxels(unitID, unitDefID, pieceIDs, voxelSize, maxVoxels)
    local model, errorMessage = getDaeModel(unitDefID)
    if not model then return nil, errorMessage end

    local pieceMap = Spring.GetUnitPieceMap(unitID) or {}
    local namesByID = {}
    for name, pieceID in pairs(pieceMap) do
        namesByID[pieceID] = name
    end

    local occupied, rasterTriangle, voxelState = makeVoxelMarker(voxelSize, maxVoxels)
    local matchedPieces, skippedPieces, triangleCount = 0, 0, 0
    local stop = false

    for _, pieceID in ipairs(pieceIDs) do
        if stop then break end
        local pieceName = namesByID[pieceID]
        local geometryIDs = pieceName and model.pieceGeometries[normalizeName(pieceName)]
        local matrix = pieceName and {Spring.GetUnitPieceMatrix(unitID, pieceID)}

        if geometryIDs and matrix[1] then
            local pieceMatched = false
            for _, geometryID in ipairs(geometryIDs) do
                local geometry = model.geometries[geometryID]
                if geometry then
                    pieceMatched = true
                    local vertices = transformGeometry(geometry, matrix)
                    local triangles = geometry.triangles
                    for i = 1, #triangles, 3 do
                        local a, b, c = vertices[triangles[i]], vertices[triangles[i + 1]], vertices[triangles[i + 2]]
                        if a and b and c then
                            triangleCount = triangleCount + 1
                            if not rasterTriangle(
                                a[1], a[2], a[3],
                                b[1], b[2], b[3],
                                c[1], c[2], c[3]
                            ) then
                                stop = true
                                break
                            end
                        end
                    end
                    if stop then break end
                end
            end
            if pieceMatched then matchedPieces = matchedPieces + 1 else skippedPieces = skippedPieces + 1 end
        else
            skippedPieces = skippedPieces + 1
        end
    end

    local voxelCount, truncated = voxelState()
    local voxels = {}
    for _, cell in pairs(occupied) do
        local mx = (cell.ix + 0.5) * voxelSize
        local my = (cell.iy + 0.5) * voxelSize
        local mz = (cell.iz + 0.5) * voxelSize
        local wx, wy, wz = modelToWorld(unitID, mx, my, mz)
        if wx then
            voxels[#voxels + 1] = {
                mx = mx, my = my, mz = mz,
                x = wx, y = wy, z = wz,
            }
        end
    end

    return {
        voxels = voxels,
        voxelSize = voxelSize,
        unitDefID = unitDefID,
        modelPath = model.path,
        daeUnitMeter = model.unitMeter,
        selectedPieceCount = #pieceIDs,
        matchedPieceCount = matchedPieces,
        skippedPieceCount = skippedPieces,
        triangleCount = triangleCount,
        voxelCount = voxelCount,
        truncated = truncated,
        heading = Spring.GetUnitHeading(unitID) or 0,
    }
end

return M
