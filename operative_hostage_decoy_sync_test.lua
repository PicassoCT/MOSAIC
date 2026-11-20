-- Execute production event/transition functions with narrow engine boundaries.
local compile = loadstring or load
local function source(path)
    local f=assert(io.open(path));local s=f:read('*a');f:close();return s
end
local function run(text, env)
    setmetatable(env,{__index=_G})
    if setfenv then return setfenv(assert(compile(text)),env)() end
    return assert(load(text,'hostage decoy','t',env))()
end
local text=source('scripts/lib_mosaic.lua')
local first=assert(text:find('function syncDecoyToAgent(',1,true))
local following=assert(text:find('function getRegionByCulture(',first,true))
local held, transfers, visits, goals, starts = true,0,0,0,0
local scope={GG={HumanShield={IsHostage=function(id) assert(id==10);return held end},
    CivilianLife={GuardedVisit=function()visits=visits+1 end}},
    doesUnitExistAlive=function()return true end,
    transferUnitStatusToUnit=function(from,to)assert(from==10 and to==20);transfers=transfers+1 end,
    distance=function(x,y,z,a,b,c)return math.sqrt((x-a)^2+(y-b)^2+(z-c)^2)end,
    Spring={GetUnitPosition=function(id)return id==10 and 100 or 180,0,0 end,
        GetUnitTransporter=function()return nil end,
        SetUnitMoveGoal=function(id)assert(id==10);goals=goals+1 end,
        UnitScript={GetScriptEnv=function()return {script={StartMoving=function()starts=starts+1 end}}end,
            CallAsUnit=function(id,fn)fn()end}},
}
run(text:sub(first,following-1),scope)
local pack={myID=10,syncedID=20,boolMoving=true,boolTransported=true,followGoal={},stuckSince=1}
assert(scope.syncDecoyToAgent(1,60,pack)==65)
assert(transfers==1 and visits==0 and goals==0 and starts==0,'held decoy must only synchronize status')
assert(not pack.boolTransported and not pack.followGoal and not pack.stuckSince,'stale following state is cleared')
held=false
assert(scope.syncDecoyToAgent(1,66,pack)==72)
assert(transfers==2 and visits==1 and goals==1 and starts==1,'normal following resumes after release')

for _,path in ipairs({'scripts/operativeassetscript.lua','scripts/operativePropagatorScript.lua','scripts/operativeInvestigatorScript.lua'}) do
    text=source(path)
    local env={unitID=20,GG={HumanShield={IsHostage=function(id)assert(id==20);return true end}}}
    for _,name in ipairs({'transitionToCloaked','transitionToUncloaked'}) do
        local fn=assert(text:match('(function '..name..'%(%).-\nend)'))
        run(fn,env)
        -- No movement, mesh, cloak or destruction API is provided: reaching one
        -- would fail rather than quietly hiding a captive-cleanup regression.
        assert(env[name]()=='cloaked',path..': held disguise was changed')
    end
end

-- Militia has a separate cloak loop. Capture during its yield must prevent
-- stale decloak observations from destroying the captive body.
text=source('scripts/civilianagentscript.lua')
local loop=assert(text:match('(function cloakLoop%(%).-\nend)'))
local captured, cloaked = false,true
local env={unitID=20,boolDeCloaked=false,CMD={FIRE_STATE=45},COB={WANT_CLOAK=1,CLOAKED=2},
    GG={HumanShield={IsHostage=function()return captured end}},
    Spring={GetUnitIsCloaked=function()return cloaked end,GetUnitRulesParam=function()return 0 end,
        GiveOrderToUnit=function()end},
    waitTillComplete=function()end,SetUnitValue=function()end,StartThread=function()end,
    Sleep=function(ms)coroutine.yield(ms)end}
run(loop,env)
local thread=coroutine.create(env.cloakLoop)
local function step()local ok,err=coroutine.resume(thread);assert(ok,err)end
step();step();step() -- enters the main loop and yields after reading cloak
captured=true;cloaked=false
for _=1,5 do step()end
assert(not env.boolDeCloaked,'captured civilian agent must not destroy its disguise after a stale sleep')
print('PASS: actual decoy event pauses following during capture, resumes afterward, and all four disguise scripts preserve captivity')
