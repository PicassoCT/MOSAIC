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
-- Map-fixed spoken sectors: letters west-to-east, numbers north-to-south.
-- Camera rotation and zoom never change the reference.
M.SECTOR_SIZE=1024
function M.sector(x,z,sizeX,sizeZ)
    local column=floor(math.max(0,math.min(sizeX-1,x))/M.SECTOR_SIZE)+1
    local row=floor(math.max(0,math.min(sizeZ-1,z))/M.SECTOR_SIZE)+1
    local letters,n='',column
    repeat n=n-1;letters=string.char(65+n%26)..letters;n=floor(n/26) until n==0
    return letters..row,letters,row
end
local names = {
    western = {'Oak Street', 'River Street', 'Market Street', 'Garden Street', 'Station Road', 'Park Avenue'},
    arabic = {'Al Noor Street', 'Al Salam Street', 'Al Quds Street', 'Al Amal Street', 'Al Zahra Street'},
    asian = {'Sakura Street', 'Jade Street', 'Lotus Street', 'Bamboo Street', 'Sunrise Street'},
    international = {'Market Street', 'River Street', 'Garden Street', 'Station Road', 'Park Avenue'},
}
function M.name(id, culture, seed)
    local pool = names[culture] or names.international
    local roots = {'Cedar', 'Palm', 'Olive', 'Harbour', 'Canal', 'Old Market', 'Jasmine', 'Cypress', 'Acacia', 'Saffron', 'Silver', 'Fountain', 'Lantern', 'Orchard', 'Willow', 'Temple', 'Crescent', 'Rose', 'Amber', 'Juniper', 'Silk', 'Copper', 'Westgate', 'Eastgate', 'Citadel', 'Oasis', 'Fig', 'Myrtle', 'Hill', 'Meadow', 'Beacon', 'Pearl'}
    local h=M.hash(tostring(seed)..':'..id)
    if h % 8 == 0 then return pool[(floor(h/8) % #pool)+1] end
    if culture=='arabic' then roots={'Al Noor','Al Salam','Al Quds','Al Amal','Al Zahra','Al Nakheel','Al Waha','Al Bahr','Al Souq','Al Yasmin','Al Ward','Al Safa','Al Rimal','Al Mina','Al Bustan','Al Qamar','Al Shams','Al Zaytun','Al Lulu','Al Nahr','Al Fajr','Al Sahl','Al Jabal','Al Rayan','Al Bahar','Al Rawda','Al Manar','Al Hamra','Al Khaleej','Al Madina','Al Hilal','Al Sadr'} end
    local endings={'Street','Road','Lane','Walk','Way','Avenue','Crescent','Terrace'}
    return roots[(floor(h/8)%#roots)+1]..' '..endings[(h%#endings)+1]
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
        do -- connected same-name pieces share one address street
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
-- Extract a centreline graph from a finite street/clearance mask. Zhang-Suen
-- thinning preserves junctions and loops; stable raster traversal sets IDs.
-- This is run once in synced Lua, never in the renderer or engine RNG.
function M.trace(mask, nx, nz, step, culture, seed)
    local function at(x,z) return x>0 and x<=nx and z>0 and z<=nz and mask[(z-1)*nx+x] and 1 or 0 end
    for pass=1,256 do
        local changed=false
        for phase=1,2 do
            local remove={}
            for z=2,nz-1 do for x=2,nx-1 do
                local k=(z-1)*nx+x
                if mask[k] then
                    local p={at(x,z-1),at(x+1,z-1),at(x+1,z),at(x+1,z+1),at(x,z+1),at(x-1,z+1),at(x-1,z),at(x-1,z-1)}
                    local n,a=0,0
                    for i=1,8 do n=n+p[i];if p[i]==0 and p[i%8+1]==1 then a=a+1 end end
                    local b,c
                    if phase==1 then b=p[1]*p[3]*p[5];c=p[3]*p[5]*p[7]
                    else b=p[1]*p[3]*p[7];c=p[1]*p[5]*p[7] end
                    if n>=2 and n<=6 and a==1 and b==0 and c==0 then remove[#remove+1]=k end
                end
            end end
            if #remove>0 then changed=true;for _,k in ipairs(remove) do mask[k]=nil end end
        end
        if not changed then break end
    end
    local function neighbours(k)
        local x,z=(k-1)%nx+1,floor((k-1)/nx)+1;local list={}
        for dz=-1,1 do for dx=-1,1 do
            if (dx~=0 or dz~=0) and at(x+dx,z+dz)==1 then
                -- Diagonals only when there is no cardinal connection. This
                -- avoids triangular junctions and one-cell spurious branches.
                if dx==0 or dz==0 or (at(x+dx,z)==0 and at(x,z+dz)==0) then list[#list+1]=(z+dz-1)*nx+x+dx end
            end
        end end
        table.sort(list);return list
    end
    local adjacency,keys={},{}
    for k=1,nx*nz do if mask[k] then keys[#keys+1]=k;adjacency[k]=neighbours(k) end end
    local visited,lines={},{}
    local function edge(a,b) return math.min(a,b)..':'..math.max(a,b) end
    local function walk(start,next)
        local chain={start};local prev,k=start,next;visited[edge(prev,k)]=true
        while true do
            chain[#chain+1]=k
            local ns=adjacency[k];if #ns~=2 or k==start then break end
            local following=ns[1]==prev and ns[2] or ns[1]
            if visited[edge(k,following)] then break end
            visited[edge(k,following)]=true;prev,k=k,following
        end
        if #chain>=4 then
            local points={}
            for _,cell in ipairs(chain) do points[#points+1]={((cell-1)%nx+0.5)*step,(floor((cell-1)/nx)+0.5)*step} end
            -- Remove staircase noise without moving the endpoints/junctions.
            -- One local B-spline pass stays within one raster cell of source.
            local smooth={points[1]}
            for i=2,#points-1 do
                smooth[#smooth+1]={integer((points[i-1][1]+4*points[i][1]+points[i+1][1])/6),integer((points[i-1][2]+4*points[i][2]+points[i+1][2])/6)}
            end
            smooth[#smooth+1]=points[#points];lines[#lines+1]={id='lane/'..start..'/'..next,width=math.min(24,step),points=smooth}
        end
    end
    for _,k in ipairs(keys) do if #adjacency[k]~=2 then for _,n in ipairs(adjacency[k]) do if not visited[edge(k,n)] then walk(k,n) end end end end
    for _,k in ipairs(keys) do for _,n in ipairs(adjacency[k]) do if not visited[edge(k,n)] then walk(k,n) end end end
    table.sort(lines,function(a,b) return a.id<b.id end)
    -- Continue a street through a junction using the straightest compatible
    -- tangent pair. Names describe routes, not every little graph edge.
    local parent,ends={},{}
    local function root(i) while parent[i]~=i do i=parent[i] end;return i end
    for i,r in ipairs(lines) do
        parent[i]=i
        for side=1,2 do
            local p=side==1 and r.points[1] or r.points[#r.points]
            local q=side==1 and r.points[math.min(4,#r.points)] or r.points[math.max(1,#r.points-3)]
            local dx,dz=q[1]-p[1],q[2]-p[2];local length=sqrt(dx*dx+dz*dz)
            if length>0 then
                local key=M.key(p[1],p[2]);ends[key]=ends[key] or {}
                ends[key][#ends[key]+1]={i=i,dx=dx/length,dz=dz/length}
            end
        end
    end
    local junctions={};for key in pairs(ends) do junctions[#junctions+1]=key end;table.sort(junctions)
    for _,key in ipairs(junctions) do
        local e=ends[key];local pairs={}
        for i=1,#e do for j=i+1,#e do
            local dot=e[i].dx*e[j].dx+e[i].dz*e[j].dz
            if dot<-0.65 then pairs[#pairs+1]={a=i,b=j,d=dot} end
        end end
        table.sort(pairs,function(a,b) if a.d~=b.d then return a.d<b.d end;if a.a~=b.a then return a.a<b.a end;return a.b<b.b end)
        local taken={}
        for _,pair in ipairs(pairs) do
            if not taken[pair.a] and not taken[pair.b] then
                taken[pair.a]=true;taken[pair.b]=true
                local a,b=root(e[pair.a].i),root(e[pair.b].i);parent[math.max(a,b)]=math.min(a,b)
            end
        end
    end
    local used,assigned={},{}
    for i,r in ipairs(lines) do
        local component=root(i)
        if not assigned[component] then
            local salt=0;local id=lines[component].id;local name=M.name(id,culture,seed)
            while used[name] and salt<512 do salt=salt+1;name=M.name(id..':'..salt,culture,seed) end
            assigned[component]=name;used[name]=true
        end
        r.name=assigned[component]
    end
    return M.normalize({schema=1,generation='game',roads=lines})
end
-- Infer only occupied neighbourhoods, not full-map grid lines. Raster clearance
-- follows irregular blocks and terrain; outer districts keep their large gaps.
function M.infer(plots,sizeX,sizeZ,blocked,culture,seed,radius)
    local step=64;local nx,nz=floor(sizeX/step),floor(sizeZ/step)
    local mask,occupied={},{};radius=radius or 144
    local sorted={};for _,p in ipairs(plots) do sorted[#sorted+1]=p end
    table.sort(sorted,function(a,b) return M.key(a.x,a.z)<M.key(b.x,b.z) end)
    for _,p in ipairs(sorted) do
        local reach=radius+320
        for z=math.max(1,floor((p.z-reach)/step)),math.min(nz,math.ceil((p.z+reach)/step)) do
            for x=math.max(1,floor((p.x-reach)/step)),math.min(nx,math.ceil((p.x+reach)/step)) do
                local dx,dz=math.abs((x-0.5)*step-p.x),math.abs((z-0.5)*step-p.z);local k=(z-1)*nx+x
                if dx<=radius and dz<=radius then occupied[k]=true
                elseif dx*dx+dz*dz<=reach*reach then mask[k]=true end
            end
        end
    end
    for k=1,nx*nz do
        if mask[k] and (occupied[k] or (blocked and blocked(((k-1)%nx+0.5)*step,(floor((k-1)/nx)+0.5)*step))) then mask[k]=nil end
    end
    return M.trace(mask,nx,nz,step,culture,seed)
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
