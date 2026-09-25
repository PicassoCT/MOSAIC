function widget:GetInfo()
    return {name="Betrayal runners", desc="Public chase markers and fading blood trails",
        author="MOSAIC contributors", license="GPL3", layer=10, enabled=true}
end
local tracked, trails = {}, {}
local nextTrail=1
local MAX_TRAILS, TRAIL_FRAMES, SPACING = 256, 900, 22
local texture="bitmaps/ProjectileTextures/bloodsplat.tga"
local types={}
for _,name in ipairs({"operativepropagator","operativeinvestigator","operativeasset","civilianagent","deaddropicon"}) do
    if UnitDefNames[name] then types[UnitDefNames[name].id]=true end
end
local function track(id,def)
    -- DrawScreen can run before the next six-frame rules-param refresh.
    if types[def] then tracked[id]=tracked[id] or {execution=0} end
end
function widget:Initialize()
    for _,id in ipairs(Spring.GetAllUnits()) do track(id,Spring.GetUnitDefID(id)) end
end
function widget:UnitCreated(id,def) track(id,def) end
function widget:UnitEnteredLos(id,team,ally,def) track(id,def or Spring.GetUnitDefID(id)) end
function widget:UnitDestroyed(id) tracked[id]=nil end
function widget:GameFrame(frame)
    if frame%6~=0 then return end
    for id,state in pairs(tracked) do
        local running=Spring.GetUnitRulesParam(id,"betrayal_runner")==1
        local x,y,z=Spring.GetUnitPosition(id)
        state.running=running
        state.pending=Spring.GetUnitRulesParam(id,"betrayal_pending")==1
        state.execution=Spring.GetUnitRulesParam(id,"betrayal_execution_frame") or 0
        state.drop=Spring.GetUnitRulesParam(id,"betrayal_drop")==1
        if running and x then
            local hp,maxHP=Spring.GetUnitHealth(id)
            local ground=Spring.GetGroundHeight(x,z)
            if hp and hp<maxHP and ground>=0 and math.abs(y-ground)<24 and
                (not state.x or (x-state.x)^2+(z-state.z)^2>=SPACING^2) then
                local size=4+(id+frame)%4
                trails[nextTrail]={x=x,y=ground,z=z,size=size,born=frame}
                nextTrail=nextTrail%MAX_TRAILS+1
                state.x,state.z=x,z
            end
        end
    end
    for i,trail in pairs(trails) do
        if frame-trail.born>=TRAIL_FRAMES then trails[i]=nil end
    end
end
function widget:DrawWorldPreUnit()
    if next(trails)==nil then return end
    local frame=Spring.GetGameFrame()
    gl.DepthTest(true)
    gl.DepthMask(false)
    gl.PolygonOffset(-2,-2)
    gl.Texture(texture)
    for _,t in pairs(trails) do
        if Spring.IsSphereInView(t.x,t.y,t.z,t.size) then
            local alpha=0.8*math.min(1,(TRAIL_FRAMES-frame+t.born)/180)
            gl.Color(0.55,0.16,0.12,alpha)
            gl.DrawGroundQuad(t.x-t.size,t.z-t.size,t.x+t.size,t.z+t.size,false,true)
        end
    end
    gl.Texture(false)
    gl.PolygonOffset(false)
    gl.DepthMask(true)
    gl.DepthTest(false)
    gl.Color(1,1,1,1)
end
function widget:DrawScreen()
    local frame=Spring.GetGameFrame()
    for id,s in pairs(tracked) do
        local text=s.running and "DEFECTOR - INTERCEPT / RECEIVE" or
            (s.drop and "DEAD DROP - RECOVER") or
            (s.pending and "DEFECTOR - AWAITING CONTACT") or
            (s.execution>frame and ("TERMINATION: "..math.ceil((s.execution-frame)/30).."s - CTRL+D TO CANCEL"))
        if text then
            local x,y,z=Spring.GetUnitPosition(id)
            if x and Spring.IsSphereInView(x,y,z,40) then
                local sx,sy,sz=Spring.WorldToScreenCoords(x,y+55,z)
                if sz and sz<1 then
                    gl.Color(1,0.65,0.3,1)
                    gl.Text(text,sx,sy,13,"oc")
                end
            end
        end
    end
    gl.Color(1,1,1,1)
end
function widget:Shutdown() tracked,trails={},{} end
