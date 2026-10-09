function widget:GetInfo()
    return {name="Civilian conversations", desc="Read nearby speech on hover or with Observe (O)",
        author="MOSAIC contributors", license="GPL3", layer=5, enabled=true}
end
local exchanges, hovered, hoverTime, elapsed = {}, nil, 0, 0
local function visible(id)
    if not id or not Spring.ValidUnitID(id) or Spring.GetUnitIsDead(id) then return false end
    local spec,full=Spring.GetSpectatingState()
    if spec and full then return true end
    local los=Spring.GetUnitLosState(id,Spring.GetMyAllyTeamID())
    return (los and los.los) or Spring.IsUnitVisible(id)
end
local function civilian(id)
    local def=UnitDefs[Spring.GetUnitDefID(id)]
    return def and def.name and def.name:find("civilian_",1,true)==1
end
local function clean(s)
    return tostring(s or ""):gsub("\255...",""):gsub("[%z\1-\31]"," ")
end
local function receive(speaker,partner,text,duration)
    if not visible(speaker) then return end
    local a,b=speaker,partner
    if b>0 and b<a then a,b=b,a end
    local key=a..":"..b
    local entry=exchanges[key] or {a=a,b=b,lines={}}
    exchanges[key]=entry
    local name=(Spring.GetUnitTooltip(speaker) or "Civilian"):match("^[^<\n]+") or "Civilian"
    if partner==0 and text:sub(1,7)=="Phone: " then name="Other end"; text=text:sub(8) end
    entry.lines[#entry.lines+1]={name=clean(name):sub(1,58),text=clean(text)}
    if #entry.lines>4 then table.remove(entry.lines,1) end
    entry.frame=Spring.GetGameFrame()
end
function widget:Initialize()
    widgetHandler:RegisterGlobal("CivilianConversation",receive)
end
function widget:Shutdown()
    widgetHandler:DeregisterGlobal("CivilianConversation")
end
function widget:UnitDestroyed(id)
    for key,entry in pairs(exchanges) do if entry.a==id or entry.b==id then exchanges[key]=nil end end
end
function widget:Update(dt)
    elapsed=elapsed+dt
    local mx,my=Spring.GetMouseState()
    local kind,id=Spring.TraceScreenRay(mx,my)
    if kind~="unit" or not visible(id) or not civilian(id) then id=nil end
    if hovered~=id then hovered=id; hoverTime=elapsed end
    local frame=Spring.GetGameFrame()
    for key,entry in pairs(exchanges) do
        if frame-entry.frame>45*30 or not visible(entry.a) then exchanges[key]=nil end
    end
end
local function findExchange(id)
    local best
    for _,entry in pairs(exchanges) do
        if (entry.a==id or entry.b==id) and (not best or entry.frame>best.frame) then best=entry end
    end
    -- A quiet companion can still overhear the group's conversation. This also
    -- lets a guarded disguise share the same readable social context.
    if not best then
        local x,_,z=Spring.GetUnitPosition(id)
        local bestDistance=180*180
        for _,entry in pairs(exchanges) do
            if entry.b>0 and Spring.GetGameFrame()-entry.frame<8*30 and visible(entry.a) then
                local ex,_,ez=Spring.GetUnitPosition(entry.a)
                local d=x and ex and (x-ex)^2+(z-ez)^2
                if d and (d<bestDistance or (d==bestDistance and best and entry.a<best.a)) then
                    best,bestDistance=entry,d
                end
            end
        end
    end
    return best
end
local function wrap(text,width,size)
    local lines,current={},""
    for word in text:gmatch("%S+") do
        local candidate=current=="" and word or current.." "..word
        if current~="" and gl.GetTextWidth(candidate)*size>width then
            lines[#lines+1]=current; current=word
        else current=candidate end
    end
    if current~="" then lines[#lines+1]=current end
    return lines
end
function widget:DrawScreen()
    if Spring.IsGUIHidden() then return end
    local id,entry,mode
    if hovered and elapsed-hoverTime>=0.18 then
        id=hovered; entry=findExchange(id); mode="Conversation"
    else
        local observed=WG.ObservedCivilianUnits or {}
        for tracked in pairs(observed) do
            if visible(tracked) then
                local candidate=findExchange(tracked)
                if candidate and (not entry or candidate.frame>entry.frame or
                    (candidate.frame==entry.frame and tracked<id)) then
                    id,entry,mode=tracked,candidate,"Observe"
                end
            end
        end
    end
    if not id then return end
    local vsx,vsy=Spring.GetViewGeometry()
    local scale=math.max(0.85,math.min(1.25,vsx/1920))
    local size,pad,width=15*scale,14*scale,470*scale
    local rows={}
    if entry then
        for _,line in ipairs(entry.lines) do
            rows[#rows+1]={text=line.name,color={0.57,0.83,0.76,1}}
            for _,part in ipairs(wrap(line.text,width-2*pad,size)) do
                rows[#rows+1]={text=part,color={0.94,0.94,0.91,1}}
            end
        end
    else rows[1]={text="No conversation right now.",color={0.65,0.68,0.68,1}} end
    local lineHeight=19*scale
    local height=pad*3+22*scale+#rows*lineHeight
    local x,y=24*scale,vsy-90*scale
    if hovered==id then
        local mx,my=Spring.GetMouseState()
        x=math.min(vsx-width-pad,mx+22*scale)
        y=math.max(height+pad,math.min(vsy-pad,my-18*scale))
    end
    gl.Color(0.035,0.05,0.05,0.94); gl.Rect(x,y-height,x+width,y)
    gl.Color(0.18,0.64,0.49,1); gl.Rect(x,y-3*scale,x+width,y)
    gl.Color(0.76,0.86,0.81,1)
    gl.Text(mode.."    Hover a civilian + O to toggle observation",x+pad,y-pad-16*scale,12*scale,"o")
    local ty=y-pad*2-30*scale
    for _,row in ipairs(rows) do
        gl.Color(row.color); gl.Text(row.text,x+pad,ty,size,"o"); ty=ty-lineHeight
    end
    gl.Color(1,1,1,1)
end
