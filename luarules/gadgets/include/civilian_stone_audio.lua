-- Cosmetic stone-contact notifications and local, close-camera playback.
-- Camera/FPS decisions never enter the deterministic projectile simulation.
local M={event="civilian_stone_impact",maxEventsPerFrame=8,
    fullDistance=220,maxDistance=500,minFPS=30,maxUpdateSeconds=.05,
    minSimulationRatio=.9,maxSoundsPerSecond=4,minGapFrames=3}
local directory="sounds/physics/stone_impacts/"
M.profiles={
    vehicle={volume=.48,files={
        "stone_vehicle_01_door_skin.ogg","stone_vehicle_02_metal_panel.ogg",
        "stone_vehicle_03_heavy_panel.ogg"}},
    person={volume=.38,files={
        "stone_person_01_dull_thud.ogg","stone_person_02_compact_hit.ogg",
        "stone_person_03_weighted_thud.ogg"}},
    building_ground={volume=.45,files={
        "stone_building_ground_01_stone_grit.ogg","stone_building_ground_02_hard_surface.ogg",
        "stone_building_ground_03_heavy_structure.ogg"}},
}
local surfaceByClass={civilian="person",truck="vehicle",tank="vehicle"}
-- Human also labels software icons and combat arenas; only actual people opt in.
local humanNames={operativeinvestigator=true,operativepropagator=true,
    operativeasset=true,civilianagent=true,civilian_suicidebomber=true}
local function finite(v) return type(v)=="number" and v==v and math.abs(v)<1e9 end
function M.UnitKinds(defs)
    local kinds={}
    for id,def in pairs(defs) do
        local cp=def.customParams or {}
        local kind=surfaceByClass[string.lower(cp.baseclass or "")]
        if humanNames[def.name] then kind="person" end
        kinds[id]=not def.isBuilding and kind or "building_ground"
    end
    return kinds
end
function M.NewEmitter(S,send)
    local lastFrame,count=-1,0
    return function(kind,x,y,z,projectile,bounce)
        if not M.profiles[kind] or not finite(x) or not finite(y) or not finite(z) then return false end
        local frame=S.GetGameFrame()
        if frame~=lastFrame then lastFrame,count=frame,0 end
        if count>=M.maxEventsPerFrame then return false end
        count=count+1
        send(M.event,kind,x,y,z,projectile or 0,bounce==true)
        return true
    end
end
function M.NewPlayer(S,Game)
    local api={}
    local second,count,lastFrame,lastSound=-1,0,-1,-math.huge
    local lastVariant={}
    local framesPerSecond=(Game and Game.gameSpeed) or 30
    function api:Receive(kind,x,y,z,projectile,bounce)
        local profile=M.profiles[kind]
        if not profile or not finite(x) or not finite(y) or not finite(z) then return false end
        -- Drop suppressed events immediately: never replay a backlog on zoom-in.
        local fps=S.GetFPS and S.GetFPS()
        if not finite(fps) or fps<M.minFPS then return false end
        local dt=S.GetLastUpdateSeconds and S.GetLastUpdateSeconds()
        if dt and (not finite(dt) or dt>M.maxUpdateSeconds) then return false end
        if S.GetGameSpeed then
            local wanted,actual,paused=S.GetGameSpeed()
            if paused or (wanted and actual and wanted>0 and actual<wanted*M.minSimulationRatio) then return false end
        end
        local camera=S.GetCameraState and S.GetCameraState()
        if camera and camera.name=="ov" then return false end
        local cx,cy,cz=S.GetCameraPosition()
        if not finite(cx) or not finite(cy) or not finite(cz) then return false end
        local d2=(x-cx)^2+(y-cy)^2+(z-cz)^2
        if d2>=M.maxDistance*M.maxDistance then return false end
        if S.IsSphereInView and not S.IsSphereInView(x,y,z,24) then return false end
        local _,fullView=S.GetSpectatingState()
        if not fullView and not S.IsPosInLos(x,y,z,S.GetMyAllyTeamID()) then return false end
        local frame=S.GetGameFrame()
        if frame<lastFrame then second,count,lastSound=-1,0,-math.huge end
        lastFrame=frame
        local bucket=math.floor(frame/framesPerSecond)
        if bucket~=second then second,count=bucket,0 end
        if count>=M.maxSoundsPerSecond or frame-lastSound<M.minGapFrames then return false end
        local distance=math.sqrt(d2)
        local t=math.max(0,(distance-M.fullDistance)/(M.maxDistance-M.fullDistance))
        local gain=1-t*t*(3-2*t)
        local index=(math.floor(finite(projectile) and projectile or frame)%#profile.files)+1
        if lastVariant[kind]==index then index=index%#profile.files+1 end
        lastVariant[kind]=index
        count,lastSound=count+1,frame
        S.PlaySoundFile(directory..profile.files[index],profile.volume*gain*(bounce and .45 or 1),x,y,z)
        return true
    end
    return api
end
return M
