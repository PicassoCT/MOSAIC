-- Run one independent regression: lua5.1 tests/lua_audit_regressions.lua <case>
local cases = {}
local function noop() end
local function size(t) local n=0; for _ in pairs(t) do n=n+1 end; return n end
local function loadEnv(path, env)
    setmetatable(env, {__index=_G}); env._G=env
    setfenv(assert(loadfile(path)), env)()
    return env
end
local function collateralUI()
    local f={frame=30, actions={}, drawn={}, visits=0, positions=0, missing={}}
    local env={gadget={},GetInfo=function() return {name='test'} end,
        gadgetHandler={IsSyncedCode=function() return false end,
            AddSyncAction=function(_,name,fn) f.actions[name]=fn end},
        Spring={GetGameFrame=function() return f.frame end,GetLocalTeamID=function() return 1 end,
            GetGaiaTeamID=function() return 0 end,GetUnitTeam=function() return 1 end,
            GetAllUnits=function() local t={} for i=1,1000 do t[i]=i end return t end,
            GetUnitPosition=function(id) f.positions=f.positions+1; if not f.missing[id] then return 100,0,100 end end,
            WorldToScreenCoords=function(x,y) return x,y end,Echo=noop},
        gl={Color=noop,Text=function(message) f.drawn[#f.drawn+1]=message end},
        pairs=function(t)
            return function(t,k) local key,value=next(t,k); if key then f.visits=f.visits+1 end; return key,value end,t,nil
        end}
    loadEnv('luarules/gadgets/game_collateral.lua',env)
    env.gadget:Initialize(); f.env=env; f.gadget=env.gadget
    return f
end
cases['collateral-labels']=function()
    local f=collateralUI()
    for i=1,1000 do f.actions.DisplaytAtUnit(nil,i,1,12.75,1,1,1,1) end
    f.gadget:DrawScreenEffects()
    assert(#f.drawn==1000 and f.visits<=1000,'label drawing must scale with labels, not all units times labels')
    f.drawn={}; f.frame=90; f.visits=0; f.positions=0
    f.gadget:DrawScreenEffects()
    assert(#f.drawn==0 and f.positions==0,'expired labels must not query unit positions')
    f.visits=0; f.gadget:DrawScreenEffects()
    assert(f.visits==0,'expired records retained')
    f.actions.DisplaytAtUnit(nil,42,1,8,1,1,1,1)
    f.gadget:UnitDestroyed(42); f.gadget:DrawScreenEffects()
    assert(#f.drawn==0,'destroyed/reused IDs retained old label')
    f.actions.DisplaytAtUnit(nil,43,1,8,1,1,1,1); f.missing[43]=true
    f.gadget:DrawScreenEffects(); f.missing[43]=nil; f.gadget:DrawScreenEffects()
    assert(#f.drawn==0,'vanished unit retained label')
end
cases['collateral-locations']=function()
    local f=collateralUI(); local credit
    local env={gadget={},GG={},UnitDefs={},UnitDefNames={},
        gadgetHandler={IsSyncedCode=function() return true end},
        getGameConfig=function() return {economy={propaganda={serverMultiplier=.1},collateral={houseDestructionMoney=500}}} end,
        getExemptFromRefundTypes=function() return {} end,getCultureUnitModelNames_Dict_DefIDName=function() return {} end,
        getChemTrailInfluencedTypes=function() return {} end,getChemTrailTypes=function() return {} end,
        assertNum=function(n) assert(type(n)=='number') end,
        VFS={Include=function(path)
            if path=='luarules/configs/collateral.lua' then return {collectionIntervalFrames=5} end
            if path=='luarules/gadgets/include/collateral_collection.lua' then
                return function() return {Initialize=noop,Collect=noop,Charge=noop} end
            end
        end},
        Spring={GetGameFrame=function() return f.frame end,GetGaiaTeamID=function() return 0 end,
            GetTeamList=function() return {0,1} end,AreTeamsAllied=function(a,b) return a==b end,
            AddTeamResource=function(_,_,amount) credit=amount end,Echo=noop},
        SendToUnsynced=function(name,uid,...)
            assert(uid==42,'location UID lost in sync message')
            assert(f.actions[name],'location sync action not registered')
            f.actions[name](name,uid,...)
        end}
    loadEnv('luarules/gadgets/game_collateral.lua',env); env.gadget:Initialize()
    env.GG.Bank:TransferToTeam(12.987,1,{uid=42,x=10,y=0,z=20})
    env.gadget:GameFrame(30); assert(credit==12.987,'accounting was rounded')
    f.frame=31; f.gadget:DrawScreenEffects()
    assert(#f.drawn==1 and f.drawn[1]:find('$ 12',1,true),'location message did not draw')
    f.frame=90; f.drawn={}; f.gadget:DrawScreenEffects(); f.visits=0; f.gadget:DrawScreenEffects()
    assert(#f.drawn==0 and f.visits==0,'expired location retained')
    f.actions.DisplayAtLocation(nil,43,10,0,20,1,-12.987,1,1,1)
    f.frame=91; f.gadget:DrawScreenEffects()
    assert(f.drawn[1]:find('$ -12',1,true),'negative location amount lost its sign')
end
cases['flame-vectors']=function()
    local factory=dofile('luaui/widgets_mosaic/include/pyro_flame_collision.lua')
    local a=math.sqrt(.5)
    for _,kind in ipairs({'unit','feature'}) do
        for _,basis in ipairs({
            {{0,0,1},{0,1,0},{1,0,0}},
            {{a,0,a},{0,1,0},{a,0,-a}},
            {{1,0,0},{0,1,0},{0,0,-1}},
            {{0,0,1},{-a,a,0},{a,a,0}},
        }) do
            for face=2,3 do
                local n=basis[face]; local sign=face==2 and 1 or -1
                local nx,ny,nz=n[1]*sign,n[2]*sign,n[3]*sign
                local S={GetGroundHeight=function() return -10000 end,ValidUnitID=function() return true end,
                    TraceRayInDirection=function() return {{10,2,kind}} end}
                local prefix=kind=='unit' and 'GetUnit' or 'GetFeature'
                S[prefix..'Position']=function() return 0,0,0 end
                S[prefix..'CollisionVolumeData']=function() return 20,20,20,0,0,0 end
                S[prefix..'Vectors']=function() return unpack(basis) end
                local hit=factory(S).Trace(1,20*nx,20*ny,20*nz,-nx,-ny,-nz,100,0,true)
                assert(hit and hit.kind==kind,'expected object hit')
                assert(math.abs(hit.normal[1]-nx)<1e-6 and math.abs(hit.normal[2]-ny)<1e-6
                    and math.abs(hit.normal[3]-nz)<1e-6,'rotated surface normal was flattened')
            end
        end
    end
end
cases['neon-los']=function()
    local sent=0
    local env={gadget={},GG={},UnitDefs={[1]={customParams={}}},VFS={Include=noop},
        gadgetHandler={IsSyncedCode=function() return true end},
        Spring={GetGameFrame=function() return 0 end,SetUnitNoDraw=noop,GetAllUnits=function() return {} end,
            UnitScript={CallAsUnit=noop}},getHologramTypes=function() return {[1]=true} end,
        getHologramTypeNames=function() return {[1]='ad'} end,getEngineVersion=function() return 105 end,count=size,
        SendToUnsynced=function(name) if name=='updateUnitNeonLuaDraw' then sent=sent+1 end end}
    loadEnv('luarules/gadgets/gfx_neonHolograms.lua',env)
    local g=env.gadget; g:Initialize(); g:UnitCreated(42,1)
    if g.UnitEnteredLos then g:UnitEnteredLos(42,0,1,1); g:UnitEnteredLos(42,0,2,1) end
    env.GG.VisibleUnitPieces[42]={1,2}; g:GameFrame(1)
    if g.UnitLeftLos then g:UnitLeftLos(42,0,1,1) end
    env.GG.VisibleUnitPieces[42]={1,2,3}; g:GameFrame(2)
    assert(sent==2 and env.NeonHologramUnits[42]==1,'one ally LOS exit stopped global animation')
    g:UnitDestroyed(42,1); assert(not env.NeonHologramUnits[42],'destroyed hologram retained')
end
local function neonRenderer(compile)
    local f={actions={},textures={},nextTexture=0,copies=0,pieces=0,finalized=0}
    local shader={Initialize=function() return compile~=false end,
        ActivateWith=function(_,fn) fn() end,SetUniformInt=noop,SetUniformFloat=noop,
        Finalize=function() f.finalized=f.finalized+1 end}
    local gl=setmetatable({HasExtension=function() return true end,
        CreateTexture=function() f.nextTexture=f.nextTexture+1; local id='tex'..f.nextTexture; f.textures[id]=true; return id end,
        DeleteTexture=function(id) assert(f.textures[id],'invalid/double texture deletion'); f.textures[id]=nil end,
        DeleteTextureFBO=function() error('delete the owned texture, not just its FBO') end,
        CopyToTexture=function() f.copies=f.copies+1 end,
        PushPopMatrix=function(fn) fn() end,UnitPiece=function() f.pieces=f.pieces+1 end}, {__index=function() return noop end})
    local env={gadget={},gl=gl,GL=setmetatable({},{__index=function() return 1 end}),
        UnitDefs={{id=1,name='house_western_hologram_casino',customParams={}}},
        VFS={Include=function() return function() return shader end end,LoadFile=function() return '' end},
        Spring={GetViewGeometry=function() return 1920,1080,0,0 end,Echo=noop,GetGameFrame=function() return 30 end,
            GetGameSeconds=function() return 1 end,GetCameraPosition=function() return 0,0,0 end,
            GetUnitPosition=function() return 0,0,0 end,GetUnitDefID=function() return 1 end,
            UnitRendering={SetUnitLuaDraw=noop},ValidUnitID=function() return true end,GetUnitIsDead=function() return false end,
            GetUnitRulesParam=function() return 0 end,IsUnitInView=function() return true end},
        gadgetHandler={IsSyncedCode=function() return false end,
            AddSyncAction=function(_,name,fn) f.actions[name]=fn end,
            RemoveSyncAction=function(self,name) assert(self and name,'RemoveSyncAction needs its receiver'); f.actions[name]=nil end,
            RemoveGadget=function(_,g) g:Shutdown() end}}
    loadEnv('luarules/gadgets/gfx_neonHolograms.lua',env); f.gadget=env.gadget
    return f
end
cases['neon-copy']=function()
    local f=neonRenderer(); f.gadget:Initialize()
    f.actions.updateUnitNeonLuaDraw(nil,42,1,1,2,3); f.gadget:DrawWorld()
    assert(f.pieces==6,'hologram geometry changed')
    assert(f.copies==0,'active shader performs unused full-screen framebuffer copy')
end
cases['neon-cleanup']=function()
    local f=neonRenderer(); f.gadget:Initialize()
    assert(size(f.textures)==2 and f.nextTexture==2,'initialization allocated textures twice')
    f.gadget:ViewResize(); assert(size(f.textures)==2 and f.nextTexture==4,'resize leaked textures')
    f.gadget:Shutdown(); f.gadget:Shutdown()
    assert(size(f.textures)==0 and size(f.actions)==0 and f.finalized==1,'shutdown leaked/double-freed resources')
    f.gadget:Initialize(); f.gadget:Shutdown()
    assert(size(f.textures)==0 and f.finalized==2,'reinitialization leaked resources')
    local failed=neonRenderer(false); failed.gadget:Initialize()
    assert(size(failed.textures)==0 and size(failed.actions)==0,'shader compile failure leaked resources')
    local early=neonRenderer(); early.gadget:Shutdown()
    assert(early.finalized==0,'shutdown before initialize finalized nonexistent shader')
end
cases['team-platter']=function()
    local visible,selected,defs={42},{42},{[42]=1}
    local draws,queries,scans={},{},0
    local names=setmetatable({},{__index=function(t,k) local v={id=1000+size(t)};rawset(t,k,v);return v end})
    local S=setmetatable({GetGaiaTeamID=function() return 0 end,GetTimer=function() return 0 end,
        GetAllUnits=function() error('platter scans all units') end,GetVisibleUnits=function() return visible end,
        GetSelectedUnits=function() return selected end,IsUnitVisible=function() return true end,
        GetUnitTeam=function() return 7 end,GetUnitDefID=function(id) queries[id]=(queries[id] or 0)+1;return defs[id] end,
        GetUnitDefDimensions=function(id) return {radius=id*10} end,GetTeamColor=function() return .2,.3,.4 end,
        GetPlayerList=function() return {8} end,GetMyPlayerID=function() return 8 end}, {__index=function() return noop end})
    local env={widget={},WG={},Spring=S,UnitDefNames=names,UnitDefs={[1]={canFly=true},[2]={canFly=true}},
        GL={},gl=setmetatable({DrawListAtUnit=function(id,_,_,radius) draws[#draws+1]={id,radius} end},{__index=function() return noop end}),
        ipairs=function(t) if t==selected then scans=scans+1 end;return ipairs(t) end}
    loadEnv('luaui/widgets_mosaic/gui_team_platter.lua',env)
    env.widget:DrawWorldPreUnit()
    assert(env.WG.UnitSelectedBy[42]==8 and not env.WG.UnitSelectedBy[7],'selection attribution used a team ID')
    assert(#draws==3 and draws[1][2]==10,'visible/selected platter geometry changed')
    env.widget:UnitDestroyed(42); defs[42]=2; selected={}; draws={}
    env.widget:DrawWorldPreUnit()
    assert(draws[1][2]==20 and not env.WG.UnitSelectedBy[42],'reused unit ID kept cached definition/owner')
    visible={}; selected={}; for i=1,1000 do visible[i]=i+100; defs[i+100]=1; selected[i]=i+100 end
    scans=0; env.widget:DrawWorldPreUnit()
    assert(scans<=2,'selected units rescanned for each visible unit')
end
local function scheduler(path)
    local f={frame=100}
    local env={gadget={},GG={},gadgetHandler={IsSyncedCode=function() return true end},
        Spring={GetGameFrame=function() return f.frame end}}
    loadEnv(path,env); f.env=env
    function f:step(frame) self.frame=frame;env.gadget:GameFrame(frame) end
    return f
end
cases['eventstream']=function()
    local f=scheduler('luarules/gadgets/game_eventstream.lua'); local stream=f.env.GG.EventStream; local calls={}
    local id=stream:CreateEvent(function() error('cancelled callback executed') end,{},110)
    assert(id==0 and stream:DeactivateEvent(id) and not stream:DeactivateEvent(id),'cancellation did not remove event 0')
    assert(not stream:DeactivateEvent('CreateEvent') and type(stream.CreateEvent)=='function','invalid cancellation removed API')
    f:step(110)
    local recurring=stream:CreateEvent(function(id,frame,pack)
        calls[#calls+1]=frame; pack.n=pack.n+1
        if pack.n==3 then return nil end
        return frame,pack
    end,{n=0},111)
    f:step(111); f:step(112); f:step(113)
    assert(#calls==3 and not stream[recurring],'same-frame reschedule orphaned event')
    local selfCancelled=stream:CreateEvent(function(id,frame) assert(stream:DeactivateEvent(id)); return frame+1,{} end,{},114)
    f:step(114); f:step(115); assert(not stream[selfCancelled],'self-cancelled event revived')
    local order={}
    stream:CreateEvent(function()
        order[#order+1]='first'
        stream:CreateEvent(function() order[#order+1]='child' end,{},116)
    end,{},116)
    stream:CreateEvent(function() order[#order+1]='second' end,{},116)
    f:step(116); assert(table.concat(order,',')=='first,second','dispatch order changed')
    f:step(117); assert(table.concat(order,',')=='first,second,child','callback-created event was lost')
    local ran=0; stream:CreateEvent(function() ran=ran+1 end,{},100); f:step(118)
    assert(ran==1,'past start frame was stranded')
    stream:CreateEvent(function() ran=ran+1 end,{},119.5); f:step(119); assert(ran==1);f:step(120);assert(ran==2)
    for _,invalid in ipairs({math.huge,-math.huge,'bad'}) do
        assert(not pcall(stream.CreateEvent,stream,noop,{},invalid),'invalid frame accepted')
    end
    assert(not pcall(stream.CreateEvent,stream,noop,{},0/0),'NaN frame accepted')
    local victim
    stream:CreateEvent(function() assert(stream:DeactivateEvent(victim)) end,{},121)
    victim=stream:CreateEvent(function() error('cancelled sibling executed') end,{},121)
    stream:CreateEvent(function() ran=ran+1 end,{},121)
    f:step(121); assert(ran==3,'cancellation skipped an unrelated sibling')
end
cases['delayed-code']=function()
    local f=scheduler('luarules/gadgets/game_delayedCodeExecution.lua'); local calls={}
    local function callback(pack) calls[#calls+1]=pack.name end
    f.env.GG.ExecuteDelayed:PushCode(function(pack)
        callback(pack);f.env.GG.ExecuteDelayed:PushCode(callback,{name='child'})
    end,{name='first'})
    f.env.GG.ExecuteDelayed:PushCode(callback,{name='second'})
    f:step(100); assert(#calls==0,'same-frame callback ran early')
    f:step(110); assert(table.concat(calls,',')=='first,second','queue entry callback/arguments were lost')
    f:step(120); assert(table.concat(calls,',')=='first,second,child','reentrant queue was lost')
    f:step(130); assert(#calls==3,'callbacks repeated')
end
cases['blackhawk']=function()
    local function lowerkeys(t) local out={} for k,v in pairs(t) do out[type(k)=='string' and k:lower() or k]=v end return out end
    local env={lowerkeys=lowerkeys,Spring={GetModOptions=function() return {} end},
        VFS={Include=function(path) if path=='gamedata/system.lua' then return {lowerkeys=lowerkeys} else return {} end end}}
    setmetatable(env,{__index=_G})
    local file=assert(io.open('gamedata/unitdefs_pre.lua')); local source=file:read('*a');file:close()
    source=source:sub(1,assert(source:find('-- Include Base Classes',1,true))-1)
    setfenv(assert(loadstring(source)),env)()
    env.VTOL=setfenv(assert(loadfile('baseclasses/units/AirDrones.lua')),env)().VTOL
    local unit=setfenv(assert(loadfile('units/shared/chasis/air/copter/air_copter_blackhawk.lua')),env)().air_copter_blackhawk
    assert(unit.customparams.normaltex=='unittextures/air_copter_blackhawk_normal.dds','Blackhawk normal map overwritten')
    assert(unit.customparams.crashable==1 and unit.customparams.baseclass=='AIRCRAFT','inherited/custom metadata lost')
    assert(unit.maxdamage==1950 and unit.buildcostmetal==1400,'unit balance changed')
end
local syntaxPaths={['protagon-syntax']='gamedata/protagon.lua',
    ['chili-demo-syntax']='luaui/widgets_mosaic/chili/gui_chiliguidemo.lua',['tetris-syntax']='scripts/tetris.lua'}
for name,path in pairs(syntaxPaths) do
    local sourcePath=path
    cases[name]=function() assert(loadfile(sourcePath)) end
end
local name=assert(arg and arg[1],'specify a regression case')
assert(cases[name],'unknown case: '..name)()
print('PASS: '..name)
