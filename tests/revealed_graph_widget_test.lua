-- Run from repository root: lua tests/revealed_graph_widget_test.lua
-- Exercises the real UI with the existing serialized LuaRules payload contract.
local frame, hidden, dead = 100, false, {}
local callback, text, vertices = nil, {}, {}
local currentColor, currentMode
local function finite(n) return type(n) == 'number' and n == n and math.abs(n) < math.huge end
widget = {}
GL = {LINES=1, LINE_STRIP=2, LINE_LOOP=3, SRC_ALPHA=4, ONE_MINUS_SRC_ALPHA=5}
UnitDefs = {[1]={speed=2}, [2]={speed=0, isBuilding=true}}
Spring = {
    GetGameFrame=function() return frame end,
    GetUnitIsDead=function(id) return dead[id] or false end,
    WorldToScreenCoords=function(x,y,z) return x, z+y, x < 0 and 2 or 0.5 end,
    IsGUIHidden=function() return hidden end,
    GetMouseState=function() return 0,0 end,
}
-- Deliberately no unit position, command, or LuaRules APIs: rendering must use
-- only the disclosed positions and must never modify simulation state.
widgetHandler = {
    RegisterGlobal=function(_,_,name,fn) assert(name=='RevealedGraphChanged'); callback=fn end,
    DeregisterGlobal=function(_,name) assert(name=='RevealedGraphChanged'); callback=nil end,
}
gl = {
    Color=function(r,g,b,a) assert(finite(r) and finite(g) and finite(b) and finite(a)); currentColor={r,g,b,a} end,
    LineWidth=function(n) assert(finite(n) and n>0) end,
    BeginEnd=function(mode,fn) currentMode=mode; fn() end,
    Vertex=function(x,y) assert(finite(x) and finite(y)); vertices[#vertices+1]={x,y,mode=currentMode,color=currentColor} end,
    Rect=function(x,y,xx,yy) assert(finite(x) and finite(y) and finite(xx) and finite(yy)) end,
    Text=function(value,x,y,size) assert(finite(x) and finite(y) and size>0); text[#text+1]=value end,
    GetTextWidth=function(value) return #value*0.55 end,
    GetViewSizes=function() return 1920,1080 end,
    DepthTest=function() end, Blending=function() end,
}
local function has(value)
    for _,v in ipairs(text) do if v==value then return true end end
    return false
end
local function draw()
    text, vertices = {}, {}
    widget:DrawScreen()
end
local function payload(x)
    return 'return {[2]={x=850,y=20,z=400,teamID=1,endFrame=400,revealedUnits={'..
        '[10]={pos={x=200,y=30,z=200},defID=1,boolIsParent=true,name="Handler"},'..
        '[11]={pos={x='..x..',y=10,z=600},defID=1,boolIsParent=false,name="Asset"},'..
        '[12]={pos={x=1400,y=40,z=200},defID=2,boolIsParent=false,name="Safehouse"}'..
        '}}}'
end
dofile('luaui/widgets_mosaic/gui_RevealedGraph.lua')
widget:Initialize()
assert(callback)
callback(payload(1200))
draw()
frame=130; draw()
assert(has('SOURCE') and has('RECRUITER') and has('RECRUITED') and has('BUILT'))
assert(has('HANDLER') and has('ASSET') and has('SAFEHOUSE') and has('9 s'))
-- Purple link runs from parent to source; orange links run out from source.
local purple, orange = {}, {}
for _,v in ipairs(vertices) do
    if v.mode==GL.LINES and v.color[4]==0.7 then
        -- Dark under-strokes are the first segment of each connection.
        if #purple<2 then purple[#purple+1]=v elseif #orange<2 then orange[#orange+1]=v end
    end
end
assert(#purple==2 and purple[1][1]<purple[2][1], 'parent arrow must lead toward source')
assert(#orange==2 and orange[1][1]<orange[2][1], 'child arrow must lead away from source')
callback(payload(1300)); draw()
assert(has('9 s'), 'position refresh must not restart expiry')
dead[11]=true; draw(); assert(not has('ASSET') and has('SAFEHOUSE'))
hidden=true; draw(); assert(#text==0 and #vertices==0); hidden=false
callback('not valid Lua'); draw(); assert(has('SOURCE'), 'malformed update must preserve last valid payload')
callback('return Spring.GiveOrder(1)'); draw(); assert(has('SOURCE'), 'payload environment must be isolated')
frame=400; draw(); assert(#text==0 and #vertices==0, 'expired reveals must not render')
-- A reveal behind the camera and a zero-length edge must remain finite.
frame=500
callback('return {[8]={x=-10,y=0,z=0,teamID=1,endFrame=600,revealedUnits={}}}')
draw(); assert(#text==0)
callback('return {[8]={x=200,y=0,z=200,teamID=1,endFrame=600,revealedUnits={[12]={pos={x=200,y=0,z=200},defID=2,name="Same place"}}}}')
draw(); frame=530; draw(); assert(has('BUILT'))
callback('return {}'); draw(); assert(#text==0)
widget:Shutdown(); assert(callback==nil)
print('PASS: reveal roles, direction, sparse data, refresh, death, expiry, GUI hiding, projection, cleanup')
