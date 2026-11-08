-- One bounded placement pass at assembly time. No per-frame work or global RNG.
local catalogue = VFS.Include('scripts/house_asian_placeable_catalog.lua')
local M = {catalogue = catalogue, walkwayWidth = 12, pedestrianWidth = 2.5, roadWidth = 25}
local function hash(seed, text)
    local n = seed % 2147483647
    for i=1,#text do n=(n*31+text:byte(i))%2147483647 end
    n=(n*48271)%2147483647
    return (n*48271)%2147483647
end
local function overlap(a,b,gap)
    return a.minX < b.maxX+gap and a.maxX > b.minX-gap
        and a.minZ < b.maxZ+gap and a.maxZ > b.minZ-gap
end
M.overlap = overlap
local policies = {
    public={front=true}, market={front=true}, service={service=true},
    clutter={service=true}, barrier={service=true}, lighting={},
}
-- Cosmetic siting only: these tests never register movement blockers.
function M.roadOverlap(box,road)
    local lo,hi=0,1
    for _,axis in ipairs({'X','Z'}) do
        local a,b=road['a'..axis],road['b'..axis]
        local minimum,maximum=box['min'..axis]-road.width/2,box['max'..axis]+road.width/2
        local delta=b-a
        if math.abs(delta)<1e-8 then
            if a<minimum or a>maximum then return false end
        else
            local enter,leave=(minimum-a)/delta,(maximum-a)/delta
            if enter>leave then enter,leave=leave,enter end
            lo,hi=math.max(lo,enter),math.min(hi,leave)
            if lo>hi then return false end
        end
    end
    return true
end
function M.streetEdges(options,side,along,half)
    local near=half+(options.walkwayWidth or M.walkwayWidth)/catalogue.scale
    local far=near+(options.roadWidth or M.roadWidth)/catalogue.scale
    local closest
    for _,road in ipairs(options.roads or {}) do
        local a,b,normalA,normalB
        if side%2==1 then a,b,normalA,normalB=road.aX,road.bX,road.aZ,road.bZ
        else a,b,normalA,normalB=road.aZ,road.bZ,road.aX,road.bX end
        if math.abs(b-a)>1e-8 then
            local t=(along-a)/(b-a)
            if t>=0 and t<=1 then
                local sign=side<=2 and 1 or -1
                local distance=(normalA+t*(normalB-normalA))*sign
                local cosine=math.abs(b-a)/math.sqrt((b-a)^2+(normalB-normalA)^2)
                if distance>half and cosine>.05 and (not closest or distance<closest) then
                    closest=distance
                    local thickness=road.width/(2*cosine)
                    near,far=distance-thickness,distance+thickness
                end
            end
        end
    end
    return near,far
end
-- Convert the published road centre lines into this house's source coordinates.
function M.localRoads(network,convert,radius)
    local result={}
    for _,road in ipairs((network or {}).roads or {}) do
        for i=2,#road.points do
            local a,b=road.points[i-1],road.points[i]
            local ax,az=convert(a[1],a[2]);local bx,bz=convert(b[1],b[2])
            local width=(road.width or M.roadWidth)/catalogue.scale
            local limit=radius+width/2
            if math.max(ax,bx)>=-limit and math.min(ax,bx)<=limit
                and math.max(az,bz)>=-limit and math.min(az,bz)<=limit then
                result[#result+1]={aX=ax,aZ=az,bX=bx,bZ=bz,width=width}
            end
        end
    end
    return result
end
-- Facades: +Z, +X, -Z, -X. Source meshes face +Z at Turn(Z,0).
local yaw = {0,6,4,2}
local stations = {-.65,-.3,.3,.65}

function M.plan(options)
    local seed, cell = options.seed or 1, options.cell or 770
    local half = options.halfExtent or cell*3 + 2/catalogue.scale
    local cornerClearance, separation = cell*.45, cell*.16
    local front = 1 + hash(seed,'front')%4
    local service = (front+1)%4+1
    local pool = {}
    for name,id in pairs(options.pieces) do
        if catalogue.pieces[name] then pool[#pool+1]={name=name,id=id} end
    end
    table.sort(pool,function(a,b)
        local ha,hb=hash(seed,a.name),hash(seed,b.name)
        return ha==hb and a.name<b.name or ha<hb
    end)
    local result,sideCount = {},{0,0,0,0}
    local requested = math.min(options.count or (1+hash(seed,'count')%5),#pool)
    for _,item in ipairs(pool) do
        if #result >= requested then break end
        local prop = catalogue.pieces[item.name]
        local policy = policies[prop.category]
        local candidates = {}
        for side=1,4 do
            local orientation = yaw[side]
            -- Long lamps, barriers and wrecks run along, not across, the street.
            local p0=prop.poses[1]
            if (prop.category=='lighting' or prop.category=='barrier' or prop.category=='clutter')
                and p0.max[3]-p0.min[3] > p0.max[1]-p0.min[1] then
                orientation=(orientation+2)%8
            end
            if prop.category=='clutter' then
                orientation=(orientation+hash(seed,item.name..':tilt')%2)%8
            end
            local pose=prop.poses[orientation+1]
            local low,high=pose.footMin,pose.footMax
            local hx,hz=(high[1]-low[1])/2,(high[3]-low[3])/2
            local tangentHalf = side%2==1 and hx or hz
            local limit = half-cornerClearance-tangentHalf
            if limit>0 then
                for station,t in ipairs(stations) do
                    local jitter=(hash(seed,item.name..':'..side..':'..station)%1000/999-.5)*cell*.12
                    local along=math.max(-limit,math.min(limit,half*t+jitter))
                    -- Leave the middle of every facade open as an approach lane.
                    if math.abs(along)-tangentHalf >= cell*.22 then
                        local near,far=M.streetEdges(options,side,along,half)
                        local depth=side%2==1 and hz or hx
                        local pedestrian=(options.pedestrianWidth or M.pedestrianWidth)/catalogue.scale
                        local walkwayEnd=math.min(near,half+(options.walkwayWidth or M.walkwayWidth)/catalogue.scale)
                        local small=prop.walkway and 2*depth+pedestrian <= walkwayEnd-half
                        local curbside=small and (prop.category=='lighting' or prop.category=='barrier')
                        local distance=small and (curbside and walkwayEnd-depth or half+depth)
                            or far+2/catalogue.scale+depth
                        local x,z
                        if side==1 then x,z=along,distance
                        elseif side==2 then x,z=distance,along
                        elseif side==3 then x,z=along,-distance
                        else x,z=-distance,along end
                        local c={name=item.name,id=item.id,category=prop.category,side=side,
                            x=x,z=z,rotation=orientation*math.pi/4, zone=small and "walkway" or "far-curb",
                            roadNear=near,roadFar=far, facade=half, curbside=curbside,
                            moveX=x-(low[1]+high[1])/2,
                            moveZ=z-(low[3]+high[3])/2,moveY=-pose.min[2],
                            minX=x-hx,maxX=x+hx,minZ=z-hz,maxZ=z+hz}
                        local clear=true
                        for _,road in ipairs(options.roads or {}) do
                            if M.roadOverlap(c,road) then clear=false;break end
                        end
                        for _,other in ipairs(result) do if overlap(c,other,separation) then clear=false;break end end
                        if clear then
                            local preferred=policy.front and front or policy.service and service
                            local distance=preferred and math.min((side-preferred)%4,(preferred-side)%4) or 0
                            -- Spread before reusing a side; function provides softer zoning.
                            c.score=sideCount[side]*10+distance*2+hash(seed,item.name..':score:'..side..':'..station)%1000/1000
                            candidates[#candidates+1]=c
                        end
                    end
                end
            end
        end
        table.sort(candidates,function(a,b)
            if a.score~=b.score then return a.score<b.score end
            if a.side~=b.side then return a.side<b.side end
            return a.x==b.x and a.z<b.z or a.x<b.x
        end)
        for _,c in ipairs(candidates) do
            if not options.accept or options.accept(c) then
                result[#result+1]=c;sideCount[c.side]=sideCount[c.side]+1
                break
            end
        end
    end
    return result
end
return M
