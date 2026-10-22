-- Display-only road geometry. No engine calls, RNG or writes to the source
-- network: street IDs, addresses and navigation keep their original vertices.
local M = {}
local sqrt, abs, min, max = math.sqrt, math.abs, math.min, math.max
local EPSILON = 1e-8
local MAX_STEP = 64
local MAX_TURN_COS = math.cos(math.rad(6))
local MAX_CHORD_ERROR = 0.35
local MITER_LIMIT = 1.5

local function copy(p) return {p[1], p[2]} end
local function distance(a, b)
    local x, z = b[1] - a[1], b[2] - a[2]
    return sqrt(x * x + z * z)
end
local function same(a, b)
    return abs(a[1] - b[1]) < EPSILON and abs(a[2] - b[2]) < EPSILON
end
local function append(points, p)
    if not points[#points] or not same(points[#points], p) then
        points[#points + 1] = copy(p)
    end
end
local function straight(a, b, c)
    local ux, uz, vx, vz = b[1]-a[1], b[2]-a[2], c[1]-b[1], c[2]-b[2]
    return abs(ux*vz-uz*vx) <= EPSILON and ux*vx+uz*vz >= 0
end

-- Remove only exactly collinear samples. Unlike an unconstrained simplifier,
-- this does not spend any of the half-width allowance for rounding a bend.
local function collapse(points, closed)
    local out = {}
    local count = closed and #points-1 or #points
    for i = 1, count do
        local p = points[i]
        if not out[#out] or not same(out[#out], p) then
            while #out >= 2 and straight(out[#out-1], out[#out], p) do
                out[#out] = nil
            end
            out[#out+1] = copy(p)
        end
    end
    if closed then
        local changed = true
        while changed and #out > 3 do
            changed = false
            if straight(out[#out], out[1], out[2]) then
                table.remove(out, 1); changed = true
            end
            if #out > 3 and straight(out[#out-1], out[#out], out[1]) then
                out[#out] = nil; changed = true
            end
        end
    end
    return out
end

local function line(points, target)
    local start = points[#points]
    if not start then append(points, target); return end
    local steps = max(1, math.ceil(distance(start, target) / MAX_STEP))
    for i = 1, steps do
        local t = i / steps
        append(points, {start[1]+(target[1]-start[1])*t, start[2]+(target[2]-start[2])*t})
    end
end

local function midpoint(a, b) return {(a[1]+b[1])*0.5, (a[2]+b[2])*0.5} end

-- Subdivide the actual quadratic, not the source polyline. Tangent rotation
-- controls visible faceting; chord error and length also bound terrain chords.
local function quadratic(points, a, control, b, depth)
    local ux, uz = control[1]-a[1], control[2]-a[2]
    local vx, vz = b[1]-control[1], b[2]-control[2]
    local tangentLength = sqrt((ux*ux+uz*uz)*(vx*vx+vz*vz))
    local dx, dz = b[1]-a[1], b[2]-a[2]
    local chordLength = sqrt(dx*dx+dz*dz)
    local error = chordLength > EPSILON and abs(ux*dz-uz*dx)/chordLength*0.5 or distance(a, control)
    local gentle = tangentLength <= EPSILON or ux*vx+uz*vz >= MAX_TURN_COS*tangentLength
    if depth >= 12 or (gentle and error <= MAX_CHORD_ERROR and chordLength <= MAX_STEP) then
        append(points, b)
        return
    end
    local ac, cb = midpoint(a, control), midpoint(control, b)
    local center = midpoint(ac, cb)
    quadratic(points, a, ac, center, depth+1)
    quadratic(points, center, cb, b, depth+1)
end

local function corner(a, b, c, width)
    local incoming, outgoing = distance(a,b), distance(b,c)
    if incoming <= EPSILON or outgoing <= EPSILON then return {entry=b, exit=b} end
    local ux, uz = (b[1]-a[1])/incoming, (b[2]-a[2])/incoming
    local vx, vz = (c[1]-b[1])/outgoing, (c[2]-b[2])/outgoing
    local dot = max(-1, min(1, ux*vx+uz*vz))
    -- A reversal has no regular rounding tangent. Preserve the authored cusp;
    -- the section builder still keeps its offset finite and bounded.
    if dot > 0.999999 or dot < -0.999999 then return {entry=b, exit=b} end
    local sine = abs(ux*vz-uz*vx)
    -- With equal cutbacks d, the quadratic is at most d*sin(turn)/4 from
    -- either source leg. Reserve at most width/2, even for a sparse long L.
    -- Adjacent corners use < half a segment each and therefore cannot overlap.
    local cutback = min(incoming*0.45, outgoing*0.45, 2*width/max(sine, EPSILON))
    return {
        entry={b[1]-ux*cutback, b[2]-uz*cutback},
        control=b,
        exit={b[1]+vx*cutback, b[2]+vz*cutback},
        ux=ux, uz=uz, vx=vx, vz=vz, dot=dot, cutback=cutback,
        legLength=min(incoming,outgoing),
        turn=ux*vz-uz*vx > 0 and 1 or -1,
    }
end

local function smooth(points, width, closed)
    local source = collapse(points, closed)
    if #source < 2 then return source end
    local out, arcs = {}, {}
    local function round(c)
        line(out, c.entry)
        if c.control then
            local first = #out
            quadratic(out, c.entry, c.control, c.exit, 0)
            arcs[#arcs+1] = {first=first, last=#out, corner=c}
        end
    end
    if not closed then
        append(out, source[1])
        for i = 2, #source-1 do
            local c = corner(source[i-1], source[i], source[i+1], width)
            round(c)
        end
        line(out, source[#source])
    else
        local corners = {}
        for i = 1, #source do
            corners[i] = corner(source[(i-2)%#source+1], source[i], source[i%#source+1], width)
        end
        append(out, corners[1].exit)
        for j = 2, #source+1 do
            local c = corners[(j-1)%#source+1]
            round(c)
        end
        -- An exact closing point lets adjacent quads share the same cross
        -- section, rather than drawing a tiny gap or a second end cap.
        if same(out[#out], out[1]) then out[#out] = copy(out[1])
        else out[#out+1] = copy(out[1]) end
    end
    return out, arcs
end

local function sections(points, width, closed)
    local out, half = {}, width*0.5
    local count = closed and #points-1 or #points
    for i = 1, count do
        local p = points[i]
        local before = i > 1 and points[i-1] or (closed and points[count] or nil)
        local after = i < count and points[i+1] or (closed and points[1] or nil)
        local inx, inz, outx, outz
        if before then
            local len = distance(before,p)
            if len > EPSILON then inx, inz = (p[1]-before[1])/len, (p[2]-before[2])/len end
        end
        if after then
            local len = distance(p,after)
            if len > EPSILON then outx, outz = (after[1]-p[1])/len, (after[2]-p[2])/len end
        end
        inx, inz = inx or outx or 1, inz or outz or 0
        outx, outz = outx or inx, outz or inz
        local nx, nz = -inz-outz, inx+outx
        local len = sqrt(nx*nx+nz*nz)
        local scale = half
        if len > EPSILON then
            nx, nz = nx/len, nz/len
            local projected = nx*(-outz)+nz*outx
            scale = min(half/max(projected, EPSILON), half*MITER_LIMIT)
        else
            nx, nz = -outz, outx
        end
        out[i] = {left={p[1]+nx*scale,p[2]+nz*scale}, right={p[1]-nx*scale,p[2]-nz*scale}}
    end
    if closed and out[1] then
        out[#out+1] = {left=copy(out[1].left), right=copy(out[1].right)}
    end
    return out
end

-- A fixed-width offset of a tight curve folds over itself on the inside.
-- Collapse that inner loop to its analytic intersection. The outer edge and
-- centerline remain smooth, and consecutive sections share the same fan pole.
-- This is a stroke join, not narrower centerline sampling or overlapping quads.
local function innerJoins(points, crossSections, arcs, width, closed)
    local half = width*0.5
    for _, arc in ipairs(arcs or {}) do
        local c = arc.corner
        local cosine, sine = sqrt((1+c.dot)*0.5), sqrt((1-c.dot)*0.5)
        local d = c.cutback
        local minimumRadius = d*cosine*cosine/sine
        local wx, wz = (c.ux+c.vx)/(2*cosine), (c.uz+c.vz)/(2*cosine)
        local nx, nz = -wz*c.turn, wx*c.turn
        -- Adaptive intervals are not all equal. Averaging their chord normals
        -- can oscillate across subdivision boundaries even on a regular arc.
        -- Use its exact tangent for every shared cross-section instead.
        for i = arc.first, arc.last do
            local p = points[i]
            local q = ((p[1]-c.control[1])*wx+(p[2]-c.control[2])*wz)/(d*cosine)
            local tx, tz = cosine*wx+sine*q*nx, cosine*wz+sine*q*nz
            local length = sqrt(tx*tx+tz*tz)
            local ox, oz = -tz/length*half, tx/length*half
            crossSections[i] = {left={p[1]+ox,p[2]+oz},right={p[1]-ox,p[2]-oz}}
        end
        if minimumRadius < half then
            local extent, poleHeight
            if d >= half*sine/cosine then
                local k = half*sine/(d*cosine)
                extent = sqrt(max(0, (k*k-cosine*cosine)/(sine*sine)))
                poleHeight = d*sine*(1+extent*extent)*0.5+d*cosine*cosine/sine
            else
                -- The inner offset intersection reaches the straight legs.
                -- Use their shared join, bounded on exceptionally short,
                -- acute source corners instead of extending a long miter.
                extent = 1
                local limit = half*MITER_LIMIT
                poleHeight = min(half/cosine,
                    d*sine+sqrt(max(0,limit*limit-d*d*cosine*cosine)),
                    d*sine*0.5+limit)
            end
            local pole = {c.control[1]+nx*poleHeight, c.control[2]+nz*poleHeight}
            local boundedFallback = half*sine/cosine > c.legLength*0.5
            for i = arc.first, arc.last do
                local p = points[i]
                local q = ((p[1]-c.control[1])*wx+(p[2]-c.control[2])*wz)/(d*cosine)
                if abs(q) <= extent+EPSILON and distance(p,pole) > half*MITER_LIMIT+EPSILON then
                    boundedFallback = true; break
                end
            end
            for i = arc.first, arc.last do
                local p = points[i]
                local q = ((p[1]-c.control[1])*wx+(p[2]-c.control[2])*wz)/(d*cosine)
                if boundedFallback then
                    -- Exceptionally short/acute authored legs cannot contain
                    -- a full-width inner join. Keep the outer edge at full
                    -- width, but keep the inner offset below local curvature
                    -- radius so it advances instead of turning backwards.
                    local tangentSquared = cosine*cosine+sine*sine*q*q
                    local radius = d*tangentSquared*sqrt(tangentSquared)/(cosine*sine)
                    local fraction = min(1, radius*0.85/half)
                    local edge = c.turn > 0 and crossSections[i].left or crossSections[i].right
                    edge[1], edge[2] = p[1]+(edge[1]-p[1])*fraction, p[2]+(edge[2]-p[2])*fraction
                elseif abs(q) <= extent+EPSILON then
                    if c.turn > 0 then crossSections[i].left = copy(pole)
                    else crossSections[i].right = copy(pole) end
                end
            end
        end
    end
    if closed and crossSections[#crossSections] then
        local last = crossSections[#crossSections]
        crossSections[1] = {left=copy(last.left),right=copy(last.right)}
    end
end

-- Each source segment is a graph edge, so a T meeting an interior source
-- vertex is protected exactly like a T made from three separate road pieces.
local function graph(network)
    local nodes, byPosition, edges, seenEdges, sourcePoints = {}, {}, {}, {}, 0
    local function node(p)
        local key = p[1]..':'..p[2]
        local n = byPosition[key]
        if not n then
            n = {x=p[1], z=p[2], edges={}}
            byPosition[key] = n; nodes[#nodes+1] = n
        end
        return n
    end
    for _, road in ipairs(network.roads or {}) do
        sourcePoints = sourcePoints + #road.points
        local width = road.width or 24
        for i = 2, #road.points do
            local a, b = road.points[i-1], road.points[i]
            if not same(a,b) then
                local na, nb = node(a), node(b)
                local low, high = na, nb
                if low.x > high.x or (low.x == high.x and low.z > high.z) then low, high = high, low end
                local key = low.x..':'..low.z..'/'..high.x..':'..high.z..'/'..width
                -- Overlapping OSM ways can repeat the very same segment in
                -- reverse. Render it once, without inventing a two-edge loop
                -- or altering either authoritative source road/identity.
                if not seenEdges[key] then
                    local edge = {a=na, b=nb, width=width}
                    seenEdges[key] = true; edges[#edges+1] = edge
                    na.edges[#na.edges+1] = edge; nb.edges[#nb.edges+1] = edge
                end
            end
        end
    end
    table.sort(nodes, function(a,b) return a.x < b.x or (a.x == b.x and a.z < b.z) end)
    for _, n in ipairs(nodes) do
        table.sort(n.edges, function(a,b)
            local aa, bb = a.a == n and a.b or a.a, b.a == n and b.b or b.a
            if aa.x ~= bb.x then return aa.x < bb.x end
            if aa.z ~= bb.z then return aa.z < bb.z end
            return a.width < b.width
        end)
        n.continuous = #n.edges == 2 and n.edges[1].width == n.edges[2].width
    end
    return nodes, edges, sourcePoints
end

function M.build(network)
    local nodes, edges, sourcePoints = graph(network)
    local result = {strips={}, junctions={}, stats={sourcePoints=sourcePoints, sourceSegments=#edges, displayPoints=0}}
    local visited = {}
    local function walk(start, edge)
        local points, current, first = {{start.x,start.z}}, start, edge
        while edge and not visited[edge] do
            visited[edge] = true
            current = edge.a == current and edge.b or edge.a
            points[#points+1] = {current.x,current.z}
            if current == start or not current.continuous then break end
            edge = current.edges[1] == edge and current.edges[2] or current.edges[1]
        end
        local closed = current == start and start.continuous and #points > 3
        local display, arcs = smooth(points, first.width, closed)
        if #display >= 2 then
            local crossSections = sections(display, first.width, closed)
            innerJoins(display, crossSections, arcs, first.width, closed)
            result.strips[#result.strips+1] = {
                width=first.width, points=display, sections=crossSections, closed=closed,
            }
            result.stats.displayPoints = result.stats.displayPoints + #display
        end
    end
    for _, n in ipairs(nodes) do
        if not n.continuous then
            if #n.edges >= 2 then
                local radius = 0
                for _, edge in ipairs(n.edges) do radius = max(radius, edge.width*0.5) end
                result.junctions[#result.junctions+1] = {x=n.x,z=n.z,radius=radius,degree=#n.edges}
            end
            for _, edge in ipairs(n.edges) do if not visited[edge] then walk(n,edge) end end
        end
    end
    -- Components containing only degree-two vertices are closed loops.
    for _, n in ipairs(nodes) do
        for _, edge in ipairs(n.edges) do if not visited[edge] then walk(n,edge) end end
    end
    result.stats.strips = #result.strips
    result.stats.junctions = #result.junctions
    return result
end

return M
