-- Whole announcements from different blimps must never interleave.
GG={InstanceCulture='asian'};Game={gameSpeed=30}
UnitDefNames=setmetatable({}, {__index=function() return {id=1} end});UnitDefs={{id=1,buildOptions={}}}
dofile('scripts/lib_mosaic.lua')
local base='sounds/civilian/mostwanted/'
local durations=dofile(base..'durations.lua')
local pools={};local clips=0
for name,ms in pairs(durations) do
    local folder=name:match('^([^/]+)/');pools[base..folder]=pools[base..folder] or {}
    table.insert(pools[base..folder],base..name);clips=clips+1
    assert(ms>0);local f=assert(io.open(base..name,'rb'));assert(f:read(4)=='RIFF');f:close()
end
assert(clips==64)
VFS={DirList=function(path) local out={};for _,p in ipairs(pools[path] or {}) do out[#out+1]=p end;return out end,
    FileExists=function()return true end,Include=function()return durations end}
local frame,current,played,threads=0,nil,{},{}
Spring={GetGameFrame=function() return frame end,
    PlaySoundFile=function(file) played[#played+1]={file=file,frame=frame,owner=current} end}
function Sleep(ms) coroutine.yield(math.ceil(ms*30/1000)) end
function isNight() return true end
function waitTillDay() Sleep(1000) end
function waitTillNight() Sleep(1000) end
local function start(id)
    threads[id]={wake=frame,co=coroutine.create(function() assert(buildRunMostWanted(id)) end)}
end
local function step()
    local id
    for key,t in pairs(threads) do if not id or t.wake<threads[id].wake or (t.wake==threads[id].wake and key<id) then id=key end end
    if not id then return false end
    local t=threads[id];frame=t.wake;current=id
    local ok,wait=coroutine.resume(t.co);assert(ok,wait)
    if coroutine.status(t.co)=='dead' then threads[id]=nil else t.wake=frame+wait end
    return true
end
start(1);start(2)
while step() do end
local transitions,owner=0,nil
for i,p in ipairs(played) do
    if p.owner~=owner then transitions=transitions+1;owner=p.owner;assert(p.file:find('/intro/',1,true)) end
    if played[i+1] then
        assert(played[i+1].frame-p.frame>=math.ceil(durations[p.file:sub(#base+1)]*30/1000),'audio clips overlap')
    end
end
assert(transitions==2 and played[#played].owner==2,'bulletins interleaved or disappeared')
assert(played[#played].file:find('/postlude/',1,true))
-- Destruction terminates a unit thread; the remaining reservation must expire.
frame,current,played,threads=0,nil,{},{};GG.MostWantedAudioUntil=nil
start(1);start(2)
while #played==0 do assert(step()) end
local untilFrame=GG.MostWantedAudioUntil
threads[1]=nil
while step() do end
assert(played[2].owner==2 and played[2].frame>=untilFrame,'dead owner released audio too early or blocked forever')
-- Missing metadata cannot launch a partially timed bulletin or take a lease.
local previous=GG.MostWantedAudioUntil
VFS.FileExists=function()return false end
assert(buildRunMostWanted(3)==false and GG.MostWantedAudioUntil==previous)
print('PASS: 64 timed WAV clips, two dawn bulletins serialized, no phrase overlap, dead-owner expiry and missing-pack guard')
