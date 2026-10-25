-- Exercise the production helper at the truck's existing 100 ms cadence.
local file=assert(io.open('scripts/lib_UnitScript.lua'))
local source=file:read('*a');file:close()
local helper=assert(source:match('(function transferAttackOrder%([^\n]*\n.-\nend)'))
CMD={ATTACK=20,FIGHT=16,STOP=0,MOVE=10}
local queues,orders,reads={},0,0
Spring={
    GetUnitCommands=function(id,count)
        assert(count==1,'only the current command is needed')
        reads=reads+1;return queues[id] or {}
    end,
    GiveOrderToUnit=function(id,command,params)
        orders=orders+1
        local copy={};for i,v in ipairs(params)do copy[i]=v end
        queues[id]={{id=command,params=copy}}
    end,
}
assert((loadstring or load)(helper))()
queues[1]={{id=CMD.ATTACK,params={42}}}
for i=1,100 do transferAttackOrder(1,2)end
assert(orders==1 and reads==200,'ten seconds of unchanged attack must forward once')
queues[1][1].params[1]=43;transferAttackOrder(1,2)
assert(orders==2 and queues[2][1].params[1]==43)
queues[2]={};transferAttackOrder(1,2)
assert(orders==3,'an interrupted gun command must be restored')
transferAttackOrder(1,3)
assert(orders==4,'a replacement mounted gun must receive the order')
queues[1]={{id=CMD.FIGHT,params={10,20,30}}}
transferAttackOrder(1,2);transferAttackOrder(1,2)
assert(orders==5)
queues[1][1].params[3]=31;transferAttackOrder(1,2)
assert(orders==6 and queues[2][1].params[3]==31)
queues[1]={{id=CMD.MOVE,params={40,20,30}}};transferAttackOrder(1,2)
assert(orders==6,'a sidestep must leave the mounted gun targeting')
queues[1]={{id=CMD.STOP,params={}}};transferAttackOrder(1,2)
assert(orders==7 and queues[2][1].id==CMD.STOP)
queues[2]={{id=CMD.ATTACK,params={42}}};queues[1]={};transferAttackOrder(1,2)
assert(orders==8 and queues[2][1].id==CMD.STOP,'idle parent still clears its gun')
print('PASS: truck attack forwarding preserves locks, changed targets, interrupted orders, replacement guns and stops')
