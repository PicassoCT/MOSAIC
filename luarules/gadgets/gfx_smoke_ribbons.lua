function gadget:GetInfo()
    return {name='Procedural Smoke Ribbons', desc='Piece-attached curling smoke, steam and luminous wisps',
        author='Mosaic contributors', layer=1, enabled=true}
end

local Config = VFS.Include('luarules/gadgets/include/smoke_ribbon_config.lua')
local Trace = VFS.Include('luarules/gadgets/include/execution_trace.lua')
local traces = {}
local function logger(prefix)
    if not traces[prefix] then traces[prefix]=Trace.New(prefix) end
    return traces[prefix]
end
local function observe(t, stage, fields)
    if t then
        fields=fields or {};fields.piece=t.piece;fields.slot=t.slot
        logger(t.prefix).Log(t.unitID,t.cycle,t.stagePrefix..'_'..stage,fields)
    end
end
if gadgetHandler:IsSyncedCode() then
    local records, api = {}, {}
    -- Versioned snapshot also restores effects after an unsynced Lua reload.
    _G.SmokeRibbonRecords = records
    _G.SmokeRibbonRevision = 0
    local function changed() _G.SmokeRibbonRevision = _G.SmokeRibbonRevision+1 end
    local function key(unitID, slot) return unitID..':'..tostring(slot or 'default') end
    function api.Set(unitID, slot, piece, options)
        assert(type(slot)=='string' or type(slot)=='number' or slot==nil, 'invalid smoke slot')
        local requested=type(options)=='table' and options.executionTrace
        local detail
        if type(requested)=='table' and type(requested.prefix)=='string' and type(requested.stagePrefix)=='string' then
            local cycle=requested.cycle
            if type(cycle)~='number' and type(cycle)~='string' then cycle=nil end
            detail={prefix=requested.prefix,stagePrefix=requested.stagePrefix,cycle=cycle,
                unitID=unitID,piece=piece,slot=slot or 'default'}
            observe(detail,'registration_requested')
        end
        local ok, record = pcall(Config.Normalize,unitID,piece,options)
        if not ok then
            observe(detail,'registration_rejected',{reason=record})
            return false, record
        end
        if detail then detail.piece=record.piece;record.executionTrace=detail end
        records[key(unitID,slot)] = record; changed()
        observe(detail,'registered',{mode=record.mode,revision=_G.SmokeRibbonRevision,
            length=record.length,width=record.width,distance_factor=record.distanceFactor,
            start_r=record.colorStart[1],start_g=record.colorStart[2],start_b=record.colorStart[3],
            end_r=record.colorEnd[1],end_g=record.colorEnd[2],end_b=record.colorEnd[3]})
        return true
    end
    function api.Remove(unitID, slot)
        local k=key(unitID,slot)
        if records[k] then
            local detail=records[k].executionTrace
            records[k]=nil; changed()
            observe(detail,'removed',{revision=_G.SmokeRibbonRevision})
        end
    end
    function api.SetEnabled(unitID, slot, enabled)
        local r=records[key(unitID,slot)]
        if r and r.enabled ~= (enabled == true) then r.enabled=enabled == true; changed() end
    end
    function gadget:UnitDestroyed(unitID)
        local dirty=false
        for k,r in pairs(records) do if r.unitID==unitID then
            observe(r.executionTrace,'removed',{reason='unit_destroyed'})
            records[k]=nil;dirty=true
        end end
        if dirty then changed() end
        for _,trace in pairs(traces) do trace.Forget(unitID) end
    end
    function gadget:Initialize()
        GG.SmokeRibbon=api
        logger('SmokeRibbon').Log(nil,0,'provider_ready',{side='synced'})
        -- This handler has no TextCommand dispatcher. LuaRules chat actions
        -- must cross to the requesting client before using local selection.
        gadgetHandler:AddChatAction('smokeribbon',function(_,message,_,playerID)
            SendToUnsynced('smoke_ribbon_command',playerID,message)
            return true
        end,'<piece> electric|glow|steam|hair, status, or off (local preview)')
    end
    function gadget:Shutdown()
        gadgetHandler:RemoveChatAction('smokeribbon')
        if GG.SmokeRibbon==api then GG.SmokeRibbon=nil end
        _G.SmokeRibbonRecords=nil; _G.SmokeRibbonRevision=nil
    end
else
    local renderer, revision, preview
    local fields={'mode','stiffness','gravity','hang','unitID','piece','directionPiece','directionSpace','scale','length','width','curl','speed','seed','strands','enabled','distanceFactor',
        'groundDirected','windAffected','motionAffected','windInfluence','motionInfluence','trailTime',
        'padPiece','distanceCulling','drawInIcon','endFrame','fadeFrames'}
    function gadget:Initialize()
        local err
        renderer,err=VFS.Include('luarules/gadgets/include/smoke_ribbon_renderer.lua')()
        if not renderer then
            Spring.Echo('Smoke ribbons disabled: '..tostring(err)); gadgetHandler:RemoveGadget(self)
            return
        end
        logger('SmokeRibbon').Log(nil,0,'renderer_ready',{side='unsynced'})
        gadgetHandler:AddSyncAction('smoke_ribbon_command',function(_,playerID,message)
            if playerID==Spring.GetMyPlayerID() then
                return self:TextCommand('smokeribbon '..message)
            end
        end)
    end
    local function refresh()
        local current=SYNCED.SmokeRibbonRevision
        if revision==current then return end
        revision=current
        local records={}
        for k,source in pairs(SYNCED.SmokeRibbonRecords or {}) do
            local r={}
            for _,f in ipairs(fields) do r[f]=source[f] end
            r.rootOffset={source.rootOffset[1],source.rootOffset[2],source.rootOffset[3]}
            r.direction={source.direction[1],source.direction[2],source.direction[3]}
            r.colorStart={source.colorStart[1],source.colorStart[2],source.colorStart[3],source.colorStart[4]}
            r.colorEnd={source.colorEnd[1],source.colorEnd[2],source.colorEnd[3],source.colorEnd[4]}
            r.emission={source.emission[1],source.emission[2]}
            local glow=source.sourceGlow
            r.sourceGlow=glow and {glow[1],glow[2],glow[3],glow[4]} or {0,0,0,0}
            local detail=source.executionTrace
            if detail then
                -- Copy scalar metadata across the synced boundary; the logger
                -- itself is local to this client and is never synchronized.
                r.executionTrace={logger=logger(detail.prefix),unitID=detail.unitID,cycle=detail.cycle,
                    stagePrefix=detail.stagePrefix,piece=detail.piece,slot=detail.slot}
                r.executionTrace.logger.Log(detail.unitID,detail.cycle,detail.stagePrefix..'_received',
                    {piece=detail.piece,slot=detail.slot,mode=r.mode,revision=current})
            end
            records[k]=r
        end
        renderer.records=records
    end
    function gadget:DrawWorld()
        if not renderer then return end
        refresh()
        renderer.records.__preview=preview
        renderer:Draw()
    end
    -- Local-only preview, no synced changes. Explicit piece name avoids guessing.
    function gadget:TextCommand(command)
        local piece,preset=command:match('^smokeribbon%s+(%S+)%s*(%S*)$')
        if not piece or not renderer then return false end
        if piece=='off' then preview=nil;return true end
        local unitID=(Spring.GetSelectedUnits() or {})[1]
        if piece=='status' then
            refresh()
            local count,electric=0,0
            for key,r in pairs(renderer.records) do
                if key~='__preview' and unitID and r.unitID==unitID then
                    count=count+1
                    if r.mode=='electric' then electric=electric+1 end
                end
            end
            Spring.Echo('Smoke ribbons: renderer ready; synced registry '
                ..(SYNCED.SmokeRibbonRevision~=nil and 'ready' or 'MISSING')
                ..'; selected unit slots '..count..' ('..electric..' electric)')
            return true
        end
        if not unitID then Spring.Echo('Smoke ribbon: select a unit first');return true end
        local options={}
        if preset=='hair' then
            options={mode='hair'}
        elseif preset=='electric' then
            options=VFS.Include('scripts/lib_graphene_arc.lua').Options(19)
        elseif preset=='glow' then
            options={colorStart={1,0.35,0.7,0.65},colorEnd={0.35,0.15,0.8,0},emission={2,0.3}}
        elseif preset=='steam' then
            options={colorStart={0.9,0.95,1,0.45},colorEnd={0.85,0.9,1,0},width=14,speed=0.7}
        end
        local ok,result=pcall(Config.Normalize,unitID,tonumber(piece) or piece,options)
        if ok then preview=result else Spring.Echo('Smoke ribbon: '..tostring(result)) end
        return true
    end
    function gadget:Shutdown()
        gadgetHandler:RemoveSyncAction('smoke_ribbon_command')
        if renderer then renderer:Shutdown();renderer=nil end
    end
end
