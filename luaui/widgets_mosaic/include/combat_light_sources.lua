-- Bounded, client-side combat effects. Expiry never depends on a renderer.
local M = {maxTransient=128, maxFires=128, maxProjectiles=64, maxLights=96}
local function clamp(v,lo,hi) return math.max(lo,math.min(hi,v)) end
local projectileTypes={Cannon=true,MissileLauncher=true,StarburstLauncher=true,
    LaserCannon=true,BeamLaser=true,LightningCannon=true,DGun=true,Flame=true}
function M.Weapon(wd)
    local cp=wd.customParams or {}
    if cp.light_skip or cp.expl_light_skip then return nil end
    local fire=wd.type=='Flame' or wd.name=='molotow' or tonumber(cp.molotov_fire)==1
    if not projectileTypes[wd.type] and not fire then return nil end
    local v=wd.visuals or {}
    return {fire=fire,trail=wd.name=='molotow',tracer=tonumber(cp.night_tracer)==1,
        tracerWidth=clamp(tonumber(cp.tracer_width) or (.8+(wd.size or 1)*.35),.4,3),
        radius=clamp(tonumber(cp.light_radius) or (40+(wd.damageAreaOfEffect or 0)*.6),40,220),
        color=fire and {1,.32,.045} or {v.colorR or 1,v.colorG or .65,v.colorB or .25}}
end

function M.New(weaponConf)
    local self={transient={},fires={},wrecks={},police={},torches={},projectiles={},weaponConf=weaponConf,
        brightness=1.3,radius=1.3}
    local cursor,scanAge=0,1
    local drawFrame,lights,flames,tracers
    local definitions={}
    for id,wd in pairs(WeaponDefs) do definitions[id]=M.Weapon(wd) end
    local function visible(x,y,z)
        local _,full=Spring.GetSpectatingState()
        return full or Spring.IsPosInLos(x,y,z,Spring.GetMyAllyTeamID())
    end
    local function unitVisible(id)
        if not Spring.ValidUnitID(id) or Spring.GetUnitIsDead(id) or Spring.GetUnitIsCloaked(id)
            or Spring.GetUnitNoDraw(id) or Spring.GetUnitTransporter(id) then return false end
        local _,full=Spring.GetSpectatingState()
        local los=full or Spring.GetUnitLosState(id,Spring.GetMyAllyTeamID())
        return full or (los and los.los)
    end
    function self:UnitCreated(id,defID)
        local name=UnitDefs[defID] and UnitDefs[defID].name
        if name=='vehiclecorpse' or name=='tankcorpse' then self.wrecks[id]=name=='tankcorpse' and 1.5 or 1 end
        if name=='policetruck' then self.police[id]=true end
    end
    function self:UnitDestroyed(id) self.wrecks[id]=nil;self.police[id]=nil;drawFrame=nil end
    function self:AddExplosion(x,y,z,weaponID,muzzle)
        local p=self.weaponConf[weaponID]
        if not p or not visible(x,y,z) then return end
        local frame=Spring.GetGameFrame()
        cursor=cursor%M.maxTransient+1
        local life=math.max(4,muzzle and p.life*.3 or p.life)
        self.transient[cursor]={x=x,y=y+4,z=z,born=frame,expires=frame+life,
            radius=clamp(muzzle and 20+p.radius*.44 or p.radius,30,480),
            color={p.r,p.g,p.b},strength=muzzle and .55 or p.orgMult,nightOnly=true}
        drawFrame=nil
    end
    function self:SetFire(id,x,y,z,born,expires)
        if expires<=Spring.GetGameFrame() then return end
        -- IDs are slots in the synced bounded fire ring, never an unbounded counter.
        if type(id)~='number' or id<1 or id>M.maxFires then return end
        local old=self.fires[id]
        if old and old.born==born and old.expires==expires and old.x==x and old.y==y and old.z==z then return end
        self.fires[id]={x=x,y=y,z=z,born=born,expires=expires}
        drawFrame=nil
    end
    function self:AddPyroTorch(x,y,z,id)
        if not visible(x,y,z) then return end
        local now=Spring.GetGameFrame()
        self.torches[id]={x=x,y=y,z=z,born=now,expires=now+42,seed=id%10000}
        drawFrame=nil
    end
    function self:Update(dt)
        local frame=Spring.GetGameFrame()
        for key,r in pairs(self.transient) do if frame>=r.expires then self.transient[key]=nil end end
        for key,r in pairs(self.fires) do if frame>=r.expires then self.fires[key]=nil end end
        for key,r in pairs(self.torches) do if frame>=r.expires then self.torches[key]=nil end end
        scanAge=scanAge+dt
        if scanAge<.1 then return end
        scanAge=0
        local cx,cy,cz=Spring.GetCameraPosition()
        local candidates={}
        for _,id in ipairs(Spring.GetVisibleProjectiles() or {}) do
            local defID=Spring.GetProjectileDefID(id)
            local def=definitions[defID]
            if def then
                local x,y,z=Spring.GetProjectilePosition(id)
                if x then candidates[#candidates+1]={id=id,defID=defID,def=def,d2=(x-cx)^2+(y-cy)^2+(z-cz)^2} end
            end
        end
        table.sort(candidates,function(a,b) if a.d2==b.d2 then return a.id<b.id end;return a.d2<b.d2 end)
        for i=#candidates,M.maxProjectiles+1,-1 do candidates[i]=nil end
        self.projectiles=candidates;drawFrame=nil
    end
    local function flame(x,y,z,scale,seed,trail,vx,vy,vz,opacity)
        return {x=x,y=y,z=z,length=(trail and 24 or 45)*scale,width=(trail and 4 or 12)*scale,
            direction={0,1,0},velocity={vx or 0,vy or 0,vz or 0},scale=1,
            speed=2.2,curl=.65,seed=seed%10000,strands=3,
            colorStart={1,.7,.2,.8},colorEnd={.8,.1,.015,0},emission={3,.3},
            sourceGlow={1,.3,.03,.5},windInfluence=.45,trailTime=trail and .1 or .6,
            distanceFactor=50,opacity=opacity or 1}
    end
    function self:Collect()
        local stamp=Spring.GetDrawFrame()
        if drawFrame==stamp then return lights,flames,tracers end
        drawFrame=stamp;lights,flames,tracers={},{},{}
        local cx,cy,cz=Spring.GetCameraPosition()
        local frame=Spring.GetGameFrame()+(Spring.GetFrameTimeOffset() or 0)
        local function add(x,y,z,radius,color,strength,nightOnly,ribbon,tracer)
            if not visible(x,y,z) then return end
            lights[#lights+1]={x=x,y=y,z=z,radius=radius,color=color,strength=strength,
                nightOnly=nightOnly,ribbon=ribbon,tracer=tracer,d2=(x-cx)^2+(y-cy)^2+(z-cz)^2,order=#lights+1}
        end
        local function fire(x,y,z,scale,seed,opacity)
            local flicker=.82+.11*math.sin(frame*.43+seed)+.07*math.sin(frame*.79+seed*2)
            add(x,y,z,100*scale*self.radius/1.3,{1,.3,.04},flicker*opacity*self.brightness/1.3,false,
                flame(x,y,z,scale,seed,false,nil,nil,nil,opacity))
        end
        for _,r in pairs(self.transient) do
            if frame<r.expires then
                local fade=clamp((r.expires-frame)/(r.expires-r.born),0,1)
                add(r.x,r.y,r.z,r.radius,r.color,r.strength*fade,true)
            end
        end
        for id,r in pairs(self.fires) do
            if frame<r.expires then
                local fade=clamp((r.expires-frame)/30,0,1)
                fire(r.x,r.y+5,r.z,1.1,id,fade)
            end
        end
        -- One upward ruptured-tank torch and four smaller splashing fuel jets.
        -- Direction and strength are purely visual; gameplay AoE remains in WeaponDef.
        for id,r in pairs(self.torches) do
            if frame<r.expires then
                local t=clamp((frame-r.born)/(r.expires-r.born),0,1)
                local opacity=(1-t)^1.35
                local main=flame(r.x,r.y+21,r.z,1.2,r.seed,false,0,6,0,opacity)
                main.direction={0,1,0}
                main.length=95*(1-.35*t)
                main.width=15*(1-.4*t)
                main.speed=4.0
                main.strands=5
                main.windInfluence=.18
                add(r.x,r.y+23,r.z,145,{1,.38,.055},2.1*opacity,false,main)
                for i=1,4 do
                    local angle=i*math.pi*.5+(r.seed%11)*.17
                    local dx,dz=math.cos(angle),math.sin(angle)
                    local spread=26+10*i
                    local fx,fz=r.x+dx*spread,r.z+dz*spread
                    local jet=flame(fx,r.y+8,fz,.55,r.seed+i*47,false,dx*4,1.7,dz*4,opacity*.75)
                    jet.direction={dx*.9,.28,dz*.9}
                    jet.length=32+6*(i%2)
                    jet.width=5
                    jet.strands=2
                    jet.curl=.85
                    jet.windInfluence=.3
                    add(fx,r.y+8,fz,62,{1,.26,.035},.65*opacity,false,jet)
                end
            end
        end
        for id,scale in pairs(self.wrecks) do
            if unitVisible(id) then
                local expires=Spring.GetUnitRulesParam(id,'mosaic_fire_until') or 0
                local piece=Spring.GetUnitRulesParam(id,'mosaic_fire_piece')
                if piece and frame<expires then
                    local x,y,z=Spring.GetUnitPiecePosDir(id,piece)
                    if x then
                        local ux,uy,uz=Spring.GetUnitPosition(id)
                        local vx,vy,vz=Spring.GetUnitViewPosition(id)
                        if ux and vx then x,y,z=x+vx-ux,y+vy-uy,z+vz-uz end
                        fire(x,y+4,z,scale,id,clamp((expires-frame)/15,0,1))
                    end
                end
            end
        end
        -- Police lightbars share the normal combat-light radiance capture: no extra pass.
        -- Two rooftop beacons alternate at 3 Hz, remaining visible by day as well.
        for id in pairs(self.police) do
            if unitVisible(id) then
                local x,y,z=Spring.GetUnitPosition(id)
                local _,_,right=Spring.GetUnitVectors(id)
                if x and right then
                    local phase=math.floor(frame/5)%2
                    local side=phase==0 and -1 or 1
                    local color=phase==0 and {1,.025,.015} or {.025,.18,1}
                    local lx,lz=x+right[1]*side*11,z+right[3]*side*11
                    add(lx,y+37,lz,135,color,2.4,false)
                end
            end
        end
        for _,p in ipairs(self.projectiles) do
            -- Def check prevents a reused projectile ID inheriting an old flame.
            if Spring.GetProjectileDefID(p.id)==p.defID then
                local x,y,z=Spring.GetProjectilePosition(p.id)
                if x then
                    local vx,vy,vz=Spring.GetProjectileVelocity(p.id)
                    -- Recoil GetProjectilePosition returns simulation position.
                    -- Match its render interpolation; velocity is per sim frame.
                    local offset=Spring.GetFrameTimeOffset() or 0
                    x,y,z=x+(vx or 0)*offset,y+(vy or 0)*offset,z+(vz or 0)*offset
                    local r=p.def
                    local ribbon=r.fire and flame(x,y,z,r.trail and 1 or .7,p.id,true,vx,vy,vz)
                    local tracer=r.tracer and {x=x,y=y,z=z,vx=vx or 0,vy=vy or 0,vz=vz or 0,
                        width=r.tracerWidth,color=r.color}
                    add(x,y,z,r.radius*self.radius/1.3,r.color,.65*self.brightness/1.3,not r.fire,ribbon,tracer)
                end
            end
        end
        table.sort(lights,function(a,b) if a.d2==b.d2 then return a.order<b.order end;return a.d2<b.d2 end)
        for i=#lights,M.maxLights+1,-1 do lights[i]=nil end
        for _,l in ipairs(lights) do
            if l.ribbon then flames[#flames+1]=l.ribbon end
            if l.tracer then tracers[#tracers+1]=l.tracer end
        end
        return lights,flames,tracers
    end
    return self
end
return M
