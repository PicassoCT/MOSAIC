-- Unsynced FlamePainter-style railgun residue. Stored path spans are owned by
-- railgun_wakes.lua; this renderer never extends their lifetime or trajectory.
-- All visible spans share one compatibility-profile draw and two shaders.
return function()
    if not gl.CreateShader or not gl.MultiTexCoord then
        return nil, 'railgun wake GLSL/multitexture attributes unavailable'
    end
    local path='luaui/widgets_mosaic/shaders/railgun_wake/'
    local shader=gl.CreateShader({vertex=VFS.LoadFile(path..'wake.vert'),
        fragment=VFS.LoadFile(path..'wake.frag')})
    if not shader then return nil,gl.GetShaderLog() end
    local loc={}
    for _,name in ipairs({'cameraPosition','driftDirection','ambient'}) do
        loc[name]=gl.GetUniformLocation(shader,name)
    end
    local self={maxSpans=256,maxCells=384,maxDistance=14000,stats={}}
    local fps=Game.gameSpeed or 30
    local function clamp(x,lo,hi) return math.max(lo,math.min(hi,x)) end
    local function emit(d,t,side,frame)
        local r=d.r
        local born=r.bornA+(r.bornB-r.bornA)*t
        gl.MultiTexCoord(0,side,(r.distance or 0)+d.length*t,(frame-born)/fps,(r.expires-frame)/fps)
        gl.MultiTexCoord(2,r.seed or 0,d.opacity,r.fadeA or 1,r.fadeB or 1)
        -- w is the local span coordinate, not a homogeneous world position.
        -- Fragment-side endpoint envelopes keep a one-quad short shot visible
        -- even when BOTH of its true endpoint opacities are zero.
        gl.Vertex(r.ax+d.dx*t,r.ay+d.dy*t,r.az+d.dz*t,t)
    end
    local function draw(spans,frame)
        for _,d in ipairs(spans) do
            gl.MultiTexCoord(1,d.dx/d.length,d.dy/d.length,d.dz/d.length,d.width)
            for cell=0,d.cells-1 do
                local a,b=cell/d.cells,(cell+1)/d.cells
                emit(d,a,-1,frame);emit(d,a,1,frame)
                emit(d,b,1,frame);emit(d,b,-1,frame)
            end
        end
    end
    function self:Draw(spans,frame)
        local stats={submittedSpans=#spans,drawnSpans=0,drawnShots=0,cells=0,
            vertices=0,drawCalls=0,droppedShots=0}
        self.stats=stats
        if not shader or #spans==0 then return end
        frame=frame or Spring.GetGameFrame()+(Spring.GetFrameTimeOffset() or 0)
        local cx,cy,cz=Spring.GetCameraPosition()
        local groups,lookup={},{}
        local cutoff=self.maxDistance
        for _,r in ipairs(spans) do
            if frame<r.expires and frame>=r.bornA and (r.opacity or 1)>0 then
                local dx,dy,dz=r.bx-r.ax,r.by-r.ay,r.bz-r.az
                local length=math.sqrt(dx*dx+dy*dy+dz*dz)
                local x,y,z=r.ax+dx*.5,r.ay+dy*.5,r.az+dz*.5
                local d2=(cx-x)^2+(cy-y)^2+(cz-z)^2
                local width=clamp(r.width or 3.5,.2,12)
                if length>.001 and d2<cutoff*cutoff and
                    Spring.IsSphereInView(x,y,z,length*.5+width*4+5) then
                    local key=r.shotKey or tostring(r.seed or 0)..':'..tostring(r.expires)
                    local group=lookup[key]
                    if not group then
                        group={expires=r.expires,nearest=d2,order=#groups+1,spans={}}
                        lookup[key]=group;groups[#groups+1]=group
                    end
                    group.nearest=math.min(group.nearest,d2)
                    local desired=math.min(6,math.max(1,math.ceil(length/16)))
                    if d2>3000^2 then desired=1 elseif d2>1400^2 then desired=math.min(desired,3) end
                    group.spans[#group.spans+1]={r=r,dx=dx,dy=dy,dz=dz,length=length,
                        width=width,d2=d2,desired=desired,cells=1,
                        opacity=clamp((cutoff-math.sqrt(d2))/(cutoff*.2),0,1)*(r.opacity or 1)}
                end
            end
        end
        -- Retain whole recent shot paths. Budget pressure never cuts an
        -- arbitrary missing middle out of one accepted trail.
        table.sort(groups,function(a,b)
            if a.expires~=b.expires then return a.expires>b.expires end
            if a.nearest~=b.nearest then return a.nearest<b.nearest end
            return a.order<b.order
        end)
        local accepted,desired={},0
        for _,group in ipairs(groups) do
            if #accepted+#group.spans<=math.min(self.maxSpans,self.maxCells) then
                stats.drawnShots=stats.drawnShots+1
                for _,d in ipairs(group.spans) do
                    accepted[#accepted+1]=d;d.order=#accepted;desired=desired+d.desired
                end
            else stats.droppedShots=stats.droppedShots+1 end
        end
        if #accepted==0 then return end
        local extra=math.max(0,self.maxCells-#accepted)
        local scale=desired>#accepted and math.min(1,extra/(desired-#accepted)) or 0
        local cells=0
        for _,d in ipairs(accepted) do
            d.cells=1+math.floor((d.desired-1)*scale);cells=cells+d.cells
        end
        -- Spread the available detail over the entire retained path before
        -- sorting for alpha blending. Distant spans keep one quad each.
        for _,d in ipairs(accepted) do
            if cells<self.maxCells and d.cells<d.desired then d.cells=d.cells+1;cells=cells+1 end
        end
        table.sort(accepted,function(a,b)
            if a.d2~=b.d2 then return a.d2>b.d2 end
            return a.order<b.order
        end)
        local wx,wy,wz=0,0,0
        if Spring.GetWind then wx,wy,wz=Spring.GetWind() end
        wx,wy,wz=wx or 0,wy or 0,wz or 0
        local windLength=math.sqrt(wx*wx+wy*wy+wz*wz)
        local windScale=1/math.max(1,windLength)
        local ar,ag,ab=gl.GetSun('ambient','unit')
        gl.PushAttrib(GL.ALL_ATTRIB_BITS)
        if gl.AlphaTest then gl.AlphaTest(false) end
        gl.DepthTest(true);gl.DepthMask(false);gl.Culling(false);gl.Texture(false)
        gl.Blending(GL.ONE,GL.ONE_MINUS_SRC_ALPHA);gl.UseShader(shader)
        gl.Uniform(loc.cameraPosition,cx,cy,cz)
        gl.Uniform(loc.driftDirection,wx*windScale,wy*windScale,wz*windScale)
        gl.Uniform(loc.ambient,ar or .5,ag or .5,ab or .5)
        gl.BeginEnd(GL.QUADS,draw,accepted,frame)
        gl.UseShader(0);gl.PopAttrib()
        stats.drawnSpans=#accepted;stats.cells=cells;stats.vertices=cells*4;stats.drawCalls=1
    end
    function self:GetStats() return self.stats end
    function self:Shutdown()
        if shader then gl.DeleteShader(shader);shader=nil end
    end
    return self
end
