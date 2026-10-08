-- Shared FlamePainter budget for potentially hundreds of Antagon Cinders.
-- All records are cosmetic. The synced Flame weapon owns damage/collision.
-- A fixed CPU sample budget and a fixed ribbon budget prevent an O(N) raycast
-- or O(N*strands) draw-call explosion as the number of walkers increases.
return function(S,Collision)
    local M={MAX_DETAILED=8,MAX_SIMPLE=16,MAX_RIBBONS=48,
        MAX_TRACES_PER_FRAME=2,MAX_LITE_PER_FRAME=4,
        DETAIL_DISTANCE=1250,SIMPLE_DISTANCE=2700}
    local min,max,sqrt=math.min,math.max,math.sqrt
    local function clamp(v,lo,hi) return max(lo,min(hi,v)) end
    local lastBudgetFrame=-1
    local traceCount,liteCount=0,0

    local function makeRibbon(env,x,y,z,seed,opacity)
        return env.flame(x,y,z,1,seed,false,0,0,0,opacity)
    end
    local function extra(env,ribbon)
        local x,y,z=ribbon.x,ribbon.y,ribbon.z
        env.extraFlames[#env.extraFlames+1]={ribbon=ribbon,
            d2=(env.cx-x)^2+(env.cy-y)^2+(env.cz-z)^2}
    end
    local function normalize(x,y,z)
        local mag=sqrt(x*x+y*y+z*z)
        if mag<0.001 then return 0,1,0 end
        return x/mag,y/mag,z/mag
    end
    local function emitLight(env,x,y,z,r,c,strength,ribbon)
        env.add(x,y,z,r,c,strength,false,ribbon)
    end
    local function emitMain(env,record,x,y,z,dx,dy,dz,length,guard,opacity,detailed)
        local seed=record.seed
        local main=makeRibbon(env,x,y,z,seed,opacity)
        main.direction={dx,dy,dz}
        main.length=length
        main.width=detailed and min(17,max(5,length*.38)) or 12
        main.strands=detailed and 4 or 2
        main.curl=detailed and .62 or .45
        main.speed=detailed and 3.6 or 3.0
        main.trailTime=.14
        main.windInfluence=.15
        main.colorStart={1,.82,.29,.95}
        main.colorEnd={.83,.12,.012,0}
        main.emission={detailed and 2.5 or 1.7,.28}
        main.sourceGlow={1,.3,.035,.45}
        main.terrainGuard=guard
        local nearDist=min(15,length*.32)
        local intensity=min(1,length/90)*opacity*(env.brightness or 1.3)/1.3
        emitLight(env,x+dx*nearDist,y+dy*nearDist,z+dz*nearDist,
            min(56,max(20,length*.4)),{1,.26,.035},
            (detailed and .46 or .26)*intensity,main)
        if detailed then
            local farDist=max(2,length*.82)
            emitLight(env,x+dx*farDist,y+dy*farDist,z+dz*farDist,
                min(62,max(18,length*.35)),{1,.24,.025},.24*intensity)
        end
    end

    local function emitBreakup(env,record,origin,length,count,opacity,guard)
        local x,y,z,dx,dy,dz=unpack(origin)
        local sideX,sideZ=-dz,dx
        local sm=sqrt(sideX*sideX+sideZ*sideZ)
        if sm<.001 then sideX,sideZ=1,0 else sideX,sideZ=sideX/sm,sideZ/sm end
        for i=1,count do
            local at=length*(.15+i*.18)
            local available=length-at-3
            if available>9 then
                local phase=env.frame*.09+record.seed*.17+i*2.5
                local side=(i%2==0) and 1 or -1
                local bend=side*(.24+.05*i)+math.sin(phase)*.13
                local ax,ay,az=normalize(dx+sideX*bend,
                    dy*.7+.09+math.sin(phase*.7)*.04,dz+sideZ*bend)
                local ox,oy,oz=x+dx*at+sideX*side*3,
                    y+dy*at,z+dz*at+sideZ*side*3
                local tongue=makeRibbon(env,ox,oy,oz,record.seed+i*41,
                    opacity*(.42+.07*(i%2)))
                tongue.direction={ax,ay,az}
                tongue.length=min(19+(i%3)*7,available)
                tongue.width=5
                tongue.strands=2
                tongue.curl=.83
                tongue.speed=3.9
                tongue.windInfluence=.24
                tongue.trailTime=.12
                tongue.emission={1.8,.12}
                tongue.sourceGlow={1,.2,.03,.20}
                -- A subrange of the *same* main terrain envelope. No new
                -- GetGroundHeight calls for any breakup tongue.
                record.midGuards=record.midGuards or {}
                local cached=record.midGuards[i]
                if not cached then
                    cached=Collision.SliceGuard(guard,at,tongue.length,length,9)
                    record.midGuards[i]=cached
                end
                tongue.terrainGuard=cached
                extra(env,tongue)
            end
        end
    end

    local function emitImpact(env,record,origin,hit,opacity)
        local x,y,z,dx,dy,dz=unpack(origin)
        local nx,ny,nz=unpack(hit.normal)
        local guard=record.impactGuard
        if not guard then return end
        local sx,sy,sz,fx,fy,fz
        if hit.kind=='ground' then
            local d=dx*nx+dy*ny+dz*nz
            fx,fy,fz=normalize(dx-nx*d,dy-ny*d,dz-nz*d)
            sx,sy,sz=normalize(ny*fz-nz*fy,nz*fx-nx*fz,nx*fy-ny*fx)
        else
            sx,sy,sz=normalize(-nz,0,nx)
            if math.abs(sx)+math.abs(sz)<.05 then
                sx,sy,sz=normalize(-dz,0,dx)
            end
        end
        for i=1,2 do
            local side=i==1 and -1 or 1
            local ax,ay,az
            if hit.kind=='ground' then
                ax,ay,az=normalize(fx+sx*side*.62+nx*.25,
                    fy+sy*side*.62+ny*.25,
                    fz+sz*side*.62+nz*.25)
            else
                ax,ay,az=normalize(sx*side+nx*.16,
                    .5+max(ny,0)*.18,sz*side+nz*.16)
            end
            local ix,iy,iz=hit.x+nx*5,hit.y+ny*5+3,hit.z+nz*5
            local tongue=makeRibbon(env,ix,iy,iz,record.seed+317+i*53,opacity*.68)
            tongue.direction={ax,ay,az}
            tongue.length=hit.kind=='ground' and min(48,19+(175-hit.distance)*.24)
                or ((hit.open and hit.open[side]) and 44 or 27)
            tongue.width=6
            tongue.strands=2
            tongue.curl=.75
            tongue.speed=3.2
            tongue.windInfluence=.16
            tongue.trailTime=.12
            tongue.emission={1.9,.18}
            tongue.terrainGuard=guard -- shared fan envelope, never two probes
            extra(env,tongue)
        end
    end

    local function refreshFull(record,origin,id,simFrame,ally,full)
        local x,y,z,dx,dy,dz=unpack(origin)
        record.hit=Collision.Trace(id,x,y,z,dx,dy,dz,175,ally,full)
        local hit=record.hit
        local length=max(2,min(175,hit.distance-(hit.kind and 3 or 0)))
        record.length=length
        record.guard=Collision.Guard(x,z,dx,dz,length,9,18)
        record.impactGuard=hit.kind and Collision.FanGuard(hit.x,hit.z,54,11) or nil
        record.midGuards=nil
        record.sampleFrame=simFrame
        record.sample=origin
    end
    local function changed(origin,sample)
        if not sample then return true end
        local x,y,z,dx,dy,dz=unpack(origin)
        local px,py,pz,pdx,pdy,pdz=unpack(sample)
        return (x-px)^2+(y-py)^2+(z-pz)^2>16
            or dx*pdx+dy*pdy+dz*pdz<.995
    end

    function M.Collect(records,env)
        local simFrame=env.simFrame
        if simFrame~=lastBudgetFrame then
            lastBudgetFrame=simFrame
            traceCount,liteCount=0,0
        end
        local candidates={}
        for id,record in pairs(records) do
            if record.ruleFrame~=simFrame then
                record.untilFrame=S.GetUnitRulesParam(id,'mosaic_pyro_fire_until') or 0
                record.ruleFrame=simFrame
            end
            if record.untilFrame>env.frame and
                (not S.IsUnitIcon or not S.IsUnitIcon(id)) then
                local x,y,z=S.GetUnitViewPosition and S.GetUnitViewPosition(id)
                if not x then x,y,z=S.GetUnitPosition(id) end
                if x then
                    local d2=(env.cx-x)^2+(env.cy-y)^2+(env.cz-z)^2
                    if d2<M.SIMPLE_DISTANCE^2
                        and (not S.IsSphereInView or S.IsSphereInView(x,y,z,175))
                        and env.unitVisible(id) then
                        candidates[#candidates+1]={id=id,record=record,d2=d2}
                    end
                end
            end
        end
        table.sort(candidates,function(a,b)
            if a.d2==b.d2 then return a.id<b.id end
            return a.d2<b.d2
        end)
        -- Ensure the entire render budget is decided before any rays or
        -- ribbons are constructed, even with hundreds of firing walkers.
        local available=max(0,min(M.MAX_RIBBONS,64-env.otherRibbons))
        local detail,simple=0,0
        local selected={}
        for _,candidate in ipairs(candidates) do
            local tier
            if candidate.d2<M.DETAIL_DISTANCE^2
                and detail<M.MAX_DETAILED and available>=4 then
                tier='detail';detail=detail+1;available=available-4
            elseif simple<M.MAX_SIMPLE and available>=1 then
                tier='simple';simple=simple+1;available=available-1
            end
            if tier then
                candidate.tier=tier
                local x,y,z,dx,dy,dz=env.origin(candidate.id,candidate.record)
                if x then
                    candidate.origin={x,y,z,dx,dy,dz}
                    selected[#selected+1]=candidate
                end
            end
            if detail>=M.MAX_DETAILED and simple>=M.MAX_SIMPLE then break end
            if available==0 then break end
        end

        -- Fair, global scheduling: oldest/most-stale detailed sample first.
        -- Two expensive solves per simulation frame, regardless of population.
        local due={}
        for _,c in ipairs(selected) do
            if c.tier=='detail' then
                local r=c.record
                if not r.sampleFrame or simFrame-r.sampleFrame>=5
                    or changed(c.origin,r.sample) then
                    due[#due+1]=c
                end
            end
        end
        table.sort(due,function(a,b)
            local fa=a.record.sampleFrame or -100000
            local fb=b.record.sampleFrame or -100000
            if fa==fb then return a.d2<b.d2 end
            return fa<fb
        end)
        local _,full=S.GetSpectatingState()
        local ally=S.GetMyAllyTeamID()
        for _,c in ipairs(due) do
            if traceCount>=M.MAX_TRACES_PER_FRAME then break end
            refreshFull(c.record,c.origin,c.id,simFrame,ally,full)
            traceCount=traceCount+1
        end
        -- Cheaper LOD uses nine ground-height queries at most every 12 frames,
        -- scheduled four per frame. No unit/feature colvol rays or extra tongues.
        local liteDue={}
        for _,c in ipairs(selected) do
            if c.tier=='simple' then
                local r=c.record
                if not r.liteFrame or simFrame-r.liteFrame>=12
                    or changed(c.origin,r.liteSample) then
                    liteDue[#liteDue+1]=c
                end
            end
        end
        table.sort(liteDue,function(a,b)
            local fa=a.record.liteFrame or -100000
            local fb=b.record.liteFrame or -100000
            if fa==fb then return a.d2<b.d2 end
            return fa<fb
        end)
        for _,c in ipairs(liteDue) do
            if liteCount>=M.MAX_LITE_PER_FRAME then break end
            local r=c.record
            local x,y,z,dx,dy,dz=unpack(c.origin)
            r.liteLength,r.liteGuard=Collision.Lite(x,y,z,dx,dy,dz,175,12)
            r.liteFrame=simFrame
            r.liteSample=c.origin
            liteCount=liteCount+1
        end
        -- Rendering reads only cached collision/surface data, with a hard
        -- reservation of 4 ribbons per detailed / 1 per simple Cinder.
        for _,c in ipairs(selected) do
            local r=c.record
            r.seed=c.id%10000
            local x,y,z,dx,dy,dz=unpack(c.origin)
            local opacity=clamp((r.untilFrame-env.frame)/5,0,1)
            if c.tier=='detail' then
                if r.guard and r.length then
                    emitMain(env,r,x,y,z,dx,dy,dz,r.length,r.guard,opacity,true)
                    local hit=r.hit
                    emitBreakup(env,r,c.origin,r.length,hit and hit.kind and 1 or 3,opacity,r.guard)
                    if hit and hit.kind then emitImpact(env,r,c.origin,hit,opacity) end
                end
            elseif r.liteGuard then
                emitMain(env,r,x,y,z,dx,dy,dz,r.liteLength,r.liteGuard,opacity,false)
            end
        end
        M.lastStats={candidateCount=#candidates,detailed=detail,simplified=simple,
            selected=#selected,tracesThisFrame=traceCount,liteThisFrame=liteCount,
            extraRibbons=#env.extraFlames}
    end
    return M
end
