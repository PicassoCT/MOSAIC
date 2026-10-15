-- Headless rendering contract for the world-space civilian Observe transcript.
-- The real camera, glyph metrics and depth behaviour still need a Recoil check.
local captured, rects, textDraws, widthCalls, sent = {}, {}, {}, 0, {}
local color = {1,1,1,1}
local env = setmetatable({
    widget={}, WG={}, GL={SRC_ALPHA=1,ONE_MINUS_SRC_ALPHA=2},
    LUAUI_DIRNAME="luaui/", UnitDefs={[1]={name="civilian_arab0",height=32}},
}, {__index=_G})
env.Spring={
    IsUnitIcon=function() return false end,
    IsUnitInView=function() return true end,
    GetTeamColor=function() return 1,1,1 end,
    GetUnitTeam=function() return 0 end,
    GetUnitDefID=function() return 1 end,
    GetUnitPosition=function() return 100,0,100 end,
    GetUnitTooltip=function() return "Citizen Ten" end,
    GetConfigString=function(_,fallback) return fallback end,
    GetViewGeometry=function() return 1280,720 end,
    GetMouseState=function() return 500,350 end,
    TraceScreenRay=function() return "unit",10 end,
    SendLuaRulesMsg=function(msg) sent[#sent+1]=msg end,
    IsGUIHidden=function() return false end,
}
env.gl={
    LineWidth=function() end, DepthTest=function() end, DepthMask=function() end,
    AlphaTest=function() end, Texture=function() end,
    Translate=function() end, Rotate=function() end, Billboard=function() end,
    PolygonOffset=function() end, Blending=function() end,
    BeginText=function() end, EndText=function() end,
    LoadFont=function() return {} end, DeleteFont=function() end,
    Color=function(r,g,b,a)
        if type(r)=="table" then color={r[1],r[2],r[3],r[4]}
        else color={r,g,b,a} end
    end,
    Rect=function(x1,y1,x2,y2)
        rects[#rects+1]={x1=x1,y1=y1,x2=x2,y2=y2,alpha=color[4]}
    end,
    Text=function(str,x,y,size)
        textDraws[#textDraws+1]={str=str,x=x,y=y,size=size}
    end,
    GetTextWidth=function(str)
        widthCalls=widthCalls+1
        return #str*0.5
    end,
    DrawFuncAtUnit=function(_,_,fn,...) return fn(...) end,
}
local fn=assert(loadfile("luaui/widgets_mosaic/gui_unit_tracking.lua"))
setfenv(fn,env); fn()
env.widget:Initialize()
env.widget:KeyRelease(111)
assert(env.WG.ObservedCivilianUnits[10],"O did not create an observation marker")
assert(sent[1]=="SET_TRACKED:10","observing did not notify LuaRules")

local revision=100
local lines={
    {name="Citizen Ten",text="An older bit of chatter."},
    {name="Citizen Eleven",text="The traffic cameras are watching again."},
    {name="Citizen Ten",text="Do the cameras even blink, or do we have to pay for that?"}
}
env.WG.CivilianConversationWorld={
    GetRecentLines=function()
        if not lines then return nil end
        return lines, math.max(1,#lines-2), #lines, revision
    end
}
local function redraw()
    rects,textDraws={},{}
    env.widget:DrawWorld()
    local background
    for _,r in ipairs(rects) do
        if r.alpha==0.75 and r.y2-r.y1>2 then background=r end
    end
    return background
end
local bg=assert(redraw(),"observed civilian did not receive a dialogue box")
-- Marker is from -60 to +120 in X, and from -20 to +20 in Y.
assert(bg.x2-bg.x1<=2*180,"world box wider than twice the icon")
assert(bg.y2-bg.y1<=2*40,"world box taller than twice the icon")
assert(bg.y2 < -20,"conversation is not below its observation icon")
assert(bg.alpha==0.75,"25% transparency should be alpha 0.75")
local sawRecent=false
for _,line in ipairs(textDraws) do
    if line.str:find("blink",1,true) then sawRecent=true end
    if line.str:find("Citizen Ten:",1,true) or line.str:find("blink",1,true)
            or line.str:find("Citizen Eleven:",1,true) then
        assert(line.x>=bg.x1+5,"speech starts outside its box")
        assert(line.x+#line.str*0.5*line.size <= bg.x2-5,"speech exceeds the box width")
    end
end
assert(sawRecent,"latest generated text was not drawn")
local widths=widthCalls; redraw()
assert(widthCalls==widths,"unchanged speech was unnecessarily rewrapped")

-- Stress the strict box limits, including generated words with no whitespace.
lines={{name="Citizen Ten",text=string.rep("A",600)}}
revision=101; bg=assert(redraw(),"very long speech hid the box")
assert(bg.x2-bg.x1<=360 and bg.y2-bg.y1<=80,"long speech broke icon-relative caps")
local worldRows=0
for _,line in ipairs(textDraws) do
    if line.str:find("Citizen Ten:",1,true) or line.str:find("AAA",1,true) then
        worldRows=worldRows+1
        assert(line.x+#line.str*0.5*line.size<=bg.x2-5,"oversized token escaped box")
    end
end
assert(worldRows<=6 and worldRows>=1,"world transcript not capped to available height")

lines=nil
assert(not redraw(),"expired or invisible speech still generated a box")
env.widget:KeyRelease(127)
assert(not env.WG.ObservedCivilianUnits[10],"Delete did not clear observation markers")
assert(sent[#sent]=="SET_UNTRACKED:10","Delete did not notify LuaRules")
env.widget:Shutdown()
print("PASS in-world observation: marker anchoring, 75% opacity, icon-relative bounds, wrapping, caching, expiry and clearing")
