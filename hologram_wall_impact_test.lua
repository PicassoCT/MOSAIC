-- Exercise the live effect with rotated/scaled glyph parents and house pieces.
assert(_VERSION=='Lua 5.1')
local function read(path)local f=assert(io.open(path));local s=f:read('*a');f:close();return s end
local prefix={}
local header=read('gamedata/unit_script_header.lua')
for _,a in ipairs({'x_axis','y_axis','z_axis'}) do prefix[#prefix+1]=assert(header:match('local '..a..' = %d+')) end
sizeSpacingLetter,sizeDownLetter,textSpinner=321,350,99
UnitDefs={}
local positions,angles,visible,scale,heading,houseHeading,houseScale,mode,dead
local spin,restores,holds,ticks,total,flown,first,borrowed,p
local function near(a,b)assert(math.abs(a-b)<1e-5,tostring(a)..' ~= '..tostring(b))end
local function rotate(v,h)
    local c,s=math.cos(h*math.pi/2),math.sin(h*math.pi/2)
    return {c*v[1]+s*v[3],v[2],-s*v[1]+c*v[3]}
end
local function glyphVector(v) return rotate({scale*v[1],scale*v[3],-scale*v[2]},heading) end
local function world(id)
    local v=positions[id] or {0,0,0}
    local w=rotate({10+scale*(id*.2+v[1]),80+scale*(id*.1+v[3]),5-scale*(id*.3+v[2])},heading)
    return {100+w[1],10+w[2],200+w[3]}
end
local function houseLocal(w)
    local v={w[1]-400,w[2],w[3]-200}
    if houseHeading==1 then v={-v[3],v[2],v[1]} end
    return {v[1]/houseScale,v[2]/houseScale,v[3]/houseScale}
end
function Move(id,a,v,s)assert(v==v and s>=0 and s<math.huge);positions[id]=positions[id] or {0,0,0};positions[id][a]=v end
function Turn(id,a,v,s)assert(v==v and s>=0 and s<math.huge);angles[id]=angles[id] or {0,0,0};angles[id][a]=v end
function StopSpin(id,a)if id==textSpinner then assert(a==3);spin=nil end end
function Spin(id,a,v)assert(id==textSpinner and a==3);spin=v end
function ShowReg(id)visible[id]=true end
function HideReg(id)visible[id]=nil end
function hideTReg(ids)for _,id in ipairs(ids)do HideReg(id)end end
function restoreMessageOriginalPosition(ids,pos)
    restores=restores+1
    for _,id in ipairs(ids) do
        for a=1,3 do near(positions[id][a],0);near(angles[id][a],0);Move(id,a,pos[id][a],0) end
        ShowReg(id)
    end
end
function getCivilianHouseTypeTable()return {[2]=true}end
Spring={
    GetUnitsInCylinder=function()return mode=='absent' and {} or {8,9}end,
    GetUnitDefID=function(id)return id==8 and mode~='nonhouse' and 2 or 3 end,
    ValidUnitID=function()return not dead end,
    GetUnitIsDead=function()return dead end,
    GetUnitPosition=function(id)if id==8 then return 400,0,200 end return 100,10,200 end,
    GetUnitVectors=function(id)
        local h=id==8 and houseHeading or heading
        return rotate({0,0,1},h),{0,1,0},rotate({-1,0,0},h)
    end,
    GetUnitPieceMap=function()return {text_spin=textSpinner}end,
    GetUnitPieceInfo=function(owner,id)
        if owner==8 then
            assert(id==71,'hidden house variants must not participate')
            if mode=='small' then return {min={-1,0,-1},max={1,1,1}} end
            return {min={-60,0,-30},max={60,100,30}}
        end
        return {parent='text_spin'}
    end,
    GetUnitPieceMatrix=function(owner,id)
        if owner==8 then return houseScale,0,0,0,0,houseScale,0,0,0,0,houseScale,0,0,0,0,1 end
        if mode=='missingMatrix' then return end
        local v=positions[id] or {0,0,0}
        local x,y,z=10,80,5
        if id~=textSpinner then x,y,z=x+scale*(id*.2+v[1]),y+scale*(id*.1+v[3]),z-scale*(id*.3+v[2]) end
        return scale,0,0,0,0,0,-scale,0,0,scale,0,0,x,y,z,1
    end,
    UnitScript={
        GetScriptEnv=function()return {GetBuildingClearancePieces=function()if mode~='unfinished' then return {71} end end}end,
        CallAsUnit=function(_,fn)return fn()end,
    },
}
local function finalFacing(id)
    local a=angles[id]
    local cx,sx,cy,sy,cz,sz=math.cos(a[1]),math.sin(a[1]),math.cos(a[2]),math.sin(a[2]),math.cos(a[3]),math.sin(a[3])
    local depth=glyphVector({cy*cz+sy*sx*sz,cx*sz,-sy*cz+cy*sx*sz})
    local up=glyphVector({sy*cx,-sx,cy*cx})
    near(up[1],0);near(up[2],scale);near(up[3],0)
    local normal={-1,0,0}
    -- For both house headings the owner is west of the house: the chosen face
    -- must face west, while the glyph's positive depth points into that wall.
    for k=1,3 do near(depth[k],-normal[k]*scale) end
end
function Sleep(ms)
    total=total+ms
    if ms==34 then return end
    assert(not spin,'parent must freeze for world targets')
    if ms==33 then
        ticks=ticks+1
        if mode=='destroyed' and ticks==4 then dead=true end
        for id=1,4 do
            if visible[id] then
                flown[id]=true
                local w=houseLocal(world(id))
                -- Flight remains outside the west wall; never shoots through it.
                if houseHeading==0 then assert(w[1]<=-60+1e-6) else assert(w[3]<=-30+1e-6) end
            end
        end
        if ticks==1 then assert(visible[1] and not visible[2],'volley must be staggered') end
    elseif ms==500 then
        holds=holds+1
        if mode=='destroyedHold' then dead=true end
        for id=1,4 do
            assert(flown[id] and visible[id])
            local w=houseLocal(world(id))
            local offset=sizeDownLetter*scale*.04/houseScale
            if houseHeading==0 then near(w[1],-60-offset);assert(math.abs(w[3])<30)
            else near(w[3],-30-offset);assert(math.abs(w[1])<60) end
            assert(w[2]>0 and w[2]<100,'letters exceed wall height')
            finalFacing(id)
        end
        if holds==1 then first=world(1) end
        if holds==2 then local w=world(1);borrowed=math.abs(w[2]-first[2])+math.abs(w[3]-first[3])>1 end
    else error('unexpected sleep '..ms) end
end
assert(loadstring(table.concat(prefix,'\n')..'\n'..read('scripts/lib_textFx.lua')))()
local function run(which)
    mode,dead=which,false
    positions,angles,visible,flown={},{},{},{}
    spin,restores,holds,ticks,total,borrowed=-.3,0,0,0,0,false
    p={unitID=7,spacing={1,2,' ',3,4,1},slotByPiece={[1]=1,[2]=2,[3]=4,[4]=5},leases={[1]={1,6}},spinnerSpeed=-.3}
    for id=1,4 do p[id]={0,-321*(id-1),0} end
    wallImpactText({1,2,3,4},p)
    assert(restores==1);near(spin,-.3)
    assert(total<8000,'wall effect exceeded bounded volley and hold')
end
for _,h in ipairs({0,.37,1}) do for _,hh in ipairs({0,1}) do
    for _,sc in ipairs({.01,.03}) do for _,hs in ipairs({1,2}) do
        heading,houseHeading,scale,houseScale=h,hh,sc,hs
        run('normal');assert(holds==8 and borrowed and ticks>20)
        p.boolUpright=true;assert(canProjectTextFx('wallImpactText',p))
    end end
end end
for _,which in ipairs({'absent','nonhouse','unfinished','small','missingMatrix'}) do run(which);assert(holds==0 and ticks==0,which) end
run('destroyed');assert(holds==0 and ticks==4,'destroyed wall must terminate promptly')
run('destroyedHold');assert(holds==1,'destroyed wall must terminate during hold')
restores=0;wallImpactText({},p);assert(restores==0)
assert(getAllTextFx().wallImpactText==wallImpactText)
print('PASS: wall volley, outward facing, imported scales, rotated houses/parents, wrapping, leases, missing/destroyed targets and cleanup')
