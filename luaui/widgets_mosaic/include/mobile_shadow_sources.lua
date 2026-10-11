-- Bounded, client-side moving radiance blockers. This module owns no GL objects.
-- Collect({minX,maxX,minZ,maxZ,margin?}, drawFrame?) returns records, stats.
-- A snapshot is reused for the same draw/domain and may be overwritten on the
-- next draw. Consumers must retain unitID so an emitter can clear its own proxy.
local M = {maxCasters = 128, hardMaxCasters = 256}
local abs, sqrt, min, max = math.abs, math.sqrt, math.min, math.max
local function finite(v) return type(v) == 'number' and v == v and abs(v) < math.huge end
local function bounded(v, fallback, lo, hi)
    return finite(v) and max(lo, min(hi, math.floor(v))) or fallback
end
local function nearer(a, b)
    return a.d2 < b.d2 or (a.d2 == b.d2 and a.unitID < b.unitID)
end
local function normalize(x, y, z)
    if not finite(x) or not finite(y) or not finite(z) then return end
    local length = sqrt(x*x + y*y + z*z)
    if length < 0.00001 or not finite(length) then return end
    return x/length, y/length, z/length
end
local function clearArray(t) for i = #t, 1, -1 do t[i] = nil end end

function M.New(profiles, limits)
    profiles, limits = profiles or {}, limits or {}
    local cap = bounded(limits.maxCasters, M.maxCasters, 1, M.hardMaxCasters)
    local candidateCap = bounded(limits.maxCandidates, cap*2, cap, M.hardMaxCasters*2)
    local scanInterval = bounded(limits.scanIntervalFrames, 3, 1, 30)
    -- Rectangle queries test the unit origin, not its volume. This extra pad
    -- covers the authored vehicle extents around the requested lighting area.
    local queryPadding = bounded(limits.queryPadding, 128, 0, 2048)
    local candidates, candidatePool, records, recordPool = {}, {}, {}, {}
    local stats = {maxCasters=cap, maxCandidates=candidateCap, queried=0,
        eligible=0, retained=0, selected=0, overBudget=0, geometryReads=0, scans=0}
    local self = {stats=stats}
    local cachedDraw, lastScan, scanAlly, scanFull, scanDomain, scanX, scanY, scanZ
    local snapshotDomain, stopped
    local destroyed, destroyedFrame = {}, nil

    local function valid(id, full, ally)
        if destroyed[id] or not Spring.ValidUnitID(id) or Spring.GetUnitIsDead(id)
            or Spring.GetUnitIsCloaked(id) or Spring.GetUnitNoDraw(id)
            or Spring.GetUnitTransporter(id)
            or (Spring.IsUnitIcon and Spring.IsUnitIcon(id)) then return false end
        if not full then
            local los = Spring.GetUnitLosState(id, ally)
            if not los or not los.los then return false end
        end
        local _, _, _, _, built = Spring.GetUnitHealth(id)
        return built and built >= 1
    end
    local function midpoint(id)
        if Spring.GetUnitViewPosition then
            return Spring.GetUnitViewPosition(id, true)
        end
        -- A compatibility fallback still uses the model midpoint, never pos.
        local _, _, _, x, y, z = Spring.GetUnitPosition(id, true)
        return x, y, z
    end
    local function position(candidate, cx, cy, cz)
        local x, y, z = midpoint(candidate.unitID)
        if not finite(x) or not finite(y) or not finite(z) then return false end
        candidate.x, candidate.y, candidate.z = x, y, z
        candidate.d2 = (cx-x)^2 + (cy-y)^2 + (cz-z)^2
        return finite(candidate.d2)
    end
    local function domainBounds(domain)
        if type(domain) ~= 'table' or not finite(domain.minX) or not finite(domain.maxX)
            or not finite(domain.minZ) or not finite(domain.maxZ)
            or domain.minX >= domain.maxX or domain.minZ >= domain.maxZ then return end
        local margin = finite(domain.margin) and max(0, domain.margin) or 0
        return {domain.minX-margin, domain.maxX+margin,
            domain.minZ-margin, domain.maxZ+margin}
    end
    local function sameDomain(a, b)
        return a and b and a[1]==b[1] and a[2]==b[2] and a[3]==b[3] and a[4]==b[4]
    end

    -- A farthest-first heap keeps selection storage and work per insertion
    -- bounded even when the spatial query includes thousands of civilians.
    local function siftDown(index)
        local n = #candidates
        while index*2 <= n do
            local child = index*2
            if child < n and nearer(candidates[child], candidates[child+1]) then child=child+1 end
            if not nearer(candidates[index], candidates[child]) then break end
            candidates[index], candidates[child] = candidates[child], candidates[index]
            index = child
        end
    end
    local function retain(id, defID, x, y, z, d2)
        local n, item = #candidates
        if n < candidateCap then
            item = candidatePool[n+1]
            if not item then item={}; candidatePool[n+1]=item end
        else
            item = candidates[1]
            if d2 > item.d2 or (d2 == item.d2 and id >= item.unitID) then return end
        end
        item.unitID, item.defID, item.x, item.y, item.z, item.d2 = id, defID, x, y, z, d2
        if n < candidateCap then
            local index = n+1
            candidates[index] = item
            while index > 1 do
                local parent = math.floor(index/2)
                if not nearer(candidates[parent], item) then break end
                candidates[index], candidates[parent] = candidates[parent], item
                index = parent
            end
        else
            siftDown(1)
        end
    end
    local function scan(bounds, frame, full, ally, cx, cy, cz)
        clearArray(candidates)
        local ids = Spring.GetUnitsInRectangle(bounds[1]-queryPadding, bounds[3]-queryPadding,
            bounds[2]+queryPadding, bounds[4]+queryPadding) or {}
        stats.queried, stats.eligible, stats.scans = #ids, 0, stats.scans+1
        for i = 1, #ids do
            local id = ids[i]
            local defID = Spring.GetUnitDefID(id)
            if profiles[defID] and valid(id, full, ally) then
                local x, y, z = midpoint(id)
                if finite(x) and finite(y) and finite(z) then
                    local d2 = (cx-x)^2 + (cy-y)^2 + (cz-z)^2
                    if finite(d2) then
                        stats.eligible = stats.eligible+1
                        retain(id, defID, x, y, z, d2)
                    end
                end
            end
        end
        stats.retained = #candidates
        lastScan, scanAlly, scanFull, scanDomain = frame, ally, full, bounds
        scanX, scanY, scanZ = cx, cy, cz
    end
    local function geometry(candidate, record)
        local id = candidate.unitID
        stats.geometryReads = stats.geometryReads+1
        local sx, sy, sz, ox, oy, oz = Spring.GetUnitCollisionVolumeData(id)
        if not finite(sx) or not finite(sy) or not finite(sz)
            or sx<=0 or sy<=0 or sz<=0 or not finite(ox) or not finite(oy) or not finite(oz) then return end
        local front, up = Spring.GetUnitVectors(id)
        if not front or not up then return end
        local zx, zy, zz = normalize(front[1], front[2], front[3])
        if not zx then return end
        local ux, uy, uz = normalize(up[1], up[2], up[3])
        if not ux then return end
        local dot = ux*zx + uy*zy + uz*zz
        local yx, yy, yz = normalize(ux-dot*zx, uy-dot*zy, uz-dot*zz)
        if not yx then return end
        local xx, xy, xz = yy*zz-yz*zy, yz*zx-yx*zz, yx*zy-yy*zx
        -- Recoil ComposeMatrix uses {-right,up,front}. CollisionHandler adds
        -- relMidPos then the collision offsets in that model basis. The view
        -- midpoint already includes relMidPos and the engine draw translation.
        local x = candidate.x + xx*ox + yx*oy + zx*oz
        local y = candidate.y + xy*ox + yy*oy + zy*oz
        local z = candidate.z + xz*ox + yz*oy + zz*oz
        local hx, hy, hz = sx*.5, sy*.5, sz*.5
        local shape = profiles[candidate.defID].shape
        if shape ~= 1 and shape ~= 2 then return end
        local ex, ey, ez, radius
        if shape == 1 then
            ex, ey, ez = abs(xx)*hx+abs(yx)*hy+abs(zx)*hz,
                abs(xy)*hx+abs(yy)*hy+abs(zy)*hz, abs(xz)*hx+abs(yz)*hy+abs(zz)*hz
            radius = sqrt(hx*hx+hy*hy+hz*hz)
        else
            ex, ey, ez = sqrt((xx*hx)^2+(yx*hy)^2+(zx*hz)^2),
                sqrt((xy*hx)^2+(yy*hy)^2+(zy*hz)^2), sqrt((xz*hx)^2+(yz*hy)^2+(zz*hz)^2)
            radius = max(hx,hy,hz)
        end
        if not finite(x) or not finite(y) or not finite(z) or not finite(radius)
            or not finite(ex) or not finite(ey) or not finite(ez) then return end
        record.unitID, record.shape, record.d2, record.radius = id, shape, candidate.d2, radius
        local center, axisX, axisY, axisZ, half = record.center, record.axisX, record.axisY, record.axisZ, record.half
        center[1], center[2], center[3] = x, y, z
        axisX[1], axisX[2], axisX[3] = xx, xy, xz
        axisY[1], axisY[2], axisY[3] = yx, yy, yz
        axisZ[1], axisZ[2], axisZ[3] = zx, zy, zz
        half[1], half[2], half[3] = hx, hy, hz
        record.minX, record.maxX, record.minZ, record.maxZ = x-ex, x+ex, z-ez, z+ez
        record.minY, record.maxY = y-ey, y+ey
        return true
    end

    function self:Invalidate()
        cachedDraw, lastScan = nil, nil
    end
    function self:UnitCreated(id)
        destroyed[id]=nil; self:Invalidate()
    end
    function self:UnitDestroyed(id)
        local frame = Spring.GetGameFrame()
        if destroyedFrame ~= frame then destroyed={}; destroyedFrame=frame end
        destroyed[id]=true; self:Invalidate()
    end
    function self:UnitEnteredLos() self:Invalidate() end
    function self:UnitLeftLos() self:Invalidate() end
    function self:Clear()
        clearArray(candidates); clearArray(records)
        stats.queried, stats.eligible, stats.retained, stats.selected = 0, 0, 0, 0
        stats.overBudget, stats.geometryReads = 0, 0
        stats.minY, stats.maxY = nil, nil
        scanDomain, snapshotDomain = nil, nil
        destroyed, destroyedFrame = {}, nil
        self:Invalidate()
    end
    function self:Shutdown()
        self:Clear(); clearArray(candidatePool); clearArray(recordPool); stopped=true
    end
    function self:Collect(domain, drawFrame)
        if stopped then return records, stats end
        local bounds = domainBounds(domain)
        if not bounds then self:Clear(); return records, stats end
        drawFrame = drawFrame or (Spring.GetDrawFrame and Spring.GetDrawFrame())
        if drawFrame and cachedDraw==drawFrame and sameDomain(bounds,snapshotDomain) then return records, stats end
        local frame = Spring.GetGameFrame()
        if destroyedFrame ~= frame then destroyed={}; destroyedFrame=frame end
        local _, full = Spring.GetSpectatingState()
        local ally = Spring.GetMyAllyTeamID()
        local cx, cy, cz = Spring.GetCameraPosition()
        if not finite(cx) or not finite(cy) or not finite(cz) then self:Clear(); return records, stats end
        local paused
        if Spring.GetGameSpeed then local _, _, value=Spring.GetGameSpeed(); paused=value end
        local cameraShift = scanX and ((cx-scanX)^2+(cy-scanY)^2+(cz-scanZ)^2) or 0
        if not lastScan or frame<lastScan or frame-lastScan>=scanInterval
            or ally~=scanAlly or full~=scanFull or not sameDomain(bounds,scanDomain)
            or cameraShift>=64*64 or (paused and cameraShift>.01) then
            scan(bounds, frame, full, ally, cx, cy, cz)
        end
        -- Hidden/destroyed units disappear every draw, even between spatial
        -- scans. DefID is rechecked before reuse; no model/piece state survives.
        for i = #candidates, 1, -1 do
            local item = candidates[i]
            if Spring.GetUnitDefID(item.unitID) ~= item.defID or not valid(item.unitID,full,ally)
                or not position(item,cx,cy,cz) then table.remove(candidates,i) end
        end
        table.sort(candidates,nearer)
        clearArray(records)
        stats.geometryReads = 0
        stats.minY, stats.maxY = nil, nil
        for i = 1, #candidates do
            local index = #records+1
            local record = recordPool[index]
            if not record then
                record={center={},axisX={},axisY={},axisZ={},half={}}; recordPool[index]=record
            end
            if geometry(candidates[i],record) and record.maxX>=bounds[1] and record.minX<=bounds[2]
                and record.maxZ>=bounds[3] and record.minZ<=bounds[4] then
                records[index] = record
                stats.minY = stats.minY and min(stats.minY,record.minY) or record.minY
                stats.maxY = stats.maxY and max(stats.maxY,record.maxY) or record.maxY
                if index >= cap then break end
            end
        end
        stats.retained, stats.selected = #candidates, #records
        stats.overBudget = max(0,stats.eligible-cap)
        cachedDraw, snapshotDomain = drawFrame, bounds
        return records, stats
    end
    return self
end
return M
