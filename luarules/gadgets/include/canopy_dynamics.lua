-- Unsynced, simulation-clock response of a tensioned veil to relative air flow.
-- Exact critically damped spring solution: no frame-dependent Euler steps.
local M = {}
function M.Step(old, now, tx, ty, tz, wx, wy, wz, length, stiffness, trailTime, motionInfluence)
    local dt = old and now-old.time or 0
    if old and dt == 0 then return old end
    local state = {time=now, tx=tx, ty=ty, tz=tz, x=0,y=0,z=0, vx=0,vy=0,vz=0}
    if not old or dt < 0 or dt >= 0.25 then return state end
    local dx,dy,dz = tx-old.tx,ty-old.ty,tz-old.tz
    if dx*dx+dy*dy+dz*dz >= (length*4)^2 then return state end
    -- Tip displacement includes rotation and MoveCtrl travel, which does not
    -- reliably appear in the engine's unit-velocity query.
    local gain = motionInfluence*trailTime/dt
    local fx,fy,fz = wx-dx*gain,wy-dy*gain,wz-dz*gain
    local magnitude = math.sqrt(fx*fx+fy*fy+fz*fz)
    local cap = math.min(1,length*1.5/math.max(magnitude,0.0001))
    fx,fy,fz = fx*cap,fy*cap,fz*cap
    local omega = (3+6*stiffness)/math.sqrt(math.max(trailTime,0.05)/0.45)
    local decay = math.exp(-omega*dt)
    local function axis(position, velocity, target)
        local offset = position-target
        local impulse = velocity+omega*offset
        return target+(offset+impulse*dt)*decay, (velocity-omega*impulse*dt)*decay
    end
    state.x,state.vx = axis(old.x,old.vx,fx)
    state.y,state.vy = axis(old.y,old.vy,fy)
    state.z,state.vz = axis(old.z,old.vz,fz)
    return state
end
return M
