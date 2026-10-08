function gadget:GetInfo()
    return {name='Combat effect events', desc='Visible weapon flashes and bounded persistent Molotov fires',
        author='Floris, MOSAIC contributors', license='GPL V2', layer=0, enabled=true}
end

local types={Cannon=true,MissileLauncher=true,StarburstLauncher=true,AircraftBomb=true,
    LaserCannon=true,BeamLaser=true,LightningCannon=true,DGun=true,Flame=true}
local watched,wanted={},{}
for id,wd in pairs(WeaponDefs) do
    -- Cinder fire projectiles do gameplay damage but never emit individual
    -- muzzle/explosion light events. The unit emits one continuous ribbon.
    local cp=wd.customParams or {}
    if types[wd.type] and tonumber(cp.no_projectile_vfx)~=1 then
        watched[id]=true;wanted[#wanted+1]=id
    end
end
local molotov=WeaponDefNames.molotow and WeaponDefNames.molotow.id
local fuelburst=WeaponDefNames.walkerfuelburst and WeaponDefNames.walkerfuelburst.id
local pyro=UnitDefNames and UnitDefNames.ground_walker_flame and UnitDefNames.ground_walker_flame.id
if gadgetHandler:IsSyncedCode() then
    local fires,cursor,lastMuzzle={},0,{}
    _G.MosaicCombatFires=fires
    function gadget:Initialize()
        for id in pairs(watched) do Script.SetWatchWeapon(id,true) end
    end
    function gadget:Explosion_GetWantedWeaponDef() return wanted end
    function gadget:Explosion(weaponID,x,y,z,ownerID)
        if not watched[weaponID] then return end
        SendToUnsynced('explosion_light',x,y,z,weaponID,ownerID)
        if (weaponID==molotov or weaponID==fuelburst) and y>=0 then
            cursor=cursor%128+1
            local frame=Spring.GetGameFrame()
            fires[cursor]={x=x,y=y,z=z,born=frame,expires=frame+15*(Game.gameSpeed or 30)}
        end
    end
    function gadget:ProjectileCreated(projectileID,ownerID,weaponID)
        if not watched[weaponID] then return end
        local frame=Spring.GetGameFrame()
        local key=ownerID or -1
        local prior=lastMuzzle[key]
        if prior and frame-prior<3 then return end -- at most 10 Hz per firing unit
        local x,y,z=Spring.GetProjectilePosition(projectileID)
        if x then
            lastMuzzle[key]=frame
            SendToUnsynced('barrelfire_light',x,y,z,weaponID,ownerID)
        end
    end
    function gadget:UnitDestroyed(id,defID)
        lastMuzzle[id]=nil
        if defID==pyro then
            local x,y,z=Spring.GetUnitPosition(id)
            if x then SendToUnsynced('pyro_torch_off',x,y,z,id) end
        end
    end
    function gadget:GameFrame(frame)
        if frame%3~=0 then return end
        for id,r in pairs(fires) do if frame>=r.expires then fires[id]=nil end end
    end
    function gadget:Shutdown() _G.MosaicCombatFires=nil end
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
    end
    function gadget:Shutdown()
        gadgetHandler:RemoveSyncAction('explosion_light')
        gadgetHandler:RemoveSyncAction('barrelfire_light')
        gadgetHandler:RemoveSyncAction('pyro_torch_off')
    end
end
