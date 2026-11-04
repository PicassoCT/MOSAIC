-- Lua 5.1+: distance lifecycle, native script animation, and shared neon protocol.
unpack = unpack or table.unpack
local catalog = dofile('scripts/lib_truck_parade_payloads.lua')
local art = dofile('luarules/configs/parade_hologram_decorations.lua')
local ghosts = dofile('luarules/configs/parade_ghost_parts.lua')
local config = dofile('luarules/configs/parade_hologram_spawning.lua')
local factory = dofile('luarules/gadgets/include/parade_hologram_spawning.lua')
local function loadEnv(path, env)
    setmetatable(env, {__index=_G})
    if setfenv then local f=assert(loadfile(path)); setfenv(f,env); return f() end
    return assert(loadfile(path,'t',env))()
end
local function check(name, test) test(); print('PASS: '..name) end
local function size(t) local n=0; for _ in pairs(t) do n=n+1 end; return n end
local function fixture()
    local f={nextID=100,created={},destroyed={},positions={[1]={500,0,500}},
        alive={[1]=true,[2]=true},teams={[1]=0,[2]=0},parents={[2]=1},variants={[2]=1},
        blocked=false,ground=0,accept=true}
    local G={CityParade={phase='touring',vehicles={[1]={payload=2}}}}
    local S={GetGaiaTeamID=function() return 0 end,
        ValidUnitID=function(id) return f.alive[id]~=nil end,
        GetUnitIsDead=function(id) return not f.alive[id] end,
        GetUnitTeam=function(id) return f.teams[id] end,
        GetUnitTransporter=function(id) return f.parents[id] end,
        GetUnitRulesParam=function(id,key) assert(key=='city_parade_variant'); return f.variants[id] end,
        GetUnitPosition=function(id) return unpack(f.positions[id]) end,
        GetUnitVectors=function() return {0,0,1},{0,1,0},{1,0,0} end,
        GetGroundHeight=function() return f.ground end,
        GetUnitsInCylinder=function() return f.blocked and {99} or {} end,
        GetUnitBlocking=function() return true end,
        CreateUnit=function(name,x,y,z,facing,team)
            assert(name=='paradehologram' and team==0)
            f.nextID=f.nextID+1; local id=f.nextID
            f.alive[id],f.teams[id],f.positions[id]=true,team,{x,y,z}
            f.created[#f.created+1]=id; return id
        end,
        DestroyUnit=function(id,selfd,reclaimed)
            assert(not selfd and reclaimed and G.DiedPeacefully[id])
            f.alive[id]=false; f.destroyed[#f.destroyed+1]=id
        end,
        UnitScript={GetScriptEnv=function(id) return {SetParadeHologram=function(glyph,yaw)
            f.glyph,f.yaw=glyph,yaw; return f.accept
        end, SetParadeGhost=function(body,face,mask,yaw)
            f.ghost={body=body,face=face,mask=mask}; f.yaw=yaw; return f.accept
        end} end, CallAsUnit=function(id,fn,...) return fn(...) end}}
    local c={}; for k,v in pairs(config) do c[k]=v end
    f.controller=factory.New(S,G,{mapSizeX=4096,mapSizeZ=4096},c,catalog,art,ghosts)
    f.S,f.G,f.config=S,G,c
    return f
end

check('every float retains its original valid animated pixel artwork',function()
    for _,variant in ipairs(catalog.variants) do
        local theme=assert(art.themes[variant.hologramTheme or variant.key])
        assert(#theme==6)
        for _,placement in ipairs(theme) do assert(art.glyphs[placement.glyph]) end
    end
    local frames=0
    for name,glyph in pairs(art.glyphs) do
        for _,frame in ipairs(glyph.frames) do
            frames=frames+1
            for _,row in ipairs(frame) do
                assert(#row==#frame[1],name)
                for s in row:gmatch('.') do assert(s=='.' or glyph.palette[s],name) end
            end
        end
    end
    assert(size(art.glyphs)==11 and frames==22)
end)
check('stationary projections persist while a stopped parade stays nearby',function()
    local f=fixture(); f.controller:Frame(0)
    local id=f.created[1]; assert(id and f.positions[id][1]==560 and f.positions[id][3]==500)
    assert(f.glyph==art.themes[catalog.variants[1].key][1].glyph)
    local position=f.positions[id]
    f.controller:Frame(30000)
    assert(#f.created==1 and #f.destroyed==0 and f.positions[id]==position)
    f.positions[1]={500,0,550}; f.controller:Frame(30120)
    assert(#f.created==2 and f.positions[f.created[2]][1]==440)
    assert(f.positions[id]==position and #f.destroyed==0)
    f.positions[1]={1500,0,1500}; f.controller:Frame(30240)
    assert(not f.alive[id] and #f.destroyed==2)
end)
check('a following float keeps the projection alive after its source leaves',function()
    local f=fixture(); f.controller:Frame(0); local id=f.created[1]
    f.G.CityParade.vehicles[3]={payload=4}
    f.alive[3],f.alive[4],f.teams[3],f.parents[4],f.variants[4]=true,true,0,3,2
    f.positions[3]={500,0,500}; f.positions[1]={1500,0,1500}
    f.controller:Frame(120); assert(f.alive[id])
    f.alive[3]=false; f.controller:Frame(135); assert(not f.alive[id])
end)
check('spawn interval, distance, overlap and total cap bound a dense convoy',function()
    local f=fixture(); f.config.maxHolograms=2; f.controller:Frame(0)
    f.positions[1]={500,0,550}; f.controller:Frame(15); assert(#f.created==1)
    f.controller:Frame(120); assert(#f.created==2)
    f.positions[1]={500,0,600}; f.controller:Frame(240); assert(#f.created==2)
    f=fixture(); f.controller:Frame(0)
    f.G.CityParade.vehicles[3]={payload=4}
    f.alive[3],f.alive[4],f.teams[3],f.parents[4],f.variants[4]=true,true,0,3,1
    f.positions[3]={500,0,500}; f.controller:Frame(15); assert(#f.created==1)
end)
check('invalid sources, water, buildings and map edges cannot spawn',function()
    for _,setup in ipairs({
        function(f) f.parents[2]=nil end, function(f) f.alive[1]=false end,
        function(f) f.alive[2]=false end, function(f) f.teams[1]=1 end,
        function(f) f.variants[2]=999 end, function(f) f.blocked=true end,
        function(f) f.ground=-10 end, function(f) f.positions[1]={4050,0,500} end,
        function(f) f.G.CityParade.phase='assembling' end,
    }) do local f=fixture(); setup(f); f.controller:Frame(0); assert(#f.created==0) end
    local f=fixture(); f.accept=false; f.controller:Frame(0)
    assert(#f.destroyed==1 and not next(f.controller.holograms))
end)
check('stop, source death and attachment loss clean up all owned units',function()
    for _,setup in ipairs({
        function(f) f.G.CityParade=nil end,
        function(f) f.G.CityParade.phase='cleanup' end,
        function(f) f.parents[2]=nil end,
        function(f) f.alive[1]=false end,
    }) do
        local f=fixture(); f.controller:Frame(0); setup(f); f.controller:Frame(15)
        assert(#f.destroyed==1 and not next(f.controller.holograms))
        f.controller:Clear(); assert(#f.destroyed==1)
    end
end)

check('ghost assemblies cover all 27 slot combinations deterministically',function()
    local seen={}
    for serial=0,26 do
        local parts=ghosts.Select(serial)
        for slot,name in pairs(parts) do assert(ghosts.parts[name].slot==slot) end
        local key=parts.body..':'..parts.face..':'..parts.mask
        assert(not seen[key]); seen[key]=true
        local repeatParts=ghosts.Select(serial+27)
        assert(repeatParts.body==parts.body and repeatParts.face==parts.face and repeatParts.mask==parts.mask)
    end
    assert(size(seen)==27)
end)
check('ghost cadence preserves every original ornament and shares distance cleanup',function()
    local f=fixture(); local ornament=0
    for n=1,9 do
        f.positions[1]={500,0,500+(n-1)*60}; f.ghost=nil
        f.controller:Frame((n-1)*120)
        assert(#f.created==n)
        if n%3==0 then assert(f.ghost and ghosts.parts[f.ghost.body])
        else
            ornament=ornament+1
            assert(not f.ghost and f.glyph==art.themes[catalog.variants[1].key][ornament].glyph)
        end
    end
    f.G.CityParade.phase='idle'; f.controller:Frame(1200)
    assert(not next(f.controller.holograms) and #f.destroyed==9)
    f=fixture(); f.config.ghostEvery=0
    for n=1,3 do
        f.positions[1]={500,0,500+(n-1)*60}; f.controller:Frame((n-1)*120)
    end
    assert(not f.ghost and #f.created==3)
end)

check('native script publishes animated pieces, blackouts and fixed orientation',function()
    local frame,thread=0
    local pieces={center=0}; local shown,turns,flags={},{},{}
    for name,glyph in pairs(art.glyphs) do
        for index in ipairs(glyph.frames) do pieces[name..'_'..index]=size(pieces) end
    end
    for name,part in pairs(ghosts.parts) do
        for index in ipairs(part.frames) do pieces[name..'_'..index]=size(pieces) end
    end
    local env={GG={},unitID=101,y_axis=2,script={},
        VFS={Include=dofile},
        Hide=function(id) shown[id]=nil end,Show=function(id) shown[id]=true end,
        Turn=function(id,axis,angle) turns[#turns+1]={id,axis,angle} end,
        Sleep=function() coroutine.yield() end,
        StartThread=function(fn) thread=coroutine.create(fn); assert(coroutine.resume(thread)) end,
        Spring={GetUnitPieceMap=function() return pieces end,GetGameFrame=function() return frame end,
            MoveCtrl={Enable=function(id) flags.frozen=true end}}}
    for _,name in ipairs({'Neutral','Blocking','NoSelect','NoDraw','Stealth'}) do
        env.Spring['SetUnit'..name]=function(id,value) flags[name]=value end
    end
    loadEnv('scripts/paradeHologramScript.lua',env)
    assert(not env.SetParadeHologram('missing',0)); assert(env.SetParadeHologram('candle',1.2))
    env.script.Create()
    assert(flags.frozen and flags.NoDraw and flags.NoSelect and flags.Blocking==false)
    assert(#turns==1 and turns[1][3]==1.2)
    local first=env.GG.VisibleUnitPieces[101]
    assert(#first==1 and shown[first[1]])
    frame=8; assert(coroutine.resume(thread))
    local second=env.GG.VisibleUnitPieces[101]
    assert(#second==1 and first~=second and size(shown)==1)
    env.setTimeOutExternal(1000); assert(#env.GG.VisibleUnitPieces[101]==0 and size(shown)==0)
    frame=20; assert(coroutine.resume(thread)); assert(#env.GG.VisibleUnitPieces[101]==0)
    frame=40; assert(coroutine.resume(thread)); assert(#env.GG.VisibleUnitPieces[101]==1)
    env.GG.BlackOutDeactivationTime={[101]=frame}; assert(coroutine.resume(thread))
    assert(#env.GG.VisibleUnitPieces[101]==0)
    frame=9040; assert(coroutine.resume(thread)); assert(#env.GG.VisibleUnitPieces[101]==1)
    assert(#turns==1 and env.script.HitByWeapon()==0)
    assert(env.SetParadeGhost('ghost_wisp','ghost_round','ghost_veil',0.7))
    assert(coroutine.resume(thread))
    local assembly=env.GG.VisibleUnitPieces[101]
    assert(#assembly==3 and size(shown)==3 and turns[#turns][3]==0.7)
    for _,id in ipairs(assembly) do assert(shown[id]) end
    assert(not env.SetParadeGhost('ghost_round','ghost_wisp','ghost_veil',0))
    assert(not env.SetParadeGhost('ghost_wisp','missing','ghost_veil',0))
    assert(not env.SetParadeGhost('ghost_wisp',nil,'ghost_veil',0))
    frame=frame+15; assert(coroutine.resume(thread))
    assert(#env.GG.VisibleUnitPieces[101]==3 and size(shown)==3)
    assert(env.GG.VisibleUnitPieces[101][1]~=assembly[1], 'ghost body did not animate')
    env.setTimeOutExternal(1000); assert(size(shown)==0 and #env.GG.VisibleUnitPieces[101]==0)
    frame=frame+31; assert(coroutine.resume(thread)); assert(size(shown)==3)
    assert(env.SetParadeHologram('candle',0)); assert(coroutine.resume(thread))
    assert(size(shown)==1 and #env.GG.VisibleUnitPieces[101]==1, 'ghost pieces leaked into ornament')
    env.script.Killed(); assert(#env.GG.VisibleUnitPieces[101]==0 and size(shown)==0)
end)

check('shared neon registers, streams changed frames and removes projection light',function()
    local sent={}
    local env={gadget={},GG={},UnitDefs={[7]={customParams={parade_hologram=true}}},
        gadgetHandler={IsSyncedCode=function() return true end},VFS={Include=function() end},
        getHologramTypes=function() return {[7]=true} end,
        getHologramTypeNames=function() return {[7]='paradehologram'} end,
        getEngineVersion=function() return 105 end,count=size,
        Spring={GetGameFrame=function() return 0 end,GetAllUnits=function() return {} end,
            SetUnitNoDraw=function() end,UnitScript={CallAsUnit=function() end}},
        SendToUnsynced=function(...) sent[#sent+1]={...} end}
    env._G=env
    loadEnv('luarules/gadgets/gfx_neonHolograms.lua',env)
    env.gadget:Initialize(); env.gadget:UnitCreated(101,7); env.gadget:UnitCreated(101,7)
    assert(#sent==1)
    env.GG.VisibleUnitPieces[101]={3,6,8}; env.gadget:GameFrame(1)
    assert(sent[2][1]=='updateUnitNeonLuaDraw' and sent[2][4]==3 and sent[2][5]==6 and sent[2][6]==8)
    env.gadget:UnitLeftLos(101,0,1,7)
    env.GG.VisibleUnitPieces[101]={4}; env.gadget:GameFrame(2)
    assert(sent[3][4]==4 and env.NeonHologramUnits[101]==7)
    env.GG.VisibleUnitPieces[101]={}; env.gadget:GameFrame(3)
    assert(#sent[4]==3)
    env.gadget:UnitDestroyed(101,7)
    assert(sent[5][1]=='unsetUnitNeonLuaDraw' and not env.NeonHologramUnits[101])
    assert(not env.GG.VisibleUnitPieces[101])
end)
check('late join, LOS, cloaking and destruction feed the same filtered cascade list',function()
    local file=assert(io.open('luarules/gadgets/gfx_neonHolograms.lua'))
    local source=file:read('*a'); file:close()
    local function section(a,b)
        local start=assert(source:find(a,1,true)); local finish=assert(source:find(b,start+#a,true))
        return source:sub(start,finish-1)
    end
    local body='local neonUnitTables,UnitUnitDefIDMap={},{}; local counterNeonUnits=0; '..
        'local neonSnapshotPending,objectiveSnapshotPending=true,false; local objectiveRadiancePieces={}\n'..
        section('    local function setUnitNeonLuaDraw(', '    local function InitializeTextures()')..
        section('    local function neonVisible(', '    local boolActivated = false')..
        '\nreturn updateUnitNeonLuaDraw,unsetUnitNeonLuaDraw,function() return counterNeonUnits end'
    local los,full,cloaked,dead=true,false,false,false
    local captured
    local bridge=setmetatable({RecieveAllNeonUnitsPieces=function(t) captured=t end},
        {__call=function(_,name) return name=='RecieveAllNeonUnitsPieces' end})
    local env=setmetatable({gadget={},Script={LuaUI=bridge},updateRainPercent=function() end,
        UnitDefs={[7]={customParams={parade_hologram=true}},[8]={customParams={}}},
        SYNCED={NeonHologramUnits={[101]=7,[102]=8},NeonHologramPieces={[101]={3},[102]={5}}},
        Spring={ValidUnitID=function() return true end,GetUnitIsDead=function() return dead end,
            GetUnitIsCloaked=function() return cloaked end,GetSpectatingState=function() return full,full end,
            GetMyAllyTeamID=function() return 1 end,GetUnitLosState=function() return {los=los,radar=true} end}},
        {__index=_G})
    local chunk
    if setfenv then chunk=assert(loadstring(body)); setfenv(chunk,env)
    else chunk=assert(load(body,'neon receiver','t',env)) end
    local update,remove,count=chunk()
    env.gadget:GameFrame(1); assert(captured[101][1]==3 and count()==2)
    update(nil,101,7,4); env.gadget:GameFrame(2)
    assert(captured[101][1]==4 and env.SYNCED.NeonHologramPieces[101][1]==3 and count()==2)
    los=false; env.gadget:GameFrame(3); assert(not captured[101] and captured[102])
    full=true; env.gadget:GameFrame(4); assert(captured[101])
    cloaked=true; env.gadget:GameFrame(5); assert(not captured[101])
    cloaked=false; full=false; los=true; env.gadget:GameFrame(6); assert(captured[101])
    remove(nil,101); remove(nil,101); env.gadget:GameFrame(7)
    assert(not captured[101] and count()==1)
    dead=true; env.gadget:GameFrame(8); assert(not next(captured))
end)
check('gadget reload and shutdown clean only projection units',function()
    local f=fixture(); f.alive[90],f.teams[90]=true,0
    f.S.GetAllUnits=function() return {1,2,90} end
    f.S.GetUnitDefID=function(id) return id==90 and 7 or 8 end
    local env={gadget={},Spring=f.S,GG=f.G,Game={mapSizeX=4096,mapSizeZ=4096},
        UnitDefNames={paradehologram={id=7}},VFS={Include=dofile},
        gadgetHandler={IsSyncedCode=function() return true end}}
    loadEnv('luarules/gadgets/gfx_parade_holograms.lua',env)
    env.gadget:Initialize(); assert(#f.destroyed==1 and f.destroyed[1]==90)
    env.gadget:GameFrame(1); assert(#f.created==0)
    env.gadget:GameFrame(15); assert(#f.created==1)
    env.gadget:Shutdown(); env.gadget:Shutdown(); assert(#f.destroyed==2)
    assert(f.alive[1] and f.alive[2])
end)
print('PASS: parade native hologram regression suite')
