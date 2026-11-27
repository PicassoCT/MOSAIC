function gadget:GetInfo()
    return {
        name = 'Raid interior visibility',
        desc = 'Keep the occupied building and its production model off the raid board',
        author = 'MOSAIC contributors', license = 'GPL3', layer = 1, enabled = true,
    }
end

local rule = 'raid_interior_hidden'
if gadgetHandler:IsSyncedCode() then
    local hidden = {}
    local function alive(id)
        return id and Spring.ValidUnitID(id) and not Spring.GetUnitIsDead(id)
    end
    local function update()
        local wanted = {}
        for house, icon in pairs(GG.HouseRaidIconMap or {}) do
            if alive(house) and alive(icon) then
                local interior = (GG.houseHasSafeHouseTable or {})[house]
                if alive(interior) then
                    wanted[interior] = true
                    local product = Spring.GetUnitIsBuilding(interior)
                    if alive(product) then wanted[product] = true end
                end
            end
        end
        for id in pairs(hidden) do
            if not wanted[id] then
                if alive(id) then Spring.SetUnitRulesParam(id, rule, 0, {inlos=true}) end
                hidden[id] = nil
            end
        end
        for id in pairs(wanted) do
            if not hidden[id] then
                -- Do not expose a hidden enemy occupant's ID through a public map.
                Spring.SetUnitRulesParam(id, rule, 1, {inlos=true})
                hidden[id] = true
            end
        end
    end
    function gadget:GameFrame(frame) if frame % 5 == 0 then update() end end
    function gadget:UnitDestroyed(id) hidden[id] = nil; update() end
    function gadget:Initialize() update() end
    function gadget:Shutdown()
        for id in pairs(hidden) do
            if alive(id) then Spring.SetUnitRulesParam(id, rule, 0, {inlos=true}) end
        end
    end
else
    local hidden = {}
    local function restore(id)
        local previous = hidden[id]
        if previous and Spring.ValidUnitID(id) then
            Spring.SetUnitNoDraw(id, previous.noDraw)
            Spring.UnitIconSetDraw(id, previous.iconDraw)
            Spring.SetUnitNoSelect(id, previous.noSelect)
        end
        hidden[id] = nil
    end
    local function update()
        for _, id in ipairs(Spring.GetAllUnits()) do
            if Spring.GetUnitRulesParam(id, rule) == 1 then
                if not hidden[id] then
                    hidden[id] = {noDraw=Spring.GetUnitNoDraw(id), iconDraw=Spring.UnitIconGetDraw(id),
                        noSelect=Spring.GetUnitNoSelect(id)}
                end
                Spring.SetUnitNoDraw(id, true)
                Spring.UnitIconSetDraw(id, false)
                -- noDraw alone does not remove the unit from screen-ray picking.
                Spring.SetUnitNoSelect(id, true)
            end
        end
        for id in pairs(hidden) do
            if not Spring.ValidUnitID(id) or Spring.GetUnitRulesParam(id, rule) ~= 1 then restore(id) end
        end
    end
    local lastFrame
    function gadget:Update()
        local frame = Spring.GetGameFrame()
        if lastFrame and frame >= lastFrame and frame - lastFrame < 5 then return end
        lastFrame = frame
        update()
    end
    function gadget:PlayerChanged() lastFrame = nil end
    function gadget:Shutdown() for id in pairs(hidden) do restore(id) end end
end
