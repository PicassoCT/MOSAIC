VFS={Include=dofile}
local planner=dofile('scripts/lib_house_asian_placeables.lua')
local pool={}
for i=1,24 do pool['Placeable'..i]=i end
local function check(result)
    local ids={}
    for _,p in ipairs(result) do
        assert(not ids[p.id],'duplicate piece');ids[p.id]=true
        local profile=planner.catalogue.pieces[p.name]
        local pose=profile.poses[math.floor(p.rotation/(math.pi/4)+.5)+1]
        assert(math.abs(p.moveX+pose.footMin[1]-p.minX)<.001,'pivot offset lost')
        assert(math.abs(p.moveZ+pose.footMax[3]-p.maxZ)<.001,'pivot offset lost')
        assert(math.abs(p.moveY+pose.min[2])<.001,'mesh not grounded')
        local half=770*3+2/planner.catalogue.scale
        local nearEdge,farEdge
        if p.side==1 then nearEdge,farEdge=p.minZ,p.maxZ
        elseif p.side==2 then nearEdge,farEdge=p.minX,p.maxX
        elseif p.side==3 then nearEdge,farEdge=-p.maxZ,-p.minZ
        else nearEdge,farEdge=-p.maxX,-p.minX end
        if p.zone=='walkway' then
            assert(profile.walkway and farEdge<=p.roadNear+.001,'walkway prop enters road')
            local gap=p.curbside and nearEdge-half or p.roadNear-farEdge
            assert(gap>=planner.pedestrianWidth/planner.catalogue.scale-.001,
                'walkway prop blocks pedestrian strip')
        else assert(nearEdge>=p.roadFar+2/planner.catalogue.scale-.001,'large prop intrudes into roadway') end
        assert(p.minX>=half or p.maxX<=-half or p.minZ>=half or p.maxZ<=-half,'prop intersects building')
        local lo,hi=p.minX,p.maxX
        if p.side%2==0 then lo,hi=p.minZ,p.maxZ end
        assert(lo>=-half+770*.45-.001 and hi<=half-770*.45+.001,'corner clearance lost')
        assert(lo>=770*.22-.001 or hi<=-770*.22+.001,'middle approach lane blocked')
        for _,other in ipairs(result) do
            if p~=other then assert(not planner.overlap(p,other,770*.16-.001),'props overlap') end
        end
    end
end
local oldRandom=math.random
math.random=function() error('planner consumed global RNG') end
local all={}
for seed=1,500 do
    local result=planner.plan{pieces=pool,seed=seed,count=5}
    assert(#result==5,'lost requested variety on level open ground')
    check(result)
    for _,p in ipairs(result) do all[p.name]=true end
    local reversed={}
    for i=24,1,-1 do reversed['Placeable'..i]=i end
    local again=planner.plan{pieces=reversed,seed=seed,count=5}
    for i,p in ipairs(result) do
        local q=again[i]
        assert(q.name==p.name and q.x==p.x and q.z==p.z and q.rotation==p.rotation,'unstable placement')
    end
end
for name in pairs(pool) do
    assert(all[name],'unreachable prop '..name)
    assert(#planner.plan{pieces={[name]=1},seed=123,count=5}==1,'small pool duplicated or lost prop')
end
assert(#planner.plan{pieces=pool,seed=5,accept=function() return false end}==0,'invalid ground accepted')
local allowed=planner.plan{pieces=pool,seed=5,count=5,accept=function(p) return p.side==1 end}
assert(#allowed>0,'did not try alternative sites')
for _,p in ipairs(allowed) do assert(p.side==1) end
check(allowed)
assert(#planner.plan{pieces={Placeable999=1},seed=1}==0,'unknown geometry guessed')
math.random=oldRandom
print('PASS: 500 five-prop layouts, all 24 props reachable, size/pivot-aware spacing, corner and approach clearances, deterministic selection, bounded rejection')

local scale=planner.catalogue.scale
local roads={
 {aX=-100/scale,aZ=85/scale,bX=100/scale,bZ=85/scale,width=25/scale},
 {aX=85/scale,aZ=-100/scale,bX=85/scale,bZ=100/scale,width=25/scale},
}
for seed=1,100 do
 local placed=planner.plan{pieces=pool,seed=seed,count=5,roads=roads}
 check(placed)
 assert(#placed==5)
 for _,p in ipairs(placed) do for _,road in ipairs(roads) do
  assert(not planner.roadOverlap(p,road),'prop placed on actual mapped road')
 end end
end
local converted=planner.localRoads({roads={{width=25,points={{10,20},{30,40}}}}},
 function(x,z) return (x-10)/scale,(z-20)/scale end,1000)
assert(#converted==1 and converted[1].aX==0 and converted[1].bZ==20/scale)
assert(planner.roadOverlap({minX=0,maxX=10,minZ=0,maxZ=10},
 {aX=-20,aZ=-20,bX=20,bZ=20,width=2}),'diagonal crossing missed')
print('PASS: walkway pedestrian strip and far-curb zones; mapped roads and diagonal crossings stay visually clear')
