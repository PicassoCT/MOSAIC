-- Run from the repository root with lua5.1 or texlua.
-- Tests observed paths, not a synthetic target ray or a live projectile lookup.
local frame, ally, full, inView = 0, 1, false, true
local losMode, losQueries = 'all', 0
local Spring = {
    GetGameFrame = function() return frame end,
    GetFrameTimeOffset = function() return 0 end,
    GetSpectatingState = function() return full, full end,
    GetMyAllyTeamID = function() return ally end,
    IsPosInLos = function(x, y, z)
        losQueries = losQueries + 1
        if losMode == 'none' then return false end
        if losMode == 'hole' then return x < 25 or x > 40 end
        if losMode == 'ally' then return ally == 1 end
        return true
    end,
    GetCameraPosition = function() return 0, 100, 0 end,
    IsSphereInView = function() return inView end,
}
local Game = {gameSpeed=30}
local WeaponDefs = {
    [1]={name='railgun',type='Cannon',customParams={railgun_wake=1}},
    [2]={name='orbitalrailgun',type='Cannon',noExplode=true,customParams={railgun_wake='1'}},
    [3]={name='tankcannon',type='Cannon',customParams={}},
}
local M=dofile('luaui/widgets_mosaic/include/railgun_wakes.lua')
local function fresh()
    frame,ally,full,inView,losMode=0,1,false,true,'all'
    return M.New(Spring,Game,WeaponDefs)
end
local function collect(s)
    return s:Collect(frame)
end
local function point(s,id,born,x,y,z,at,finished,weapon)
    frame=at
    s:Point(id,born,weapon or 1,x,y,z,at,finished or false)
end
local function bounds(spans,axis)
    local low,high=math.huge,-math.huge
    for _,p in ipairs(spans) do
        low=math.min(low,p['a'..axis],p['b'..axis])
        high=math.max(high,p['a'..axis],p['b'..axis])
    end
    return low,high
end

-- A hit within one simulation step still leaves its exact observed path.
local s=fresh()
point(s,10,0,0,20,0,0)
point(s,10,0,80,22,0,1,true)
local spans=collect(s)
assert(#spans>0,'short shot vanished with its projectile')
local low,high=bounds(spans,'x')
assert(low==0 and high==80,'wake invented a target or lost its collision endpoint')
for _,p in ipairs(spans) do
    assert(p.expires==450,'expiry must be fixed to shot birth, not last sample')
end
frame=120;s:Update();assert(#collect(s)>0,'residue depends on live projectile or owner')
frame=449;s:Update();assert(#collect(s)>0,'wake lost its final faint residue too early')
frame=450;s:Update();assert(#collect(s)==0,'wake survived its 15-second ceiling')

-- An archived shot cannot revive by replaying an old start after expiry.
point(s,10,0,0,20,0,451)
point(s,10,0,80,22,0,452,true)
assert(#collect(s)==0,'expired shot replay revived the trail')

-- The engine may reuse a projectile ID while the old atmospheric wake remains.
s=fresh()
point(s,7,0,0,20,0,0);point(s,7,0,64,20,0,1,true)
point(s,7,20,300,30,50,20);point(s,7,20,364,30,50,21,true)
spans=collect(s)
local old,new=false,false
for _,p in ipairs(spans) do
    assert(p.az==p.bz,'reused ID connected two independent shots')
    old=old or p.az==0
    new=new or p.az==50
end
assert(old and new,'overlapping shots sharing a reused ID overwrite one another')
frame=450;s:Update();spans=collect(s)
assert(#spans>0,'old shot expiry erased its newer ID reuse')
for _,p in ipairs(spans) do assert(p.az==50,'old shot retained after expiry') end

-- A hidden interval permanently breaks the observed route.
s=fresh()
point(s,8,0,0,20,0,0);point(s,8,0,60,20,0,1)
frame=2;s:Gap(8,0,2,false)
point(s,8,0,180,20,0,3);point(s,8,0,240,20,0,4,true)
spans=collect(s)
assert(#spans>=2,'visible portions on both sides of a gap were lost')
for _,p in ipairs(spans) do
    assert(p.bx<=60 or p.ax>=180,'hidden path was connected across a gap')
end
full=true
for _,p in ipairs(collect(s)) do
    assert(p.bx<=60 or p.ax>=180,'later full-view reconstructed unobserved history')
end

-- A hidden endpoint is rejected even when a caller forgets to send Gap.
s=fresh()
point(s,9,0,0,20,0,0)
losMode='none';point(s,9,0,64,20,0,1)
losMode='all';point(s,9,0,128,20,0,2);point(s,9,0,192,20,0,3,true)
for _,p in ipairs(collect(s)) do assert(p.ax>=128,'receiver accepted or bridged hidden coordinates') end

-- Endpoint visibility alone is insufficient for a long segment across fog.
s=fresh()
point(s,11,0,0,20,0,0);point(s,11,0,64,20,0,1,true)
losMode='hole';frame=2
for _,p in ipairs(collect(s)) do
    assert(p.bx<25 or p.ax>40,'visible endpoints leaked a hidden interior')
end
losMode='all';frame=3
assert(#collect(s)>0,'currently visible archived path failed to return')
local scans=losQueries
collect(s);collect(s)
assert(losQueries==scans,'LOS rechecked per draw instead of cached simulation state')
losMode='ally';ally=2
assert(#collect(s)==0,'same-frame ally switch reused another team visibility')
full=true
assert(#collect(s)>0,'same-frame spectator full-view change was ignored')

-- A never-observed interior is not archived for later map/full-view reveal.
s=fresh();losMode='hole'
point(s,14,0,0,20,0,0);point(s,14,0,64,20,0,1)
point(s,14,0,128,20,0,2,true)
full=true;losMode='all'
for _,p in ipairs(collect(s)) do
    assert(p.bx<25 or p.ax>40,'unseen interior was stored then revealed retrospectively')
end

-- Offscreen culling must not mark a visibility cache as valid for a new team.
s=fresh()
point(s,15,0,0,20,0,0);point(s,15,0,64,20,0,1,true)
assert(#collect(s)>0)
inView=false;losMode='ally';ally=2
assert(#collect(s)==0,'offscreen geometry submitted')
inView=true
assert(#collect(s)==0,'offscreen ally switch retained another team visibility cache')
inView=false;full=true;assert(#collect(s)==0)
inView=true;assert(#collect(s)>0,'offscreen full-view switch failed to refresh visibility')

-- Distinct actual samples retain curvature; no straight endpoint shortcut.
s=fresh()
point(s,12,0,0,20,0,0);point(s,12,0,64,40,0,1);point(s,12,0,128,20,0,2,true)
local peak=0
for _,p in ipairs(collect(s)) do peak=math.max(peak,p.ay,p.by) end
assert(peak==40,'sampled Cannon trajectory was flattened into a target ray')

-- Non-opted-in weapons never create railgun residue.
s=fresh()
point(s,13,0,0,20,0,0,false,3);point(s,13,0,64,20,0,1,true,3)
assert(#collect(s)==0,'ordinary cannon gained railgun wake')

-- Long shots and heavy overlap stay within fixed memory/render limits.
s=fresh()
for sample=0,150 do
    for id=1,40 do
        point(s,id,0,sample*16,20,id*8,sample,sample==150)
    end
end
local stats=s:GetStats()
assert(stats.tracked<=16,'retained shot budget exceeded')
assert(#collect(s)<=16*96,'retained segment budget exceeded')
assert(stats.tracked==16 and stats.spans>=16,'overlapping continuations churned the budget into empty trails')
frame=450;s:Update();assert(#collect(s)==0,'offscreen budgeted wakes did not expire')
s:Clear();assert(#collect(s)==0,'Clear retained GPU submission data')

print('PASS: short-shot endpoints, fixed 15-second expiry, independent residue, ID reuse, LOS gaps/interiors, team changes, path curvature and fixed budgets')
