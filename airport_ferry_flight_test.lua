-- Real airport ferry helper, with concurrent flights and finite yaw rate.
local source = 'scripts/'
local clock, tracks, moves, rotations, shown = 0,{},{},{},{}
local departingCarrier=false
local ferryYaw=0
local turnTargets,headings,turnLog={},{},{}
local parent = {0,0,-2,0, 0,2,0,0, 2,0,0,0, 100,20,300,1}
local function transform(m,p)
    return {m[13]+m[1]*p[1]+m[5]*p[2]+m[9]*p[3],
            m[14]+m[2]*p[1]+m[6]*p[2]+m[10]*p[3],
            m[15]+m[3]*p[1]+m[7]*p[2]+m[11]*p[3]}
end
local function restMatrix(x,y,z)
    return {1,0,0,0, 0,0,1,0, 0,-1,0,0, x,y,z,1}
end
local ferries = {[1]={50,0,0},[2]={-80,0,20}}
Spring = {
    GetUnitPieceMap=function() return {root=10} end,
    GetUnitPieceInfo=function(_,p)
        if ferries[p] then return {parent='root',offset=ferries[p],min={-10,-20,-5},max={10,20,5}} end
        return {parent='root',offset={0,0,0},min={-200,-150,-30},max={200,150,30}}
    end,
    GetUnitPieceMatrix=function(_,p)
        if p==10 then return unpack(parent) end
        if ferries[p] then
            local pos=transform(parent,ferries[p]);local m=restMatrix(unpack(pos))
            m[1],m[3],m[5],m[7]=math.cos(ferryYaw),-math.sin(ferryYaw),math.sin(ferryYaw),math.cos(ferryYaw)
            return unpack(m)
        end
        local escape=departingCarrier and clock>1 and 100000 or 0
        return unpack(restMatrix(1000+clock*80+escape,1000,2000+clock*40))
    end,
}
function Move(p,axis,destination,speed)
    assert(destination==destination and speed==speed and speed<math.huge, 'non-finite animation')
    moves[p]=moves[p] or {}; moves[p][axis]=destination
end
function Turn(p,axis,angle,speed)
    assert(axis==3 and angle==angle and speed==speed)
    turnTargets[p]={angle=angle,speed=speed}
    if speed==0 then rotations[p]=angle end
    turnLog[#turnLog+1]={piece=p,angle=angle,speed=speed,time=clock}
end
local function sample(p)
    local delta=moves[p] or {0,0,0};local home=ferries[p]
    return transform(parent,{home[1]+delta[1],home[2]+delta[2],home[3]+delta[3]})
end
function Show(p)
    shown[p]=true
    if ferries[p] then tracks[p]={sample(p)};headings[p]={rotations[p]} end
end
function Sleep(ms) coroutine.yield(ms) end
local flight = assert(loadfile(source..'lib_airport_ferry_flight.lua'))()(42)
local function launch(p,up,time,variation)
    return coroutine.create(function() flight(p,p+20,30,31,time,up,p,variation) end)
end
local function run(list)
    for _=1,1000 do
        local alive=false
        for _,co in ipairs(list) do
            if coroutine.status(co)~='dead' then
                local ok,ms=coroutine.resume(co);assert(ok,ms)
                if ms then assert(ms==100);alive=true end
            end
        end
        if not alive then return end
        for p,track in pairs(tracks) do
            local turn=turnTargets[p]
            local delta=turn.angle-rotations[p]
            rotations[p]=rotations[p]+math.max(-turn.speed*0.1,math.min(turn.speed*0.1,delta))
            track[#track+1]=sample(p)
            headings[p][#headings[p]+1]=rotations[p]
        end
        clock=clock+0.1
    end
    error('flight did not finish')
end
local function distance(a,b)
    local d=0;for axis=1,3 do d=d+(a[axis]-b[axis])^2 end;return math.sqrt(d)
end
run({launch(1,true,10000),launch(2,false,12000)})
local up,down=tracks[1],tracks[2]
assert(distance(up[1],transform(parent,ferries[1]))<1e-6,'takeoff did not start at gate')
assert(down[1][2]>900 and down[1][1]>900,'detachment did not start at carrier')
assert(distance(down[#down],transform(parent,ferries[2]))<1e-6,'landing missed gate under rotated/scaled parent')
assert(distance(up[2],up[1])<distance(up[35],up[34]),'takeoff did not accelerate')
assert(distance(down[119],down[118])<distance(down[70],down[69]),'landing did not decelerate')
local function checkFinal(p,glideSamples)
    local track=tracks[p];local home=transform(parent,ferries[p])
    local first=#track-glideSamples+1
    local previousHeight=math.huge
    local previousRemaining=math.huge
    for n=first,#track do
        local pos=track[n]
        local dx,dz=pos[1]-home[1],pos[3]-home[3]
        assert(math.abs(dx*math.cos(ferryYaw)-dz*math.sin(ferryYaw))<1e-6,'final approach left the landing centerline')
        assert(pos[2]>=home[2]-1e-6 and pos[2]<=previousHeight+1e-6,'final descent climbed or went below the apron')
        local remaining=-(dx*math.sin(ferryYaw)+dz*math.cos(ferryYaw))
        assert(remaining>=-1e-6 and remaining<=previousRemaining+1e-6,'final approach backed into its berth')
        assert(math.abs(headings[p][n])<1e-6,'ferry was still turning during final descent/touchdown')
        previousHeight,previousRemaining=pos[2],remaining
    end
    assert(previousHeight==home[2] and distance(track[#track],home)<1e-6,'touchdown missed the berth')
end
checkFinal(2,36)
-- All turn commands are paired with airborne motion samples; no extra
-- turn/reset is issued once the completed landing loop returns.
assert(turnLog[#turnLog].time<clock,'heading correction was deferred until after landing')
-- The six attachment samples move with the carrier rather than freezing aloft.
for n=102,106 do
    assert(math.abs((up[n][1]-up[n-1][1])-8)<1e-6,'docked ferry lost carrier velocity')
    assert(math.abs((up[n][3]-up[n-1][3])-4)<1e-6,'docked ferry lost carrier direction')
end
clock,tracks,moves=0,{},{}
run({launch(1,true,0)})
assert(#tracks[1]>=37,'zero duration skipped visible flight')
clock,tracks,moves=0,{},{};departingCarrier=true
run({launch(2,false,10000)})
for _,p in ipairs(tracks[2]) do assert(p[1]<3000,'detached ferry followed departing carrier') end
assert(distance(tracks[2][#tracks[2]],transform(parent,ferries[2]))<1e-6)
checkFinal(2,30)
for _,orientation in ipairs({0,math.pi/2,math.pi}) do
 ferryYaw=orientation
 for _,duration in ipairs({0,3000,10000,30000}) do
    for _,sign in ipairs({-1,1}) do
        clock,tracks,moves,headings,turnTargets,turnLog=0,{},{},{},{},{}
        departingCarrier=false
        run({launch(2,false,duration,{yaw=45*sign,side=sign,trail=-sign})})
        local steps=math.max(60,math.ceil(duration/100))
        assert(#tracks[2]==steps+1,'return flight timing or final sample changed')
        checkFinal(2,math.max(12,math.ceil(steps*0.3)))
        assert(turnLog[#turnLog].time<clock,'post-touchdown turn survived')
    end
 end
end
print('PASS: moving docking, concurrent trips, rotated/scaled parent, airborne alignment, straight descent, touchdown heading, variation and short flights')
