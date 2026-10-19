-- Client-side red impact glow for the game's harmless aiming BeamLasers.
-- Recoil represents a BeamLaser projectile with pos=startPos and
-- velocity=targetPos-startPos (NOT units per frame). Never extrapolate it.
local M = {
    radius = 36,
    strength = 1.35,
    color = {1.0, 0.025, 0.015},
    maxGlows = 24,
}
local laserNames = {targetlaser=true, targetlaseroperative=true}

function M.New(spring, weaponDefs, unitDefs)
    local laserWeapons = {}
    for weaponID,def in pairs(weaponDefs or {}) do
        if laserNames[string.lower(def.name or '')] and def.type == 'BeamLaser' then
            laserWeapons[weaponID] = true
        end
    end

    local tracked, trackedCount = {}, 0
    local self = {}

    function self:UnitCreated(id,defID)
        -- Re-registration after LOS entry must not inflate the active count.
        local def = unitDefs[defID]
        local equipped = false
        for _,slot in ipairs(def and def.weapons or {}) do
            if laserWeapons[slot.weaponDef] then equipped = true; break end
        end
        if equipped and not tracked[id] then
            tracked[id] = true
            trackedCount = trackedCount + 1
        elseif not equipped and tracked[id] then
            tracked[id] = nil
            trackedCount = trackedCount - 1
        end
    end

    function self:UnitDestroyed(id)
        if tracked[id] then
            tracked[id] = nil
            trackedCount = trackedCount - 1
        end
    end

    function self:Collect(unitVisible,cx,cy,cz)
        if trackedCount == 0 or not spring.GetVisibleProjectiles then return {} end
        local newest = {}
        -- Scan the short-lived beams on EACH draw frame; the existing 100ms
        -- projectile cache would skip many of these one-sim-frame visuals.
        for _,pid in ipairs(spring.GetVisibleProjectiles() or {}) do
            local weaponID = spring.GetProjectileDefID(pid)
            if laserWeapons[weaponID] then
                local owner = spring.GetProjectileOwnerID(pid)
                if tracked[owner] and unitVisible(owner) then
                    local x,y,z = spring.GetProjectilePosition(pid)
                    local dx,dy,dz = spring.GetProjectileVelocity(pid)
                    if x and dx and dy and dz then
                        local length = math.sqrt(dx*dx+dy*dy+dz*dz)
                        if length > 0.5 then
                            -- Exactly the engine's visible beam endpoint, not
                            -- its target coordinate or a ground-only guess.
                            local endX,endY,endZ = x+dx,y+dy,z+dz
                            -- Move the lamp slightly toward the muzzle, out of
                            -- the surface's own occupancy cell where possible.
                            -- The laser's existing RedDot sprite remains at the
                            -- unmodified beam endpoint.
                            local back = math.min(8,length*0.25)/length
                            local lx,ly,lz = endX-dx*back,endY-dy*back,endZ-dz*back
                            local key = owner..':'..weaponID
                            local prev = newest[key]
                            -- Reflections can split one shot into segments;
                            -- the last segment, not the intermediate hit, glows.
                            if not prev or pid > prev.pid then
                                newest[key] = {
                                    pid=pid,owner=owner,x=lx,y=ly,z=lz,
                                    d2=(lx-cx)^2+(ly-cy)^2+(lz-cz)^2,
                                }
                            end
                        end
                    end
                end
            end
        end
        local result = {}
        for _,dot in pairs(newest) do result[#result+1] = dot end
        table.sort(result,function(a,b)
            if a.d2 == b.d2 then return a.pid < b.pid end
            return a.d2 < b.d2
        end)
        for i=#result,M.maxGlows+1,-1 do result[i] = nil end
        return result
    end
    return self
end

return M
