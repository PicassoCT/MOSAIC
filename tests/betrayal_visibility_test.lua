-- Actual reveal sender: dense lists survive holes, deaths and normal expiration.
GG={RevealedLocations={
    [1]={endFrame=30,revealedUnits={[10]={pos={}}}},
    [3]={endFrame=100,revealedUnits={[11]={pos={}},[12]={pos={}}}},
}}
local alive={[10]=true,[11]=true}
gadget={};gadgetHandler={IsSyncedCode=function() return true end}
VFS={Include=function() end}
Spring={GetGameFrame=function() return 0 end,GetUnitPosition=function(id) if alive[id] then return id,0,id end end}
function doesUnitExistAlive(id) return alive[id]==true end
function serializeTableToString(t) return tostring(#t) end
local sent
function SendToUnsynced(action,value) sent=value end
dofile('luarules/gadgets/send_RevealedUnitsData.lua');gadget:Initialize()
gadget:GameFrame(30)
assert(#GG.RevealedLocations==1 and GG.RevealedLocations[1].revealedUnits[11])
assert(not GG.RevealedLocations[1].revealedUnits[12]);assert(sent=='1')
gadget:GameFrame(102);assert(type(GG.RevealedLocations)=='table' and #GG.RevealedLocations==0)

-- Actual widget: bounded ground marks, no trails on water/rooftops or while stationary.
widget={};UnitDefNames={operativeasset={id=1}}
local frame,x,y,z=0,100,0,100
local running,hp,ground,execution=true,300,0,nil
local draws,labels=0,{}
Spring={GetAllUnits=function() return {1} end,GetUnitDefID=function() return 1 end,
    GetUnitRulesParam=function(id,k)
        if k=='betrayal_runner' then return running and 1 or 0 end
        if k=='betrayal_execution_frame' then return execution end
    end,
    GetUnitPosition=function() return x,y,z end,GetUnitHealth=function() return hp,750 end,
    GetGroundHeight=function() return ground end,GetGameFrame=function() return frame end,
    IsSphereInView=function() return true end,
    WorldToScreenCoords=function() return 100,100,0.5 end}
gl={DepthTest=function() end,DepthMask=function() end,PolygonOffset=function() end,
    Texture=function() end,Color=function() end,
    DrawGroundQuad=function() draws=draws+1 end,
    Text=function(text) labels[#labels+1]=text end}
dofile('luaui/widgets_mosaic/gui_betrayal_runners.lua');widget:Initialize()
widget:DrawScreen();assert(#labels==0,'new tracker drew an uninitialized marker')
widget:UnitCreated(2,1);widget:DrawScreen()
widget:UnitEnteredLos(3,0,0,1);widget:DrawScreen()
widget:UnitDestroyed(2);widget:UnitDestroyed(3)
frame=6;widget:GameFrame(frame);widget:DrawWorldPreUnit();assert(draws==1)
widget:UnitEnteredLos(1,0,0,1);widget:DrawScreen()
assert(labels[#labels]=='DEFECTOR - INTERCEPT / RECEIVE','LOS reentry cleared active runner state')
frame=12;widget:GameFrame(frame);draws=0;widget:DrawWorldPreUnit();assert(draws==1,'stationary runner paints no extra blood')
x=x+30;y=100;frame=18;widget:GameFrame(frame);draws=0;widget:DrawWorldPreUnit();assert(draws==1,'no blood projected from roof')
y=0;ground=-10;frame=24;widget:GameFrame(frame);draws=0;widget:DrawWorldPreUnit();assert(draws==1,'no underwater blood')
ground=0;hp=750;frame=30;widget:GameFrame(frame);draws=0;widget:DrawWorldPreUnit();assert(draws==1,'uninjured runners do not bleed')
hp=300
for i=1,400 do x=x+30;frame=36;widget:GameFrame(frame) end
widget:UnitDestroyed(1);draws=0;widget:DrawWorldPreUnit();assert(draws<=256,'blood has a hard budget')
frame=1002;widget:GameFrame(frame);draws=0;widget:DrawWorldPreUnit();assert(draws==0,'blood must expire after death')
running=false;execution=frame+90
widget:UnitCreated(4,1);widget:GameFrame(frame);labels={};widget:DrawScreen()
assert(labels[1]=='TERMINATION: 3s - CTRL+D TO CANCEL','execution countdown is missing')
execution=nil;frame=frame+6;widget:GameFrame(frame);labels={};widget:DrawScreen()
assert(#labels==0,'absent execution parameter left a countdown')
print('PASS betrayal presentation: draw before refresh, creation/LOS reentry, countdown, graph expiry, holes, dead contacts, bounded blood, terrain and lifetime')
