-- Exercise the placement widget with roof clicks, queue modifiers and GL cleanup.
widget={};UnitDefNames={icon_investigation={id=12}}
UnitDefs={[3]={name='truck'},[4]={name='factory'},[12]={customParams={baseclass='Abstract'}}}
VFS={Include=dofile}
local active=-12
local hitKind,hit='unit',77
local orders,draws,attributes,matrices=0,0,0,0
local last,translation
Spring={
    GetActiveCommand=function() return 1,active end,
    GetMouseState=function() return 400,300 end,
    TraceScreenRay=function(x,y) assert(x==400 and y==300);return hitKind,hit end,
    GetUnitDefID=function(id) assert(id==77);return 4 end,
    GetUnitPosition=function(id) assert(id==77);return 100,20,200 end,
    GetUnitHeight=function() return 80 end,
    GetMyTeamID=function() return 1 end,
    GetGameFrame=function() return 90 end,
    IsGUIHidden=function() return false end,
    GiveOrder=function(cmd,p,options) orders=orders+1;last={cmd=cmd,p=p,options=options} end,
}
GL={ALL_ATTRIB_BITS=1,SRC_ALPHA=2,ONE_MINUS_SRC_ALPHA=3}
gl={
    PushAttrib=function() attributes=attributes+1 end,
    PopAttrib=function() attributes=attributes-1 end,
    PushMatrix=function() matrices=matrices+1 end,
    PopMatrix=function() matrices=matrices-1 end,
    Translate=function(...) translation={...} end,
    Rotate=function() end,Color=function() end,
    DepthTest=function() end,DepthMask=function() end,Blending=function() end,
    UnitShape=function(def,team,raw,toScreen,opaque)
        assert(def==12 and team==1 and not raw and not toScreen and not opaque)
        assert(attributes==1 and matrices==1);draws=draws+1
    end,
}
dofile('luaui/widgets_mosaic/cmd_investigation_build.lua')
widget:DrawWorld()
assert(draws==1 and orders==0, 'Hover preview must not issue commands or construct units')
assert(translation[1]==100 and translation[2]==164 and translation[3]==200)
assert(attributes==0 and matrices==0, 'Preview leaked render state')
-- Ground projection is far beyond the roof: the actual clicked factory wins.
assert(widget:CommandNotify(-12,{900,0,800},{coded=32}))
assert(last.cmd==CMD_BUILD_INVESTIGATION and #last.p==1 and last.p[1]==77 and last.options==32)
assert(widget:CommandNotify(-12,{77},{shift=true,alt=true}))
assert(last.options[1]=='shift' and last.options[2]=='alt')
hitKind,hit='ground',{900,0,800}
assert(not widget:CommandNotify(-12,{900,0,800},{}), 'Ground coordinates use synced nearest-target validation')
widget:DrawWorld();assert(draws==1)
active=10;hitKind,hit='unit',77
widget:DrawWorld();assert(draws==1)
assert(not widget:CommandNotify(10,{77},{}));assert(orders==2)
print('PASS Investigation UI: hologram placement preview, exact roof target, queued builds, no Repair action, render-state cleanup')
