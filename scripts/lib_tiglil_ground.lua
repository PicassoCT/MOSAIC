-- Street projection for conversational idles. A dedicated model parent keeps
-- placement independent of deathpivot/dancepivot, which the old poses reset.
local M={}
local function add(a,b)return {a[1]+b[1],a[2]+b[2],a[3]+b[3]}end
local function sub(a,b)return {a[1]-b[1],a[2]-b[2],a[3]-b[3]}end
local function apply(a,v)return {a[1][1]*v[1]+a[1][2]*v[2]+a[1][3]*v[3],a[2][1]*v[1]+a[2][2]*v[2]+a[2][3]*v[3],a[3][1]*v[1]+a[3][2]*v[2]+a[3][3]*v[3]}end
local function mul(a,b)local r={{},{},{}};for i=1,3 do for j=1,3 do r[i][j]=0;for k=1,3 do r[i][j]=r[i][j]+a[i][k]*b[k][j]end end end;return r end
local function inverse(m)
    local a,b,c,d,e,f,g,h,i=m[1][1],m[1][2],m[1][3],m[2][1],m[2][2],m[2][3],m[3][1],m[3][2],m[3][3]
    local det=a*(e*i-f*h)-b*(d*i-f*g)+c*(d*h-e*g)
    if math.abs(det)<1e-12 then return end
    return {{(e*i-f*h)/det,(c*h-b*i)/det,(b*f-c*e)/det},
        {(f*g-d*i)/det,(a*i-c*g)/det,(c*d-a*f)/det},
        {(d*h-e*g)/det,(b*g-a*h)/det,(a*e-b*d)/det}}
end
local function euler(r)
    local x=-math.asin(math.max(-1,math.min(1,r[2][3])))
    if math.abs(math.cos(x))<1e-6 then return {x,math.atan2(-r[3][1],r[1][1]),0}end
    return {x,math.atan2(r[1][3],r[3][3]),math.atan2(r[2][1],r[2][2])}
end
function M.new(spring,native,owner,defs,lifetime)
    local SIG_GROUND=32768
    local anchor,parent,active,parts
    local function world(id)
        local front,up,right=spring.GetUnitVectors(owner)
        local ux,uy,uz=spring.GetUnitPosition(owner)
        if not (front and up and right and ux) then return end
        local unit={{-right[1],up[1],front[1]},{-right[2],up[2],front[2]},{-right[3],up[3],front[3]}}
        if not id then return unit,{ux,uy,uz}end
        local m={spring.GetUnitPieceMatrix(owner,id)}
        if not m[16] then return end
        return mul(unit,{{m[1],m[5],m[9]},{m[2],m[6],m[10]},{m[3],m[7],m[11]}}),add({ux,uy,uz},apply(unit,{m[13],m[14],m[15]}))
    end
    local function snap(fn,id,axis,value)
        -- Clear any queued native animation before setting an immediate value.
        fn(id,axis,value,1);fn(id,axis,value,0)
    end
    local function stop()
        active=nil
        if anchor then for axis=1,3 do snap(native.Move,anchor,axis,0);snap(native.Turn,anchor,axis,0)end end
        Signal(SIG_GROUND)
    end
    local function person(id)
        if id==owner or not spring.ValidUnitID(id) or spring.GetUnitIsDead(id) then return end
        local def=defs[spring.GetUnitDefID(id)]
        local base=def and def.customParams and def.customParams.baseclass
        if not base or string.lower(base)~='civilian' or def.isBuilding or def.canFly then return end
        if spring.GetUnitTransporter and spring.GetUnitTransporter(id) then return end
        local x,y,z=spring.GetUnitPosition(id)
        local vx,vy,vz=spring.GetUnitVelocity(id)
        if not x or not vx or vx*vx+vz*vz>.12 then return end
        if math.abs(y-spring.GetGroundHeight(x,z))>8 then return end
        return x,y,z
    end
    local function spot(id,x,z,radius,config,bodyScale)
        local personRadius=spring.GetUnitRadius(id) or 5
        if spring.GetUnitCollisionVolumeData then
            local sx,_,sz=spring.GetUnitCollisionVolumeData(id)
            if sx and sz then personRadius=math.max(sx,sz)*.5 end
        end
        local separation=config.distance and math.max(bodyScale*config.distance,personRadius*.65+bodyScale)
            or radius+personRadius+4
        local front=config.personal and spring.GetUnitVectors(id)
        local heading=front and math.atan2(front[3],front[1]) or (owner%8)*math.pi/4
        for i=0,(config.personal and 0 or 7) do
            local angle=heading+i*math.pi/4
            local px,pz=x+math.cos(angle)*separation,z+math.sin(angle)*separation
            local py=spring.GetGroundHeight(px,pz)
            local kind,blocked=spring.GetGroundBlocked(px-radius,pz-radius,px+radius,pz+radius)
            local clear=py>=0 and (not kind or (config.distance and kind=='unit' and blocked==id))
            for _,v in ipairs({{-radius,-radius},{radius,-radius},{-radius,radius},{radius,radius}})do
                if math.abs(spring.GetGroundHeight(px+v[1],pz+v[2])-py)>1.5 then clear=false end
            end
            if clear then return {px,py+.1,pz}end
        end
    end
    local function update()
        local state=active
        if not state then return false end
        local x,_,z=person(state.person)
        local ox,_,oz=spring.GetUnitPosition(owner)
        if not x or not ox or (x-state.personX)^2+(z-state.personZ)^2>20^2
            or (ox-state.ownerX)^2+(oz-state.ownerZ)^2>30^2 then stop();return false end
        local current,origin=world(anchor)
        local parentR,parentPos=world(parent)
        local inv=current and inverse(current)
        local invParent=parentR and inverse(parentR)
        if not (inv and invParent) then stop();return false end
        -- Evaluate the current animated silhouette under the fixed street
        -- orientation. Conservative mesh bounds also support snow angels and
        -- bent poses, where the torso or a hand can be lower than the feet.
        local lowest=math.huge
        for _,p in ipairs(parts)do
            local r,pos=world(p.id)
            if not r then stop();return false end
            local relative=mul(inv,r)
            local offset=apply(inv,sub(pos,origin))
            for mask=0,7 do
                local point={}
                for axis=1,3 do point[axis]=(math.floor(mask/2^(axis-1))%2==0 and p.min or p.max)[axis]end
                local v=apply(state.rotation,add(offset,apply(relative,point)))
                lowest=math.min(lowest,v[2])
            end
        end
        local target={state.origin[1],state.ground-lowest,state.origin[3]}
        local position=apply(invParent,sub(target,parentPos))
        local angles=euler(mul(invParent,state.rotation))
        for axis=1,3 do
            snap(native.Move,anchor,axis,position[axis])
            snap(native.Turn,anchor,axis,angles[axis])
        end
        return true
    end
    local function begin(config)
        config=config or {}
        -- Old models and isolated animation previews can omit placement APIs.
        for _,name in ipairs({'GetUnitPieceMap','GetUnitPieceInfo','GetUnitPieceMatrix','GetUnitVectors','GetUnitsInCylinder',
            'GetUnitPosition','GetUnitVelocity','GetGroundHeight','GetGroundBlocked','GetUnitRadius','GetUnitDefID','ValidUnitID','GetUnitIsDead'})do
            if not spring[name] then return false end
        end
        local map=spring.GetUnitPieceMap(owner)
        anchor=map and map.tiglil_anchor
        if not anchor then return false end
        stop()
        local info=spring.GetUnitPieceInfo(owner,anchor)
        parent=info and map[info.parent]
        parts={}
        for _,name in ipairs({'tigLil','tlHead','tlhairup','tlhairdown','tlarm','tlarmr','tllegUp','tllegUpR','tllegLow','tllegLowR'})do
            local id=map[name];local p=id and spring.GetUnitPieceInfo(owner,id)
            if not (p and p.min and p.max) then return false end
            parts[#parts+1]={id=id,min=p.min,max=p.max}
        end
        local a,apos=world(anchor);local body,bpos=world(map.tigLil)
        local inv=a and inverse(a)
        if not (inv and body) then return false end
        local relative=mul(inv,body);local invRelative=inverse(relative)
        if not invRelative then return false end
        local scale=math.sqrt(body[1][3]^2+body[2][3]^2+body[3][3]^2)
        local bodyScale=scale*(11060.378906/12)
        local radius=math.max(6,bodyScale*7)
        local ox,_,oz=spring.GetUnitPosition(owner)
        local candidates=spring.GetUnitsInCylinder(ox,oz,400) or {}
        table.sort(candidates,function(l,r)
            local lx,_,lz=spring.GetUnitPosition(l);local rx,_,rz=spring.GetUnitPosition(r)
            local ld=lx and (lx-ox)^2+(lz-oz)^2 or math.huge
            local rd=rx and (rx-ox)^2+(rz-oz)^2 or math.huge
            return ld==rd and l<r or ld<rd
        end)
        for _,id in ipairs(candidates)do
            local x,_,z=person(id)
            local height=spring.GetUnitHeight and spring.GetUnitHeight(id) or 18*bodyScale
            -- Civilian metadata uses a generic height/radius. Prefer the
            -- actual head location and collision width for close staging.
            if x and config.distance and spring.GetUnitPiecePosDir then
                local targetMap=spring.GetUnitPieceMap(id) or {}
                local head=targetMap.Head1 or targetMap.head or targetMap.Head
                if head then
                    local _,hy=spring.GetUnitPiecePosDir(id,head)
                    if hy then height=hy-spring.GetGroundHeight(x,z)+2*bodyScale end
                end
            end
            local compatible=not config.distance or (height>bodyScale*11 and height<bodyScale*26)
            local goal=x and compatible and spot(id,x,z,radius,config,bodyScale)
            if goal then
                local fx,fz=x-goal[1],z-goal[3];local len=math.sqrt(fx*fx+fz*fz);fx,fz=fx/len,fz/len
                local desiredBody={{fz*scale,-fx*scale,0},{0,0,scale},{-fx*scale,-fz*scale,0}}
                local rotation=mul(desiredBody,invRelative)
                local bodyOffset=apply(rotation,apply(inv,sub(bpos,apos)))
                active={person=id,personX=x,personZ=z,ownerX=ox,ownerZ=oz,rotation=rotation,
                    origin={goal[1]-bodyOffset[1],0,goal[3]-bodyOffset[3]},ground=goal[2]}
                if not update() then return false end
                StartThread(function()
                    SetSignalMask((lifetime or 0)+SIG_GROUND)
                    while active do Sleep(33);if not update()then return end end
                end)
                return {person=id,height=height,bodyScale=bodyScale}
            end
        end
        return false
    end
    return {begin=begin,stop=stop,update=update,isActive=function()return active~=nil end}
end
return M
