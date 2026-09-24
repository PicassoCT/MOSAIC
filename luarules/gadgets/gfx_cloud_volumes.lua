function gadget:GetInfo()
    return {name='Procedural Cloud Volumes', desc='Piece clouds and independent impact volumes', author='Mosaic contributors', layer=2, enabled=true}
end
local Config=VFS.Include('luarules/gadgets/include/cloud_volume_config.lua')
if gadgetHandler:IsSyncedCode() then
    local records,api,serial={}, {},0
    _G.CloudVolumeRecords=records; _G.CloudVolumeRevision=0
    local function changed() _G.CloudVolumeRevision=_G.CloudVolumeRevision+1 end
    function api.SetPiece(id,piece,preset)
        if not Config.Preset(preset) then return false,'unknown preset '..tostring(preset) end
        if not Spring.ValidUnitID(id) then return false,'invalid unit' end
        if type(piece)=='string' then piece=(Spring.GetUnitPieceMap(id) or {})[piece] end
        if type(piece)~='number' then return false,'piece not found' end
        local k=id..':'..piece
        if records[k] and records[k].preset==preset then return true end
        local center,half=Config.Bounds(id,piece)
        if not center then return false,half end
        records[k]={unitID=id,piece=piece,preset=preset,center=center,half=half,
            born=Spring.GetGameFrame(),seed=(id*13+piece*7)%997}
        changed(); return true
    end
    function api.RemovePiece(id,piece)
        local k=id..':'..tostring(piece)
        if records[k] then records[k]=nil;changed() end
    end
    -- Freeze lingering smoke in world space before the script resets its proxy.
    -- Only round smoke profiles opt in; fire and exhaust stop immediately.
    function api.ReleasePiece(id,piece)
        local k=id..':'..tostring(piece)
        local r=records[k]
        if not r then return end
        local p=Config.Preset(r.preset)
        if p.linger and Spring.GetUnitVectors and Spring.GetUnitPieceMatrix then
            local x,y,z=Spring.GetUnitPiecePosDir(id,piece)
            local front,up,right=Spring.GetUnitVectors(id)
            local m={Spring.GetUnitPieceMatrix(id,piece)}
            if x and front and up and right and m[16] then
                local center={x,y,z};local half={0,0,0}
                for j=1,3 do
                    local col=(j-1)*4
                    for axis=1,3 do
                        -- Spring model X is opposite the unit's right vector.
                        local v=-right[axis]*m[col+1]+up[axis]*m[col+2]+front[axis]*m[col+3]
                        center[axis]=center[axis]+v*r.center[j]
                        half[axis]=half[axis]+math.abs(v)*r.half[j]
                    end
                end
                serial=serial+1
                records['burst:'..(serial-256)]=nil
                records['burst:'..serial]={preset=r.preset,born=r.born,seed=r.seed,
                    x=center[1],y=center[2],z=center[3],worldHalf=half,duration=p.lifetime}
            end
        end
        records[k]=nil;changed()
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
            if not r.unitID and frame-r.born>=(r.duration or Config.Preset(r.preset).duration)*(Game.gameSpeed or 30) then
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
    function gadget:Initialize()
        GG.CloudVolume=api
        gadgetHandler:AddChatAction('cloudvolumes',function(_,_,_,playerID)
            SendToUnsynced('cloud_volume_report',playerID)
            return true
        end,'Report cloud renderer and selected piece registration')
        Spring.Echo('Cloud volumes: synced API ready; /luarules cloudvolumes')
    end
    function gadget:Shutdown()
        gadgetHandler:RemoveChatAction('cloudvolumes')
        if GG.CloudVolume==api then GG.CloudVolume=nil end
        _G.CloudVolumeRecords=nil;_G.CloudVolumeRevision=nil
    end
else
    local renderer,revision,rendererError
    local function report()
        Spring.Echo('Cloud volumes: renderer '..(renderer and 'ready' or ('FAILED: '..tostring(rendererError)))
            ..'; synced registry '..(SYNCED.CloudVolumeRevision~=nil and 'ready' or 'MISSING'))
        local selected=Spring.GetSelectedUnits() or {}
        if #selected==0 then Spring.Echo('Select the pump station or spaceport, then /luarules cloudvolumes');return true end
        for _,id in ipairs(selected) do
            local matched,registered,rejected=0,0,0
            local details={}
            for name,piece in pairs(Spring.GetUnitPieceMap(id) or {}) do
                if Config.SpaceportPreset(name) or Config.PumpPreset(name) then
                    matched=matched+1
                    if (SYNCED.CloudVolumeRecords or {})[id..':'..piece] then registered=registered+1 end
                    local center,reason=Config.Bounds(id,piece)
                    if not center then
                        rejected=rejected+1
                        if #details<6 then details[#details+1]=name..': '..tostring(reason) end
                    end
                end
            end
            Spring.Echo('Cloud unit '..id..': '..matched..' matching pieces, '..registered
                ..' registered now, '..rejected..' unusable bounds (hidden pieces need not be registered)')
            for _,line in ipairs(details) do Spring.Echo('Cloud bounds: '..line) end
        end
        return true
    end
    function gadget:Initialize()
        local err
        renderer,err=VFS.Include('luarules/gadgets/include/cloud_volume_renderer.lua')(Config)
        rendererError=err
        -- Remains registered when GPU initialization fails. Selection is local.
        gadgetHandler:AddSyncAction('cloud_volume_report',function(_,playerID)
            if playerID==Spring.GetMyPlayerID() then report() end
        end)
        Spring.Echo('Cloud volumes: renderer '..(renderer and 'ready' or ('FAILED: '..tostring(err))))
    end
    function gadget:DrawWorld()
        if not renderer then return end
        if revision~=SYNCED.CloudVolumeRevision then
            revision=SYNCED.CloudVolumeRevision
            local records={}
            for k,s in pairs(SYNCED.CloudVolumeRecords or {}) do
                local r={}
                for _,f in ipairs({'unitID','piece','preset','born','seed','x','y','z','scale','duration'}) do r[f]=s[f] end
                if s.center then r.center={s.center[1],s.center[2],s.center[3]};r.half={s.half[1],s.half[2],s.half[3]} end
                if s.worldHalf then r.worldHalf={s.worldHalf[1],s.worldHalf[2],s.worldHalf[3]} end
                records[k]=r
            end
            renderer.records=records
        end
        renderer:Draw()
    end
    function gadget:Shutdown()
        gadgetHandler:RemoveSyncAction('cloud_volume_report')
        if renderer then renderer:Shutdown() end
    end
end
