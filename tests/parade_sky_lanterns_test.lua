local sky=dofile('scripts/lib_parade_sky_lanterns.lua')
local config=dofile('luarules/configs/parade_hologram_scene.lua').skyLanterns
local state,station={}, {born=0}
local releases=0
local function release()
 releases=releases+1
 return{x=100,y=10,z=200,ceiling=355,clearTime=config.riseSeconds,windX=1,windZ=-.5,phase=.3}
end
sky.Update(state,station,1,config,release);assert(releases==0)
local first
for tick=12,900 do
 local time=tick/10
 local list=sky.Update(state,station,time,config,release)
 first=first or list[1]
 assert(#list<=config.maxPerPayload)
 if first and time<=first.born+config.lifetime then
  local pose=sky.Pose(first,time,config)
  if time-first.born<config.riseSeconds then assert(math.abs(pose.x-first.x)<.66) end
 end
end
assert(releases>6,'bounded recycling stopped new releases')
local p0=sky.Pose(first,first.born,config)
local high=sky.Pose(first,first.born+28,config)
local drift=sky.Pose(first,first.born+34,config)
local gone=sky.Pose(first,first.born+38,config)
assert(p0.opacity==0 and high.y==355 and high.opacity>.7)
assert(drift.x>high.x+3 and drift.z<high.z-1)
assert(not gone.visible and gone.opacity==0)
station.retired=90
local count=releases
for t=91,130 do sky.Update(state,station,t,config,release) end
assert(releases==count and #state.flights==0)
sky.Update(state,{born=200},200,config,release);assert(#state.flights==0,'visibility gap caught up old launches')
sky.Update(state,{born=0},0,config,release);assert(#state.flights==0,'replay rewind kept future flights')
print('PASS roof-clearing ascent, delayed wind drift, soft fades, bounded recycling, retirement and visibility resets')
