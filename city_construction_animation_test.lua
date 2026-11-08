local function section(path,first,last)
 local f=assert(io.open(path));local s=f:read('*a');f:close()
 local a=assert(s:find(first,1,true));return s:sub(a,last and assert(s:find(last,a+#first,true))-1 or #s)
end
local function execute(s,env)
 setmetatable(env,{__index=_G})
 local fn
 if setfenv then fn=assert(loadstring(s));setfenv(fn,env) else fn=assert(load(s,'test','t',env)) end
 fn()
end
local plot={elapsed=0,paused=false}
local shown,moves,destroyed={}, {}, false
local env={GG={CityConstructionSites={[1]=plot},CityRubble={[1]=plot},ManualRenderedBuildingWithWindowsVisiblePieces={}},
 unitID=1,Icon=99,boolDoneShowing=true,ToShowTable={1,2,3},toShowDict={[1]=true,[2]=true,[3]=true},
 GameConfig={city={rubble={decayFrames=30,constructionFrames=30}}},
 Spring={GetUnitPiecePosDir=function(_,p)return 0,({30,10,20})[p],0 end,
 DestroyUnit=function()destroyed=true end},
 Sleep=function()coroutine.yield()end,Show=function(id)shown[id]=true end,Hide=function(id)shown[id]=nil end,
 SetRadiancePlaceables=function()end,hideT=function()end,
 Move=function(_,_,position)moves[#moves+1]=position end,
 center=1,z_axis=3,distanceToGoDown=90,ExcavatorTable={}}
env.getGameConfig=function()return env.GameConfig end
execute(section('scripts/lib_mosaic.lua','function waitForCityConstruction'),env)
execute(section('scripts/lib_UnitScript.lua','function sortPiecesInDictionaryByHeight','function sortDictKeysNumeric'),env)
local sorted=env.sortPiecesInDictionaryByHeight(env.toShowDict)
assert(sorted[1]==2 and sorted[2]==3 and sorted[3]==1)
execute(section('scripts/house_asian_script.lua','function buildAnimationSequential()','function addGroundPlaceables'),env)
local c=coroutine.create(env.buildAnimationSequential)
assert(coroutine.resume(c));assert(coroutine.resume(c));assert(not shown[1] and not shown[2])
plot.elapsed=15;assert(coroutine.resume(c));assert(shown[2] and not shown[1] and not shown[3])
assert(coroutine.resume(c));plot.paused=true;plot.elapsed=30
assert(coroutine.resume(c));assert(not shown[1] and not shown[3],'paused assembly advanced')
env.GG.CityConstructionSites[1]=nil
for _=1,5 do if coroutine.status(c)~='dead' then assert(coroutine.resume(c)) end end
assert(shown[1] and shown[2] and shown[3] and coroutine.status(c)=='dead')
-- Rubble reads exactly the lifecycle progress, with no autonomous deletion.
execute(section('scripts/gCScrapHeap.lua','function waitForAnEnd()'),env)
plot.elapsed=15;plot.paused=true
c=coroutine.create(env.waitForAnEnd);assert(coroutine.resume(c));assert(coroutine.resume(c))
assert(moves[#moves]==-45 and not destroyed)
assert(coroutine.resume(c));assert(moves[#moves]==-45 and not destroyed)
env.GG.CityRubble[1]=nil;assert(coroutine.resume(c));assert(not destroyed)
print('PASS reconstruction animations: deterministic height sort, peace-gated partial assembly and clock-driven rubble decay')
