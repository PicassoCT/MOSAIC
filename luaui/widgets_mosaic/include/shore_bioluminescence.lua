-- Unsynced coastal atlas. GPU textures own the history; Lua owns only static
-- tile metadata and a simulation clock. No pixel readback or per-wave objects.
local M={tileSize=512,scanStep=32,halfLife=6,updateInterval=0.1}
local PATH='luaui/widgets_mosaic/shaders/shore_bioluminescence/'

function M.DryFactor(rain)
    local t=math.max(0,math.min(1,((rain or 0)-0.001)/0.029))
    return 1-t*t*(3-2*t)
end

function M.CollectTiles(sizeX,sizeZ,height)
    local tiles,seen={},{}
    local function addCoast(x,z)
        for tz=math.max(0,math.floor((z-96)/M.tileSize)),math.min(math.ceil(sizeZ/M.tileSize)-1,math.floor((z+M.scanStep+96)/M.tileSize)) do
            for tx=math.max(0,math.floor((x-96)/M.tileSize)),math.min(math.ceil(sizeX/M.tileSize)-1,math.floor((x+M.scanStep+96)/M.tileSize)) do
                local key=tx..':'..tz
                if not seen[key] then
                    local tile={x=tx*M.tileSize,z=tz*M.tileSize,cells={}}
                    seen[key]=tile;tiles[#tiles+1]=tile
                end
                local tile=seen[key]
                for cz=math.max(tile.z,z-96),math.min(tile.z+M.tileSize-M.scanStep,z+96),M.scanStep do
                    for cx=math.max(tile.x,x-96),math.min(tile.x+M.tileSize-M.scanStep,x+96),M.scanStep do
                        tile.cells[cx..':'..cz]={x=cx,z=cz}
                    end
                end
            end
        end
    end
    -- One startup scan, spread across frames. No terrain API calls afterward.
    local previous,calls={},0
    for z=0,sizeZ,M.scanStep do
        local row={}
        for x=0,sizeX,M.scanStep do
            local i=x/M.scanStep+1;local h=height(x,z);row[i]=h
            if i>1 and previous[i] then
                local lo=math.min(h,row[i-1],previous[i],previous[i-1])
                local hi=math.max(h,row[i-1],previous[i],previous[i-1])
                if lo<0 and hi>=0 then addCoast(x-M.scanStep,z-M.scanStep) end
            end
            calls=calls+1;if calls%1024==0 then coroutine.yield() end
        end
        previous=row
    end
    table.sort(tiles,function(a,b) return a.z==b.z and a.x<b.x or a.z<b.z end)
    return tiles
end

function M.Layout(tiles)
    local columns=math.ceil(math.sqrt(#tiles))
    if columns==0 then return nil,'no shoreline' end
    local pixels=128
    while columns*(pixels+2)>1088 and pixels>16 do pixels=pixels/2 end
    if columns*(pixels+2)>1088 then return nil,'coast exceeds atlas budget' end
    local pitch=pixels+2
    local width,height=columns*pitch,math.ceil(#tiles/columns)*pitch
    for i,tile in ipairs(tiles) do
        local col,row=(i-1)%columns,math.floor((i-1)/columns)
        tile.u0,tile.v0=(col*pitch+1)/width,(row*pitch+1)/height
        tile.u1,tile.v1=(col*pitch+1+pixels)/width,(row*pitch+1+pixels)/height
        tile.au0,tile.av0=col*pitch/width,row*pitch/height
        tile.au1,tile.av1=(col+1)*pitch/width,(row+1)*pitch/height
    end
    return {width=width,height=height,pixels=pixels,step=M.tileSize/pixels}
end

local function atlasQuad(tile,layout)
    local border=layout.step
    local function v(u,v,x,z)
        gl.MultiTexCoord(0,u,v);gl.MultiTexCoord(1,x,z);gl.Vertex(u*2-1,v*2-1,0)
    end
    v(tile.au0,tile.av0,tile.x-border,tile.z-border)
    v(tile.au1,tile.av0,tile.x+M.tileSize+border,tile.z-border)
    v(tile.au1,tile.av1,tile.x+M.tileSize+border,tile.z+M.tileSize+border)
    v(tile.au0,tile.av1,tile.x-border,tile.z+M.tileSize+border)
end

function M.New(tiles,sandTexture)
    local layout,reason=M.Layout(tiles)
    if not layout then return nil,reason end
    local self={tiles=tiles,layout=layout,shaders={},textures={},lists={},built=0,
        ready=false,intensity=0,historyTime=nil,time=0,sandTexture=sandTexture}
    function self:Shutdown()
        self.ready=false
        for _,id in ipairs(self.textures) do gl.DeleteTexture(id) end
        for _,id in ipairs(self.shaders) do gl.DeleteShader(id) end
        for _,id in ipairs(self.lists) do gl.DeleteList(id) end
        self.textures,self.shaders,self.lists={},{},{}
    end
    local function fail(message) self:Shutdown();return nil,message end
    local common=VFS.LoadFile(PATH..'common.glsl')
    local atlasVertex=VFS.LoadFile(PATH..'atlas.vert')
    local surfaceVertex=VFS.LoadFile(PATH..'surface.vert')
    if not common or not atlasVertex or not surfaceVertex then return fail('missing shaders') end
    local function shader(name,vertex,uniforms)
        local source=VFS.LoadFile(PATH..name..'.frag')
        if not source then return nil end
        source=source:gsub('// SHORE_COMMON',function() return common end)
        local id=gl.CreateShader({vertex=vertex,fragment=source,uniformInt=uniforms})
        if id then self.shaders[#self.shaders+1]=id end
        return id
    end
    self.maskShader=shader('mask',atlasVertex,{heightTex=0,sandTex=1})
    self.historyShader=shader('history',atlasVertex,{previousTex=0,maskTex=1})
    self.surfaceShader=shader('surface',surfaceVertex,{historyTex=0,maskTex=1,heightTex=2})
    if not self.maskShader or not self.historyShader or not self.surfaceShader then
        return fail(gl.GetShaderLog() or 'shader compilation failed')
    end
    self.loc={}
    for _,id in ipairs(self.shaders) do
        local locations={};self.loc[id]=locations
        for _,name in ipairs({'mapSize','shoreTime','halfLife','intensity','previousTime',
            'historyTime','lineWidth','gain','capture','heightRange'}) do
            locations[name]=gl.GetUniformLocation(id,name)
        end
    end
    local function texture(format)
        local id=gl.CreateTexture(layout.width,layout.height,{format=format,
            min_filter=GL.LINEAR,mag_filter=GL.LINEAR,wrap_s=GL.CLAMP_TO_EDGE,wrap_t=GL.CLAMP_TO_EDGE,fbo=true})
        if id then self.textures[#self.textures+1]=id end
        return id
    end
    self.mask=texture(GL.RGBA16F or 0x881A)
    self.previous=texture(GL.R16F or 0x822D);self.next=texture(GL.R16F or 0x822D)
    if not self.mask or not self.previous or not self.next then return fail('atlas allocation failed') end
    local function list(fn)
        local id=gl.CreateList(fn)
        if id then self.lists[#self.lists+1]=id end
        return id
    end
    self.atlasList=list(function()
        gl.BeginEnd(GL.QUADS,function() for _,tile in ipairs(tiles) do atlasQuad(tile,layout) end end)
    end)
    for _,tile in ipairs(tiles) do
        tile.drawList=list(function()
            -- Fixed meshes, shader-sampled live heights, hardware depth testing.
            -- Separate strips reproduce the terrain's triangle grid at 16 units.
            local step=16
            local function v(x,z)
                gl.TexCoord(tile.u0+(x-tile.x)/M.tileSize*(tile.u1-tile.u0),
                    tile.v0+(z-tile.z)/M.tileSize*(tile.v1-tile.v0))
                gl.Vertex(x,0,z)
            end
            gl.BeginEnd(GL.TRIANGLES,function()
                for _,cell in pairs(tile.cells) do
                    for z=cell.z,cell.z+M.scanStep-step,step do
                        for x=cell.x,cell.x+M.scanStep-step,step do
                            v(x,z);v(x,z+step);v(x+step,z)
                            v(x+step,z);v(x,z+step);v(x+step,z+step)
                        end
                    end
                end
            end)
        end)
        if not tile.drawList then return fail('shore mesh allocation failed') end
    end
    if not self.atlasList then return fail('atlas list allocation failed') end
    local function clear() gl.Clear(GL.COLOR_BUFFER_BIT,0,0,0,0) end
    function self:ClearHistory(time)
        gl.Texture(0,false);gl.Texture(1,false);gl.Texture(2,false)
        gl.RenderToTexture(self.previous,clear);gl.RenderToTexture(self.next,clear)
        self.historyTime=time
    end
    gl.Texture(0,false);gl.Texture(1,false);gl.Texture(2,false)
    gl.RenderToTexture(self.mask,clear);self:ClearHistory(0)

    local function clean()
        gl.UseShader(0)
        for i=0,2 do gl.Texture(i,false) end
        gl.Color(1,1,1,1);gl.Blending(GL.SRC_ALPHA,GL.ONE_MINUS_SRC_ALPHA)
        gl.DepthMask(false);gl.DepthTest(false);gl.PolygonOffset(false)
    end
    function self:Step(time,intensity)
        self.time,self.intensity=time,intensity
        gl.DepthTest(false);gl.DepthMask(false);gl.Culling(false);gl.Blending(false)
        if not self.ready then
            -- One tile per draw keeps initial mask work bounded. Never readback.
            local tile=self.tiles[self.built+1]
            gl.Texture(0,'$heightmap');gl.Texture(1,self.sandTexture)
            gl.UseShader(self.maskShader)
            gl.Uniform(self.loc[self.maskShader].mapSize,Game.mapSizeX,Game.mapSizeZ)
            gl.RenderToTexture(self.mask,function() gl.BeginEnd(GL.QUADS,atlasQuad,tile,layout) end)
            self.built=self.built+1;self.ready=self.built==#self.tiles
            clean();self.historyTime=time
            return
        end
        if time<self.historyTime or (intensity<=0 and not self.dormant) then
            self:ClearHistory(time)
        end
        self.dormant=intensity<=0
        if self.dormant then self.historyTime=time;clean();return end
        if time-self.historyTime<M.updateInterval then clean();return end
        gl.Texture(0,self.previous);gl.Texture(1,self.mask)
        gl.UseShader(self.historyShader);local l=self.loc[self.historyShader]
        gl.Uniform(l.shoreTime,time);gl.Uniform(l.previousTime,self.historyTime)
        gl.Uniform(l.halfLife,M.halfLife);gl.Uniform(l.intensity,intensity)
        gl.Uniform(l.lineWidth,math.max(3.0,layout.step*1.2))
        gl.RenderToTexture(self.next,function() gl.CallList(self.atlasList) end)
        self.previous,self.next=self.next,self.previous;self.historyTime=time
        clean()
    end
    function self:Draw(capture,bottom,top,domain)
        if not self.ready or self.intensity<=0 or (capture and (bottom>=12 or top<=0)) then return end
        gl.Texture(0,self.previous);gl.Texture(1,self.mask);gl.Texture(2,'$heightmap')
        gl.UseShader(self.surfaceShader);local l=self.loc[self.surfaceShader]
        gl.Uniform(l.mapSize,Game.mapSizeX,Game.mapSizeZ)
        gl.Uniform(l.shoreTime,self.time);gl.Uniform(l.historyTime,self.historyTime)
        gl.Uniform(l.halfLife,M.halfLife);gl.Uniform(l.intensity,self.intensity)
        gl.Uniform(l.lineWidth,math.max(3.0,layout.step*1.2))
        gl.Uniform(l.gain,capture and 0.28 or 1.5)
        gl.UniformInt(l.capture,capture and 1 or 0)
        gl.Uniform(l.heightRange,bottom or 0,top or 128)
        if capture then gl.DepthTest(false) else gl.DepthTest(GL.LEQUAL) end
        gl.DepthMask(false)
        gl.Culling(false);gl.Blending(GL.ONE,GL.ONE);gl.PolygonOffset(-1,-1)
        for _,tile in ipairs(self.tiles) do
            local inDomain=not domain or (tile.x<domain.x+domain.span and tile.x+M.tileSize>domain.x
                and tile.z<domain.z+domain.span and tile.z+M.tileSize>domain.z)
            local visible=capture or not Spring.IsAABBInView or Spring.IsAABBInView(tile.x,-24,tile.z,
                tile.x+M.tileSize,16,tile.z+M.tileSize)
            if inDomain and visible then
                if capture then
                    -- Projection is top-down; four vertices suffice. The
                    -- fragment shader still clips using per-texel ground height.
                    gl.BeginEnd(GL.QUADS,function()
                        gl.TexCoord(tile.u0,tile.v0);gl.Vertex(tile.x,0,tile.z)
                        gl.TexCoord(tile.u1,tile.v0);gl.Vertex(tile.x+M.tileSize,0,tile.z)
                        gl.TexCoord(tile.u1,tile.v1);gl.Vertex(tile.x+M.tileSize,0,tile.z+M.tileSize)
                        gl.TexCoord(tile.u0,tile.v1);gl.Vertex(tile.x,0,tile.z+M.tileSize)
                    end)
                else gl.CallList(tile.drawList) end
            end
        end
        clean()
    end
    return self
end
return M
