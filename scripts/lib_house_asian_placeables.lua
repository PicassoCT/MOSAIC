-- Two bounded placement passes at assembly time. No per-frame work or global RNG.
local variation = VFS.Include('scripts/lib_house_placeable_variation.lua')
local function withCatalogue(catalogue)
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
local forecourtStations = {0,-.65,.65,-1,1}
local fallbackStations = {0,-.35,.35,-.7,.7,-1,1}

-- A large ground prop has a footprint at least as wide as the walkway.
-- Height alone must not let a thin lamp satisfy the large-prop requirement.
function M.isLarge(name)
    local prop = catalogue.pieces[name]
    if not prop or prop.walkway then return false end
    local pose = prop.poses[1]
    return math.max(pose.footMax[1]-pose.footMin[1],
        pose.footMax[3]-pose.footMin[3])*catalogue.scale >= M.walkwayWidth
end

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
    if options.selection then
        variation.order(pool, catalogue, options.selection.seed, options.selection.getUses)
    else
        table.sort(pool,function(a,b)
            local ha,hb=hash(seed,a.name),hash(seed,b.name)
            return ha==hb and a.name<b.name or ha<hb
        end)
    end
    local result,sideCount,used,usedTypes = {},{0,0,0,0},{},{}
    local minimum = options.minimum or (2+hash(seed,'minimum')%2)
    local requested = math.min(options.count or math.max(minimum,1+hash(seed,'count')%5),#pool)
    minimum = math.min(minimum,requested)
    local hasLarge,needsLarge = false,false
    for _,item in ipairs(pool) do if M.isLarge(item.name) then needsLarge=true;break end end
    local function tryItem(item,relaxed)
        if used[item.id] or (item.typeKey and usedTypes[item.typeKey]) then return false end
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
            -- Oversized authored plazas/tanks use an open forecourt across the
            -- road. Do not silently remove them because a facade slot is smaller.
            local forecourt = catalogue.largeForecourts and tangentHalf > half*.38
            if limit>0 or forecourt or relaxed then
                for station,t in ipairs(relaxed and fallbackStations or (forecourt and forecourtStations or stations)) do
                    local jitter=(hash(seed,item.name..':'..side..':'..station)%1000/999-.5)*cell*.12
                    local along=(forecourt or relaxed) and half*t or math.max(-limit,math.min(limit,half*t+jitter))
                    -- Leave the middle of every facade open as an approach lane.
                    if relaxed or forecourt or math.abs(along)-tangentHalf >= cell*.22 then
                        local near,far=M.streetEdges(options,side,along,half)
                        local depth=side%2==1 and hz or hx
                        local pedestrian=(options.pedestrianWidth or M.pedestrianWidth)/catalogue.scale
                        local walkwayEnd=math.min(near,half+(options.walkwayWidth or M.walkwayWidth)/catalogue.scale)
                        local small=not forecourt and prop.walkway and 2*depth+pedestrian <= walkwayEnd-half
                        local curbside=small and (prop.category=='lighting' or prop.category=='barrier')
                        local distance=small and (curbside and walkwayEnd-depth or half+depth)
                            or far+2/catalogue.scale+depth
                        -- Fall back towards the house, including the street,
                        -- before using a more distant dry site. Keep the entire
                        -- footprint outside the selected building's bounds.
                        local distances=relaxed and {half+depth+2/catalogue.scale,
                            half+depth+cell*.5,half+depth+cell,
                            math.max(distance,half+depth+2/catalogue.scale)} or {distance}
                        for ring,distance in ipairs(distances) do
                            local x,z
                            if side==1 then x,z=along,distance
                            elseif side==2 then x,z=distance,along
                            elseif side==3 then x,z=along,-distance
                            else x,z=-distance,along end
                            local c={name=item.name,id=item.id,category=prop.category,side=side,
                                x=x,z=z,rotation=orientation*math.pi/4, zone=relaxed and "fallback" or (small and "walkway" or "far-curb"),
                                relaxed=relaxed, large=M.isLarge(item.name),
                                roadNear=near,roadFar=far, facade=half, curbside=curbside,
                                moveX=x-(low[1]+high[1])/2,
                                moveZ=z-(low[3]+high[3])/2,moveY=-pose.min[2],
                                minX=x-hx,maxX=x+hx,minZ=z-hz,maxZ=z+hz}
                            local clear=true
                            local onRoad=false
                            for _,road in ipairs(options.roads or {}) do
                                if M.roadOverlap(c,road) then onRoad=true;break end
                            end
                            if onRoad and not relaxed then clear=false end
                            for _,other in ipairs(result) do
                                if overlap(c,other,relaxed and 0 or separation) then clear=false;break end
                            end
                            if clear then
                                local preferred=policy.front and front or policy.service and service
                                local distance=preferred and math.min((side-preferred)%4,(preferred-side)%4) or 0
                                -- Spread before reusing a side; function provides softer zoning.
                                c.score=sideCount[side]*10+distance*2+hash(seed,item.name..':score:'..side..':'..station)%1000/1000
                                -- Preserve the centred forecourt when it fits, but
                                -- try offsets before dropping a large authored prop.
                                if forecourt and station>1 and not relaxed then c.score=c.score+100 end
                                if relaxed then c.score=c.score+(onRoad and 1000 or 0)+ring*.1 end
                                candidates[#candidates+1]=c
                            end
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
                used[item.id]=true
                c.typeKey = item.typeKey
                if item.typeKey then usedTypes[item.typeKey] = true end
                hasLarge=hasLarge or c.large
                return true
            end
        end
        return false
    end
    if options.selection then
        local function choose(largeOnly, relaxed)
            -- Exhaust a usage tier before repeating more common types. For
            -- required slots, try that tier's dry fallback sites first too.
            local first = 1
            while first <= #pool do
                local last = first
                while last < #pool and pool[last+1].uses == pool[first].uses do last=last+1 end
                for pass=1,(relaxed and 2 or 1) do
                    for i=first,last do
                        local item=pool[i]
                        if (not largeOnly or M.isLarge(item.name)) and tryItem(item,pass==2) then return true end
                    end
                end
                first=last+1
            end
            return false
        end
        if needsLarge and requested>0 then choose(true,true) end
        while #result<requested do
            if not choose(false,#result<minimum) then break end
        end
        return result
    end
    local function tryLarge(relaxed)
        if hasLarge or not needsLarge or requested==0 then return end
        for _,item in ipairs(pool) do
            if M.isLarge(item.name) and tryItem(item,relaxed) then return end
        end
    end
    tryLarge(false)
    -- Reserve one slot for a large prop if it needs the fallback pass.
    local strictTarget=requested-((needsLarge and not hasLarge) and 1 or 0)
    for _,item in ipairs(pool) do
        if #result>=strictTarget then break end
        tryItem(item,false)
    end
    tryLarge(true)
    for _,item in ipairs(pool) do
        if #result>=minimum then break end
        tryItem(item,true)
    end
    return result
end
-- Bind engine operations to the owning unit; the planner itself is shared.
-- Explicit header-local primitives retain building-damage/cloud hooks.
function M:bindPlacement(env)
    local placeablePlanner=self
    local unitID,GG,Game,Spring=env.unitID,env.GG,env.Game,env.Spring
    local Move,Turn,Show,Sleep=env.Move,env.Turn,env.Show,env.Sleep
    local SetRadiancePlaceables=env.SetRadiancePlaceables
    return function(options)
        local service=assert(GG.HousePlaceableSelection,'Shared house placeable selection gadget is unavailable')
        local ticket=service:Request(unitID,function(selection,saved)
            local ux, uy, uz = Spring.GetUnitPosition(unitID)
            local front, _, right = Spring.GetUnitVectors(unitID)
            local scale = placeablePlanner.catalogue.scale
            local function world(x,z)
                -- Spring's model matrix uses -right, up, front as its basis.
                return ux+scale*(-right[1]*x+front[1]*z), uz+scale*(-right[3]*x+front[3]*z)
            end
            local roads=placeablePlanner.localRoads(GG.CityRoadNetwork,function(x,z)
                local dx,dz=x-ux,z-uz
                return (-right[1]*dx-right[3]*dz)/scale,(front[1]*dx+front[3]*dz)/scale
            end,math.max(options.halfExtent or 0, options.cell*3)+options.cell*6)
            local placements = saved or placeablePlanner.plan({
                seed=options.seed,
                selection=selection,
                cell=options.cell, halfExtent=options.halfExtent, pieces=options.pieces, roads=roads,
                roadWidth=options.roadWidth or placeablePlanner.roadWidth,
                accept=function(candidate)
                    local x,z=world(candidate.x,candidate.z)
                    local ground=Spring.GetGroundHeight(x,z)
                    if ground<0 then return false end
                    -- Relax cosmetic siting on pass two, but never water/map bounds.
                    -- Permit a 20% slope instead of 4%; cliffs remain unsuitable.
                    local grade=candidate.relaxed and 0.20 or 0.04
                    local low=ground
                    local samples={{x=x,z=z,h=ground}}
                    for _,px in ipairs({candidate.minX,candidate.maxX}) do
                        for _,pz in ipairs({candidate.minZ,candidate.maxZ}) do
                            local wx,wz=world(px,pz)
                            if (Game.mapSizeX and (wx<0 or wx>Game.mapSizeX))
                                or (Game.mapSizeZ and (wz<0 or wz>Game.mapSizeZ)) then return false end
                            local h=Spring.GetGroundHeight(wx,wz)
                            if h<0 then return false end
                            for _,sample in ipairs(samples) do
                                local dx,dz=wx-sample.x,wz-sample.z
                                if math.abs(h-sample.h)>math.max(2,grade*math.sqrt(dx*dx+dz*dz)) then
                                    return false
                                end
                            end
                            samples[#samples+1]={x=wx,z=wz,h=h}
                            low=math.min(low,h)
                        end
                    end
                    -- Centre/corners alone can straddle a river. Sample the footprint
                    -- at terrain-square spacing, including its edges, on both passes.
                    local step=Game.squareSize or 8
                    local nx=math.max(1,math.ceil((candidate.maxX-candidate.minX)*scale/step))
                    local nz=math.max(1,math.ceil((candidate.maxZ-candidate.minZ)*scale/step))
                    for ix=0,nx do
                        for iz=0,nz do
                            local wx,wz=world(candidate.minX+(candidate.maxX-candidate.minX)*ix/nx,
                                candidate.minZ+(candidate.maxZ-candidate.minZ)*iz/nz)
                            local h=Spring.GetGroundHeight(wx,wz)
                            if h<0 then return false end
                            local dx,dz=wx-x,wz-z
                            if math.abs(h-ground)>math.max(2,grade*math.sqrt(dx*dx+dz*dz)) then return false end
                            low=math.min(low,h)
                        end
                    end
                    candidate.ground=low
                    return true
                end,
            })
            for _,p in ipairs(placements) do
                -- Resolve local IDs again when replaying a saved layout.
                p.id=assert(options.pieces[p.name],'Saved placeable is absent from this model: '..p.name)
                local offsets={p.moveX,p.moveY+(p.ground-uy)/scale,p.moveZ}
                local basis=placeablePlanner.catalogue.moveBasis
                for axis=1,3 do
                    local value=offsets[axis]
                    if basis then
                        value=0
                        for j=1,3 do value=value+basis[axis][j]*offsets[j] end
                    end
                    Move(p.id,axis,value,0)
                end
                Turn(p.id,3,p.rotation,0)
                options.addToShowTable(p.id)
                Show(p.id)
                SetRadiancePlaceables({p.id},true)
                if options.onPlaced then options.onPlaced(p) end
            end
            return placements
        end)
        while not ticket.done do Sleep(33) end
        if ticket.error then error(ticket.error) end
        return ticket.result
    end
end

return M
end
local M = withCatalogue(VFS.Include('scripts/house_asian_placeable_catalog.lua'))
M.withCatalogue = withCatalogue
return M
