-- Run through run.sh -- lua5.1 tests/house_asian_placeable_fallback_test.lua
VFS={Include=dofile}
local base=dofile('scripts/lib_house_asian_placeables.lua')
local function poolFor(planner)
    local names,pool={},{}
    for name in pairs(planner.catalogue.pieces) do names[#names+1]=name end
    table.sort(names)
    for id,name in ipairs(names) do pool[name]=id end
    return pool
end
local function check(planner,result)
    local seen,large={},false
    for _,p in ipairs(result) do
        assert(not seen[p.id],'duplicate prop');seen[p.id]=true
        large=large or planner.isLarge(p.name)
        assert(p.minX>=p.facade or p.maxX<=-p.facade or
            p.minZ>=p.facade or p.maxZ<=-p.facade,'fallback entered the building')
        for _,q in ipairs(result) do
            if p~=q then assert(not planner.overlap(p,q,0),'fallback stacked props') end
        end
    end
    assert(large,'missing large ground prop')
end
local oldRandom=math.random
math.random=function() error('placement consumed game RNG') end
for _,planner in ipairs({base,base.withCatalogue(dofile('scripts/house_asian_standalone_placeable_catalog.lua'))}) do
    local pool=poolFor(planner)
    local counts={}
    for seed=1,100 do
        local normal=planner.plan{pieces=pool,seed=seed}
        assert(#normal>=2 and #normal<=5);check(planner,normal)
        for _,p in ipairs(normal) do assert(not p.relaxed,'open ground needed fallback') end
        -- Every nearby site is road surface; the only accepted sites are nearby.
        -- The first pass must fail, then use the road without entering the house.
        local road={aX=-100000,aZ=0,bX=100000,bZ=0,width=100000}
        local options={pieces=pool,seed=seed,roads={road},accept=function(p)
            return math.abs(p.x)<18000 and math.abs(p.z)<18000
        end}
        local fallback=planner.plan(options)
        assert(#fallback==2 or #fallback==3,'fallback must satisfy two/three minimum')
        counts[#fallback]=true;check(planner,fallback)
        for _,p in ipairs(fallback) do
            assert(p.relaxed and planner.roadOverlap(p,road),'street fallback was not exercised')
        end
        local repeatPlan=planner.plan(options)
        for i,p in ipairs(fallback) do
            local q=repeatPlan[i]
            assert(p.name==q.name and p.x==q.x and p.z==q.z,'fallback is not deterministic')
        end
    end
    assert(counts[2] and counts[3],'minimum must vary between two and three')
    -- Small props can fit normally while the required large prop needs pass two.
    local reserved=planner.plan{pieces=pool,seed=9,count=3,accept=function(p)
        return not planner.isLarge(p.name) or p.relaxed
    end}
    assert(#reserved==3);check(planner,reserved)
    local largeFallback=false
    for _,p in ipairs(reserved) do largeFallback=largeFallback or (p.large and p.relaxed) end
    assert(largeFallback,'small props exhausted the large-prop slot')
    assert(#planner.plan{pieces=pool,accept=function() return false end}==0,'hard rejection was overridden')
    assert(#planner.plan{pieces={Placeable1=1},seed=7}==1,'tiny pool duplicated props')
end
math.random=oldRandom

-- Exercise the production terrain filter independently of the candidate search.
-- A narrow wet strip misses both the centre and the four corners.
local function accepted(candidate,terrain,angle)
    local angle=angle or 0
    local c,s=math.cos(angle),math.sin(angle)
    local outcome
    local planner={catalogue={scale=1},roadWidth=25,localRoads=function() return {} end,
        plan=function(options) outcome=options.accept(candidate);return {} end}
    local env=setmetatable({unitID=1,GG={},Game={mapSizeX=1000,mapSizeZ=1000,squareSize=8},
        Spring={GetUnitPosition=function() return 200,20,200 end,
            GetUnitVectors=function() return {s,0,c},{0,1,0},{-c,0,s} end,
            GetGroundHeight=function(x,z)
                local dx,dz=x-200,z-200
                return terrain(c*dx-s*dz,s*dx+c*dz)
            end}}, {__index=_G})
    env.GG.HousePlaceableSelection={Request=function(_,id,apply) return {done=true,result=apply(nil)} end}
    local f=assert(loadfile('scripts/lib_house_asian_ground_placeables.lua'))
    setfenv(f,env)
    f()(planner,{cell=20,seed=1,pieces={}})
    return outcome
end
local function candidate(relaxed)
    return {x=40,z=40,minX=0,maxX=80,minZ=0,maxZ=80,relaxed=relaxed}
end
for _,angle in ipairs({0,math.pi/2,.61}) do
    for _,relaxed in ipairs({false,true}) do
        assert(accepted(candidate(relaxed),function() return 20 end,angle))
        assert(not accepted(candidate(relaxed),function() return -1 end,angle),'underwater prop accepted')
        assert(not accepted(candidate(relaxed),function(x,z)
            return x>12 and x<20 and -3 or 20
        end,angle),'prop straddled river between centre and corners')
        assert(not accepted(candidate(relaxed),function(x,z) return 1000+10*x end,angle),'cliff accepted')
    end
    assert(not accepted(candidate(false),function(x,z) return 20+.1*x end,angle),'first pass accepted steep slope')
    assert(accepted(candidate(true),function(x,z) return 20+.1*x end,angle),'fallback did not relax slope')
end
local outside=candidate(true);outside.minX=-300
assert(not accepted(outside,function() return 20 end),'fallback escaped map bounds')
print('PASS: two/three minimum, large-prop reservation, deterministic street fallback, no duplicates/building overlap, slopes and river rejection')
