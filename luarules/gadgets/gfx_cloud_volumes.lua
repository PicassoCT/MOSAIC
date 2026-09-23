function gadget:GetInfo()
    return {name='Procedural Cloud Volumes', desc='Piece clouds and independent impact volumes', author='Mosaic contributors', layer=2, enabled=true}
end
local Config=VFS.Include('luarules/gadgets/include/cloud_volume_config.lua')
if gadgetHandler:IsSyncedCode() then
    local records,api,serial={}, {},0
    _G.CloudVolumeRecords=records; _G.CloudVolumeRevision=0
    local function changed() _G.CloudVolumeRevision=_G.CloudVolumeRevision+1 end
    function api.SetPiece(id,piece,preset)
        if not Config.Preset(preset) or not Spring.ValidUnitID(id) then return false end
        if type(piece)=='string' then piece=(Spring.GetUnitPieceMap(id) or {})[piece] end
        if type(piece)~='number' then return false end
        local k=id..':'..piece
        if records[k] and records[k].preset==preset then return true end
        local center,half=Config.Bounds(id,piece)
        if not center then return false end
        records[k]={unitID=id,piece=piece,preset=preset,center=center,half=half,
            born=Spring.GetGameFrame(),seed=(id*13+piece*7)%997}
        changed(); return true
    end
    function api.RemovePiece(id,piece)
        local k=id..':'..tostring(piece)
        if records[k] then records[k]=nil;changed() end
    end
    -- World-space effects intentionally survive destruction of their source unit.
    function api.Burst(preset,x,y,z,scale)
        local p=Config.Preset(preset)
        scale=scale or 1
        if not p or not p.duration or not Config.finite(x) or not Config.finite(y) or not Config.finite(z)
            or not Config.finite(scale) or scale<=0 or scale>8 then return false end
        serial=serial+1
        -- Bound registry growth during mass payload events; visuals never affect damage.
        records['burst:'..(serial-256)]=nil
        records['burst:'..serial]={preset=preset,x=x,y=y,z=z,scale=scale,born=Spring.GetGameFrame(),seed=serial%997}
        changed(); return true
    end
    function gadget:GameFrame(frame)
        if frame%15~=0 then return end
        local dirty=false
        for k,r in pairs(records) do
            if not r.unitID and frame-r.born>=Config.Preset(r.preset).duration*(Game.gameSpeed or 30) then
                records[k]=nil;dirty=true
            end
        end
        if dirty then changed() end
    end
    function gadget:UnitDestroyed(id)
        local dirty=false
        for k,r in pairs(records) do if r.unitID==id then records[k]=nil;dirty=true end end
        if dirty then changed() end
    end
    function gadget:Initialize() GG.CloudVolume=api end
    function gadget:Shutdown()
        if GG.CloudVolume==api then GG.CloudVolume=nil end
        _G.CloudVolumeRecords=nil;_G.CloudVolumeRevision=nil
    end
else
    local renderer,revision
    function gadget:Initialize()
        local err
        renderer,err=VFS.Include('luarules/gadgets/include/cloud_volume_renderer.lua')(Config)
        if not renderer then Spring.Echo('Cloud volumes disabled: '..tostring(err));gadgetHandler:RemoveGadget(self) end
    end
    function gadget:DrawWorld()
        if not renderer then return end
        if revision~=SYNCED.CloudVolumeRevision then
            revision=SYNCED.CloudVolumeRevision
            local records={}
            for k,s in pairs(SYNCED.CloudVolumeRecords or {}) do
                local r={}
                for _,f in ipairs({'unitID','piece','preset','born','seed','x','y','z','scale'}) do r[f]=s[f] end
                if s.center then r.center={s.center[1],s.center[2],s.center[3]};r.half={s.half[1],s.half[2],s.half[3]} end
                records[k]=r
            end
            renderer.records=records
        end
        renderer:Draw()
    end
    function gadget:Shutdown() if renderer then renderer:Shutdown() end end
end
