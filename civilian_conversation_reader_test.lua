-- Headless UI contract check; actual Recoil rendering still needs visual review.
local frame,mx,my,hovered,visible=0,400,500,10,true
local received,drawn,rects,wraps={}, {}, {}, 0
local e=setmetatable({widget={},WG={},UnitDefs={[1]={name="civilian_arab0"}}},{__index=_G})
e.Spring={ValidUnitID=function()return true end,GetUnitIsDead=function()return false end,
    GetSpectatingState=function()return false,false end,GetUnitLosState=function()return {los=visible} end,
    IsUnitVisible=function()return visible end,GetMyAllyTeamID=function()return 0 end,
    GetUnitDefID=function()return 1 end,GetUnitTooltip=function(id)return "Civilian "..id end,
    GetGameFrame=function()return frame end,GetMouseState=function()return mx,my end,
    TraceScreenRay=function()return hovered and "unit",hovered end,
    GetUnitPosition=function()return 100,0,100 end,IsGUIHidden=function()return false end,
    GetViewGeometry=function()return 1280,720 end}
e.widgetHandler={RegisterGlobal=function(_,name,fn)received[name]=fn end,DeregisterGlobal=function()end}
e.gl={Color=function()end,Rect=function(x,y,x2,y2)rects[#rects+1]={x=x,y=y,x2=x2,y2=y2} end,
    GetTextWidth=function(text)wraps=wraps+1; return #text*0.5 end,
    Text=function(text)drawn[#drawn+1]=text end}
local fn=assert(loadfile("luaui/widgets_mosaic/gui_civilian_conversations.lua"));setfenv(fn,e);fn()
e.widget:Initialize()
local receive=assert(received.CivilianConversation)
for i=1,20 do receive(10,11,"Claim "..i.." followed by an increasingly unlikely explanation.",150) end
e.widget:Update(0.1);e.widget:Update(0.3)
local function draw()
    drawn,rects={},{};e.widget:DrawScreen();return table.concat(drawn,"\n")
end
local text=draw()
assert(text:find("Claim 20",1,true) and not text:find("Claim 1 followed",1,true),"reader should follow latest speech")
local before=wraps;draw();assert(wraps==before,"unchanged text should use cached wrapping")
local panel=rects[1]
assert(panel.y>=0 and panel.y2<=720,"panel outside viewport")
mx,my=(panel.x+panel.x2)/2,(panel.y+panel.y2)/2;hovered=nil
e.widget:Update(0.1)
assert(e.widget:MouseWheel(true,1),"panel did not capture scrolling")
for _=1,30 do e.widget:MouseWheel(true,1);draw() end
assert(draw():find("Claim 1 followed",1,true),"earlier turns were discarded")
receive(10,11,"Claim 21 followed by another unlikely explanation.",150)
assert(draw():find("Claim 1 followed",1,true),"new speech moved the user's reading position")
-- Observe's compact reader now belongs to the world-space marker. The large
-- scrollable transcript is still available when deliberately hovering.
mx,my=1,1;e.widget:Update(0.1);e.WG.ObservedCivilianUnits={[10]=true}
assert(draw()=="","observed speech still opened a duplicate screen-space panel")
local world=e.WG.CivilianConversationWorld
local recent,first,last=world.GetRecentLines(10)
assert(recent and first==last-2 and recent[last].text:find("Claim 21",1,true),
    "world reader did not expose the latest bounded dialogue")
frame=90*30;e.widget:Update(0.1)
assert(not world.GetRecentLines(10),"world bubble outlived the current utterance")
visible=false;e.widget:Update(0.1);assert(draw()=="","reader leaked speech through lost vision")
assert(not world.GetRecentLines(10),"world speech leaked through lost vision")
visible=true;hovered=10;mx,my=400,500;e.widget:Update(0.1);e.widget:Update(0.3)
for i=1,120 do receive(10,11,"Bounded "..i,150) end
draw();panel=rects[1];mx,my=(panel.x+panel.x2)/2,(panel.y+panel.y2)/2
for _=1,150 do e.widget:MouseWheel(true,1);draw() end
text=draw()
assert(text:find("Bounded 25",1,true) and not text:find("Bounded 24",1,true),"history bound not enforced")
frame=frame+5*60*30+1;e.widget:Update(0.1)
assert(not draw():find("Bounded",1,true),"old history not expired")
e.widget:Shutdown()
assert(e.WG.CivilianConversationWorld==nil,"world API leaked after shutdown")
print("PASS conversation reader: scrollback, world Observe feed, live expiry, cached layout, visibility and retention")
