-- Lua 5.1+; production policy with controlled camera/LOS/time, no engine claims.
local P=dofile('luaui/widgets_mosaic/include/combat_sfx_policy.lua')
local frame,zoom,seen,onScreen=100,100,true,true
local terrainQueries=0
local api={GetGameFrame=function() return frame end,
    GetCameraPosition=function() return 0,zoom,0 end,
    GetGroundHeight=function() terrainQueries=terrainQueries+1;return 0 end,
    IsSphereInView=function() return onScreen end}
local defs={
    [1]={name='S16 launcher',type='MissileLauncher'},
    [2]={name='mortar',type='Cannon'},
    [3]={name='mg',type='Cannon',customParams={night_tracer='1'}},
    [4]={name='railgun',type='Cannon',customParams={railgun_wake=1}},
    [5]={name='unknown',type='Cannon'},
    [6]={name='manual',type='Cannon',customParams={sfx_priority='High'}},
    [7]={name='ignored',type='Flame',customParams={no_projectile_vfx=1}},
}
local names={s16rocket={id=1},supportmortar={id=2}}
local function visible() return seen end
local function unitVisible(id) return seen and id~=666 end
local function fresh() return P.New(api,{gameSpeed=30},defs,names) end
local s=fresh()
assert(s:Profile(1).kind=='missile' and s:Profile(1).priority=='Low')
assert(s:Profile(2).kind=='mortar' and s:Profile(2).priority=='Low')
assert(s:Profile(3).priority=='Low' and s:Profile(4).priority=='High')
assert(s:Profile(5).priority=='Low' and s:Profile(6).priority=='High')
assert(s:Profile(7).skip)
assert(P.CloseGain(900^2)==1 and P.CloseGain(1400^2)==0)
assert(P.CloseGain(1150^2)>.49 and P.CloseGain(1150^2)<.51)
local previous=1
for distance=0,2000 do
    local gain=P.CloseGain(distance^2)
    assert(gain<=previous and gain>=0 and gain<=1);previous=gain
end
local function emit(id,x,owner,muzzle)
    return s:Explosion(x or 0,10,0,id,muzzle,owner,visible,unitVisible)
end
local function collect()
    local lights,extras={},{}
    s:Collect(frame,0,zoom,0,visible,unitVisible,function(x,y,z,radius,color,strength,night,ribbon,_,owner,priority)
        local l={x=x,y=y,z=z,radius=radius,color=color,strength=strength,night=night,ribbon=ribbon,priority=priority}
        lights[#lights+1]=l;return l
    end,extras,1.3,1.3)
    return lights,extras
end
-- High-only at orbital zoom. A new LuaUI instance cannot resurrect old events.
zoom=12000
emit(P.stickyEvent,0,12);emit(P.empEvent,30,13);emit(2,60,14);emit(3,80,14,true)
local lights,extras=collect()
assert(#lights==2 and #extras==1 and terrainQueries==0,'Low allocated orbit detail')
for _,l in ipairs(lights) do
    assert(l.priority=='High' and l.ribbon)
    local r=l.ribbon
    local cutoff=math.max(r.length,r.width*2)*r.distanceFactor
    assert(cutoff>zoom*1.5,'High was recut by legacy ribbon distance envelope')
end
assert(not next(fresh().high),'UI reload resurrected expired visual history')
zoom=100
emit(2,50,21);emit(3,80,22,true);emit(3,80,22,true)
lights,extras=collect()
assert(#lights==4,'gun pulses were not merged or near mortar absent')
local hasGun=false
for _,l in ipairs(lights) do
    if l.night then hasGun=true;assert(not l.ribbon and l.y==9,'gun did not use ground flash') end
end
assert(hasGun)
-- Far, hidden and aerial guns neither allocate terrain probes nor ground lights.
local queries=terrainQueries
zoom=12000;emit(3,0,33,true);assert(terrainQueries==queries)
seen=false;emit(P.stickyEvent,0,99);assert(#collect()==0)
seen=true;emit(P.empEvent,0,666)
zoom=100
local before=0;for _ in pairs(s.low) do before=before+1 end
s:Explosion(0,500,0,3,true,42,visible,unitVisible)
local after=0;for _ in pairs(s.low) do after=after+1 end
assert(before==after,'aircraft gun projected an implausible ground flash')
onScreen=false;assert(#collect()==0);onScreen=true
frame=200;s:Update();assert(not next(s.high) and not next(s.low),'expiry depended on rendering')
-- Pause keeps age, not count; replay rewind clears all queues.
emit(P.stickyEvent,0,12);local count=#collect();assert(#collect()==count)
frame=10;s:Update();assert(#collect()==0)
-- Stress caps independent High and Low retention and draw work.
frame=300;zoom=100
for i=1,1000 do emit(P.stickyEvent,i%100,12);emit(2,i%100,13) end
local high,low=0,0
for _ in pairs(s.high) do high=high+1 end
for _ in pairs(s.low) do low=low+1 end
assert(high==32 and low==32,'unbounded record pools')
lights,extras=collect()
assert(#lights==16 and #extras==8 and s.stats.high==8 and s.stats.low==8)
zoom=12000;lights=collect();assert(#lights==8 and s.stats.low==0)
-- Geometry follows reverse velocity, stays finite, and has no dead-projectile history.
local r=s:Missile(0,20,0,3,4,0,77,'Low',100)
assert(r.direction[1]==-.6 and r.direction[2]==-.8 and r.length==22)
assert(s:Missile(0,0,0,0,0,0,77,'Low',0)==nil)
assert(emit(P.stickyEvent,0/0,2)==true)
-- Overview vetoes Low detail regardless of camera distance; one state read
-- per draw, while High does not even request camera state.
local stateQueries=0
api.GetCameraState=function() stateQueries=stateQueries+1;return {name='ov'} end
s=fresh();zoom=100
assert(s:Gain('High',0,0,0)==1 and stateQueries==0)
assert(s:Gain('Low',0,0,0)==0 and s:Gain('Low',10,0,0)==0 and stateQueries==1)
local sorted={{priority='Low' ,d2=0,order=1},{priority='High',d2=1e8,order=2}}
table.sort(sorted,P.Before);assert(sorted[1].priority=='High')
print('PASS: High/Low classification, aliases, close-only gates, fades, independent cues, LOS, frustum, expiry, pause/seek, finite geometry and stress budgets')
