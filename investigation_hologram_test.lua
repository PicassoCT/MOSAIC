local function read(path) local f=assert(io.open(path));local s=f:read('*a');f:close();return s end
local function normalize(t)
    if type(t)~='table' then return t end
    local n={};for k,v in pairs(t) do n[type(k)=='string' and k:lower() or k]=normalize(v) end
    return n
end
function lowerkeys(t)
    local n=normalize(t);for k in pairs(t) do t[k]=nil end;for k,v in pairs(n) do t[k]=v end;return t
end
Spring={GetModOptions=function() return {} end}
VFS={Include=function(path)
    if path=='gamedata/VFSUtils.lua' then return end
    if path=='gamedata/system.lua' then return {lowerkeys=lowerkeys} end
    if path=='gamedata/sidedata.lua' then return {} end
    return dofile(path)
end}
local source=read('gamedata/unitdefs_pre.lua')
assert((loadstring or load)(source:sub(1,assert(source:find('local sharedEnv =',1,true))-1)))()
for _,path in ipairs({'Abstract','Human'}) do
    for name,class in pairs(dofile('baseclasses/units/'..path..'.lua')) do _G[name]=class end
end
local icons=dofile('units/shared/abstracts/Icons.lua')
local new,old=icons.icon_investigation,icons.interrogationicon
assert(new.name=='Investigation' and new.buildtime==30 and new.buildcostmetal==300)
assert(new.objectname==old.objectname and new.script==old.script and new.buildpic==old.buildpic,'reuse original hologram assets and animation')
assert(new.customparams.baseclass=='Abstract' and not new.blocking and not new.reclaimable and not new.capturable)
for _,path in ipairs({'units/protagon/operativeInvestigator.lua','units/antagon/OperativePropagator.lua',
    'units/shared/human/OperativeAsset.lua','units/shared/human/CivilianAgent.lua'}) do
    for _,def in pairs(dofile(path)) do
        local found=false;for _,name in ipairs(def.buildoptions or {}) do if name=='icon_investigation' then found=true end end
        assert(found and def.builder,'every former operative investigator retains build-menu access: '..path)
    end
end

local function run(name)
    local now,threads,destroyed,alwaysVisible=0,{},false,nil
    local rules={ci_progress=.6}
    local env={unitID=100,unitDefID=1,UnitDefs={[1]={name=name}},script={},GG={},
        y_axis=2,z_axis=3,COB={WANT_CLOAK=1},
        include=function() end,piece=function(n) return n end,
        getGameConfig=function() return {espionage={interrogation={durationFrames=900}}} end,
        getPieceTableByNameGroups=function() return {Ring={1,2},Load={3,4},Puzzle={5}} end,
        generatepiecesTableAndArrayCode=function() end,showAll=function() end,
        hideT=function() end,showT=function() end,Spin=function() end,Move=function() end,
        WMove=function() end,syncMoveInTime=function() end,WaitForMoves=function() end,SetUnitValue=function() end,
        Sleep=function(ms) coroutine.yield(ms) end}
    env.Spring={SetUnitAlwaysVisible=function(_,v) alwaysVisible=v end,SetUnitNeutral=function() end,
        SetUnitNoSelect=function() end,MoveCtrl={Enable=function() end},
        GetUnitPosition=function() return 10,20,30 end,SetUnitPosition=function() end,
        GetGameFrame=function() return math.floor(now*.03) end,
        GetUnitRulesParam=function(_,key) return rules[key] end,
        DestroyUnit=function() destroyed=true end}
    env.StartThread=function(fn)
        local t={co=coroutine.create(fn),wake=now};threads[#threads+1]=t
        local ok,delay=coroutine.resume(t.co);assert(ok,delay);t.wake=now+(delay or 0)
    end
    setmetatable(env,{__index=_G})
    local chunk=assert(loadfile('scripts/interrogationIconScript.lua'))
    if setfenv then setfenv(chunk,env) else chunk=assert(loadfile('scripts/interrogationIconScript.lua','t',env)) end
    chunk();env.script.Create()
    for ms=1,4000 do
        now=ms
        for _,t in ipairs(threads) do
            if t.wake<=now and coroutine.status(t.co)~='dead' and not destroyed then
                local ok,delay=coroutine.resume(t.co);assert(ok,delay);t.wake=now+(delay or 0)
            end
        end
    end
    if name=='icon_investigation' then
        assert(not destroyed,'investigation must not hit the unrelated raid timeout')
        assert(not alwaysVisible,'investigation must not broadcast suspicion globally')
        assert(env.getCurrentPercent()==.6,'rings use actual resource-funded build progress')
        rules.ci_progress=.9;assert(env.getCurrentPercent()==.9)
    else
        assert(destroyed and alwaysVisible,'ordinary interrogation keeps its original raid lifecycle')
    end
end
run('icon_investigation');run('interrogationicon')
print('PASS: Investigation definition, operative build menus, original hologram animation and independent build-progress lifetime')
