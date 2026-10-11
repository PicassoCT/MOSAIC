-- Run from the repository root: lua5.1 tests/graphene_arcs_lifecycle.lua
-- Executes the real parachute fallingDown path with bounded engine fixtures.
local registered, attached, detached, destroyed, threads = {}, {}, {}, {}, {}
local pieces = {anchor=201, Infantrz=202, step=203}
for i=1,156 do pieces['Rotator'..i] = i end
local env = setmetatable({unitID=7, script={}, Unitdefs={}, x_axis=1,y_axis=2,z_axis=3,
    CMD={MOVE=10}, GG={ParachutPassengers={[7]={id=8,x=10,y=500,z=20}}}}, {__index=_G})
env.Spring = {
    ValidUnitID=function(id) return id==7 or id==8 end,
    GetUnitIsDead=function() return false end,
    GetUnitPosition=function() return 10,500,20 end,
    GetUnitPieceMap=function() return pieces end,
    GetUnitPieceInfo=function(_,p)
        -- Deliberately coincident pivots with different scaled leaf extents.
        return {min={-p,-2,-3},max={p,40+p,60+2*p}}
    end,
    GetUnitDefID=function() return 42 end,
    GetUnitIsTransporting=function() return {} end,
    GetUnitIsCloaked=function() return false end,
    UnitAttach=function(...) attached={...} end,
    UnitDetach=function(...) detached={...} end,
    DestroyUnit=function(...) destroyed={...} end,
    MoveCtrl={SetPosition=function() end},
    Echo=function(message) error(message) end,
}
local function include(path)
    local chunk=assert(loadfile(path));setfenv(chunk,env);return chunk()
end
env.VFS={Include=include}
env.include=function() end
env.piece=function(name) return assert(pieces[name]) end
env.getOperativeTypeTable=function() return {[42]=true} end
env.waitTillComplete=function() end
env.Sleep=function() end
env.StartThread=function(fn,...) threads[#threads+1]={fn,...} end
env.showT=function() end
env.isUnitAlive=function() return true end
env.isPieceAboveGround=function() return false end
env.WMove=function() end
local config=include('luarules/gadgets/include/smoke_ribbon_config.lua')
env.GG.SmokeRibbon={Set=function(unitID,slot,piece,options)
    registered[#registered+1]={slot=slot,record=config.Normalize(unitID,piece,options)}
    return true
end}
include('scripts/parachutscript.lua')
env.TablesOfPiecesGroups={Rotator={},Cord={301,302}}
for i=1,156 do env.TablesOfPiecesGroups.Rotator[i]=i end
env.fallingDown()
assert(#registered==4,'electrical effects no longer have a bounded four-emitter budget')
assert(#threads==1 and threads[1][1]==env.Strandanimation,'original polygon animation was lost')
local selected={1,40,79,118}
for i,effect in ipairs(registered) do
    local r=effect.record
    assert(r.piece==selected[i],'emitter sampling no longer spans the animated sheets')
    assert(r.rootOffset[2]==40+r.piece and r.rootOffset[3]==60+2*r.piece,
        'discharge still attaches to the coincident pivot instead of the outer sheet tip')
    assert(r.mode=='electric' and r.strands==4,'parachute fell back to the generic smoke profile')
    assert(r.directionSpace=='world' and r.direction[1]==0 and r.direction[2]==1 and r.direction[3]==0,
        'animated sheet rotations pointed the electrical plume downward')
    assert(r.width==18 and r.length==190 and r.drawInIcon,'electrical canopy lost its visible scale')
    assert(r.colorStart[1]==0.8 and r.colorEnd[2]==0.7 and r.colorEnd[3]==1,
        'original cyan/blue electrical colours were changed')
end
assert(attached[1]==7 and attached[2]==8 and attached[3]==pieces.step,
    'visual repair changed live passenger attachment')
assert(detached[1]==8 and destroyed[1]==7,'visual repair changed landing teardown')
local preset=include('scripts/lib_graphene_arc.lua')
env.Spring.GetUnitPieceInfo=function() return nil end
local offset=preset.OuterTip(7,1)
assert(offset[1]==0 and offset[2]==0 and offset[3]==0,'missing piece bounds produced an invalid offset')
print('PASS: real parachute registration, separate animated tip attachments, four-emitter budget, original colours/animation, live passenger attachment and teardown')
