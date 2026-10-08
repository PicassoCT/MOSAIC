-- One independent flame per departing aircraft; replace at the VTOL transition.
return function(unitID)
    local active, dead = {}, false
    local self = {}
    function self.Start(nr, nozzle, jet, forward)
        if dead or not GG.SmokeRibbon then return false end
        local slot='airport-scramjet-'..nr
        local ok,err=GG.SmokeRibbon.Set(unitID,slot,nozzle,{
            directionSpace=forward and 'piece' or 'world', direction={0,-1,0},
            -- Follow the hull's heading, not the old spinning flame mesh.
            directionPiece=forward and jet or nil,
            length=forward and 900 or 480, width=forward and 54 or 60,
            curl=0.22, speed=3.2, strands=3,
            colorStart={0.75,0.88,1,0.95}, colorEnd={0.36,0.2,1,0},
            emission={3.8,0.9}, windAffected=true, windInfluence=0.12, trailTime=0.4,
            motionAffected=false, distanceCulling=false, drawInIcon=true,
        })
        if ok then active[nr]=slot
        else Spring.Echo('Airport scramjet flame: '..tostring(err)) end
        return ok
    end
    function self.Stop(nr)
        if active[nr] and GG.SmokeRibbon then GG.SmokeRibbon.Remove(unitID,active[nr]) end
        active[nr]=nil
    end
    function self.Shutdown()
        dead=true
        for nr in pairs(active) do self.Stop(nr) end
    end
    return self
end
