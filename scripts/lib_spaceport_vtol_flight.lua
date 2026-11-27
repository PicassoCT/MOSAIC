-- Model-space routes: the imported harbour is rotated and scaled, so raw
-- piece offsets are not metres and the script header's Y/Z aliases differ.
return function(unitID)
    local geometry = {}
    local function dot(a,b) return a[1]*b[1]+a[2]*b[2]+a[3]*b[3] end
    local function normalized(v)
        local length = math.sqrt(dot(v,v))
        return {v[1]/length,v[2]/length,v[3]/length}
    end
    local function inverseVector(m,v)
        local a,b,c,d,e,f,g,h,i = m[1],m[5],m[9],m[2],m[6],m[10],m[3],m[7],m[11]
        local det = a*(e*i-f*h)-b*(d*i-f*g)+c*(d*h-e*g)
        local x,y,z = v[1],v[2],v[3]
        return {((e*i-f*h)*x+(c*h-b*i)*y+(b*f-c*e)*z)/det,
                ((f*g-d*i)*x+(a*i-c*g)*y+(c*d-a*f)*z)/det,
                ((d*h-e*g)*x+(b*g-a*h)*y+(a*e-b*d)*z)/det}
    end
    local function dimensions(piece)
        if geometry[piece] then return geometry[piece] end
        local info = Spring.GetUnitPieceInfo(unitID,piece)
        local map = Spring.GetUnitPieceMap(unitID)
        local parent = {Spring.GetUnitPieceMatrix(unitID,map[info.parent])}
        local rest = {Spring.GetUnitPieceMatrix(unitID,piece)}
        local length = 0
        for axis=1,3 do
            local index = (axis-1)*4+1
            local scale = math.sqrt(rest[index]^2+rest[index+1]^2+rest[index+2]^2)
            length = math.max(length,(info.max[axis]-info.min[axis])*scale)
        end
        local forward = normalized({rest[5],0,rest[7]})
        local right = normalized({rest[1],0,rest[3]})
        local outward = {rest[13]-parent[13],0,rest[15]-parent[15]}
        if dot(outward,outward)<0.001 then outward=forward end
        local result = {parent=parent,length=length,forward=forward,right=right,outward=normalized(outward)}
        geometry[piece] = result
        return result
    end
    local function smooth(t) return t*t*(3-2*t) end
    local function hermite(start,finish,initial,final,t,seconds)
        return (2*t*t*t-3*t*t+1)*start+(t*t*t-2*t*t+t)*initial*seconds
            +(-2*t*t*t+3*t*t)*finish+(t*t*t-t*t)*final*seconds
    end

    return function(piece, departing)
        local g = dimensions(piece)
        -- Retain varied traffic, but keep routes outside the central launch pad.
        local angle = math.rad(math.random(-15,15))
        local dx = g.outward[1]*math.cos(angle)-g.outward[3]*math.sin(angle)
        local dz = g.outward[1]*math.sin(angle)+g.outward[3]*math.cos(angle)
        local direction = departing and 1 or -1
        local heading = {dx*direction,0,dz*direction}
        local yaw = math.atan2(dot(heading,g.right),dot(heading,g.forward))
        local previous = {0,0,0}
        local function position(distance,height,instant)
            local p = inverseVector(g.parent,{dx*distance*g.length,height*g.length,dz*distance*g.length})
            for axis=1,3 do
                Move(piece,axis,p[axis],instant and 0 or math.abs(p[axis]-previous[axis])*10)
            end
            previous = p
        end
        local function leg(seconds,d0,d1,h0,h1,v0,v1,climb0,climb1,pitch0,pitch1)
            local steps = seconds*10
            for step=1,steps do
                local t = step/steps
                position(hermite(d0,d1,v0,v1,t,seconds),hermite(h0,h1,climb0,climb1,t,seconds))
                Turn(piece,1,math.rad(pitch0+(pitch1-pitch0)*smooth(t)),math.rad(20))
                Sleep(100)
            end
            WaitForMove(piece,1); WaitForMove(piece,2); WaitForMove(piece,3)
        end
        if departing then
            -- Lift clear before changing heading or translating across the pad.
            leg(6,0,0,0,3,0,0,0,0,0,0)
            Turn(piece,3,yaw,math.rad(45))
            Sleep(4000)
            WaitForTurn(piece,3)
            leg(8,0,8,3,5,0,2,0,0.6,0,-8)
            -- Constant forward velocity and climb continue beyond the harbour.
            -- Only hide after travelling 64 aircraft lengths, not half a hull.
            leg(28,8,64,5,21.8,2,2,0.6,0.6,-8,-8)
            Hide(piece)
            position(0,0,true)
            Turn(piece,1,0,0); Turn(piece,3,0,0)
        else
            Hide(piece)
            position(64,18,true)
            Turn(piece,1,math.rad(-4),0); Turn(piece,3,yaw,0)
            Show(piece)
            leg(20,64,24,18,6,-2,-2,-0.6,-0.6,-4,-4)
            leg(12,24,0,6,3,-2,0,-0.6,0,-4,0)
            -- Align while hovering; touchdown has no sideways slide or yaw.
            Turn(piece,3,0,math.rad(45))
            Sleep(4000)
            WaitForTurn(piece,3)
            leg(6,0,0,3,0,0,0,0,0,0,0)
        end
    end
end
