-- Ferry pieces are rooted at the airport, whereas the carrier has animated
-- parents. Work in model space, then convert back to each ferry parent's space.
return function(unitID)
    local bounds = {}
    local function info(p)
        if not bounds[p] then bounds[p] = Spring.GetUnitPieceInfo(unitID, p) end
        return bounds[p]
    end
    local function matrix(p)
        return {Spring.GetUnitPieceMatrix(unitID, p)}
    end
    local function transform(m, p)
        return {m[13]+m[1]*p[1]+m[5]*p[2]+m[9]*p[3],
                m[14]+m[2]*p[1]+m[6]*p[2]+m[10]*p[3],
                m[15]+m[3]*p[1]+m[7]*p[2]+m[11]*p[3]}
    end
    local identity = {1,0,0,0, 0,1,0,0, 0,0,1,0, 0,0,0,1}
    local function inverseTransform(m, p)
        local x,y,z = p[1]-m[13],p[2]-m[14],p[3]-m[15]
        local a,b,c,d,e,f,g,h,i = m[1],m[5],m[9],m[2],m[6],m[10],m[3],m[7],m[11]
        local det = a*(e*i-f*h)-b*(d*i-f*g)+c*(d*h-e*g)
        return {((e*i-f*h)*x+(c*h-b*i)*y+(b*f-c*e)*z)/det,
                ((f*g-d*i)*x+(a*i-c*g)*y+(c*d-a*f)*z)/det,
                ((d*h-e*g)*x+(b*g-a*h)*y+(a*e-b*d)*z)/det}
    end
    local function dot(a,b)
        return a[1]*b[1]+a[2]*b[2]+a[3]*b[3]
    end
    local function normalized(v)
        local length = math.sqrt(dot(v,v))
        return {v[1]/length,v[2]/length,v[3]/length}
    end
    local function modelBounds(p)
        local b,m = info(p),matrix(p)
        local low,high = {math.huge,math.huge,math.huge},{-math.huge,-math.huge,-math.huge}
        for x=1,2 do for y=1,2 do for z=1,2 do
            local sides = {b.min,b.max}
            local v = transform(m,{sides[x][1],sides[y][2],sides[z][3]})
            for axis=1,3 do
                low[axis],high[axis] = math.min(low[axis],v[axis]),math.max(high[axis],v[axis])
            end
        end end end
        return low,high
    end

    return function(ferry, engine, hull, driver, durationMs, upward, lane, variation)
        variation = variation or {yaw=0, side=0, trail=0}
        local pieceMap = Spring.GetUnitPieceMap(unitID)
        local ferryInfo = info(ferry)
        local parent = pieceMap[ferryInfo.parent]
        local parentMatrix = parent and matrix(parent) or identity
        local home = transform(parentMatrix,ferryInfo.offset)
        local rest = matrix(ferry)
        local right = normalized({rest[1],rest[2],rest[3]})
        local forward = normalized({rest[5],rest[6],rest[7]})
        local ferryLow,ferryHigh = modelBounds(ferry)
        local clearance = (ferryHigh[2]-ferryLow[2])*0.55
        -- Existing callers can request zero time on the last rendezvous. Keep
        -- every trip finite and long enough to read as a flight.
        local steps = math.max(upward and 30 or 60,math.ceil((durationMs or 10000)/100))
        local previous,previousLocal
        local function dockingPoint()
            local low,high = modelBounds(hull)
            local m = matrix(driver)
            local heading = normalized({m[5],m[6],m[7]})
            local side = normalized({m[1],m[2],m[3]})
            local berth = (lane-5.5)*clearance*0.3
            return {(low[1]+high[1])*0.5+side[1]*berth,
                    low[2]-clearance,
                    (low[3]+high[3])*0.5+side[3]*berth},heading
        end
        local function position(p, heading, instant, aligned)
            local localPos = inverseTransform(parentMatrix,p)
            for axis=1,3 do
                local delta = localPos[axis]-ferryInfo.offset[axis]
                local speed = previousLocal and math.abs(localPos[axis]-previousLocal[axis])*10 or 0
                Move(ferry,axis,delta,instant and 0 or speed)
            end
            local motion = previous and {p[1]-previous[1],0,p[3]-previous[3]} or heading
            if aligned then
                Turn(ferry,3,0,instant and 0 or 3)
            elseif dot(motion,motion)>0.0001 then
                Turn(ferry,3,math.atan2(dot(motion,right),dot(motion,forward)),instant and 0 or 3)
            end
            previous,previousLocal = p,localPos
        end
        local start,heading = dockingPoint()
        position(upward and home or start,heading,true)
        Show(ferry)
        Show(engine)

        if not upward then
            -- Observe the carrier briefly, then detach. Its later orbit must
            -- not drag the ferry's approach away from the airport centerline.
            local departure,departureHeading=start,heading
            local departureVelocity={0,0,0}
            for sample=1,2 do
                local dock,flightHeading=dockingPoint()
                for axis=1,3 do departureVelocity[axis]=(dock[axis]-departure[axis])*10 end
                position(dock,flightHeading,false)
                departure,departureHeading=dock,flightHeading
                Sleep(100)
            end

            local landingHeading=normalized({forward[1],0,forward[3]})
            -- The level lead-in lasts longer than a half-turn at the existing
            -- yaw rate. Heading correction therefore finishes while airborne,
            -- even for a very short requested rendezvous.
            local alignSteps=math.max(12,math.ceil(steps*0.15))
            local glideSteps=math.max(12,math.ceil(steps*0.30))
            local curveSteps=steps-2-alignSteps-glideSteps
            local dx,dz=departure[1]-home[1],departure[3]-home[3]
            local glideDistance=math.max(clearance*12,math.sqrt(dx*dx+dz*dz)*0.35)
            local height=math.max(clearance*4,math.min((departure[2]-home[2])*0.6,glideDistance*0.35))
            local approachSpeed=2*glideDistance/(glideSteps*0.1)
            local alignDistance=approachSpeed*alignSteps*0.1
            local glide,lineup,control1,control2={},{},{},{}
            for axis=1,3 do
                glide[axis]=home[axis]-landingHeading[axis]*glideDistance
                lineup[axis]=glide[axis]-landingHeading[axis]*alignDistance
            end
            glide[2],lineup[2]=home[2]+height,home[2]+height
            for axis=1,3 do
                control1[axis]=departure[axis]+departureVelocity[axis]*curveSteps*0.1/3
                control2[axis]=lineup[axis]-landingHeading[axis]*approachSpeed*curveSteps*0.1/3
            end
            control1[2]=math.max(control1[2],math.min(departure[2],lineup[2]))
            local trail=variation.trail*clearance*6
            local side=(variation.side+math.sin(math.rad(variation.yaw)))*clearance*6
            local lateral={departureHeading[3],0,-departureHeading[1]}
            for step=1,curveSteps do
                local t=step/curveSteps;local u=1-t
                local bow=16*t*t*u*u
                local p={}
                for axis=1,3 do
                    p[axis]=u*u*u*departure[axis]+3*u*u*t*control1[axis]
                        +3*u*t*t*control2[axis]+t*t*t*lineup[axis]
                        +(lateral[axis]*side-departureHeading[axis]*trail)*bow
                end
                -- Variation belongs to the airborne turn, never the final.
                p[2]=math.max(p[2],home[2]+clearance*2)
                position(p,landingHeading,false)
                Sleep(100)
            end
            for step=1,alignSteps do
                local t=step/alignSteps
                local p={}
                for axis=1,3 do p[axis]=lineup[axis]+(glide[axis]-lineup[axis])*t end
                position(p,landingHeading,false,true)
                Sleep(100)
            end
            for step=1,glideSteps do
                local u=1-step/glideSteps
                local p={}
                -- Straight glide, with a gentle deceleration into the berth.
                for axis=1,3 do p[axis]=home[axis]+(glide[axis]-home[axis])*u*u end
                position(p,landingHeading,false,true)
                Sleep(100)
            end
            return
        end

        for step=1,steps do
            local t = step/steps
            local blend = t*t*(3-2*t)
            local carrierWeight = upward and blend or 1-blend
            local dock,flightHeading = dockingPoint()
            local dx,dz = dock[1]-home[1],dock[3]-home[3]
            local trail = math.sqrt(dx*dx+dz*dz)*0.3 + variation.trail*clearance*6
            local side = (variation.side + math.sin(math.rad(variation.yaw)))*clearance*6
            local lateral = {flightHeading[3],0,-flightHeading[1]}
            -- Bow behind the carrier; the offset and its derivative vanish at
            -- both ends, matching carrier velocity at docking and zero at land.
            local bow = 16*t*t*(1-t)*(1-t)
            local p = {}
            for axis=1,3 do
                p[axis] = home[axis]+(dock[axis]-home[axis])*carrierWeight
                    -flightHeading[axis]*trail*bow+lateral[axis]*side*bow
            end
            position(p,flightHeading,false)
            Sleep(100)
        end
        -- Stay visibly attached briefly while continuing to follow the hull.
        for _=1,6 do
            local dock,flightHeading = dockingPoint()
            position(dock,flightHeading,false)
            Sleep(100)
        end
    end
end
