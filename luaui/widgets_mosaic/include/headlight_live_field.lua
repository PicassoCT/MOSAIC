-- Direct headlight footprints only: no cascade solves or scene copies here.
-- Two fixed 512-square RGBA8 targets (2 MiB total). Near field every draw;
-- whole-map field at 10 Hz. The owner supplies the existing cone capture.
return function()
    local self={ready=false,localReady=false,enabled=true,age=1,size=512}
    function self:Shutdown()
        self.ready,self.localReady=false,false
        for _,key in ipairs({'texture','localTexture'}) do
            if self[key] then gl.DeleteTexture(self[key]);self[key]=nil end
        end
    end
    local opts={format=GL.RGBA8 or 0x8058,min_filter=GL.LINEAR,mag_filter=GL.LINEAR,
        wrap_s=GL.CLAMP_TO_EDGE,wrap_t=GL.CLAMP_TO_EDGE,fbo=true}
    self.texture=gl.CreateTexture(self.size,self.size,opts)
    self.localTexture=gl.CreateTexture(self.size,self.size,opts)
    if not self.texture or not self.localTexture then self:Shutdown();return nil end
    function self:Update(dt) self.age=self.age+dt end
    local function draw(capture,bottom,top,domain)
        gl.Clear(GL.COLOR_BUFFER_BIT,0,0,0,0)
        gl.DepthTest(false);gl.DepthMask(false);gl.Culling(false);gl.Blending(false)
        gl.Color(1,1,1,1)
        gl.MatrixMode(GL.PROJECTION);gl.PushMatrix();gl.LoadIdentity()
        gl.Ortho(domain and domain.x or 0,domain and domain.x+domain.span or Game.mapSizeX,
            domain and domain.z or 0,domain and domain.z+domain.span or Game.mapSizeZ,-100000,100000)
        gl.MatrixMode(GL.MODELVIEW);gl.PushMatrix();gl.LoadIdentity();gl.Rotate(-90,1,0,0)
        capture(bottom,top,1) -- full direct intensity; slow injection uses 0.08
        gl.PopMatrix();gl.MatrixMode(GL.PROJECTION);gl.PopMatrix();gl.MatrixMode(GL.MODELVIEW)
        gl.UseShader(0);gl.Texture(0,false);gl.Blending(false);gl.Color(1,1,1,1)
    end
    function self:Draw(capture,bottom,top,domain,enabled)
        if not self.enabled or not enabled or not capture then
            self.ready,self.localReady=false,false
            self.age=1
            return
        end
        -- Changes of provider or height must never reuse an unrelated field.
        if self.capture~=capture or self.bottom~=bottom or self.top~=top then self.age=1 end
        self.capture,self.bottom,self.top=capture,bottom,top
        if self.age>=0.1 or not self.ready then
            gl.RenderToTexture(self.texture,draw,capture,bottom,top,nil)
            self.age=0;self.ready=true
        end
        self.localReady=false
        if domain then
            gl.RenderToTexture(self.localTexture,draw,capture,bottom,top,domain)
            self.domain=domain;self.localReady=true
        end
    end
    return self
end
