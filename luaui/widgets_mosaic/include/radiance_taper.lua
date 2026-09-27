-- Automatic house_asian1/3 experiment, with optional single-house selection.
-- Full intensity in daylight is enabled on this prototype branch for testing.
-- Two 256-square floating-point capture targets + depth; allocated on demand.
-- Capture the actual visible piece set, then splat at original facade positions.
local PATH = "luaui/widgets_mosaic/shaders/radiancecascade/"
local SIZE = 256
local SUPPORTED = {house_asian1=true, house_asian3=true}

return function()
    local self = {enabled=true, automatic=true, test=true, units={}, ready=false, preview=false, taper=0.18,
        falloff=256, strength=0.15, span=1536, height=1536, age=1, scanAge=1}
    local captureLoc, splatLoc = {}, {}
    local function echo(message) Spring.Echo("Radiance taper: " .. message) end
    function self:Shutdown()
        self.ready=false
        if self.fbo then gl.DeleteFBO(self.fbo); self.fbo=nil end
        if self.points then gl.DeleteList(self.points); self.points=nil end
        for _,key in ipairs({"emission", "position", "depth"}) do
            if self[key] then gl.DeleteTexture(self[key]); self[key]=nil end
        end
        for _,key in ipairs({"captureShader", "splatShader"}) do
            if self[key] then gl.DeleteShader(self[key]); self[key]=nil end
        end
    end
    function self:Allocate()
        if self.fbo then return true end
        for _,name in ipairs({"CreateFBO", "ActiveFBO", "IsValidFBO", "Unit", "CreateList"}) do
            if not gl[name] then echo("missing gl." .. name); return false end
        end
        local function fail(reason)
            echo(reason); self:Shutdown(); return false
        end
        local sources={}
        for _,name in ipairs({"taper_capture.vert", "taper_capture.frag", "taper_splat.vert", "taper_splat.geom", "taper_splat.frag"}) do
            sources[name]=VFS.LoadFile(PATH..name)
            if not sources[name] then return fail("missing "..name) end
        end
        self.captureShader=gl.CreateShader({vertex=sources["taper_capture.vert"],
            fragment=sources["taper_capture.frag"], uniformInt={sourceTex=0, materialTex=1}})
        if not self.captureShader then return fail("capture shader: "..(gl.GetShaderLog() or "failed")) end
        self.splatShader=gl.CreateShader({vertex=sources["taper_splat.vert"], geometry=sources["taper_splat.geom"],
            fragment=sources["taper_splat.frag"], uniformInt={captureEmission=0, capturePosition=1}})
        if not self.splatShader then return fail("splat shader: "..(gl.GetShaderLog() or "failed")) end
        local options={format=GL.RGBA32F or 0x8814, min_filter=GL.NEAREST, mag_filter=GL.NEAREST,
            wrap_s=GL.CLAMP_TO_EDGE, wrap_t=GL.CLAMP_TO_EDGE}
        self.emission=gl.CreateTexture(SIZE,SIZE,options)
        self.position=gl.CreateTexture(SIZE,SIZE,options)
        self.depth=gl.CreateTexture(SIZE,SIZE,{format=GL.DEPTH_COMPONENT24 or 0x81A6,
            min_filter=GL.NEAREST, mag_filter=GL.NEAREST, wrap_s=GL.CLAMP_TO_EDGE, wrap_t=GL.CLAMP_TO_EDGE})
        if not self.emission or not self.position or not self.depth then return fail("capture texture allocation failed") end
        self.fbo=gl.CreateFBO({color0=self.emission,color1=self.position,depth=self.depth,
            drawbuffers={GL.COLOR_ATTACHMENT0_EXT or 0x8CE0, GL.COLOR_ATTACHMENT1_EXT or 0x8CE1}})
        if not self.fbo or not gl.IsValidFBO(self.fbo) then return fail("capture framebuffer incomplete") end
        self.points=gl.CreateList(function()
            gl.BeginEnd(GL.POINTS,function()
                for y=0,SIZE-1 do for x=0,SIZE-1 do gl.Vertex((x+0.5)/SIZE,(y+0.5)/SIZE,0) end end
            end)
        end)
        if not self.points then return fail("sample list allocation failed") end
        for _,name in ipairs({"buildingOrigin", "taperAmount", "taperHeight", "clipZeroToOne"}) do
            captureLoc[name]=gl.GetUniformLocation(self.captureShader,name)
        end
        for _,name in ipairs({"domainOrigin", "domainSize", "atlasSize", "heightRange", "heightFalloff", "emissionStrength", "sourceOffset"}) do
            splatLoc[name]=gl.GetUniformLocation(self.splatShader,name)
        end
        return true
    end
    local function valid(unitID)
        if not unitID or not Spring.ValidUnitID(unitID) or Spring.GetUnitIsDead(unitID) then return false end
        local defID=Spring.GetUnitDefID(unitID)
        local def=defID and UnitDefs and UnitDefs[defID]
        if not def or not SUPPORTED[def.name] then return false end
        -- Never continue showing a cached emitter after losing access to it.
        if Spring.GetUnitLosState then
            local spectating,fullView=Spring.GetSpectatingState()
            if not (spectating and fullView) then
                local los=Spring.GetUnitLosState(unitID)
                if not los or not los.los then return false end
            end
        end
        return defID
    end
    local function automaticUnit(unitID)
        return valid(unitID)
    end
    function self:Fit(unitID)
        local defID=valid(unitID)
        local dims=defID and Spring.GetUnitDefDimensions and Spring.GetUnitDefDimensions(defID)
        if dims and dims.minx and dims.maxx and dims.minz and dims.maxz then
            local rx=math.max(math.abs(dims.minx),math.abs(dims.maxx))
            local rz=math.max(math.abs(dims.minz),math.abs(dims.maxz))
            if not self.spanOverride then self.span=math.max(128,2.1*math.sqrt(rx*rx+rz*rz)) end
            if not self.heightOverride then self.height=math.max(64,dims.maxy or 1536) end
        end
    end
    function self:GetDebugPosition(unitID)
        if not self.enabled then return end
        unitID=unitID or self.focusID or self.unitID
        if not valid(unitID) then return end
        if self.automatic then
            if not automaticUnit(unitID) then return end
        elseif unitID~=self.unitID then return end
        local x,y,z=Spring.GetUnitPosition(unitID)
        if x then return x,y,z,unitID end
    end
    function self:Focus(unitID)
        local x,y,z,id=self:GetDebugPosition(unitID)
        if x then self.focusID=id; return x,y,z,id end
    end
    function self:TextCommand(command)
        if not command:match("^radiancetaper%s") and command~="radiancetaper" then return false end
        if command=="radiancetaper off" then
            self.enabled=false; self.ready=false; echo("OFF"); return true
        end
        if command=="radiancetaper auto" then
            self.enabled=true; self.automatic=true; self.ready=false; self.scanAge=1
            echo("automatic house_asian1/3 emission ON"); return true
        end
        if command=="radiancetaper test on" or command=="radiancetaper test off" then
            self.test=command=="radiancetaper test on"
            echo("daylight test "..(self.test and "ON" or "OFF")); return true
        end
        if command=="radiancetaper debug on" or command=="radiancetaper debug off" then
            self.preview=command=="radiancetaper debug on"; return true
        end
        local id=command:match("^radiancetaper on (%d+)$")
        if command=="radiancetaper on" or id then
            local unitID=tonumber(id) or (Spring.GetSelectedUnits() or {})[1]
            if not valid(unitID) then echo("select a visible Arcology or Project (house_asian1/3)"); return true end
            self.unitID=unitID; self.focusID=unitID; self.enabled=true; self.automatic=false; self.ready=false; self.age=1
            -- The model's authored radius/height are selection helpers (25/40),
            -- not its real bounds. Use imported extents, including all variants,
            -- conservatively; span/height commands can tighten a chosen variant.
            self.spanOverride=false; self.heightOverride=false; self:Fit(unitID)
            echo("ON for unit "..unitID.."; /radiancetaper debug on shows the capture")
            return true
        end
        local key,value=command:match("^radiancetaper (%a+) ([%d%.]+)$")
        value=tonumber(value)
        local limits={taper={0.03,0.4},falloff={16,4096},strength={0,8},span={128,8192},height={64,8192}}
        if limits[key] and value then
            self[key]=math.max(limits[key][1],math.min(limits[key][2],value))
            if key=="span" or key=="height" then self[key.."Override"]=true end
            self.age=1; self.ready=false; echo(key.." = "..self[key]); return true
        end
        echo("automatic house_asian1/3; auto | off | on [UNITID] | test on/off | debug on/off | taper 0.18 | falloff 256 | strength 0.15 | span 1536 | height 1536")
        return true
    end
    function self:Update(dt) self.age=self.age+dt; self.scanAge=self.scanAge+dt end
    function self:Refresh()
        if not self.enabled then return end
        if not self.automatic then self:Capture(); return end
        if self.scanAge>=1 then
            self.units={}
            for _,id in ipairs(Spring.GetAllUnits and Spring.GetAllUnits() or {}) do
                if automaticUnit(id) then self.units[#self.units+1]=id end
            end
            table.sort(self.units)
            self.scanAge=0
        end
        local selected=(Spring.GetSelectedUnits() or {})[1]
        if automaticUnit(selected) then self.focusID=selected
        elseif not automaticUnit(self.focusID) then self.focusID=self.units[1] end
        if not valid(self.unitID) then self.ready=false end
    end
    function self:Capture()
        if not self.enabled then return end
        local defID=valid(self.unitID)
        if not defID then self.ready=false; return end
        if self.ready and self.age<1 then return end
        self.ready=false
        if not self:Allocate() then self.enabled=false; return end
        local x,y,z=Spring.GetUnitPosition(self.unitID)
        if not x then return end
        self.x,self.y,self.z=x,y,z
        -- Bind BOTH material textures, and never turn missing masks into white light.
        local diffuse=gl.Texture(0,"%"..defID..":0")
        local material=gl.Texture(1,"%"..defID..":1")
        if not diffuse or not material then
            gl.Texture(0,false); gl.Texture(1,false)
            self.enabled=false; echo("model textures unavailable"); return
        end
        gl.ActiveFBO(self.fbo,function()
            gl.DepthMask(true); gl.DepthTest(GL.LESS); gl.Blending(false); gl.Culling(false)
            gl.Clear(GL.COLOR_BUFFER_BIT,0,0,0,0); gl.Clear(GL.DEPTH_BUFFER_BIT,1)
            gl.UseShader(self.captureShader)
            gl.Uniform(captureLoc.buildingOrigin,x,y,z)
            gl.Uniform(captureLoc.taperAmount,self.taper); gl.Uniform(captureLoc.taperHeight,self.height)
            gl.UniformInt(captureLoc.clipZeroToOne,Platform and Platform.glSupportClipSpaceControl and 1 or 0)
            gl.MatrixMode(GL.PROJECTION); gl.PushMatrix(); gl.LoadIdentity()
            -- With -90 X, view Z is -world Y. Reverse the depth interval so
            -- higher roofs win GL.LESS rather than looking up from below.
            gl.Ortho(x-self.span/2,x+self.span/2,z-self.span/2,z+self.span/2,100000,-100000)
            gl.MatrixMode(GL.MODELVIEW); gl.PushMatrix(); gl.LoadIdentity(); gl.Rotate(-90,1,0,0)
            -- Raw material draw retains visible-piece transforms; skips Lua material/callin recursion.
            gl.Unit(self.unitID,true,-1,true)
            gl.PopMatrix(); gl.MatrixMode(GL.PROJECTION); gl.PopMatrix(); gl.MatrixMode(GL.MODELVIEW)
            gl.UseShader(0)
        end)
        gl.Texture(0,false); gl.Texture(1,false); gl.DepthMask(false); gl.DepthTest(false); gl.Blending(false)
        self.age=0; self.ready=true
    end
    function self:DrawCapture(bottom,top,domain,atlasSize,intensity)
        if not self.enabled or not self.ready or intensity<=0 or not valid(self.unitID) then return end
        gl.UseShader(self.splatShader)
        gl.Texture(0,self.emission); gl.Texture(1,self.position)
        gl.Uniform(splatLoc.domainOrigin,domain and domain.x or 0,domain and domain.z or 0)
        gl.Uniform(splatLoc.domainSize,domain and domain.span or Game.mapSizeX,domain and domain.span or Game.mapSizeZ)
        gl.Uniform(splatLoc.atlasSize,atlasSize,atlasSize)
        gl.Uniform(splatLoc.heightRange,bottom,top)
        gl.Uniform(splatLoc.heightFalloff,self.falloff)
        gl.Uniform(splatLoc.emissionStrength,self.strength*intensity)
        gl.Uniform(splatLoc.sourceOffset,4)
        gl.DepthMask(false); gl.DepthTest(false); gl.Culling(false); gl.Blending(GL.ONE,GL.ONE)
        gl.CallList(self.points)
        gl.UseShader(0); gl.Texture(0,false); gl.Texture(1,false); gl.Blending(false)
    end
    function self:Draw(bottom,top,domain,atlasSize,intensity)
        if not self.enabled then return end
        intensity=self.test and 1 or intensity
        if not self.automatic then self:DrawCapture(bottom,top,domain,atlasSize,intensity); return end
        if intensity<=0 then return end
        -- Reuse one capture pair for all houses. Capture/splat within the caller's
        -- atlas FBO; ActiveFBO restores that target and its viewport on return.
        -- The focused house goes last so its source remains in the debug texture.
        local function drawUnit(id)
            if not automaticUnit(id) then return end
            self.unitID=id; self.ready=false; self:Fit(id); self:Capture()
            self:DrawCapture(bottom,top,domain,atlasSize,intensity)
        end
        for _,id in ipairs(self.units) do
            if not self.enabled then break end
            if id~=self.focusID then drawUnit(id) end
        end
        if self.enabled and self.focusID then drawUnit(self.focusID) end
    end
    function self:DrawScreen(previewShader,exposureLoc,exposure)
        if not self.preview then return end
        local vsx,vsy=gl.GetViewSizes()
        local size=math.min(256,math.floor(vsy*0.28))
        local x,y=vsx-size-20,vsy-size-64
        if not self.enabled or not self.ready or not valid(self.unitID) then
            gl.Color(1,1,1,1)
            gl.Text(self.enabled and "Radiance taper: waiting for visible house_asian1/3" or "Radiance taper: OFF",x,y+size+19,14,"o")
            return
        end
        gl.Color(1,1,1,1); gl.Texture(self.emission); gl.Blending(false)
        if previewShader then gl.UseShader(previewShader);gl.Uniform(exposureLoc,exposure or 4) end
        gl.TexRect(x,y,x+size,y+size,0,0,1,1)
        gl.UseShader(0)
        gl.Texture(false); gl.Blending(GL.SRC_ALPHA,GL.ONE_MINUS_SRC_ALPHA)
        gl.Text("Tapered facade emission | unit "..self.unitID,x,y+size+19,14,"o")
        gl.Text(string.format("taper %.2f | span %.0f | falloff %.0f | strength %.2f",self.taper,self.span,self.falloff,self.strength),x,y+size+1,12,"o")
    end
    return self
end
