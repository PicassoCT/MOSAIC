local function read(path)local f=assert(io.open(path));local s=f:read('*a');f:close();return s end
local source=read('luaui/widgets_mosaic/include/window_lighting.lua')
local function exercise(failure,chunked)
    local serial,draws,readbacks,matrices=0,0,0,0
    local allocated,deleted,bound,uniforms={},{},{},{}
    local revisions={[42]=1,[43]=1};local visible={[42]=true,[43]=true}
    local all={42,99};local selected=42;local activeFBO
    local sizes={}
    local function alloc(kind)
        serial=serial+1;if serial==failure then return end
        local id=kind..serial;allocated[id]=true;return id
    end
    local function delete(id)assert(allocated[id] and not deleted[id],'bad deletion '..tostring(id));deleted[id]=true end
    local gl={
        CreateShader=function()return alloc('shader')end,DeleteShader=delete,
        CreateTexture=function(w,h)local t=alloc('texture');if t then sizes[t]={w,h}end;return t end,DeleteTexture=delete,
        CreateList=function()return alloc('list')end,DeleteList=delete,
        CreateFBO=function(desc)local f=alloc('fbo');if f then sizes[f]=desc end;return f end,DeleteFBO=delete,
        IsValidFBO=function()return failure~='fbo'end,
        GetShaderLog=function()return 'fixture failure'end,
        GetUniformLocation=function(_,name)return name end,
        Uniform=function(name,...)uniforms[name]={...}end,UniformInt=function(name,...)uniforms[name]={...}end,
        Texture=function(slot,t)bound[slot]=t;return failure~='material' or t~='%7:1'end,
        PushMatrix=function()matrices=matrices+1 end,PopMatrix=function()matrices=matrices-1;assert(matrices>=0)end,
        ActiveFBO=function(f,callback)local before=activeFBO;activeFBO=f;callback();activeFBO=before end,
        RenderToTexture=function(t,callback)
            for _,b in pairs(bound) do assert(b~=t,'framebuffer feedback')end
            local before=activeFBO;activeFBO=t;callback();activeFBO=before
        end,
        Unit=function(id,raw,lod,noLua)
            assert((id==42 or id==43) and raw and lod==-1 and noLua)
            if failure=='draw' then error('draw failure')end
            draws=draws+1
        end,
        BeginEnd=function(_,fn)fn()end,
        ReadPixels=function(_,__,w,h)
            readbacks=readbacks+1;if failure=='read' then return end
            local p={};for x=1,w do p[x]={} end
            for y=0,h-1 do for x=0,w-1 do
                local pixel=w==2 and {x,y,0,1} or w==256 and {320+x,10+y*6,520+(x%64)*2,1} or {0,0,0,0}
                if chunked then local i=y*w+x;p[math.floor(i/h)+1][i%h+1]=pixel
                else p[x+1][y+1]=pixel end
            end end
            return p
        end,
        GetViewSizes=function()return 1280,720 end,
    }
    setmetatable(gl,{__index=function()return function()end end})
    local env=setmetatable({gl=gl,GL={},Game={mapSizeX=2048,mapSizeZ=2048},UnitDefs={
        [7]={name='house_asian1'},[8]={name='house_asian3'},[9]={name='civilian_arab0'}},Spring={
        Echo=function()end,ValidUnitID=function(id)return id~=nil end,GetUnitIsDead=function()return false end,
        GetUnitDefID=function(id)return id==42 and 7 or id==43 and 8 or 9 end,
        GetUnitPosition=function(id)return id==42 and 400 or 600,10,600 end,
        GetUnitDefDimensions=function()error('hidden-variant bounds must never size facade capture')end,
        GetUnitTransformMatrix=function(id)return 1,0,0,0,0,1,0,0,0,0,1,0,id==42 and 400 or 600,10,600,1 end,
        GetUnitPieceMatrix=function()return 1,0,0,0,0,1,0,0,0,0,1,0,0,0,0,1 end,
        GetUnitPieceInfo=function()return {min={-80,0,-80},max={180,400,80}}end,
        GetUnitLosState=function(id)return {los=visible[id]}end,GetSpectatingState=function()return false,false end,
        GetUnitRulesParam=function(id,key)
            if key=='mosaic_window_revision' then return revisions[id]end
            if key=='mosaic_window_piece_count' or key=='mosaic_window_piece_1' then return 1 end
        end,GetAllUnits=function()return all end,
        GetSelectedUnits=function()return {selected}end,GetCameraPosition=function()return 400,100,600 end,
        GetGroundHeight=function()return 10 end,
    }},{__index=_G})
    env.VFS={LoadFile=read,Include=function(path)return assert(load(read(path),path,'t',env))()end}
    local obj=assert(load(source,'window','t',env))()()
    local originalRefresh=obj.Refresh
    function obj:Refresh(blockers,changed,intensity)
        originalRefresh(self,blockers,changed,intensity)
        for i=1,16 do self:Step()end
        originalRefresh(self,blockers,false,intensity)
    end
    assert(obj.enabled and obj.automatic and obj.test and serial==0)
    obj:TextCommand('windowlight off');obj:Refresh({},false,1);assert(serial==0 and not obj.ready)
    obj:TextCommand('windowlight auto')
    revisions[42]=0;obj:Refresh({},false,1);assert(serial==0,'captured construction icon')
    revisions[42]=1
    local blockers={};for i=1,16 do blockers[i]='occupancy'..i end
    if not failure then
        originalRefresh(obj,blockers,false,0)
        assert(not obj.ready and obj.records[42].bakeStep==1,'partial bake was exposed or not chunked')
    end
    obj:Refresh(blockers,false,0)
    local firstAllocations=serial
    if failure then assert(not obj.enabled and not obj.ready,'failure did not disable prototype')
    else
        assert(obj.ready and obj.records[42].captured and #obj.units==1)
        assert(obj.records[42].x==450 and obj.records[42].span<300,'visible piece bounds not used')
        assert(obj.records[42].y<10 and obj.records[42].height<500,'hidden model bounds retained')
        assert(draws==8,'expected one four-side capture plus four wall bands')
        assert(obj.records[42].litPixels==64*256,'capture diagnostics did not count source pixels')
        local previousReads,previousDraws=readbacks,draws
        obj:Update(1);obj:Refresh(blockers,false,0)
        assert(readbacks==previousReads and draws==previousDraws,'static cache recaptured geometry')
        assert(obj:GetDebugPosition(42)==400 and not obj:GetDebugPosition(99))
        obj:TextCommand('windowlight debug on');obj:DrawWorld();obj:DrawScreen();assert(draws==previousDraws+1)
        obj:TextCommand('windowlight debug off')
        obj:TextCommand('windowlight status');obj:Refresh(blockers,false,1)
        assert(obj.enabled and not obj.report,'status readback failed or remained queued')
        all={42,43,99};obj:Refresh(blockers,false,1);obj:Refresh(blockers,false,1)
        assert(obj.records[43].captured and obj.records[43].fieldGeneration==obj.generation,'second standalone missing')
        assert(#obj.units==2)
        local oldGeneration=obj.generation
        obj:TextCommand('windowlight test off');obj:Refresh(blockers,true,0);assert(not obj.ready,'daylight remained on')
        assert(obj.generation>oldGeneration,'daylight lost blocker invalidation')
        obj:TextCommand('windowlight test on');obj:Refresh(blockers,false,0);assert(obj.ready)
        oldGeneration=obj.generation
        obj:TextCommand('windowlight off');obj:Refresh(blockers,true,0)
        assert(obj.generation>oldGeneration,'disabled light lost blocker invalidation')
        obj:TextCommand('windowlight auto');obj:Refresh(blockers,false,0);obj:Refresh(blockers,false,0)
        assert(obj.ready and obj.records[42].fieldGeneration==obj.generation,'old shadow field reused after enabling')
        local before=readbacks
        obj:Refresh(blockers,true,1);assert(readbacks==before,'occlusion change recaptured sources')
        revisions[42]=-2;obj:Refresh(blockers,false,1);assert(not obj.records[42],'hidden building retained light')
        revisions[42]=3;obj:Refresh(blockers,false,1);assert(obj.records[42].revision==3,'reshown model failed to recapture')
        visible[42]=false;obj:Refresh(blockers,false,1);assert(not obj.records[42],'LOS loss retained sources')
        selected=43;obj:TextCommand('windowlight on');obj:Refresh(blockers,false,1)
        assert(not obj.automatic and obj.focusID==43 and #obj.units==1)
        obj:TextCommand('windowlight range 128');assert(not next(obj.records),'range change kept stale field bounds')
        obj:Refresh(blockers,false,1);assert(obj.records[43])
        obj:TerrainChanged();assert(obj.terrainDirty and not obj.ready)
        obj:Refresh(blockers,false,1);assert(obj.ready and not obj.terrainDirty)
        local getParam=env.Spring.GetUnitRulesParam
        env.Spring.GetUnitRulesParam=function(id,key)
            if key=='mosaic_window_piece_count' then return nil end
            return getParam(id,key)
        end
        obj:Invalidate(43);obj:Refresh(blockers,false,1)
        assert(obj.enabled and obj.records[43].failed and not obj.ready,'missing piece metadata was hidden')
        obj:TextCommand('windowlight debug on');obj:DrawWorld();obj:DrawScreen()
        env.Spring.GetUnitRulesParam=getParam
        obj:TextCommand('windowlight rebuild');obj:Refresh(blockers,false,1);assert(obj.ready)
        assert(not obj:TextCommand('radiancetaper on'),'removed taper command still active')
        obj:TextCommand('windowlight off');assert(not obj.ready)
    end
    obj:Shutdown();obj:Shutdown()
    assert(matrices==0,'unbalanced GL matrix stack')
    for id in pairs(allocated) do assert(deleted[id],'leaked '..id)end
    return firstAllocations
end
local count=exercise(nil,true);exercise(nil,false)
for i=1,count do exercise(i,true) end
for _,failure in ipairs({'fbo','read','material','draw'}) do exercise(failure,true) end
print('PASS: two standalone types, both ReadPixels layouts, construction gating, static reuse, visibility revisions, LOS cleanup, day/night, direct cache invalidation, GL cleanup and every allocation failure')
