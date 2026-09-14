-- Camera-local capture + solve. Fixed textures; no screen-size allocations.
-- Outside the patch, rays read the current scene-band whole-map inputs.
local M={}
function M.ChooseDomain(x,z,distance,previousSpan)
    local span
    if distance<1300 or previousSpan==1024 and distance<1600 then span=1024
    elseif distance<3000 or previousSpan==2048 and distance<3400 then span=2048
    else return nil end
    span=math.min(span,Game.mapSizeX,Game.mapSizeZ)
    local step=span/128
    return {span=span,
        x=math.max(0,math.min(Game.mapSizeX-span,math.floor((x-span*0.5)/step)*step)),
        z=math.max(0,math.min(Game.mapSizeZ-span,math.floor((z-span*0.5)/step)*step))}
end
function M.New()
    local self={ready=false,enabled=true}
    function self:Shutdown()
        self.ready=false
        if self.solver then self.solver:Shutdown();self.solver=nil end
        for _,key in ipairs({"emission","occupancy"}) do
            if self[key] then gl.DeleteTexture(self[key]);self[key]=nil end
        end
    end
    function self:CameraDomain()
        if not self.enabled or self.failed or not Spring.TraceScreenRay or not Spring.GetCameraPosition then return nil end
        local sx,sy=gl.GetViewSizes()
        local kind,pos=Spring.TraceScreenRay(math.floor(sx/2),math.floor(sy/2),true,false)
        if kind~="ground" or type(pos)~="table" or not pos[1] or not pos[2] or not pos[3] then return nil end
        local cx,cy,cz=Spring.GetCameraPosition()
        if not cx or not cy or not cz then return nil end
        local distance=math.sqrt((cx-pos[1])^2+(cy-pos[2])^2+(cz-pos[3])^2)
        return M.ChooseDomain(pos[1],pos[3],distance,self.domain and self.domain.span)
    end
    function self:Allocate()
        if self.solver then return true end
        local factory=VFS.Include("luaui/widgets_mosaic/include/radiance_propagation.lua")
        local reason
        self.solver,reason=factory(1024,true)
        if self.solver then
            local opts={format=GL.RGBA8 or 0x8058,min_filter=GL.NEAREST,mag_filter=GL.NEAREST,
                wrap_s=GL.CLAMP_TO_EDGE,wrap_t=GL.CLAMP_TO_EDGE,fbo=true}
            self.emission=gl.CreateTexture(1024,1024,opts)
            self.occupancy=gl.CreateTexture(512,512,opts)
        end
        if not self.solver or not self.emission or not self.occupancy then
            self:Shutdown();self.failed=true
            Spring.Echo("Neon local detail disabled: "..tostring(reason or "capture allocation failed"))
            return false
        end
        return true
    end
    function self:Refresh(layer,coarseEmission,coarseOccupancy,captureEmission,captureOccupancy)
        self.ready=false
        local domain=self:CameraDomain()
        if not domain or not self:Allocate() then self.domain=nil;return end
        gl.RenderToTexture(self.emission,captureEmission,layer,domain)
        gl.RenderToTexture(self.occupancy,captureOccupancy,layer-1,domain)
        self.solver:Draw(self.emission,self.occupancy,1,(layer-1)*128,layer*128,
            false,domain,coarseEmission,coarseOccupancy)
        self.domain=domain;self.texture=self.solver.unitTexture;self.ready=true
    end
    return self
end
return M
