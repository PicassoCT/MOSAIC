-- Run from repo root with Lua 5.4 (or lupa). GL and engine calls are mocked.
local function read(path) local f=assert(io.open(path));local s=f:read('*a');f:close();return s end
local source=read('luaui/widgets_mosaic/include/radiance_taper.lua')
local function exercise(failure)
    local allocated,deleted,bound,uniforms={},{},{},{}
    local serial,passes,draws,selected,visible,dead=0,0,0,42,true,false
    local function alloc(kind)
        serial=serial+1
        if serial==failure then return nil end
        local id=kind..serial;allocated[id]=true;return id
    end
    local function delete(id) assert(allocated[id] and not deleted[id]);deleted[id]=true end
    local gl={
        CreateShader=function() return alloc('shader') end,DeleteShader=delete,
        CreateTexture=function(w,h,opts) assert(w==256 and h==256);return alloc('texture') end,DeleteTexture=delete,
        CreateFBO=function() return alloc('fbo') end,DeleteFBO=delete,
        IsValidFBO=function() return failure~='incomplete' end,
        CreateList=function() return alloc('list') end,DeleteList=delete,
        GetShaderLog=function() return 'fixture failure' end,
        GetUniformLocation=function(_,name) return name end,
        Uniform=function(name,...) uniforms[name]={...} end,
        Texture=function(slot,name) bound[slot]=name;return failure~='material' or slot~=1 end,
        ActiveFBO=function(_,fn) passes=passes+1;fn() end,
        Unit=function(id,raw,lod,noLua)
            assert(id==42 and raw and lod==-1 and noLua,'raw draw/Lua material recursion')
        end,
        CallList=function() draws=draws+1 end,
    }
    setmetatable(gl,{__index=function() return function() end end})
    local env=setmetatable({gl=gl,GL={},Game={mapSizeX=8192,mapSizeZ=4096},UnitDefs={[7]={name='house_asian1'},[8]={name='civilian_arab0'}},
        Spring={Echo=function() end,GetSelectedUnits=function() return {selected} end,
            ValidUnitID=function(id) return id~=nil end,GetUnitIsDead=function() return dead end,
            GetUnitDefID=function(id) return id==42 and 7 or 8 end,
            GetUnitLosState=function() return {los=visible} end,GetSpectatingState=function() return false,false end,
            GetUnitPosition=function() return 400,10,600 end},
        VFS={LoadFile=function(path) return read(path) end}}, {__index=_G})
    local obj=assert(load(source,'taper','t',env))()()
    assert(serial==0 and not obj.enabled)
    obj:Refresh();obj:Draw(0,128,nil,1024,1);assert(serial==0 and draws==0)
    selected=99;obj:TextCommand('radiancetaper on');assert(not obj.enabled)
    selected=42;obj:TextCommand('radiancetaper on');assert(obj.enabled and not obj.ready and serial==0)
    obj:Refresh()
    if failure then
        assert(not obj.ready and not obj.enabled)
    else
        assert(obj.ready and passes==1)
        obj:Refresh();assert(passes==1,'capture cache not reused')
        obj:Draw(0,128,nil,1024,0);assert(draws==0)
        obj:Draw(0,128,nil,1024,.5);assert(draws==1 and uniforms.emissionStrength[1]==.075)
        obj:Draw(256,384,{x=100,z=200,span=1024},1024,1)
        assert(uniforms.heightRange[1]==256 and uniforms.domainOrigin[2]==200 and uniforms.domainSize[1]==1024)
        assert(not bound[0] and not bound[1])
        visible=false;obj:Refresh();obj:Draw(0,128,nil,1024,1);assert(not obj.ready and draws==2,'stale light after LOS loss')
        visible=true;obj:Refresh();assert(passes==2)
        obj:TextCommand('radiancetaper taper 2');assert(obj.taper==.4 and not obj.ready)
        obj:Refresh();assert(passes==3)
        obj:TextCommand('radiancetaper off');obj:Draw(0,128,nil,1024,1);assert(draws==2)
        obj:TextCommand('radiancetaper on 42');obj:Refresh();assert(passes==4)
        dead=true;obj:Refresh();assert(not obj.ready)
        assert(not obj:TextCommand('radiancetaperother on'))
    end
    obj:Shutdown();obj:Shutdown()
    for id in pairs(allocated) do assert(deleted[id],'leaked '..id) end
end
exercise()
for i=1,7 do exercise(i) end
exercise('incomplete');exercise('material')
print('PASS: default off, selected standalone restriction, lazy allocation, raw draw, capture reuse, global/local injection, intensity, LOS/death invalidation, commands, failure cleanup')
