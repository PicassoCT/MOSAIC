VFS={Include=dofile}
local planner=dofile('scripts/lib_house_asian_placeables.lua').withCatalogue(
 dofile('scripts/house_asian_standalone_placeable_catalog.lua'))
local pool,names={},{}
for name in pairs(planner.catalogue.pieces) do names[#names+1]=name end
table.sort(names);assert(#names==59)
for id,name in ipairs(names) do pool[name]=id end
local all={}
local function check(result)
 local ids={}
 for _,p in ipairs(result) do
  assert(not ids[p.id]);ids[p.id]=true;all[p.name]=true
  local near,far
  if p.side==1 then near,far=p.minZ,p.maxZ
  elseif p.side==2 then near,far=p.minX,p.maxX
  elseif p.side==3 then near,far=-p.maxZ,-p.minZ
  else near,far=-p.maxX,-p.minX end
  assert(near>=p.facade-.001,'prop inside selected building bounds')
  if p.zone=='walkway' then assert(far<=p.roadNear+.001,'small prop in road')
  else assert(near>=p.roadFar+2/planner.catalogue.scale-.001,'large prop before far curb') end
  for _,q in ipairs(result) do
   if p~=q then assert(not planner.overlap(p,q,770*.16-.001),'overlapping props') end
  end
 end
end
for seed=1,500 do
 local result=planner.plan{pieces=pool,seed=seed,count=5}
 assert(#result==5,'lost open-ground variety');check(result)
end
for name,id in pairs(pool) do
 local result=planner.plan{pieces={[name]=id},seed=4,count=1}
 assert(#result==1,'unreachable prop: '..name);check(result)
end
local reached=0;for _ in pairs(all)do reached=reached+1 end;assert(reached==59)
local bodies=0
for name,half in pairs(planner.catalogue.buildings)do
 bodies=bodies+1
 check(planner.plan{pieces=pool,seed=7,count=5,halfExtent=math.max(2390,half)})
end
assert(bodies>0)
print('PASS: all 59 standalone props retained; 500 layouts, selected-building extents, walkway/far-curb zoning and non-overlap')
