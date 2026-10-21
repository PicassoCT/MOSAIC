-- Run from the repository root with Lua 5.1+ or luatex --luaonly.
-- Exercise the real controllers through the production registration validator.
unpack = unpack or table.unpack
local AIRPORT, F35 = 11, 12
local LEFT, RIGHT, HULL, EXHAUST = 1, 2, 3, 4
local Config = dofile('luarules/gadgets/include/smoke_ribbon_config.lua')
local bounds = {
    [LEFT] = {min={0,-8,-1}, max={10,2,1}},
    [RIGHT] = {min={-10,-8,-1}, max={0,2,1}},
    [HULL] = {min={-24,-45,-4}, max={24,45,4}},
    [EXHAUST] = {min={-6,-12,-1}, max={6,12,1}},
}
local state, build, transported, crashDeadline, dead, ground, altitude, velocity
local logs = {}
local function flying()
    state, build, transported, crashDeadline, dead = 'flying', 1, nil, nil, false
    ground, altitude, velocity = 0, 80, {0,0,1}
end
flying()
Game = {gameSpeed=30}
GG = {}
Spring = {
    ValidUnitID=function(id) return id==AIRPORT or id==F35 end,
    GetUnitIsDead=function() return dead end,
    GetUnitPieceMap=function(id)
        if id==AIRPORT then return {LeftWing=LEFT, RightWing=RIGHT, MainBirdBody1=HULL} end
        return {bodyFly=EXHAUST}
    end,
    GetUnitPieceInfo=function(_, piece) return bounds[piece] end,
    GetUnitMoveTypeData=function() return state and {aircraftState=state} or nil end,
    GetUnitHealth=function() return 1500,1500,0,0,build end,
    GetUnitTransporter=function() return transported end,
    GetUnitRulesParam=function(_, name)
        assert(name=='aircraft_crash_deadline', 'unexpected aircraft rule query: '..tostring(name))
        return crashDeadline
    end,
    GetUnitPosition=function() return 100,altitude,200 end,
    GetGroundHeight=function() return ground end,
    GetUnitVelocity=function() return unpack(velocity) end,
    Echo=function(message) logs[#logs+1]=message end,
}

local function newAPI()
    local api = {records={}, sets=0, removes=0}
    function api.Set(id, slot, piece, options)
        api.sets=api.sets+1
        if api.failSlot==slot then return false, 'injected registration failure' end
        local ok, record = pcall(Config.Normalize, id, piece, options)
        if not ok then return false, record end
        api.records[id..':'..slot]=record
        return true
    end
    function api.Remove(id, slot)
        api.removes=api.removes+1
        api.records[id..':'..slot]=nil
    end
    return api
end
local function count(api, id)
    local n=0
    for _,r in pairs(api.records) do if r.unitID==id then n=n+1 end end
    return n
end
local function near(a,b,message)
    assert(math.abs(a-b)<1e-7, message)
end
local function get(api, id, slot)
    return assert(api.records[id..':'..slot], 'missing slot '..slot)
end
local function zeroEmission(record, label)
    assert(record.emission[1]==0 and record.emission[2]==0, label..' unexpectedly emits light')
    assert(record.colorEnd[4]==0, label..' has an opaque tail')
end

local airport = dofile('scripts/lib_airport_contrails.lua')(AIRPORT)
assert(not airport.Start(LEFT,RIGHT,HULL), 'airport started without the ribbon gadget')
local api = newAPI()
GG.SmokeRibbon=api
assert(airport.Start(LEFT,RIGHT,HULL), 'airport failed to recover after gadget became available')
assert(count(api,AIRPORT)==2, 'airport must have exactly two contrails')
local left=get(api,AIRPORT,'airport-contrail-left')
local right=get(api,AIRPORT,'airport-contrail-right')
assert(left.piece==LEFT and right.piece==RIGHT, 'both trails were attached to one wing')
for _,r in ipairs({left,right}) do
    zeroEmission(r,'airport contrail')
    assert(r.directionSpace=='piece' and r.directionPiece==HULL,
        'steering-wing motion incorrectly controls wake direction')
    assert(r.direction[1]==0 and r.direction[2]==-1 and r.direction[3]==0,
        'airport contrail points away from the aircraft aft axis')
    assert(r.rootOffset[2]<bounds[r.piece].min[2], 'contrail starts inside the trailing edge')
    assert(r.drawInIcon and not r.distanceCulling, 'airport icon/distance hides its airborne trails')
end
near(left.rootOffset[1],-right.rootOffset[1],'wingtip attachment is not mirrored')
near(left.rootOffset[2],right.rootOffset[2],'wingtip outlets differ along the hull')
near(left.rootOffset[3],right.rootOffset[3],'wingtip outlet heights differ')
assert(left.rootOffset[1]>0 and right.rootOffset[1]<0, 'trails attach on the inboard side')
local sets=api.sets
for _=1,20 do assert(airport.Start(LEFT,RIGHT,HULL)) end
assert(api.sets==sets, 'steady circling repeatedly rewrites the ribbon registry')
airport.Stop(); assert(count(api,AIRPORT)==0, 'hidden airport plane retains trails')
assert(airport.Start(LEFT,RIGHT,HULL), 'next airport flight did not regain contrails')

-- A fresh API after a gadget reload must receive both records.
api=newAPI(); GG.SmokeRibbon=api
assert(airport.Start(LEFT,RIGHT,HULL), 'airport did not recover from ribbon API replacement')
assert(count(api,AIRPORT)==2, 'airport API replacement restored only one wing')
airport.Stop(); assert(count(api,AIRPORT)==0)
api.failSlot='airport-contrail-right'
assert(not airport.Start(LEFT,RIGHT,HULL), 'partial airport registration was reported as success')
assert(count(api,AIRPORT)==0, 'failed pair left a unilateral airport trail')
api.failSlot=nil
assert(airport.Start(LEFT,RIGHT,HULL), 'airport did not retry failed pair registration')
airport.Shutdown(); assert(count(api,AIRPORT)==0, 'airport death retained contrails')
sets=api.sets
assert(not airport.Start(LEFT,RIGHT,HULL))
assert(api.sets==sets, 'dead airport restarted its contrails')

-- An earlier model without usable bounds must not receive guessed attachments.
local savedBounds=bounds[RIGHT]
bounds[RIGHT]=nil
local missingWing=dofile('scripts/lib_airport_contrails.lua')(AIRPORT)
assert(not missingWing.Start(LEFT,RIGHT,HULL), 'airport accepted missing wing bounds')
assert(count(api,AIRPORT)==0, 'missing wing bounds left a partial emitter')
bounds[RIGHT]=savedBounds
missingWing.Shutdown()

GG.SmokeRibbon=nil
local fighter = dofile('scripts/lib_f35_exhaust.lua')(F35,EXHAUST)
fighter.Update()
api=newAPI(); GG.SmokeRibbon=api
fighter.Update()
assert(count(api,F35)==2, 'airborne F35 did not recover when ribbon gadget became available')
local flame=get(api,F35,'f35-afterburner')
local smoke=get(api,F35,'f35-smoke')
assert(flame.piece==EXHAUST and smoke.piece==EXHAUST, 'F35 layers use different exhaust anchors')
for axis=1,3 do
    near(flame.rootOffset[axis],smoke.rootOffset[axis],'F35 hot and cold layers do not share a nozzle')
    near(flame.direction[axis],smoke.direction[axis],'F35 layers point in different directions')
end
assert(flame.directionSpace=='piece' and smoke.directionSpace=='piece'
    and flame.direction[1]==0 and flame.direction[2]==-1 and flame.direction[3]==0,
    'F35 exhaust does not follow its aft model axis')
assert(flame.emission[1]>1 and flame.colorEnd[4]==0, 'F35 afterburner lacks a fading luminous core')
zeroEmission(smoke,'F35 smoke')
assert(smoke.length>flame.length, 'smoke does not extend behind the afterburner')
sets=api.sets
for _=1,100 do fighter.Update() end
assert(api.sets==sets, 'steady flight repeatedly rewrites F35 effects')

local function rejects(label, change)
    flying(); fighter.Update()
    assert(count(api,F35)==2, 'flight reset failed before '..label)
    change(); fighter.Update()
    assert(count(api,F35)==0, label..' retains F35 exhaust')
    local before=api.sets
    fighter.Update()
    assert(api.sets==before, label..' registers a new effect')
end
for _,notFlying in ipairs({'landed','takeoff','landing','crashing'}) do
    rejects(notFlying, function() state=notFlying end)
end
rejects('missing move type', function() state=nil end)
rejects('unfinished construction', function() build=0.99 end)
rejects('transported aircraft', function() transported=999 end)
rejects('crash rule', function() crashDeadline=900 end)
rejects('ground clearance threshold', function() altitude=5 end)
rejects('raised terrain', function() ground=100; altitude=104 end)
rejects('sea-level contact', function() ground=-100; altitude=4 end)
rejects('stationary aircraft', function() velocity={0,0,0} end)
rejects('speed threshold', function() velocity={0,0,0.05} end)
rejects('dead aircraft', function() dead=true end)

-- Eligible motion can include climbing; zero crash deadlines are not crashes.
flying(); velocity={0,0.06,0}; crashDeadline=0
fighter.Update(); assert(count(api,F35)==2, 'eligible airborne climb was rejected')
api=newAPI(); GG.SmokeRibbon=api
fighter.Update()
assert(count(api,F35)==2, 'F35 API replacement failed to restore its effects')

-- A partial registration must be retried without leaving a lone plume behind.
state='landed'; fighter.Update()
api.failSlot='f35-smoke'; flying(); fighter.Update()
assert(count(api,F35)==0, 'failed F35 registration left one layer active')
api.failSlot=nil; fighter.Update()
assert(count(api,F35)==2, 'F35 did not retry after transient registration failure')
GG.SmokeRibbon=nil; fighter.Update()
GG.SmokeRibbon=newAPI(); api=GG.SmokeRibbon
fighter.Update(); assert(count(api,F35)==2, 'F35 failed to recover after gadget absence')
fighter.Shutdown(); assert(count(api,F35)==0, 'F35 death retained its exhaust')
sets=api.sets
flying(); fighter.Update()
assert(api.sets==sets and count(api,F35)==0, 'dead F35 restarted exhaust')

-- Imported model scale belongs in plume dimensions once, never in local offsets.
local matrixScale=0.0254
Spring.GetUnitPieceMatrix=function()
    return matrixScale,0,0,0, 0,matrixScale,0,0, 0,0,matrixScale,0, 0,0,0,1
end
local scaled=dofile('scripts/lib_f35_exhaust.lua')(F35,EXHAUST)
scaled.Update()
local firstFlame=get(api,F35,'f35-afterburner')
local firstSmoke=get(api,F35,'f35-smoke')
scaled.Shutdown()
matrixScale=matrixScale*2
scaled=dofile('scripts/lib_f35_exhaust.lua')(F35,EXHAUST)
scaled.Update()
local twiceFlame=get(api,F35,'f35-afterburner')
local twiceSmoke=get(api,F35,'f35-smoke')
for _,pair in ipairs({{firstFlame,twiceFlame},{firstSmoke,twiceSmoke}}) do
    near(pair[2].length,pair[1].length*2,'imported scale not applied once to trail length')
    near(pair[2].width,pair[1].width*2,'imported scale not applied once to trail width')
    for axis=1,3 do
        near(pair[2].rootOffset[axis],pair[1].rootOffset[axis],'imported scale was baked into local offset')
    end
end
scaled.Shutdown()

print('PASS: aircraft ribbon validation, mirrored wing attachments, aft directions, fading smoke/afterburner, flight gates, idempotence, API reload/retry and death cleanup')
