-- Run the actual worker with numeric-only visibility calls, as in the engine.
include=function(name)
 if name=='lib_cloud_pieces.lua' or name=='lib_objective_ribbon_flames.lua' then
  return function()return {}end
 end
end
piece=function(name)return name=='nightlight' and 42 or 1 end
script={}
dofile('scripts/objective_pumpstationscript.lua')
local seen={}
Hide=function(p)assert(type(p)=='number');seen[#seen+1]='hide:'..p end
Show=function(p)assert(type(p)=='number');seen[#seen+1]='show:'..p end
waitTillNight=function()end;waitTillDay=function()end
Sleep=function()coroutine.yield()end
local worker=coroutine.create(nightLight)
local ok,err=coroutine.resume(worker);assert(ok,err)
assert(table.concat(seen,',')=='hide:42,show:42,hide:42')
assert(type(nightLight)=='function','piece replaced worker function')
print('PASS: pump night light passes piece IDs through a complete day/night cycle')
