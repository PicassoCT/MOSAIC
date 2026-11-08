-- Run from repository root: texlua tests/mobile_shadow_sources.lua
unpack = unpack or table.unpack
local function loadIn(path, env)
    local chunk = setfenv and setfenv(assert(loadfile(path)),env)
        or assert(loadfile(path,'t',env))
    return chunk()
end
local env = setmetatable({MOSAIC_CONFIG_ONLY=true},{__index=_G})
local config = loadIn('scripts/lib_mosaic.lua',env)
assert(not env.GG,'config-only import initialized synced game state')
local definitions = {
    [1]={name='policetruck',speed=30,customParams={baseclass='Truck'}},
    [2]={name='civilian_arab0',speed=30,customParams={baseclass='Civilian'}},
    [3]={name='operativeasset',speed=30,customParams={baseclass='Human'}},
    [4]={name='ground_tank_day',speed=30,customParams={baseclass='Tank'}},
    [5]={name='closecombatarena',speed=30,customParams={baseclass='Human'}},
    [6]={name='observer',speed=30,customParams={baseclass='Human'}},
    [7]={name='house_arab0',speed=0,customParams={baseclass='Truck'}},
    [8]={name='flying_truck',speed=30,canFly=true,customParams={baseclass='Truck'}},
    [9]={name='building_truck',speed=30,isBuilding=true,customParams={baseclass='Truck'}},
    [10]={name='immobile_truck',speed=30,canMove=false,customParams={baseclass='Truck'}},
}
local profiles = config.getMobileRadianceShadowTypeTable(definitions)
assert(profiles[1].shape==1 and profiles[2].shape==2 and profiles[3].shape==2 and profiles[4].shape==1)
for i=5,10 do assert(not profiles[i],'non-mobile/person unit entered central shadow set: '..i) end
assert(config.getPoliceLightTypeTable(definitions)[1] and config.getTankMuzzleTypeTable(definitions)[4],
    'new config export removed existing lighting profiles')

-- Exercise real definitions, including every culture/gender and vehicle model
-- variation, without loading synced culture helpers or making a second UI list.
local base = {}
function base:New(options)
    local result={}; for k,v in pairs(self) do result[k]=v end
    for k,v in pairs(options or {}) do result[k]=v end
    return result
end
local rawEnv=setmetatable({Truck=base,Tank=base,Walker=base,Civilian=base,Human=base,
    lowerkeys=function(t) return t end},{__index=_G})
local paths={'units/shared/chasis/ground/wheels/Truck.lua',
    'units/shared/chasis/ground/wheels/Motorbike.lua','units/shared/chasis/ground/wheels/Tank.lua',
    'units/shared/chasis/ground/walker/ground_walker_mg.lua',
    'units/shared/chasis/ground/walker/ground_walker_grenade.lua',
    'units/shared/chasis/ground/walker/ground_walker_flame.lua',
    'units/neutral/riotPolice.lua','units/shared/human/OperativeAsset.lua',
    'units/protagon/operativeInvestigator.lua','units/antagon/OperativePropagator.lua',
    'units/shared/human/CivilianAgent.lua','units/shared/human/Civilian_suicidebomber.lua'}
for _,culture in ipairs({'arab','western'}) do
    for i=0,5 do paths[#paths+1]='units/neutral/civilian_'..culture..'/Civilian_'..culture..i..'.lua' end
end
local actual, expected, count = {}, {}, 0
for _,path in ipairs(paths) do
    for name,def in pairs(loadIn(path,rawEnv)) do
        count=count+1
        actual[count]={name=name,speed=30,customParams=def.customparams or def.customParams}
        expected[count]=((actual[count].customParams or {}).baseclass=='Truck'
            or (actual[count].customParams or {}).baseclass=='Tank') and 1 or 2
    end
end
local actualProfiles=config.getMobileRadianceShadowTypeTable(actual)
for id,def in pairs(actual) do
    assert(actualProfiles[id] and actualProfiles[id].shape==expected[id],
        'real model variation omitted/misclassified: '..def.name)
end
assert(count>=30,'real-definition fixture stopped loading the model variations')

local frame, draw, full, ally, paused = 100, 1, false, 0, false
local camera={0,100,0}
local units, queries, colReads, viewReads, vectorReads = {},0,0,0,0
local lastRectangle
local function makeUnit(id, defID, x, y, z)
    units[id]={defID=defID,los=true,built=1,base={x,0,z},mid={x,y,z},view={x,y,z},
        scales=defID==2 and {10,25,10} or {40,50,70},offset={0,0,0},
        front={0,0,1},up={0,1,0},right={-1,0,0}}
    return units[id]
end
Spring={
    GetGameFrame=function() return frame end,GetDrawFrame=function() return draw end,
    GetGameSpeed=function() return 1,1,paused end,
    GetCameraPosition=function() return unpack(camera) end,
    GetSpectatingState=function() return full,full end,GetMyAllyTeamID=function() return ally end,
    GetUnitsInRectangle=function(x0,z0,x1,z1)
        queries=queries+1;lastRectangle={x0,z0,x1,z1}
        local ids={}
        for id,u in pairs(units) do
            if u.base[1]>=x0 and u.base[1]<=x1 and u.base[3]>=z0 and u.base[3]<=z1 then ids[#ids+1]=id end
        end
        table.sort(ids,function(a,b) return a>b end) -- never rely on engine iteration order
        return ids
    end,
    GetVisibleUnits=function() error('frustum gathering loses offscreen shadow casters') end,
    IsPosInLos=function() error('visible unit was incorrectly checked against positional LOS') end,
    GetUnitDefID=function(id) return units[id] and units[id].defID end,
    ValidUnitID=function(id) return units[id] and not units[id].invalid end,
    GetUnitIsDead=function(id) return units[id].dead end,
    GetUnitIsCloaked=function(id) return units[id].cloaked end,
    GetUnitNoDraw=function(id) return units[id].noDraw end,
    GetUnitTransporter=function(id) return units[id].transporter end,
    IsUnitIcon=function(id) return units[id].icon end,
    GetUnitLosState=function(id) return {los=units[id].los} end,
    GetUnitHealth=function(id) return 100,100,0,0,units[id].built end,
    GetUnitPosition=function(id,wantMid)
        assert(wantMid,'fallback used the unit base rather than its model midpoint')
        local u=units[id];return u.base[1],u.base[2],u.base[3],u.mid[1],u.mid[2],u.mid[3]
    end,
    GetUnitViewPosition=function(id,wantMid)
        assert(wantMid,'collector used drawPos rather than drawMidPos')
        viewReads=viewReads+1;return unpack(units[id].view)
    end,
    GetUnitCollisionVolumeData=function(id)
        colReads=colReads+1;local u=units[id]
        return u.scales[1],u.scales[2],u.scales[3],u.offset[1],u.offset[2],u.offset[3],2,1,2,false
    end,
    GetUnitVectors=function(id)
        vectorReads=vectorReads+1;local u=units[id];return u.front,u.up,u.right
    end,
}
local Sources=dofile('luaui/widgets_mosaic/include/mobile_shadow_sources.lua')
local domain={minX=-100,maxX=400,minZ=-100,maxZ=400}
local function near(a,b,message)
    assert(math.abs(a-b)<.00001,(message or 'values differ')..': '..tostring(a)..' / '..tostring(b))
end
local function find(records,id) for _,r in ipairs(records) do if r.unitID==id then return r end end end
local function collect(s,d) draw=draw+1;return s:Collect(d or domain) end
local car=makeUnit(10,1,100,30,200)
car.front={.6,0,.8};car.right={-.8,0,.6};car.offset={3,7,-11}
local pedestrian=makeUnit(20,2,20,12.5,20)
local s=Sources.New(profiles)
local records,stats=s:Collect(domain)
assert(#records==2 and records[1].unitID==20 and records[2].unitID==10)
local r=assert(find(records,10))
near(r.center[1],95.8,'model X sign / offset X');near(r.center[2],37,'draw midpoint / offset Y')
near(r.center[3],189.4,'rotated offset Z')
near(r.axisX[1],.8);near(r.axisX[3],-.6);near(r.half[1],20);near(r.half[2],25);near(r.half[3],35)
near(r.minX,58.8);near(r.maxX,132.8);near(r.minY,12);near(r.maxY,62)
near(r.radius,math.sqrt(20^2+25^2+35^2))
r=assert(find(records,20));assert(r.shape==2);near(r.radius,12.5);near(r.minX,15);near(r.maxY,25)
near(stats.minY,0);near(stats.maxY,62)
local q,c,v=queries,colReads,viewReads
assert(s:Collect(domain)==records and queries==q and colReads==c and viewReads==v,
    'same-draw capture repeated queries or rebuilt the snapshot')

-- Draw interpolation and orientation update while a spatial scan is cached.
car.view={112.5,31.75,200};car.front={0,.6,.8};car.up={0,.8,-.6}
records,stats=collect(s);r=assert(find(records,10))
assert(queries==q and stats.geometryReads==2,'new draw rescanned the entire unit population')
near(r.center[1],115.5);near(r.center[2],30.75);near(r.center[3],187)
near(r.maxY-r.center[2],.8*25+.6*35,'pitched box vertical envelope')
near(r.maxZ-r.center[3],.6*25+.8*35,'pitched box Z extent')
for _,axis in ipairs({r.axisX,r.axisY,r.axisZ}) do near(axis[1]^2+axis[2]^2+axis[3]^2,1) end
near(r.axisY[1]*r.axisZ[1]+r.axisY[2]*r.axisZ[2]+r.axisY[3]*r.axisZ[3],0)
pedestrian.front={0,.6,.8};pedestrian.up={0,.8,-.6}
records=collect(s);r=assert(find(records,20))
near(r.maxY-r.center[2],math.sqrt((.8*12.5)^2+(.6*5)^2),'ellipsoid vertical extent')

-- Hidden owners disappear between scans; visible disguise units remain ordinary
-- people. Unit LOS intentionally allows alwaysVisible neutral/police units.
for _,flag in ipairs({'cloaked','noDraw','transporter','dead','invalid','icon'}) do
    car[flag]=true;assert(not find(collect(s),10),'hidden caster survived: '..flag)
    car[flag]=nil;s:Invalidate();assert(find(collect(s),10),'restored caster failed: '..flag)
end
car.built=.99;assert(not find(collect(s),10),'unfinished unit cast a shadow')
car.built=1;s:Invalidate();assert(find(collect(s),10))
car.los=false;assert(not find(collect(s),10),'unit outside LOS leaked a shadow')
full=true;assert(find(collect(s),10),'full-view spectator lost a visible model')
car.cloaked=true;assert(not find(collect(s),10),'full-view bypassed cloak filtering')
car.cloaked=nil;car.los=true;full=false;s:Invalidate()
local operative=makeUnit(30,3,25,12.5,25);operative.cloaked=true
s:UnitCreated(30);records=collect(s)
assert(find(records,20) and not find(records,30),'cloaked operative doubled its civilian disguise shadow')

-- The destruction callback is authoritative even before engine read state
-- disappears. Same-ID creation clears it and always reads the new definition.
s:UnitDestroyed(10);assert(not find(s:Collect(domain),10),'destroy callback retained a stale caster')
car=makeUnit(10,2,110,12.5,210);s:UnitCreated(10)
r=assert(find(s:Collect(domain),10));assert(r.shape==2 and r.half[2]==12.5,'unit ID reuse inherited vehicle geometry')
car.defID=5;assert(not find(collect(s),10),'missed callback reused an unsupported definition')
car.defID=1;car.scales={40,50,70};s:UnitCreated(10)

-- Units beyond the camera viewport can still block a light reaching into it.
units={};camera={50,100,50};local offscreen=makeUnit(40,1,150,25,50)
offscreen.offscreen=true
local localDomain={minX=0,maxX=100,minZ=0,maxZ=100,margin=64}
s=Sources.New(profiles,{queryPadding=128});records,stats=s:Collect(localDomain)
assert(find(records,40),'offscreen caster within light margin was omitted')
assert(lastRectangle[1]==-192 and lastRectangle[3]==292,'query lost domain or volume padding')
localDomain.margin=0;assert(not find(s:Collect(localDomain),40),'domain change reused out-of-domain geometry')
offscreen.front={1,0,0};offscreen.up={0,1,0};offscreen.view[1]=128;offscreen.base[1]=128
assert(find(collect(s,localDomain),40),'volume overlapping the domain was rejected by origin only')
local before=queries;frame=frame+3;collect(s,localDomain);assert(queries==before+1,'timed candidate refresh stopped')
before=queries;paused=true;camera[1]=camera[1]+1;collect(s,localDomain)
assert(queries==before+1,'paused camera movement retained stale nearest candidates');paused=false
before=queries;frame=frame-20;collect(s,localDomain);assert(queries==before+1,'frame rewind retained stale scan')

-- Large populations use a bounded nearest-candidate heap, stable ID ties and
-- pooled per-draw records. Geometry work never scales with the queried crowd.
units={};camera={0,100,0};domain={minX=-500,maxX=500,minZ=-500,maxZ=500}
for id=1,1000 do makeUnit(id,1,(id+1)/2,25,0) end
units[1].view[1]=-1;units[1].base[1]=-1
units[2].view[1]=1;units[2].base[1]=1
s=Sources.New(profiles,{maxCasters=4,maxCandidates=8})
records,stats=s:Collect(domain)
assert(#records==4 and stats.retained==8 and stats.queried==1000 and stats.overBudget==996)
for i=1,4 do assert(records[i].unitID==i,'nearest/id budget is not deterministic') end
assert(stats.geometryReads==4,'collector read geometry for the whole population')
local first=records[1];before=queries;c=colReads;v=viewReads
records,stats=collect(s)
assert(records[1]==first and queries==before and colReads-c==4 and viewReads-v<=8,
    'cached draw lost bounded geometry/allocation behavior')
units[1].scales[1]=0/0;records,stats=collect(s)
assert(not find(records,1) and #records==4 and stats.geometryReads<=8,'invalid proxy poisoned the bounded snapshot')
s:Clear();assert(stats.selected==0 and stats.minY==nil and #records==0)
records=s:Collect(domain);assert(#records==4,'Clear prevented a clean rebuild')
s:Shutdown();before=queries;assert(#s:Collect(domain)==0 and queries==before,'Shutdown continued collecting')
assert(Sources.New(profiles,{maxCasters=10000}).stats.maxCasters==256,'hard budget limit was bypassed')

-- Older-engine fallback uses the simulation midpoint only when the draw API
-- does not exist; malformed domains and volume data always fail closed.
units={};local u=makeUnit(50,1,20,35,20);u.view={999,999,999};u.mid={20,35,20}
local getView=Spring.GetUnitViewPosition;Spring.GetUnitViewPosition=nil
s=Sources.New(profiles);records=s:Collect(domain);near(records[1].center[2],35,'simulation-midpoint fallback')
Spring.GetUnitViewPosition=getView
assert(#collect(s,{minX=0,maxX=0,minZ=0,maxZ=1})==0,'invalid domain retained stale shadows')
print('PASS: central real-model variants, collision midpoint/basis/full scales, height bounds, ellipsoids, interpolation, visibility/disguises, ID reuse, offscreen margin, bounded nearest snapshots and cleanup')
