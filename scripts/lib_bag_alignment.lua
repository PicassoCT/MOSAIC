-- Bag gravity alignment. One finite worker per unit-script environment.
-- GetUnitPieceMatrix is already model-space (including ancestors).
local bags, running, untilFrame = {}, false, 0
local M = {}
local function norm(x,y,z)
    local n = math.sqrt(x*x+y*y+z*z)
    if n < 1e-8 then return 0,-1,0 end
    return x/n,y/n,z/n
end
local function wrap(a) return (a+math.pi)%(2*math.pi)-math.pi end
local function mul(a,b)
    local c={}
    for i=1,3 do
        c[i]={}
        for j=1,3 do c[i][j]=a[i][1]*b[1][j]+a[i][2]*b[2][j]+a[i][3]*b[3][j] end
    end
    return c
end
local function transpose(a)
    return {{a[1][1],a[2][1],a[3][1]},
            {a[1][2],a[2][2],a[3][2]},
            {a[1][3],a[2][3],a[3][3]}}
end
local function apply(a,x,y,z)
    return a[1][1]*x+a[1][2]*y+a[1][3]*z,
           a[2][1]*x+a[2][2]*y+a[2][3]*z,
           a[3][1]*x+a[3][2]*y+a[3][3]*z
end
-- Spring script rotation: Ry(y) * Rx(x) * Rz(z).
local function rotation(x,y,z)
    local sx,cx,sy,cy,sz,cz=math.sin(x),math.cos(x),math.sin(y),math.cos(y),math.sin(z),math.cos(z)
    return {{cy*cz+sy*sx*sz,-cy*sz+sy*sx*cz,sy*cx},
            {cx*sz,cx*cz,-sx},
            {-sy*cz+cy*sx*sz,sy*sz+cy*sx*cz,cy*cx}}
end
local function modelRotation(id,piece)
    local m={Spring.GetUnitPieceMatrix(id,piece)}
    if not m[16] then return end
    -- Remove uniform import scale before using transpose as inverse.
    local a,b,c=norm(m[1],m[2],m[3])
    local d,e,f=norm(m[5],m[6],m[7])
    local g,h,i=norm(m[9],m[10],m[11])
    return {{a,d,g},{b,e,h},{c,f,i}}
end
local function align(ax,ay,az,bx,by,bz)
    local dot=math.max(-1,math.min(1,ax*bx+ay*by+az*bz))
    local x,y,z,w=ay*bz-az*by,az*bx-ax*bz,ax*by-ay*bx,1+dot
    if w < 1e-7 then
        if math.abs(ax)<0.9 then x,y,z=0,az,-ay else x,y,z=-az,0,ax end
        x,y,z=norm(x,y,z)
        w=0
    else
        local n=math.sqrt(x*x+y*y+z*z+w*w)
        x,y,z,w=x/n,y/n,z/n,w/n
    end
    -- Quaternion -> script YXZ Euler angles, including the gimbal pole.
    local pitch=math.asin(math.max(-1,math.min(1,2*(w*x-y*z))))
    local yaw,roll
    if math.abs(math.cos(pitch))<1e-6 then
        yaw=math.atan2(2*(w*y-x*z),1-2*(y*y+z*z))
        roll=0
    else
        yaw=math.atan2(2*(x*z+w*y),1-2*(x*x+y*y))
        roll=math.atan2(2*(x*y+w*z),1-2*(x*x+z*z))
    end
    return pitch,yaw,roll
end
local function update(config,frame)
    local id,piece=config.unitID,config.pieceId
    local mat=modelRotation(id,piece)
    if not mat then return end
    local x,y,z=Spring.UnitScript.GetPieceRotation(piece)
    -- Factor out the bag's own scripted rotation. Keep its baked DAE transform.
    local base=mul(mat,transpose(rotation(x,y,z)))
    local front,up,right=Spring.GetUnitVectors(id)
    if not front then return end
    -- Unit model basis is (-right, up, front).
    local gx,gy,gz=right[2],-up[2],-front[2]
    gx,gy,gz=apply(transpose(base),gx,gy,gz)
    gx,gy,gz=norm(gx,gy,gz)
    if (config.iterations or 0)>0 then
        config.amplitude=0.18
        config.swingStart=frame
        config.iterations=0
    end
    local age=(frame-(config.swingStart or frame))/30
    local angle=(config.amplitude or 0)*math.exp(-age*3)*math.sin(age*9)
    -- Swing within the same local frame as gravity, never against world up.
    local c,s=math.cos(angle),math.sin(angle)
    gy,gz=gy*c-gz*s,gy*s+gz*c
    local a=config.downAxis
    x,y,z=align(a[1],a[2],a[3],gx,gy,gz)
    -- The target is recomputed every three frames; no blocking WaitForTurn.
    Turn(piece,x_axis,x,0)
    Turn(piece,y_axis,y,0)
    Turn(piece,z_axis,z,0)
end
local function worker()
    SetSignalMask(0)
    repeat
        local frame=Spring.GetGameFrame()
        for _,config in pairs(bags) do update(config,frame) end
        Sleep(100)
    until Spring.GetGameFrame()>untilFrame
    -- End exactly vertical, without retaining the final swing offset.
    local frame=Spring.GetGameFrame()
    for _,config in pairs(bags) do config.amplitude=0; update(config,frame) end
    running=false
end
function M.wake(milliseconds)
    if not next(bags) then return end
    untilFrame=math.max(untilFrame,Spring.GetGameFrame()+math.ceil((milliseconds or 0)*0.03)+30)
    if not running then running=true; StartThread(worker) end
end
function M.add(id,piece,parentPieceMap,speed,iterations)
    local info=Spring.GetUnitPieceInfo(id,piece)
    -- The bag pivot is its handle. Its bounds centre points into the bag,
    -- including models authored sideways in the T-pose.
    local lo,hi=info.min,info.max
    local x,y,z=norm((lo[1]+hi[1])*0.5,(lo[2]+hi[2])*0.5,(lo[3]+hi[3])*0.5)
    local config={unitID=id,pieceId=piece,downAxis={x,y,z},iterations=iterations or 0}
    bags[piece]=config
    M.wake(1000)
    return config
end
function M.remove(piece) bags[piece]=nil end
function M.owns(piece) return bags[piece]~=nil end
function M.poseCommand(piece,axis,target,speed,command)
    if not next(bags) then return end
    local duration=0
    if speed and speed>0 then
        local values
        if command=="turn" then
            values={Spring.UnitScript.GetPieceRotation(piece)}
            duration=math.abs(wrap(target-(values[axis] or 0)))/speed
        elseif command=="move" then
            values={Spring.UnitScript.GetPieceTranslation(piece)}
            duration=math.abs(target-(values[axis] or 0))/speed
        end
    end
    M.wake(duration*1000)
end
-- Pure math exposed for regression tests.
M.rotation,M.align=rotation,align
return M
