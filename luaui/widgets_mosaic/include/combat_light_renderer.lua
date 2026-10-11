-- Joins the existing car-light captures. Owns one shader, no textures or FBOs.
return function(sources)
    local path='luaui/widgets_mosaic/shaders/radiancecascade/'
    local shader=gl.CreateShader({vertex=VFS.LoadFile(path..'combat_emission.vert'),
        fragment=VFS.LoadFile(path..'combat_emission.frag'),uniformInt={buildingOccupancy=0}})
    if not shader then return nil,gl.GetShaderLog() end
    local loc={}
    for _,name in ipairs({'mapSize','lamp','radius','color','strength','hasOccupancy','heightRange'}) do
        loc[name]=gl.GetUniformLocation(shader,name)
    end
    local self={}
    local function quad(l,y)
        local x,z,r=l.x,l.z,l.radius
        gl.Vertex(x-r,y,z-r);gl.Vertex(x+r,y,z-r);gl.Vertex(x+r,y,z+r);gl.Vertex(x-r,y,z+r)
    end
    function self:Capture(bottom,top,gain,night)
        gl.DepthTest(false);gl.DepthMask(false);gl.Blending(GL.ONE,GL.ONE)
        gl.UseShader(shader);gl.Uniform(loc.mapSize,Game.mapSizeX,Game.mapSizeZ)
        gl.Uniform(loc.heightRange,bottom,top)
        for _,l in ipairs(sources:Collect()) do
            local strength=l.strength*(gain or 1)*(l.nightOnly and (night or 0) or 1)
            if strength>0 and l.y+l.radius>bottom and l.y-l.radius<top then
                local y=math.max(bottom,math.min(top-1,math.max(0,Spring.GetGroundHeight(l.x,l.z))+1))
                local atlas=WG.GetVehicleLightOcclusion and WG.GetVehicleLightOcclusion(y)
                gl.Texture(0,atlas or false);gl.Uniform(loc.hasOccupancy,atlas and 1 or 0)
                gl.Uniform(loc.lamp,l.x,l.y,l.z);gl.Uniform(loc.radius,l.radius)
                gl.Uniform(loc.color,l.color[1],l.color[2],l.color[3]);gl.Uniform(loc.strength,strength)
                gl.BeginEnd(GL.QUADS,quad,l,y)
            end
        end
        gl.UseShader(0);gl.Texture(0,false);gl.Blending(false)
    end
    function self:Shutdown() if shader then gl.DeleteShader(shader);shader=nil end end
    return self
end
