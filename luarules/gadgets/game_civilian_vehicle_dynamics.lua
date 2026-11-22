function gadget:GetInfo()
    return {name='Civilian vehicle dynamics', desc='Model/load driving profiles and identity-preserving theft',
        author='MOSAIC contributors', license='GPL3', layer=5, enabled=true}
end
if not gadgetHandler:IsSyncedCode() then return false end
local config = VFS.Include('luarules/configs/civilian_vehicle_dynamics.lua')
local carriers,payloads,dirty,parents,ownership,hijacks,builders = {},{},{},{},{},{},{}
local capturable,boarding = {},{}
local gaia = Spring.GetGaiaTeamID()
local private = {private=true}
local iconDef = UnitDefNames.stealvehicleicon.id
local function alive(id) return id and Spring.ValidUnitID(id) and not Spring.GetUnitIsDead(id) end
local function sorted(t)
    local ids={};for id in pairs(t) do ids[#ids+1]=id end;table.sort(ids);return ids
end
for id,def in pairs(UnitDefs) do
    carriers[id]=config.models[def.name]
    capturable[id]=carriers[id] or config.hijackExtraNames[def.name]
    local cargo=config.payloadDefaults[def.name]
    if cargo then payloads[id]=config.cargoMass[cargo] end
end
local function param(id,key) return Spring.GetUnitRulesParam(id,'vehicle_'..key) end
local function save(id,key,value) Spring.SetUnitRulesParam(id,'vehicle_'..key,value,private) end
local function carrier(id) return alive(id) and carriers[Spring.GetUnitDefID(id)] end
local function stealable(id) return alive(id) and capturable[Spring.GetUnitDefID(id)] end
local function mark(id)
    while alive(id) do
        if carriers[Spring.GetUnitDefID(id)] then dirty[id]=true end
        id=parents[id] or Spring.GetUnitTransporter(id)
    end
end
local function mass(id)
    local result=0
    for _,child in ipairs(Spring.GetUnitIsTransporting(id) or {}) do
        local fallback=payloads[Spring.GetUnitDefID(child)]
        if fallback then result=result+(param(child,'cargo_mass') or fallback)+mass(child) end
    end
    return result
end
local function update(id)
    local default=carrier(id)
    if not default then return end
    local profile=config.profiles[param(id,'profile')] or config.profiles[default]
    if not param(id,'profile') then save(id,'profile',default) end
    local data,speed=config.Calculate(profile,mass(id),param(id,'speed_factor') or 1)
    Spring.MoveCtrl.SetGroundMoveTypeData(id,data)
    save(id,'base_speed',speed)
end
local api={}
function api.SetModel(id,profile)
    if not carrier(id) or not config.profiles[profile] then return end
    save(id,'profile',profile);dirty[id]=true
end
function api.SetLongBody(id,index)
    api.SetModel(id,config.longBodies[index])
end
function api.SetPayload(id,family,variant)
    local choices=config.payloadVariants[family]
    if not alive(id) or not choices then return end
    local cargo=choices[variant] or 'medium'
    save(id,'cargo_mass',config.cargoMass[cargo])
    local parent=Spring.GetUnitTransporter(id)
    if parent then mark(parent) end
end
function api.ScaleSpeed(id,factor)
    if not carrier(id) then return false end
    save(id,'speed_factor',factor)
    -- Calls are already event-driven (bus stops, parade pace); no motion loop.
    update(id)
    return true
end
function api.RequestHijack(id,icon,range)
    if not stealable(id) or not alive(icon) or Spring.GetUnitDefID(icon)~=iconDef
        or Spring.GetUnitTeam(id)~=gaia or Spring.GetUnitTeam(icon)==gaia or hijacks[icon]
        or type(range)~='number' or range<=0 then return false end
    hijacks[icon]={id=id,range=range}
    return true
end
local function transferCargo(id,team)
    for _,child in ipairs(Spring.GetUnitIsTransporting(id) or {}) do
        if alive(child) and payloads[Spring.GetUnitDefID(child)] then
            if Spring.GetUnitTeam(child)~=team then Spring.TransferUnit(child,team,false) end
            Spring.SetUnitAlwaysVisible(child,team==gaia)
            Spring.SetUnitNoSelect(child,true)
            transferCargo(child,team)
        end
    end
end
function gadget:Initialize()
    GG.CivilianVehicles=api
    for _,id in ipairs(Spring.GetAllUnits()) do
        local def=Spring.GetUnitDefID(id)
        if carriers[def] then dirty[id]=true end
        if payloads[def] then parents[id]=Spring.GetUnitTransporter(id) end
    end
end
function gadget:UnitCreated(id,def,team,builder)
    if carriers[def] then dirty[id]=true end
    if def==iconDef then builders[id]=builder end
end
function gadget:UnitLoaded(id,def,team,transport)
    parents[id]=transport;mark(transport)
end
function gadget:UnitUnloaded(id,def,team,transport)
    parents[id]=nil;mark(transport)
end
function gadget:UnitDestroyed(id)
    if parents[id] then mark(parents[id]) end
    parents[id],dirty[id],ownership[id],hijacks[id],builders[id]=nil,nil,nil,nil,nil
    boarding[id]=nil
end
function gadget:UnitGiven(id,def,newTeam)
    if capturable[def] then ownership[id]=newTeam end
end
function gadget:GameFrame()
    if not next(boarding) and not next(hijacks) and not next(ownership) and not next(dirty) then return end
    -- Never transfer units or run boarding callbacks inside CommandFallback,
    -- UnitGiven or UnitLoaded. Ownership changes retain the original IDs/scripts.
    local passengers=boarding;boarding={}
    for _,id in ipairs(sorted(passengers)) do
        local passenger=passengers[id]
        if alive(id) and alive(passenger) and Spring.GetUnitTeam(id)==Spring.GetUnitTeam(passenger) then
            local env=Spring.UnitScript.GetScriptEnv(id)
            local pickup=env and ((env.script and env.script.TransportPickup) or env.TransportPickup)
            if pickup then Spring.UnitScript.CallAsUnit(id,pickup,passenger) end
        end
    end
    local requests=hijacks;hijacks={}
    for _,icon in ipairs(sorted(requests)) do
        local request=requests[icon]
        local id=request.id
        local distance=alive(icon) and alive(id) and Spring.GetUnitSeparation(icon,id,true)
        if distance and distance<=request.range and stealable(id) and Spring.GetUnitTeam(id)==gaia then
            local team=Spring.GetUnitTeam(icon)
            Spring.TransferUnit(id,team,false)
            if alive(id) and Spring.GetUnitTeam(id)==team then
                Spring.SetUnitNoSelect(id,false)
                Spring.SetUnitAlwaysVisible(id,false)
                Spring.SetUnitNeutral(id,false)
                -- Model pieces and attached cargo never get recreated.
                transferCargo(id,team)
                if GG.CivilianLife then GG.CivilianLife:Interrupt(id) end
                Spring.GiveOrderToUnit(id,CMD.STOP,{},{})
                api.ScaleSpeed(id,1)
                boarding[id]=builders[icon]
                Spring.DestroyUnit(icon,false,true)
            end
        end
    end
    local changes=ownership;ownership={}
    for _,id in ipairs(sorted(changes)) do
        if stealable(id) then
            local team=Spring.GetUnitTeam(id)
            transferCargo(id,team)
            Spring.SetUnitAlwaysVisible(id,team==gaia)
            if team~=gaia then Spring.SetUnitNoSelect(id,false) end
            api.ScaleSpeed(id,1)
        end
    end
    local updates=dirty;dirty={}
    for _,id in ipairs(sorted(updates)) do update(id) end
end
function gadget:Shutdown()
    if GG.CivilianVehicles==api then GG.CivilianVehicles=nil end
end
