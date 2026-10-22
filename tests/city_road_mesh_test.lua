-- Pure Lua 5.1 geometry regressions for the existing-map orientation overlay.
-- These assertions describe topology, clearance and ribbon continuity rather
-- than a particular curve implementation or tessellation count.
local mesh = dofile('luaui/widgets_mosaic/include/city_road_mesh.lua')
local roads = dofile('scripts/lib_city_roads.lua')
local EPS = 0.000001
local realRandom = math.random
math.random = function() error('Visual road construction consumed RNG') end

local function finite(x)
    return type(x) == 'number' and x == x and math.abs(x) < math.huge
end

local function distance(a, b)
    return math.sqrt((a[1]-b[1])^2 + (a[2]-b[2])^2)
end

local function same(a, b)
    return distance(a, b) <= EPS
end

local function road(id, name, points, width)
    return {id=id, name=name, width=width or 24, points=points}
end

local function network(list)
    return {schema=1, generation='map', roads=list}
end

local function serialize(value)
    if type(value) ~= 'table' then
        if type(value) == 'number' then return string.format('%.17g', value) end
        return type(value)..':'..tostring(value)
    end
    local keys, result = {}, {}
    for key in pairs(value) do keys[#keys+1] = key end
    table.sort(keys, function(a,b) return tostring(a) < tostring(b) end)
    for _,key in ipairs(keys) do
        result[#result+1] = serialize(key)..'='..serialize(value[key])
    end
    return '{'..table.concat(result, ';')..'}'
end

local function build(source)
    local before = serialize(source)
    local result = mesh.build(source)
    assert(serialize(source) == before, 'Visual smoothing mutated authoritative road data')
    assert(type(result.strips) == 'table' and type(result.junctions) == 'table')
    return result
end

local function reversed(source)
    local list = {}
    for i=#source.roads,1,-1 do
        local r, points = source.roads[i], {}
        for j=#r.points,1,-1 do points[#points+1] = {r.points[j][1],r.points[j][2]} end
        list[#list+1] = road(r.id,r.name,points,r.width)
    end
    return network(list)
end

local function pointKey(p)
    local function quantize(x)
        local n = math.floor(x*1000000+0.5)
        if n == 0 then n = 0 end -- normalize negative zero
        return string.format('%.0f', n)
    end
    return quantize(p[1])..','..quantize(p[2])
end

-- Compare actual geometry regardless of strip ordering, traversal direction,
-- left/right naming or the arbitrary first sample of a closed loop.
local function geometryKey(result)
    local pieces = {}
    for _,s in ipairs(result.strips) do
        local records = {}
        local n = #s.points - (s.closed and 1 or 0)
        for i=1,n do
            local section = s.sections[i]
            local a,b = pointKey(section.left),pointKey(section.right)
            if b < a then a,b = b,a end
            records[i] = pointKey(s.points[i])..'/'..a..'/'..b
        end
        local candidates = {}
        if s.closed then
            local smallest
            for i=1,n do if not smallest or records[i]<smallest then smallest=records[i] end end
            for start=1,n do if records[start] == smallest then
                for _,direction in ipairs({1,-1}) do
                    local ordered = {}
                    for offset=0,n-1 do ordered[#ordered+1] = records[(start-1+offset*direction)%n+1] end
                    candidates[#candidates+1] = table.concat(ordered, ';')
                end
            end end
        else
            candidates[1] = table.concat(records, ';')
            local back = {};for i=n,1,-1 do back[#back+1] = records[i] end
            candidates[2] = table.concat(back, ';')
        end
        table.sort(candidates)
        pieces[#pieces+1] = tostring(s.width)..':'..tostring(not not s.closed)..':'..candidates[1]
    end
    for _,j in ipairs(result.junctions) do
        pieces[#pieces+1] = 'junction:'..pointKey({j.x,j.z})..':'..j.degree..':'..j.radius
    end
    table.sort(pieces)
    return table.concat(pieces, '|')
end

local function maxTurn(points, closed)
    local largest = 0
    local count = #points - (closed and 1 or 0)
    local first, last = closed and 1 or 2, closed and count or count-1
    for i=first,last do
        local a,b,c = points[(i-2)%count+1],points[i],points[i%count+1]
        local ux,uz,vx,vz = b[1]-a[1],b[2]-a[2],c[1]-b[1],c[2]-b[2]
        local lu,lv = math.sqrt(ux*ux+uz*uz),math.sqrt(vx*vx+vz*vz)
        if lu>EPS and lv>EPS then
            local cosine = math.max(-1,math.min(1,(ux*vx+uz*vz)/(lu*lv)))
            largest = math.max(largest,math.acos(cosine)*180/math.pi)
        end
    end
    return largest
end

local function cross(a,b,c)
    return (b[1]-a[1])*(c[2]-a[2])-(b[2]-a[2])*(c[1]-a[1])
end

local function intersects(a,b,c,d)
    return cross(a,b,c)*cross(a,b,d)<-EPS*EPS
        and cross(c,d,a)*cross(c,d,b)<-EPS*EPS
end

local function inTriangle(p,a,b,c)
    local area=cross(a,b,c)
    if math.abs(area)<=EPS then return false end
    local ab,bc,ca=cross(a,b,p),cross(b,c,p),cross(c,a,p)
    return (ab>=-EPS and bc>=-EPS and ca>=-EPS)
        or (ab<=EPS and bc<=EPS and ca<=EPS)
end

local function inQuad(p,a,b)
    return inTriangle(p,a.left,b.left,b.right)
        or inTriangle(p,a.left,b.right,a.right)
end

local function validate(result, requireSimpleRibbon)
    local count, largestTurn, largestMiter = 0,0,0
    for _,s in ipairs(result.strips) do
        assert(finite(s.width) and s.width>0)
        assert(#s.points >= 2 and #s.sections == #s.points, 'Missing ribbon cross-sections')
        largestTurn = math.max(largestTurn,maxTurn(s.points,s.closed))
        for i,p in ipairs(s.points) do
            assert(finite(p[1]) and finite(p[2]), 'Non-finite centreline coordinate')
            local section = s.sections[i]
            for _,edge in ipairs({section.left,section.right}) do
                assert(finite(edge[1]) and finite(edge[2]), 'Non-finite ribbon coordinate')
                largestMiter = math.max(largestMiter,distance(p,edge)/(s.width/2))
                assert(distance(p,edge) <= s.width*0.75+EPS, 'Unbounded miter spike')
            end
            -- Tight inner edges may collapse into a fan. Preserve the outer
            -- half-width, and require the actual emitted faces to cover the
            -- centreline instead of assuming a symmetric offset everywhere.
            assert(math.max(distance(p,section.left),distance(p,section.right))>=s.width/2-EPS,
                'Both ribbon edges collapsed below the intended half-width')
            if i>1 then
                assert(distance(p,s.points[i-1])>EPS, 'Duplicate visual samples create degenerate quads')
                local previous = s.sections[i-1]
                -- A bow-tie quad can retain the expected signed total area.
                -- Check its opposite edges directly, especially where a tight
                -- authored bend has a radius smaller than half the road width.
                assert(not intersects(previous.left,section.left,section.right,previous.right)
                    and not intersects(previous.left,previous.right,section.left,section.right),
                    string.format('Ribbon quad crosses itself on a tight bend at %.3f,%.3f',p[1],p[2]))
                if requireSimpleRibbon then
                    -- The widget joins the same cross-section to both adjacent
                    -- quads: verify those quads do not fold/invert at a bend.
                    local quad = {previous.left,section.left,section.right,previous.right}
                    local twiceArea = 0
                    for q=1,4 do local a,b=quad[q],quad[q%4+1];twiceArea=twiceArea+a[1]*b[2]-b[1]*a[2] end
                    assert(twiceArea < EPS, 'Adjacent ribbon sections inverted at a bend')
                end
            end
            count = count+1
        end
        -- Fan vertices can change the angular ordering of samples around the
        -- inner pole. Test coverage against the actual strip faces nearby,
        -- independent of which source sample generated each face.
        local faces,cellSize={},64
        for i=2,#s.sections do
            local a,b=s.sections[i-1],s.sections[i]
            local minX,maxX,minZ,maxZ=math.huge,-math.huge,math.huge,-math.huge
            for _,p in ipairs({a.left,a.right,b.left,b.right}) do
                minX=math.min(minX,p[1]);maxX=math.max(maxX,p[1])
                minZ=math.min(minZ,p[2]);maxZ=math.max(maxZ,p[2])
            end
            for x=math.floor((minX-EPS)/cellSize),math.floor((maxX+EPS)/cellSize) do
                for z=math.floor((minZ-EPS)/cellSize),math.floor((maxZ+EPS)/cellSize) do
                    local key=x..':'..z;faces[key]=faces[key] or {};faces[key][#faces[key]+1]={a,b}
                end
            end
        end
        for _,p in ipairs(s.points) do
            local covered=false
            for _,face in ipairs(faces[math.floor(p[1]/cellSize)..':'..math.floor(p[2]/cellSize)] or {}) do
                if inQuad(p,face[1],face[2]) then covered=true;break end
            end
            assert(covered,string.format('Ribbon faces leave a centreline gap at %.3f,%.3f',p[1],p[2]))
        end
        if s.closed then
            assert(same(s.points[1],s.points[#s.points]), 'Closed loop has an open centreline seam')
            assert(same(s.sections[1].left,s.sections[#s.sections].left)
                and same(s.sections[1].right,s.sections[#s.sections].right), 'Closed ribbon has a seam')
        end
    end
    for _,j in ipairs(result.junctions) do
        assert(finite(j.x) and finite(j.z) and finite(j.radius) and j.radius>0)
    end
    return count,largestTurn,largestMiter
end

local function pointSegmentDistance(p,a,b)
    local dx,dz = b[1]-a[1],b[2]-a[2]
    local length = dx*dx+dz*dz
    local t = length>0 and math.max(0,math.min(1,((p[1]-a[1])*dx+(p[2]-a[2])*dz)/length)) or 0
    return distance(p,{a[1]+t*dx,a[2]+t*dz})
end

local function withinCorridor(result,source,bound)
    -- Independent uniform-grid index avoids a quadratic full-atlas test.
    local cells, size = {},64
    for _,r in ipairs(source.roads) do for i=2,#r.points do
        local a,b = r.points[i-1],r.points[i]
        for x=math.floor((math.min(a[1],b[1])-bound)/size),math.floor((math.max(a[1],b[1])+bound)/size) do
            for z=math.floor((math.min(a[2],b[2])-bound)/size),math.floor((math.max(a[2],b[2])+bound)/size) do
                local key=x..':'..z;cells[key]=cells[key] or {};cells[key][#cells[key]+1]={a,b}
            end
        end
    end end
    local largest = 0
    for _,s in ipairs(result.strips) do for _,p in ipairs(s.points) do
        local nearby=cells[math.floor(p[1]/size)..':'..math.floor(p[2]/size)] or {}
        local best=math.huge
        for _,segment in ipairs(nearby) do best=math.min(best,pointSegmentDistance(p,segment[1],segment[2])) end
        assert(best<=bound+EPS, 'Smoothing left the source-road clearance corridor')
        largest=math.max(largest,best)
    end end
    return largest
end

local function checkPinned(result,point,degree)
    local node, endpoints = nil,0
    for _,j in ipairs(result.junctions) do if same({j.x,j.z},point) then node=j end end
    assert(node and node.degree==degree, 'Shared junction lost its graph degree or position')
    for _,s in ipairs(result.strips) do
        if same(s.points[1],point) then endpoints=endpoints+1 end
        if same(s.points[#s.points],point) then endpoints=endpoints+1 end
    end
    assert(endpoints==degree, 'Junction arms do not meet at their fixed source vertex')
end

local cornerSource=network({
    road('west','Old name',{{0,0},{1000,0}}),
    road('north','New name',{{1000,0},{1000,1000}}),
})
local corner=build(cornerSource)
assert(#corner.strips==1, 'A name change prevented smooth degree-two continuation')
assert(#corner.junctions==0, 'A simple bend became a junction disc')
local cornerCount,cornerTurn=validate(corner,true)
assert(cornerTurn<20, 'Degree-two 90-degree bend retained a visible sharp corner')
assert(cornerCount>4, 'Corner was not interpolated')
local p,q=corner.strips[1].points[1],corner.strips[1].points[#corner.strips[1].points]
assert((same(p,{0,0}) and same(q,{1000,1000})) or (same(q,{0,0}) and same(p,{1000,1000})), 'Open road endpoints moved')
local cornerDeviation=withinCorridor(corner,cornerSource,12)
assert(geometryKey(corner)==geometryKey(build(reversed(cornerSource))), 'Reversal changed corner geometry')

-- Dhubai's 32-unit raster legs can bend more tightly than a 24-unit ribbon's
-- half-width. Independent offset strips used to form bow-tie quads here even
-- though their signed area and their miter lengths looked valid.
local tightSource=network({road('tight','Tight bend',{{0,0},{32,0},{32,32}})})
local tight=build(tightSource)
validate(tight,true);withinCorridor(tight,tightSource,12)
assert(geometryKey(tight)==geometryKey(build(reversed(tightSource))), 'Tight-corner clipping depends on direction')

-- Two specific failures found while checking the fixed-width fan boundary:
-- a pole can extend beyond a very short source leg, or beyond the allowed
-- offset on an obtuse turn. Both still need a covered, non-crossing ribbon.
for _,case in ipairs({{length=4,turn=90},{length=128,turn=150}}) do
    local length,angle=case.length,math.rad(case.turn)
    local source=network({road('bounded','Bounded corner',{
        {0,0},{length,0},{length+length*math.cos(angle),length*math.sin(angle)},
    })})
    local result=build(source)
    local _,turn=validate(result,true)
    assert(turn<20,'Exceptional fan fallback restored a sharp centreline bend')
    withinCorridor(result,source,12)
    assert(geometryKey(result)==geometryKey(build(reversed(source))),
        'Exceptional short/obtuse corner depends on traversal direction')
end

local tSource=network({
    road('left','Main',{{0,500},{500,500}}),
    road('right','Main',{{500,500},{1000,500}}),
    road('stem','Side',{{500,500},{500,1000}}),
})
local tee=build(tSource);validate(tee,true);checkPinned(tee,{500,500},3)
assert(geometryKey(tee)==geometryKey(build(reversed(tSource))), 'Road ordering changed junction geometry')
local interiorSource=network({
    road('main','Main',{{0,500},{500,500},{1000,500}}),
    road('side','Side',{{500,500},{500,1000}}),
})
local interior=build(interiorSource);validate(interior,true);checkPinned(interior,{500,500},3)

local cycleSource=network({
    road('one','One',{{100,100},{1100,100}}),road('two','Two',{{1100,100},{1100,1100}}),
    road('three','Three',{{1100,1100},{100,1100}}),road('four','Four',{{100,1100},{100,100}}),
})
local cycle=build(cycleSource)
assert(#cycle.strips==1 and cycle.strips[1].closed, 'Degree-two loop was split or opened')
local _,cycleTurn=validate(cycle,true)
assert(cycleTurn<20, 'Closed loop retained a sharp traversal seam')
withinCorridor(cycle,cycleSource,12)
assert(geometryKey(cycle)==geometryKey(build(reversed(cycleSource))), 'Loop geometry depends on traversal origin')

local degenerates=network({
    road('valid','Valid',{{0,0},{0,0},{50,0},{50,0},{100,0}}),
    road('point','Point',{{33,33},{33,33}}),road('single','Single',{{44,44}}),road('empty','Empty',{}),
})
local safe=build(degenerates);validate(safe,true)
assert(#safe.strips==1,'Degenerate source created a phantom road')
assert(#build(network({})).strips==0,'Empty network created geometry')
local overlappingSource=network({
    road('first','First name',{{0,0},{100,0}}),
    road('reverse','Other name',{{100,0},{0,0}}),
})
local overlapping=build(overlappingSource);validate(overlapping,true)
assert(#overlapping.strips==1 and not overlapping.strips[1].closed,
    'Identical reversed source ways created a phantom closed loop')
assert(geometryKey(overlapping)==geometryKey(build(network({overlappingSource.roads[1]}))),
    'Duplicate source ways changed visible road geometry')
local unequalOverlap=build(network({
    road('narrow','Narrow',{{0,0},{100,0}},12),
    road('broad','Broad',{{100,0},{0,0}},48),
}))
assert(#unequalOverlap.strips==2,'Display deduplication discarded a distinct source width')
validate(unequalOverlap,true)
local acute=build(network({road('acute','Acute',{{0,0},{100,0},{1,1},{2,70}})}))
validate(acute,false)

local changingWidth=build(network({road('thin','Thin',{{0,0},{100,0}},12),road('wide','Wide',{{100,0},{200,0}},48)}))
validate(changingWidth,true);checkPinned(changingWidth,{100,0},2)

local atlas=roads.normalize(dofile('scripts/city_roads/dhubai.lua'))
assert(#atlas.roads==319, 'Update the real Dhubai geometry fixture deliberately if the atlas changes')
local addressesBefore=serialize(roads.assign(atlas,{{x=6992,z=1250},{x=7700,z=1500},{x=6300,z=1900}}))
local atlasMesh=build(atlas)
local displayPoints,atlasTurn,atlasMiter=validate(atlasMesh,false)
local sourcePoints=0;for _,r in ipairs(atlas.roads) do sourcePoints=sourcePoints+#r.points end
assert(displayPoints>0 and displayPoints<sourcePoints*16,'Authored-map tessellation grew beyond a sensible cached mesh')
local atlasDeviation=withinCorridor(atlasMesh,atlas,12)
for _,s in ipairs(atlasMesh.strips) do for _,p in ipairs(s.points) do
    assert(p[1]>=-EPS and p[1]<=8192+EPS and p[2]>=-EPS and p[2]<=8192+EPS,'Curve overshot authored map bounds')
end end
assert(addressesBefore==serialize(roads.assign(atlas,{{x=6992,z=1250},{x=7700,z=1500},{x=6300,z=1900}})), 'Visual rebuild changed existing house addresses')
assert(geometryKey(atlasMesh)==geometryKey(build(reversed(atlas))), 'Dhubai geometry changes with road order or direction')

-- Previous renderer's two fixed corner-cutting passes, retained only as a
-- measurement reference. Regression acceptance above uses independent bounds.
local function previousCurve(points)
    for pass=1,2 do
        local nextPoints={points[1]}
        for i=2,#points do
            local a,b=points[i-1],points[i]
            if distance(a,b)>0.01 then
                nextPoints[#nextPoints+1]={0.75*a[1]+0.25*b[1],0.75*a[2]+0.25*b[2]}
                nextPoints[#nextPoints+1]={0.25*a[1]+0.75*b[1],0.25*a[2]+0.75*b[2]}
            end
        end
        nextPoints[#nextPoints+1]=points[#points];points=nextPoints
    end
    return points
end
local oldPoints,oldTurn=0,0
for _,r in ipairs(atlas.roads) do
    local points=#r.points<3 and r.points or previousCurve(r.points)
    oldPoints=oldPoints+#points;oldTurn=math.max(oldTurn,maxTurn(points,false))
end
math.random=realRandom
print(string.format('Dhubai: %d roads, %d source points; %d display points (previous %d), %d strips, %d junctions',#atlas.roads,sourcePoints,displayPoints,oldPoints,#atlasMesh.strips,#atlasMesh.junctions))
print(string.format('Geometry: maximum source deviation %.3f / 12 world units; maximum miter %.3fx half-width; maximum sampled turn %.3f degrees (previous %.3f)',atlasDeviation,atlasMiter,atlasTurn,oldTurn))
print(string.format('Sparse degree-two turn: %.3f degrees per sample (source 90); deviation %.3f / 12 world units; cycle seam max turn %.3f',cornerTurn,cornerDeviation,cycleTurn))
print('PASS: bounded visual road interpolation, connected bends, pinned junctions, closed seams, stable addresses and deterministic Dhubai geometry')
