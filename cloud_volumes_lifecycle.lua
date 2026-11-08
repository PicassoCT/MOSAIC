-- Run from repository root with Lua 5.1 (or lupa.lua51).
local frame=0
local map={GroundGases=1,RocketFusionPlume=2,LaunchCone=3,SpaceHarbour=4}
Spring={GetGameFrame=function() return frame end,ValidUnitID=function(id)return id==10 end,
    GetUnitPieceMap=function()return map end,
    GetUnitPieceInfo=function(id,piece)
        if piece==99 then return {isEmpty=true} end
        return {min={-2,-5,-3},max={2,5,3}}
    end}
Game={gameSpeed=30};GG={};gadget={}
gadgetHandler={AddChatAction=function()end,RemoveChatAction=function()end,IsSyncedCode=function()return true end}
VFS={Include=function(p)return dofile(p)end}
Spring.Echo=Spring.Echo or function()end
dofile('luarules/gadgets/gfx_cloud_volumes.lua');gadget:Initialize()
local api=GG.CloudVolume
assert(api.SetPiece(10,'GroundGases','fire'))
local revision=_G.CloudVolumeRevision
assert(api.SetPiece(10,1,'fire') and _G.CloudVolumeRevision==revision,'duplicate Show restarts animation')
assert(not api.SetPiece(10,99,'fire'),'empty mesh accepted')
assert(not api.SetPiece(10,1,'invalid'))
assert(not api.Burst('nuclear',0/0,0,0))
assert(not api.Burst('nuclear',0,0,0,0))
assert(api.Burst('nuclear',100,0,200))
gadget:UnitDestroyed(10)
assert(not _G.CloudVolumeRecords['10:1'])
assert(_G.CloudVolumeRecords['burst:1'],'destruction killed independent cloud')
frame=31*30;gadget:GameFrame(frame);assert(_G.CloudVolumeRecords['burst:1'])
frame=32*30;gadget:GameFrame(frame);assert(not next(_G.CloudVolumeRecords),'expired record leaked')
-- Visibility interception includes helpers such as showT, with radiance preserved.
local shown,hidden,lights={},{},{}
Show=function(id)shown[id]=true end
Hide=function(id)hidden[id]=true;shown[id]=nil end
ShowRadiancePiece=function(id)Show(id)end
HideRadiancePiece=function(id)Hide(id)end
GG.SetObjectiveRadiancePieceVisible=function(id,piece,on)lights[piece]=on end
unitID=10
Spring.UnitScript={Show=Show,Hide=Hide}
local helper=dofile('scripts/lib_cloud_pieces.lua')('spaceport')
ShowRadiancePiece(1)
assert(hidden[1] and not shown[1] and _G.CloudVolumeRecords['10:1'],'mesh not replaced')
assert(lights[1],'radiance emitter lost')
Show(4);assert(shown[4],'ordinary structure hidden')
HideRadiancePiece(1);assert(not _G.CloudVolumeRecords['10:1'] and lights[1]==false)
Show(1);Show(2);helper.Shutdown();assert(not next(_G.CloudVolumeRecords))
Show(1);assert(not next(_G.CloudVolumeRecords),'dead unit resurrected effect')
gadget:Shutdown();assert(not GG.CloudVolume)
-- Real pump Create/Killed: worker scheduling does not control the steady ribbon.
local starts,stops,shutdown=0,0,0
include=function(name)
    if name=='lib_cloud_pieces.lua' then return function(kind)
        assert(kind=='pump');return {Shutdown=function()end}
    end end
    if name=='lib_objective_ribbon_flames.lua' then return function()
        return {Start=function(p)starts=starts+1;assert(p==7)end,
            Stop=function()stops=stops+1 end,Shutdown=function()shutdown=shutdown+1 end}
    end end
end
piece=function(name)return name=='Igniter' and 7 or 1 end
script={};getPieceTableByNameGroups=function()return {Flame={},Flames={},FireRotor={}}end
HideRadiancePieces=function()end;Hide=function()end;StartThread=function()end
Spring.SetUnitBlocking=function()end
-- Loading must not start a flare until script.Create.
dofile('scripts/objective_pumpstationscript.lua');assert(starts==0)
script.Create();assert(starts==1 and stops==0)
script.Killed();assert(shutdown==1)
print('PASS: registry validation, idempotent Show, lifetimes, source destruction, visibility/radiance, death guards, continuous pump Create/Killed')
