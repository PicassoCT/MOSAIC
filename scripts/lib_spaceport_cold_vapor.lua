-- Tank condensation spills down the parked hull; no synced animation loop.
return function(unitID)
    local active, dead = {}, false
    local self = {}
    function self.Stop()
        for _, slot in ipairs(active) do
            if GG.SmokeRibbon then GG.SmokeRibbon.Remove(unitID, slot) end
        end
        active = {}
    end
    function self.Start(hull)
        if dead or not GG.SmokeRibbon then return false end
        self.Stop()
        local info = Spring.GetUnitPieceInfo(unitID, hull)
        if not (info and info.min and info.max) then return false end
        local center, half, axis = {}, {}, 1
        for i=1,3 do
            center[i]=(info.min[i]+info.max[i])*0.5
            half[i]=(info.max[i]-info.min[i])*0.5
            if half[i]>half[axis] then axis=i end
        end
        -- MainStageRocket's long axis follows the tank. Bounds keep the outlets
        -- outside the hull and work with the imported model's scale/rotation.
        local a, b = axis%3+1, (axis+1)%3+1
        for ring, height in ipairs({0.35,0.75}) do
            for outlet=1,4 do
                local angle=(outlet-1)*math.pi*0.5+(ring-1)*math.pi*0.25
                local offset={unpack(center)}
                offset[axis]=info.min[axis]+2*half[axis]*height
                offset[a]=center[a]+half[a]*1.04*math.cos(angle)
                offset[b]=center[b]+half[b]*1.04*math.sin(angle)
                local slot='spaceport-cold-'..ring..'-'..outlet
                local ok, err = GG.SmokeRibbon.Set(unitID, slot, hull, {
                    directionSpace='world', direction={0,-1,0}, rootOffset=offset,
                    length=640, width=120, curl=0.85, speed=0.45, strands=3,
                    colorStart={0.82,0.91,1,0.7}, colorEnd={0.94,0.97,1,0},
                    emission={0,0}, windAffected=true, windInfluence=0.8, trailTime=1.5,
                    motionAffected=false, seed=(unitID*0.754877666+ring*17+outlet*2.399963)%100,
                })
                if not ok then
                    Spring.Echo('Spaceport cold vapor: '..tostring(err))
                    self.Stop()
                    return false
                end
                active[#active+1]=slot
            end
        end
        return true
    end
    function self.Shutdown() dead=true;self.Stop() end
    return self
end
