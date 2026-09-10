-- Standalone behavioral test: lua tests/asset_rooftop_test.lua
local frame = 0
local current, attached, controlled, modes = {}, {}, {}, {}
local pos = {[1]={0,0,0},[10]={500,0,0},[11]={900,0,0}}
local defs = {[1]=1,[10]=2,[11]=2}
CMD = {MOVE=10,ATTACK=20,STOP=0,INSERT=1}
CMDTYPE = {ICON_UNIT=12}
CMD_ASSET_ROOFTOP=33456
UnitDefNames={operativeasset={id=1}}
UnitDefs={[1]={id=1},[2]={id=2,isBuilding=true}}
gadget={}
gadgetHandler={IsSyncedCode=function() return true end,RegisterCMDID=function() end}
VFS={Include=function() end}
getHouseTypeTable=function() return {[2]=true} end
local env={getRooftopPieces=function() return {1,2,3} end}
Spring={
    ValidUnitID=function(id) return pos[id] ~= nil end,
    GetUnitIsDead=function() return false end,
    GetUnitDefID=function(id) return defs[id] end,
    GetUnitPosition=function(id) return (table.unpack or unpack)(pos[id]) end,
    GetUnitPiecePosDir=function(id,piece) return 420+piece*60,120,0 end,
    GetUnitTransporter=function(id) return attached[id] end,
    UnitDetach=function(id) attached[id]=nil end,
    UnitAttach=function(h,id,piece) assert(not controlled[id]); attached[id]=h end,
    GetUnitRadius=function() return 100 end,
    GetGroundHeight=function() return 0 end,
    SetUnitMoveGoal=function(id,x,y,z,r) pos[id]={x-r,y,z} end,
    ClearUnitGoal=function() end,
    GetGameFrame=function() return frame end,
    GetUnitCurrentCommand=function(id) local c=current[id]; if c then return c[1],0,c[2] end end,
    SetUnitRulesParam=function() end,
    GetHeadingFromVector=function() return 0 end,
    UnitScript={GetScriptEnv=function(id)
        if id ~= 1 then return env end
        return {setRooftopMotion=function(mode) modes[1]=mode end,onRooftop=function() end}
    end,CallAsUnit=function(id,fn,...) return fn(...) end},
    MoveCtrl={Enable=function(id) controlled[id]=true end,
        Disable=function(id) controlled[id]=false end,
        IsEnabled=function(id) return controlled[id] end,
        SetPosition=function(id,x,y,z) pos[id]={x,y,z} end,
        SetVelocity=function() end,SetHeading=function() end},
}
dofile('luarules/gadgets/game_sniperPosition.lua')
local function order(params,tag)
    current[1]={CMD_ASSET_ROOFTOP,tag}
    return gadget:CommandFallback(1,1,0,CMD_ASSET_ROOFTOP,params,{},tag)
end
local function tick(n)
    for i=1,n do frame=frame+3; gadget:GameFrame(frame) end
end
local ray={10,600,1000,0,0,-1,0}
assert(gadget:AllowCommand(1,1,0,CMD_ASSET_ROOFTOP,ray,{}))
assert(not gadget:AllowCommand(1,1,0,CMD_ASSET_ROOFTOP,{10,0/0,0,0,0,-1,0},{}))
assert(not gadget:AllowCommand(1,1,0,CMD.ATTACK,{10},{}))
assert(gadget:AllowCommand(1,1,0,CMD.ATTACK,{1},{}))
order(ray,1); tick(1)
assert(not attached[1], 'distant roof must require approach')
tick(100)
assert(attached[1]==10 and modes[1]=='idle','approach, grapple, walk, attach')
local _,done=order(ray,1); assert(done)
current[1]=nil; tick(3); assert(attached[1]==10,'empty queue stays on roof')
-- Same roof retarget starts at the current roof position without ground teleport.
local before=pos[1][2]
order({10,480,1000,0,0,-1,0},2)
assert(controlled[1] and not attached[1] and pos[1][2]==before)
tick(100); assert(attached[1]==10)
-- Stop/new command releases attachment and MoveCtrl.
current[1]={CMD.STOP,3}; tick(1)
assert(not attached[1] and not controlled[1] and not modes[1])
assert(pos[1][2]==0,'release returns to approach ground position')
order(ray,4); tick(3)
current[1]={CMD.MOVE,5}; tick(1)
assert(not controlled[1] and not attached[1],'cancel during grapple')
order(ray,6); tick(100)
gadget:UnitDestroyed(10)
assert(not controlled[1] and not attached[1],'building destruction cleanup')
-- A building-only order approaches but does not mount an arbitrary tile.
order({11},7); tick(3)
local _,done=order({11},7); assert(done and not attached[1])
print('PASS: validation, approach, grapple, traversal, occupancy, retarget, cancellation, destruction, facade')

-- UI integration: movement conversion, mixed selections, Shift preservation.
widget = {}
local sent = {}
Spring.GetMouseState=function() return 100,100 end
Spring.TraceScreenRay=function(x,y,coords)
    if coords then return "ground",{600,0,0} end
    return "unit",10
end
Spring.IsAboveMiniMap=function() return false end
Spring.GetCameraPosition=function() return 600,1000,0 end
Spring.GetSelectedUnits=function() return {1,2} end
defs[2]=3; UnitDefs[3]={id=3,name="other"}
Spring.GiveOrderToUnitArray=function(ids,cmd,p,opts) sent[#sent+1]={ids,cmd,p,opts} end
dofile('luaui/widgets_mosaic/cmd_asset_rooftop.lua')
assert(widget:CommandNotify(CMD.MOVE,{600,0,0},{shift=true}))
assert(#sent==2 and sent[1][1][1]==1 and sent[1][2]==CMD_ASSET_ROOFTOP)
assert(sent[1][4][1]=='shift' and sent[2][2]==CMD.MOVE and sent[2][1][1]==2)
assert(widget:DefaultCommand('unit',10)==nil,'mixed selection default unchanged')
Spring.GetSelectedUnits=function() return {1} end
assert(widget:DefaultCommand('unit',10)==CMD_ASSET_ROOFTOP)
print('PASS: movement conversion, mixed selection, Shift, contextual roof cursor')
