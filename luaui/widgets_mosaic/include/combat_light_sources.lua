-- Bounded, client-side combat effects. Expiry never depends on a renderer.
local M = {maxTransient=128, maxFires=128, maxProjectiles=64, maxLights=96}
local function clamp(v,lo,hi) return math.max(lo,math.min(hi,v)) end
-- Railgun light is spent during discharge; the detached wake owns its longer
-- visual lifetime. These sources reuse the existing combat radiance captures.
local railgunColor={.32,.82,1}
local railgunChargePhases={
    {param='mosaic_railgun_charge_a_frame',heights={45,10}},
    {param='mosaic_railgun_charge_b_frame',heights={65,35}},
}
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
local AimLaserGlow = VFS and VFS.Include and
    VFS.Include('luaui/widgets_mosaic/include/aiming_laser_glow.lua') or
    dofile('luaui/widgets_mosaic/include/aiming_laser_glow.lua')

local Sfx = VFS and VFS.Include and
    VFS.Include('luaui/widgets_mosaic/include/combat_sfx_policy.lua') or
    dofile('luaui/widgets_mosaic/include/combat_sfx_policy.lua')

local projectileTypes={Cannon=true,MissileLauncher=true,StarburstLauncher=true,
    LaserCannon=true,BeamLaser=true,LightningCannon=true,DGun=true,Flame=true}
function M.Weapon(wd)
    local cp=wd.customParams or {}
    if cp.light_skip or cp.expl_light_skip or tonumber(cp.no_projectile_vfx)==1 then return nil end
    local fire=wd.type=='Flame' or wd.name=='molotow' or tonumber(cp.molotov_fire)==1
    local railgun=tonumber(cp.railgun_wake)==1
    if not projectileTypes[wd.type] and not fire then return nil end
    local v=wd.visuals or {}
    return {fire=fire,railgun=railgun,nightOnly=not fire and not railgun,
        strength=railgun and 1.1 or .65,
        trail=wd.name=='molotow',tracer=tonumber(cp.night_tracer)==1,
        tracerWidth=clamp(tonumber(cp.tracer_width) or (.8+(wd.size or 1)*.35),.4,3),
        radius=railgun and 160 or clamp(tonumber(cp.light_radius) or (40+(wd.damageAreaOfEffect or 0)*.6),40,220),
        color=railgun and railgunColor or (fire and {1,.32,.045} or {v.colorR or 1,v.colorG or .65,v.colorB or .25})}
end

function M.New(weaponConf, policeProfiles, tankProfiles, debugLampProfiles)
    policeProfiles = policeProfiles or {}
    tankProfiles = tankProfiles or {}
    debugLampProfiles = debugLampProfiles or {}
    local self={transient={},fires={},wrecks={},police={},tanks={},railguns={},debugLamps={},torches={},pyros={},projectiles={},weaponConf=weaponConf,
        brightness=1.3,radius=1.3}
    local aimingLasers = AimLaserGlow.New(Spring,WeaponDefs,UnitDefs)
    self.sfx=Sfx.New(Spring,Game,WeaponDefs,WeaponDefNames)
    local cursor,scanAge=0,1
    local drawFrame,lights,flames,tracers
    local definitions={}
    for id,wd in pairs(WeaponDefs) do
        local def=M.Weapon(wd)
        if def then
            def.priority=self.sfx:Profile(id).priority
            def.sfxKind=self.sfx:Profile(id).kind
        end
        definitions[id]=def
    end
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
        aimingLasers:UnitCreated(id,defID)
        local name=UnitDefs[defID] and UnitDefs[defID].name
        if name=='vehiclecorpse' or name=='tankcorpse' then self.wrecks[id]=name=='tankcorpse' and 1.5 or 1 end
        if name=='ground_walker_flame' then self.pyros[id]={} end
        self.railguns[id]=name=='nimrod' or nil
        local profile=policeProfiles[defID]
        self.police[id]=profile and {profile=profile} or nil
        profile=tankProfiles[defID]
        self.tanks[id]=profile and {profile=profile} or nil
        profile=debugLampProfiles[defID]
        self.debugLamps[id]=profile and {profile=profile} or nil
        drawFrame=nil
    end
    function self:UnitDestroyed(id)
        aimingLasers:UnitDestroyed(id)
        self.wrecks[id]=nil
        self.pyros[id]=nil
        self.police[id]=nil
        self.tanks[id]=nil
        self.railguns[id]=nil
        self.debugLamps[id]=nil
        drawFrame=nil
    end
    function self:HasTankMuzzleFlash(id)
        local record=self.tanks[id]
        return record and TankMuzzle.ActiveFrame(Spring,id,record.profile,Spring.GetGameFrame())~=nil
    end
    function self:AddExplosion(x,y,z,weaponID,muzzle,ownerID)
        if self.sfx:Explosion(x,y,z,weaponID,muzzle,ownerID,visible,unitVisible) then
            drawFrame=nil
            return
        end
        local p=self.weaponConf[weaponID]
        if not p or not visible(x,y,z) then return end
        local priority=self.sfx:Profile(weaponID).priority
        if self.sfx:Gain(priority,x,y,z)<=0 then return end
        local frame=Spring.GetGameFrame()
        cursor=cursor%M.maxTransient+1
        -- Low traffic never evicts a High flash from the bounded event ring.
        if self.transient[cursor] and self.transient[cursor].priority==Sfx.HIGH then
            local free
            for i=1,M.maxTransient do
                local at=(cursor+i-1)%M.maxTransient+1
                if not self.transient[at] or self.transient[at].priority~=Sfx.HIGH then free=at;break end
            end
            if free then cursor=free elseif priority==Sfx.LOW then return end
        end
        local life=math.max(4,muzzle and p.life*.3 or p.life)
        self.transient[cursor]={x=x,y=y+4,z=z,born=frame,expires=frame+life,
            radius=clamp(muzzle and 20+p.radius*.44 or p.radius,30,480),
            color={p.r,p.g,p.b},strength=muzzle and .55 or p.orgMult,nightOnly=true,priority=priority}
        if definitions[weaponID] and definitions[weaponID].railgun then
            local r=self.transient[cursor]
            r.expires=frame+math.max(1,math.floor((muzzle and .4 or .6)*(Game.gameSpeed or 30)+.5))
            r.radius=(muzzle and 150 or 200)*self.radius/1.3
            r.color=railgunColor
            r.strength=(muzzle and 2.4 or 2.8)*self.brightness/1.3
            r.nightOnly=false
            r.fadePower=1.65
            -- Metadata excludes the firing unit's own occupancy. It must not
            -- grant the position the attached-lamp visibility exemption.
            if muzzle and type(ownerID)=='number' and Spring.ValidUnitID(ownerID)
                and not Spring.GetUnitIsDead(ownerID) then r.ownerID=ownerID end
        end
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
        self.sfx:Update()
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
                if x then
                    local gain,d2=self.sfx:Gain(def.priority,x,y,z,cx,cy,cz)
                    -- Tracer geometry has its own cheap, all-distance cue path.
                    if gain>0 or def.tracer then
                        candidates[#candidates+1]={id=id,defID=defID,def=def,d2=d2,priority=def.priority}
                    end
                end
            end
        end
        table.sort(candidates,Sfx.Before)
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
    local function debugLampOrigin(id,record)
        local ux,uy,uz=Spring.GetUnitPosition(id)
        if not ux then return end
        local x,y,z=ux,uy,uz
        if Spring.GetUnitViewPosition then
            local vx,vy,vz=Spring.GetUnitViewPosition(id)
            if vx then x,y,z=vx,vy,vz end
        end
        local p=record.profile
        if record.piece==nil and Spring.GetUnitPieceMap then
            local map=Spring.GetUnitPieceMap(id)
            record.piece=map and map[p.piece] or false
        end
        if record.piece and Spring.GetUnitPiecePosDir then
            local px,py,pz=Spring.GetUnitPiecePosDir(id,record.piece)
            if px then
                return px+x-ux,py+y-uy,pz+z-uz,true
            end
        end
        return x,y+(p.fallbackHeight or 54),z,false
    end
    local function debugLampColor(frame,cycleFrames)
        local h=((frame%(cycleFrames or 240))/(cycleFrames or 240))*6
        local sector=math.floor(h)
        local f=h-sector
        if sector==0 then return {1,f,0} end
        if sector==1 then return {1-f,1,0} end
        if sector==2 then return {0,1,f} end
        if sector==3 then return {0,1-f,1} end
        if sector==4 then return {f,0,1} end
        return {1,0,1-f}
    end
    function self:Collect()
        local stamp=Spring.GetDrawFrame()
        if drawFrame==stamp then return lights,flames,tracers end
        drawFrame=stamp;lights,flames,tracers={},{},{}
        local extraFlames={}
        local cx,cy,cz=Spring.GetCameraPosition()
        local frame=Spring.GetGameFrame()+(Spring.GetFrameTimeOffset() or 0)
        local function add(x,y,z,radius,color,strength,nightOnly,ribbon,tracer,visibleUnitID,priority)
            priority=priority or Sfx.HIGH
            local gain,d2=self.sfx:Gain(priority,x,y,z,cx,cy,cz)
            if gain<=0 or strength<=0 then return end
            if Spring.IsSphereInView and not Spring.IsSphereInView(x,y,z,radius) then return end
            -- A validated unit's visibility is authoritative for attached lamps.
            -- Always-visible police can be outside the terrain's positional LOS.
            -- Unattached combat effects retain their positional visibility check.
            if not visibleUnitID and not visible(x,y,z) then return end
            if ribbon then
                ribbon.opacity=(ribbon.opacity or 1)*gain
                Sfx.PrepareRibbon(ribbon,priority,d2)
            end
            lights[#lights+1]={x=x,y=y,z=z,radius=radius,color=color,strength=strength*gain,
                nightOnly=nightOnly,ribbon=ribbon,tracer=tracer,unitID=visibleUnitID,
                d2=d2,priority=priority,order=#lights+1}
            return lights[#lights]
        end
        local function fire(x,y,z,scale,seed,opacity,priority)
            priority=priority or Sfx.HIGH
            if self.sfx:Gain(priority,x,y,z,cx,cy,cz)<=0 then return end
            local flicker=.82+.11*math.sin(frame*.43+seed)+.07*math.sin(frame*.79+seed*2)
            return add(x,y,z,100*scale*self.radius/1.3,{1,.3,.04},flicker*opacity*self.brightness/1.3,false,
                flame(x,y,z,scale,seed,false,nil,nil,nil,opacity),nil,nil,priority)
        end
        for _,r in pairs(self.transient) do
            if frame<r.expires then
                local fade=clamp((r.expires-frame)/(r.expires-r.born),0,1)
                local light=add(r.x,r.y,r.z,r.radius,r.color,r.strength*fade^(r.fadePower or 1),r.nightOnly,
                    nil,nil,nil,r.priority)
                if light then light.unitID=r.ownerID end
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
        local function closeUnit(id)
            local x,y,z
            if Spring.GetUnitViewPosition then x,y,z=Spring.GetUnitViewPosition(id) end
            if not x then x,y,z=Spring.GetUnitPosition(id) end
            return x and self.sfx:Gain(Sfx.LOW,x,y,z,cx,cy,cz)>0
        end
        for id,scale in pairs(self.wrecks) do
            if (scale>1 or closeUnit(id)) and unitVisible(id) then
                local expires=Spring.GetUnitRulesParam(id,'mosaic_fire_until') or 0
                local piece=Spring.GetUnitRulesParam(id,'mosaic_fire_piece')
                if piece and frame<expires then
                    local x,y,z=Spring.GetUnitPiecePosDir(id,piece)
                    if x then
                        local ux,uy,uz=Spring.GetUnitPosition(id)
                        local vx,vy,vz=Spring.GetUnitViewPosition(id)
                        if ux and vx then x,y,z=x+vx-ux,y+vy-uy,z+vz-uz end
                        local light=fire(x,y+4,z,scale,id,clamp((expires-frame)/15,0,1),scale>1 and Sfx.HIGH or Sfx.LOW)
                        if light and Spring.GetUnitRulesParam(id,'mosaic_fire_broad')==1 then
                            -- Car-only opt-in: one broad upward column at the
                            -- original anchor. Do not alter its radiance light.
                            local ribbon=light.ribbon
                            ribbon.direction={0,1,0}
                            ribbon.length=90*scale
                            ribbon.width=20*scale
                            ribbon.speed=3.0
                            ribbon.strands=4
                            ribbon.curl=.28
                            ribbon.windInfluence=.18
                            ribbon.trailTime=.7
                            ribbon.emission={3.5,.35}
                            ribbon.sourceGlow={1,.3,.03,.55}
                        end
                    end
                end
            end
        end
        -- Police lightbars share the normal combat-light radiance capture: no extra pass.
        -- Two rooftop beacons alternate at 3 Hz, remaining visible by day as well.
        for id,record in pairs(self.police) do
            if closeUnit(id) and unitVisible(id) then
                local profile=record.profile
                local phase=math.floor(frame/profile.phaseFrames)%2
                local x,y,z=policeOrigin(id,record,phase)
                if x then
                    add(x,y,z,profile.radius,profile.colors[phase+1],profile.strength,false,nil,nil,id,Sfx.LOW)
                end
            end
        end
        -- Debug lamps are ordinary attached radiance sources. The moving bulb
        -- therefore exercises the same owner exclusion, mobile blockers,
        -- receiver-height tests and soft shadow path as production lights.
        for id,record in pairs(self.debugLamps) do
            if unitVisible(id) then
                local profile=record.profile
                local x,y,z=debugLampOrigin(id,record)
                if x then
                    add(x,y,z,profile.radius,debugLampColor(frame,profile.cycleFrames),
                        profile.strength,false,nil,nil,id)
                end
            end
        end
        for id,record in pairs(self.tanks) do
            if unitVisible(id) then
                local flash=TankMuzzle.Collect(Spring,id,record,frame)
                if flash then
                    -- The visible plume is directional; submit its radiance as
                    -- a short axis-aligned chain instead of one broad spherical
                    -- bulb.  Only the first source owns the ribbon so the shared
                    -- ribbon budget and renderer behavior remain unchanged.
                    local chain=flash.lights or {flash}
                    for index,source in ipairs(chain) do
                        add(source.x,source.y,source.z,source.radius*self.radius/1.3,
                            flash.color,source.strength*self.brightness/1.3,false,
                            index==1 and flash.ribbon or nil,nil,id)
                    end
                end
            end
        end
        -- Keep the two original Nimrod deployment flash pairs and their heights.
        -- Script timestamps make them finite through UI reloads and offscreen
        -- periods, and visibility checks keep cloaked emplacements concealed.
        local chargeLife=1.4*(Game.gameSpeed or 30)
        for id in pairs(self.railguns) do
            local bornA=Spring.GetUnitRulesParam(id,railgunChargePhases[1].param)
            local bornB=Spring.GetUnitRulesParam(id,railgunChargePhases[2].param)
            local activeA=type(bornA)=='number' and bornA>=0 and frame>=bornA and frame<bornA+chargeLife
            local activeB=type(bornB)=='number' and bornB>=0 and frame>=bornB and frame<bornB+chargeLife
            -- Idle guns need no position, terrain-height or visibility queries.
            if (activeA or activeB) and unitVisible(id) then
                local x,_,z=Spring.GetUnitPosition(id)
                if x then
                    local ground=Spring.GetGroundHeight(x,z)
                    for index,phase in ipairs(railgunChargePhases) do
                        local active=index==1 and activeA or (index==2 and activeB)
                        local born=index==1 and bornA or bornB
                        if active then
                            local strength=.8*(1-(frame-born)/chargeLife)^1.5*self.brightness/1.3
                            for _,height in ipairs(phase.heights) do
                                add(x,ground+height,z,142*self.radius/1.3,railgunColor,strength,false,nil,nil,id)
                            end
                        end
                    end
                end
            end
        end
        -- Glow at each currently visible aiming laser's actual hitscan endpoint.
        -- A small source, not a second beam, CEG, or permanent unit light.
        -- Keep positional LOS checking in add(): a visible drone must not
        -- illuminate a target outside the player's explored sight.
        for _,dot in ipairs(aimingLasers:Collect(unitVisible,cx,cy,cz)) do
            add(dot.x,dot.y,dot.z,AimLaserGlow.radius*self.radius/1.3,
                AimLaserGlow.color,AimLaserGlow.strength*self.brightness/1.3,false)
        end
        self.sfx:Collect(frame,cx,cy,cz,visible,unitVisible,add,extraFlames,self.brightness,self.radius)
        local missileCount=0
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
                    if r.tracer then
                        -- Keep the night tracer even when its expensive detail
                        -- is culled. MG lighting comes from pooled gun flashes,
                        -- never a moving radiance source on every round.
                        if visible(x,y,z) then
                            tracers[#tracers+1]={x=x,y=y,z=z,vx=vx or 0,vy=vy or 0,vz=vz or 0,
                                width=r.tracerWidth,color=r.color}
                        end
                    else
                        local gain,d2=self.sfx:Gain(r.priority,x,y,z,cx,cy,cz)
                        if gain>0 and visible(x,y,z) then
                            local ribbon
                            if r.sfxKind=='missile' then
                                if missileCount<Sfx.maxMissiles then
                                    ribbon=self.sfx:Missile(x,y,z,vx,vy,vz,p.id,r.priority,d2)
                                    missileCount=missileCount+1
                                    add(x,y,z,70*self.radius/1.3,{1,.55,.12},.9*self.brightness/1.3,
                                        false,ribbon,nil,nil,r.priority)
                                end
                            else
                                ribbon=r.fire and flame(x,y,z,r.trail and 1 or .7,p.id,true,vx,vy,vz)
                                add(x,y,z,r.radius*self.radius/1.3,r.color,r.strength*self.brightness/1.3,
                                    r.nightOnly,ribbon,nil,nil,r.priority)
                            end
                        end
                    end
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
        table.sort(lights,Sfx.Before)
        for i=#lights,M.maxLights+1,-1 do lights[i]=nil end
        local ribbonCandidates={}
        for _,l in ipairs(lights) do
            if l.ribbon then
                ribbonCandidates[#ribbonCandidates+1]={ribbon=l.ribbon,d2=l.d2,priority=l.priority,order=#ribbonCandidates+1}
            end
            if l.tracer then tracers[#tracers+1]=l.tracer end
        end
        -- All ribbons share the old cap, including unlit secondary tongues.
        -- Select High before Low here: the renderer may then sort the admitted
        -- set for blending without dropping a distant High for a nearby Low.
        for _,r in ipairs(extraFlames) do
            r.priority=r.priority or Sfx.HIGH
            r.order=#ribbonCandidates+1
            Sfx.PrepareRibbon(r.ribbon,r.priority,r.d2)
            ribbonCandidates[#ribbonCandidates+1]=r
        end
        table.sort(ribbonCandidates,Sfx.Before)
        for i=1,math.min(64,#ribbonCandidates) do flames[i]=ribbonCandidates[i].ribbon end
        self.sfx.stats.missiles=missileCount
        self.sfx.stats.lights=#lights
        self.sfx.stats.ribbons=#flames
        self.sfx.stats.tracers=#tracers
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

