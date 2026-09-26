function gadget:GetInfo()
    return {name='Procedural Smoke Ribbons', desc='Piece-attached curling smoke, steam and luminous wisps',
        author='Mosaic contributors', layer=1, enabled=true}
end

local Config = VFS.Include('luarules/gadgets/include/smoke_ribbon_config.lua')
if gadgetHandler:IsSyncedCode() then
    local records, api = {}, {}
    -- Versioned snapshot also restores effects after an unsynced Lua reload.
    _G.SmokeRibbonRecords = records
    _G.SmokeRibbonRevision = 0
    local function changed() _G.SmokeRibbonRevision = _G.SmokeRibbonRevision+1 end
    local function key(unitID, slot) return unitID..':'..tostring(slot or 'default') end
    function api.Set(unitID, slot, piece, options)
        assert(type(slot)=='string' or type(slot)=='number' or slot==nil, 'invalid smoke slot')
        local ok, record = pcall(Config.Normalize,unitID,piece,options)
        if not ok then return false, record end
        records[key(unitID,slot)] = record; changed()
        return true
    end
    function api.Remove(unitID, slot)
        local k=key(unitID,slot)
        if records[k] then records[k]=nil; changed() end
    end
    function api.SetEnabled(unitID, slot, enabled)
        local r=records[key(unitID,slot)]
        if r and r.enabled ~= (enabled == true) then r.enabled=enabled == true; changed() end
    end
    function gadget:UnitDestroyed(unitID)
        local dirty=false
        for k,r in pairs(records) do if r.unitID==unitID then records[k]=nil;dirty=true end end
        if dirty then changed() end
    end
    function gadget:Initialize() GG.SmokeRibbon=api end
    function gadget:Shutdown()
        if GG.SmokeRibbon==api then GG.SmokeRibbon=nil end
        _G.SmokeRibbonRecords=nil; _G.SmokeRibbonRevision=nil
    end
else
    local renderer, revision, preview
    local fields={'mode','stiffness','gravity','hang','unitID','piece','directionPiece','directionSpace','scale','length','width','curl','speed','seed','strands','enabled','distanceFactor',
        'groundDirected','windAffected','motionAffected','windInfluence','motionInfluence','trailTime'}
    function gadget:Initialize()
        local err
        renderer,err=VFS.Include('luarules/gadgets/include/smoke_ribbon_renderer.lua')()
        if not renderer then
            Spring.Echo('Smoke ribbons disabled: '..tostring(err)); gadgetHandler:RemoveGadget(self)
        end
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
        if not unitID then Spring.Echo('Smoke ribbon: select a unit first');return true end
        local options={}
        if preset=='hair' then
            options={mode='hair'}
        elseif preset=='glow' then
            options={colorStart={1,0.35,0.7,0.65},colorEnd={0.35,0.15,0.8,0},emission={2,0.3}}
        elseif preset=='steam' then
            options={colorStart={0.9,0.95,1,0.45},colorEnd={0.85,0.9,1,0},width=14,speed=0.7}
        end
        local ok,result=pcall(Config.Normalize,unitID,tonumber(piece) or piece,options)
        if ok then preview=result else Spring.Echo('Smoke ribbon: '..tostring(result)) end
        return true
    end
    function gadget:Shutdown() if renderer then renderer:Shutdown();renderer=nil end end
end
