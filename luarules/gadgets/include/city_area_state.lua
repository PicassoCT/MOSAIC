-- One sparse spatial index for recent combat, civilian danger and damage heat.
-- A touched cell is conservatively unsafe until the incident expires. Queries
-- never allocate cells; cost/storage depend on active incidents, not city size.
return function(config, sizeX, sizeZ, getFrame)
    local cells = {}
    local service = {cells = cells, normalizationValue = 1}
    local size = config.cellSize
    local maxX, maxZ = math.ceil(sizeX / size) - 1, math.ceil(sizeZ / size) - 1
    local function coordinates(x, z)
        if type(x) ~= 'number' or type(z) ~= 'number' or x ~= x or z ~= z then return end
        if x < 0 or z < 0 or x > sizeX or z > sizeZ then return end
        return math.min(maxX, math.floor(x / size)), math.min(maxZ, math.floor(z / size))
    end
    local function heat(cell, frame)
        return math.max(0, cell.heat - math.max(0, frame - cell.frame) * config.heatDecayPerFrame)
    end
    function service:ReportIncident(x, z, damage, radius)
        if not coordinates(x, z) then return end
        local frame = getFrame()
        radius = math.max(0, radius or config.dangerRadius)
        for ix = math.max(0, math.floor((x-radius)/size)), math.min(maxX, math.floor((x+radius)/size)) do
            for iz = math.max(0, math.floor((z-radius)/size)), math.min(maxZ, math.floor((z+radius)/size)) do
                local dx = math.max(ix*size-x, 0, x-(ix+1)*size)
                local dz = math.max(iz*size-z, 0, z-(iz+1)*size)
                if dx*dx+dz*dz <= radius*radius then
                    local key = ix*(maxZ+1)+iz
                    local cell = cells[key] or {x=ix, z=iz, heat=0, frame=frame}
                    cell.heat = math.min(config.maxHeat, heat(cell, frame) + math.max(0, damage or 0))
                    cell.frame, cell.untilFrame = frame, frame+config.quietFrames
                    cells[key] = cell
                    self.normalizationValue = math.max(self.normalizationValue, cell.heat)
                end
            end
        end
    end
    local function at(x, z)
        local ix, iz = coordinates(x, z)
        return ix and cells[ix*(maxZ+1)+iz]
    end
    function service:IsDangerous(x, z)
        local cell = at(x, z)
        return cell ~= nil and getFrame() < cell.untilFrame
    end
    service.IsConflictNearby = service.IsDangerous
    function service:IsPeaceful(x, z) return not self:IsConflictNearby(x, z) end
    function service:getDangerAtLocation(x, z)
        local cell, frame = at(x, z), getFrame()
        if not cell or frame >= cell.untilFrame then return 0 end
        return math.min(1, heat(cell, frame) / math.max(1, self.normalizationValue))
    end
    function service:getHighestDangerLocation()
        local best, bestKey, value, frame = nil, nil, -1, getFrame()
        for key, cell in pairs(cells) do
            local current = heat(cell, frame)
            if frame < cell.untilFrame and (current > value or (current == value and key < bestKey)) then
                best, bestKey, value = cell, key, current
            end
        end
        if best then return math.min(sizeX, (best.x+0.5)*size), math.min(sizeZ, (best.z+0.5)*size) end
        return nil, nil
    end
    function service:Update()
        local frame, peak = getFrame(), 1
        for key, cell in pairs(cells) do
            if frame >= cell.untilFrame then cells[key] = nil
            else peak = math.max(peak, heat(cell, frame)) end
        end
        self.normalizationValue = peak
    end
    -- Compatibility alias only; no duplicate map.
    service.addDamageAtLocation = service.ReportIncident
    return service
end
