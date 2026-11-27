function gadget:GetInfo()
    return {name = "Assembly turret delivery", desc = "Place completed stationary turrets outside their assembly's house",
        author = "MOSAIC contributors", license = "GPL3", layer = 0, enabled = true}
end
if not gadgetHandler:IsSyncedCode() then return false end

VFS.Include("scripts/lib_UnitScript.lua")
VFS.Include("scripts/lib_mosaic.lua")
local assemblyNames = {antagonassembly=true, protagonassembly=true}
local assemblies, turrets = {}, {}
for defID,def in pairs(UnitDefs) do
    assemblies[defID] = assemblyNames[def.name]
    turrets[defID] = (def.customParams or {}).baseclass == "turret" and (def.speed or 0) == 0
end
local houses = getHouseTypeTable(UnitDefs)
local pending = {}
local margin, ringStep, rings, sectors = 24, 48, 10, 32
local retryFrames = 30
local square = Game.squareSize or 8
local function alive(id)
    return id and Spring.ValidUnitID(id) and not Spring.GetUnitIsDead(id)
end
local function footprint(def)
    return (def.xsize or (def.footprintX or 1)*2)*square*.5,
        (def.zsize or (def.footprintZ or 1)*2)*square*.5
end
local function bounds(id)
    local def = UnitDefs[Spring.GetUnitDefID(id)]
    local x,_,z,mx,_,mz = Spring.GetUnitPosition(id,true)
    if not x or not def then return end
    local sx,sy,sz,ox,oy,oz = Spring.GetUnitCollisionVolumeData(id)
    local front,up,right = Spring.GetUnitVectors(id)
    local fx,fz = footprint(def)
    if (Spring.GetUnitBuildFacing(id) or 0)%2 == 1 then fx,fz = fz,fx end
    local minX,maxX,minZ,maxZ = x-fx,x+fx,z-fz,z+fz
    if sx and front and up and right then
        -- Collision offsets are relative to midPos, in the unit's local basis.
        -- Whole model radii include hidden procedural house variants.
        local cx = (mx or x)+right[1]*ox+up[1]*oy+front[1]*oz
        local cz = (mz or z)+right[3]*ox+up[3]*oy+front[3]*oz
        local hx = (math.abs(right[1]*sx)+math.abs(up[1]*sy)+math.abs(front[1]*sz))*.5
        local hz = (math.abs(right[3]*sx)+math.abs(up[3]*sy)+math.abs(front[3]*sz))*.5
        minX,maxX = math.min(minX,cx-hx),math.max(maxX,cx+hx)
        minZ,maxZ = math.min(minZ,cz-hz),math.max(maxZ,cz+hz)
    end
    return {x=(minX+maxX)*.5,z=(minZ+maxZ)*.5,hx=(maxX-minX)*.5,hz=(maxZ-minZ)*.5}
end
local function host(factory)
    for house,occupant in pairs(GG.houseHasSafeHouseTable or {}) do
        if occupant == factory and alive(house) then return house end
    end
end
local function obstacles(unit)
    local result = {}
    for _,id in ipairs(Spring.GetAllUnits()) do
        if id ~= unit and alive(id) and not Spring.GetUnitTransporter(id) then
            local defID = Spring.GetUnitDefID(id)
            local def = UnitDefs[defID]
            -- Houses deliberately do not block native traffic; still exclude
            -- their physical envelope when choosing a deployment location.
            if houses[defID] or assemblies[defID] or (not def.canFly and Spring.GetUnitBlocking(id)) then
                local box = bounds(id)
                if box then result[#result+1] = box end
            end
        end
    end
    return result
end
local function findPosition(id, request)
    local anchor = alive(request.host) and bounds(request.host) or request.anchor
    local body = bounds(id)
    local ux,_,uz = Spring.GetUnitPosition(id)
    if not anchor or not body then return end
    -- Cover both the footprint and offset collision volume around the origin.
    local radius = math.max(body.hx+math.abs(body.x-ux),body.hz+math.abs(body.z-uz))
    local occupied = obstacles(id)
    local facing = Spring.GetUnitBuildFacing(id) or 0
    local function clear(x,z)
        if x-radius < 0 or z-radius < 0 or x+radius > Game.mapSizeX or z+radius > Game.mapSizeZ then return end
        for _,box in ipairs(occupied) do
            if math.abs(x-box.x) < box.hx+radius+8 and math.abs(z-box.z) < box.hz+radius+8 then return end
        end
        local y = Spring.GetGroundHeight(x,z)
        local status,feature = Spring.TestBuildOrder(request.def,x,y,z,facing)
        -- Native engines report open ground as either 2 or 3. Reclaimable
        -- features also return 2, but additionally supply their feature ID.
        if status and status >= 2 and not feature then return x,z end
    end
    for ring=0,rings do
        local hx,hz = anchor.hx+radius+margin+ring*ringStep,anchor.hz+radius+margin+ring*ringStep
        for sector=0,sectors-1 do
            local angle = request.heading+sector*2*math.pi/sectors
            local dx,dz = math.sin(angle),math.cos(angle)
            local scale = 1/math.max(math.abs(dx)/hx,math.abs(dz)/hz)
            local x,z = anchor.x+dx*scale,anchor.z+dz*scale
            x,_,z = Spring.Pos2BuildPos(request.def,x,Spring.GetGroundHeight(x,z),z,facing)
            if x and clear(x,z) then return x,z end
        end
    end
end
function gadget:UnitFromFactory(id, def, team, factory, factoryDef)
    if not turrets[def] or not assemblies[factoryDef] then return end
    local house = host(factory)
    local anchor = bounds(house or factory)
    if not anchor then return end
    pending[id] = {def=def,team=team,factory=factory,host=house,anchor=anchor,
        heading=(Spring.GetUnitHeading(factory) or 0)*math.pi/32768,
        frame=Spring.GetGameFrame()+1}
end
function gadget:UnitDestroyed(id)
    pending[id] = nil
end
function gadget:GameFrame(frame)
    if not next(pending) then return end
    local ids = {}
    for id in pairs(pending) do ids[#ids+1] = id end
    table.sort(ids)
    for _,id in ipairs(ids) do
        local request = pending[id]
        if not alive(id) or Spring.GetUnitTeam(id) ~= request.team or Spring.GetUnitTransporter(id)
            or Spring.MoveCtrl.IsEnabled(id) then
            pending[id] = nil
        elseif frame >= request.frame then
            local x,z = findPosition(id,request)
            if x then
                -- The factory has released its build platform by this frame.
                -- Preserve the unit, fire state, experience and queued orders.
                Spring.SetUnitPosition(id,x,z)
                pending[id] = nil
                Spring.Echo(string.format("[MOSAIC assembly] delivered turret=%d factory=%d host=%s pos=(%.1f,%.1f)",
                    id,request.factory,tostring(request.host or "none"),x,z))
            else
                request.frame = frame+retryFrames
                if not request.warned then
                    request.warned = true
                    Spring.Echo(string.format("[MOSAIC assembly] delivery waiting: no clear ground for turret=%d factory=%d host=%s",
                        id,request.factory,tostring(request.host or "none")))
                end
            end
        end
    end
end
