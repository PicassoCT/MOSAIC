-- Run the production behaviour and assault helper without script-global aliases.
local function read(path)local f=assert(io.open(path));local s=f:read('*a');f:close();return s end
local source=read('scripts/lib_mosaic.lua')
local start=assert(source:find('function getAerosolInfluencedStateMachine(',1,true))
local finish=assert(source:find('function headShake(',start,true))
local frame=4245
local nearby,distances,dead={}, {}, {}
local turns,spins,stops,commands,damage,blood,animations={},{},{},{},{},{},{}
local lifeThreads=0
local env=setmetatable({GG={GameConfig={Aerosols={tollwutox={VictimLiftime=1000}}},AerosolAffectedCivilians={}},
    x_axis=1,head=nil,UnitID=nil}, {__index=_G})
local validPieces={[11]=true,[12]=true,[13]=true,[14]=true}
local function recordPiece(into,id)
    assert(type(id)=='number' and validPieces[id],'animation received invalid piece '..tostring(id))
    into[#into+1]=id
end
env.Spring={GetGameFrame=function()return frame end,
    GetUnitPieceMap=function(id)assert(id==42);return {center=11,left=12,right=13,Head1=14}end,
    GetUnitPieceList=function()return {'center','left','right','Head1'}end,
    GetUnitDefID=function(id)return id==99 and 2 or (id~=98 and 1 or nil)end,
    GetUnitIsDead=function(id)return dead[id] or false end,ValidUnitID=function(id)return id~=98 end,
    GetUnitPosition=function(id)assert(type(id)=='number');return id*10,5,15 end,
    SetUnitNeutral=function(id,value)assert(id==42 and value==false)end,
    AddUnitDamage=function(id,value)damage[#damage+1]={id,value}end}
env.getChemTrailTypes=function()return {tollwutox='tollwutox',orgyanyl='orgyanyl',wanderlost='wanderlost',depressol='depressol'}end
env.getInfluencedStates=function()return {Init='Init',Standalone='Standalone'}end
env.getCivilianTypeTable=function()return {[1]=true,[2]=true}end -- also includes buildings
env.getCultureUnitModelTypes=function()return {[1]=true}end -- walking civilians only
env.getGameConfig=function()return {instance={culture='international'}}end
env.lifeTime=function()end
env.StartThread=function(fn,id,time)assert(fn==env.lifeTime and id==42 and time==1000);lifeThreads=lifeThreads+1 end
env.Turn=function(id)recordPiece(turns,id)end
env.Spin=function(id)recordPiece(spins,id)end
env.StopSpin=function(id)recordPiece(stops,id)end
env.maRa=function()return true end
env.getAllNearUnit=function(id)assert(id==42);return nearby end
env.distanceUnitToUnit=function(a,b)assert(a==42 and type(b)=='number');return distances[b]end
env.Command=function(id,cmd,target)commands[#commands+1]={id,cmd,target}end
env.spawnCegAtUnit=function(id,name)assert(name=='bloodslay');blood[#blood+1]=id end
env.closeCombatAnimation=function(c,l,r,h)
    assert(c==11 and l==12 and r==13 and h==14,'combat lost actor piece handles')
    animations[#animations+1]=true
end
local chunk=assert(loadstring(source:sub(start,finish-1)));setfenv(chunk,env);chunk()
local stateMachine=env.getAerosolInfluencedStateMachine(42,{},'tollwutox',11,12,13,14)
local state=stateMachine('tollwutox','tollwutox',42)
assert(turns[1]==14 and lifeThreads==1,'initial infection failed')
frame=30;state=stateMachine(state,state,42);assert(#spins==12,'shiver uses names instead of IDs')
frame=90;state=stateMachine(state,state,42);assert(#stops==12,'shiver never stops')
assert(lifeThreads==1,'infection lifetime restarts each tick')
frame=91;nearby={42,99,98,50};distances={[42]=0,[99]=1,[50]=40}
state=stateMachine(state,state,42)
assert(#commands==1 and commands[1][1]==42 and commands[1][2]=='go' and commands[1][3].x==500,'pursuit commands wrong unit/target')
env.GG.AerosolAffectedCivilians[50]='tollwutox';env.GG.TollWutoxAfflicted[50]=50
state=stateMachine(state,state,42)
assert(commands[2][1]==42 and commands[2][2]=='guard' and commands[2][3]==50,'afflicted ally not guarded')
env.GG.AerosolAffectedCivilians[50]=nil;distances[50]=10
state=stateMachine(state,state,42)
assert(#animations==1 and damage[1][1]==50 and damage[1][2]==30 and blood[1]==50,'close combat hits wrong unit')
env.closeCombatAnimation=function()dead[50]=true end
state=stateMachine(state,state,42)
assert(#damage==1 and #blood==1,'damage applied after target died during animation')
-- Both owning scripts must pass their local unit ID and head into the factory.
for _,file in ipairs({'civilianscript.lua','civilianagentscript.lua'})do
    local s=read('scripts/'..file)
    local a=assert(s:find('function aeroSolStateBehaviour()',1,true))
    local b=assert(s:find('\nfunction wailing()',a,true))
    local owner=setmetatable({unitID=42,UnitID=nil,UnitDefs={},UnitDefNames={civilian_arab4={id=2}},
        aeroSolType='tollwutox',center=11,UpArm1=12,UpArm2=13,Head1=14,bodyConfig={},Spring=env.Spring,
        spGetUnitDefID=env.Spring.GetUnitDefID,hideAllProps=function()end,Sleep=function()coroutine.yield()end,
        getAerosolInfluencedStateMachine=function(id,defs,kind,c,l,r,h)
            assert(id==42 and kind=='tollwutox' and h==14,'owning script passes undefined UnitID/head')
            return stateMachine
        end}, {__index=_G})
    local c=assert(loadstring(s:sub(a,b-1)));setfenv(c,owner);c()
    local thread=coroutine.create(owner.aeroSolStateBehaviour)
    local ok,err=coroutine.resume(thread);assert(ok,err)
end
print('PASS: reported Tollwutox head crash, numeric shiver handles, lifetime, civilian targeting, pursuit/guard/combat, target death during animation, both owning script entrypoints')
