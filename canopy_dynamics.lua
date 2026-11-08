local dynamics = dofile('luarules/gadgets/include/canopy_dynamics.lua')
local function step(old,time,x,wind)
    return dynamics.Step(old,time,x,0,0,wind,0,0,100,0.28,0.45,0.7)
end
local function travel(hz)
    local state = step(nil,0,0,0)
    for i=1,hz do state=step(state,i/hz,20*i/hz,0) end
    return state
end
local a,b=travel(30),travel(144)
assert(a.x<0 and a.vx<0,'moving root did not leave a trailing veil')
assert(math.abs(a.x-b.x)<1e-8 and math.abs(a.vx-b.vx)<1e-8,
    'canopy inertia changes with render frequency')
assert(step(a,a.time,20,100)==a,'paused simulation changed wind or momentum')
local first=step(a,1+1/60,20,0)
assert(math.abs(first.x)>math.abs(a.x)*0.9,'stopping instantly erased inertia')
local state=first
for i=2,300 do state=step(state,1+i/60,20,0) end
assert(math.abs(state.x)<1e-6 and math.abs(state.vx)<1e-5,'stopped veil does not settle')
local wind=step(nil,0,0,0)
for i=1,300 do wind=step(wind,i/60,0,20) end
assert(math.abs(wind.x-20)<1e-6,'steady airflow does not reach equilibrium')
for i=301,600 do wind=step(wind,i/60,0,-20) end
assert(math.abs(wind.x+20)<1e-6,'veil ignores wind reversal')
for _,reset in ipairs({step(a,0,20,0),step(a,2,20,0),step(a,1.01,10000,0)}) do
    assert(reset.x==0 and reset.vx==0,'clock jump, hidden interval or teleport retained stale momentum')
end
local extreme=step(nil,0,0,0)
for i=1,300 do extreme=step(extreme,i/60,0,1e12) end
assert(extreme.x==extreme.x and extreme.x<=150,'extreme airflow escaped the length bound')
print('PASS: canopy inertia, frame-rate independence, pause, settling, wind reversal and reset bounds')
