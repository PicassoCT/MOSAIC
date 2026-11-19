-- Bounded procedural falls, not free-spinning limbs. Each joint keeps its
-- current pose, responds with a different delay, then damps into a resting pose.
local profiles = {
    collapse = {fall=1.0, hip=-42, knee=72, arm=-35, curl=24, twist=8, shiver=0},
    backwards = {fall=0.85, hip=18, knee=28, arm=35, curl=-8, twist=12, shiver=0},
    sideways = {fall=0.8, hip=-18, knee=48, arm=-12, curl=12, twist=26, shiver=0},
    coiling = {fall=1.15, hip=-64, knee=96, arm=-55, curl=32, twist=18, shiver=0},
    shivering = {fall=0.95, hip=-28, knee=55, arm=-24, curl=20, twist=15, shiver=5},
    blasted = {fall=0.6, hip=-28, knee=60, arm=65, curl=18, twist=35, shiver=0},
    swirling = {fall=0.75, hip=-48, knee=78, arm=48, curl=26, twist=85, shiver=0},
}
local ordinary = {'collapse','backwards','sideways','coiling','shivering'}
local explosive = {'blasted','swirling','coiling'}
local function clamp(x,lo,hi) return math.max(lo,math.min(hi,x)) end
local function ease(t) t=clamp(t,0,1);return t*t*(3-2*t) end

return function(unitID, pieces)
    return function(recentDamage,maxHealth,hitX,hitZ)
        local blast = recentDamage/math.max(1,maxHealth or 1)>2.5
        local choices = blast and explosive or ordinary
        local name = choices[math.random(1,#choices)]
        local profile = profiles[name]
        local side = math.random(0,1)==0 and -1 or 1
        -- HitByWeapon points towards the attacker, in unit space.
        local dx,dz = -(hitX or 0),-(hitZ or 0)
        local length = math.sqrt(dx*dx+dz*dz)
        if length<0.001 then
            local angle=math.rad(math.random(0,359));dx,dz=math.sin(angle),math.cos(angle)
        else dx,dz=dx/length,dz/length end
        local root,center=pieces.root,pieces.center
        local rootMatrix={Spring.GetUnitPieceMatrix(unitID,root)}
        -- The authored skeleton is Z-up. Convert the horizontal fall direction
        -- into its baked frame; don't confuse local twist with world yaw.
        local function component(index)
            local norm=math.sqrt(rootMatrix[index]^2+rootMatrix[index+1]^2+rootMatrix[index+2]^2)
            return (rootMatrix[index]*dx+rootMatrix[index+2]*dz)/norm
        end
        local localX,localY=component(1),component(5)
        local tilt=math.rad(86)
        local pitch=math.asin(clamp(localY*math.sin(tilt),-1,1))
        local roll=math.atan2(-localX*math.sin(tilt),math.cos(tilt))
        local stature=clamp(Spring.GetUnitHeight(unitID) or 25,12,60)
        local fallTime=profile.fall*math.random(90,115)/100
        local duration=fallTime+1.8
        local joints={}
        local function joint(piece,target,delay,limit)
            if not piece then return end
            local angles={Spring.UnitScript.GetPieceRotation(piece)}
            local state={piece=piece,angle=angles,initial={angles[1],angles[2],angles[3]},velocity={0,0,0},target=target,
                delay=delay,stiffness=math.random(55,85),limit=math.rad(limit or 120)}
            for axis=1,3 do StopSpin(piece,axis,0) end
            joints[#joints+1]=state
        end
        local function degrees(x,y,z) return {math.rad(x),math.rad(y),math.rad(z)} end
        local asymmetry=math.random(6,18)*side
        joint(root,{pitch,roll,math.rad(profile.twist*side)},0,175)
        if center and center~=root then joint(center,degrees(0,0,math.random(-12,12)),0.03,45) end
        joint(pieces.UpBody,degrees(profile.curl,asymmetry*0.4,side*8),0.08,65)
        joint(pieces.Head1,degrees(profile.curl*0.6,asymmetry,side*10),0.18,55)
        joint(pieces.UpArm1,degrees(profile.arm+asymmetry,-15,32),0.10,110)
        joint(pieces.UpArm2,degrees(profile.arm-asymmetry,15,-32),0.17,110)
        joint(pieces.LowArm1,degrees(-55-asymmetry,0,10),0.20,125)
        joint(pieces.LowArm2,degrees(-55+asymmetry,0,-10),0.26,125)
        joint(pieces.UpLeg1,degrees(profile.hip+asymmetry,side*8,8),0.02,100)
        joint(pieces.UpLeg2,degrees(profile.hip-asymmetry,-side*8,-8),0.09,100)
        joint(pieces.LowLeg1,degrees(profile.knee-asymmetry,0,0),0.06,125)
        joint(pieces.LowLeg2,degrees(profile.knee+asymmetry,0,0),0.14,125)
        joint(pieces.Feet1,degrees(-12-asymmetry*0.5,0,0),0.18,45)
        joint(pieces.Feet2,degrees(-12+asymmetry*0.5,0,0),0.23,45)
        local startMove={Spring.UnitScript.GetPieceTranslation(root)}
        if center and center~=root then
            local centerMove={Spring.UnitScript.GetPieceTranslation(center)}
            for axis=1,3 do Move(center,axis,0,math.abs(centerMove[axis] or 0)/fallTime) end
        end
        local rootInfo=Spring.GetUnitPieceInfo(unitID,root)
        local parent=Spring.GetUnitPieceMap(unitID)[rootInfo.parent]
        local parentMatrix=parent and {Spring.GetUnitPieceMatrix(unitID,parent)}
        local function parentDelta(x,y,z,axis)
            if not parentMatrix then return ({x,y,z})[axis] end
            local i=(axis-1)*4+1
            local a,b,c=parentMatrix[i],parentMatrix[i+1],parentMatrix[i+2]
            return (a*x+b*y+c*z)/(a*a+b*b+c*c)
        end
        local contactPieces={}
        for _,j in ipairs(joints) do
            if j.piece~=root and j.piece~=center then
                contactPieces[#contactPieces+1]={piece=j.piece,info=Spring.GetUnitPieceInfo(unitID,j.piece)}
            end
        end
        local function groundClearance()
            local ux,uy,uz=Spring.GetUnitPosition(unitID)
            local front,up,right=Spring.GetUnitVectors(unitID)
            local clearance=math.huge
            for _,part in ipairs(contactPieces) do
                local m={Spring.GetUnitPieceMatrix(unitID,part.piece)}
                local b=part.info
                for ix=1,2 do for iy=1,2 do for iz=1,2 do
                    local x=(ix==1 and b.min[1] or b.max[1])
                    local y=(iy==1 and b.min[2] or b.max[2])
                    local z=(iz==1 and b.min[3] or b.max[3])
                    local mx=m[1]*x+m[5]*y+m[9]*z+m[13]
                    local my=m[2]*x+m[6]*y+m[10]*z+m[14]
                    local mz=m[3]*x+m[7]*y+m[11]*z+m[15]
                    local wx=ux-right[1]*mx+up[1]*my+front[1]*mz
                    local wy=uy-right[2]*mx+up[2]*my+front[2]*mz
                    local wz=uz-right[3]*mx+up[3]*my+front[3]*mz
                    clearance=math.min(clearance,wy-Spring.GetGroundHeight(wx,wz))
                end end end
            end
            return clearance
        end
        -- Root gravity follows the posed body down to support instead of only
        -- lifting penetrations. This keeps a collapsing pelvis from hovering.
        -- All motion stays on the body rig; secondary physics owners are untouched.
        local dt,groundLift=1/30,0
        local verticalVelocity=blast and stature*1.6 or 0
        local gravity=stature*5
        local impactTime
        local skin=0.04
        local previousMove=startMove
        for frame=1,math.ceil(duration/dt) do
            local t=frame*dt
            local landed=impactTime~=nil
            for _,j in ipairs(joints) do
                local response=ease((t-j.delay)/fallTime)
                if j.piece==root then response=response*response end
                local damping=landed and 18 or 8
                for axis=1,3 do
                    local target=j.initial[axis]+(j.target[axis]-j.initial[axis])*response
                    if name=='shivering' and landed and j.piece~=root then
                        target=target+math.rad(profile.shiver)*math.sin(t*42+j.delay*20)*math.exp(-(t-impactTime)*5)
                    end
                    -- One small impact rebound; head and distal limbs lag behind.
                    if landed and j.piece~=root then
                        target=target+math.rad(8*side)*math.sin((t-impactTime)*18)*math.exp(-(t-impactTime)*7)
                    end
                    local v=j.velocity[axis]+(j.stiffness*(target-j.angle[axis])-damping*j.velocity[axis])*dt
                    local angle=clamp(j.angle[axis]+v*dt,-j.limit,j.limit)
                    if math.abs(angle)==j.limit then v=0 end
                    Turn(j.piece,axis,angle,math.abs(angle-j.angle[axis])/dt)
                    j.angle[axis],j.velocity[axis]=angle,v
                end
            end
            -- Terrain contact lifts the whole skeleton instead of allowing the
            -- head or a knee to disappear through the pavement. Blast arcs and
            -- slides are model offsets, so pathing and combat orders are untouched.
            local clearance=groundClearance()
            verticalVelocity=verticalVelocity-gravity*dt
            local verticalStep=verticalVelocity*dt
            if clearance+verticalStep<skin then
                verticalStep=skin-clearance
                -- Ignore initial foot support; the later body impact starts
                -- distal follow-through and settling, once per fall.
                if not impactTime and t>=fallTime*.7 then impactTime=t end
                verticalVelocity=0
            end
            groundLift=groundLift+verticalStep
            local travel=ease(t/fallTime)
            local slide=stature*(blast and 0.55 or 0.08)*travel
            -- Blast lift is the initial vertical impulse above, integrated with gravity.
            local nextMove={}
            for axis=1,3 do
                nextMove[axis]=(startMove[axis] or 0)+parentDelta(dx*slide,groundLift,dz*slide,axis)
                Move(root,axis,nextMove[axis],math.abs(nextMove[axis]-(previousMove[axis] or 0))/dt)
            end
            previousMove=nextMove
            Sleep(33)
        end
        -- Keep the final pose visible before the engine creates the bodybag.
        Sleep(350)
        return name
    end
end
