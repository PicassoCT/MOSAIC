-- Synced, distance-driven projection lifecycle. Never moves a spawned unit.
local M = {}
function M.New(S, G, map, config, catalog, decorations, ghosts)
    local self = {holograms = {}, sources = {}}
    local gaia = S.GetGaiaTeamID()
    local function alive(id)
        return id and S.ValidUnitID(id) and not S.GetUnitIsDead(id)
    end
    local function remove(id)
        self.holograms[id] = nil
        if alive(id) then
            G.DiedPeacefully = G.DiedPeacefully or {}
            G.DiedPeacefully[id] = true
            S.DestroyUnit(id, false, true)
        end
    end
    function self:Clear()
        local ids = {}; for id in pairs(self.holograms) do ids[#ids+1] = id end
        table.sort(ids)
        for _, id in ipairs(ids) do remove(id) end
        self.sources = {}
    end
    function self:Frame(frame)
        local parade = G.CityParade
        if not parade or parade.phase ~= "touring" then self:Clear(); return end
        local active, ids = {}, {}
        for id in pairs(parade.vehicles) do ids[#ids+1] = id end
        table.sort(ids)
        for _, id in ipairs(ids) do
            local payload = parade.vehicles[id].payload
            if alive(id) and alive(payload) and S.GetUnitTeam(id) == gaia
                and S.GetUnitTransporter(payload) == id then
                local index = S.GetUnitRulesParam(payload, "city_parade_variant")
                local variant = index and catalog.variants[index]
                local x, _, z = S.GetUnitPosition(id)
                if variant and x then
                    active[#active+1] = {id=id, x=x, z=z, variant=variant}
                end
            end
        end
        local count, expired = 0, {}
        for id, position in pairs(self.holograms) do
            local near = false
            for _, source in ipairs(active) do
                if (source.x-position.x)^2 + (source.z-position.z)^2 <= config.keepRadius^2 then
                    near = true; break
                end
            end
            if alive(id) and S.GetUnitTeam(id) == gaia and near then count = count + 1
            else expired[#expired+1] = id end
        end
        table.sort(expired)
        for _, id in ipairs(expired) do remove(id) end
        local retained = {}
        for _, source in ipairs(active) do
            local state = self.sources[source.id] or {nextFrame=0, sequence=0}
            retained[source.id] = state
            if count < config.maxHolograms and frame >= state.nextFrame
                and (not state.x or (source.x-state.x)^2+(source.z-state.z)^2 >= config.spawnDistance^2) then
                state.nextFrame = frame + config.spawnIntervalFrames
                local front = S.GetUnitVectors(source.id)
                local length = front and math.sqrt(front[1]^2 + front[3]^2) or 0
                local theme = decorations.themes[source.variant.hologramTheme or source.variant.key]
                if length > 0 and theme and #theme > 0 then
                    local dx, dz = front[1]/length, front[3]/length
                    local side = state.sequence % 2 == 0 and 1 or -1
                    local x = source.x + dz * config.roadsideOffset * side
                    local z = source.z - dx * config.roadsideOffset * side
                    local y = S.GetGroundHeight(x, z)
                    local clear = y >= 0 and x > config.clearance and z > config.clearance
                        and x < map.mapSizeX-config.clearance and z < map.mapSizeZ-config.clearance
                    if clear then
                        for _, other in ipairs(S.GetUnitsInCylinder(x,z,config.clearance) or {}) do
                            if S.GetUnitBlocking(other) then clear=false; break end
                        end
                        for _, point in pairs(self.holograms) do
                            if (point.x-x)^2+(point.z-z)^2 < (config.clearance*2)^2 then clear=false; break end
                        end
                    end
                    if clear then
                        local id = S.CreateUnit(config.unitName,x,y+config.groundOffset,z,0,gaia)
                        if id then
                            local env = S.UnitScript.GetScriptEnv(id)
                            -- Board faces the road, rather than rotating with a camera or truck.
                            local yaw = math.atan2(-dz*side, dx*side)
                            local isGhost = ghosts and (config.ghostEvery or 0) > 0
                                and (state.sequence+1) % config.ghostEvery == 0
                            local accepted
                            if isGhost then
                                local parts = ghosts.Select(source.id+(state.ghosts or 0))
                                accepted = env and env.SetParadeGhost and S.UnitScript.CallAsUnit(
                                    id,env.SetParadeGhost,parts.body,parts.face,parts.mask,yaw)
                            else
                                local glyph = theme[(state.ornaments or 0) % #theme + 1].glyph
                                accepted = env and env.SetParadeHologram
                                    and S.UnitScript.CallAsUnit(id,env.SetParadeHologram,glyph,yaw)
                            end
                            if accepted then
                                self.holograms[id] = {x=x,z=z}
                                state.x,state.z,state.sequence = source.x,source.z,state.sequence+1
                                local counter = isGhost and "ghosts" or "ornaments"
                                state[counter] = (state[counter] or 0)+1
                                count=count+1
                            else remove(id) end
                        end
                    end
                end
            end
        end
        self.sources = retained
    end
    return self
end
return M
