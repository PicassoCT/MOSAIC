function gadget:GetInfo()
    return {name='Combat effect events', desc='Visible weapon flashes and bounded persistent Molotov fires',
        author='Floris, MOSAIC contributors', license='GPL V2', layer=0, enabled=true}
end

local types={Cannon=true,MissileLauncher=true,StarburstLauncher=true,AircraftBomb=true,
    LaserCannon=true,BeamLaser=true,LightningCannon=true,DGun=true,Flame=true}
local watched,wanted,railguns={},{},{}
for id,wd in pairs(WeaponDefs) do
    -- Cinder fire projectiles do gameplay damage but never emit individual
    -- muzzle/explosion light events. The unit emits one continuous ribbon.
    local cp=wd.customParams or {}
    if tonumber(cp.railgun_wake)==1 then railguns[id]=true end
    if types[wd.type] and tonumber(cp.no_projectile_vfx)~=1 then
        watched[id]=true;wanted[#wanted+1]=id
    end
end
local molotov=WeaponDefNames.molotow and WeaponDefNames.molotow.id
local fuelburst=WeaponDefNames.walkerfuelburst and WeaponDefNames.walkerfuelburst.id
local pyro=UnitDefNames and UnitDefNames.ground_walker_flame and UnitDefNames.ground_walker_flame.id
local nimrod=UnitDefNames and UnitDefNames.nimrod and UnitDefNames.nimrod.id
local launchWeapon=WeaponDefNames.railgun and WeaponDefNames.railgun.id
local launchTypes={}
for _,name in ipairs({'satellitescan','satelliteanti','satellitegodrod','air_plane_artillery'}) do
    local def=UnitDefNames and UnitDefNames[name]
    if def then launchTypes[def.id]=true end
end
local maxLaunchHeight,launchStep=2048,64
if gadgetHandler:IsSyncedCode() then
    local fires,cursor,lastMuzzle={},0,{}
    local railShots,railCount={},0
    local maxRailShots=32
    local pendingLaunches={}
    local launchAPI={}
    function launchAPI.Departure(unitID,topY)
        local record=pendingLaunches[unitID]
        if not record then return false end
        local owner=record.owner
        if Spring.GetUnitDefID(unitID)~=record.defID or Spring.GetUnitIsDead(unitID)
            or Spring.GetUnitDefID(owner)~=nimrod or Spring.GetUnitIsDead(owner) then
            pendingLaunches[unitID]=nil
            return false
        end
        local _,_,_,_,progress=Spring.GetUnitHealth(unitID)
        if not progress or progress<1 then return false end
        -- Completion alone is insufficient: the payload calls this immediately
        -- before actual departure. A canceled build never reaches this path.
        pendingLaunches[unitID]=nil
        if not launchWeapon or not railguns[launchWeapon]
            or Spring.GetUnitTeam(unitID)~=Spring.GetUnitTeam(owner) then return false end
        local x,y,z
        if Spring.GetUnitPieceMap and Spring.GetUnitPiecePosDir then
            local pieces=Spring.GetUnitPieceMap(owner)
            local barrel=pieces and pieces.projectile
            if barrel then x,y,z=Spring.GetUnitPiecePosDir(owner,barrel) end
        end
        if not x then x,y,z=Spring.GetUnitPosition(unitID) end
        if not x then return false end
        local height=maxLaunchHeight
        if type(topY)=='number' and topY==topY then
            height=math.max(launchStep,math.min(maxLaunchHeight,topY-y))
        end
        -- Synthetic identities cannot collide with engine projectile IDs. The
        -- serial also separates same-frame unit-ID reuse, including gadget reload.
        GG.NimrodLaunchFXSerial=(GG.NimrodLaunchFXSerial or 0)%100000000+1
        SendToUnsynced('nimrod_launch',-GG.NimrodLaunchFXSerial,
            Spring.GetGameFrame(),launchWeapon,owner,Spring.GetUnitAllyTeam(owner),
            Spring.GetUnitIsCloaked(owner) and 1 or 0,x,y,z,height)
        return true
    end
    local function railPoint(projectileID,shot,x,y,z,frame,done)
        if not x then x,y,z=shot.x,shot.y,shot.z end
        if x then
            shot.x,shot.y,shot.z,shot.frame=x,y,z,frame
            SendToUnsynced('railgun_wake_point',projectileID,shot.born,shot.weaponID,
                x,y,z,frame,done and 1 or 0)
        end
        if done then railShots[projectileID]=nil;railCount=railCount-1 end
    end
    local function startRailShot(projectileID,weaponID,x,y,z,frame)
        if not railguns[weaponID] or not x then return end
        if railShots[projectileID] then
            railPoint(projectileID,railShots[projectileID],nil,nil,nil,frame,true)
        end
        if railCount>=maxRailShots then
            local oldestID,oldest
            for id,shot in pairs(railShots) do
                if not oldest or shot.born<oldest.born or (shot.born==oldest.born and id<oldestID) then
                    oldestID,oldest=id,shot
                end
            end
            if oldest then railPoint(oldestID,oldest,nil,nil,nil,frame,true) end
        end
        local shot={born=frame,weaponID=weaponID,expires=frame+15*(Game.gameSpeed or 30)}
        railShots[projectileID]=shot;railCount=railCount+1
        railPoint(projectileID,shot,x,y,z,frame,false)
    end
    _G.MosaicCombatFires=fires
    function gadget:Initialize()
        for id in pairs(watched) do Script.SetWatchWeapon(id,true) end
        GG=GG or {}
        GG.NimrodLaunchFX=launchAPI
    end
    function gadget:UnitCreated(unitID,defID,unitTeam,builderID)
        pendingLaunches[unitID]=nil
        if nimrod and builderID and launchTypes[defID]
            and Spring.GetUnitDefID(builderID)==nimrod then
            pendingLaunches[unitID]={owner=builderID,defID=defID}
        end
    end
    function gadget:Explosion_GetWantedWeaponDef() return wanted end
    function gadget:Explosion(weaponID,x,y,z,ownerID,projectileID)
        if not watched[weaponID] then return end
        SendToUnsynced('explosion_light',x,y,z,weaponID,ownerID)
        local shot=projectileID and railShots[projectileID]
        if shot and shot.weaponID==weaponID then
            -- Orbital noExplode rounds can hit and continue; ordinary railgun
            -- rounds end at this exact impact point rather than an aimed target.
            railPoint(projectileID,shot,x,y,z,Spring.GetGameFrame(),not WeaponDefs[weaponID].noExplode)
        end
        if (weaponID==molotov or weaponID==fuelburst) and y>=0 then
            cursor=cursor%128+1
            local frame=Spring.GetGameFrame()
            fires[cursor]={x=x,y=y,z=z,born=frame,expires=frame+15*(Game.gameSpeed or 30)}
        end
    end
    function gadget:ProjectileCreated(projectileID,ownerID,weaponID)
        weaponID=weaponID or Spring.GetProjectileDefID(projectileID)
        if not watched[weaponID] then return end
        local frame=Spring.GetGameFrame()
        local x,y,z
        -- This happens before generic muzzle throttling, so every burst member
        -- and same-frame short shot has its own identity and observed start.
        if railguns[weaponID] then
            x,y,z=Spring.GetProjectilePosition(projectileID)
            startRailShot(projectileID,weaponID,x,y,z,frame)
        end
        local key=ownerID or -1
        local prior=lastMuzzle[key]
        if prior and frame-prior<3 then return end -- at most 10 Hz per firing unit
        if not railguns[weaponID] then x,y,z=Spring.GetProjectilePosition(projectileID) end
        if x then
            lastMuzzle[key]=frame
            SendToUnsynced('barrelfire_light',x,y,z,weaponID,ownerID)
        end
    end
    function gadget:ProjectileDestroyed(projectileID)
        local shot=railShots[projectileID]
        if shot then
            -- Recoil invokes this before deleting the projectile; retain a
            -- cached endpoint as a fallback for older engine builds.
            local x,y,z=Spring.GetProjectilePosition(projectileID)
            railPoint(projectileID,shot,x,y,z,Spring.GetGameFrame(),true)
        end
    end
    function gadget:UnitDestroyed(id,defID)
        lastMuzzle[id]=nil
        pendingLaunches[id]=nil
        if defID==nimrod then
            for payload,record in pairs(pendingLaunches) do
                if record.owner==id then pendingLaunches[payload]=nil end
            end
        end
        if defID==pyro then
            local x,y,z=Spring.GetUnitPosition(id)
            if x then SendToUnsynced('pyro_torch_off',x,y,z,id) end
        end
    end
    function gadget:GameFrame(frame)
        for id,shot in pairs(railShots) do
            local x,y,z=Spring.GetProjectilePosition(id)
            railPoint(id,shot,x,y,z,frame,not x or frame>=shot.expires)
        end
        if frame%3~=0 then return end
        for id,r in pairs(fires) do if frame>=r.expires then fires[id]=nil end end
    end
    function gadget:Shutdown()
        _G.MosaicCombatFires=nil
        if GG and GG.NimrodLaunchFX==launchAPI then GG.NimrodLaunchFX=nil end
    end
else
    local function visible(x,y,z)
        local _,full=Spring.GetSpectatingState()
        return full or Spring.IsPosInLos(x,y,z,Spring.GetMyAllyTeamID())
    end
    local function Explosion(_,x,y,z,weaponID,ownerID)
        if visible(x,y,z) and Script.LuaUI('GadgetWeaponExplosion') then
            Script.LuaUI.GadgetWeaponExplosion(x,y,z,weaponID,ownerID)
        end
    end
    local function PyroTorch(_,x,y,z,id)
        if visible(x,y,z) and Script.LuaUI('GadgetPyroTorchOff') then
            Script.LuaUI.GadgetPyroTorchOff(x,y,z,id)
        end
    end
    local function Muzzle(_,x,y,z,weaponID,ownerID)
        if visible(x,y,z) and Script.LuaUI('GadgetWeaponBarrelfire') then
            Script.LuaUI.GadgetWeaponBarrelfire(x,y,z,weaponID,ownerID)
        end
    end
    local function RailgunPoint(_,projectileID,born,weaponID,x,y,z,frame,done)
        if visible(x,y,z) then
            if Script.LuaUI('GadgetRailgunWakePoint') then
                Script.LuaUI.GadgetRailgunWakePoint(projectileID,born,weaponID,x,y,z,frame,done)
            end
        elseif Script.LuaUI('GadgetRailgunWakeGap') then
            -- Never forward a hidden position or join two visible sections
            -- across an unobserved part of the projectile's flight.
            Script.LuaUI.GadgetRailgunWakeGap(projectileID,born,frame,done)
        end
    end
    local function NimrodLaunch(_,id,born,weaponID,owner,ownerAlly,wasCloaked,x,y,z,height)
        local _,full=Spring.GetSpectatingState()
        local ally=Spring.GetMyAllyTeamID()
        if not full and ownerAlly~=ally then
            -- Eligibility is decided only at departure. Concealed enemy events
            -- are discarded and cannot be replayed when the gun becomes visible.
            if wasCloaked==1 then return end
            local los=Spring.GetUnitLosState(owner,ally)
            if not los or not los.los then return end
        end
        if visible(x,y,z) then Muzzle(nil,x,y,z,weaponID,owner) end
        -- This is a deliberate local launch stroke, not a fabricated projectile
        -- or a chord to a satellite's map-edge orbital entry. At most 33 samples;
        -- all enter the existing LOS-filtered, bounded, 15-second wake renderer.
        height=math.max(launchStep,math.min(maxLaunchHeight,height))
        local count=math.ceil(height/launchStep)
        for i=0,count do
            RailgunPoint(nil,id,born,weaponID,x,y+height*i/count,z,born,i==count and 1 or 0)
        end
    end
    local lastUpdate
    function gadget:Update()
        -- MOSAIC's gadget handler does not pass dt to Update.
        local now=Spring.GetTimer()
        if lastUpdate and Spring.DiffTimers(now,lastUpdate)<.1 then return end
        lastUpdate=now
        if not Script.LuaUI('GadgetCombatFire') then return end
        local frame=Spring.GetGameFrame()
        -- Snapshot supports LuaUI reloads and entering LOS partway through a fire.
        -- Only visible positions cross into LuaUI. The receiver rechecks LOS.
        for id,r in pairs(SYNCED.MosaicCombatFires or {}) do
            if frame<r.expires and visible(r.x,r.y,r.z) then
                Script.LuaUI.GadgetCombatFire(id,r.x,r.y,r.z,r.born,r.expires)
            end
        end
    end
    function gadget:Initialize()
        gadgetHandler:AddSyncAction('explosion_light',Explosion)
        gadgetHandler:AddSyncAction('barrelfire_light',Muzzle)
        gadgetHandler:AddSyncAction('pyro_torch_off',PyroTorch)
        gadgetHandler:AddSyncAction('railgun_wake_point',RailgunPoint)
        gadgetHandler:AddSyncAction('nimrod_launch',NimrodLaunch)
    end
    function gadget:Shutdown()
        gadgetHandler:RemoveSyncAction('explosion_light')
        gadgetHandler:RemoveSyncAction('barrelfire_light')
        gadgetHandler:RemoveSyncAction('pyro_torch_off')
        gadgetHandler:RemoveSyncAction('railgun_wake_point')
        gadgetHandler:RemoveSyncAction('nimrod_launch')
    end
end

