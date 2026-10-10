function widget:GetInfo()
    return {name="Civilian conversations", desc="Read nearby speech on hover or with Observe (O)",
        author="MOSAIC contributors", license="GPL3", layer=5, enabled=true}
end
local exchanges, hovered, hoverTime, elapsed = {}, nil, 0, 0
local panel, pinnedHover
local HISTORY_LINES, HISTORY_FRAMES = 96, 5*60*30
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
    if #entry.lines>HISTORY_LINES then table.remove(entry.lines,1) end
    entry.pending=(entry.pending or 0)+1
    entry.dirty=true
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
    -- Keep a hovered conversation open while moving onto its scrollable panel.
    local overPanel=panel and mx>=panel.x and mx<=panel.x+panel.width and
        my>=panel.y-panel.height and my<=panel.y
    if overPanel and pinnedHover and visible(pinnedHover) then id=pinnedHover; kind="unit" end
    if kind~="unit" or not visible(id) or not civilian(id) then id=nil end
    if hovered~=id then hovered=id; hoverTime=elapsed end
    local frame=Spring.GetGameFrame()
    for key,entry in pairs(exchanges) do
        if frame-entry.frame>HISTORY_FRAMES or not visible(entry.a) then exchanges[key]=nil end
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
function widget:MouseWheel(up, value)
    if not panel or not panel.entry then return false end
    local mx,my=Spring.GetMouseState()
    if mx<panel.x or mx>panel.x+panel.width or my<panel.y-panel.height or my>panel.y then return false end
    local e=panel.entry
    e.scroll=math.max(0,math.min(panel.maxScroll,(e.scroll or 0)+(up and 3 or -3)))
    return true
end
function widget:DrawScreen()
    if Spring.IsGUIHidden() then panel=nil; pinnedHover=nil; return end
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
    if not id then panel=nil; pinnedHover=nil; return end
    local vsx,vsy=Spring.GetViewGeometry()
    local scale=math.max(0.85,math.min(1.25,vsx/1920))
    local size,pad,width=15*scale,14*scale,470*scale
    local rows={}
    if entry then
        -- Layout only when text or viewport changes, not on every render frame.
        if entry.dirty or entry.rowWidth~=width then
            local added=0
            for i,line in ipairs(entry.lines) do
                local before=#rows
                rows[#rows+1]={text=line.name,color={0.57,0.83,0.76,1}}
                for _,part in ipairs(wrap(line.text,width-2*pad,size)) do
                    rows[#rows+1]={text=part,color={0.94,0.94,0.91,1}}
                end
                if i>#entry.lines-(entry.pending or 0) then added=added+#rows-before end
            end
            if (entry.scroll or 0)>0 then entry.scroll=entry.scroll+added end
            entry.rows,entry.rowWidth,entry.dirty,entry.pending=rows,width,false,0
        end
        rows=entry.rows
    else rows[1]={text="No conversation right now.",color={0.65,0.68,0.68,1}} end
    local lineHeight=19*scale
    local maxRows=math.max(3,math.min(18,math.floor((vsy*0.65-pad*3-44*scale)/lineHeight)))
    local maxScroll=math.max(0,#rows-maxRows)
    local scroll=entry and math.min(entry.scroll or 0,maxScroll) or 0
    if entry then entry.scroll=scroll end
    local last=#rows-scroll
    local first=math.max(1,last-maxRows+1)
    local height=pad*3+44*scale+(last-first+1)*lineHeight
    local x,y=24*scale,vsy-90*scale
    if hovered==id then
        local mx,my=Spring.GetMouseState()
        local overPanel=panel and panel.entry==entry and mx>=panel.x and mx<=panel.x+panel.width and
            my>=panel.y-panel.height and my<=panel.y
        x=overPanel and panel.x or math.min(vsx-width-pad,mx+22*scale)
        y=overPanel and panel.y or my-18*scale
        pinnedHover=id
    else pinnedHover=nil
    end
    x=math.max(pad,math.min(vsx-width-pad,x))
    y=math.max(height+pad,math.min(vsy-pad,y))
    panel={x=x,y=y,width=width,height=height,entry=entry,maxScroll=maxScroll}
    gl.Color(0.035,0.05,0.05,0.94); gl.Rect(x,y-height,x+width,y)
    gl.Color(0.18,0.64,0.49,1); gl.Rect(x,y-3*scale,x+width,y)
    gl.Color(0.76,0.86,0.81,1)
    gl.Text(mode.."    Hover a civilian + O to toggle observation",x+pad,y-pad-16*scale,12*scale,"o")
    local ty=y-pad*2-30*scale
    for i=first,last do
        local row=rows[i]
        gl.Color(row.color); gl.Text(row.text,x+pad,ty,size,"o"); ty=ty-lineHeight
    end
    if maxScroll>0 then
        gl.Color(0.57,0.73,0.69,1)
        gl.Text(scroll>0 and "Earlier dialogue - scroll down to return to live speech" or
            "Scroll up over this panel for earlier dialogue",x+pad,y-height+pad,11*scale,"o")
    end
    gl.Color(1,1,1,1)
end
