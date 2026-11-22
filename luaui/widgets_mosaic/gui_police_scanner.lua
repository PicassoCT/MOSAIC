function widget:GetInfo()
    return {name='Police Scanner', desc='Cycle through the three latest police reports and enemy sightings',
        author='MOSAIC contributors', license='GPL3', layer=5, enabled=true}
end

local labels = {violence='Police incident', cybercrime='Cybercrime reported',
    hostage='Hostage taken', hostage_death='Hostage killed', enemy='Enemy sighting'}
local contacts = {}
local history, team, ally, sequence = {}, nil, nil, 0
local radioSerial, legacyReport
local cycle, cycleIndex, lastClick, clock = nil, 0, -math.huge, 0
local cycleTimeout = 5
local elapsed, ping, pingTime = 0, nil, 0
local box, scale
local gaia = Spring.GetGaiaTeamID()

local function remember(entry)
    sequence = sequence + 1
    entry.sequence,entry.orderFrame = sequence,entry.frame
    history[#history+1] = entry
    table.sort(history,function(a,b)
        if a.orderFrame ~= b.orderFrame then return a.orderFrame > b.orderFrame end
        return a.sequence > b.sequence
    end)
    history[4] = nil
end
local function cycling() return cycle and clock-lastClick < cycleTimeout end

local function hostile(id)
    local owner = Spring.GetUnitTeam(id)
    return owner and owner ~= gaia and not Spring.AreTeamsAllied(team, owner)
end
local function inSight(id)
    local state = Spring.GetUnitLosState(id, ally)
    return state and state.los
end
local function observe(id, contact, frame)
    -- Check LOS before reading coordinates: radar contacts and last-known
    -- engine positions must never turn into live tracking through fog.
    if not hostile(id) or not inSight(id) then return false end
    local x,y,z = Spring.GetUnitPosition(id)
    if not x then return false end
    contact.x,contact.y,contact.z,contact.frame = x,y,z,frame
    return true
end
local function entered(id)
    if not team or not hostile(id) or not inSight(id) then return end
    if not contacts[id] then
        local contact = {kind='enemy'}
        if observe(id,contact,Spring.GetGameFrame()) then
            contacts[id] = contact
            remember(contact)
        end
    end
end
local function reset()
    team,ally = Spring.GetMyTeamID(),Spring.GetMyAllyTeamID()
    contacts,history,ping,sequence = {},{},nil,0
    radioSerial,legacyReport,cycle,cycleIndex = nil,nil,nil,0
    -- A single scan handles widget reloads / changing the viewed team.
    for _,id in ipairs(Spring.GetAllUnits()) do entered(id) end
end
local function readReport(prefix)
    local frame = Spring.GetGameRulesParam(prefix..'frame')
    if not frame then return end
    local kind = Spring.GetGameRulesParam(prefix..'kind')
    local x = Spring.GetGameRulesParam(prefix..'x')
    local y = Spring.GetGameRulesParam(prefix..'y')
    local z = Spring.GetGameRulesParam(prefix..'z')
    if x and y and z and labels[kind] then return {kind=kind,x=x,y=y,z=z,frame=frame} end
end
local function readPolice()
    local serial = Spring.GetGameRulesParam('police_scanner_serial')
    if serial then
        local first = math.max(1,serial-2,(radioSerial or 0)+1)
        for n=first,serial do
            local prefix = 'police_scanner_'..((n-1)%3+1)..'_'
            if Spring.GetGameRulesParam(prefix..'serial') == n then
                local entry = readReport(prefix)
                if entry then remember(entry) end
            end
        end
        radioSerial = serial
    else
        -- Supports reloading this widget during a match with the old publisher.
        local entry = readReport('police_scanner_')
        if entry and (not legacyReport or entry.frame ~= legacyReport.frame or
            entry.kind ~= legacyReport.kind or entry.x ~= legacyReport.x or
            entry.y ~= legacyReport.y or entry.z ~= legacyReport.z) then
            legacyReport = entry
            remember(entry)
        end
    end
end
local function latest()
    if cycling() then return cycle[cycleIndex] end
    return history[1]
end
local function layout()
    local width,height = Spring.GetViewGeometry()
    scale = math.max(0.75,math.min(1.5,height/1080))
    local top = height-68*scale
    if WG.topbar and WG.topbar.GetPosition then
        local area = WG.topbar.GetPosition()
        if area then top = math.min(top,area[2]-8*scale) end
    end
    box = {width/2-115*scale,top-46*scale,width/2+115*scale,top}
end
local function available()
    return not Spring.IsGUIHidden() and not (WG.topbar and WG.topbar.showingQuit and WG.topbar.showingQuit())
end
local function inside(x,y)
    return box and x>=box[1] and x<=box[3] and y>=box[2] and y<=box[4]
end
local function age(entry)
    local seconds = math.max(0,math.floor((Spring.GetGameFrame()-entry.frame)/30))
    if seconds < 2 then return 'just now' end
    if seconds < 60 then return seconds..'s ago' end
    return math.floor(seconds/60)..'m '..seconds%60 ..'s ago'
end

function widget:Initialize() reset(); readPolice(); layout() end
function widget:ViewResize() layout() end
function widget:PlayerChanged()
    if team ~= Spring.GetMyTeamID() or ally ~= Spring.GetMyAllyTeamID() then reset(); readPolice() end
end
function widget:UnitEnteredLos(id,unitTeam,allyTeam)
    if allyTeam == nil or allyTeam == ally then entered(id) end
end
function widget:UnitLeftLos(id,unitTeam,allyTeam)
    if allyTeam == nil or allyTeam == ally then contacts[id] = nil end
end
function widget:UnitDestroyed(id) contacts[id] = nil end
function widget:UnitTaken(id) contacts[id] = nil end
function widget:UnitGiven(id) contacts[id] = nil; entered(id) end
function widget:Update(dt)
    clock = clock + dt
    elapsed = elapsed + dt
    pingTime = math.max(0,pingTime-dt)
    if elapsed < 0.25 then return end
    elapsed = elapsed % 0.25
    self:PlayerChanged()
    local frame = Spring.GetGameFrame()
    for id,contact in pairs(contacts) do
        if not observe(id,contact,frame) then contacts[id] = nil end
    end
    readPolice()
    layout()
end
function widget:DrawScreen()
    if not available() or not box then return end
    local entry = latest()
    local mx,my = Spring.GetMouseState()
    local hover = inside(mx,my)
    gl.Color(0.025,0.045,0.065,hover and 0.97 or 0.9)
    gl.Rect(box[1],box[2],box[3],box[4])
    gl.Color(entry and 0.25 or 0.35,entry and 0.75 or 0.4,entry and 1 or 0.45,1)
    gl.Rect(box[1],box[4]-3*scale,box[3],box[4])
    local title = 'POLICE SCANNER'..(cycling() and ('  '..cycleIndex..'/'..#cycle) or '')
    gl.Text(title,(box[1]+box[3])/2,box[4]-20*scale,14*scale,'oc')
    gl.Color(0.85,0.9,0.95,1)
    gl.Text(entry and (labels[entry.kind]..' - '..age(entry)) or 'No reports yet',
        (box[1]+box[3])/2,box[2]+8*scale,11*scale,'oc')
    gl.Color(1,1,1,1)
end
function widget:IsAbove(x,y) return available() and inside(x,y) end
function widget:GetTooltip()
    local entry = cycling() and cycle[cycleIndex%#cycle+1] or history[1]
    return entry and ('Next: '..labels[entry.kind]..' ('..age(entry)..').\nClick repeatedly to cycle the last three events, newest first.\nAfter 5 seconds without clicking, start again at the newest event.')
        or 'Police Scanner: waiting for a police report or an enemy in your team\'s line of sight.'
end
function widget:MousePress(x,y,button)
    if button ~= 1 or not available() or not inside(x,y) then return false end
    if not cycling() then
        -- Freeze the order during repeated clicks, so incoming reports and
        -- moving contacts cannot keep restarting the cycle at its first item.
        cycle = {}
        for i,entry in ipairs(history) do cycle[i] = entry end
        cycleIndex = 0
    end
    local entry = cycle[cycleIndex%math.max(1,#cycle)+1]
    if entry then
        cycleIndex = cycleIndex%#cycle+1
        lastClick = clock
        Spring.SetCameraTarget(entry.x,entry.y,entry.z,0.6)
        ping,pingTime = {x=entry.x,y=entry.y,z=entry.z},4
    end
    return true
end
function widget:DrawWorld()
    if not ping or pingTime <= 0 or not available() then return end
    gl.Color(0.25,0.8,1,math.min(1,pingTime))
    gl.DrawGroundCircle(ping.x,Spring.GetGroundHeight(ping.x,ping.z),ping.z,70+(pingTime%1)*80,48)
    gl.Color(1,1,1,1)
end
