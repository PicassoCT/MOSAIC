function include(name)return dofile('scripts/'..name)end
local pole=include('lib_tiglil_pole.lua')
local signatures,directions,accents={},{},{}
local minTime,maxTime=math.huge,0
for seed=1,40 do
    math.randomseed(seed)
    local sequence=pole.compose()
    local seen,signature,time={}, {},0
    local floorStarted=false
    local bridgeRises,bridgeLowers=0,0
    local direction=sequence[2].angle<0 and -1 or 1
    for _,p in ipairs(sequence)do if p.angle~=0 then direction=p.angle<0 and -1 or 1;break end end
    directions[direction]=true
    local previous=0
    for _,p in ipairs(sequence)do
        assert(p.ms>=400 and p.ms<4000,'component timing became unreadable')
        assert((p.angle-previous)*direction>=-1e-7,'orbit reverses inside a component')
        previous=p.angle;time=time+p.ms
        seen[p.name]=(seen[p.name]or 0)+1
        if p.name=='raised stag hold' or p.name=='long-leg diagonal hold' or p.name=='supported pike hold' then
            accents[p.name]=true
            assert(p.freeLeft==0 and p.freeRight==0,'new aerial accent lost its two-hand support')
        end
        signature[#signature+1]=p.name..':'..p.ms..':'..p.angle
        assert(p.freeLeft==0 or p.freeRight==0,'aerial pose releases both hands')
        if p.name=='open overhead split' or p.name=='hold overhead split' then
            assert(math.abs(p.angle%180-90)<1e-6,'inversion is not aligned for native Euler motion')
            assert(p.leftKnee==0 and p.rightKnee==0 and p.leftSpread==-90 and p.rightSpread==90)
        end
        if (p.floorBlend or 0)>0 then
            assert(seen['controlled descent'],'floor work begins before descent')
            assert(p.angle%180==0,'floor entry is not aligned')
            floorStarted=true
        elseif floorStarted then assert(p.name=='stand from floor','unsupported aerial transition after floor work')end
        if p.name=='floor bridge rise' then bridgeRises=bridgeRises+1;assert(p.bridge>=.7 and p.bridge<=1)end
        if p.name=='floor bridge lower' then bridgeLowers=bridgeLowers+1 end
    end
    for _,name in ipairs({'tucked spin','first climb','second climb','sideways tucked hold','hold overhead split','extended-leg turn','side flourish','fan kick sweep','controlled descent','lowering lunge','stand from floor'})do
        assert(seen[name],name..' lost from composition')
    end
    local accentCount=0
    for _,name in ipairs({'raised stag hold','long-leg diagonal hold','supported pike hold'})do if seen[name]then accentCount=accentCount+1 end end
    assert(accentCount==1,'each routine should contain one held accent')
    assert(bridgeRises>=2 and bridgeRises<=4 and bridgeLowers==bridgeRises)
    assert(time<80000,'composed routine is unbounded')
    minTime,maxTime=math.min(minTime,time),math.max(maxTime,time)
    signatures[table.concat(signature,';')]=true
end
assert(accents['raised stag hold'] and accents['long-leg diagonal hold'] and accents['supported pike hold'],'new pole poses are unreachable')
local count=0;for _ in pairs(signatures)do count=count+1 end
assert(count==40 and directions[-1]and directions[1],'composer lacks independent variation')
print('PASS: 40 distinct supported pole compositions, both orbit directions, all skills retained, 2–4 grounded bridge repetitions; '..minTime..'–'..maxTime..' ms')
