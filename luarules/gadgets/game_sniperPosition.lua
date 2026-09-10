function gadget:GetInfo()
    return {name = "Asset rooftop movement", desc = "Approach, grapple and traverse roof tiles",
        author = "Mosaic contributors", license = "GNU GPL, v2 or later", layer = 0, enabled = true}
end
if not gadgetHandler:IsSyncedCode() then return end
VFS.Include("scripts/lib_OS.lua")
VFS.Include("scripts/lib_UnitScript.lua")
VFS.Include("scripts/lib_mosaic.lua")
VFS.Include("scripts/lib_type.lua")
VFS.Include("luarules/configs/commandsIDs.lua")
local ROOF = CMD_ASSET_ROOFTOP
local assetDef = UnitDefNames.operativeasset.id
local houses = getHouseTypeTable(UnitDefs)
local states = {}
local step = 3 -- ten updates per simulated second
local walkSpeed, climbSpeed = 45, 90 -- world units per second
local linkDistance, maxStep = 96, 24 -- conservative tile-centre adjacency, tune in game

local function alive(id)
    return id and Spring.ValidUnitID(id) and not Spring.GetUnitIsDead(id)
end
local function building(id)
    local defID = id and Spring.GetUnitDefID(id)
    local def = defID and UnitDefs[defID]
    return def and (def.isBuilding or houses[defID])
end
local function call(id, name, ...)
    local env = Spring.UnitScript.GetScriptEnv(id)
    if env and env[name] then return Spring.UnitScript.CallAsUnit(id, env[name], ...) end
end
local function motion(id, mode)
    call(id, "setRooftopMotion", mode)
    Spring.SetUnitRulesParam(id, "asset_rooftop", mode and 1 or 0, {allied = true})
end
local function distance(a, b)
    return math.sqrt((a[1]-b[1])^2 + (a[2]-b[2])^2 + (a[3]-b[3])^2)
end
local function position(id)
    local x,y,z = Spring.GetUnitPosition(id)
    return x and {x,y,z}
end
local function release(id)
    local s = states[id]
    if not s then return end
    states[id] = nil
    if not alive(id) then return end
    if s.control then
        if Spring.GetUnitTransporter(id) == s.house then Spring.UnitDetach(id) end
        -- Return to the last reachable ground position, outside the footprint.
        if s.ground then
            Spring.MoveCtrl.Enable(id)
            Spring.MoveCtrl.SetPosition(id, s.ground[1], s.ground[2], s.ground[3])
        end
        Spring.MoveCtrl.Disable(id)
        motion(id, nil)
    end
    Spring.ClearUnitGoal(id)
end
local function tiles(house)
    local result = {}
    for _,piece in pairs(call(house, "getRooftopPieces") or {}) do
        local x,y,z = Spring.GetUnitPiecePosDir(house, piece)
        if x then result[#result+1] = {x,y,z,piece} end
    end
    table.sort(result, function(a,b) return a[4] < b[4] end)
    return result
end
local function nearest(list, p, horizontal)
    local best, cost
    for i,t in ipairs(list) do
        local d = (t[1]-p[1])^2 + (t[3]-p[3])^2 + (horizontal and 0 or (t[2]-p[2])^2)
        if not cost or d < cost then best,cost = i,d end
    end
    return best
end
local function pick(list, p)
    if #p ~= 7 then return nil end
    local origin,dir = {p[2],p[3],p[4]}, {p[5],p[6],p[7]}
    local len = math.sqrt(dir[1]^2+dir[2]^2+dir[3]^2)
    if len < 0.001 then return nil end
    local best,cost
    for i,t in ipairs(list) do
        local along = ((t[1]-origin[1])*dir[1]+(t[2]-origin[2])*dir[2]+(t[3]-origin[3])*dir[3])/len
        if along >= 0 then
            local d = (t[1]-origin[1]-along*dir[1]/len)^2 +
                (t[2]-origin[2]-along*dir[2]/len)^2 + (t[3]-origin[3]-along*dir[3]/len)^2
            if d <= linkDistance^2 and (not cost or d < cost) then best,cost = i,d end
        end
    end
    return best
end
local function route(list, first, last)
    local queue, prev = {first}, {[first] = false}
    local head = 1
    while queue[head] do
        local i = queue[head]
        if i == last then
            local path = {}
            while i do table.insert(path,1,list[i]); i = prev[i] end
            return path
        end
        for j,t in ipairs(list) do
            if prev[j] == nil and math.abs(t[2]-list[i][2]) <= maxStep and distance(t,list[i]) <= linkDistance then
                prev[j] = i; queue[#queue+1] = j
            end
        end
        head = head+1
    end
end
local function start(id, p, tag)
    local house = p[1]
    if not alive(house) or not building(house) then release(id); return end
    local old = states[id]
    local list = tiles(house)
    local target = pick(list,p)
    -- A facade click / building without roof support is just an approach order.
    if not target then
        release(id)
        local pos = position(house)
        states[id] = {house=house, tag=tag, phase="approach", destination=pos, started=Spring.GetGameFrame()}
        return
    end
    local here = position(id)
    local entry = nearest(list,here,true)
    local path = route(list,entry,target)
    if not path then release(id); return end
    if old and old.house == house and old.control then
        if Spring.GetUnitTransporter(id) == house then Spring.UnitDetach(id) end
        Spring.MoveCtrl.Enable(id)
        states[id] = {house=house,tag=tag,phase="walk",path=path,index=1,ground=old.ground,control=true}
        motion(id,"walk")
    else
        release(id)
        if Spring.GetUnitTransporter(id) or Spring.MoveCtrl.IsEnabled(id) then return end
        states[id] = {house=house,tag=tag,phase="approach",destination=list[entry],path=path,
            index=1,started=Spring.GetGameFrame()}
    end
end
function gadget:UnitCreated(id, defID)
    if defID == assetDef and not Spring.FindUnitCmdDesc(id, ROOF) then
        Spring.InsertUnitCmdDesc(id, {id=ROOF, type=CMDTYPE.ICON_UNIT,
            name="Roof", action="assetrooftop", cursor="Move",
            tooltip="Approach building and grapple onto a roof tile"})
    end
end
function gadget:Initialize()
    gadgetHandler:RegisterCMDID(ROOF)
    for _,id in ipairs(Spring.GetAllUnits()) do self:UnitCreated(id,Spring.GetUnitDefID(id)) end
end
local function validParams(p)
    if #p ~= 1 and #p ~= 7 then return false end
    for _,v in ipairs(p) do
        if type(v) ~= "number" or v ~= v or math.abs(v) > 1e8 then return false end
    end
    return alive(p[1]) and building(p[1])
end
function gadget:AllowCommand(id, defID, team, cmd, p, opts)
    if defID ~= assetDef then return cmd ~= ROOF end
    if cmd == ROOF then return validParams(p) end
    -- Do not allow explicit building attacks from widgets, AI, or inserted orders.
    if cmd == CMD.ATTACK and #p == 1 and building(p[1]) then return false end
    if cmd == CMD.INSERT and p[2] == CMD.ATTACK and #p == 4 and building(p[4]) then return false end
    return true
end
function gadget:CommandFallback(id, defID, team, cmd, p, opts, tag)
    if cmd ~= ROOF then return false end
    if defID ~= assetDef or not validParams(p) then release(id); return true,true end
    if not states[id] or states[id].tag ~= tag then start(id,p,tag) end
    local s = states[id]
    return true, not s or s.phase == "idle" or s.phase == "done"
end
function gadget:GameFrame(frame)
    if frame % step ~= 0 then return end
    for id,s in pairs(states) do
        local cmd,_,tag = Spring.GetUnitCurrentCommand(id)
        if not alive(id) or not alive(s.house) then
            release(id)
        elseif (s.phase ~= "idle" and tag ~= s.tag) or (s.phase == "idle" and cmd and cmd ~= ROOF) then
            release(id)
        elseif s.phase == "approach" then
            local here = position(id)
            local d = s.destination
            local dx,dz = here[1]-d[1],here[3]-d[3]
            local range = math.max(96, (Spring.GetUnitRadius(s.house) or 0)+24)
            if dx*dx+dz*dz <= range*range then
                Spring.ClearUnitGoal(id)
                if not s.path then s.phase = "done"
                elseif not Spring.GetUnitTransporter(id) and not Spring.MoveCtrl.IsEnabled(id) then
                    s.ground = here; s.control = true; s.phase = "grapple"
                    local length = math.max(1, math.sqrt(dx*dx+dz*dz))
                    s.landing = {d[1]+dx/length*16,d[2],d[3]+dz/length*16}
                    s.launchFrame = frame+9
                    Spring.MoveCtrl.Enable(id)
                    Spring.MoveCtrl.SetVelocity(id,0,0,0)
                    motion(id,"grapple")
                else release(id) end
            elseif frame-s.started > 30*60 then release(id)
            else
                Spring.SetUnitMoveGoal(id,d[1],Spring.GetGroundHeight(d[1],d[3]),d[3],range-8)
            end
        elseif s.phase == "grapple" or s.phase == "walk" then
            local dest = s.phase == "grapple" and s.landing or s.path[s.index]
            local here = position(id)
            local dist = distance(here,dest)
            local amount = (s.phase == "grapple" and climbSpeed or walkSpeed)*step/30
            local f = frame < (s.launchFrame or 0) and 0 or math.min(1,amount/math.max(dist,0.001))
            Spring.MoveCtrl.SetPosition(id,here[1]+(dest[1]-here[1])*f,
                here[2]+(dest[2]-here[2])*f,here[3]+(dest[3]-here[3])*f)
            local dx,dz = dest[1]-here[1],dest[3]-here[3]
            if dx*dx+dz*dz > 0.01 then
                Spring.MoveCtrl.SetHeading(id,Spring.GetHeadingFromVector(dx,dz))
            end
            if f == 1 then
                if s.phase == "grapple" then
                    s.phase = "walk"; motion(id,"walk")
                elseif s.index < #s.path then
                    s.index = s.index+1; s.phase = "walk"; motion(id,"walk")
                else
                    Spring.MoveCtrl.Disable(id)
                    Spring.UnitAttach(s.house,id,dest[4])
                    if Spring.GetUnitTransporter(id) == s.house then
                        s.phase = "idle"; motion(id,"idle"); call(id,"onRooftop")
                    else release(id) end
                end
            end
        end
    end
end
function gadget:UnitDestroyed(id)
    states[id] = nil
    for asset,s in pairs(states) do if s.house == id then release(asset) end end
end
function gadget:UnitTaken(id)
    release(id)
    for asset,s in pairs(states) do if s.house == id then release(asset) end end
end
function gadget:Shutdown()
    for id in pairs(states) do release(id) end
end
