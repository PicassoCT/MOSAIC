-- Visual importance, not hardware quality. Highs remain eligible at strategic
-- zoom; Lows spend lighting/ribbon budget only near the camera. Gameplay and
-- cheap engine projectiles/CEGs are deliberately outside this policy.
local M = {
    HIGH='High', LOW='Low', closeFull=900, closeEnd=1400,
    maxMissiles=8, maxHighEvents=8, maxLowEvents=8,
    highSlots=32, lowSlots=32,
    -- Reserved visual event IDs; never engine weapon IDs or damage commands.
    stickyEvent=-101, empEvent=-102,
}
M.categories={
    sticky='High', emp='High', railgun='High', tank='High',
    strategic='High', hazard='High', debug='High', aiming='High',
    missile='Low', mortar='Low', gun='Low', wreck='Low', police='Low',
    ordinary='Low',
}
local highWeapons={railgun=true,orbitalrailgun=true,tankcannon=true,breachingcannon=true,
    molotow=true,walkerfuelburst=true,ssied=true}
local missiles={s16rocket=true,javelinrocket=true,militaryantiair=true,
    militaryantitank=true,interceptormissile=true,campaignrocket=true}
local mortars={mortar=true,supportmortar=true}
local function clamp(v,a,b) return math.max(a,math.min(b,v)) end
local function finite(v) return type(v)=='number' and v==v and math.abs(v)<1e9 end
function M.CloseGain(d2)
    if d2>=M.closeEnd*M.closeEnd then return 0 end
    if d2<=M.closeFull*M.closeFull then return 1 end
    local t=(math.sqrt(d2)-M.closeFull)/(M.closeEnd-M.closeFull)
    return 1-t*t*(3-2*t)
end
function M.Before(a,b)
    local ah,bh=a.priority==M.HIGH,b.priority==M.HIGH
    if ah~=bh then return ah end
    if a.d2~=b.d2 then return a.d2<b.d2 end
    return (a.order or a.id or 0)<(b.order or b.id or 0)
end
function M.Profiles(defs,names)
    local keys={}
    for name,wd in pairs(names or {}) do
        if wd.id then keys[wd.id]=name:lower() end
    end
    local result={}
    for id,wd in pairs(defs or {}) do
        local cp=wd.customParams or {}
        local key=keys[id] or (wd.name or ''):lower()
        local kind=missiles[key] and 'missile' or mortars[key] and 'mortar'
            or tonumber(cp.night_tracer)==1 and 'gun' or 'ordinary'
        local high=highWeapons[key] or tonumber(cp.railgun_wake)==1 or wd.type=='Flame'
            or tonumber(cp.molotov_fire)==1
        -- Strategic weapons opt in by their actual internal family, not damage
        -- or AoE: a cheap rapid-fire weapon must not accidentally become High.
        if key:find('cruise',1,true) or key:find('godrod',1,true) then high=true end
        local priority=high and M.HIGH or M.LOW
        if cp.sfx_priority=='High' or cp.sfx_priority=='Low' then priority=cp.sfx_priority end
        result[id]={kind=kind,priority=priority,
            skip=cp.light_skip or cp.expl_light_skip or tonumber(cp.no_projectile_vfx)==1}
    end
    return result
end
-- Keep High ribbons inside the existing renderer's distance envelope without
-- changing their physical size. Its finite cutoff is made camera-relative;
-- frustum, LOS, scene depth and the shared 64-ribbon cap still apply.
function M.PrepareRibbon(r,priority,d2)
    r.priority=priority
    if priority==M.HIGH then
        r.distanceFactor=2*(math.sqrt(d2)+math.max(r.length,r.width*2)+1)
            /math.max(.01,r.length,r.width*2)
    end
    return r
end
local function ribbon(x,y,z,length,width,seed,opacity,electric)
    return {x=x,y=y,z=z,length=length,width=width,direction={0,1,0},
        scale=1,speed=electric and 5 or 3.2,curl=electric and .65 or .35,
        seed=seed%10000,strands=2,mode=electric and 'electric' or nil,
        colorStart=electric and {.45,.75,1,.85} or {1,.8,.3,.85},
        colorEnd=electric and {.08,.18,.8,0} or {.85,.12,.015,0},
        emission={3,.15},sourceGlow=electric and {.2,.5,1,.3} or {1,.3,.02,.3},
        windInfluence=0,trailTime=0,velocity={0,0,0},distanceFactor=80,
        opacity=opacity}
end
function M.New(api,game,defs,names)
    local fps=(game and game.gameSpeed) or 30
    local self={profiles=M.Profiles(defs,names),high={},low={},highCursor=0,lowCursor=0,
        serial=0,lastFrame=api.GetGameFrame(),stats={}}
    function self:Profile(id) return self.profiles[id] or {kind='ordinary',priority=M.LOW} end
    function self:Gain(priority,x,y,z,cx,cy,cz)
        if not cx then cx,cy,cz=api.GetCameraPosition() end
        local d2=(x-cx)^2+(y-cy)^2+(z-cz)^2
        if priority==M.HIGH then return 1,d2 end
        -- Overview is never a close-up, even on a very small map. Cache the
        -- camera-state allocation once per draw; no per-emitter state tables.
        if api.GetCameraState then
            local stamp=api.GetDrawFrame and api.GetDrawFrame() or api.GetGameFrame()
            if self.cameraStamp~=stamp then
                local state=api.GetCameraState()
                self.overview=state and state.name=='ov'
                self.cameraStamp=stamp
            end
            if self.overview then return 0,d2 end
        end
        return M.CloseGain(d2),d2
    end
    function self:Update()
        local frame=api.GetGameFrame()
        if frame<self.lastFrame then self.high,self.low={},{} end
        self.lastFrame=frame
        for _,pool in ipairs({self.high,self.low}) do
            for key,r in pairs(pool) do if frame>=r.expires then pool[key]=nil end end
        end
    end
    -- Return true when this specialized effect owns the event, even when it
    -- is culled, so a generic flash cannot leak around a Low cutoff.
    function self:Explosion(x,y,z,id,muzzle,owner,visible,unitVisible)
        local p=self:Profile(id)
        local kind=id==M.stickyEvent and 'sticky' or id==M.empEvent and 'emp' or p.kind
        if kind~='sticky' and kind~='emp' and kind~='mortar' and kind~='gun' then return false end
        if p.skip or not finite(x) or not finite(y) or not finite(z) or not visible(x,y,z) then return true end
        if kind=='gun' and not muzzle then return true end -- no per-bullet hit lights
        if kind=='mortar' and muzzle then return false end
        local priority=(kind=='sticky' or kind=='emp') and M.HIGH or p.priority
        if self:Gain(priority,x,y,z)<=0 then return true end
        if kind=='emp' and owner and owner>=0 and not unitVisible(owner) then return true end
        local frame=api.GetGameFrame()
        self:Update()
        local pool=priority==M.HIGH and self.high or self.low
        -- Merge pulses from the same gun/victim, not one light per bullet/arc.
        if kind=='gun' or kind=='emp' then
            for _,r in pairs(pool) do
                if r.kind==kind and r.owner==owner and frame<r.expires then return true end
            end
        end
        local life=kind=='sticky' and .55 or kind=='emp' and .45 or kind=='mortar' and .45 or .09
        if kind=='gun' then
            local ground=api.GetGroundHeight(x,z)
            -- An aircraft gun high above the road must not create ground light.
            if y-ground>90 then return true end
            y=ground+5
        end
        local index
        if priority==M.HIGH then
            self.highCursor=self.highCursor%M.highSlots+1;index=self.highCursor
        else
            self.lowCursor=self.lowCursor%M.lowSlots+1;index=self.lowCursor
        end
        self.serial=self.serial+1
        pool[index]={kind=kind,priority=priority,x=x,y=y,z=z,owner=owner,
            born=frame,expires=frame+math.max(1,math.ceil(life*fps)),seed=self.serial,
            radius=kind=='sticky' and 150 or kind=='emp' and 95 or kind=='mortar' and 115 or 65}
        return true
    end
    function self:Collect(frame,cx,cy,cz,visible,unitVisible,add,extraFlames,brightness,radius)
        self:Update()
        local selected={}
        for _,pool in ipairs({self.high,self.low}) do
            for _,r in pairs(pool) do
                if frame>=r.born and frame<r.expires then
                    local gain,d2=self:Gain(r.priority,r.x,r.y,r.z,cx,cy,cz)
                    if gain>0 and visible(r.x,r.y,r.z)
                        and (r.kind~='emp' or not r.owner or r.owner<0 or unitVisible(r.owner))
                        and (not api.IsSphereInView or api.IsSphereInView(r.x,r.y,r.z,r.radius)) then
                        selected[#selected+1]={r=r,gain=gain,d2=d2,order=r.seed,priority=r.priority}
                    end
                end
            end
        end
        table.sort(selected,M.Before)
        local high,low=0,0
        for _,s in ipairs(selected) do
            local r=s.r
            local allowed=r.priority==M.HIGH and high<M.maxHighEvents
                or r.priority~=M.HIGH and low<M.maxLowEvents
            if allowed then
                if r.priority==M.HIGH then high=high+1 else low=low+1 end
                local t=clamp((frame-r.born)/(r.expires-r.born),0,1)
                local fade=(1-t)^1.4
                local electric=r.kind=='emp'
                local color=electric and {.25,.55,1} or {1,.48,.09}
                local strength=electric and 1.7 or r.kind=='sticky' and 2.4 or r.kind=='gun' and .7 or 1.6
                if electric then strength=strength*(.45+.55*math.cos(t*math.pi*5)^2) end
                local main
                if r.kind~='gun' then
                    local length=electric and 22 or r.kind=='sticky' and 38 or 30
                    main=ribbon(r.x,r.y+3,r.z,length*(1-.3*t),electric and 4 or 8,r.seed,fade,electric)
                    M.PrepareRibbon(main,r.priority,s.d2)
                end
                local light=add(r.x,r.y+4,r.z,r.radius*radius/1.3,color,
                    strength*fade*brightness/1.3,r.kind=='gun',main,nil,nil,r.priority)
                if light and electric and r.owner and r.owner>=0 then light.unitID=r.owner end
                if light and main and r.kind=='sticky' then
                    -- Two short lobes share one light; no second radiance source.
                    local side=ribbon(r.x,r.y+3,r.z,24,7,r.seed+43,fade,false)
                    local angle=r.seed*2.39996
                    side.direction={math.cos(angle)*.8,.6,math.sin(angle)*.8}
                    side.opacity=side.opacity*s.gain
                    M.PrepareRibbon(side,r.priority,s.d2)
                    extraFlames[#extraFlames+1]={ribbon=side,d2=s.d2,priority=r.priority,order=r.seed}
                end
            end
        end
        self.stats={high=high,low=low,candidates=#selected}
    end
    function self:Missile(x,y,z,vx,vy,vz,id,priority,d2)
        local speed=math.sqrt((vx or 0)^2+(vy or 0)^2+(vz or 0)^2)
        if speed<.001 then return nil end
        local r=ribbon(x,y,z,22,3,id,1,false)
        r.direction={-vx/speed,-vy/speed,-vz/speed}
        r.strands=2;r.curl=.2;r.speed=4
        return M.PrepareRibbon(r,priority,d2)
    end
    return self
end
return M
