-- Actual report publisher and widget, with fog-of-war and UI boundary checks.
local frame,team,ally,hidden=0,1,1,false
local rules,writes={},0
Spring={GetGameFrame=function() return frame end,
    GetGameRulesParam=function(k) return rules[k] end,
    SetGameRulesParam=function(k,v,access) assert(access.public);rules[k]=v;writes=writes+1 end}
local reports=dofile('luarules/gadgets/include/police_scanner_reports.lua').New()
for n=1,100 do reports.Report('violence',{x=n,y=0,z=n+10}) end
assert(writes==0)
reports.Flush();assert(writes==12 and rules.police_scanner_x==100)
reports.Flush();assert(writes==12,'Idle radio must not write every tick')

local units={
    [1]={team=0,los=true,x=100}, -- Gaia
    [2]={team=1,los=true,x=200}, -- own unit
    [3]={team=3,los=true,x=300}, -- ally
    [4]={team=2,los=false,x=400}, -- radar / fog
    [5]={team=2,los=false,x=500},
}
local camera,scans,reads,rectangles,texts,pings=nil,0,0,{}, {},0
local width,height=1920,1080
WG={topbar={GetPosition=function() return {500,height-50,width,height} end}}
Spring.GetGaiaTeamID=function() return 0 end
Spring.GetMyTeamID=function() return team end
Spring.GetMyAllyTeamID=function() return ally end
Spring.AreTeamsAllied=function(a,b) return a==b or (a==1 and b==3) end
Spring.GetUnitTeam=function(id) return units[id] and units[id].team end
Spring.GetUnitLosState=function(id) return {los=units[id] and units[id].los} end
Spring.GetUnitPosition=function(id)
    assert(units[id].los,'Read enemy coordinates through fog')
    reads=reads+1;return units[id].x,0,units[id].x+10
end
Spring.GetAllUnits=function() scans=scans+1;return {1,2,3,4,5} end
Spring.GetGameRulesParam=function(k) return rules[k] end
Spring.GetViewGeometry=function() return width,height,0,0 end
Spring.GetMouseState=function() return 0,0 end
Spring.IsGUIHidden=function() return hidden end
Spring.GetGroundHeight=function() return 0 end
Spring.SetCameraTarget=function(x,y,z,duration) camera={x=x,y=y,z=z,duration=duration} end
gl={Color=function() end,Rect=function(...) rectangles[#rectangles+1]={...} end,
    Text=function(text) texts[#texts+1]=text end,
    DrawGroundCircle=function() pings=pings+1 end}
rules={}
widget={};dofile('luaui/widgets_mosaic/gui_police_scanner.lua');widget:Initialize()
local function tick(f) frame=f;widget:Update(0.25) end
local function click()
    rectangles={};widget:DrawScreen();local b=assert(rectangles[1])
    assert(widget:IsAbove((b[1]+b[3])/2,(b[2]+b[4])/2))
    assert(widget:MousePress((b[1]+b[3])/2,(b[2]+b[4])/2,1))
end
local function pause() widget:Update(5.1) end
local function expect(x) click();assert(camera.x==x,'Expected '..x..', got '..tostring(camera.x)) end
local function radio(kind,x,f)
    frame=f;reports.Report(kind,{x=x,y=0,z=x+10});reports.Flush()
end
assert(scans==1 and reads==0,'No coordinates read without hostile visual contact')
click();assert(not camera,'Empty scanner does not move camera')
frame=30;units[5].los=true;widget:UnitEnteredLos(5,2)
expect(500);assert(camera.duration==0.6)
assert(widget:GetTooltip():find('Enemy sighting',1,true))
widget:DrawWorld();assert(pings==1)
units[5].x=550;tick(60);expect(550);expect(550)
assert(texts[#texts-1]:find('1/1',1,true),'Continuous observation stays one event')
units[5].los=false;widget:UnitLeftLos(5,2);units[5].x=9999
local before=reads;tick(90);expect(550)
assert(reads==before,'Lost sighting freezes; no hidden coordinate read')
radio('hostage',700,100);tick(105)
expect(550) -- Incoming events cannot interrupt an active click cycle.
pause();expect(700);expect(550);expect(700)
widget:UnitEnteredLos(4,2);tick(120);pause();expect(700)
assert(reads==before,'Radar-only contact is never read')
units[4].los=true;widget:UnitEnteredLos(4,2,9)
pause();expect(700) -- Other ally team's LOS callback ignored.
widget:UnitEnteredLos(4,2,1);pause()
expect(400);expect(700);expect(550);expect(400)
assert(texts[#texts-1]:find('3/3',1,true),'Button shows cycle position')
units[4].x=410;tick(150)
expect(700);expect(550);expect(410) -- Updating a contact never reshuffles the cycle.
widget:UnitDestroyed(4);units[4]=nil;tick(180)
expect(700);expect(550);expect(410)
assert(scans==1,'Steady-state widget never scans the world')
-- Three reports between UI polls must all survive, even at the same coordinates.
radio('violence',900,200);radio('hostage',910,210);radio('cybercrime',920,220)
tick(225);expect(700) -- Existing snapshot still intact.
pause();expect(920);expect(910);expect(900);expect(920)
-- A fourth event evicts the oldest, and repeated polling creates no duplicates.
radio('hostage_death',930,230);tick(240);tick(255)
pause();expect(930);expect(920);expect(910);expect(930)
hidden=true
assert(not widget:MousePress(960,990,1) and not widget:IsAbove(960,990))
local oldPings=pings;widget:DrawWorld();assert(pings==oldPings);hidden=false
width,height=1024,768;widget:ViewResize();expect(920)
-- Changing viewed team clears private sightings and restores only public history.
team,ally=2,2;units[2].los=false;units[3].los=false
widget:PlayerChanged();expect(930);expect(920);expect(910);assert(scans==2)
widget={};dofile('luaui/widgets_mosaic/gui_police_scanner.lua');widget:Initialize()
expect(930);expect(920);expect(910)
-- Publisher reload keeps monotonically increasing report IDs.
reports=dofile('luarules/gadgets/include/police_scanner_reports.lua').New()
radio('violence',940,260);tick(270);pause();expect(940);expect(930);expect(920)
-- Two reports on the same frame remain separate events with stable order.
radio('hostage',950,280);radio('hostage_death',960,280);tick(285)
pause();expect(960);expect(950);expect(940)
-- Widget-only reload during an old match still supports the legacy radio fields.
rules={police_scanner_frame=0,police_scanner_kind='violence',police_scanner_x=80,
    police_scanner_y=0,police_scanner_z=90}
widget={};dofile('luaui/widgets_mosaic/gui_police_scanner.lua');widget:Initialize()
expect(80);tick(300);expect(80);assert(texts[#texts-1]:find('1/1',1,true))
rules={};widget={};dofile('luaui/widgets_mosaic/gui_police_scanner.lua');widget:Initialize()
local saved=camera;click();assert(camera==saved and widget:GetTooltip():find('waiting',1,true))
print('PASS scanner: three-event cycling/wrap/eviction, stable active cycle, timeout reset, radio backlog/reload, deduplication, fog, camera/ping, team change, empty state')
