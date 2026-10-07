local records, calls = {}, 0
GG={SmokeRibbon={Set=function(unit,slot,piece,options)
    assert(piece and options.directionSpace=='world')
    assert(options.windAffected)
    assert(options.motionAffected==(slot=='objective-slagcrane'))
    assert(options.colorEnd[4]==0 and options.emission[1]>1)
    records[unit..slot]={piece=piece,options=options};calls=calls+1
    return true
end,Remove=function(unit,slot) records[unit..slot]=nil end}}
Spring={Echo=function(message) error(message) end}
local create=dofile('scripts/lib_objective_ribbon_flames.lua')
for i,kind in ipairs({'pump','industrial','launch','slagheap','slagcrane'}) do
    local flame=create(i,kind)
    assert(flame.Start(10+i,99))
    local key=i..'objective-'..kind
    assert(records[key].options.direction[2]==(kind=='launch' and -1 or 1))
    if kind=='launch' then
        local o=records[key].options
        assert(o.mode=='landing' and o.padPiece==99 and o.strands==4,'launch lost pad streamers')
        assert(o.distanceCulling==false and o.drawInIcon,'flight exhaust can disappear at distance')
    end
    flame.Start(20+i,99);assert(records[key].piece==20+i,'repeat ignition must replace the same slot')
    flame.Stop();assert(records[key]==nil,'extinction left a flame active')
    assert(flame.Start(10+i,99),'reignition failed')
    flame.Shutdown();assert(records[key]==nil)
    local before=calls;flame.Start(10+i);assert(calls==before,'dead objective restarted flame')
end
GG.SmokeRibbon=nil;assert(not create(1,'pump').Start(1))
print('PASS: objective flame presets, launch streamers, directions, gradients, wind, replacement, extinction, reignition, death and missing gadget')
