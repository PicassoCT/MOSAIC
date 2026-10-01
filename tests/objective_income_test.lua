local Income=dofile('luarules/gadgets/include/objective_income.lua')
local config={ReferenceServerCount=3,ServerNetworkBonus=1,StrategyIncomeFraction=.5,
    BaseRiskWeight=1,ExposureRiskWeight=1,PressureRiskWeight=1,PressureSeconds=30,PressureDamageFraction=.2}
local function near(a,b)assert(math.abs(a-b)<1e-6,tostring(a)..' ~= '..tostring(b))end
local function setup(base,fps,cfg)
    local s={records={},money={},byUnit={},dead={},starts={[1]={0,500},[2]={1000,500},[3]={0,500}},
        allied=false,sides={protagon={[1]=true},antagon={[2]=true}},clock={frame=0}}
    local Spring={
        GetGameFrame=function()return s.clock.frame end,
        GetTeamInfo=function(id)return id,nil,s.dead[id] or false end,
        GetTeamStartPosition=function(id)local p=s.starts[id];if not p then return -1,0,-1 end;return p[1],0,p[2]end,
        AreTeamsAllied=function(a,b)return a==b or s.allied end,
    }
    s.api=Income.New(Spring,{gameSpeed=fps or 30,mapSizeX=1000,mapSizeZ=1000},cfg or config,base or 5,s.sides,
        function(amount,team,id)
            s.money[team]=(s.money[team] or 0)+amount
            s.byUnit[id]=(s.byUnit[id] or 0)+amount
        end,function()return s.records end,s.clock)
    local nextID=0
    function s.new(x,pro,frame)
        nextID=nextID+1
        local r={uid=nextID,x=x or 0,z=500,boolProProtagon=pro~=false}
        s.api.Register(r,frame or 0);s.records[#s.records+1]=r;return r
    end
    function s.pay(frame)for _,r in ipairs(s.records)do s.api.Pay(r,frame)end end
    function s.total()local n=0;for _,v in pairs(s.money)do n=n+v end;return n end
    return s
end

-- A medium three-server strategy earns 3*(5+3)=24 money/s. All objectives
-- together earn half that, regardless of objective count or payout cadence.
for _,n in ipairs({1,2,4,8,16,64})do
    local s=setup()
    for _=1,n do local r=s.new(500);near(s.api.Rate(r,0),12/#s.records)end
    s.pay(1800);near(s.total(),720)
    for _,r in ipairs(s.records)do near(s.byUnit[r.uid],720/n)end
end

-- Risk redistributes the pool: quiet home weight 1, forward weight 2.
local s=setup();local home=s.new(0);local forward=s.new(1000)
near(s.api.Exposure(home),0);near(s.api.Exposure(forward),1)
near(s.api.Rate(home,0),4);near(s.api.Rate(forward,0),8)
s.api.Damage(forward,0,3000,15000,2,false)
near(s.api.Rate(home,0),3);near(s.api.Rate(forward,0),9)
s.pay(900);near(s.total(),360);near(s.api.Rate(forward,900),8)
-- Integral of forward share while weight decays 3 -> 2 against home weight 1.
near(s.byUnit[forward.uid],12*(30+30*math.log(3/4)))
s.pay(1800);near(s.total(),720)

-- Full and partial pressure stop at different times. Exact integration must
-- be independent of payout frequency, including under sustained fire.
local function sustained(payout)
    local t=setup();local a=t.new(0);local b=t.new(500,false);local c=t.new(1000)
    for f=0,1799,3 do
        if f%90==0 then t.api.Damage(a,f,400,15000,2,false)end
        if f%210==0 then t.api.Damage(b,f,1700,15000,1,false)end
        if f%51==0 then t.api.Damage(c,f,3000,15000,2,false)end
        if f>0 and f%payout==0 then t.pay(f)end
        if f%30==0 then
            local rate=0;for _,r in ipairs(t.records)do rate=rate+t.api.Rate(r,f)end;near(rate,12)
        end
    end
    t.pay(1800);near(t.total(),720);return t.byUnit
end
local frequent,rare=sustained(30),sustained(1800)
for id,money in pairs(frequent)do near(money,rare[id])end

-- A last-moment hit cannot back-pay a minute's pressure bonus.
s=setup();home=s.new(0);forward=s.new(1000)
s.api.Damage(forward,1797,3000,15000,2,false);s.pay(1800)
assert(s.byUnit[forward.uid]>480 and s.byUnit[forward.uid]<480.11);near(s.total(),720)

-- Friendly fire, allied opposite-side teams, paralysis and invalid damage.
s=setup();home=s.new(0);forward=s.new(1000)
for _,args in ipairs({{3000,1,false},{3000,0,false},{3000,2,true},{-100,2,false},{math.huge,2,false},{0/0,2,false}})do
    s.api.Damage(forward,0,args[1],15000,args[2],args[3]);near(s.api.Rate(forward,0),8)
end
s.api.Damage(forward,0,3000,15000,nil,false);near(s.api.Rate(forward,0),8)
s.allied=true;s.api.Damage(forward,0,3000,15000,2,false);near(s.api.Rate(forward,0),8)

-- One map budget, split between living teammates rather than duplicated.
s=setup();s.sides.protagon[3]=true;home=s.new(0)
s.pay(1800);near(s.money[1],360);near(s.money[3],360)
s.dead[3]=true;s.pay(3600);near(s.money[1],1080);near(s.money[3],360)
s.dead[1]=true;s.pay(5400);near(s.total(),1440)

-- Unknown starts use public centrality; no hidden-unit query API exists.
s=setup();s.starts[1]=nil;s.starts[2]=nil;home=s.new(500)
near(s.api.Exposure(home),1);home.x=0;near(s.api.Exposure(home),0)

-- Future server rebalance, benchmark count and simulation speed.
s=setup(2.5,60);home=s.new(0);s.pay(1800);near(s.total(),247.5)
local cfg={};for k,v in pairs(config)do cfg[k]=v end;cfg.ReferenceServerCount=2
s=setup(5,30,cfg);home=s.new(0);s.pay(1800);near(s.total(),420)

-- A new site joins only from its creation frame, not retroactively.
s=setup();home=s.new(500);forward=s.new(500,true,900);s.pay(1800)
near(s.byUnit[home.uid],540);near(s.byUnit[forward.uid],180);near(s.total(),720)

-- Capture settles actual holding time and clears inherited pressure.
s=setup();home=s.new(500);forward=s.new(500)
s.api.Damage(home,0,3000,15000,2,false);s.api.Pay(home,1799)
s.records[1]=nil -- replace immediately; no time passes with a missing record
home.boolProProtagon=false;s.api.Register(home,1799);s.records[1]=home
near(home.income.pressure,0);s.pay(1800);near(s.money[2],6/30);near(s.total(),720)

-- Missing models retain a site's allocation but cannot earn. Restoration
-- starts earning at actual creation, so destroying markers cannot inflate
-- the remaining sites' shares while the replacement is queued.
s=setup();home=s.new(500);forward=s.new(500);forward.uid=nil
s.pay(900);near(s.total(),180);near(s.api.Rate(home,900),6);near(s.api.Rate(forward,900),0)
forward.uid=2;s.api.Register(forward,900);s.pay(1800)
near(s.byUnit[1],360);near(s.byUnit[2],180);near(s.total(),540)

print('Objective income: strategy budget, count/risk allocation, conservation, timing, pressure, teams and pending sites PASS')
