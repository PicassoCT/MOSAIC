-- A bounded vertical envelope for the existing 2D radiance field. No new solve.
-- Each texel selects its nearest contributing unit; never average unrelated heights.
local M = {}
local PATH = 'luaui/widgets_mosaic/shaders/radiancecascade/'
local SIZE = 512
local function finite(n) return type(n)=='number' and n==n and math.abs(n)<1e7 end
local function visible(id)
    if not Spring.ValidUnitID(id) or Spring.GetUnitIsDead(id) then return false end
    if Spring.GetUnitIsCloaked and Spring.GetUnitIsCloaked(id) then return false end
    if Spring.GetUnitLosState then
        local spectator,fullView = Spring.GetSpectatingState()
        if not (spectator and fullView) then
            local los = Spring.GetUnitLosState(id)
            if not los or not los.los then return false end
        end
    end
    return true
end
function M.UnitEnvelope(id)
    if not visible(id) then return end
    local defID = Spring.GetUnitDefID(id)
    local x,y,z = Spring.GetUnitPosition(id)
    if not finite(x) or not finite(y) or not finite(z) then return end
    local dims = defID and Spring.GetUnitDefDimensions and Spring.GetUnitDefDimensions(defID)
    local lo,hi,radius
    if dims and finite(dims.miny) and finite(dims.maxy) and dims.maxy>dims.miny then
        -- Imported bounds, not the small authored selection height of standalone houses.
        lo,hi = dims.miny,dims.maxy
        if finite(dims.minx) and finite(dims.maxx) and finite(dims.minz) and finite(dims.maxz) then
            local rx = math.max(math.abs(dims.minx),math.abs(dims.maxx))
            local rz = math.max(math.abs(dims.minz),math.abs(dims.maxz))
            radius = math.sqrt(rx*rx+rz*rz)
        end
    else
        local height = Spring.GetUnitHeight and Spring.GetUnitHeight(id)
        if not finite(height) or height<=0 then return end -- unknown height is never an infinite column
        lo,hi = 0,height
    end
    radius = math.min(1024,math.max(8,radius or (Spring.GetUnitRadius and Spring.GetUnitRadius(id)) or 32))
    return {x=x,z=z,bottom=y+lo,top=y+hi,radius=radius,
        reach=math.min(512,192+radius),fade=math.min(128,math.max(24,(hi-lo)*0.3))}
end
function M.LampEnvelope(light)
    local a,b,front,range = light.a,light.b,light.front,light.range
    if not a or not b or not front or not finite(range) or range<=0 then return end
    for i=1,3 do if not finite(a[i]) or not finite(b[i]) or not finite(front[i]) then return end end
    local length = math.sqrt(front[1]^2+front[3]^2)
    if length<0.001 then return end
    -- Follow the real lamps, including bridges/elevated vehicles, rather than sea level.
    return {x=(a[1]+b[1])*0.5+front[1]/length*range*0.35,
        z=(a[3]+b[3])*0.5+front[3]/length*range*0.35,
        bottom=math.min(a[2],b[2])-4,top=math.max(a[2],b[2])+4,
        radius=range*0.35,reach=range*0.65,fade=math.max(12,math.min(24,range*0.06))}
end
function M.New()
    local self = {ready=false}
    local uniforms = {}
    function self:Shutdown()
        self.ready=false
        if self.fbo then gl.DeleteFBO(self.fbo);self.fbo=nil end
        for _,key in ipairs({'texture','depth'}) do
            if self[key] then gl.DeleteTexture(self[key]);self[key]=nil end
        end
        if self.shader then gl.DeleteShader(self.shader);self.shader=nil end
    end
    function self:Allocate()
        if self.fbo then return true end
        if self.failed then return false end
        local function fail(reason)
            self:Shutdown();self.failed=true
            Spring.Echo('Fog radiance disabled: '..reason)
            return false
        end
        for _,name in ipairs({'CreateFBO','ActiveFBO','IsValidFBO'}) do
            if not gl[name] then return fail('missing gl.'..name) end
        end
        self.shader=gl.CreateShader({vertex=VFS.LoadFile(PATH..'fog_heights.vert'),
            fragment=VFS.LoadFile(PATH..'fog_heights.frag')})
        if not self.shader then return fail('height shader: '..tostring(gl.GetShaderLog())) end
        local options={format=GL.RGBA16F or 0x881A,min_filter=GL.NEAREST,mag_filter=GL.NEAREST,
            wrap_s=GL.CLAMP_TO_EDGE,wrap_t=GL.CLAMP_TO_EDGE}
        self.texture=gl.CreateTexture(SIZE,SIZE,options)
        options.format=GL.DEPTH_COMPONENT24 or 0x81A6
        self.depth=gl.CreateTexture(SIZE,SIZE,options)
        if not self.texture or not self.depth then return fail('height texture allocation') end
        self.fbo=gl.CreateFBO({color0=self.texture,depth=self.depth})
        if not self.fbo or not gl.IsValidFBO(self.fbo) then return fail('height framebuffer incomplete') end
        for _,name in ipairs({'sourceXZ','sourceShape','sourceY'}) do
            uniforms[name]=gl.GetUniformLocation(self.shader,name)
        end
        return true
    end
    function self:Refresh(unitSet, lamps)
        self.ready=false
        local sources,ids={},{}
        for id in pairs(unitSet or {}) do ids[#ids+1]=id end
        table.sort(ids) -- deterministic tie-breaking for overlapping footprints
        for _,id in ipairs(ids) do
            local source=M.UnitEnvelope(id)
            if source then sources[#sources+1]=source end
        end
        for _,lamp in ipairs(lamps or {}) do
            local source=M.LampEnvelope(lamp)
            if source then sources[#sources+1]=source end
        end
        if #sources==0 or not self:Allocate() then return end
        gl.PushAttrib(GL.ALL_ATTRIB_BITS)
        gl.ActiveFBO(self.fbo,function()
            gl.DepthTest(GL.LESS);gl.DepthMask(true);gl.Blending(false);gl.Culling(false)
            gl.Clear(GL.COLOR_BUFFER_BIT,0,0,0,0);gl.Clear(GL.DEPTH_BUFFER_BIT,1)
            gl.UseShader(self.shader)
            for _,s in ipairs(sources) do
                gl.Uniform(uniforms.sourceXZ,s.x,s.z)
                gl.Uniform(uniforms.sourceShape,s.radius,s.reach,s.fade)
                gl.Uniform(uniforms.sourceY,s.bottom,s.top)
                local r=s.radius+s.reach
                gl.TexRect((s.x-r)/Game.mapSizeX*2-1,(s.z-r)/Game.mapSizeZ*2-1,
                    (s.x+r)/Game.mapSizeX*2-1,(s.z+r)/Game.mapSizeZ*2-1,
                    s.x-r,s.z-r,s.x+r,s.z+r)
            end
            gl.UseShader(0)
        end)
        gl.PopAttrib()
        self.ready=true
    end
    return self
end
return M
