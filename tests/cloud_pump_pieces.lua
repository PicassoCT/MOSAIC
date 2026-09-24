-- Pump family matching and actual visibility wrapper, including radiance group calls.
VFS={Include=function(p)return dofile(p)end}
local Config=VFS.Include('luarules/gadgets/include/cloud_volume_config.lua')
local map={};local names={}
local function add(name) names[#names+1]=name;map[name]=#names end
for _,n in ipairs({'Igniter','FireRotor','ExplosionStem','SmokeStem','Flame1','Flame2','Flame3'})do add(n)end
for _,family in ipairs({'Smoke','Explosion','FireRotor','FlameA','FlameB','FlameC','Flames'}) do
    for _,suffix in ipairs({'1','002','03','12','39'}) do add(family..suffix)end
end
for _,n in ipairs({'LightOn','LightOff','Tank','Pipe','SolarPanel'})do add(n)end
local active,shown,radiance={},{},{}
Spring={GetUnitPieceMap=function()return map end,Echo=function()end}
unitID=10
Show=function(id)shown[id]=true end
Hide=function(id)shown[id]=nil end
GG={CloudVolume={SetPiece=function(id,piece,preset)active[piece]=preset;return true end,
    RemovePiece=function(id,piece)active[piece]=nil end},
    SetObjectiveRadiancePieceVisible=function(id,piece,on)radiance[piece]=on end}
dofile('scripts/lib_radiance_emitters.lua')
Spring.UnitScript={Show=Show,Hide=Hide}
local helper=dofile('scripts/lib_cloud_pieces.lua')('pump')
local pieces={}
for name,id in pairs(map)do pieces[#pieces+1]=id end
ShowRadiancePieces(pieces)
for name,id in pairs(map)do
    local expected=Config.PumpPreset(name)
    if expected then
        assert(active[id]==expected and not shown[id], 'solid effect still shown: '..name)
        assert(radiance[id], 'light registration lost: '..name)
    else assert(shown[id] and not active[id], 'structure replaced: '..name)end
end
assert(active[map.Smoke1]=='soot' and active[map.FlameA1]=='flameTongue' and active[map.Explosion1]=='gasExplosion')
HideRadiancePieces(pieces);assert(not next(active),'hidden cloud stayed active')
ShowRadiancePieces(pieces);helper.Shutdown();assert(not next(active),'death leaked clouds')
Show(map.Flame1);assert(not next(active),'dead pump restarted')
print('PASS: pump cloud/flame families, ordinary geometry, radiance groups, hide/show cycles, death')
