GG={InstanceCulture="asian"}
UnitDefNames=setmetatable({}, {__index=function() return {id=1} end})
UnitDefs={{id=1,buildOptions={}}}
dofile('scripts/lib_mosaic.lua')
local base='sounds/civilian/lostandfound/'
local folders={'intro','name','surname','additionalInfo','rewards','postlude'}
local counts={4,16,16,4,4,4}
local durations=dofile(base..'durations.lua')
local played,sleeps,waits,now={},{},0,0
Spring={PlaySoundFile=function(file) played[#played+1]={file=file,time=now} end}
Sleep=function(ms) sleeps[#sleeps+1]=ms;now=now+ms end
isNight=function() return true end
waitTillDay=function() waits=waits+1 end
waitTillNight=function() waits=waits+1 end
local pools,metadata={},false
VFS={DirList=function(dir) return pools[dir] end,
 FileExists=function(file) return metadata and file==base..'durations.lua' end,
 Include=function(file) assert(file==base..'durations.lua');return durations end}
local function reset() played,sleeps,waits,now={},{},0,0 end
local function unavailable()
 reset();assert(buildRunLostAndFound(1)==false)
 assert(#played==0 and #sleeps==0 and waits==0,'incomplete pack played or stalled the blimp')
end
unavailable()
local total=0
for i,dir in ipairs(folders) do
 pools[base..dir]={}
 for n=1,counts[i] do
  local rel=dir..'/'..n..'.ogg'
  assert(type(durations[rel])=='number' and durations[rel]>0,'missing clip duration: '..rel)
  local file=assert(io.open(base..rel,'rb'));assert(file:read(4)=='OggS');file:close()
  pools[base..dir][n]=base..rel;total=total+1
 end
end
assert(total==48)
unavailable() -- metadata absent
metadata=true
for _,dir in ipairs(folders) do
 local key=base..dir;local saved=pools[key];pools[key]={}
 unavailable();pools[key]=saved
end
local saved=durations['intro/1.ogg'];durations['intro/1.ogg']=nil
unavailable();durations['intro/1.ogg']=0;unavailable();durations['intro/1.ogg']=saved
local originalRandom=math.random
local seen={}
-- Every clip and all three announcement lengths remain reachable.
for choice=1,16 do
 for people=1,3 do
  local call=0
  math.random=function(lo,hi)
   call=call+1
   if call==2 then assert(hi==3);return people end
   return 1+(choice-1)%hi
  end
  reset();assert(buildRunLostAndFound(1)==true)
  assert(waits==1 and #played==2+4*people and #sleeps==#played)
  for i,event in ipairs(played) do
   local folder=i==1 and 'intro' or i==#played and 'postlude' or folders[2+(i-2)%4]
   assert(event.file:sub(1,#base+#folder+1)==base..folder..'/', 'wrong announcement order')
   local rel=event.file:sub(#base+1);seen[rel]=true
   local pause=(folder=='name' or folder=='surname') and 120 or 300
   assert(sleeps[i]==durations[rel]+pause,'clip timing not respected')
   if played[i+1] then assert(played[i+1].time>=event.time+durations[rel], 'speech overlaps') end
  end
 end
end
math.random=originalRandom
local reached=0;for _ in pairs(seen) do reached=reached+1 end
assert(reached==48,'some recorded alternatives are unreachable')
print('PASS: all 48 clips reachable, six-group ordering, 1–3 people, measured timing, incomplete-pack guards')
