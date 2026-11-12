-- Run through run.sh -- lua tests/house_icon_holograms_lifecycle.lua
-- Use the real renderer and mesh with Recoil's actual icon API spelling.
local function read(path)
    local f = assert(io.open(path)); local s = f:read('*a'); f:close(); return s
end
local source = read('luarules/gadgets/gfx_house_icon_holograms.lua')
local function fixture(options)
    options = options or {}
    local s = {icon=true, drawIcon=true, enabled=1, los=true, draws=0,
        vertices=0, lists=0, deleted=0, messages={}, grids={}, masks=0, contours=0,
        textures=0, deletedTextures=0, fbos=0, deletedFBOs=0, shaders=0, deletedShaders=0,
        width=640, height=480, originX=17, originY=23}
    local function noop() end
    local spring = {
        UnitIconSetDraw=function(id, draw) assert(id==7); s.drawIcon=draw end,
        IsUnitIcon=function() return s.icon end,
        ValidUnitID=function() return true end,
        GetAllUnits=function() return {7} end,
        GetUnitDefID=function() return 1 end,
        GetConfigInt=function() return s.enabled end,
        IsGUIHidden=function() return s.hidden end,
        GetSpectatingState=function() return false,false end,
        GetMyAllyTeamID=function() return 0 end,
        IsUnitInView=function() return true end,
        GetUnitIsCloaked=function() return s.cloaked end,
        GetUnitNoDraw=function() return false end,
        GetUnitLosState=function() return {los=s.los} end,
        GetViewGeometry=function() return s.width,s.height,s.originX,s.originY end,
        GetGameSeconds=function() return 1 end,
        GetUnitBasePosition=function() return 0,0,0 end,
        GetUnitVectors=function() return {0,0,1},{0,1,0},{-1,0,0} end,
        Echo=function(message) s.messages[#s.messages+1]=message end,
    }
    if options.missingAPI then spring.UnitIconSetDraw=nil end
    local gl = setmetatable({
        CreateShader=function(spec)
            assert(spec.vertex:find('gl_Position') and spec.fragment:find('fragColor'))
            s.shaderAttempted=true
            s.shaders=s.shaders+1
            if not options.shaderFailure and not (options.contourFailure and s.shaders==2) then return s.shaders end
        end,
        GetShaderLog=function() return 'test shader failure' end,
        DeleteShader=function() s.deletedShaders=s.deletedShaders+1 end,
        GetUniformLocation=function(_,name) return name end,
        Uniform=function(name,value,x)
            if name=='maskPass' then s.pass=value end
            if name=='viewportOrigin' then assert(value==s.originX and x==s.originY) end
        end,
        CreateTexture=function(w,h)
            assert(w==s.width and h==s.height)
            if options.textureFailure then return nil end
            s.textures=s.textures+1; return s.textures
        end,
        DeleteTexture=function() s.deletedTextures=s.deletedTextures+1 end,
        CreateFBO=function(spec)
            assert(spec.color0 and spec.depth)
            s.fbos=s.fbos+1; return s.fbos
        end,
        IsValidFBO=function() return not options.fboFailure end,
        DeleteFBO=function() s.deletedFBOs=s.deletedFBOs+1 end,
        CopyToTexture=function(_,dx,dy,x,y,w,h)
            assert(dx==0 and dy==0 and x==s.originX and y==s.originY)
            assert(w==s.width and h==s.height)
            s.copied=true
        end,
        ActiveFBO=function(_,fn,...)
            assert(s.copied, 'copy scene depth before mask rendering')
            s.inMask=true; fn(...); s.inMask=false
        end,
        Clear=function(bits) assert(s.inMask and bits==1, 'never clear copied scene depth') end,
        DepthMask=function(write)
            assert(not write or s.inMask, 'never write to the main scene depth')
        end,
        TexRect=function() s.contours=s.contours+1 end,
        CreateList=function(fn) fn(); s.lists=s.lists+1; return s.lists end,
        DeleteList=function() s.deleted=s.deleted+1 end,
        BeginEnd=function(_,fn,...) fn(...) end,
        Vertex=function() s.vertices=s.vertices+1 end,
        CallList=function()
            if s.pass==1 then assert(s.inMask); s.masks=s.masks+1
            else assert(not s.inMask); s.draws=s.draws+1 end
        end,
    }, {__index=function() return noop end})
    if options.missingContourAPI then gl.CreateFBO=false end
    local env=setmetatable({gadget={}, Spring=spring, gl=gl,
        GL={QUADS=7,COLOR_BUFFER_BIT=1}, GG={HouseIconShadowGrids=s.grids},
        UnitDefs={[1]={name='house_western0'}},
        VFS={Include=dofile, LoadFile=read},
        gadgetHandler={IsSyncedCode=function() return false end,
            RemoveGadget=function() s.removed=true end},
    }, {__index=_G})
    local f
    if setfenv then f=assert(loadstring(source)); setfenv(f,env)
    else f=assert(load(source,'house icon renderer','t',env)) end
    f(); s.gadget=env.gadget; s.gadget:Initialize()
    function s:frame() self.gadget:DrawWorldPreUnit(); self.gadget:DrawWorld() end
    function s:geometry()
        self.grids[7]={dx=10,dy=10,dz=10,columns={{x=0,z=0,base=0,mask=1}}}
    end
    return s
end

local s=fixture()
assert(s.shaderAttempted and not s.removed, 'renderer must load with UnitIconSetDraw')
s:frame()
assert(s.drawIcon and s.draws==0, 'keep regular icon while geometry is unavailable')
s:geometry(); s:frame()
assert(not s.drawIcon and s.draws==1 and s.vertices==24, 'zoomed-out house must draw its voxel mesh')
s:frame()
assert(not s.drawIcon and s.draws==2 and s.lists==1, 'retain mesh and icon suppression across frames')
s.icon=false; s:frame()
assert(s.drawIcon and s.draws==2, 'zooming in must restore ordinary rendering')
s.icon=true; s:frame()
assert(not s.drawIcon and s.draws==3, 'zooming out must reactivate hologram')
s.enabled=0; s:frame()
assert(s.drawIcon and s.draws==3, 'option off must restore icon')
s.enabled=1; s:frame(); s.hidden=true; s:frame()
assert(s.drawIcon and s.draws==4, 'hidden GUI must stop the hologram')
s.hidden=false; s:frame(); s.los=false; s:frame()
assert(s.drawIcon and s.draws==5, 'LOS loss must stop the hologram')
s.los=true; s:frame(); s.cloaked=true; s:frame()
assert(s.drawIcon and s.draws==6, 'cloaking must stop the hologram')
s.cloaked=false; s:frame(); s:geometry(); s:frame()
assert(s.lists==2 and s.deleted==1, 'changed geometry must replace the cached mesh')
assert(s.masks==s.draws and s.contours==s.draws, 'each visible frame adds a mask and contour')
assert(s.textures==2 and s.fbos==1, 'reuse targets between frames')
s.gadget:ViewResize(); s.width=800; s.height=600; s:frame()
assert(s.textures==4 and s.deletedTextures==2 and s.deletedFBOs==1, 'resize releases old targets')
s.gadget:Shutdown()
assert(s.deletedTextures==s.textures and s.deletedFBOs==s.fbos and s.deletedShaders==2)
assert(s.drawIcon and s.deleted==2, 'shutdown must restore icon and release meshes')

local missing=fixture({missingAPI=true})
assert(missing.removed and not missing.shaderAttempted and missing.drawIcon)
assert(missing.messages[1]:find('Spring.UnitIconSetDraw',1,true), 'missing API must produce a diagnostic')
local failed=fixture({shaderFailure=true})
assert(failed.removed and failed.drawIcon and failed.messages[1]:find('Shader failed',1,true))
for _,option in ipairs({'missingContourAPI','contourFailure','textureFailure','fboFailure'}) do
    local fallback=fixture({[option]=true})
    fallback:geometry(); fallback:frame(); fallback:frame()
    assert(not fallback.removed and not fallback.drawIcon and fallback.draws==2, option..': retain original material')
    assert(fallback.masks==0 and fallback.contours==0, option..': skip unavailable contour')
    if option=='fboFailure' then
        assert(fallback.fbos==1 and fallback.deletedFBOs==1, 'do not retry failed allocation every frame')
    end
    fallback.gadget:Shutdown()
    assert(fallback.drawIcon and fallback.deletedTextures==fallback.textures)
end
local recoveryOptions={fboFailure=true}
local recovery=fixture(recoveryOptions)
recovery:geometry(); recovery:frame()
recoveryOptions.fboFailure=false
recovery.gadget:ViewResize(); recovery:frame()
assert(recovery.masks==1 and recovery.contours==1 and recovery.draws==2, 'resize retries a failed contour allocation')
recovery.gadget:Shutdown()
print('house icon hologram lifecycle: passed (two passes, fallback, resize, cleanup)')
