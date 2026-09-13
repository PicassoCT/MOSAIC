-- Four fixed-size 2D radiance cascades for one occupancy height band.
-- RGB is radiance; alpha is transmittance. No previous-frame feedback.
local PATH = "luaui/widgets_mosaic/shaders/radiancecascade/"
local COUNT, PROBES, SIZE, RESOLVE_SIZE = 4, 128, 256, 512
local MAX_STEPS = 256

local function fullscreen()
    gl.MatrixMode(GL.PROJECTION); gl.PushMatrix(); gl.LoadIdentity()
    gl.MatrixMode(GL.MODELVIEW); gl.PushMatrix(); gl.LoadIdentity()
    gl.TexRect(-1,-1,1,1,0,0,1,1)
    gl.PopMatrix()
    gl.MatrixMode(GL.PROJECTION); gl.PopMatrix()
    gl.MatrixMode(GL.MODELVIEW)
end

return function(emissionSize)
    emissionSize = emissionSize or 1024
    local self = {textures = {}, ready = false}
    function self:Shutdown()
        self.ready = false
        for _, key in ipairs({"cascadeShader","resolveShader","emissionShader","previewShader"}) do
            if self[key] then gl.DeleteShader(self[key]); self[key] = nil end
        end
        for i = 1, #self.textures do gl.DeleteTexture(self.textures[i]) end
        self.textures = {}
        for _, key in ipairs({"texture","unitTexture"}) do
            if self[key] then gl.DeleteTexture(self[key]); self[key] = nil end
        end
    end
    local function fail(message)
        self:Shutdown()
        return nil, message
    end
    local function source(name)
        return VFS.LoadFile(PATH .. name)
    end
    local cascadeSource, resolveSource = source("propagate.frag"), source("resolve.frag")
    local emissionVertex, emissionFragment = source("emission_slice.vert"), source("emission_slice.frag")
    local emissionGeometry, previewSource = source("emission_slice.geom"), source("preview.frag")
    if not emissionGeometry or not previewSource then return fail("missing capture/preview shader source") end
    if not cascadeSource or not resolveSource or not emissionVertex or not emissionFragment then
        return fail("missing propagation shader source")
    end
    local defines = string.format("#define BASE_PROBES %d\n#define CASCADE_COUNT %d\n#define MAX_TRACE_STEPS %d\n", PROBES, COUNT, MAX_STEPS)
    cascadeSource = cascadeSource:gsub("#version 150 compatibility", "#version 150 compatibility\n" .. defines, 1)
    self.cascadeShader = gl.CreateShader({fragment = cascadeSource,
        uniformInt = {emissionTex=0, occupancyTex=1, parentTex=2}})
    if not self.cascadeShader then return fail("cascade shader: " .. (gl.GetShaderLog() or "failed")) end
    self.resolveShader = gl.CreateShader({fragment = resolveSource,
        uniformInt = {cascadeTex=0, occupancyTex=1, emissionTex=2}})
    if not self.resolveShader then return fail("resolve shader: " .. (gl.GetShaderLog() or "failed")) end
    self.emissionShader = gl.CreateShader({vertex=emissionVertex,geometry=emissionGeometry,fragment=emissionFragment})
    if not self.emissionShader then return fail("emission slice shader: " .. (gl.GetShaderLog() or "failed")) end
    self.previewShader = gl.CreateShader({fragment=previewSource,uniformInt={previewTex=0}})
    if not self.previewShader then return fail("preview shader: " .. (gl.GetShaderLog() or "failed")) end
    local options = {format = GL.RGBA16F or 0x881A, min_filter=GL.NEAREST, mag_filter=GL.NEAREST,
        wrap_s=GL.CLAMP_TO_EDGE, wrap_t=GL.CLAMP_TO_EDGE, fbo=true}
    for i=1,COUNT do
        local tex=gl.CreateTexture(SIZE,SIZE,options)
        if not tex then return fail("cascade FBO allocation failed") end
        self.textures[i]=tex
    end
    self.unitTexture=gl.CreateTexture(RESOLVE_SIZE,RESOLVE_SIZE,options)
    self.texture=gl.CreateTexture(RESOLVE_SIZE,RESOLVE_SIZE,options)
    if not self.unitTexture or not self.texture then return fail("resolve FBO allocation failed") end
    local function loc(shader,name) return gl.GetUniformLocation(shader,name) end
    self.previewExposureLoc=loc(self.previewShader,"exposure")
    self.atlasSizeLoc=loc(self.emissionShader,"atlasSize")
    self.heightLoc=loc(self.emissionShader,"heightRange")
    local indexLoc=loc(self.cascadeShader,"cascadeIndex")
    local parentLoc=loc(self.cascadeShader,"hasParent")
    local mapLoc=loc(self.cascadeShader,"mapSize")
    local intervalLoc=loc(self.cascadeShader,"baseInterval")
    local intensityLoc=loc(self.resolveShader,"intensity")
    local function cascadePass(index)
        gl.UseShader(self.cascadeShader)
        gl.UniformInt(indexLoc,index)
        gl.UniformInt(parentLoc,index < COUNT-1 and 1 or 0)
        gl.Uniform(mapLoc,Game.mapSizeX,Game.mapSizeZ)
        -- Two emission texels on the shorter map axis; highest interval needs
        -- at most 256 half-texel steps even for rectangular maps.
        gl.Uniform(intervalLoc,self.baseInterval)
        fullscreen()
    end
    local function resolvePass(intensity)
        gl.UseShader(self.resolveShader)
        gl.Uniform(intensityLoc,intensity)
        fullscreen()
    end
    function self:Draw(emission, occupancy, intensity, heightMin, heightMax)
        self.ready = false
        self.heightMin, self.heightMax = heightMin, heightMax
        self.mapSizeX, self.mapSizeZ = Game.mapSizeX, Game.mapSizeZ
        self.baseInterval = 2 * math.min(Game.mapSizeX,Game.mapSizeZ) / emissionSize
        gl.DepthTest(false); gl.DepthMask(false); gl.Blending(false); gl.Culling(false)
        gl.Color(1,1,1,1)
        gl.Texture(0,emission); gl.Texture(1,occupancy)
        for index=COUNT-1,0,-1 do
            -- Never sample the texture attached to the current target FBO.
            gl.Texture(2,index < COUNT-1 and self.textures[index+2] or emission)
            gl.RenderToTexture(self.textures[index+1],cascadePass,index)
        end
        gl.Texture(0,self.textures[1]); gl.Texture(1,occupancy); gl.Texture(2,emission)
        gl.RenderToTexture(self.unitTexture,resolvePass,1)
        gl.RenderToTexture(self.texture,resolvePass,intensity)
        gl.UseShader(0)
        for unit=0,2 do gl.Texture(unit,false) end
        self.ready=true
    end
    return self
end
