-- Unsynced, standalone compatibility GLSL. No model-shader framework required.
return function(Config)
    if not gl.CreateShader or not gl.CopyToTexture then return nil,'GLSL/depth copy unavailable' end
    local path='luarules/gadgets/shaders/cloudVolume.'
    local shader=gl.CreateShader({vertex=VFS.LoadFile(path..'vert'),fragment=VFS.LoadFile(path..'frag'),uniformInt={sceneDepth=0}})
    if not shader then return nil,gl.GetShaderLog() end
    local self={records={}}
    local loc={}
    for _,n in ipairs({'viewportSize','viewportOrigin','zeroToOne','effectTime','seed','density','emission',
        'opacity','phase','smokeColor','hotColor','ambient','shape','steps','volumeAxis','gradientSign'}) do loc[n]=gl.GetUniformLocation(shader,n) end
    local depth,w,h
    local quad=gl.CreateList(function() gl.BeginEnd(GL.QUADS,function()
        gl.Vertex(-1,-1);gl.Vertex(1,-1);gl.Vertex(1,1);gl.Vertex(-1,1)
    end) end)
    if not quad then gl.DeleteShader(shader);return nil,'quad allocation failed' end
    local function transform(d)
        local r=d.r
        if r.unitID then
            local ux,uy,uz=Spring.GetUnitPosition(r.unitID)
            local vx,vy,vz=Spring.GetUnitViewPosition(r.unitID)
            if ux and vx then gl.Translate(vx-ux,vy-uy,vz-uz) end
            (gl.UnitMultMatrix or gl.UnitMatrix)(r.unitID)
            gl.UnitPieceMatrix(r.unitID,r.piece)
            gl.Translate(unpack(r.center));gl.Scale(unpack(r.half))
        else
            gl.Translate(d.x,d.y,d.z);gl.Scale(d.radius,d.height,d.radius)
        end
    end
    local function rect(proj,vw,vh)
        local m={gl.GetMatrixData(GL.MODELVIEW)}
        local xmin,ymin,xmax,ymax=1,1,-1,-1
        for x=-1,1,2 do for y=-1,1,2 do for z=-1,1,2 do
            local v={m[1]*x+m[5]*y+m[9]*z+m[13],m[2]*x+m[6]*y+m[10]*z+m[14],
                m[3]*x+m[7]*y+m[11]*z+m[15],m[4]*x+m[8]*y+m[12]*z+m[16]}
            local cw=proj[4]*v[1]+proj[8]*v[2]+proj[12]*v[3]+proj[16]*v[4]
            -- Near-plane/inside-volume case: full viewport, fragment ray-box test clips it.
            if cw<.01 then return {0,0,vw,vh} end
            local px=(proj[1]*v[1]+proj[5]*v[2]+proj[9]*v[3]+proj[13]*v[4])/cw
            local py=(proj[2]*v[1]+proj[6]*v[2]+proj[10]*v[3]+proj[14]*v[4])/cw
            xmin=math.min(xmin,px);xmax=math.max(xmax,px);ymin=math.min(ymin,py);ymax=math.max(ymax,py)
        end end end
        local x0=math.max(0,math.floor((xmin*.5+.5)*vw)-1)
        local y0=math.max(0,math.floor((ymin*.5+.5)*vh)-1)
        local x1=math.min(vw,math.ceil((xmax*.5+.5)*vw)+1)
        local y1=math.min(vh,math.ceil((ymax*.5+.5)*vh)+1)
        if x1<=x0 or y1<=y0 then return end
        return {x0,y0,x1-x0,y1-y0}
    end
    function self:Draw()
        local vw,vh,vx,vy=Spring.GetViewGeometry()
        vx,vy=vx or 0,vy or 0
        local cx,cy,cz=Spring.GetCameraPosition()
        local _,fullView=Spring.GetSpectatingState()
        local ally=Spring.GetMyAllyTeamID()
        local now=(Spring.GetGameFrame()+(Spring.GetFrameTimeOffset() or 0))/(Game.gameSpeed or 30)
        local candidates={}
        for key,r in pairs(self.records) do
            local p=Config.Preset(r.preset)
            local age=math.max(0,now-r.born/(Game.gameSpeed or 30))
            local visible=true
            local x,y,z,radius,height,bound
            local phase=0
            if r.unitID then
                local id=r.unitID
                local los=fullView or Spring.GetUnitLosState(id,ally)
                visible=(fullView or (los and los.los)) and not Spring.GetUnitIsDead(id)
                    and not Spring.GetUnitIsCloaked(id) and not Spring.GetUnitNoDraw(id)
                    and not Spring.GetUnitTransporter(id) and not Spring.IsUnitIcon(id)
                if visible then
                    x,y,z=Spring.GetUnitPiecePosDir(id,r.piece)
                    if x then
                        local m={Spring.GetUnitPieceMatrix(id,r.piece)}
                        if m[16] then
                            local scale=math.max(math.sqrt(m[1]^2+m[2]^2+m[3]^2),
                                math.sqrt(m[5]^2+m[6]^2+m[7]^2),math.sqrt(m[9]^2+m[10]^2+m[11]^2))
                            radius=math.sqrt(r.half[1]^2+r.half[2]^2+r.half[3]^2)*scale
                            bound=radius+math.sqrt(r.center[1]^2+r.center[2]^2+r.center[3]^2)*scale
                        end
                    end
                end
            else
                phase=age/p.duration
                visible=phase<1 and (fullView or Spring.IsPosInLos(r.x,r.y,r.z,ally))
                local grow=.15+.85*(1-math.exp(-age*.7))
                radius=p.radius*r.scale*grow;height=p.height*r.scale*grow*.5
                x,y,z=r.x,r.y+height*.8,r.z
                bound=math.sqrt(radius^2*2+height^2)
            end
            if visible and x and radius and radius>.01 then
                local d2=(cx-x)^2+(cy-y)^2+(cz-z)^2
                local cutoff=radius*40+ (bound-radius)
                if d2<cutoff^2 and Spring.IsSphereInView(x,y,z,bound) then
                    local fade=math.max(0,math.min(1,(cutoff-math.sqrt(d2))/(cutoff*.2)))
                    fade=fade*fade*(3-2*fade)
                    if not r.unitID then
                        local tail=math.max(0,math.min(1,(1-phase)/.35));fade=fade*tail*tail*(3-2*tail)
                    else fade=fade*math.min(1,age/.15) end
                    candidates[#candidates+1]={key=key,r=r,p=p,age=age,phase=phase,x=x,y=y,z=z,
                        radius=radius,height=height,fade=fade,d2=d2}
                end
            end
        end
        if #candidates==0 then return end
        table.sort(candidates,function(a,b) if a.d2==b.d2 then return a.key<b.key end return a.d2<b.d2 end)
        local proj={gl.GetMatrixData(GL.PROJECTION)}
        local draw,budget={},vw*vh*64 -- two full-screen 32-step volumes worth of samples
        for i=1,math.min(#candidates,24) do
            local d=candidates[i]
            gl.PushMatrix();transform(d);d.rect=rect(proj,vw,vh);gl.PopMatrix()
            if d.rect then
                local area=d.rect[3]*d.rect[4]
                d.steps=d.d2>(d.radius*10)^2 and 12 or 24
                if area*d.steps>budget then d.steps=math.min(d.steps,math.floor(budget/area)) end
                if d.steps>=8 then budget=budget-area*d.steps;draw[#draw+1]=d end
            end
        end
        if #draw==0 then return end
        if vw~=w or vh~=h then
            if depth then gl.DeleteTexture(depth);depth=nil end
            depth=gl.CreateTexture(vw,vh,{format=GL.DEPTH_COMPONENT24 or 0x81A6,
                min_filter=GL.NEAREST,mag_filter=GL.NEAREST,wrap_s=GL.CLAMP_TO_EDGE,wrap_t=GL.CLAMP_TO_EDGE})
            w,h=vw,vh
        end
        if not depth then return end
        gl.CopyToTexture(depth,0,0,vx,vy,vw,vh)
        local ar,ag,ab=gl.GetSun('ambient','unit')
        gl.PushAttrib(GL.ALL_ATTRIB_BITS)
        gl.DepthTest(false);gl.DepthMask(false);gl.Culling(false)
        gl.Blending(GL.ONE,GL.ONE_MINUS_SRC_ALPHA);gl.Texture(0,depth);gl.UseShader(shader)
        gl.Uniform(loc.viewportSize,vw,vh);gl.Uniform(loc.viewportOrigin,vx,vy)
        gl.Uniform(loc.zeroToOne,(Platform and Platform.glSupportClipSpaceControl) and 1 or 0)
        gl.Uniform(loc.ambient,ar or .5,ag or .5,ab or .5)
        for i=#draw,1,-1 do
            local d=draw[i];local p=d.p
            gl.Scissor(vx+d.rect[1],vy+d.rect[2],d.rect[3],d.rect[4])
            gl.Uniform(loc.effectTime,d.age*p.speed);gl.Uniform(loc.seed,d.r.seed)
            gl.Uniform(loc.density,p.density);gl.Uniform(loc.emission,p.emission)
            gl.Uniform(loc.opacity,d.fade);gl.Uniform(loc.phase,d.phase)
            gl.Uniform(loc.smokeColor,unpack(p.color));gl.Uniform(loc.hotColor,unpack(p.hot))
            local axis,sign=2,1
            if d.r.half then
                for j=1,3 do
                    if (p.shape==1 and d.r.half[j]>d.r.half[axis]) or
                        (p.shape==2 and d.r.half[j]<d.r.half[axis]) then axis=j end
                end
                if d.r.center[axis]>0 then sign=-1 end
            end
            gl.UniformInt(loc.volumeAxis,axis-1);gl.Uniform(loc.gradientSign,sign)
            gl.UniformInt(loc.shape,p.shape);gl.UniformInt(loc.steps,d.steps)
            gl.PushMatrix();transform(d);gl.CallList(quad);gl.PopMatrix()
        end
        gl.UseShader(0);gl.Texture(0,false);gl.PopAttrib()
    end
    function self:Shutdown()
        if depth then gl.DeleteTexture(depth) end
        gl.DeleteList(quad);gl.DeleteShader(shader)
    end
    return self
end
