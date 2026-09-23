local current,removed,sets=nil,0,0
GG={SmokeRibbon={Set=function(id,slot,piece,options)
    assert(id==7 and slot=='cigarette')
    assert(options.motionAffected and options.windAffected)
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
local investigator=create(7,false);investigator.Show(5);investigator.Shutdown()
assert(sets==before,'shared investigator script opted in')
GG.SmokeRibbon=nil;create(7,true).Show(5) -- safely tolerate unavailable gadget
print('PASS: cigarette stages, hide/show, icon mode, death, investigator exclusion, missing gadget')
