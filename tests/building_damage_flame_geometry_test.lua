-- Run from the repository root with Lua 5.1+.
-- Real attachment normalizer and CPU renderer: mesh emitters are first vertices,
-- not pivots, and raw imported mesh coordinates are not world coordinates.
unpack = unpack or table.unpack
local state = {}
local drawn, origin, direction, length, width = 0
local boundsQueries = 0
local function near(actual, expected, message)
    assert(math.abs(actual-expected) < 1e-7, message..': '..tostring(actual)..' ~= '..tostring(expected))
end
Spring = {
    ValidUnitID=function(id) return id==7 end,
    GetUnitIsDead=function() return false end,
    GetUnitPieceMap=function() return {block=2} end,
    GetUnitPieceInfo=function()
        boundsQueries=boundsQueries+1
        return state.bounds
    end,
    GetUnitPieceMatrix=function() return unpack(state.matrix) end,
    GetUnitPiecePosDir=function() return unpack(state.emitter) end,
    GetUnitPosition=function() return unpack(state.position) end,
    GetUnitVectors=function() return state.front,state.up,state.right end,
    GetCameraPosition=function() return unpack(state.camera) end,
    GetSpectatingState=function() return true,true end,
    GetMyAllyTeamID=function() return 0 end,
    GetUnitIsCloaked=function() return false end,
    GetUnitNoDraw=function() return false end,
    GetUnitTransporter=function() return nil end,
    IsUnitIcon=function() return false end,
    IsSphereInView=function() return true end,
    GetGameFrame=function() return 30 end,
    GetFrameTimeOffset=function() return 0 end,
}
Game={gameSpeed=30}
VFS={LoadFile=function() return '' end}
GL={TRIANGLE_STRIP=5,ALL_ATTRIB_BITS=1,ONE=1,ONE_MINUS_SRC_ALPHA=2}
gl=setmetatable({
    CreateShader=function() return 1 end,
    GetUniformLocation=function(_, name) return name end,
    CreateList=function() return 1 end,
    CallList=function() drawn=drawn+1 end,
    GetSun=function() return .3,.3,.3 end,
    Uniform=function(name, ...)
        if name=='origin' then origin={...}
        elseif name=='direction' then direction={...}
        elseif name=='plumeLength' then length=(...)
        elseif name=='plumeWidth' then width=(...) end
    end,
}, {__index=function() return function() end end})
local effects=dofile('scripts/lib_building_damage_effects.lua')
local normalize=dofile('luarules/gadgets/include/smoke_ribbon_config.lua').Normalize
local renderer=assert(dofile('luarules/gadgets/include/smoke_ribbon_renderer.lua')())
local function register(geometry)
    local options=effects.FlameOptions(7,2,geometry)
    renderer.records={fire=normalize(7,2,options)}
    return options
end
local function draw()
    local before=drawn
    renderer:Draw()
    assert(drawn==before+1, 'building flame did not reach the actual renderer')
end

-- Identity piece basis. The first raw vertex (-10,0,-8) is deliberately far
-- from both the pivot and the desired upper/outward facade attachment.
state={bounds={min={-10,0,-8},max={10,12,8}},
    matrix={1,0,0,0, 0,1,0,0, 0,0,1,0, 20,60,0,1},
    position={100,20,200},emitter={110,80,192,0,1,0},
    front={0,0,1},up={0,1,0},right={-1,0,0},camera={250,140,450}}
local options=register({floorHeight=12,cellSize=20,modelScale=1})
draw()
near(origin[1],132.4,'flame root was not beyond the outward wall')
near(origin[2],92.72,'flame root was not above the facade top')
near(origin[3],200,'flame did not use the middle of the selected wall')
assert(direction[1]>0 and direction[2]>0 and direction[3]==0,'flame did not point outward and up')
near(length,26.4,'world floor height did not size the flame')
near(width,11,'world facade width did not size the flame')
near(options.rootOffset[1],22.4,'raw first vertex was not subtracted from the target')

-- Re-exporting the same shape with a different first vertex must not move the
-- visible fire to a different corner of the same building block.
state.emitter={124,87,197,0,1,0}
register({floorHeight=12,cellSize=20,modelScale=1})
draw()
near(origin[1],132.4,'reordered mesh vertices moved the attachment')
near(origin[2],92.72,'reordered mesh vertices changed attachment height')
near(origin[3],200,'reordered mesh vertices changed attachment depth')

-- Imported model: raw Z is vertical, raw X points along world -Z after the
-- unit heading, and the complete piece matrix contains the .0254 scale.
local scale=.0254
state={bounds={min={-400,-300,0},max={400,300,600}},
    matrix={scale,0,0,0, 0,0,-scale,0, 0,scale,0,0, 40,0,0,1},
    position={1000,50,2000},emitter={1007.62,50,1970.16,0,1,0},
    front={1,0,0},up={0,1,0},right={0,0,1},camera={1000,500,4500}}
options=register({floorHeight=600,cellSize=800,modelScale=scale})
draw()
near(origin[1],1000,'imported facade midpoint used the wrong unit axis')
near(origin[2],66.1544,'imported model scale was missing or applied twice vertically')
near(origin[3],1947.4016,'imported first vertex was treated as the pivot')
assert(direction[3]<0 and direction[2]>0 and math.abs(direction[1])<1e-9,
    'rotated facade flame did not point outward and up')
near(length,600*scale*2.2,'imported flame length was not in world units')
near(width,800*scale*.55,'imported flame width was not in world units')
near(options.rootOffset[1],896,'imported root offset was not in raw piece coordinates')
near(options.rootOffset[2],300,'imported first-vertex depth was not removed')
near(options.rootOffset[3],636,'imported root height was scaled twice')
assert((state.camera[3]-origin[3])^2 > 840^2,
    'fixture no longer covers the old 24*35 distance cutoff')

-- The accepted attachment follows a retained block's later translation with
-- no geometry resampling or new fire registration.
local queries=boundsQueries
state.matrix[14]=state.matrix[14]-5
state.emitter[2]=state.emitter[2]-5
draw()
near(origin[2],61.1544,'retained block movement left the flame behind')
assert(boundsQueries==queries,'ordinary rendering recomputed the static facade choice')

-- Minimal engine fixtures or empty/unavailable mesh metadata keep a finite
-- world-sized upward preset, rather than crashing the structural controller.
state.bounds=nil
options=register({floorHeight=600,cellSize=800,modelScale=scale})
assert(options.direction[2]==1 and options.rootOffset[1]==0,
    'unavailable geometry did not use a valid fallback')
near(options.length,600*scale*2.2,'geometry fallback lost known block dimensions')

-- Exercise the actual house caller too: helper-only fixtures already supplied
-- the correct import scale while the Arab script mistakenly supplied 1.
local houseFile=assert(io.open('scripts/house_arab_script.lua'))
local houseSource=houseFile:read('*a'); houseFile:close()
local function section(first,last)
    local start=assert(houseSource:find(first,1,true))
    return houseSource:sub(start,assert(houseSource:find(last,start+#first,true))-1)
end
local geometry,shadowScale
local function noop() end
local houseEnv=setmetatable({
    Spring=Spring,GG={},LevelPieces={},ToShowTable={},
    StartThread=noop,selectBase=noop,selectBackYard=noop,addRoofDeocrate=noop,
    buildDecorateGroundLvl=function() return 'test' end,
    buildDecorateLvl=noop,
    initializeBuildingShadowVoxels=function(_,_,importScale) shadowScale=importScale end,
    buildingDamage={initialize=function(_,_,_,_,height,cell,importScale)
        geometry={floorHeight=height,cellSize=cell,modelScale=importScale}
    end},
}, {__index=_G})
local code=section('local spGetGroundHeight','supriseChances =')..
    section('function buildBuilding()','function script.StartMoving()')
local chunk
if setfenv then chunk=assert(loadstring(code)); setfenv(chunk,houseEnv)
else chunk=assert(load(code,'Arab building initialization','t',houseEnv)) end
chunk(); houseEnv.buildBuilding()
near(shadowScale,.0254,'Arab shadow geometry lost the export scale')
state={bounds={min={-400,-300,0},max={400,300,600}},
    matrix={scale,0,0,0, 0,0,-scale,0, 0,scale,0,0, 40,0,0,1},
    position={1000,50,2000},emitter={1007.62,50,1970.16,0,1,0},
    front={1,0,0},up={0,1,0},right={0,0,1},camera={1000,500,4500}}
register(assert(geometry,'Arab building did not initialize structural damage'))
draw()
near(length,33.180147,'Arab caller produced an oversized flame length')
near(width,11.667744,'Arab caller produced an oversized flame width')
near(origin[1],1000,'Arab caller moved the flame off the facade midpoint')
near(origin[2],66.1449131,'Arab caller placed the flame too far above the facade')
near(origin[3],1947.2943104,'Arab caller placed the flame too far outside the facade')
renderer:Shutdown()
print('building damage flame geometry: first-vertex correction, facade exterior, import scale, retained motion and Arab caller passed')
