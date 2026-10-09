-- Shared by MOSAIC and CityLights. Pure Lua 5.1; no engine RNG or unit IDs.
local M = {SCHEMA = 1}
local floor, sqrt = math.floor, math.sqrt
function M.hash(s)
    local h = 0
    for i = 1, #s do h = (h * 131 + s:byte(i)) % 2147483647 end
    return h
end
local function integer(v)
    assert(type(v) == 'number' and v == v and math.abs(v) < 100000000, 'Invalid road coordinate')
    return floor(v + 0.5)
end
function M.clean(s)
    s=tostring(s or ''):gsub('[%z\1-\31\127]', '')
    local n=math.min(160,#s)
    while n>0 and s:byte(n+1) and s:byte(n+1)>=128 and s:byte(n+1)<192 do n=n-1 end
    return s:sub(1,n)
end
function M.key(x, z) return integer(x) .. ':' .. integer(z) end
local names = {
    western = {'Oak Street', 'River Street', 'Market Street', 'Garden Street', 'Station Road', 'Park Avenue'},
    arabic = {'Al Noor Street', 'Al Salam Street', 'Al Quds Street', 'Al Amal Street', 'Al Zahra Street'},
    asian = {'Sakura Street', 'Jade Street', 'Lotus Street', 'Bamboo Street', 'Sunrise Street'},
    international = {'Market Street', 'River Street', 'Garden Street', 'Station Road', 'Park Avenue'},
}
function M.name(id, culture, seed)
    local pool = names[culture] or names.international
    return pool[(M.hash(tostring(seed) .. ':' .. id) % #pool) + 1] .. ' ' .. id
end
-- Canonical point direction makes odd/even sides and stationing independent
-- of OSM way direction. Different ways keep distinct IDs even with equal names.
function M.normalize(network)
    assert(network.schema == M.SCHEMA and type(network.roads) == 'table', 'Unsupported city roads')
    assert(#network.roads <= 4096, 'Too many city roads')
    local out = {schema=M.SCHEMA, generation=network.generation, roads={}}
    local seen, total = {}, 0
    for _, r in ipairs(network.roads) do
        local id = M.clean(r.id)
        assert(id ~= '' and not seen[id], 'Duplicate road ID'); seen[id] = true
        local points = {}
        for _, p in ipairs(r.points) do
            local q = {integer(p[1]), integer(p[2])}
            local prev = points[#points]
            if not prev or prev[1] ~= q[1] or prev[2] ~= q[2] then points[#points+1] = q end
        end
        total = total + #points; assert(total <= 65536, 'Too many road points')
        if #points >= 2 then
            local a, b = points[1], points[#points]
            if a[1] > b[1] or (a[1] == b[1] and a[2] > b[2]) then
                local reverse = {}; for i=#points,1,-1 do reverse[#reverse+1] = points[i] end; points=reverse
            end
            out.roads[#out.roads+1] = {id=id, name=M.clean(r.name), width=math.max(1, math.min(128, integer(r.width or 25))), points=points}
        end
    end
    table.sort(out.roads, function(a,b) return a.id < b.id end)
    -- Connected OSM ways with the same name are one address street. Separate
    -- streets sharing a display name remain separate. Endpoint/vertex keys and
    -- smallest source ID resolve components without depending on input order.
    local parent,vertices,bounds={},{},{}
    local function root(i) while parent[i]~=i do i=parent[i] end;return i end
    for i,r in ipairs(out.roads) do
        parent[i]=i
        if out.generation=='map' then
            for _,p in ipairs(r.points) do
                local key=r.name..'\0'..M.key(p[1],p[2]);local other=vertices[key]
                if other then local a,b=root(i),root(other);parent[math.max(a,b)]=math.min(a,b) else vertices[key]=i end
            end
        end
    end
    for i,r in ipairs(out.roads) do
        local id=root(i);local b=bounds[id] or {math.huge,math.huge,-math.huge,-math.huge};bounds[id]=b
        for _,p in ipairs(r.points) do b[1]=math.min(b[1],p[1]);b[2]=math.min(b[2],p[2]);b[3]=math.max(b[3],p[1]);b[4]=math.max(b[4],p[2]) end
    end
    for i,r in ipairs(out.roads) do
        local id=root(i);local b=bounds[id];r.street_id=out.roads[id].id;r.street_axis=b[3]-b[1]>=b[4]-b[2] and 1 or 2
    end
    return out
end
function M.grid(sizeX, sizeZ, spacingX, spacingZ, width, culture, seed)
    local roads = {}
    -- These are the lanes excluded by the inner-city (2*cursor-1)%4 grid.
    for axis=1,2 do
        local extent, spacing = axis==1 and sizeX or sizeZ, axis==1 and spacingX or spacingZ
        for i=0,floor(extent/(2*spacing)) do
            local p = (2*i+0.5)*spacing
            if p < extent then
                local id = (axis==1 and 'X' or 'Z') .. string.format('%04d', i)
                roads[#roads+1] = {id=id, name=M.name(id,culture,seed), width=width,
                    points=axis==1 and {{p,0},{p,sizeZ}} or {{0,p},{sizeX,p}}}
            end
        end
    end
    return M.normalize({schema=1,generation='game',roads=roads})
end
function M.nearest(network, x, z, street)
    local best
    for _, r in ipairs(network.roads) do
        local along = 0
        for i=2,#r.points do
            local a,b=r.points[i-1],r.points[i]
            local dx,dz=b[1]-a[1],b[2]-a[2]; local length=sqrt(dx*dx+dz*dz)
            local t=math.max(0,math.min(1,((x-a[1])*dx+(z-a[2])*dz)/(length*length)))
            local ex,ez=x-a[1]-dx*t,z-a[2]-dz*t; local distance=ex*ex+ez*ez
            local preferred=street and street==r.name or false
            if not best or (preferred and not best.preferred) or (preferred==best.preferred and distance<best.distance) then
                best={road=r, distance=distance, along=along+t*length, side=dx*(z-a[2])-dz*(x-a[1])>=0 and 1 or 2, preferred=preferred}
            end
            along=along+length
        end
    end
    return best
end
-- Initial plot batch is sorted geometrically, never by unit creation order.
-- Imported numbers win; generated numbers skip every occupied odd/even number.
function M.assign(network, plots)
    local sorted, groups, result = {}, {}, {}
    for _,p in ipairs(plots) do sorted[#sorted+1]=p end
    table.sort(sorted,function(a,b) return M.key(a.x,a.z)<M.key(b.x,b.z) end)
    for _,p in ipairs(sorted) do
        local key=M.key(p.x,p.z); assert(not result[key], 'Duplicate city plot')
        local street=M.clean(p.street_name); local near=M.nearest(network,p.x,p.z,street~='' and street or nil)
        local id=near and near.road.street_id or 'unmapped'
        -- An addr:street without corresponding geometry remains authoritative.
        if street~='' and (not near or near.road.name~=street) then id='address/'..street end
        local name=street~='' and street or near and near.road.name or 'Unmapped Street'
        local number=M.clean(p.house_number)
        local a={plot_key=key,street_id=id,street_name=name,house_number=number~='' and number or nil,
            number_source=number~='' and 'osm' or 'generated', generation=network.generation}
        result[key]=a
        local group=groups[id] or {entries={},used={}}; groups[id]=group
        if a.house_number then group.used[a.house_number]=true end
        group.entries[#group.entries+1]={address=a,along=near and (near.road.street_axis==1 and p.x or p.z) or p.x,side=near and near.side or 1,key=key}
    end
    for _,g in pairs(groups) do
        table.sort(g.entries,function(a,b) return a.along==b.along and a.key<b.key or a.along<b.along end)
        local nextNumber={1,2}
        for _,e in ipairs(g.entries) do
            if not e.address.house_number then
                local n=nextNumber[e.side]
                while g.used[tostring(n)] do n=n+2 end
                e.address.house_number=tostring(n); g.used[tostring(n)]=true; nextNumber[e.side]=n+2
            end
        end
    end
    return result
end
-- Data-only wire format: UTF-8 names/IDs hex encoded, integer geometry.
local function hex(s) return (s:gsub('.',function(c) return string.format('%02x',c:byte()) end)) end
local function unhex(s)
    assert(#s%2==0 and not s:find('[^0-9a-f]'), 'Invalid road text')
    return (s:gsub('..',function(c) return string.char(tonumber(c,16)) end))
end
function M.encode(network)
    local lines={'1|'..network.generation}
    for _,r in ipairs(network.roads) do
        local points={};for _,p in ipairs(r.points) do points[#points+1]=p[1]..','..p[2] end
        lines[#lines+1]=hex(r.id)..'|'..hex(r.name)..'|'..r.width..'|'..table.concat(points,';')
    end
    return table.concat(lines,'\n')
end
function M.decode(data)
    assert(#data<=2000000, 'City roads too large')
    local generation=data:match('^1|(%a+)\n') or data:match('^1|(%a+)$')
    assert(generation=='map' or generation=='game','Invalid city road header')
    local roads={}
    for line in data:gmatch('[^\n]+') do
        if line:sub(1,2)~='1|' then
            local id,name,width,coords=line:match('^([0-9a-f]+)|([0-9a-f]*)|(%d+)|([%d,;%-]+)$')
            assert(id,'Invalid city road record')
            local points={};for x,z in coords:gmatch('(%-?%d+),(%-?%d+)') do points[#points+1]={tonumber(x),tonumber(z)} end
            roads[#roads+1]={id=unhex(id),name=unhex(name),width=tonumber(width),points=points}
        end
    end
    return M.normalize({schema=1,generation=generation,roads=roads})
end
return M
