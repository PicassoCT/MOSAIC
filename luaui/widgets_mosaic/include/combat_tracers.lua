-- Camera-facing luminous streaks. They share combat projectile discovery and
-- ground lighting, and submit nothing in daylight. No textures or framebuffers.
return function()
    local path='luaui/widgets_mosaic/shaders/radiancecascade/'
    local shader=gl.CreateShader({vertex=VFS.LoadFile(path..'tracer.vert'),fragment=VFS.LoadFile(path..'tracer.frag')})
    if not shader then return nil,gl.GetShaderLog() end
    local nightLoc=gl.GetUniformLocation(shader,'nightIntensity')
    local self={}
    local function draw(tracers,cx,cy,cz)
        for _,t in ipairs(tracers) do
            local speed=math.sqrt(t.vx^2+t.vy^2+t.vz^2)
            if speed>.001 then
                local dx,dy,dz=t.vx/speed,t.vy/speed,t.vz/speed
                local length=math.max(12,math.min(60,speed*1.5))
                local ex,ey,ez=cx-t.x,cy-t.y,cz-t.z
                local d2=ex*ex+ey*ey+ez*ez
                if d2<8000^2 and Spring.IsSphereInView(t.x,t.y,t.z,length) then
                    local sx,sy,sz=dy*ez-dz*ey,dz*ex-dx*ez,dx*ey-dy*ex
                    local mag=math.sqrt(sx*sx+sy*sy+sz*sz)
                    if mag<.001 then
                        -- Looking straight down the round: use a stable alternate axis.
                        local ax,ay=math.abs(dy)<.9 and 0 or 1,math.abs(dy)<.9 and 1 or 0
                        sx,sy,sz=-dz*ay,dz*ax,dx*ay-dy*ax
                        mag=math.sqrt(sx*sx+sy*sy+sz*sz)
                    end
                    sx,sy,sz=sx/mag*t.width,sy/mag*t.width,sz/mag*t.width
                    local x,y,z=t.x-dx*length,t.y-dy*length,t.z-dz*length
                    gl.Color(t.color[1],t.color[2],t.color[3],1)
                    gl.TexCoord(0,0);gl.Vertex(x-sx,y-sy,z-sz)
                    gl.TexCoord(0,1);gl.Vertex(x+sx,y+sy,z+sz)
                    gl.TexCoord(1,1);gl.Vertex(t.x+sx,t.y+sy,t.z+sz)
                    gl.TexCoord(1,0);gl.Vertex(t.x-sx,t.y-sy,t.z-sz)
                end
            end
        end
    end
    function self:Draw(tracers,night)
        if not shader or night<=0 or #tracers==0 then return end
        local cx,cy,cz=Spring.GetCameraPosition()
        gl.PushAttrib(GL.ALL_ATTRIB_BITS)
        gl.DepthTest(true);gl.DepthMask(false);gl.Culling(false);gl.Texture(false)
        gl.Blending(GL.ONE,GL.ONE);gl.UseShader(shader)
        gl.Uniform(nightLoc,night)
        gl.BeginEnd(GL.QUADS,draw,tracers,cx,cy,cz)
        gl.UseShader(0);gl.PopAttrib()
    end
    function self:Shutdown() if shader then gl.DeleteShader(shader);shader=nil end end
    return self
end
