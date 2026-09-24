local frame=30
Game={gameSpeed=30};GG={};gadget={}
gadgetHandler={AddChatAction=function()end,RemoveChatAction=function()end,IsSyncedCode=function()return true end}
VFS={Include=function(p)return dofile(p)end}
Spring={GetGameFrame=function()return frame end,ValidUnitID=function()return true end,
 GetUnitPieceInfo=function()return {min={1,-2,-3},max={3,2,3}}end,
 GetUnitPiecePosDir=function()return 10,20,30 end,
 GetUnitVectors=function()return {0,0,1},{0,1,0},{-1,0,0}end,
 GetUnitPieceMatrix=function()return 1,0,0,0,0,1,0,0,0,0,1,0,9,8,7,1 end}
Spring.Echo=Spring.Echo or function()end
dofile('luarules/gadgets/gfx_cloud_volumes.lua');gadget:Initialize()
local api=GG.CloudVolume
assert(api.SetPiece(1,2,'steam'));frame=90
api.ReleasePiece(1,2)
local r=CloudVolumeRecords['burst:1']
assert(r and not r.unitID and not CloudVolumeRecords['1:2'])
assert(r.x==12 and r.y==20 and r.z==30,'offset center transformed incorrectly')
assert(r.born==30 and r.duration==45,'release restarted fade')
assert(math.abs(r.worldHalf[1]-1.2)<.0001 and math.abs(r.worldHalf[3]-3.6)<.0001)
api.ReleasePiece(1,2);assert(not CloudVolumeRecords['burst:2'],'duplicate Hide emitted cloud')
assert(api.SetPiece(1,2,'steam'),'next cycle cannot restart')
gadget:UnitDestroyed(1);assert(CloudVolumeRecords['burst:1'],'released smoke followed source death')
frame=46*30;gadget:GameFrame(frame);assert(not next(CloudVolumeRecords),'world tail leaked')
assert(api.SetPiece(1,3,'flameTongue'));api.ReleasePiece(1,3)
assert(not next(CloudVolumeRecords),'flame tongue lingered')
print('PASS: release coordinates, original age, duplicate Hide, restart, death survival, expiry, fire cutoff')
