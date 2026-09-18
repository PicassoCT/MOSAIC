-- Direct moving spotlights. No Recoil model-shader framework or engine setting changes.
local PATH = 'luaui/widgets_mosaic/shaders/headlights/'
local function screenQuad(x0, y0, x1, y1)
    gl.MatrixMode(GL.PROJECTION); gl.PushMatrix(); gl.LoadIdentity()
    gl.MatrixMode(GL.MODELVIEW); gl.PushMatrix(); gl.LoadIdentity()
    gl.TexRect(x0, y0, x1, y1)
    gl.PopMatrix(); gl.MatrixMode(GL.PROJECTION); gl.PopMatrix(); gl.MatrixMode(GL.MODELVIEW)
end
local function clamp(x, a, b) return math.max(a, math.min(b, x)) end
return function()
    if not gl.CreateShader or not gl.CopyToTexture or not gl.UniformMatrix then return nil end
    local self = {pieces = {}}
    self.shader = gl.CreateShader({fragment = VFS.LoadFile(PATH .. 'spotlight.frag'),
        uniformInt = {depthTex = 0, occupancyTex = 1}})
    self.glow = gl.CreateShader({fragment = VFS.LoadFile(PATH .. 'glow.frag')})
    function self:Resize()
        if self.depth then gl.DeleteTexture(self.depth) end
        self.depth, self.width, self.height, self.failedSize = nil, nil, nil, nil
    end
    function self:Shutdown()
        self:Resize()
        if self.shader then gl.DeleteShader(self.shader) end
        if self.glow then gl.DeleteShader(self.glow) end
    end
    if not self.shader or not self.glow then
        Spring.Echo('Headlights: shader unavailable; retaining legacy searchlights. ' .. (gl.GetShaderLog() or ''))
        self:Shutdown(); return nil
    end
    local loc = {}
    for _, name in ipairs({'inverseProjection','inverseView','viewport','viewportOrigin','mapSize',
        'lampLeft','lampRight','forward','right','up','lightRange','intensity','wetness',
        'clipZeroToOne','occlusionActive','occlusionHeight','glitterTime'}) do
        loc[name] = gl.GetUniformLocation(self.shader, name)
    end
    local function add(p, v, amount)
        return {p[1] + v[1] * amount, p[2] + v[2] * amount, p[3] + v[3] * amount}
    end
    function self:Forget(id) self.pieces[id] = nil end
    local function lamps(id, def, front, up, right)
        local x, y, z = Spring.GetUnitPosition(id)
        if not x then return end
        local sx, sy, sz, ox, oy, oz = Spring.GetUnitCollisionVolumeData(id)
        sx, sy, sz = sx or 40, sy or 30, sz or 70
        local cp = def.customParams or {}
        -- Collision extents avoid enormous radii caused by decorative model pieces.
        local centre = add(add(add({x,y,z}, right, ox or 0), up, oy or 0), front, oz or 0)
        centre = add(centre, front, tonumber(cp.headlight_forward) or sz * 0.48)
        centre = add(centre, up, tonumber(cp.headlight_height) or sy * 0.32)
        local spacing = tonumber(cp.headlight_spacing) or sx * 0.32
        local a, b = add(centre, right, -spacing), add(centre, right, spacing)
        -- Optional named lamp anchors are exact even on animated vehicle bodies.
        local pieces = self.pieces[id]
        if not pieces or pieces.definition ~= def then
            local map = Spring.GetUnitPieceMap(id) or {}
            pieces = {map[cp.headlight_left_piece or 'headlight_left'], map[cp.headlight_right_piece or 'headlight_right'], definition = def}
            self.pieces[id] = pieces
        end
        for i = 1, 2 do
            local p = pieces[i]
            if p then
                local px, py, pz = Spring.GetUnitPiecePosDir(id, p)
                if px then if i == 1 then a = {px,py,pz} else b = {px,py,pz} end end
            end
        end
        local range = clamp(tonumber(cp.headlight_range) or sz * 3.5, 100, 360)
        return a, b, range
    end
    -- Conservative projected cube bounds; camera/near-plane intersections use the
    -- full viewport. Cost elsewhere is limited to each car's screen footprint.
    local function bounds(a, b, front, range, w, h)
        local centre = {(a[1]+b[1])/2+front[1]*range/2,
            (a[2]+b[2])/2+front[2]*range/2, (a[3]+b[3])/2+front[3]*range/2}
        local radius = range * 0.85 + math.sqrt((a[1]-b[1])^2+(a[2]-b[2])^2+(a[3]-b[3])^2)
        local x0,y0,x1,y1 = w,h,0,0
        for x=-1,1,2 do for y=-1,1,2 do for z=-1,1,2 do
            local px,py,pz = Spring.WorldToScreenCoords(centre[1]+x*radius,centre[2]+y*radius,centre[3]+z*radius)
            if not pz or pz <= 0 or pz >= 1 then return -1,-1,1,1 end
            x0,y0,x1,y1 = math.min(x0,px),math.min(y0,py),math.max(x1,px),math.max(y1,py)
        end end end
        if x1<0 or y1<0 or x0>w or y0>h then return end
        return clamp(x0/w*2-1,-1,1),clamp(y0/h*2-1,-1,1),clamp(x1/w*2-1,-1,1),clamp(y1/h*2-1,-1,1)
    end
    function self:Draw(lightList, intensity, drawGlow, drawSurface)
        if intensity <= 0 then return end
        local lights = {}
        local cx,cy,cz = Spring.GetCameraPosition()
        for _, id in ipairs(Spring.GetVisibleUnits(-1, nil, false) or {}) do
            local defID = Spring.GetUnitDefID(id)
            local def = defID and UnitDefs[defID]
            if def and lightList[defID] and (def.speed or 0)>0 and not def.canFly
                and not Spring.GetUnitIsDead(id) and not Spring.GetUnitIsCloaked(id)
                and not Spring.GetUnitTransporter(id) then
                local _,_,_,_,built = Spring.GetUnitHealth(id)
                local front, up, right = Spring.GetUnitVectors(id)
                if front and up and right and (not built or built >= 1) then
                    local a,b,range = lamps(id,def,front,up,right)
                    if a then
                        local d2 = (cx-a[1])^2+(cy-a[2])^2+(cz-a[3])^2
                        lights[#lights+1] = {a=a,b=b,front=front,up=up,right=right,range=range,d2=d2}
                    end
                end
            end
        end
        if #lights == 0 then return end
        table.sort(lights,function(a,b) return a.d2<b.d2 end)
        local w,h,vpx,vpy = Spring.GetViewGeometry()
        if not w or w<1 or h<1 then return end
        local surface = false
        if drawSurface then
            if self.width ~= w or self.height ~= h then
                local sizeKey = w .. 'x' .. h
                if self.failedSize ~= sizeKey then
                    self:Resize()
                    if w*h <= 4*1024*1024 then
                        self.depth = gl.CreateTexture(w,h,{format=GL.DEPTH_COMPONENT24 or 0x81A6,
                            min_filter=GL.NEAREST,mag_filter=GL.NEAREST,wrap_s=GL.CLAMP_TO_EDGE,wrap_t=GL.CLAMP_TO_EDGE})
                    end
                    if self.depth then self.width,self.height=w,h else
                        self.failedSize=sizeKey
                        Spring.Echo('Headlights: depth copy unavailable or above 16 MiB; lamp glows only')
                    end
                end
            end
            if self.depth then
                gl.CopyToTexture(self.depth,0,0,vpx or 0,vpy or 0,w,h)
                surface = true
            end
        end
        gl.DepthMask(false); gl.Culling(false); gl.Color(1,1,1,1)
        if surface then
            gl.DepthTest(false); gl.Blending(GL.ONE,GL.ONE)
            gl.Texture(0,self.depth); gl.UseShader(self.shader)
            gl.UniformMatrix(loc.inverseProjection,'projectioninverse')
            gl.UniformMatrix(loc.inverseView,'viewinverse')
            gl.Uniform(loc.viewport,w,h); gl.Uniform(loc.viewportOrigin,vpx or 0,vpy or 0)
            gl.Uniform(loc.mapSize,Game.mapSizeX,Game.mapSizeZ)
            gl.Uniform(loc.intensity,intensity)
            gl.Uniform(loc.glitterTime,Spring.GetGameSeconds())
            gl.Uniform(loc.wetness,clamp((WG.GetVehicleHeadlightWetness and tonumber(WG.GetVehicleHeadlightWetness())) or 0,0,1))
            gl.UniformInt(loc.clipZeroToOne,Platform and Platform.glSupportClipSpaceControl and 1 or 0)
            -- Nearest 48 vehicles get road lighting; every visible vehicle retains bulbs.
            for i=1,math.min(#lights,48) do
                local l=lights[i]
                local x0,y0,x1,y1=bounds(l.a,l.b,l.front,l.range,w,h)
                if x0 then
                    gl.Uniform(loc.lampLeft,unpack(l.a)); gl.Uniform(loc.lampRight,unpack(l.b))
                    gl.Uniform(loc.forward,unpack(l.front)); gl.Uniform(loc.up,unpack(l.up)); gl.Uniform(loc.right,unpack(l.right))
                    gl.Uniform(loc.lightRange,l.range)
                    local atlas,bottom,top
                    if WG.GetVehicleLightOcclusion then atlas,bottom,top=WG.GetVehicleLightOcclusion((l.a[2]+l.b[2])*0.5) end
                    gl.Texture(1,atlas or false)
                    gl.UniformInt(loc.occlusionActive,atlas and 1 or 0)
                    gl.Uniform(loc.occlusionHeight,bottom or 0,top or 0)
                    screenQuad(x0,y0,x1,y1)
                end
            end
            gl.UseShader(0); gl.Texture(0,false); gl.Texture(1,false)
        end
        if drawGlow then
            gl.UseShader(self.glow); gl.DepthTest(true); gl.Blending(GL.SRC_ALPHA,GL.ONE)
            for _,l in ipairs(lights) do
                for _,p in ipairs({l.a,l.b}) do
                    local dx,dy,dz=cx-p[1],cy-p[2],cz-p[3]
                    local facing=(dx*l.front[1]+dy*l.front[2]+dz*l.front[3])/math.max(1,math.sqrt(dx*dx+dy*dy+dz*dz))
                    local gain=clamp((facing+0.15)/0.75,0,1)*intensity
                    if gain>0 then
                        gl.Color(1,0.92,0.8,gain)
                        gl.PushMatrix(); gl.Translate(p[1],p[2],p[3]); gl.Billboard()
                        gl.TexRect(-4,-4,4,4,0,0,1,1); gl.PopMatrix()
                    end
                end
            end
            gl.UseShader(0)
        end
        gl.Color(1,1,1,1); gl.Blending(GL.SRC_ALPHA,GL.ONE_MINUS_SRC_ALPHA)
        gl.DepthMask(true); gl.DepthTest(false)
    end
    return self
end

