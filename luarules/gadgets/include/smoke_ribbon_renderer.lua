-- Unsynced only. Bounded strip meshes are compiled once; all curling is in GLSL.
return function()
    if not gl.CreateShader then return nil, 'GLSL unavailable' end
    local path = 'luarules/gadgets/shaders/smokeRibbon.'
    local shader = gl.CreateShader({vertex = VFS.LoadFile(path..'vert'), fragment = VFS.LoadFile(path..'frag')})
    if not shader then return nil, gl.GetShaderLog() end
    local self = {records = {}, maxVisible = 128}
    local loc, meshes = {}, {}
    for _, name in ipairs({'origin','direction','cameraPosition','effectTime','plumeLength',
        'plumeWidth','curl','seed','colorStart','colorEnd','emission','ambient','strandOpacity','directionalDrift'}) do
        loc[name] = gl.GetUniformLocation(shader, name)
    end
    local function strip(segments, strand)
        for i=0,segments do
            gl.Vertex(i/segments,-1,strand); gl.Vertex(i/segments,1,strand)
        end
    end
    for _, segments in ipairs({24,48}) do
        meshes[segments] = {}
        for count=1,4 do
            meshes[segments][count] = gl.CreateList(function()
                for strand=0,count-1 do gl.BeginEnd(GL.TRIANGLE_STRIP,strip,segments,strand) end
            end)
            if not meshes[segments][count] then
                for _, group in pairs(meshes) do for _, list in pairs(group) do gl.DeleteList(list) end end
                gl.DeleteShader(shader)
                return nil, 'ribbon mesh allocation failed'
            end
        end
    end
    function self:Shutdown()
        for _, group in pairs(meshes) do for _, list in pairs(group) do gl.DeleteList(list) end end
        gl.DeleteShader(shader)
    end
    function self:Draw()
        local draw, cx,cy,cz = {}, Spring.GetCameraPosition()
        local _, fullView = Spring.GetSpectatingState()
        local ally = Spring.GetMyAllyTeamID()
        local wind, velocities = nil, {}
        for _, r in pairs(self.records) do
            local id = r.unitID
            local los = fullView or Spring.GetUnitLosState(id,ally)
            if r.enabled and (fullView or (los and los.los)) and not Spring.GetUnitIsDead(id)
                and not Spring.GetUnitIsCloaked(id) and not Spring.GetUnitNoDraw(id)
                and not Spring.GetUnitTransporter(id) and not Spring.IsUnitIcon(id) then
                local x,y,z,ex,ey,ez = Spring.GetUnitPiecePosDir(id,r.piece)
                if x then
                    -- Same draw translation correction as Mosaic's live headlights.
                    local ux,uy,uz = Spring.GetUnitPosition(id)
                    local vx,vy,vz
                    if Spring.GetUnitViewPosition then vx,vy,vz = Spring.GetUnitViewPosition(id) end
                    if ux and vx then x,y,z = x+vx-ux,y+vy-uy,z+vz-uz end
                    local length,width = r.length*r.scale,r.width*r.scale
                    -- Terrain fit stays local to rendering: no per-frame synced updates.
                    if r.groundDirected then
                        length = math.max(0.01, y - math.max(0, Spring.GetGroundHeight(x,z)))
                    end
                    local cutoff = math.max(length,2*width)*(r.distanceFactor or 40)
                    local anchorD2 = (cx-x)^2+(cy-y)^2+(cz-z)^2
                    -- Reject before direction work, frustum tests, sorting and GPU submission.
                    if anchorD2 < cutoff*cutoff then
                        local fade = 1
                        if anchorD2 > (cutoff*0.8)^2 then
                            local t = (math.sqrt(anchorD2)/cutoff-0.8)/0.2
                            fade = 1-t*t*(3-2*t)
                        end
                        local dx,dy,dz = unpack(r.direction)
                        if r.directionSpace == 'emitter' then
                            dx,dy,dz = ex,ey,ez
                        elseif r.directionSpace == 'unit' then
                            local front,up,right = Spring.GetUnitVectors(id)
                            if front and up and right then
                                dx,dy,dz = right[1]*dx+up[1]*dy+front[1]*dz,
                                    right[2]*dx+up[2]*dy+front[2]*dz,
                                    right[3]*dx+up[3]*dy+front[3]*dz
                            end
                        end
                        if r.groundDirected then dx,dy,dz = 0,-1,0 end
                        local magnitude = dx and math.sqrt(dx*dx+dy*dy+dz*dz) or 0
                        if magnitude > 1e-6 then
                            dx,dy,dz = dx/magnitude,dy/magnitude,dz/magnitude
                            local driftX,driftY,driftZ = 0,0,0
                            if r.windAffected ~= false and Spring.GetWind then
                                if not wind then wind={Spring.GetWind()} end
                                local gain=(r.windInfluence or 0.3)*(r.trailTime or 0.7)
                                driftX,driftY,driftZ=(wind[1] or 0)*gain,(wind[2] or 0)*gain,(wind[3] or 0)*gain
                            end
                            if r.motionAffected and Spring.GetUnitVelocity then
                                local velocity=velocities[id]
                                if not velocity then velocity={Spring.GetUnitVelocity(id)};velocities[id]=velocity end
                                -- Engine unit velocity is in world units per simulation frame.
                                local gain=(Game.gameSpeed or 30)*(r.motionInfluence or 1)*(r.trailTime or 0.7)
                                driftX=driftX-(velocity[1] or 0)*gain
                                driftY=driftY-(velocity[2] or 0)*gain
                                driftZ=driftZ-(velocity[3] or 0)*gain
                            end
                            -- Vertical wind/climb must not pull a ground spray away from the surface.
                            if r.groundDirected then driftY=0 end
                            local driftLength=math.sqrt(driftX*driftX+driftY*driftY+driftZ*driftZ)
                            -- Bound extreme speeds/wind to retain predictable overdraw and culling.
                            if driftLength>length*2 then
                                local cap=length*2/driftLength
                                driftX,driftY,driftZ=driftX*cap,driftY*cap,driftZ*cap
                                driftLength=length*2
                            end
                            if r.groundDirected then
                                local ground = math.max(0, Spring.GetGroundHeight(x+driftX,z+driftZ))
                                length = math.max(0.01,y-ground)
                            end
                            local mx,my,mz = x+(dx*length+driftX)*0.5,y+(dy*length+driftY)*0.5,z+(dz*length+driftZ)*0.5
                            -- Includes maximum curl, axial displacement and ribbon half-width.
                            local radius = length*0.5+width*(r.curl*2+1)+driftLength*0.5
                            if Spring.IsSphereInView(mx,my,mz,radius) then
                                draw[#draw+1] = {r=r,x=x,y=y,z=z,dx=dx,dy=dy,dz=dz,
                                    driftX=driftX,driftY=driftY,driftZ=driftZ,
                                    length=length,width=width,fade=fade,d2=(cx-mx)^2+(cy-my)^2+(cz-mz)^2}
                            end
                        end
                    end
                end
            end
        end
        if #draw == 0 then return end
        table.sort(draw,function(a,b) return a.d2 < b.d2 end)
        local now = (Spring.GetGameFrame()+(Spring.GetFrameTimeOffset() or 0))/(Game.gameSpeed or 30)
        local ar,ag,ab = gl.GetSun('ambient','unit')
        gl.PushAttrib(GL.ALL_ATTRIB_BITS)
        gl.DepthTest(true); gl.DepthMask(false); gl.Culling(false)
        gl.Blending(GL.ONE,GL.ONE_MINUS_SRC_ALPHA)
        gl.UseShader(shader)
        gl.Uniform(loc.cameraPosition,cx,cy,cz)
        gl.Uniform(loc.ambient,ar or 0.5,ag or 0.5,ab or 0.5)
        for i=math.min(#draw,self.maxVisible),1,-1 do
            local d=draw[i]; local r=d.r
            gl.Uniform(loc.origin,d.x,d.y,d.z); gl.Uniform(loc.direction,d.dx,d.dy,d.dz)
            gl.Uniform(loc.directionalDrift,d.driftX,d.driftY,d.driftZ)
            gl.Uniform(loc.effectTime,now*r.speed)
            gl.Uniform(loc.plumeLength,d.length); gl.Uniform(loc.plumeWidth,d.width)
            gl.Uniform(loc.curl,r.curl); gl.Uniform(loc.seed,r.seed)
            gl.Uniform(loc.colorStart,unpack(r.colorStart)); gl.Uniform(loc.colorEnd,unpack(r.colorEnd))
            gl.Uniform(loc.emission,unpack(r.emission)); gl.Uniform(loc.strandOpacity,1.6/r.strands*d.fade)
            local segments = d.d2 > (d.length*20)^2 and 24 or 48
            gl.CallList(meshes[segments][r.strands])
        end
        gl.UseShader(0); gl.PopAttrib()
    end
    return self
end
