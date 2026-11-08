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
