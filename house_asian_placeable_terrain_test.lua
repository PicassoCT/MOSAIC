-- Run from the game checkout, passing this external file to Lua 5.1 or 5.2.
VFS={Include=dofile}
local planner=dofile('scripts/lib_house_asian_placeables.lua')
local function read(path)
 local f=assert(io.open(path));local text=f:read('*a');f:close();return text
end
local helperCode=read('scripts/lib_house_asian_ground_placeables.lua')
local function compile(code,env)
 if setfenv then return setfenv(assert(loadstring(code)),env)() end
 return assert(load(code,'house placeable terrain','t',env))()
end
local function wrapper(family)
 local source=read('scripts/house_asian'..(family=='standalone' and '_standalone' or '')..'_script.lua')
 local first=assert(source:find('function addGroundPlaceables()',1,true))
 local marker=family=='standalone' and '\nif not GG.GlobalPieceCounterArcology' or '\nlocal accumulatedStun'
 return source:sub(first,assert(source:find(marker,first,true))-1)..'\nreturn addGroundPlaceables'
end
local names,ids={},{}
for i=1,24 do names[i]='Placeable'..i;ids[i]=i end
local scale=planner.catalogue.scale
local function close(a,b,message) assert(math.abs(a-b)<.00001,message..': '..a..' / '..b) end
local function run(angle,terrain,family)
 local radians=angle*math.pi/180
 local c,s=math.cos(radians),math.sin(radians)
 local ux,uy,uz=1400,37,2200
 -- Independent analytic rotation, used to reconstruct engine-space bounds.
 local function toWorld(x,z) return ux+scale*(c*x+s*z),uz+scale*(-s*x+c*z) end
 local x1,z1=toWorld(-6000,3500);local x2,z2=toWorld(6000,3500)
 local placed,moves,turns,shown,lit,samples={}, {},{}, {},{},{}
 local env=setmetatable({unitID=5,GG={CityRoadNetwork={roads={{width=25,points={{x1,z1},{x2,z2}}}}}},
  Game={mapName='terrain-test',mapSizeX=8192,mapSizeZ=8192},
  GameConfig={city={alleys={sizeX=25}}},cubeDim={length=770},splitPlan={seed=83},
  pieceNr_pieceName=names,getNameFilteredTable=function() return ids end,
  buildingClearanceReady=true,ToShowTable={},toShowDict={},TablesOfPieceGroups={Placeable=ids},
  getDeterministicStationaryUnitHash=function()return 83 end,
  showSubs=function()end,garbageSimPlaceable={},
  inToShowDict=function() return false end,addToShowTable=function(id) shown[id]=true end,
  Show=function() end,SetRadiancePlaceables=function(p) for _,id in ipairs(p) do lit[id]=true end end,
  Move=function(id,axis,value) moves[id]=moves[id] or {};moves[id][axis]=value end,
  Turn=function(id,axis,value) turns[id]=value end,
  Spring={GetUnitPosition=function() return ux,uy,uz end,
   GetUnitVectors=function() return {s,0,c},{0,1,0},{-c,0,s} end,
   GetGroundHeight=function(x,z) samples[#samples+1]={x,z};return terrain(x,z) end},
  placeablePlanner={catalogue=planner.catalogue,roadWidth=25,localRoads=planner.localRoads,
   plan=function(options)
    -- Check the real wrapper's world-to-local road conversion.
    close(options.roads[1].aX,-6000,'rotated road X');close(options.roads[1].aZ,3500,'rotated road Z')
    options.count=5;placed=planner.plan(options);return placed
   end}}, {__index=_G})
 env.placeGroundProps=compile(helperCode,env)
 compile(wrapper(family),env)()
 for _,p in ipairs(placed) do
  assert(shown[p.id] and lit[p.id],'selected piece missing visibility or radiance registration')
  local pose=planner.catalogue.pieces[p.name].poses[math.floor(turns[p.id]/(math.pi/4)+.5)+1]
  local m=moves[p.id]
  -- Independently apply the exported center's rotation to parent-space Moves.
  if family=='standalone' then m={m[1],m[3],-m[2]} end
  local low=math.huge
  for _,lx in ipairs({pose.footMin[1],pose.footMax[1]}) do
   for _,lz in ipairs({pose.footMin[3],pose.footMax[3]}) do
    local wx,wz=toWorld(lx+m[1],lz+m[3])
    low=math.min(low,terrain(wx,wz))
    local sampled=false
    for _,q in ipairs(samples) do if math.abs(q[1]-wx)<.00001 and math.abs(q[2]-wz)<.00001 then sampled=true;break end end
    assert(sampled,'terrain sampled in unrotated or incorrectly scaled coordinates')
   end
  end
  close(uy+scale*(m[2]+pose.min[2]),low,'mesh bottom not at sampled world terrain height')
 end
 return placed
end
for _,family in ipairs({'modular','standalone'}) do
 if family=='standalone' then
  planner=planner.withCatalogue(dofile('scripts/house_asian_standalone_placeable_catalog.lua'))
  names,ids={},{}
  for name in pairs(planner.catalogue.pieces) do names[#names+1]=name end
  table.sort(names);for i=1,#names do ids[i]=i end
 end
 for _,angle in ipairs({0,90,180,270,37}) do
  local result=run(angle,function(x,z) return 20+.004*(x-1400)-.002*(z-2200) end,family)
  assert(#result==5,'valid sloping ground lost props: '..family)
  assert(#run(angle,function() return -5 end,family)==0,'underwater location accepted')
  assert(#run(angle,function(x,z) return 10000+10*x+3*z end,family)==0,'steep footprint accepted')
 end
end
print('PASS: modular and standalone production wrappers; 5 headings, rotated roads/parent axes, terrain grounding, water and slope rejection')
