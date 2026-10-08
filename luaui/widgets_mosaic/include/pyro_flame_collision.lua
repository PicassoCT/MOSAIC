-- Client-side, bounded collision sampling for Cinder's visual flamethrower.
-- No gameplay damage is calculated here. The simulated Flame weapon remains
-- authoritative. Recoil 2026.07 exposes exact unit/feature ray/colvol hits;
-- older engines use LOS-filtered collision-volume boxes as an approximation.
return function(S)
    local M={}
    local sqrt,abs,max,min=math.sqrt,math.abs,math.max,math.min
    local TERRAIN_STEP=7
    local CLEARANCE=9
    local function normalize(x,y,z)
        local len=sqrt(x*x+y*y+z*z)
        if len<0.0001 then return 0,1,0 end
        return x/len,y/len,z/len
    end
    local function dot(x,y,z,a,b,c) return x*a+y*b+z*c end
    local function surfaceNormal(x,z)
        if S.GetGroundNormal then
            local nx,ny,nz=S.GetGroundNormal(x,z)
            if nx and ny and nz then return normalize(nx,ny,nz) end
        end
        return 0,1,0
    end
    local function groundHeight(x,z)
        return S.GetGroundHeight and S.GetGroundHeight(x,z) or -100000
    end
    local function visibleUnit(id,shooter,ally,full)
        if id==shooter or (S.ValidUnitID and not S.ValidUnitID(id))
            or (S.GetUnitIsDead and S.GetUnitIsDead(id))
            or (S.GetUnitIsCloaked and S.GetUnitIsCloaked(id)) then return false end
        if full then return true end
        if not S.GetUnitLosState then return false end
        local state=S.GetUnitLosState(id,ally)
        return state and state.los
    end
    local function visiblePosition(x,y,z,ally,full)
        return full or (S.IsPosInLos and S.IsPosInLos(x,y,z,ally))
    end
    local function groundHit(x,y,z,dx,dy,dz,reach)
        local upper=reach
        if S.TraceRayGroundInDirection then
            -- The engine ray tests terrain itself. The sampled clearance below
            -- keeps the *thick* visible ribbon from passing into the mesh.
            local dist=S.TraceRayGroundInDirection(x,y,z,dx,dy,dz,reach,false)
            if type(dist)=='number' and dist>=0 then upper=min(upper,dist) end
        end
        local prev=0
        local d=min(TERRAIN_STEP,upper)
        while d<=upper do
            local px,pz=x+dx*d,z+dz*d
            if y+dy*d<=groundHeight(px,pz)+CLEARANCE then
                local low,high=prev,d
                for _=1,4 do
                    local mid=(low+high)*.5
                    local tx,tz=x+dx*mid,z+dz*mid
                    if y+dy*mid<=groundHeight(tx,tz)+CLEARANCE then high=mid
                    else low=mid end
                end
                local hx,hz=x+dx*high,z+dz*high
                local hy=groundHeight(hx,hz)
                local nx,ny,nz=surfaceNormal(hx,hz)
                return {kind='ground',distance=high,x=hx,y=hy+CLEARANCE,z=hz,
                    normal={nx,ny,nz}}
            end
            if d==upper then break end
            prev=d
            d=min(upper,d+TERRAIN_STEP)
        end
        -- Some builds report the terrain intersection before the fixed-step
        -- clearance sampler sees it. Never allow the visual to pass that hit.
        if upper<reach then
            local hx,hz=x+dx*upper,z+dz*upper
            local nx,ny,nz=surfaceNormal(hx,hz)
            return {kind='ground',distance=upper,x=hx,
                y=groundHeight(hx,hz)+CLEARANCE,z=hz,normal={nx,ny,nz}}
        end
    end
    local function objectNormal(kind,id,x,y,z,dx,dy,dz)
        local position,volume,vectors
        if kind=='unit' then
            position=S.GetUnitPosition
            volume=S.GetUnitCollisionVolumeData
            vectors=S.GetUnitVectors
        else
            position=S.GetFeaturePosition
            volume=S.GetFeatureCollisionVolumeData
            vectors=S.GetFeatureVectors
        end
        if not position or not volume then return normalize(-dx,max(.06,-dy),-dz) end
        local px,py,pz=position(id)
        local sx,sy,sz,ox,oy,oz=volume(id)
        if not px or not sx or not sy or not sz then
            return normalize(-dx,max(.06,-dy),-dz)
        end
        local front,up,right=vectors and vectors(id)
        front=front or {0,0,1};up=up or {0,1,0};right=right or {1,0,0}
        -- Model-X in Mosaic uses -right, consistent with flame piece transforms.
        local ax={-right[1],-right[2],-right[3]}
        local by={up[1],up[2],up[3]}
        local cz={front[1],front[2],front[3]}
        local cpx=px+ax[1]*(ox or 0)+by[1]*(oy or 0)+cz[1]*(oz or 0)
        local cpy=py+ax[2]*(ox or 0)+by[2]*(oy or 0)+cz[2]*(oz or 0)
        local cpz=pz+ax[3]*(ox or 0)+by[3]*(oy or 0)+cz[3]*(oz or 0)
        local vx,vy,vz=x-cpx,y-cpy,z-cpz
        local axes={ax,by,cz}
        local extents={max(1,sx*.5),max(1,sy*.5),max(1,sz*.5)}
        local best,score,sign=1,-1,1
        for i=1,3 do
            local axis=axes[i]
            local distance=dot(vx,vy,vz,axis[1],axis[2],axis[3])
            local fraction=abs(distance)/extents[i]
            if fraction>score then best,score,sign=i,fraction,distance<0 and -1 or 1 end
        end
        local n=axes[best]
        local nx,ny,nz=normalize(n[1]*sign,n[2]*sign,n[3]*sign)
        -- The normal must oppose the incoming fuel. A far/irregular colvol
        -- may produce an ambiguous face; fall back to the incoming direction.
        if dot(nx,ny,nz,dx,dy,dz)>.05 then
            return normalize(-dx,max(.06,-dy),-dz)
        end
        return nx,ny,nz
    end
    local function traceObjects(x,y,z,dx,dy,dz,reach,shooter,ally,full)
        if S.TraceRayInDirection then
            local hits=S.TraceRayInDirection(x,y,z,dx,dy,dz,reach,'both') or {}
            for i=1,#hits do
                local hit=hits[i]
                local dist=hit[1] or hit.dist
                local id=hit[2] or hit.objID
                local kind=hit[3] or hit.type
                if dist and dist>1 and dist<=reach and id and
                    (kind=='unit' or kind=='feature') then
                    local hx,hy,hz=x+dx*dist,y+dy*dist,z+dz*dist
                    local ok=(kind=='unit' and visibleUnit(id,shooter,ally,full))
                        or (kind=='feature' and visiblePosition(hx,hy,hz,ally,full))
                    if ok then
                        local nx,ny,nz=objectNormal(kind,id,hx,hy,hz,dx,dy,dz)
                        return {kind=kind,id=id,distance=dist,
                            x=hx,y=hy,z=hz,normal={nx,ny,nz}}
                    end
                end
            end
            return nil
        end
        -- Fallback for older BAR/Recoil builds without TraceRayInDirection.
        -- Rough volume boxes are used only for visual reflection, not hit damage.
        if not S.GetUnitsInCylinder or not S.GetUnitCollisionVolumeData then return nil end
        local ids=S.GetUnitsInCylinder(x+dx*reach*.5,z+dz*reach*.5,reach*.5+75) or {}
        local best
        for i=1,min(#ids,96) do
            local id=ids[i]
            if visibleUnit(id,shooter,ally,full) then
                local ux,uy,uz=S.GetUnitPosition(id)
                local sx,sy,sz,ox,oy,oz=S.GetUnitCollisionVolumeData(id)
                if ux and sx and sy and sz then
                    local lower,upper=0,reach
                    local centre={ux+(ox or 0),uy+(oy or 0),uz+(oz or 0)}
                    local half={sx*.5,sy*.5,sz*.5}
                    local direction={dx,dy,dz}
                    local origin={x,y,z}
                    for a=1,3 do
                        local delta=origin[a]-centre[a]
                        if abs(direction[a])<.0001 then
                            if abs(delta)>half[a] then lower=reach+1;break end
                        else
                            local a0=(-half[a]-delta)/direction[a]
                            local a1=(half[a]-delta)/direction[a]
                            if a0>a1 then a0,a1=a1,a0 end
                            lower=max(lower,a0);upper=min(upper,a1)
                            if lower>upper then break end
                        end
                    end
                    if lower>1 and lower<=upper and lower<=reach
                        and (not best or lower<best.distance) then
                        local hx,hy,hz=x+dx*lower,y+dy*lower,z+dz*lower
                        local nx,ny,nz=objectNormal('unit',id,hx,hy,hz,dx,dy,dz)
                        best={kind='unit',id=id,distance=lower,x=hx,y=hy,z=hz,normal={nx,ny,nz}}
                    end
                end
            end
        end
        return best
    end
    -- Sampled conservative envelope of the terrain along a ribbon. The
    -- FlamePainter vertex shader uses this guard to lift every strip vertex
    -- above the surface, including camera-facing width and vortex curl.
    function M.Guard(x,z,dx,dz,length,pad)
        if not S.GetGroundHeight then return nil end
        local h0=groundHeight(x,z)
        local h1=groundHeight(x+dx*length,z+dz*length)
        local bump=0
        local steps=max(1,math.ceil(length/6))
        for i=1,steps-1 do
            local t=i/steps
            local actual=groundHeight(x+dx*length*t,z+dz*length*t)
            bump=max(bump,actual-(h0+(h1-h0)*t))
        end
        return {h0,h1,bump+2,pad or 8}
    end
    function M.Trace(shooter,x,y,z,dx,dy,dz,reach,ally,full)
        local ground=groundHit(x,y,z,dx,dy,dz,reach)
        local object=traceObjects(x,y,z,dx,dy,dz,reach,shooter,ally,full)
        local hit=ground
        if object and (not hit or object.distance<hit.distance) then hit=object end
        if not hit then return {distance=reach,kind=nil} end
        if hit.kind~='ground' then
            -- Two small offset rays probe the real collision hull. An open
            -- side gets the longer wrap tongue; no new gameplay events.
            local sx,sz=-dz,dx
            local mag=sqrt(sx*sx+sz*sz)
            if mag<.001 then sx,sz=1,0 else sx,sz=sx/mag,sz/mag end
            hit.open={}
            for _,side in ipairs({-1,1}) do
                local neighbor=traceObjects(x+sx*side*7,y,z+sz*side*7,
                    dx,dy,dz,reach,shooter,ally,full)
                hit.open[side]=not neighbor or neighbor.distance>hit.distance+10
            end
        end
        return hit
    end
    return M
end
