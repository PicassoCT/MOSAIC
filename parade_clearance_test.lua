local create=dofile('scripts/lib_parade_clearance.lua').new
local frame,dead,angle=0,false,0
local context={Game={mapSizeX=2048,mapSizeZ=2048},config={routeHouseClearance=45},GG={BuildingTable={[5]=true}},Spring={
 GetGameFrame=function()return frame end,ValidUnitID=function()return true end,
 GetUnitIsDead=function()return dead end,GetUnitPosition=function()return 500,0,500 end,
 GetUnitCollisionVolumeData=function()return 130,60,90,0,30,0 end,
 GetUnitVectors=function()return {math.sin(angle),0,math.cos(angle)}, {0,1,0},{math.cos(angle),0,-math.sin(angle)} end}}
local c=create(context);c:Refresh()
local function point(x,z)return{x=x,z=z}end
assert(not c:SegmentClear(point(100,500),point(900,500)),'nonblocking house crossed')
assert(not c:SegmentClear(point(100,589),point(900,589)),'truck edge clipped the house')
assert(c:SegmentClear(point(100,591),point(900,591)),'clear roadside incorrectly rejected')
assert(not c:SegmentClear(point(390,500),point(390,500)),'spawn inside clearance allowed')
assert(c:SegmentClear(point(100,100),point(200,200)))
angle=math.pi/2;frame=30;c:Refresh()
assert(not c:SegmentClear(point(100,609),point(900,609)),'rotated footprint ignored')
dead=true;frame=60;c:Refresh()
assert(c:SegmentClear(point(100,500),point(900,500)),'destroyed house still blocks route')
print('PASS nonblocking house footprints, swept vehicle clearance, rotation and destroyed-house refresh')

dead=false;angle=0;frame=90;c:Refresh()
local detour,expanded=c:Detour(point(300,500),point(700,500),function()return true end,512)
assert(detour and expanded<=512,'failed to route around a nonblocking house')
for i=2,#detour do assert(c:SegmentClear(detour[i-1],detour[i])) end
local failed,used=c:Detour(point(300,500),point(700,500),function()return false end,16)
assert(not failed and used<=16,'detour ignored impassable terrain or search budget')
print('PASS bounded house detour and impassable-route rejection')

-- A civilian stopping point can lie inside the larger parade footprint. Find
-- another curb using the real rotated bounds, including neighbouring houses.
do
    local checks=0
    local curb=c:FindCurb(5,point(1000,500),function(p)checks=checks+1;return p end)
    assert(curb and c:SegmentClear(curb,curb) and curb.x>610)
    local alternate=c:FindCurb(5,point(1000,500),function(p)
        checks=checks+1
        if p.x<500 then return p end
    end)
    assert(alternate and alternate.x<390,'did not try opposite side of building')
    local blocked=c:FindCurb(5,point(1000,500),function()checks=checks+1;return nil end)
    assert(not blocked and checks<=64,'curb search ignored terrain failure or work bound')
    angle=math.pi/2;frame=120;c:Refresh()
    local rotated=c:FindCurb(5,point(500,1000),function(p)return p end)
    assert(rotated and rotated.z>610 and c:SegmentClear(rotated,rotated))
end
print('PASS staging curb search uses rotated house bounds, alternate sides and bounded terrain checks')
