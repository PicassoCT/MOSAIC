-- One additive scene pass. Prefer engine G-buffers (no owned scene FBOs).
-- Otherwise copy only depth, capped at 16 MiB. Never enables engine settings.
local PATH="luaui/widgets_mosaic/shaders/radiancecascade/scene.frag"
local BUFFERS={"$map_gbuffer_zvaltex","$model_gbuffer_zvaltex",
    "$map_gbuffer_normtex","$model_gbuffer_normtex","$map_gbuffer_difftex","$model_gbuffer_difftex"}
local function fullscreen()
    gl.MatrixMode(GL.PROJECTION);gl.PushMatrix();gl.LoadIdentity()
    gl.MatrixMode(GL.MODELVIEW);gl.PushMatrix();gl.LoadIdentity()
    gl.TexRect(-1,-1,1,1,0,0,1,1)
    gl.PopMatrix();gl.MatrixMode(GL.PROJECTION);gl.PopMatrix();gl.MatrixMode(GL.MODELVIEW)
end
return function()
    local source=VFS.LoadFile(PATH)
    if not source or not gl.UniformMatrix then return nil,"missing scene shader/matrix API" end
    local shader=gl.CreateShader({fragment=source,uniformInt={radianceTex=0,occupancyTex=1,
        mapDepthTex=2,modelDepthTex=3,mapNormalTex=4,modelNormalTex=5,mapDiffuseTex=6,modelDiffuseTex=7,localRadianceTex=8,localOccupancyTex=9,headlightTex=10,headlightLocalTex=11}})
    if not shader then return nil,gl.GetShaderLog() or "scene shader failed" end
    local self={shader=shader,mode="pending",smoothing=true}
    local loc={}
    for _,name in ipairs({"inverseProjection","inverseView","mapSize","heightRange","clipZeroToOne",
        "deferred","strength","nightIntensity","smoothing","localActive","localOrigin","localSpan","headlightActive","headlightLocalActive","headlightOrigin","headlightSpan","headlightIntensity"}) do loc[name]=gl.GetUniformLocation(shader,name) end
    function self:Resize()
        if self.depth then gl.DeleteTexture(self.depth);self.depth=nil end
        self.width,self.height=nil,nil
        self.failedSize=nil
    end
    function self:Shutdown()
        self:Resize()
        if self.shader then gl.DeleteShader(self.shader);self.shader=nil end
    end
    local function buffersAvailable()
        if not gl.TextureInfo or not Spring.GetConfigInt then return false end
        if Spring.GetConfigInt("AllowDeferredMapRendering",0)==0 or
            Spring.GetConfigInt("AllowDeferredModelRendering",0)==0 then return false end
        for _,name in ipairs(BUFFERS) do
            local info=gl.TextureInfo(name)
            if not info or not info.xsize or info.xsize<1 or not info.ysize or info.ysize<1 then return false end
        end
        return true
    end
    function self:Draw(texture,occupancy,heightMin,heightMax,strength,intensity,detail,headlights,headlightIntensity)
        if not self.shader or not texture or intensity<=0 or strength<=0 then return end
        local useDeferred=buffersAvailable()
        local sx,sy,vpx,vpy=Spring.GetViewGeometry()
        if not sx or sx<1 or not sy or sy<1 then return end
        if useDeferred then
            if self.depth then self:Resize() end
            self.mode="deferred"
        else
            local sizeKey=sx.."x"..sy
            if self.failedSize==sizeKey then return end
            if not gl.CopyToTexture or sx*sy>4*1024*1024 then
                self:Resize();self.failedSize=sizeKey;self.mode="unavailable"
                Spring.Echo("Neon scene: depth-copy fallback unavailable or above 16 MiB; previews remain available")
                return
            end
            if self.width~=sx or self.height~=sy then
                self:Resize()
                self.depth=gl.CreateTexture(sx,sy,{format=GL.DEPTH_COMPONENT24 or 0x81A6,
                    min_filter=GL.NEAREST,mag_filter=GL.NEAREST,wrap_s=GL.CLAMP_TO_EDGE,wrap_t=GL.CLAMP_TO_EDGE})
                if not self.depth then
                    self.failedSize=sizeKey;self.mode="unavailable"
                    Spring.Echo("Neon scene: depth-copy allocation failed; previews remain available")
                    return
                end
                self.width,self.height=sx,sy
            end
            gl.CopyToTexture(self.depth,0,0,vpx or 0,vpy or 0,sx,sy)
            self.mode="depth copy"
        end
        gl.Texture(0,texture);gl.Texture(1,occupancy)
        for i,name in ipairs(BUFFERS) do gl.Texture(i+1,useDeferred and name or self.depth) end
        local useLocal=detail and detail.ready
        gl.Texture(8,useLocal and detail.texture or texture)
        gl.Texture(9,useLocal and detail.occupancy or occupancy)
        local useHeadlights=headlights and headlights.ready
        local localHeadlights=useHeadlights and headlights.localReady
        gl.Texture(10,useHeadlights and headlights.texture or texture)
        gl.Texture(11,localHeadlights and headlights.localTexture or texture)
        gl.UseShader(self.shader)
        gl.UniformInt(loc.headlightActive,useHeadlights and 1 or 0)
        gl.UniformInt(loc.headlightLocalActive,localHeadlights and 1 or 0)
        gl.Uniform(loc.headlightOrigin,localHeadlights and headlights.domain.x or 0,localHeadlights and headlights.domain.z or 0)
        gl.Uniform(loc.headlightSpan,localHeadlights and headlights.domain.span or 1)
        gl.UniformInt(loc.smoothing,self.smoothing and 1 or 0)
        gl.UniformInt(loc.localActive,useLocal and 1 or 0)
        gl.Uniform(loc.localOrigin,useLocal and detail.domain.x or 0,useLocal and detail.domain.z or 0)
        gl.Uniform(loc.localSpan,useLocal and detail.domain.span or 1)
        gl.UniformMatrix(loc.inverseProjection,"projectioninverse")
        gl.UniformMatrix(loc.inverseView,"viewinverse")
        gl.Uniform(loc.mapSize,Game.mapSizeX,Game.mapSizeZ)
        gl.Uniform(loc.heightRange,heightMin,heightMax)
        gl.Uniform(loc.headlightIntensity,headlightIntensity or 1)
        gl.Uniform(loc.strength,strength);gl.Uniform(loc.nightIntensity,intensity)
        gl.UniformInt(loc.deferred,useDeferred and 1 or 0)
        gl.UniformInt(loc.clipZeroToOne,Platform and Platform.glSupportClipSpaceControl and 1 or 0)
        gl.DepthTest(false);gl.DepthMask(false);gl.Culling(false)
        gl.Blending(GL.ONE,GL.ONE);gl.Color(1,1,1,1)
        fullscreen()
        gl.UseShader(0)
        for i=0,11 do gl.Texture(i,false) end
        gl.Blending(GL.SRC_ALPHA,GL.ONE_MINUS_SRC_ALPHA)
        gl.DepthMask(true);gl.DepthTest(true);gl.Color(1,1,1,1)
    end
    return self
end

