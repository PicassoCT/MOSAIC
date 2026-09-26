local current,removed,sets=nil,0,0
GG={SmokeRibbon={Set=function(id,slot,piece,options)
    assert(id==7 and slot=='cigarette')
    assert(options.motionAffected and options.windAffected)
    assert(options.sourceGlow[4]>0,'cigarette lost its ember glow')
    current=piece;sets=sets+1;return true
end,Remove=function() current=nil;removed=removed+1 end}}
Spring={Echo=function(msg) error(msg) end}
local create=dofile('scripts/lib_smoke_ribbon_cigarette.lua')
local smoke=create(7,true)
smoke.Show(5);assert(current==5)
smoke.Show(8);assert(current==8,'burn stage did not change emitter')
smoke.Hide(5);assert(current==8,'unrelated hidden piece stopped smoke')
smoke.Hide(8);assert(current==nil,'hidden cigarette emitted')
smoke.Show(9);smoke.SetIconMode(true);assert(current==nil)
smoke.Show(5);assert(current==nil,'icon mode re-enabled smoke')
smoke.SetIconMode(false);assert(current==nil,'hidden cigarette restored on leaving icon mode')
smoke.Show(5);assert(current==5)
smoke.Shutdown();smoke.Show(8);assert(current==nil,'death animation restarted smoke')
local before=sets
local disabled=create(7,false);disabled.Show(5);disabled.Shutdown()
assert(sets==before,'disabled preset opted in')

-- Run the female investigator's real body/icon/death hooks with her model's
-- cigarette ID. Other head decorations must not become smoke emitters.
local file=assert(io.open('scripts/operativeInvestigatorScript.lua'))
local source=file:read('*a');file:close()
local visible={}
local env=setmetatable({
    unitID=7,unitId=7,script={},upperBodyPieces={},lowerBodyPieces={},
    shownPieces={15},FoldtopFolded=20,FoldtopUnfolded=21,Icon=22,Drone=23,
    TablesOfPiecesGroups={},boolHasPonyTail=false,
    include=function(path) return dofile('scripts/'..path) end,
    piece=function(name) assert(name=='HeadDeco7');return 17 end,
    Show=function(id) visible[id]=true end,
    Hide=function(id) visible[id]=nil end,
    hideAll=function() visible={} end,
    showT=function(pieces) for _,id in pairs(pieces) do visible[id]=true end end,
    hideT=function() end,
    doesUnitExistAlive=function() return false end,
    PlayAnimation=function() end,
}, {__index=_G})
local code=assert(source:match('(local cigaretteSmoke = [^\n]+)'))..'\n'..
    assert(source:match('(local cigarette = [^\n]+)'))..'\n'..
    assert(source:match('(function showBody%(%).-\nend)'))..'\n'..
    assert(source:match('(function showHideIcon%([^\n]*.-\nend)'))..'\n'..
    assert(source:match('(function script.Killed%([^\n]*.-\nend)'))
setfenv(assert(loadstring(code,'investigator cigarette integration')),env)()
env.showBody()
assert(visible[17] and current==17,'investigator cigarette was left to random selection')
env.showHideIcon(true)
assert(visible[22] and not visible[17] and current==nil,'hidden investigator still smoked')
env.showHideIcon(false)
assert(visible[17] and not visible[22] and current==17,'reveal did not restore the cigarette')
env.script.Killed(0,0)
assert(current==nil,'death left investigator smoke active')
env.showBody()
assert(current==nil,'death animation restarted investigator smoke')

GG.SmokeRibbon=nil;create(7,true).Show(5) -- safely tolerate unavailable gadget
print('PASS: cigarette stages, hide/show, icon mode, death, investigator attachment/reveal, disabled preset, missing gadget')
