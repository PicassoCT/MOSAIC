local logs={}
Spring={AreTeamsAllied=function(a,b) return a==b end,GetUnitTeam=function() return 2 end,
 Echo=function(s) logs[#logs+1]=s end}
local factory=dofile('luarules/gadgets/prometheus/adaptation.lua')
local caps={servers=3,operatives=3,assets=2,scouts=2,combat=8,agents=2}
local function fresh() return factory(1,0,caps) end
local tank={name='tank',metalCost=3000,weapons={{}},speed=30}
local soldier={name='operativeasset',metalCost=1000,weapons={{}},speed=30}
local civilian={name='civilian_western0',metalCost=0,weapons={},speed=20}
local ai=fresh()
ai.Damaged(10,500,false,2,100);ai.Lost(10,soldier,110)
ai.Damaged(11,500,false,2,200);ai.Lost(11,soldier,210)
ai.Update(659);assert(ai.tier==0,'do not escalate mid-fight or per kill')
ai.Update(660);assert(ai.tier==1 and ai.opponentVictories==1,'one won fight raises one tier')
ai.Update(5000);assert(ai.tier==1,'idle time is not a victory')
for n=1,10 do
 local t=n*6000
 ai.Damaged(20,500,false,2,t);ai.Lost(20,soldier,t);ai.Update(t+450)
end
assert(ai.tier==6 and ai.opponentVictories==11,'bounded escalation still tracks every victory')
local grown=ai.Caps();assert(grown.combat>caps.combat and grown.servers>caps.servers)
assert(caps.combat==8,'base profile was mutated')
ai=fresh()
ai.Lost(10,soldier,10);ai.Update(1000);assert(ai.tier==0,'self destruction is not a hostile victory')
ai.Damaged(10,100,false,0,10);ai.Lost(10,soldier,11);ai.Update(1000);assert(ai.tier==0,'neutral damage is excluded')
ai.Damaged(10,100,true,2,10);ai.Lost(10,soldier,11);ai.Update(1000);assert(ai.tier==0,'paralysis is not a casualty')
ai.Damaged(10,100,false,2,10);ai.Lost(10,civilian,11);ai.Update(1000);assert(ai.tier==0,'unarmed civilians do not farm tiers')
ai.Damaged(10,100,false,2,2000);ai.Forget(10);ai.Lost(10,soldier,2001);ai.Update(3000);assert(ai.tier==0,'transfer is not a combat loss')
ai.Damaged(10,100,false,2,4000);ai.Lost(10,soldier,5001);ai.Update(6000);assert(ai.tier==0,'stale damage is not a combat loss')
local home={x=0,z=0}
local function target(id,def,x) return {id=id,def=def,kind='enemy',pos={x=x or 3000,z=0}} end
ai.Observe({target(40,tank)},home,6100)
assert(ai.mode=='armor' and ai.visible==1 and ai.material==3000)
ai.Damaged(10,100,false,2,6100);ai.Lost(10,soldier,6110)
ai.EnemyDestroyed(40,1,6120);ai.Update(6570)
assert(ai.tier==0 and ai.won==1,'winning a favorable trade does not reward the opponent')
ai.Observe({target(50,{name='gunship',canFly=true,metalCost=2000,weapons={{}}})},home,7000)
assert(ai.mode=='air')
ai.Observe({},home,8000);assert(ai.mode=='air' and ai.visible==0,'brief LOS loss retains learned counters')
ai.Observe({},home,9801);assert(ai.mode=='balanced','old sightings eventually expire')
ai.Observe({target(51,soldier,400)},home,10000);assert(ai.mode=='raids','react to approaches to our economy')
ai.Observe({},home,13000)
ai.EnemyDestroyed(999,1,13001);ai.Update(14000);assert(ai.won==1,'hidden casualties are not counted')
ai.Observe({target(60,tank)},home,15000);ai.EnemyDestroyed(60,1,15100);ai.Update(16000)
assert(ai.won==1,'stale hidden target deaths are not counted')
print('PASS: conflict outcomes, bounded escalation, observed counters, LOS memory, transfers and neutral/stale exclusions')
