local function read(path)local f=assert(io.open(path));local s=f:read('*a');f:close();return s end
local count=2
local env=setmetatable({Spring={
    GetUnitRulesParam=function(_,key)
        if key=='mosaic_window_piece_count' then return count end
        return tonumber(key:match('mosaic_window_piece_(%d+)'))
    end,
    GetUnitPieceInfo=function(_,piece)
        assert(piece<=2,'hidden model variant used')
        return {min={0,0,0},max={10,20,30},isEmpty=piece==2}
    end,
    GetUnitPieceMatrix=function()return 35,0,0,0,0,0,-35,0,0,35,0,0,100,200,300,1 end,
    GetUnitTransformMatrix=function()return 0,0,-1,0,0,1,0,0,1,0,0,0,1000,50,2000,1 end,
}},{__index=_G})
local bounds=assert(load(read('luaui/widgets_mosaic/include/window_bounds.lua'),'bounds','t',env))()
local b=assert(bounds.Read(42))
assert(b.x==950 and b.z==1725 and b.y==228.125,'piece or unit transform applied incorrectly')
assert(b.span==743.75 and b.height==1093.75,'import scale or rotation lost')
count=nil;local missing,reason=bounds.Read(42);assert(not missing and reason:find('piece list'))

-- Execute the actual script publication hook: selected facade pieces only,
-- deduplicated; far ground furniture must not inflate the capture bounds.
local published={}
local script=read('scripts/house_asian_standalone_script.lua')
local section=assert(script:match('(local windowGeometryRevision = 0.-)function buildAnimation'))
local scriptEnv=setmetatable({unitID=42,ToShowTable={1,1,2,3},
    pieceNr_pieceName={[1]='Project17',[2]='Placeable42',[3]='Project17Spin1'},
    Spring={SetUnitRulesParam=function(id,key,value,visibility)
        assert(id==42 and visibility.inlos);published[key]=value
    end},showT=function()end,hideT=function()end,SetRadiancePlaceables=function()end,
},{__index=_G})
assert(load(section,'script bounds','t',scriptEnv))()
scriptEnv.showHouse()
assert(published.mosaic_window_piece_count==2 and published.mosaic_window_piece_1==1 and published.mosaic_window_piece_2==3)
assert(published.mosaic_window_revision==1)
scriptEnv.hideHouse();assert(published.mosaic_window_revision==-2)
local manager=read('luaui/mosaicwidgets.lua')
local dispatch=assert(manager:match('(function widgetHandler:UnsyncedHeightMapUpdate%(%...%).-)function widgetHandler:ViewResize'))
local calls=0
local handler={UnsyncedHeightMapUpdateList={{UnsyncedHeightMapUpdate=function(self,x1,z1,x2,z2)
    assert(x1==10 and z1==20 and x2==30 and z2==40);calls=calls+1
end}}}
assert(load(dispatch,'terrain callback','t',setmetatable({widgetHandler=handler},{__index=_G})))()
handler:UnsyncedHeightMapUpdate(10,20,30,40);assert(calls==1)
handler.UnsyncedHeightMapUpdateList={};handler:UnsyncedHeightMapUpdate(0,0,0,0);assert(calls==1)
print('PASS: selected-piece bounds, import scale/rotation, unit transform, missing metadata, hidden variants and distant placeable exclusion')
