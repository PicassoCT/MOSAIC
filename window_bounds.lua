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

-- The procedural authoring model and every split variant use this script.
-- Exercise both reveal paths, then damage, hiding and death publication.
local asian=read('scripts/house_asian_script.lua')
local hooks=assert(asian:match('(local function updateWindowGeometryRevision%(%).-)function addGroundPlaceables'))
local killed=assert(asian:match('(function script.Killed%b().-)\nfunction showOneDeterministic'))
for _,reconstruction in ipairs({false,true}) do
    local rules={mosaic_window_revision=0}
    local plan={1,1,2,3}
    local shown={}
    local function showing(p) shown[p]=true end
    local function hiding(p) shown[p]=nil end
    local e=setmetatable({unitID=42,script={},ToShowTable=plan,toShowDict={[1]=1,[2]=2,[3]=3},
        pieceNr_pieceName={[1]='Office_Wall1',[2]='Placeable42',[3]='Industrial_Wall2'},
        boolDoneShowing=true,boolHouseHidden=false,Icon=9,
        GG={ManualRenderedBuildingWithWindowsVisiblePieces={}},LevelPieces={},
        Spring={SetUnitRulesParam=function(id,key,value,visibility)
            assert(id==42 and visibility.inlos);rules[key]=value
        end},Show=showing,Hide=hiding,
        showT=function(t)for _,p in ipairs(t) do showing(p) end end,
        hideT=function(t)for _,p in ipairs(t) do hiding(p) end end,
        SetRadiancePlaceables=function()end,initAllPieces=function()end,Sleep=function()end,
        sortPiecesInDictionaryByHeight=function()return {1,2,3}end,
        waitForCityConstruction=function()
            assert(rules.mosaic_window_revision==0,'partial reconstruction emitted window light')
        end,
        houseAnimations={start=function()end,stop=function()end},
    },{__index=_G})
    e.buildingDamage={collapse=function()
        e.OnBuildingGeometryChanged()
        assert(rules.mosaic_window_revision<0,'collapse resurrected window lighting')
    end}
    assert(load('local windowGeometryRevision,windowGeometryReady=0,false;local animationsReady=false\n'..
        hooks..killed,'procedural window hooks','t',e))()
    e.OnBuildingGeometryChanged();assert(rules.mosaic_window_revision==0)
    e.buildAnimation(reconstruction)
    assert(rules.mosaic_window_revision==1 and rules.mosaic_window_piece_count==2)
    assert(rules.mosaic_window_piece_1==1 and rules.mosaic_window_piece_2==3)
    assert(shown[1] and shown[3] and not shown[9],'captured before facade reveal or with construction icon')
    e.hideHouse();assert(rules.mosaic_window_revision==-2)
    e.OnBuildingGeometryChanged();assert(rules.mosaic_window_revision==-3)
    e.showHouse();assert(rules.mosaic_window_revision==4)
    table.remove(plan,4);e.OnBuildingGeometryChanged()
    assert(rules.mosaic_window_revision==5 and rules.mosaic_window_piece_count==1,
        'removed facade retained its cached capture bounds')
    e.OnBuildingGeometryChanged();assert(rules.mosaic_window_revision==6,'settled geometry not republished')
    e.script.Killed(1,1);assert(rules.mosaic_window_revision==-7)
end
local manager=read('luaui/mosaicwidgets.lua')
local dispatch=assert(manager:match('(function widgetHandler:UnsyncedHeightMapUpdate%(%...%).-)function widgetHandler:ViewResize'))
local calls=0
local handler={UnsyncedHeightMapUpdateList={{UnsyncedHeightMapUpdate=function(self,x1,z1,x2,z2)
    assert(x1==10 and z1==20 and x2==30 and z2==40);calls=calls+1
end}}}
assert(load(dispatch,'terrain callback','t',setmetatable({widgetHandler=handler},{__index=_G})))()
handler:UnsyncedHeightMapUpdate(10,20,30,40);assert(calls==1)
handler.UnsyncedHeightMapUpdateList={};handler:UnsyncedHeightMapUpdate(0,0,0,0);assert(calls==1)
print('PASS: selected-piece bounds, import scale/rotation, unit transform, missing metadata, hidden variants, distant placeable exclusion, procedural construction/reconstruction, hide/reveal, damage and death')
