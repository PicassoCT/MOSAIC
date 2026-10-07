-- Unsynced only. Bounded strip meshes are compiled once; all curling is in GLSL.
return function()
    if not gl.CreateShader then return nil, 'GLSL unavailable' end
    local path = 'luarules/gadgets/shaders/smokeRibbon.'
    local shader = gl.CreateShader({vertex = VFS.LoadFile(path..'vert'), fragment = VFS.LoadFile(path..'frag')})
    if not shader then return nil, gl.GetShaderLog() end
    local self = {records = {}, maxVisible = 128}
    local loc, meshes, hairHistory = {}, {}, {}
    for _, name in ipairs({'origin','direction','cameraPosition','effectTime','plumeLength',
        'plumeWidth','curl','seed','colorStart','colorEnd','emission','sourceGlow','ambient','strandOpacity','strandCount','directionalDrift','hairMode','stiffness','gravity',
        'landingMode','landingPad'}) do
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
    function self:Draw(worldEffects)
        local draw, cx,cy,cz = {}, Spring.GetCameraPosition()
        local _, fullView = Spring.GetSpectatingState()
        local ally = Spring.GetMyAllyTeamID()
        local wind, velocities = nil, {}
        local transforms = {}
        local pads = {}
        -- One animated basis query per piece/draw, shared by locks using a driver.
        local function pieceTransform(id, piece)
            local unit = transforms[id]
            if not unit then
                local front,up,right = Spring.GetUnitVectors(id)
                unit = {front=front,up=up,right=right,pieces={}}
                transforms[id] = unit
            end
            if unit.pieces[piece] ~= nil then return unit.pieces[piece] end
            local m = Spring.GetUnitPieceMatrix and {Spring.GetUnitPieceMatrix(id,piece)} or {}
            local front,up,right = unit.front,unit.up,unit.right
            local transform = false
            if m[16] and front and up and right then
                transform = function(a,b,c)
                    local px,py,pz = m[1]*a+m[5]*b+m[9]*c,
                        m[2]*a+m[6]*b+m[10]*c,m[3]*a+m[7]*b+m[11]*c
                    return -right[1]*px+up[1]*py+front[1]*pz,
                        -right[2]*px+up[2]*py+front[2]*pz,
                        -right[3]*px+up[3]*py+front[3]*pz
                end
            end
            unit.pieces[piece] = transform
            return transform
        end
        local function landingPad(id, piece)
            local key = id..':'..piece
            if pads[key] then return pads[key] end
            local pad = {0,0,0,-1} -- Invalid bounds: keep a free jet, never guess terrain.
            pads[key] = pad
            local transform = pieceTransform(id, piece)
            local info = Spring.GetUnitPieceInfo(id, piece)
            local x,y,z = Spring.GetUnitPiecePosDir(id, piece)
            if transform and x and info and info.min and info.max then
                local center, half = {}, {}
                for i=1,3 do
                    center[i]=(info.min[i]+info.max[i])*.5
                    half[i]=(info.max[i]-info.min[i])*.5
                end
                local ox,oy,oz = transform(unpack(center))
                local ax,ay,az = transform(half[1],0,0)
                local bx,by,bz = transform(0,half[2],0)
                local cx,cy,cz = transform(0,0,half[3])
                local hx,hy,hz = math.abs(ax)+math.abs(bx)+math.abs(cx),
                    math.abs(ay)+math.abs(by)+math.abs(cy),math.abs(az)+math.abs(bz)+math.abs(cz)
                local ux,uy,uz = Spring.GetUnitPosition(id)
                local vx,vy,vz
                if Spring.GetUnitViewPosition then vx,vy,vz = Spring.GetUnitViewPosition(id) end
                if ux and vx then x,y,z=x+vx-ux,y+vy-uy,z+vz-uz end
                -- LandCone's bottom is the deck contact plane, not its raised pivot.
                pad = {x+ox,y+oy-hy,z+oz,math.sqrt(hx*hx+hz*hz)}
                pads[key] = pad
            end
            return pad
        end
        local now = (Spring.GetGameFrame()+(Spring.GetFrameTimeOffset() or 0))/(Game.gameSpeed or 30)
        local nextHistory = {}
        for key, r in pairs(self.records) do
            local id = r.unitID
            local los = fullView or Spring.GetUnitLosState(id,ally)
            if r.enabled and (fullView or (los and los.los)) and not Spring.GetUnitIsDead(id)
                and not Spring.GetUnitIsCloaked(id) and not Spring.GetUnitNoDraw(id)
                and not Spring.GetUnitTransporter(id) and (r.drawInIcon or not Spring.IsUnitIcon(id)) then
                local x,y,z,ex,ey,ez = Spring.GetUnitPiecePosDir(id,r.piece)
                if x then
                    -- Same draw translation correction as Mosaic's live headlights.
                    local ux,uy,uz = Spring.GetUnitPosition(id)
                    local vx,vy,vz
                    if Spring.GetUnitViewPosition then vx,vy,vz = Spring.GetUnitViewPosition(id) end
                    if ux and vx then x,y,z = x+vx-ux,y+vy-uy,z+vz-uz end
                    -- Full piece basis, including parent animation and model scale.
                    -- Match the model-X convention used by the cloud volume renderer.
                    -- Attachment offsets are piece-local even for world-down vapor.
                    if r.rootOffset[1] ~= 0 or r.rootOffset[2] ~= 0 or r.rootOffset[3] ~= 0 then
                        local transform = pieceTransform(id,r.piece)
                        if transform then
                            local ox,oy,oz = transform(unpack(r.rootOffset))
                            x,y,z = x+ox,y+oy,z+oz
                        end
                    end
                    local length,width = r.length*r.scale,r.width*r.scale
                    -- Terrain fit stays local to rendering: no per-frame synced updates.
                    if r.groundDirected then
                        length = math.max(0.01, y - math.max(0, Spring.GetGroundHeight(x,z)))
                    end
                    local cutoff = math.max(length,2*width)*(r.distanceFactor or 40)
                    local anchorD2 = (cx-x)^2+(cy-y)^2+(cz-z)^2
                    -- Reject before direction work, frustum tests, sorting and GPU submission.
                    if r.distanceCulling == false or anchorD2 < cutoff*cutoff then
                        local fade = 1
                        if r.distanceCulling ~= false and anchorD2 > (cutoff*0.8)^2 then
                            local t = (math.sqrt(anchorD2)/cutoff-0.8)/0.2
                            fade = 1-t*t*(3-2*t)
                        end
                        local dx,dy,dz = unpack(r.direction)
                        if r.directionSpace == 'piece' then
                            local transform = pieceTransform(id,r.directionPiece or r.piece)
                            if transform then dx,dy,dz = transform(dx,dy,dz) else dx,dy,dz = 0,0,0 end
                        elseif r.directionSpace == 'emitter' then
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
                            if r.mode == 'hair' and (r.hang or 0)>0 then
                                local h=r.hang
                                dx,dy,dz=dx*(1-h),dy*(1-h)-h,dz*(1-h)
                                local norm=math.sqrt(dx*dx+dy*dy+dz*dz)
                                if norm>1e-6 then dx,dy,dz=dx/norm,dy/norm,dz/norm
                                else dx,dy,dz=0,-1,0 end
                            end
                            local driftX,driftY,driftZ = 0,0,0
                            if r.windAffected ~= false and Spring.GetWind then
                                if not wind then wind={Spring.GetWind()} end
                                local gain=(r.windInfluence or 0.3)*(r.trailTime or 0.7)
                                driftX,driftY,driftZ=(wind[1] or 0)*gain,(wind[2] or 0)*gain,(wind[3] or 0)*gain
                            end
                            if r.mode ~= 'hair' and r.motionAffected and Spring.GetUnitVelocity then
                                local velocity=velocities[id]
                                if not velocity then velocity={Spring.GetUnitVelocity(id)};velocities[id]=velocity end
                                -- Engine unit velocity is in world units per simulation frame.
                                local gain=(Game.gameSpeed or 30)*(r.motionInfluence or 1)*(r.trailTime or 0.7)
                                driftX=driftX-(velocity[1] or 0)*gain
                                driftY=driftY-(velocity[2] or 0)*gain
                                driftZ=driftZ-(velocity[3] or 0)*gain
                            end
                            if r.mode == 'hair' and r.motionAffected then
                                -- Follow a rest tip, so both translation and head turns create lag.
                                local tx,ty,tz=x+dx*length,y+dy*length,z+dz*length
                                local old=hairHistory[key]
                                local dt=old and now-old.time or 0
                                local hx,hy,hz=0,0,0
                                if old and dt>=0 and dt<0.25 then
                                    hx,hy,hz=old.x,old.y,old.z
                                    if dt>0 then
                                        local vx,vy,vz=tx-old.tx,ty-old.ty,tz-old.tz
                                        if vx*vx+vy*vy+vz*vz < (length*4)^2 then
                                            local a=1-math.exp(-dt*(8+16*r.stiffness))
                                            local gain=(r.motionInfluence or 1)*(r.trailTime or 0.12)/dt
                                            hx=hx+(-vx*gain-hx)*a
                                            hy=hy+(-vy*gain-hy)*a
                                            hz=hz+(-vz*gain-hz)*a
                                        else hx,hy,hz=0,0,0 end
                                    end
                                end
                                nextHistory[key]={time=now,tx=tx,ty=ty,tz=tz,x=hx,y=hy,z=hz}
                                -- Replace generic unit-velocity trailing with tip history.
                                driftX,driftY,driftZ=hx,hy,hz
                                if r.windAffected ~= false and wind then
                                    local gain=r.windInfluence*r.trailTime
                                    driftX=driftX+(wind[1] or 0)*gain
                                    driftY=driftY+(wind[2] or 0)*gain
                                    driftZ=driftZ+(wind[3] or 0)*gain
                                end
                            end
                            -- Vertical wind/climb must not pull a ground spray away from the surface.
                            if r.groundDirected then driftY=0 end
                            local driftLength=math.sqrt(driftX*driftX+driftY*driftY+driftZ*driftZ)
                            -- Bound extreme speeds/wind to retain predictable overdraw and culling.
                            -- Hair already applies stiffness in GLSL and preserves
                            -- arc length. A second stiffness-scaled clamp here made
                            -- even strong wind almost invisible on stationary locks.
                            local maxDrift = r.mode == 'hair' and length*1.5 or length*2
                            if driftLength>maxDrift then
                                local cap=maxDrift/driftLength
                                driftX,driftY,driftZ=driftX*cap,driftY*cap,driftZ*cap
                                driftLength=maxDrift
                            end
                            if r.groundDirected then
                                local ground = math.max(0, Spring.GetGroundHeight(x+driftX,z+driftZ))
                                length = math.max(0.01,y-ground)
                            end
                            local mx,my,mz = x+(dx*length+driftX)*0.5,y+(dy*length+driftY)*0.5,z+(dz*length+driftZ)*0.5
                            -- Includes maximum curl, axial displacement and ribbon half-width.
                            local radius = length*0.5+width*(r.curl*2+1)+driftLength*0.5
                            if r.mode == 'hair' then radius=length*1.5+width end
                            local pad
                            if r.mode == 'landing' then
                                pad = landingPad(id, r.padPiece)
                                -- Return flow and the pad fan extend up and sideways.
                                mx,my,mz=x,y,z
                                radius=length*2+width*(r.curl*2+1)+driftLength
                            end
                            if Spring.IsSphereInView(mx,my,mz,radius) then
                                draw[#draw+1] = {r=r,x=x,y=y,z=z,dx=dx,dy=dy,dz=dz,
                                    driftX=driftX,driftY=driftY,driftZ=driftZ,
                                    length=length,width=width,fade=fade,pad=pad,d2=(cx-mx)^2+(cy-my)^2+(cz-mz)^2}
                            end
                        end
                    end
                end
            end
        end
        -- Combat trails and ground fires use the same FlamePainter shader and
        -- bounded meshes as piece-attached effects, with client-side anchors.
        for _,r in ipairs(worldEffects or {}) do
            local x,y,z=r.x,r.y,r.z
            local length,width=r.length,r.width
            local d2=(cx-x)^2+(cy-y)^2+(cz-z)^2
            local cutoff=math.max(length,width*2)*(r.distanceFactor or 40)
            if (fullView or Spring.IsPosInLos(x,y,z,ally)) and d2<cutoff*cutoff
                and Spring.IsSphereInView(x,y+length*.5,z,length*2+width*3) then
                if not wind and Spring.GetWind then wind={Spring.GetWind()} end
                local v=r.velocity or {0,0,0}
                local gain=(r.trailTime or .1)*(Game.gameSpeed or 30)
                local wg=(r.windInfluence or .3)*(r.trailTime or .1)
                local drift={}
                local magnitude=0
                for axis=1,3 do
                    drift[axis]=(wind and wind[axis] or 0)*wg-(v[axis] or 0)*gain
                    magnitude=magnitude+drift[axis]^2
                end
                local cap=math.min(1,length*2/math.max(.001,math.sqrt(magnitude)))
                local fade=math.min(1,(cutoff-math.sqrt(d2))/(cutoff*.2))*(r.opacity or 1)
                draw[#draw+1]={r=r,x=x,y=y,z=z,dx=r.direction[1],dy=r.direction[2],dz=r.direction[3],
                    driftX=drift[1]*cap,driftY=drift[2]*cap,driftZ=drift[3]*cap,
                    length=length,width=width,fade=fade,d2=d2}
            end
        end
        hairHistory=nextHistory
        if #draw == 0 then return end
        table.sort(draw,function(a,b) return a.d2 < b.d2 end)
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
            gl.Uniform(loc.hairMode,r.mode == 'hair' and 1 or 0)
            gl.Uniform(loc.landingMode,r.mode == 'landing' and 1 or 0)
            gl.Uniform(loc.landingPad,unpack(d.pad or {0,0,0,-1}))
            gl.Uniform(loc.stiffness,r.stiffness or 0.7)
            gl.Uniform(loc.gravity,r.gravity or 0.35)
            gl.Uniform(loc.effectTime,now*r.speed)
            gl.Uniform(loc.plumeLength,d.length); gl.Uniform(loc.plumeWidth,d.width)
            gl.Uniform(loc.strandCount,r.strands)
            gl.Uniform(loc.curl,r.curl); gl.Uniform(loc.seed,r.seed)
            gl.Uniform(loc.colorStart,unpack(r.colorStart)); gl.Uniform(loc.colorEnd,unpack(r.colorEnd))
            gl.Uniform(loc.emission,unpack(r.emission)); gl.Uniform(loc.strandOpacity,(r.mode == 'hair' and 1 or 1.6/r.strands)*d.fade)
            gl.Uniform(loc.sourceGlow,unpack(r.sourceGlow))
            local segments = d.d2 > (d.length*20)^2 and 24 or 48
            gl.CallList(meshes[segments][r.strands])
        end
        gl.UseShader(0); gl.PopAttrib()
    end
    return self
end
