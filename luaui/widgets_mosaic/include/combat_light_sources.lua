-- Bounded, client-side combat effects. Expiry never depends on a renderer.
local M = {maxTransient=128, maxFires=128, maxProjectiles=64, maxLights=96}
local function clamp(v,lo,hi) return math.max(lo,math.min(hi,v)) end
-- Visual-only obstruction solver, independent from synced Flame projectile damage.
local makePyroCollision = VFS and VFS.Include and
    VFS.Include('luaui/widgets_mosaic/include/pyro_flame_collision.lua') or
    dofile('luaui/widgets_mosaic/include/pyro_flame_collision.lua')
local PyroCollision = makePyroCollision(Spring)
local makePyroBudget = VFS and VFS.Include and
    VFS.Include('luaui/widgets_mosaic/include/pyro_flame_budget.lua') or
    dofile('luaui/widgets_mosaic/include/pyro_flame_budget.lua')
local PyroBudget = makePyroBudget(Spring,PyroCollision)
local TankMuzzle = VFS and VFS.Include and
    VFS.Include('luaui/widgets_mosaic/include/tank_muzzle_flash.lua') or
    dofile('luaui/widgets_mosaic/include/tank_muzzle_flash.lua')

local projectileTypes={Cannon=true,MissileLauncher=true,StarburstLauncher=true,
    LaserCannon=true,BeamLaser=true,LightningCannon=true,DGun=true,Flame=true}
function M.Weapon(wd)
    local cp=wd.customParams or {}
    if cp.light_skip or cp.expl_light_skip or tonumber(cp.no_projectile_vfx)==1 then return nil end
    local fire=wd.type=='Flame' or wd.name=='molotow' or tonumber(cp.molotov_fire)==1
    if not projectileTypes[wd.type] and not fire then return nil end
    local v=wd.visuals or {}
    return {fire=fire,trail=wd.name=='molotow',tracer=tonumber(cp.night_tracer)==1,
        tracerWidth=clamp(tonumber(cp.tracer_width) or (.8+(wd.size or 1)*.35),.4,3),
        radius=clamp(tonumber(cp.light_radius) or (40+(wd.damageAreaOfEffect or 0)*.6),40,220),
        color=fire and {1,.32,.045} or {v.colorR or 1,v.colorG or .65,v.colorB or .25}}
end

function M.New(weaponConf, policeProfiles, tankProfiles)
    policeProfiles = policeProfiles or {}
    tankProfiles = tankProfiles or {}
    local self={transient={},fires={},wrecks={},police={},tanks={},torches={},pyros={},projectiles={},weaponConf=weaponConf,
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
        if name=='ground_walker_flame' then self.pyros[id]={} end
        local profile=policeProfiles[defID]
        self.police[id]=profile and {profile=profile} or nil
        profile=tankProfiles[defID]
        self.tanks[id]=profile and {profile=profile} or nil
        drawFrame=nil
    end
    function self:UnitDestroyed(id)
        self.wrecks[id]=nil
        self.pyros[id]=nil
        self.police[id]=nil
        self.tanks[id]=nil
        drawFrame=nil
    end
    function self:HasTankMuzzleFlash(id)
        local record=self.tanks[id]
        return record and TankMuzzle.ActiveFrame(Spring,id,record.profile,Spring.GetGameFrame())~=nil
    end
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
    -- Track one world-space FlamePainter jet per currently firing pyro walker.
    -- The gameplay projectiles have no independent smoke, flash or light record.
    local function pyroOrigin(id,record)
        local wx,wy,wz,dx,dy,dz
        if Spring.GetUnitWeaponVectors then
            wx,wy,wz,dx,dy,dz=Spring.GetUnitWeaponVectors(id,1)
        end
        if not record.piece and Spring.GetUnitPieceMap then
            local map=Spring.GetUnitPieceMap(id)
            record.piece=map and map.emitfire
        end
        local x,y,z
        if record.piece then
            local px,py,pz,pdx,pdy,pdz=Spring.GetUnitPiecePosDir(id,record.piece)
            x,y,z=px,py,pz
            if not dx then dx,dy,dz=pdx,pdy,pdz end
        end
        if not x then x,y,z=wx,wy,wz end
        if not x then return end
        local mag=dx and dy and dz and math.sqrt(dx*dx+dy*dy+dz*dz) or 0
        if mag<0.001 and Spring.GetUnitVectors then
            local front=Spring.GetUnitVectors(id)
            if front then dx,dy,dz=front[1],front[2],front[3] end
            mag=dx and math.sqrt(dx*dx+dy*dy+dz*dz) or 0
        end
        if mag<0.001 then return end
        local ux,uy,uz=Spring.GetUnitPosition(id)
        local vx,vy,vz
        if Spring.GetUnitViewPosition then vx,vy,vz=Spring.GetUnitViewPosition(id) end
        if ux and vx then x,y,z=x+vx-ux,y+vy-uy,z+vz-uz end
        return x,y,z,dx/mag,dy/mag,dz/mag
    end
    local function policeOrigin(id,record,phase)
        local ux,uy,uz=Spring.GetUnitPosition(id)
        if not ux then return end
        local x,y,z=ux,uy,uz
        if Spring.GetUnitViewPosition then
            local vx,vy,vz=Spring.GetUnitViewPosition(id)
            if vx then x,y,z=vx,vy,vz end
        end
        local front,up,right=Spring.GetUnitVectors(id)
        if not front or not up or not right then return end
        local p=record.profile
        if not record.pieces and Spring.GetUnitPieceMap then
            local map=Spring.GetUnitPieceMap(id)
            if map then record.pieces={map[p.pieces[1]],map[p.pieces[2]]} end
        end
        local piece=record.pieces and record.pieces[phase+1]
        if piece and Spring.GetUnitPiecePosDir then
            local px,py,pz=Spring.GetUnitPiecePosDir(id,piece)
            if px then
                -- Piece positions are at the simulation transform; keep the
                -- light on the drawn roof as the vehicle moves or tilts.
                return px+x-ux+up[1]*p.pieceLift,
                    py+y-uy+up[2]*p.pieceLift,
                    pz+z-uz+up[3]*p.pieceLift, true
            end
        end
        local side=phase==0 and -p.fallbackSpacing or p.fallbackSpacing
        return x+up[1]*p.fallbackHeight+front[1]*p.fallbackForward+right[1]*side,
            y+up[2]*p.fallbackHeight+front[2]*p.fallbackForward+right[2]*side,
            z+up[3]*p.fallbackHeight+front[3]*p.fallbackForward+right[3]*side, false
    end
    function self:Collect()
        local stamp=Spring.GetDrawFrame()
        if drawFrame==stamp then return lights,flames,tracers end
        drawFrame=stamp;lights,flames,tracers={},{},{}
        local extraFlames={}
        local cx,cy,cz=Spring.GetCameraPosition()
        local frame=Spring.GetGameFrame()+(Spring.GetFrameTimeOffset() or 0)
        local function add(x,y,z,radius,color,strength,nightOnly,ribbon,tracer,visibleUnitID)
            -- A validated unit's visibility is authoritative for attached lamps.
            -- Always-visible police can be outside the terrain's positional LOS.
            -- Unattached combat effects retain their positional visibility check.
            if not visibleUnitID and not visible(x,y,z) then return end
            lights[#lights+1]={x=x,y=y,z=z,radius=radius,color=color,strength=strength,
                nightOnly=nightOnly,ribbon=ribbon,tracer=tracer,unitID=visibleUnitID,
                d2=(x-cx)^2+(y-cy)^2+(z-cz)^2,order=#lights+1}
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
                main.strands=4 -- ribbon mesh supports at most four strands
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
        for id,record in pairs(self.police) do
            if unitVisible(id) then
                local profile=record.profile
                local phase=math.floor(frame/profile.phaseFrames)%2
                local x,y,z=policeOrigin(id,record,phase)
                if x then
                    add(x,y,z,profile.radius,profile.colors[phase+1],profile.strength,false,nil,nil,id)
                end
            end
        end
        for id,record in pairs(self.tanks) do
            if unitVisible(id) then
                local flash=TankMuzzle.Collect(Spring,id,record,frame)
                if flash then
                    add(flash.x,flash.y,flash.z,flash.radius*self.radius/1.3,
                        flash.color,flash.strength*self.brightness/1.3,false,flash.ribbon,nil,id)
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
        -- Full/simplified Cinder LOD is chosen *after* existing combat effects,
        -- before any collision rays or additional ribbons are built.
        -- Never spend the shared 64-ribbon allowance on hidden/distant pyros.
        local reserved=0
        for _,light in ipairs(lights) do
            if light.ribbon then reserved=reserved+1 end
        end
        PyroBudget.Collect(self.pyros,{
            simFrame=Spring.GetGameFrame(),frame=frame,
            cx=cx,cy=cy,cz=cz,otherRibbons=reserved,
            unitVisible=unitVisible,origin=pyroOrigin,flame=flame,
            add=add,extraFlames=extraFlames,brightness=self.brightness,
        })
        self.pyroStats=PyroBudget.lastStats
        table.sort(lights,function(a,b) if a.d2==b.d2 then return a.order<b.order end;return a.d2<b.d2 end)
        for i=#lights,M.maxLights+1,-1 do lights[i]=nil end
        for _,l in ipairs(lights) do
            if l.ribbon then flames[#flames+1]=l.ribbon end
            if l.tracer then tracers[#tracers+1]=l.tracer end
        end
        -- Side streamers have no ground-light record. Keep the nearest within
        -- the existing 64-FlamePainter budget so massed Cinders are bounded.
        table.sort(extraFlames,function(a,b) return a.d2<b.d2 end)
        for i=1,math.min(#extraFlames,math.max(0,64-#flames)) do
            flames[#flames+1]=extraFlames[i].ribbon
        end
        return lights,flames,tracers
    end
    -- On-demand diagnostics; no extra per-frame LOS or piece queries.
    -- Read the shot stamp even after the brief flash has expired, so a user can
    -- distinguish a missing firing event from a missed screenshot window.
    function self:GetTankMuzzleStats()
        local stats={tracked=0,visible=0,active=0,queued=0,missingAnchors=0}
        local frame=Spring.GetGameFrame()+(Spring.GetFrameTimeOffset() or 0)
        for id,record in pairs(self.tanks) do
            stats.tracked=stats.tracked+1
            if unitVisible(id) then
                stats.visible=stats.visible+1
                local born=Spring.GetUnitRulesParam(id,record.profile.shotParam)
                if type(born)=='number' and born>=0 and born<=frame then
                    stats.latestShotFrame=math.max(stats.latestShotFrame or born,born)
                end
                if TankMuzzle.ActiveFrame(Spring,id,record.profile,frame) then
                    stats.active=stats.active+1
                    if not TankMuzzle.Collect(Spring,id,record,frame) then
                        stats.missingAnchors=stats.missingAnchors+1
                    end
                end
            end
        end
        if stats.latestShotFrame then stats.latestShotAge=frame-stats.latestShotFrame end
        for _,light in ipairs(self:Collect()) do
            if light.unitID and self.tanks[light.unitID] and light.ribbon then
                stats.queued=stats.queued+1
            end
        end
        return stats
    end
    function self:GetPoliceLightStats()
        local stats={tracked=0,visible=0,emitted=0,outsidePointLos=0,anchored=0,fallback=0}
        local frame=Spring.GetGameFrame()+(Spring.GetFrameTimeOffset() or 0)
        for id,record in pairs(self.police) do
            stats.tracked=stats.tracked+1
            if unitVisible(id) then
                stats.visible=stats.visible+1
                local phase=math.floor(frame/record.profile.phaseFrames)%2
                local x,y,z,anchored=policeOrigin(id,record,phase)
                if x then
                    local key=anchored and 'anchored' or 'fallback'
                    stats[key]=stats[key]+1
                    if not visible(x,y,z) then stats.outsidePointLos=stats.outsidePointLos+1 end
                end
            end
        end
        for _,light in ipairs(self:Collect()) do
            if light.unitID and self.police[light.unitID] then stats.emitted=stats.emitted+1 end
        end
        return stats
    end
    return self
end
return M
