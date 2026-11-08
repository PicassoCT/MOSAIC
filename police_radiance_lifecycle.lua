-- Run from the repository root: texlua tests/police_radiance_lifecycle.lua
-- Optional first argument selects a previous combat_light_sources.lua for
-- reproducing the always-visible-unit versus terrain-LOS regression.
unpack=unpack or table.unpack
Game={gameSpeed=30}
WeaponDefs={}
UnitDefs={[13]={name='policetruck'},[14]={name='civilian_arab0'}}

-- The widget reads this same pure export; configuration must not require GG.
local configEnv=setmetatable({MOSAIC_CONFIG_ONLY=true},{__index=_G})
local configChunk
if setfenv then
    configChunk=setfenv(assert(loadfile('scripts/lib_mosaic.lua')),configEnv)
else
    configChunk=assert(loadfile('scripts/lib_mosaic.lua','t',configEnv))
end
local profiles=assert(configChunk().getPoliceLightTypeTable(UnitDefs))
local profile=assert(profiles[13],'central set does not include police trucks')
assert(not profiles[14],'ordinary civilians belong to the police-light set')
assert(profile.pieces[1]=='LightEmit01' and profile.pieces[2]=='LightEmit2',
    'central profile must preserve the model\'s case-sensitive lightbar names')
assert(profile.pieceLift==10 and profile.fallbackHeight==40
    and profile.fallbackSpacing==6 and profile.fallbackForward==5.24,
    'police emitter clearance or model-sized fallback changed')

local frame,drawFrame,offset,pointLOS,fullView=0,0,0,false,false
local units={}
local function newUnit()
    return {unitLOS=true,sim={100,20,200},draw={103,21,197},
        front={0,0,1},up={0,1,0},right={1,0,0},
        map={LightEmit01=0,LightEmit2=7,lightemit01=99},
        pieces={[0]={94,50,205.24},[7]={106,50,205.24},[99]={0,0,0}},
        mapCalls=0,pieceCalls=0}
end
Spring={
    GetGameFrame=function() return frame end,
    GetDrawFrame=function() return drawFrame end,
    GetFrameTimeOffset=function() return offset end,
    GetSpectatingState=function() return fullView,fullView end,
    GetMyAllyTeamID=function() return 0 end,
    IsPosInLos=function() return pointLOS end,
    ValidUnitID=function(id) return units[id]~=nil and not units[id].invalid end,
    GetUnitIsDead=function(id) return units[id].dead end,
    GetUnitIsCloaked=function(id) return units[id].cloaked end,
    GetUnitNoDraw=function(id) return units[id].noDraw end,
    GetUnitTransporter=function(id) return units[id].transporter end,
    GetUnitLosState=function(id)
        if units[id].nilLOS then return nil end
        return {los=units[id].unitLOS}
    end,
    GetUnitPosition=function(id) return unpack(units[id].sim) end,
    GetUnitViewPosition=function(id) return unpack(units[id].draw) end,
    GetUnitVectors=function(id)
        local u=units[id]
        return u.front,u.up,u.right
    end,
    GetUnitPieceMap=function(id)
        local u=units[id];u.mapCalls=u.mapCalls+1
        return u.map
    end,
    GetUnitPiecePosDir=function(id,piece)
        local u=units[id];u.pieceCalls=u.pieceCalls+1;u.lastPiece=piece
        local p=u.pieces[piece]
        if p then return p[1],p[2],p[3],0,1,0 end
    end,
    GetCameraPosition=function() return 0,100,0 end,
    GetGroundHeight=function() return 0 end,
    GetVisibleProjectiles=function() return {} end,
}
local sourcePath=(arg and arg[1]) or 'luaui/widgets_mosaic/include/combat_light_sources.lua'
local Sources=dofile(sourcePath)
local weaponConf={[1]={life=30,radius=90,r=1,g=.4,b=.1,orgMult=1}}
local function makeSources() return Sources.New(weaponConf,profiles) end
local function collect(fx)
    drawFrame=drawFrame+1
    return fx:Collect()
end
local function near(actual,expected,label)
    assert(type(actual)=='number' and math.abs(actual-expected)<.00001,
        label..': expected '..expected..', got '..tostring(actual))
end
local function at(light,x,y,z,label)
    near(light.x,x,label..' x');near(light.y,y,label..' y');near(light.z,z,label..' z')
end

local fx=makeSources()
units[31]=newUnit()
fx:UnitCreated(31,13)
local lights,flames,tracers=collect(fx)
assert(#lights==1,
    'visible police light was discarded when unit LOS=true but point LOS=false')
assert(lights[1].unitID==31,'police light lost its validated unit ownership')
assert(#flames==0 and #tracers==0,'police beacon created unrelated combat ribbons')
assert(lights[1].color[1]==1 and lights[1].color[3]==.015,
    'first police strobe phase must be red')
assert(lights[1].radius==135 and lights[1].strength==2.4
    and lights[1].nightOnly==false,'day-visible police light profile changed')
at(lights[1],97,61,202.24,'red piece plus clearance and render interpolation')
assert(units[31].lastPiece==0,'valid zero-based piece ID or exact piece case was lost')
local cachedLights=fx:Collect()
assert(cachedLights==lights and units[31].mapCalls==1 and units[31].pieceCalls==1,
    'same draw frame needlessly recomputed the police attachment')
frame=4;offset=.9
lights=collect(fx)
assert(#lights==1 and lights[1].color[1]==1,'red phase ended before five game frames')
frame=5;offset=0
lights=collect(fx)
assert(#lights==1 and lights[1].color[3]==1,'police strobe failed to alternate blue')
at(lights[1],109,61,202.24,'blue piece plus clearance and render interpolation')
assert(units[31].lastPiece==7 and units[31].mapCalls==1,
    'piece-name lookup repeated after a valid map was cached')

-- Moving/tilting the model must use current piece positions and the current
-- unit up-vector even though piece IDs are cached.
local u=units[31]
u.sim={300,40,400};u.draw={302,43,404}
u.front={0,-.6,.8};u.up={0,.8,.6}
u.pieces[0]={291,68,407}
frame=10
lights=collect(fx)
at(lights[1],293,79,417,'tilted moving lightbar')
assert(u.mapCalls==1,'unit movement invalidated stable piece-name metadata')

-- Unit visibility is the permission boundary, independently of terrain LOS.
pointLOS=true
for _,flag in ipairs({'invalid','dead','cloaked','noDraw','transporter','nilLOS'}) do
    u[flag]=flag=='transporter' and 123 or true
    assert(#collect(fx)==0,'police light leaked for '..flag..' unit')
    u[flag]=nil
end
u.unitLOS=false
assert(#collect(fx)==0,'terrain LOS exposed a police unit outside unit LOS')
pointLOS=false;fullView=true
assert(#collect(fx)==1,'full-view spectator did not see visible police lights')
u.noDraw=true
assert(#collect(fx)==0,'full-view spectator exposed a no-draw police unit')
u.noDraw=nil;u.unitLOS=true;fullView=false
assert(#collect(fx)==1,'police lights failed to return after LOS reentry')

-- Fallback is above the roof in the model basis, including heading and tilt.
fx=makeSources();units[32]=newUnit();u=units[32]
u.map=nil
u.front={1,0,0};u.up={0,.8,.6};u.right={0,.6,-.8}
fx:UnitCreated(32,13)
frame=0
lights=collect(fx)
at(lights[1],108.24,49.4,225.8,'red fallback with heading and tilt')
assert(u.mapCalls==1 and u.pieceCalls==0,'nil piece map used an invalid piece')
frame=5
lights=collect(fx)
at(lights[1],108.24,56.6,216.2,'blue fallback with heading and tilt')
assert(u.mapCalls==2,'a not-yet-ready piece map was cached permanently')
u.map={LightEmit01=0,LightEmit2=7};u.pieces[0]={500,80,600}
frame=10
lights=collect(fx)
at(lights[1],503,89,603,'piece-map recovery after fallback')
local readyMapCalls=u.mapCalls
collect(fx)
assert(u.mapCalls==readyMapCalls,'resolved piece map kept being fetched')

-- Lowercase lookalikes are not the actual case-sensitive model emitters.
fx=makeSources();units[33]=newUnit();u=units[33]
u.map={lightemit01=99,lightemit2=100}
fx:UnitCreated(33,13)
lights=collect(fx)
at(lights[1],97,61,202.24,'missing named emitter uses rooftop fallback')
assert(u.pieceCalls==0,'case-mismatched piece was accepted as the lightbar')

-- Creation/destruction can occur between collectors in one draw frame.
fx=makeSources();units[34]=newUnit()
assert(#collect(fx)==0,'empty registry emitted police lights')
fx:UnitCreated(34,13)
assert(#fx:Collect()==1,'registration did not invalidate the same-frame collection')
fx:UnitDestroyed(34)
assert(#fx:Collect()==0,'destroyed police source survived a cached draw frame')
units[34]=newUnit();units[34].map={LightEmit01=8,LightEmit2=9}
units[34].pieces={[8]={700,80,900},[9]={710,80,900}}
fx:UnitCreated(34,13)
lights=fx:Collect()
at(lights[1],703,91,897,'reused unit ID received a fresh model attachment')
assert(units[34].lastPiece==8,'reused unit ID inherited its previous piece index')
fx:UnitCreated(34,14)
assert(#fx:Collect()==0,'non-police replacement inherited police membership')

-- Unit-validated police emission must not relax point LOS for world effects.
fx=makeSources();frame=0;pointLOS=true
fx:AddExplosion(50,10,50,1,false)
assert(#collect(fx)==1,'visible explosion stopped emitting')
pointLOS=false
fx:AddExplosion(90,10,90,1,false)
fx:SetFire(1,70,0,70,0,30)
assert(#collect(fx)==0,'world explosion or fire leaked across point LOS')
pointLOS=true
assert(#collect(fx)==2,'visible explosion/fire did not return or hidden explosion was accepted')

-- Police share the existing light budget even without positional LOS.
fx=makeSources();pointLOS=false
for id=100,229 do units[id]=newUnit();fx:UnitCreated(id,13) end
lights=collect(fx)
assert(#lights==96 and Sources.maxLights==96,'police sources exceeded the shared 96-light budget')
local seen={}
for _,light in ipairs(lights) do
    assert(light.unitID and not seen[light.unitID],'a police unit emitted more than one active lamp')
    seen[light.unitID]=true
end
print('PASS: police unit/point LOS, hidden-unit guards, exact pieces, zero piece ID, interpolation, tilt, fallback/recovery, lifecycle, ordinary-effect LOS, shared light budget')
