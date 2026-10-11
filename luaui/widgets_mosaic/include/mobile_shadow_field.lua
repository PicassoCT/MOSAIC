-- Live analytic caster data and source positions, separate from static building
-- occupancy. Fixed allocations; no moving unit invalidates a facade bake.
local M={size=256,height=32,gridSize=32,cellCap=16,maxCasters=128,margin=512}
local GRID_OFFSET=256*5
local floor,min,max=math.floor,math.min,math.max
local function identity(fn,...)
    local projection,modelview
    local ok,reason=pcall(function(...)
        gl.MatrixMode(GL.PROJECTION);gl.PushMatrix();projection=true;gl.LoadIdentity()
        gl.MatrixMode(GL.MODELVIEW);gl.PushMatrix();modelview=true;gl.LoadIdentity()
        fn(...)
    end,...)
    -- ResetMatrices reloads only the current stack entries in Recoil. Unwind
    -- our pushes here so a failed optional upload cannot corrupt scene draws.
    if modelview then gl.MatrixMode(GL.MODELVIEW);gl.PopMatrix() end
    if projection then gl.MatrixMode(GL.PROJECTION);gl.PopMatrix() end
    gl.MatrixMode(GL.MODELVIEW)
    if not ok then error(reason,0) end
end
-- A shader is necessary here: fixed-function gl.Color clamps world positions.
local dataVertex=[[#version 150 compatibility
out vec4 payload;
void main(){gl_Position=gl_ModelViewProjectionMatrix*gl_Vertex;payload=gl_MultiTexCoord0;}
]]
local dataFragment=[[#version 150 compatibility
in vec4 payload;
void main(){gl_FragColor=payload;}
]]
function M.New(profiles)
    if not gl.CreateFBO or not gl.ActiveFBO or not gl.Viewport then return nil,"FBO API unavailable" end
    local self={enabled=true,ready=false,count=0,cascadeReady=false,directReady=false,stats={}}
    local collector=VFS.Include("luaui/widgets_mosaic/include/mobile_shadow_sources.lua").New(profiles,{maxCasters=M.maxCasters})
    self.collector=collector
    local cells,counts={},{}
    for i=1,M.gridSize*M.gridSize do cells[i]={};counts[i]=0 end
    local dataShader=gl.CreateShader({vertex=dataVertex,fragment=dataFragment})
    local copyShader=gl.CreateShader({fragment=[[#version 150 compatibility
uniform sampler2D sourceTex;
void main(){gl_FragColor=texture2D(sourceTex,gl_TexCoord[0].st);}
]],uniformInt={sourceTex=0}})
    function self:Shutdown()
        self.ready,self.cascadeReady,self.directReady=false,false,false
        self.collector:Shutdown()
        if self.sourceFBO then gl.DeleteFBO(self.sourceFBO);self.sourceFBO=nil end
        for _,key in ipairs({"texture","sourceAtlas","sourceDepth"}) do
            if self[key] then gl.DeleteTexture(self[key]);self[key]=nil end
        end
        if dataShader then gl.DeleteShader(dataShader);dataShader=nil end
        if copyShader then gl.DeleteShader(copyShader);copyShader=nil end
    end
    local function fail(reason) self:Shutdown();return nil,reason end
    if not dataShader or not copyShader then return fail(gl.GetShaderLog() or "data shader failed") end
    local function texture(w,h,format,fbo)
        return gl.CreateTexture(w,h,{format=format,min_filter=GL.NEAREST,mag_filter=GL.NEAREST,
            wrap_s=GL.CLAMP_TO_EDGE,wrap_t=GL.CLAMP_TO_EDGE,fbo=fbo})
    end
    self.texture=texture(M.size,M.height,GL.RGBA32F or 0x8814,true)
    -- One sampler for both provenance fields keeps the scene at 16 samplers.
    -- Left half is the resolved cascade source; right half is the live lamp.
    self.sourceAtlas=texture(1024,512,GL.RGBA32F or 0x8814,false)
    self.sourceDepth=texture(1024,512,GL.DEPTH_COMPONENT24 or 0x81A6,false)
    if not self.texture or not self.sourceAtlas or not self.sourceDepth then return fail("texture allocation failed") end
    self.sourceFBO=gl.CreateFBO({color0=self.sourceAtlas,depth=self.sourceDepth})
    if not self.sourceFBO or (gl.IsValidFBO and not gl.IsValidFBO(self.sourceFBO)) then return fail("source framebuffer incomplete") end
    local function pixel(index,a,b,c,d)
        gl.TexCoord(a or 0,b or 0,c or 0,d or 0)
        gl.Vertex((index%M.size+.5)*2/M.size-1,(floor(index/M.size)+.5)*2/M.height-1)
    end
    local function vertices(records)
        for i=1,#records do
            local r=records[i];local offset=(i-1)*5
            pixel(offset,r.center[1],r.center[2],r.center[3],r.shape)
            pixel(offset+1,r.axisX[1],r.axisX[2],r.axisX[3],r.half[1])
            pixel(offset+2,r.axisY[1],r.axisY[2],r.axisY[3],r.half[2])
            pixel(offset+3,r.axisZ[1],r.axisZ[2],r.axisZ[3],r.half[3])
            pixel(offset+4,r.unitID,0,0,0)
        end
        for i=1,#cells do
            local n=counts[i]
            if n>0 then
                local cell=cells[i]
                for j=1,n,4 do pixel(GRID_OFFSET+(i-1)*4+floor((j-1)/4),
                    cell[j],j+1<=n and cell[j+1] or 0,j+2<=n and cell[j+2] or 0,j+3<=n and cell[j+3] or 0) end
            end
        end
    end
    local function upload(records)
        gl.Clear(GL.COLOR_BUFFER_BIT,0,0,0,0)
        gl.DepthTest(false);gl.DepthMask(false);gl.Culling(false);gl.Blending(false);gl.AlphaTest(false)
        gl.UseShader(dataShader);gl.PointSize(1)
        identity(function() gl.BeginEnd(GL.POINTS,vertices,records) end)
        gl.UseShader(0);gl.Color(1,1,1,1)
    end
    function self:Invalidate() self.drawFrame=nil;self.collector:Invalidate() end
    function self:Update(domain)
        if not self.enabled or not domain then
            self.ready,self.cascadeReady,self.directReady=false,false,false
            self.count=0;self.drawFrame=nil;self.collector:Clear();return
        end
        local drawFrame=Spring.GetDrawFrame()
        if self.drawFrame==drawFrame and self.domainX==domain.x and self.domainZ==domain.z and self.domainSpan==domain.span then return end
        local records,stats=self.collector:Collect({minX=domain.x,maxX=domain.x+domain.span,
            minZ=domain.z,maxZ=domain.z+domain.span,margin=M.margin},drawFrame)
        self.originX,self.originZ,self.span=domain.x-M.margin,domain.z-M.margin,domain.span+2*M.margin
        for i=1,#counts do counts[i]=0 end
        local overflow,occupied=0,0
        local scale=M.gridSize/self.span
        for index,r in ipairs(records) do
            local x0=max(0,min(M.gridSize-1,floor((r.minX-self.originX)*scale)))
            local x1=max(0,min(M.gridSize-1,floor((r.maxX-self.originX)*scale)))
            local z0=max(0,min(M.gridSize-1,floor((r.minZ-self.originZ)*scale)))
            local z1=max(0,min(M.gridSize-1,floor((r.maxZ-self.originZ)*scale)))
            for z=z0,z1 do for x=x0,x1 do
                local key=z*M.gridSize+x+1;local n=counts[key]
                if n<M.cellCap then
                    if n==0 then occupied=occupied+1 end
                    counts[key]=n+1;cells[key][n+1]=index
                else overflow=overflow+1 end
            end end
        end
        self.count=#records;self.stats=stats;stats.gridOverflow=overflow;stats.occupiedCells=occupied
        self.minY,self.maxY=stats.minY or 0,stats.maxY or 0
        gl.RenderToTexture(self.texture,upload,records)
        self.ready=self.count>0
        self.drawFrame,self.domainX,self.domainZ,self.domainSpan=drawFrame,domain.x,domain.z,domain.span
    end
    local function copyCascade(texture)
        gl.UseShader(copyShader);gl.Texture(0,texture)
        gl.TexRect(-1,-1,1,1,0,0,1,1)
        gl.Texture(0,false);gl.UseShader(0)
    end
    function self:CaptureSources(capture,bottom,top,domain,detail)
        self.cascadeReady,self.directReady=false,false
        if not self.ready or not domain then return end
        local useCascade=detail and detail.ready and detail.sourceTexture
        gl.ActiveFBO(self.sourceFBO,function()
            gl.Viewport(0,0,1024,512)
            gl.UseShader(0);gl.Texture(0,false);gl.Color(1,1,1,1)
            gl.DepthMask(true);gl.DepthTest(false);gl.Blending(false);gl.Culling(false);gl.AlphaTest(false)
            gl.Clear(GL.COLOR_BUFFER_BIT,0,0,0,0);gl.Clear(GL.DEPTH_BUFFER_BIT,1)
            gl.DepthMask(false)
            if useCascade then
                gl.Viewport(0,0,512,512);identity(copyCascade,detail.sourceTexture)
                self.cascadeReady=true
            end
            if capture then
                gl.Viewport(512,0,512,512)
                identity(function()
                    gl.MatrixMode(GL.PROJECTION)
                    gl.Ortho(domain.x,domain.x+domain.span,domain.z,domain.z+domain.span,-100000,100000)
                    gl.MatrixMode(GL.MODELVIEW);gl.Rotate(-90,1,0,0)
                    -- Metadata mode uses depth to retain the brightest actual
                    -- lamp, with its owner ID. Never average source positions.
                    capture(bottom,top,1,true)
                end)
                self.directReady=true
            end
        end)
        gl.UseShader(0);gl.Texture(0,false);gl.Blending(false);gl.DepthMask(false);gl.DepthTest(false)
        gl.Color(1,1,1,1)
    end
    function self:Locations(shader)
        local result={}
        for _,name in ipairs({"mobileShadowOrigin","mobileShadowSpan","mobileShadowCount","mobileShadowActive",
            "mobileShadowHeight","mobileCascadeSourceActive","mobileDirectSourceActive"}) do
            result[name]=gl.GetUniformLocation(shader,name)
        end
        return result
    end
    function self:Bind(loc)
        gl.Texture(14,self.sourceAtlas);gl.Texture(15,self.texture)
        gl.UniformInt(loc.mobileShadowActive,self.ready and self.enabled and 1 or 0)
        gl.UniformInt(loc.mobileShadowCount,self.count)
        gl.Uniform(loc.mobileShadowOrigin,self.originX or 0,self.originZ or 0)
        gl.Uniform(loc.mobileShadowSpan,self.span or 1)
        gl.Uniform(loc.mobileShadowHeight,self.minY or 0,self.maxY or 0)
        gl.UniformInt(loc.mobileCascadeSourceActive,self.cascadeReady and 1 or 0)
        gl.UniformInt(loc.mobileDirectSourceActive,self.directReady and 1 or 0)
    end
    return self
end
return M
