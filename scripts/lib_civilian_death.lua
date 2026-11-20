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
        -- Recover the bind-frame direction; an interrupted pose may already
        -- have rotated the root (for example a prone or parachuting operative).
        local qx,qy,qz=component(1),component(5),component(9)
        local rx,ry,rz=Spring.UnitScript.GetPieceRotation(root)
        qx,qy=math.cos(rz)*qx-math.sin(rz)*qy,math.sin(rz)*qx+math.cos(rz)*qy
        qy,qz=math.cos(rx)*qy-math.sin(rx)*qz,math.sin(rx)*qy+math.cos(rx)*qz
        qx,qz=math.cos(ry)*qx+math.sin(ry)*qz,-math.sin(ry)*qx+math.cos(ry)*qz
        local localX,localY=qx,qy
        local tilt=math.rad(86)
        local pitch=-math.asin(clamp(localY*math.sin(tilt),-1,1))
        local roll=math.atan2(localX*math.sin(tilt),math.cos(tilt))
        local stature=clamp(Spring.GetUnitHeight(unitID) or 25,12,60)
        local fallTime=profile.fall*math.random(90,115)/100
        local duration=fallTime+1.8
        local joints,byPiece={},{}
        local function joint(piece,target,delay,limit)
            if not piece then return end
            local angles={Spring.UnitScript.GetPieceRotation(piece)}
            -- Native Turn stores angles in [0, 2*pi); springs and joint limits
            -- need signed angles or an ordinary negative bend snaps at death.
            for axis=1,3 do angles[axis]=(angles[axis]+math.pi)%(2*math.pi)-math.pi end
            local state={piece=piece,angle=angles,initial={angles[1],angles[2],angles[3]},velocity={0,0,0},target=target,
                delay=delay,stiffness=math.random(55,85),limit=math.rad(limit or 120),contact={0,0,0}}
            for axis=1,3 do StopSpin(piece,axis,0) end
            joints[#joints+1]=state
            byPiece[piece]=state
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
        local contactChains={
            {pieces.UpArm1,pieces.LowArm1}, {pieces.UpArm2,pieces.LowArm2},
            {pieces.UpLeg1,pieces.LowLeg1,pieces.Feet1}, {pieces.UpLeg2,pieces.LowLeg2,pieces.Feet2},
        }
        local function groundClearance(settle)
            local ux,uy,uz=Spring.GetUnitPosition(unitID)
            local front,up,right=Spring.GetUnitVectors(unitID)
            local clearance=math.huge
            local samples={}
            local function world(x,y,z,position)
                return {(position and ux or 0)-right[1]*x+up[1]*y+front[1]*z,
                    (position and uy or 0)-right[2]*x+up[2]*y+front[2]*z,
                    (position and uz or 0)-right[3]*x+up[3]*y+front[3]*z}
            end
            for _,part in ipairs(contactPieces) do
                local m={Spring.GetUnitPieceMatrix(unitID,part.piece)}
                local b=part.info
                local sample={clearance=math.huge,matrix=m}
                samples[part.piece]=sample
                -- Rounded body volumes avoid supporting a corpse on the empty
                -- corners of rotated bounding boxes. One ellipsoid support point
                -- per piece also replaces eight terrain queries per update.
                local c,r={},{}
                for axis=1,3 do c[axis]=(b.min[axis]+b.max[axis])*.5;r[axis]=(b.max[axis]-b.min[axis])*.5 end
                local wc=world(m[1]*c[1]+m[5]*c[2]+m[9]*c[3]+m[13],
                    m[2]*c[1]+m[6]*c[2]+m[10]*c[3]+m[14],m[3]*c[1]+m[7]*c[2]+m[11]*c[3]+m[15],true)
                local normal={0,1,0}
                if Spring.GetGroundNormal then normal={Spring.GetGroundNormal(wc[1],wc[3])} end
                local direction={};local norm=0
                for axis=1,3 do
                    local k=(axis-1)*4+1
                    local v=world(m[k],m[k+1],m[k+2])
                    direction[axis]=v[1]*normal[1]+v[2]*normal[2]+v[3]*normal[3]
                    norm=norm+(r[axis]*direction[axis])^2
                end
                norm=math.sqrt(norm)
                local point={}
                for axis=1,3 do point[axis]=c[axis]-(norm>1e-8 and r[axis]^2*direction[axis]/norm or 0) end
                local x,y,z=point[1],point[2],point[3]
                local p=world(m[1]*x+m[5]*y+m[9]*z+m[13],m[2]*x+m[6]*y+m[10]*z+m[14],
                    m[3]*x+m[7]*y+m[11]*z+m[15],true)
                sample.clearance= p[2]-Spring.GetGroundHeight(p[1],p[3])
                sample.point,sample.normal=p,normal
                clearance=math.min(clearance,sample.clearance)
            end
            -- A hand must not prop up the entire dead body. Relax the four body
            -- chains toward the torso's support plane before lowering the root.
            -- Correct the largest support-plane error, including raised distal
            -- limbs: correcting only the lowest segment leaves bent feet aloft.
            -- One bounded Jacobian correction per chain/frame; no accessory
            -- ownership, temporary engine poses or iterative engine queries.
            local torso=samples[pieces.UpBody]
            if settle>0 and torso then
                for _,chain in ipairs(contactChains) do
                    local contact,index
                    for i,piece in ipairs(chain) do
                        local sample=samples[piece]
                        if sample and (not contact or math.abs(torso.clearance-sample.clearance)>math.abs(torso.clearance-contact.clearance)) then contact,index=sample,i end
                    end
                    if contact then
                        local error=torso.clearance-contact.clearance
                        local best
                        if math.abs(error)>.12 then
                            for i=1,index do
                                local piece=chain[i]
                                local joint=byPiece[piece]
                                local m=samples[piece].matrix
                                local basis={}
                                for axis=1,3 do
                                    local k=(axis-1)*4+1
                                    local norm=math.sqrt(m[k]^2+m[k+1]^2+m[k+2]^2)
                                    basis[axis]=world(m[k]/norm,m[k+1]/norm,m[k+2]/norm)
                                end
                                local pivot=world(m[13],m[14],m[15],true)
                                local rx,_,rz=Spring.UnitScript.GetPieceRotation(piece)
                                -- Script rotations compose Ry*Rx*Rz. The X hinge
                                -- precedes Rz, so remove that final twist first.
                                local axes={{basis[1][1]*math.cos(rz)-basis[2][1]*math.sin(rz),
                                    basis[1][2]*math.cos(rz)-basis[2][2]*math.sin(rz),basis[1][3]*math.cos(rz)-basis[2][3]*math.sin(rz)},{},basis[3]}
                                -- Y precedes both X and Z. T-pose shoulders need
                                -- this degree of freedom; X merely twists their
                                -- upper arm and cannot relax it toward the floor.
                                for component=1,3 do
                                    axes[2][component]=(basis[1][component]*math.sin(rz)+basis[2][component]*math.cos(rz))*math.cos(rx)
                                        -basis[3][component]*math.sin(rx)
                                end
                                for _,axis in ipairs(i==1 and {1,2,3} or {1}) do
                                    local v=axes[axis]
                                    local dx,dy,dz=contact.point[1]-pivot[1],contact.point[2]-pivot[2],contact.point[3]-pivot[3]
                                    local n=contact.normal
                                    local derivative=((v[2]*dz-v[3]*dy)*n[1]+(v[3]*dx-v[1]*dz)*n[2]
                                        +(v[1]*dy-v[2]*dx)*n[3])/math.max(.2,n[2])
                                    if math.abs(derivative)>.05 then
                                        local delta=clamp(error/derivative,-math.rad(4),math.rad(4))*settle
                                        local target=joint.target[axis]+joint.contact[axis]+delta
                                        if math.abs(target)<joint.limit
                                            and (not best or math.abs(derivative)>best.leverage) then
                                            best={joint=joint,axis=axis,delta=delta,leverage=math.abs(derivative)}
                                        end
                                    end
                                end
                            end
                        end
                        if best then best.joint.contact[best.axis]=best.joint.contact[best.axis]+best.delta end
                    end
                end
            end
            return clearance,front,up,right
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
                    local target=j.initial[axis]+(j.target[axis]+j.contact[axis]-j.initial[axis])*response
                    if name=='shivering' and landed and j.piece~=root then
                        target=target+math.rad(profile.shiver)*math.sin(t*42+j.delay*20)*math.exp(-(t-impactTime)*5)
                    end
                    -- One small impact rebound; head and distal limbs lag behind.
                    if landed and j.piece~=root then
                        target=target+math.rad(8*side)*math.sin((t-impactTime)*18)*math.exp(-(t-impactTime)*7)
                    end
                    local v=j.velocity[axis]+(j.stiffness*(target-j.angle[axis])-damping*j.velocity[axis])*dt
                    -- Preserve even an extreme interrupted pose on entry, then
                    -- bring its admissible range back to the resting limit.
                    local limit=math.max(j.limit,math.abs(j.initial[axis])*(1-response)+j.limit*response)
                    local angle=clamp(j.angle[axis]+v*dt,-limit,limit)
                    if math.abs(angle)==limit then v=0 end
                    Turn(j.piece,axis,angle,math.abs(angle-j.angle[axis])/dt)
                    j.angle[axis],j.velocity[axis]=angle,v
                end
            end
            -- Terrain contact lifts the whole skeleton instead of allowing the
            -- head or a knee to disappear through the pavement. Blast arcs and
            -- slides are model offsets, so pathing and combat orders are untouched.
            local clearance,front,up,right=groundClearance(ease((t-fallTime*.65)/(fallTime*.35))*(1-ease((t-duration+.4)/.4)))
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
                nextMove[axis]=(startMove[axis] or 0)+parentDelta(dx*slide-right[2]*groundLift,up[2]*groundLift,dz*slide+front[2]*groundLift,axis)
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
