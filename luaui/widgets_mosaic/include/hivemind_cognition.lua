-- Decorative cognition only: these associations never claim actual intel.
-- Source/target visibility is checked again at draw time, including cloak changes.
local M = {maxSources = 4, maxGlyphs = 96, maxLinks = 12, radius = 1156}
local sin, cos, sqrt, pi = math.sin, math.cos, math.sqrt, math.pi
local function hash(n) return (sin(n * 127.1 + 311.7) * 43758.5453) % 1 end
local function clamp(v) return math.max(0, math.min(1, v)) end

local strokes = {
    {0,1,1,1}, {1,1,1,.5}, {1,.5,1,0}, {0,0,1,0},
    {0,.5,0,0}, {0,1,0,.5}, {0,.5,1,.5},
    {0,0,1,1}, {0,1,1,0}, {.5,0,.5,1},
}
local glyphs = {
    {1,2,3,4,5,6}, {2,3}, {1,2,7,5,4}, {1,2,7,3,4},
    {6,7,2,3}, {1,6,7,3,4}, {1,6,7,5,3,4}, {1,2,3},
    {1,2,3,4,5,6,7}, {1,2,3,4,6,7}, {7,10}, {8,9}, {1,7},
}

function M.New()
    local self = {known = {}, records = {}, sources = {}, clock = 0, scanAge = 1}
    local function visible(id, source)
        if not Spring.ValidUnitID(id) or Spring.GetUnitIsDead(id) then return false end
        local _, fullView = Spring.GetSpectatingState()
        if fullView then return true end
        local ally = Spring.GetMyAllyTeamID()
        -- Own cloaked hive is represented by its orange brain icon.
        if source and Spring.GetUnitAllyTeam(id) == ally then return true end
        if Spring.GetUnitIsCloaked(id) or Spring.GetUnitNoDraw(id) then return false end
        local los = Spring.GetUnitLosState(id, ally)
        return los and los.los == true
    end
    function self:UnitCreated(id, defID)
        local def = UnitDefs[defID or Spring.GetUnitDefID(id)]
        if def and (def.name == "hivemind" or def.name == "aicore") then self.known[id] = true end
    end
    function self:UnitDestroyed(id)
        self.known[id], self.records[id] = nil, nil
    end
    for _, id in ipairs(Spring.GetAllUnits() or {}) do self:UnitCreated(id) end

    function self:Update(dt, active, previewID)
        self.previewID = previewID
        self.clock = self.clock + math.max(0, dt)
        self.scanAge = self.scanAge + math.max(0, dt)
        if not active then
            self.records, self.sources = {}, {}
            self.scanAge = 1
            return
        end
        local cx, cy, cz = Spring.GetCameraPosition()
        local candidates = {}
        for id in pairs(self.known) do
            if visible(id, true) and (id == previewID or (not previewID and Spring.GetUnitRulesParam(id, "slowMoSourceActive") == 1)) then
                local x, y, z = Spring.GetUnitPosition(id)
                if x then
                    local r = self.records[id]
                    if not r then
                        r = {id = id, born = self.clock, targets = {}, glyphs = {}}
                        self.records[id] = r
                        for i = 1, M.maxGlyphs / M.maxSources do
                            local seed = id * 31 + i * 7
                            local a, radius = hash(seed) * 2*pi, 90 + sqrt(hash(seed+1)) * 620
                            local gx, gz = x + cos(a)*radius, z + sin(a)*radius
                            r.glyphs[i] = {x=gx, z=gz, y=Spring.GetGroundHeight(gx,gz)+18+hash(seed+2)*90,
                                phase=hash(seed+3), seed=seed}
                        end
                        self.scanAge = 1
                    end
                    r.x, r.y, r.z, r.age = x, y, z, self.clock-r.born
                    r.distance = (x-cx)^2 + (y-cy)^2 + (z-cz)^2
                    candidates[#candidates+1] = r
                end
            else
                self.records[id] = nil
            end
        end
        table.sort(candidates, function(a,b)
            if a.distance == b.distance then return a.id < b.id end
            return a.distance < b.distance
        end)
        self.sources = {}
        for _, r in ipairs(candidates) do
            if #self.sources == M.maxSources then break end
            if Spring.IsSphereInView(r.x,r.y,r.z,M.radius) then
                self.sources[#self.sources+1] = r
            end
        end
        -- One shared visible-unit scan at 2 Hz, only while a source is in view.
        if #self.sources == 0 or self.scanAge < .5 then return end
        self.scanAge = 0
        local units = Spring.GetVisibleUnits(-1, nil, false) or {}
        for _, r in ipairs(self.sources) do
            local targets = {}
            for _, id in ipairs(units) do
                if id ~= r.id and visible(id, false) then
                    local def = UnitDefs[Spring.GetUnitDefID(id)]
                    if def and not (def.customParams and def.customParams.baseclass == "Abstract") then
                        local x,y,z = Spring.GetUnitPosition(id)
                        if x then
                            local d2 = (x-r.x)^2+(z-r.z)^2
                            if d2 < 800^2 then targets[#targets+1] = {id=id, d2=d2} end
                        end
                    end
                end
            end
            table.sort(targets,function(a,b)
                if a.d2 == b.d2 then return a.id < b.id end
                return a.d2 < b.d2
            end)
            r.targets = {}
            for i=1,math.min(7,#targets) do r.targets[i]=targets[i].id end
        end
    end

    function self:Collect()
        -- Recheck immediately: a cached graph must not survive losing LOS.
        local result = {}
        for _, r in ipairs(self.sources) do
            if visible(r.id,true) and (r.id == self.previewID or (not self.previewID and Spring.GetUnitRulesParam(r.id,"slowMoSourceActive") == 1)) then
                result[#result+1] = r
            end
        end
        return result
    end

    function self:Draw(amount)
        if amount < .001 then return end
        local sources = self:Collect()
        if #sources == 0 then return end
        local camera = Spring.GetCameraVectors()
        local right, up = camera.right, camera.up
        local function line(x,y,z, ax,ay, bx,by, size)
            gl.Vertex(x+(right[1]*ax+up[1]*ay)*size, y+(right[2]*ax+up[2]*ay)*size, z+(right[3]*ax+up[3]*ay)*size)
            gl.Vertex(x+(right[1]*bx+up[1]*by)*size, y+(right[2]*bx+up[2]*by)*size, z+(right[3]*bx+up[3]*by)*size)
        end
        local function ring(x,y,z,size)
            for j=0,11 do
                local a,b=j*pi/6,(j+1)*pi/6
                line(x,y,z,cos(a),sin(a),cos(b),sin(b),size)
            end
        end
        local function draw()
            local links = 0
            for _, r in ipairs(sources) do
                -- Fade all fine detail out at strategic camera distances.
                local opacity = amount * clamp((4200-sqrt(r.distance))/2200) * clamp(r.age*2)
                for _, g in ipairs(r.glyphs) do
                    local phase = (self.clock/5 + g.phase) % 1
                    local a = opacity * sin(phase*pi)^2 * .5
                    local y = g.y - phase*22
                    if a > .01 and Spring.IsSphereInView(g.x,y,g.z,18) then
                        gl.Color(1,.51,.17,a)
                        local generation = math.floor(self.clock/5+g.phase)
                        for row=0,2 do
                            local shape = glyphs[1+math.floor(hash(g.seed+row+generation*13)*#glyphs)]
                            for _, stroke in ipairs(shape) do
                                local s = strokes[stroke]
                                line(g.x,y-row*7,g.z,s[1],s[2],s[3],s[4],4)
                            end
                        end
                    end
                end
                local points = {}
                for _, id in ipairs(r.targets) do
                    if visible(id,false) then
                        local x,y,z=Spring.GetUnitViewPosition(id)
                        if x then points[#points+1]={x,y+12,z} end
                    end
                end
                for i=1,#points-1 do
                    if links >= M.maxLinks then break end
                    local a,b = points[i],points[i+1]
                    local phase=(self.clock/7+hash(r.id+i))%1
                    local fade=sin(phase*pi)^4*opacity*.38
                    gl.Color(1,.57,.23,fade)
                    ring(a[1],a[2],a[3],5)
                    local lastX,lastY,lastZ=a[1],a[2],a[3]
                    for j=1,12 do
                        local t=j/12
                        local x,y,z=a[1]+(b[1]-a[1])*t,a[2]+(b[2]-a[2])*t+sin(t*pi)*24,a[3]+(b[3]-a[3])*t
                        gl.Vertex(lastX,lastY,lastZ);gl.Vertex(x,y,z)
                        lastX,lastY,lastZ=x,y,z
                    end
                    links=links+1
                end
                -- Small suspended glints follow the water crest; never a splash explosion.
                for j=0,2 do
                    local elapsed = r.age-j*6
                    if elapsed >= 0 then
                        local age=elapsed%18
                        local radius=40+62*age
                        local fade=clamp(age)*clamp((18-age)/3)*opacity*.42
                        gl.Color(1,.81,.51,fade)
                        for k=1,4 do
                            local angle=hash(r.id+k*17+j)*2*pi
                            local x,z=r.x+cos(angle)*radius,r.z+sin(angle)*radius
                            -- Anchor above the source's plane; depth testing clips terrain/buildings.
                            ring(x,r.y+12+sin(age*.3+k)*5,z,2.2)
                        end
                    end
                end
            end
        end
        gl.PushAttrib(GL.ALL_ATTRIB_BITS)
        gl.DepthTest(true);gl.DepthMask(false)
        gl.Blending(GL.SRC_ALPHA,GL.ONE_MINUS_SRC_ALPHA)
        gl.LineWidth(1.1)
        gl.BeginEnd(GL.LINES,draw)
        gl.PopAttrib()
    end
    return self
end
return M
