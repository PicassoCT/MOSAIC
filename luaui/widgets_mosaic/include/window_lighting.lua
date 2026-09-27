-- Direct terrain illumination from untapered facade captures. Never a cascade input.
local PATH='luaui/widgets_mosaic/shaders/windowlight/'
local SIZE,FIELD,ATLAS,GROUND,BLOCK_TILE,LIMIT=64,256,1024,256,512,32
local BAKE_CHUNKS=16
local SUPPORTED={house_asian1=true,house_asian3=true}
local DIRECTIONS={{1,0},{-1,0},{0,1},{0,-1}}
local Exterior=VFS.Include('luaui/widgets_mosaic/include/window_exterior.lua')
local Bounds=VFS.Include('luaui/widgets_mosaic/include/window_bounds.lua')
local unpack=unpack or table.unpack
local function identity(fn)
    gl.MatrixMode(GL.PROJECTION);gl.PushMatrix();gl.LoadIdentity()
    gl.MatrixMode(GL.MODELVIEW);gl.PushMatrix();gl.LoadIdentity()
    local ok,reason=pcall(fn)
    gl.PopMatrix();gl.MatrixMode(GL.PROJECTION);gl.PopMatrix();gl.MatrixMode(GL.MODELVIEW)
    if not ok then error(reason) end
end
local function quad(x0,y0,x1,y1) gl.TexRect(x0 or -1,y0 or -1,x1 or 1,y1 or 1,0,0,1,1) end
local function clean()
    gl.UseShader(0);for i=0,5 do gl.Texture(i,false) end
    gl.DepthMask(false);gl.DepthTest(false);gl.Blending(false);gl.Culling(false)
    gl.Color(1,1,1,1)
end
local function valid(id)
    if not id or not Spring.ValidUnitID(id) or Spring.GetUnitIsDead(id) then return end
    local def=Spring.GetUnitDefID(id)
    if not def or not UnitDefs or not UnitDefs[def] or not SUPPORTED[UnitDefs[def].name] then return end
    if Spring.GetUnitIsCloaked and Spring.GetUnitIsCloaked(id) then return end
    if Spring.GetUnitLosState then
        local spectator,full=Spring.GetSpectatingState()
        local los=Spring.GetUnitLosState(id)
        if not (spectator and full) and (not los or not los.los) then return end
    end
    return def
end
local function revision(id)
    return Spring.GetUnitRulesParam and Spring.GetUnitRulesParam(id,'mosaic_window_revision')
end
return function()
    local self={enabled=true,test=true,automatic=true,preview=false,strength=1,range=640,
        cutoff=0.002,clock=0,records={},units={},generation=1,ready=false}
    local ownedTex,ownedFBO,ownedLists,programs,loc={},{},{},{},{}
    local function echo(s) Spring.Echo('Window light: '..s) end
    local function tex(w,h,format,linear)
        local t=gl.CreateTexture(w,h,{format=format,min_filter=linear and GL.LINEAR or GL.NEAREST,
            mag_filter=linear and GL.LINEAR or GL.NEAREST,wrap_s=GL.CLAMP_TO_EDGE,wrap_t=GL.CLAMP_TO_EDGE,
            fbo=format~=(GL.DEPTH_COMPONENT24 or 0x81A6)})
        assert(t,'texture allocation failed');ownedTex[t]=true;return t
    end
    local function dropTex(t) if t then gl.DeleteTexture(t);ownedTex[t]=nil end end
    local function fbo(desc)
        local f=gl.CreateFBO(desc);assert(f,'framebuffer allocation failed');ownedFBO[f]=true
        assert(gl.IsValidFBO(f),'incomplete framebuffer');return f
    end
    local function dropFBO(f) if f then gl.DeleteFBO(f);ownedFBO[f]=nil end end
    local function program(name,vs,fs,gs,samplers)
        local function read(file)
            local s=assert(VFS.LoadFile(PATH..file),'missing '..file)
            if s:find('// WINDOW_CLASSIFY',1,true) then
                local common=assert(VFS.LoadFile(PATH..'classify.glsl'))
                s=s:gsub('// WINDOW_CLASSIFY',function() return common end)
            end
            return s
        end
        local p=gl.CreateShader({vertex=vs and read(vs),fragment=read(fs),geometry=gs and read(gs),uniformInt=samplers})
        assert(p,name..' shader: '..(gl.GetShaderLog() or 'failed'));programs[name]=p;loc[name]={}
    end
    local function uniform(name,key,...)
        local l=loc[name][key]
        if l==nil then l=gl.GetUniformLocation(programs[name],key);loc[name][key]=l end
        gl.Uniform(l,...)
    end
    local function integer(name,key,value)
        local l=loc[name][key]
        if l==nil then l=gl.GetUniformLocation(programs[name],key);loc[name][key]=l end
        gl.UniformInt(l,value)
    end
    local function list(fn)
        local l=gl.CreateList(fn);assert(l,'display list allocation failed');ownedLists[l]=true;return l
    end
    function self:Drop(id)
        local r=self.records[id];if not r then return end
        for _,key in ipairs({'emission','position','wall','exterior','field'}) do dropTex(r[key]) end
        self.records[id]=nil;self.generation=self.generation+1;self.ready=false
    end
    function self:Shutdown()
        for f in pairs(ownedFBO) do gl.DeleteFBO(f) end
        for t in pairs(ownedTex) do gl.DeleteTexture(t) end
        for l in pairs(ownedLists) do gl.DeleteList(l) end
        for _,p in pairs(programs) do gl.DeleteShader(p) end
        ownedTex,ownedFBO,ownedLists,programs,loc={},{},{},{},{}
        self.records={};self.allocated=false;self.ready=false
        self.texture=nil;self.ground=nil;self.blockers=nil;self.packedGeneration=nil
    end
    local function dataPass(w,h,value)
        gl.UseShader(programs.data);gl.Blending(false);gl.DepthTest(false);gl.DepthMask(false)
        gl.BeginEnd(GL.POINTS,function()
            for y=0,h-1 do for x=0,w-1 do
                local a,b,c,d=value(x,y)
                gl.Color(1,b or 0,c or 0,d or 0)
                gl.Vertex(2*(x+0.5)/w-1,2*(y+0.5)/h-1,a or 0)
            end end
        end)
        gl.UseShader(0);gl.Color(1,1,1,1)
    end
    -- Older Recoil ReadPixels chunks row-major memory into [width][height].
    -- Probe the actual return layout once; don't transpose/rotate courtyard masks.
    local readChunked
    local function readPixels(w,h)
        local p=gl.ReadPixels(0,0,w,h,GL.RGBA);assert(type(p)=='table','pixel readback unavailable')
        local out={}
        for y=0,h-1 do for x=0,w-1 do
            if readChunked then
                local i=y*w+x;out[i+1]=p[math.floor(i/h)+1][i%h+1]
            else out[y*w+x+1]=p[x+1][y+1] end
        end end
        return out
    end
    function self:Allocate()
        if self.allocated then return end
        for _,name in ipairs({'CreateFBO','ActiveFBO','IsValidFBO','ReadPixels','Unit','Viewport','CreateList'}) do
            assert(gl[name],'missing gl.'..name)
        end
        program('capture','capture.vert','capture.frag',nil,{sourceTex=0,materialTex=1})
        program('walls','walls.vert','walls.frag','walls.geom',{})
        program('project','project.vert','project.frag','project.geom',
            {emissionTex=0,positionTex=1,exteriorTex=2,groundTex=3,blockerTex=4,wallTex=5})
        program('data','data.vert','data.frag',nil,{})
        program('copy',nil,'copy.frag',nil,{sourceTex=0})
        program('debug','debug.vert','debug.frag',nil,{materialTex=0,exteriorTex=1})
        self.texture=tex(ATLAS,ATLAS,GL.RGBA16F or 0x881A,true)
        self.ground=tex(GROUND,GROUND,GL.R32F or 0x822E,true)
        self.blockers=tex(BLOCK_TILE*4,BLOCK_TILE*4,GL.R8 or 0x8229,false)
        self.points={}
        for chunk=1,BAKE_CHUNKS do
            self.points[chunk]=list(function()
                gl.BeginEnd(GL.POINTS,function()
                    for y=(chunk-1)*SIZE/BAKE_CHUNKS,chunk*SIZE/BAKE_CHUNKS-1 do
                        for x=0,SIZE*4-1 do gl.Vertex((x+0.5)/(SIZE*4),(y+0.5)/SIZE,0) end
                    end
                end)
            end)
        end
        local probe=tex(2,2,GL.RGBA32F or 0x8814,false)
        gl.RenderToTexture(probe,function()
            dataPass(2,2,function(x,y)return x,y,0,1 end)
            local p=gl.ReadPixels(0,0,2,2,GL.RGBA)
            assert(type(p)=='table' and p[1] and p[1][2],'pixel readback unavailable')
            readChunked=p[1][2][1]>0.5
        end)
        dropTex(probe);self.allocated=true;self.terrainDirty=true
    end
    function self:TerrainChanged() self.terrainDirty=true;self.generation=self.generation+1;self.ready=false end
    function self:Invalidate(id)
        if id then self:Drop(id) else
            local ids={};for unit in pairs(self.records) do ids[#ids+1]=unit end
            for _,unit in ipairs(ids) do self:Drop(unit) end
        end
    end
    function self:Update(dt) self.clock=self.clock+dt end
    local function params(name,r)
        uniform(name,'maskOrigin',r.x-r.span/2,r.z-r.span/2)
        uniform(name,'maskSpan',r.span);uniform(name,'buildingY',r.y,r.y+r.height)
    end
    local function sideCapture(r,def)
        assert(gl.Texture(0,'%'..def..':0') and gl.Texture(1,'%'..def..':1'),'missing model textures')
        local depth=tex(SIZE*4,SIZE,GL.DEPTH_COMPONENT24 or 0x81A6,false)
        local target=fbo({color0=r.emission,color1=r.position,depth=depth,
            drawbuffers={GL.COLOR_ATTACHMENT0_EXT or 0x8CE0,GL.COLOR_ATTACHMENT1_EXT or 0x8CE1}})
        gl.ActiveFBO(target,function()
            gl.DepthMask(true);gl.DepthTest(GL.LESS);gl.Blending(false);gl.Culling(false)
            gl.Clear(GL.COLOR_BUFFER_BIT,0,0,0,0);gl.Clear(GL.DEPTH_BUFFER_BIT,1)
            gl.UseShader(programs.capture)
            uniform('capture','captureOrigin',r.x,r.y,r.z);uniform('capture','captureSize',r.span,r.height)
            identity(function()
                for i,d in ipairs(DIRECTIONS) do
                    gl.Viewport((i-1)*SIZE,0,SIZE,SIZE)
                    uniform('capture','captureDirection',d[1],d[2]);gl.Unit(r.id,true,-1,true)
                end
            end)
        end)
        clean();dropFBO(target);dropTex(depth)
    end
    function self:Capture(id)
        local def=assert(valid(id));local r,reason=Bounds.Read(id)
        r=r or {failed=reason}
        r.id=id;r.revision=revision(id);r.built=self.clock
        self.records[id]=r -- register immediately so a failure can free partial resources
        if r.failed then echo('unit '..id..': '..r.failed);return end
        r.emission=tex(SIZE*4,SIZE,GL.RGBA32F or 0x8814,false)
        r.position=tex(SIZE*4,SIZE,GL.RGBA32F or 0x8814,false)
        sideCapture(r,def)
        local samples
        local readFBO=fbo({color0=r.emission})
        gl.ActiveFBO(readFBO,function() samples=readPixels(SIZE*4,SIZE) end);dropFBO(readFBO)
        r.litPixels=0
        for _,p in ipairs(samples) do
            if p[4]>0 and math.max(p[1],p[2],p[3])>0 then r.litPixels=r.litPixels+1 end
        end
        if r.litPixels==0 then echo('unit '..id..': no luminous facade pixels captured; /windowlight debug on') end
        r.wall=tex(SIZE,SIZE,GL.RGBA8 or 0x8058,false)
        r.exterior=tex(SIZE,SIZE,GL.RGBA8 or 0x8058,false)
        r.field=tex(FIELD,FIELD,GL.RGBA16F or 0x881A,true)
        local walls
        gl.RenderToTexture(r.wall,function()
            clean();gl.Clear(GL.COLOR_BUFFER_BIT,0,0,0,0);gl.UseShader(programs.walls)
            params('walls',r);uniform('walls','maskResolution',SIZE);gl.Blending(GL.ONE,GL.ONE)
            identity(function()
                for band=1,4 do
                    uniform('walls','heightRange',r.y+r.height*(band-1)/4,r.y+r.height*band/4)
                    uniform('walls','bandColor',band==1 and 1 or 0,band==2 and 1 or 0,band==3 and 1 or 0,band==4 and 1 or 0)
                    gl.Unit(id,true,-1,true)
                end
            end)
            walls=readPixels(SIZE,SIZE)
        end)
        local exterior=Exterior.Fill(walls,SIZE)
        gl.RenderToTexture(r.exterior,function()dataPass(SIZE,SIZE,function(px,py)return unpack(exterior[py*SIZE+px+1]) end)end)
        r.fieldSpan=r.span+self.range*2;r.fieldX=r.x-r.fieldSpan/2;r.fieldZ=r.z-r.fieldSpan/2
        r.captured=true;self.generation=self.generation+1;clean()
    end
    local function copy(source,x0,y0,x1,y1,channel,gain,cutoff)
        gl.Texture(0,source);gl.UseShader(programs.copy)
        integer('copy','channel',channel or -1);uniform('copy','gain',gain or 1)
        uniform('copy','minimumLight',cutoff or 0)
        quad(x0,y0,x1,y1);gl.Texture(0,false)
    end
    function self:PackBlockers(occupancy)
        gl.RenderToTexture(self.blockers,function()
            clean();gl.Clear(GL.COLOR_BUFFER_BIT,0,0,0,0)
            identity(function()
                for band=0,15 do
                    gl.Viewport(band%4*BLOCK_TILE,math.floor(band/4)*BLOCK_TILE,BLOCK_TILE,BLOCK_TILE)
                    gl.Blending(false);copy(occupancy[band+1],-1,-1,1,1,0)
                    gl.Blending(GL.ONE,GL.ONE)
                    for _,r in pairs(self.records) do if r.captured then
                        local y=(band+0.5)*128
                        if y>=r.y and y<r.y+r.height then
                            local channel=math.min(3,math.floor((y-r.y)/r.height*4))
                            copy(r.wall,2*(r.x-r.span/2)/Game.mapSizeX-1,2*(r.z-r.span/2)/Game.mapSizeZ-1,
                                2*(r.x+r.span/2)/Game.mapSizeX-1,2*(r.z+r.span/2)/Game.mapSizeZ-1,channel)
                        end
                    end end
                end
            end)
        end)
        self.packedGeneration=self.generation;clean()
    end
    function self:Bake(r)
        if r.bakeGeneration~=self.generation then r.bakeGeneration=self.generation;r.bakeStep=0 end
        gl.RenderToTexture(r.field,function()
            clean();if r.bakeStep==0 then gl.Clear(GL.COLOR_BUFFER_BIT,0,0,0,0) end
            gl.Texture(0,r.emission);gl.Texture(1,r.position);gl.Texture(2,r.exterior)
            gl.Texture(3,self.ground);gl.Texture(4,self.blockers);gl.Texture(5,r.wall)
            gl.UseShader(programs.project);params('project',r)
            uniform('project','fieldOrigin',r.fieldX,r.fieldZ);uniform('project','fieldSpan',r.fieldSpan)
            uniform('project','fieldResolution',FIELD);uniform('project','maxRange',self.range)
            -- Bound discarded per-sample energy well below the final HOUSE cutoff,
            -- even at maximum gain. Many faint windows must still add together.
            uniform('project','cutoff',self.cutoff/(SIZE*SIZE*4*8))
            uniform('project','mapSize',Game.mapSizeX,Game.mapSizeZ)
            gl.Blending(GL.ONE,GL.ONE);gl.CallList(self.points[r.bakeStep+1])
        end)
        clean();r.bakeStep=r.bakeStep+1
        if r.bakeStep==BAKE_CHUNKS then r.fieldGeneration=self.generation end
    end
    function self:Step()
        if not self.enabled or not self.allocated or self.packedGeneration~=self.generation
            or (self.intensity or 0)<=0 then return end
        local ok,reason=pcall(function()
            for _,id in ipairs(self.units) do local r=self.records[id]
                if r and r.captured and r.fieldGeneration~=self.generation and valid(id) and r.revision==revision(id) then
                    self:Bake(r);break
                end
            end
        end)
        if not ok then clean();self:Shutdown();self.enabled=false;echo('bake disabled: '..tostring(reason)) end
    end
    function self:Refresh(occupancy,occlusionChanged,intensity)
        self.ready=false;self.intensity=self.test and 1 or intensity
        -- Remember blocker changes even while disabled or in daylight. Re-enabling
        -- must never reuse a field baked against the old occupancy.
        if occlusionChanged then self.generation=self.generation+1 end
        if not self.enabled then return end
        local ok,reason=pcall(function()
            local candidates={}
            local cx,cy,cz=0,0,0
            if Spring.GetCameraPosition then cx,cy,cz=Spring.GetCameraPosition() end
            for _,id in ipairs(self.automatic and (Spring.GetAllUnits and Spring.GetAllUnits() or {}) or {self.unitID}) do
                if valid(id) then
                    local rev=revision(id)
                    if rev==nil or rev>0 then
                        local x,y,z=Spring.GetUnitPosition(id)
                        local r=self.records[id]
                        -- Keep the conservative radius after capture. Shrinking
                        -- it to the measured span makes edge-of-view houses
                        -- alternate between capture and eviction every refresh.
                        local radius=math.max(1600,r and r.span or 0)+self.range
                        local visible=not Spring.IsSphereInView or Spring.IsSphereInView(x,y,z,radius)
                        if visible then candidates[#candidates+1]={id=id,distance=(x-cx)^2+(y-cy)^2+(z-cz)^2} end
                    end
                end
            end
            local selected=(Spring.GetSelectedUnits() or {})[1]
            table.sort(candidates,function(a,b)
                if a.id==selected or b.id==selected then return a.id==selected and b.id~=selected end
                return a.distance<b.distance
            end)
            local keep={};self.units={}
            for i=1,math.min(LIMIT,#candidates) do local id=candidates[i].id;keep[id]=true;self.units[#self.units+1]=id end
            local drop={}
            for id,r in pairs(self.records) do
                if not keep[id] or r.revision~=revision(id) then drop[#drop+1]=id end
            end
            for _,id in ipairs(drop) do self:Drop(id) end
            if keep[selected] then self.focusID=selected elseif not keep[self.focusID] then self.focusID=self.units[1] end
            if #self.units==0 or self.intensity<=0 or self.strength<=0 then return end
            self:Allocate()
            if self.terrainDirty then
                gl.RenderToTexture(self.ground,function()dataPass(GROUND,GROUND,function(x,y)
                    return Spring.GetGroundHeight((x+0.5)*Game.mapSizeX/GROUND,(y+0.5)*Game.mapSizeZ/GROUND),0,0,1
                end)end)
                self.terrainDirty=false;self.generation=self.generation+1
            end
            -- Amortise new model captures: one house per cascade refresh, no per-frame readback.
            for _,id in ipairs(self.units) do if not self.records[id] then self:Capture(id);break end end
            if self.packedGeneration~=self.generation then self:PackBlockers(occupancy) end
            self:Step();if not self.enabled then return end
            gl.RenderToTexture(self.texture,function()
                clean();gl.Clear(GL.COLOR_BUFFER_BIT,0,0,0,0);gl.Blending(GL.ONE,GL.ONE)
                identity(function()
                    for _,id in ipairs(self.units) do local r=self.records[id]
                        if r and r.fieldGeneration==self.generation then
                            copy(r.field,2*r.fieldX/Game.mapSizeX-1,2*r.fieldZ/Game.mapSizeZ-1,
                                2*(r.fieldX+r.fieldSpan)/Game.mapSizeX-1,2*(r.fieldZ+r.fieldSpan)/Game.mapSizeZ-1,
                                -1,self.strength*self.intensity,self.cutoff)
                            self.ready=true
                        end
                    end
                end)
            end)
            clean()
            if self.report then self:Report();self.report=false end
        end)
        if not ok then
            clean();self:Shutdown();self.enabled=false;echo('disabled: '..tostring(reason))
        end
    end
    function self:GetDebugPosition(id)
        if not self.enabled then return end
        id=id or self.focusID or self.unitID
        if not valid(id) or (not self.automatic and id~=self.unitID) then return end
        local x,y,z=Spring.GetUnitPosition(id);return x,y,z,id
    end
    function self:Focus(id)
        local x,y,z,unit=self:GetDebugPosition(id)
        if x then self.focusID=unit;return x,y,z,unit end
    end
    function self:Report()
        local r=self.records[self.focusID]
        if not r then echo('no cached house; select a completed visible house_asian1/3');return end
        if r.failed then echo('unit '..r.id..': '..r.failed);return end
        local peak=0
        if r.fieldGeneration==self.generation then
            gl.RenderToTexture(r.field,function()
                for _,p in ipairs(readPixels(FIELD,FIELD)) do peak=math.max(peak,p[1],p[2],p[3]) end
            end)
        end
        echo(string.format('unit %d | %d lit pixels | span %.0f height %.0f | bake %d/%d | field peak %.6g | atlas %s',
            r.id,r.litPixels or 0,r.span,r.height,r.bakeStep or 0,BAKE_CHUNKS,peak,self.ready and 'ready' or 'waiting'))
    end
    function self:TextCommand(command)
        if command~='windowlight' and not command:match('^windowlight%s') then return false end
        if command=='windowlight off' then self.enabled=false;self.ready=false;echo('OFF');return true end
        if command=='windowlight auto' then self.enabled=true;self.automatic=true;echo('automatic house_asian1/3 ON');return true end
        if command=='windowlight debug on' or command=='windowlight debug off' then self.preview=command=='windowlight debug on';return true end
        if command=='windowlight test on' or command=='windowlight test off' then self.test=command=='windowlight test on';return true end
        if command=='windowlight rebuild' then self:Invalidate();return true end
        if command=='windowlight status' then self.report=true;return true end
        local id=command:match('^windowlight on (%d+)$')
        if command=='windowlight on' or id then
            id=tonumber(id) or (Spring.GetSelectedUnits() or {})[1]
            if not valid(id) then echo('select a visible house_asian1/3');return true end
            self.enabled=true;self.automatic=false;self.unitID=id;self.focusID=id;return true
        end
        local key,value=command:match('^windowlight (%a+) ([%d%.]+)$');value=tonumber(value)
        local limits={strength={0,8},range={64,1024},cutoff={0.00005,0.05}}
        if limits[key] and value then
            self[key]=math.max(limits[key][1],math.min(limits[key][2],value))
            if key~='strength' then self:Invalidate() end
            echo(key..' = '..self[key]);return true
        end
        echo('auto | on [UNITID] | off | debug on/off | status | test on/off | strength 1 | range 640 | cutoff 0.002 | rebuild')
        return true
    end
    function self:DrawWorld()
        if not self.enabled or not self.preview then return end
        local r=self.records[self.focusID]
        if not r or not r.captured or not valid(r.id) then return end
        gl.Texture(0,'%'..Spring.GetUnitDefID(r.id)..':1');gl.Texture(1,r.exterior)
        gl.UseShader(programs.debug);params('debug',r)
        gl.UniformMatrix(gl.GetUniformLocation(programs.debug,'inverseView'),'viewinverse')
        gl.DepthTest(GL.LEQUAL);gl.DepthMask(false);gl.Culling(false)
        gl.Blending(GL.SRC_ALPHA,GL.ONE_MINUS_SRC_ALPHA);gl.PolygonOffset(-1,-1)
        gl.Unit(r.id,true,-1,true)
        gl.PolygonOffset(false);clean()
        gl.DepthMask(true);gl.DepthTest(true);gl.Blending(GL.SRC_ALPHA,GL.ONE_MINUS_SRC_ALPHA)
    end
    function self:DrawScreen(previewShader,exposureLoc,exposure)
        if not self.preview then return end
        local sx,sy=gl.GetViewSizes();local size=math.min(256,math.floor(sy*0.28))
        local x,y=sx-size-20,sy-size-64
        gl.Color(1,1,1,1)
        gl.Text('Window light | green: exterior | red: courtyard',x-75,y+size+20,13,'o')
        local r=self.records[self.focusID]
        if r then
            gl.Text(r.failed or string.format('Unit %d | %d lit pixels | span %.0f | height %.0f',
                r.id,r.litPixels or 0,r.span,r.height),x-75,y-38,12,'o')
        end
        if not self.enabled or not r or r.fieldGeneration~=self.generation then
            local cached,baked=0,0
            for _,record in pairs(self.records) do
                if record.captured then cached=cached+1 end
                if record.fieldGeneration==self.generation then baked=baked+1 end
            end
            gl.Text(self.enabled and string.format('Cache %d/%d | baked %d | selected %d/%d',cached,#self.units,baked,r and r.bakeStep or 0,BAKE_CHUNKS)
                or 'Window light OFF',x-75,y+size,12,'o');return
        end
        gl.Texture(r.field);gl.Blending(false)
        if previewShader then gl.UseShader(previewShader);gl.Uniform(exposureLoc,exposure or 4) end
        quad(x,y,x+size,y+size);gl.UseShader(0);gl.Texture(false)
        gl.Blending(GL.SRC_ALPHA,GL.ONE_MINUS_SRC_ALPHA)
        gl.Text('Direct ground light | unit '..r.id,x,y-18,13,'o')
    end
    return self
end
