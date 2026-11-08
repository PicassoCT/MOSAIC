GG={InstanceCulture="asian"}
UnitDefNames=setmetatable({}, {__index=function() return {id=1} end})
UnitDefs={{id=1,buildOptions={}}}
dofile('scripts/lib_mosaic.lua')
local path='sounds/civilian/lostandfound'
local played,waits={},0
Spring={PlaySoundFile=function(file) played[#played+1]=file end}
Sleep=function() waits=waits+1 end
isNight=function() return true end
waitTillDay=function() waits=waits+1 end
waitTillNight=function() waits=waits+1 end
local pools,files={},{}
VFS={DirList=function(dir) return pools[dir] end,FileExists=function(file) return files[file] end}
local function runUnavailable()
 played,waits={},0
 assert(buildRunLostAndFound(1)==false)
 assert(#played==0 and waits==0,'missing pack played or stalled the blimp')
end
runUnavailable()
for _,dir in ipairs({'name','surname','rewards','additionalInfo'}) do pools[path..'/'..dir]={path..'/'..dir..'/1.ogg'} end
files[path..'/lostandfound_12s.ogg']=true
runUnavailable() -- missing postlude
files[path..'/Postlude_9s.ogg']=true
for _,dir in ipairs({'name','surname','rewards','additionalInfo'}) do
 local key=path..'/'..dir;local saved=pools[key];pools[key]={}
 runUnavailable();pools[key]=saved
end
assert(buildRunLostAndFound(1)==true,'available pack was disabled')
assert(played[1]==path..'/lostandfound_12s.ogg' and played[#played]==path..'/Postlude_9s.ogg')
assert((#played-2)%4==0 and #played>=6 and #played<=14,'announcement sequence incomplete')
print('PASS: absent/partial audio packs cannot kill the announcement thread; complete packs retain the full sequence')
