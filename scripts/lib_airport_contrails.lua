-- Condensation from the circling plane's two outer steering fins.
-- MainBirdBody1 owns both fins even when another hull variant is shown.
return function(unitID)
    local active, dead = false, false
    local cached, registeredAPI
    local slots = {'airport-contrail-left', 'airport-contrail-right'}
    local self = {}

    local function options(piece, driver, xFraction)
        local info = Spring.GetUnitPieceInfo(unitID, piece)
        if not (info and info.min and info.max) then return nil end
        local span = {}
        for axis=1,3 do
            if type(info.min[axis]) ~= 'number' or type(info.max[axis]) ~= 'number' then
                return nil
            end
            span[axis] = info.max[axis]-info.min[axis]
            if span[axis] <= 0 then return nil end
        end
        return {
            -- Actual aft-tip vertices in objective_airport.dae, expressed as
            -- fractions of each fin's bounds so imported scale is preserved.
            -- One percent of the chord clears the trailing surface.
            rootOffset = {
                info.min[1]+span[1]*xFraction,
                info.min[2]-span[2]*0.01,
                info.min[3]+span[3]*0.01629384,
            },
            directionSpace='piece', directionPiece=driver, direction={0,-1,0},
            -- The DAE's 0.0254 unit scale and 0.500870 parent scale give a
            -- 48.66-unit fin chord and 44.05-unit height: fourteen chords of
            -- trailing vapor, widening to roughly a third of the fin height.
            length=680, width=16, curl=0.2, speed=0.65, strands=2,
            colorStart={0.88,0.93,1,0.52}, colorEnd={0.9,0.95,1,0},
            emission={0,0}, windAffected=true, windInfluence=0.25, trailTime=1.2,
            -- The airport unit is stationary; the animated hull supplies the
            -- heading. This is an attached spatial fade, not a stored wake.
            motionAffected=false, distanceCulling=false, drawInIcon=true,
        }
    end

    function self.Start(left, right, driver)
        if dead then return false end
        local api = GG and GG.SmokeRibbon
        if not api then return false end
        if active and registeredAPI == api then return true end
        if active then self.Stop() end
        if not cached then
            if left == nil or right == nil or driver == nil then return false end
            local leftOptions = options(left,driver,0.6839662864)
            local rightOptions = options(right,driver,0.3160337136)
            if not leftOptions or not rightOptions then return false end
            cached = {{piece=left,options=leftOptions}, {piece=right,options=rightOptions}}
        end
        for i, entry in ipairs(cached) do
            local ok, err = api.Set(unitID,slots[i],entry.piece,entry.options)
            if not ok then
                -- Never leave a one-sided trail after a failed registration.
                for _, slot in ipairs(slots) do api.Remove(unitID,slot) end
                active, registeredAPI = false, nil
                Spring.Echo('Airport contrail: '..tostring(err))
                return false
            end
        end
        active, registeredAPI = true, api
        return true
    end

    function self.Stop()
        if active then
            local api = registeredAPI or (GG and GG.SmokeRibbon)
            if api then
                for _, slot in ipairs(slots) do api.Remove(unitID,slot) end
            end
        end
        active, registeredAPI = false, nil
    end

    function self.Shutdown()
        dead = true
        self.Stop()
    end

    return self
end
