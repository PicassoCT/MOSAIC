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

return function(emissionSize, singleOutput, heightAware)
    emissionSize = emissionSize or 1024
    -- Source provenance is an optional camera-local extension. Whole-map and
    -- ordinary single-output solvers keep their existing targets and shaders.
    heightAware = heightAware and singleOutput and true or false
    local self = {textures = {}, sourceTextures = {}, fbos = {}, ready = false,
        sourceReady = false, heightAware = heightAware}
    function self:Shutdown()
        self.ready, self.sourceReady = false, false
        -- FBO attachments must be released before their textures.
        for i = 1, #self.fbos do gl.DeleteFBO(self.fbos[i]) end
        self.fbos = {}; self.resolveFBO = nil
        for _, key in ipairs({"cascadeShader","resolveShader","emissionShader","previewShader"}) do
            if self[key] then gl.DeleteShader(self[key]); self[key] = nil end
        end
        for i = 1, #self.textures do gl.DeleteTexture(self.textures[i]) end
        self.textures = {}
        for i = 1, #self.sourceTextures do gl.DeleteTexture(self.sourceTextures[i]) end
        self.sourceTextures = {}
        for _, key in ipairs({"texture","unitTexture","sceneTexture","unitSourceTexture"}) do
            if self[key] then gl.DeleteTexture(self[key]); self[key] = nil end
        end
    end
    local function fail(message)
        self:Shutdown()
        return nil, message
    end
    if heightAware then
        for _, name in ipairs({"CreateFBO","DeleteFBO","ActiveFBO","IsValidFBO"}) do
            if not gl[name] then return fail("source provenance requires gl." .. name) end
        end
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
    if heightAware then
        defines = defines .. "#define HEIGHT_AWARE 1\n"
        resolveSource = resolveSource:gsub("#version 150 compatibility",
            "#version 150 compatibility\n#define HEIGHT_AWARE 1\n", 1)
    end
    cascadeSource = cascadeSource:gsub("#version 150 compatibility", "#version 150 compatibility\n" .. defines, 1)
    local cascadeSamplers = {emissionTex=0, occupancyTex=1, parentTex=2, coarseEmissionTex=3, coarseOccupancyTex=4}
    local resolveSamplers = {cascadeTex=0, occupancyTex=1, emissionTex=2}
    if heightAware then cascadeSamplers.parentSourceTex=5; resolveSamplers.cascadeSourceTex=3 end
    self.cascadeShader = gl.CreateShader({fragment = cascadeSource,
        uniformInt = cascadeSamplers})
    if not self.cascadeShader then return fail("cascade shader: " .. (gl.GetShaderLog() or "failed")) end
    self.resolveShader = gl.CreateShader({fragment = resolveSource,
        uniformInt = resolveSamplers})
    if not self.resolveShader then return fail("resolve shader: " .. (gl.GetShaderLog() or "failed")) end
    self.emissionShader = gl.CreateShader({vertex=emissionVertex,geometry=emissionGeometry,fragment=emissionFragment,
        uniformInt={sourceTex=0,materialTex=1,textured=0,materialMasked=0}})
    if not self.emissionShader then return fail("emission slice shader: " .. (gl.GetShaderLog() or "failed")) end
    self.previewShader = gl.CreateShader({fragment=previewSource,uniformInt={previewTex=0}})
    if not self.previewShader then return fail("preview shader: " .. (gl.GetShaderLog() or "failed")) end
    local options = {format = GL.RGBA16F or 0x881A, min_filter=GL.NEAREST, mag_filter=GL.NEAREST,
        wrap_s=GL.CLAMP_TO_EDGE, wrap_t=GL.CLAMP_TO_EDGE, fbo=true}
    local sourceOptions = {format = GL.RGBA32F or 0x8814, min_filter=GL.NEAREST, mag_filter=GL.NEAREST,
        wrap_s=GL.CLAMP_TO_EDGE, wrap_t=GL.CLAMP_TO_EDGE, fbo=false}
    local function pairedFBO(radiance, provenance)
        local fbo = gl.CreateFBO({color0=radiance,color1=provenance,drawbuffers={0x8CE0,0x8CE1}})
        if not fbo then return end
        self.fbos[#self.fbos+1] = fbo
        if not gl.IsValidFBO(fbo) then return end
        return fbo
    end
    for i=1,COUNT do
        local tex=gl.CreateTexture(SIZE,SIZE,options)
        if not tex then return fail("cascade FBO allocation failed") end
        self.textures[i]=tex
        if heightAware then
            self.sourceTextures[i]=gl.CreateTexture(SIZE,SIZE,sourceOptions)
            if not self.sourceTextures[i] then return fail("cascade source texture allocation failed") end
            if not pairedFBO(tex,self.sourceTextures[i]) then return fail("cascade source framebuffer incomplete") end
        end
    end
    self.unitTexture=gl.CreateTexture(RESOLVE_SIZE,RESOLVE_SIZE,options)
    if not singleOutput then
        self.texture=gl.CreateTexture(RESOLVE_SIZE,RESOLVE_SIZE,options)
        self.sceneTexture=gl.CreateTexture(RESOLVE_SIZE,RESOLVE_SIZE,options)
    end
    if not self.unitTexture or (not singleOutput and (not self.sceneTexture or not self.texture)) then
        return fail("resolve FBO allocation failed")
    end
    if heightAware then
        self.unitSourceTexture=gl.CreateTexture(RESOLVE_SIZE,RESOLVE_SIZE,sourceOptions)
        if not self.unitSourceTexture then return fail("resolve source texture allocation failed") end
        self.resolveFBO=pairedFBO(self.unitTexture,self.unitSourceTexture)
        if not self.resolveFBO then return fail("resolve source framebuffer incomplete") end
    end
    local function loc(shader,name) return gl.GetUniformLocation(shader,name) end
    self.previewExposureLoc=loc(self.previewShader,"exposure")
    self.texturedLoc=loc(self.emissionShader,"textured")
    self.materialMaskedLoc=loc(self.emissionShader,"materialMasked")
    self.emissionStrengthLoc=loc(self.emissionShader,"emissionStrength")
    self.projectToBandLoc=loc(self.emissionShader,"projectToBand")
    self.atlasSizeLoc=loc(self.emissionShader,"atlasSize")
    self.heightLoc=loc(self.emissionShader,"heightRange")
    local indexLoc=loc(self.cascadeShader,"cascadeIndex")
    local parentLoc=loc(self.cascadeShader,"hasParent")
    local mapLoc=loc(self.cascadeShader,"mapSize")
    local localLoc=loc(self.cascadeShader,"localField")
    local originLoc=loc(self.cascadeShader,"domainOrigin")
    local worldLoc=loc(self.cascadeShader,"worldSize")
    local domain
    local intervalLoc=loc(self.cascadeShader,"baseInterval")
    local intensityLoc=loc(self.resolveShader,"intensity")
    local resolveMapLoc, resolveOriginLoc
    if heightAware then
        resolveMapLoc=loc(self.resolveShader,"mapSize")
        resolveOriginLoc=loc(self.resolveShader,"domainOrigin")
    end
    local function cascadePass(index)
        gl.UseShader(self.cascadeShader)
        gl.UniformInt(indexLoc,index)
        gl.UniformInt(parentLoc,index < COUNT-1 and 1 or 0)
        gl.Uniform(mapLoc,domain and domain.span or Game.mapSizeX,domain and domain.span or Game.mapSizeZ)
        gl.UniformInt(localLoc,domain and 1 or 0)
        gl.Uniform(originLoc,domain and domain.x or 0,domain and domain.z or 0)
        gl.Uniform(worldLoc,Game.mapSizeX,Game.mapSizeZ)
        -- Two emission texels on the shorter map axis; highest interval needs
        -- at most 256 half-texel steps even for rectangular maps.
        gl.Uniform(intervalLoc,self.baseInterval)
        fullscreen()
    end
    local function resolvePass(intensity)
        gl.UseShader(self.resolveShader)
        gl.Uniform(intensityLoc,intensity)
        if heightAware then
            gl.Uniform(resolveMapLoc,domain.span,domain.span)
            gl.Uniform(resolveOriginLoc,domain.x,domain.z)
        end
        fullscreen()
    end
    function self:Draw(emission, occupancy, intensity, heightMin, heightMax, sceneOnly, localDomain, coarseEmission, coarseOccupancy)
        self.sourceReady=false
        if heightAware and (sceneOnly or not localDomain) then self.ready=false; return false end
        if not sceneOnly then
            self.ready = false
            self.heightMin, self.heightMax = heightMin, heightMax
        end
        domain=localDomain
        self.mapSizeX, self.mapSizeZ = Game.mapSizeX, Game.mapSizeZ
        self.baseInterval = 2 * math.min(Game.mapSizeX,Game.mapSizeZ) / emissionSize
        gl.AlphaTest(false) -- cascade alpha is transmittance, never coverage
        gl.DepthTest(false); gl.DepthMask(false); gl.Blending(false); gl.Culling(false)
        gl.Color(1,1,1,1)
        gl.Texture(0,emission); gl.Texture(1,occupancy)
        gl.Texture(3,coarseEmission or emission);gl.Texture(4,coarseOccupancy or occupancy)
        for index=COUNT-1,0,-1 do
            -- Never sample the texture attached to the current target FBO.
            gl.Texture(2,index < COUNT-1 and self.textures[index+2] or emission)
            if heightAware then
                gl.Texture(5,index < COUNT-1 and self.sourceTextures[index+2] or emission)
                gl.ActiveFBO(self.fbos[index+1],cascadePass,index)
            else
                gl.RenderToTexture(self.textures[index+1],cascadePass,index)
            end
        end
        gl.Texture(0,self.textures[1]); gl.Texture(1,occupancy); gl.Texture(2,emission)
        if heightAware then gl.Texture(3,self.sourceTextures[1]) end
        if sceneOnly then
            gl.RenderToTexture(self.sceneTexture,resolvePass,1)
        else
            if heightAware then gl.ActiveFBO(self.resolveFBO,resolvePass,1)
            else gl.RenderToTexture(self.unitTexture,resolvePass,1) end
            if not singleOutput then gl.RenderToTexture(self.texture,resolvePass,intensity) end
        end
        gl.UseShader(0)
        for unit=0,(heightAware and 5 or 4) do gl.Texture(unit,false) end
        if not sceneOnly then self.ready=true end
        self.sourceReady=heightAware
        return true
    end
    return self
end
