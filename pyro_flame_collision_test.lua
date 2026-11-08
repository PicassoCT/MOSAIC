-- Run from repository root: lua tests/pyro_flame_collision_test.lua
-- Visual-only Cinder collisions: ground ramps, actual Recoil colvols,
-- LOS, old-engine box fallback and conservative high-ground clearance.
local heightMode='flat'
local traceMode='none'
local seen=true
local ally=0
local groundQueries=0
local function ground(x,z)
    groundQueries=groundQueries+1
    if heightMode=='crest' then return x>=60 and 16 or 0 end
    if heightMode=='ridge' then return (x>=28 and x<=35) and 28 or 0 end
    if heightMode=='ramp' then return math.max(0,(x-15)*.42) end
    return 0
end
local spring={
    GetGroundHeight=ground,
    GetGroundNormal=function() return 0,1,0 end,
    TraceRayInDirection=function(x,y,z,dx,dy,dz,reach,kind)
        assert(kind=='both')
        if traceMode=='none' then return {} end
        if traceMode=='wall' then
            if math.abs(z)>=6 then return {} end -- side rays find an open edge
            return {{50,42,'unit'}}
        end
        if traceMode=='feature' then return {{60,201,'feature'}} end
        return {}
    end,
    GetUnitPosition=function(id) assert(id==42);return 70,10,0 end,
    GetUnitCollisionVolumeData=function()return 40,40,40,0,10,0 end,
    GetUnitVectors=function()return {0,0,1},{0,1,0},{-1,0,0} end,
    GetUnitLosState=function() return {los=seen} end,
    ValidUnitID=function()return true end,
    GetUnitIsDead=function()return false end,
    GetUnitIsCloaked=function()return false end,
    IsPosInLos=function()return seen end,
    GetFeaturePosition=function()return 80,10,0 end,
    GetFeatureCollisionVolumeData=function()return 35,45,35,0,10,0 end,
}
local module=assert(dofile('luaui/widgets_mosaic/include/pyro_flame_collision.lua'))
local collision=module(spring)
local function fire()return collision.Trace(11,0,20,0,1,0,0,175,ally,false)end
local hit=fire()
assert(hit.kind==nil and hit.distance==175,'flat unobstructed flame must span the full weapon range')
heightMode='crest'
hit=fire()
assert(hit.kind=='ground' and hit.distance>57 and hit.distance<=61,
    'ground clearance ray failed to stop before rising terrain')
assert(hit.y>=ground(hit.x,hit.z)+8,'ground impact submerged')
assert(hit.normal[2]>.9,'ground normal lost')
heightMode='ridge'
local guard=collision.Guard(0,0,1,0,60,9)
assert(guard.pad==9 and #guard.near==4 and #guard.far==4,
    'eight-band terrain envelope missing')
local maxCeiling=-math.huge
for _,part in ipairs({guard.near,guard.far}) do
    for _,height in ipairs(part) do maxCeiling=math.max(maxCeiling,height) end
end
assert(maxCeiling>=29,'mid-path terrain crest not included in FlamePainter clamping envelope')
local beforeSlice=groundQueries
local segment=collision.SliceGuard(guard,21,25,60,9)
assert(groundQueries==beforeSlice and segment.pad==9 and #segment.near==4,
    'breakup terrain lookup was repeated instead of using the shared main guard')
local beforeFan=groundQueries
local fan=collision.FanGuard(32,0,50,11)
assert(groundQueries-beforeFan==17 and fan.pad==11,
    'impact tongues must share exactly one bounded 17-sample terrain fan')
local beforeLite=groundQueries
local short,cheap=collision.Lite(0,20,0,1,0,0,175,12)
assert(groundQueries-beforeLite==9 and cheap.pad==12 and short>0,
    'simplified Cinder should sample terrain only nine times')

heightMode='ramp'
hit=fire()
assert(hit.kind=='ground' and hit.distance>15 and hit.distance<65,
    'terrain slope penetration did not shorten nozzle jet')
heightMode='flat'
traceMode='wall'
hit=fire()
assert(hit.kind=='unit' and hit.distance==50 and hit.id==42,
    'first real unit collision-volume ray did not shorten jet')
assert(hit.normal[1]<-.5,'Cinder did not obtain an outward-facing colvol wall normal')
assert(hit.open[-1] and hit.open[1],'offset probe rays did not detect free paths around the wall')
seen=false
hit=fire()
assert(not hit.kind and hit.distance==175,'enemy hidden in fog caused a reveal by flame deflection')
seen=true
traceMode='feature'
hit=fire()
assert(hit.kind=='feature' and hit.id==201 and hit.distance==60,
    'feature collision-volume trace was not handled')
traceMode='wall'
local hitShooter=collision.Trace(42,0,20,0,1,0,0,175,ally,false)
assert(hitShooter.kind==nil,'Cinder collided visually with its own colvol')
-- Older Recoil branches may not offer the exact collision-volume trace.
-- Confirm the degraded geometric fallback remains functional.
spring.TraceRayInDirection=nil
spring.GetUnitsInCylinder=function() return {42} end
hit=fire()
assert(hit.kind=='unit' and hit.distance>=49 and hit.distance<=51,
    'old-engine collision-volume fallback ignored visible units')
seen=false
hit=fire()
assert(hit.kind==nil,'fallback disclosed a hidden unit')
print('PASS: Cinder terrain/colvols, 9-query LOD, zero-query shared side profiles, 17-query impact fan, LOS and legacy fallback')
