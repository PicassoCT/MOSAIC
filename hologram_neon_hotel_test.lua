-- Real effect under scaled/rotated parents: street clearance, reading order,
-- upright glyphs, repeated-letter leases, flicker and complete restoration.
x_axis,y_axis,z_axis=1,3,2
sizeSpacingLetter,sizeDownLetter,textSpinner=321,350,99
local positions,rotations,visible,scale,heading,mode,spin,restored,time,seen,full,partial,off,reports
local function near(a,b)assert(math.abs(a-b)<1e-5,a..' ~= '..b)end
local function rotate(x,z)
    return math.cos(heading)*x+math.sin(heading)*z,-math.sin(heading)*x+math.cos(heading)*z
end
local function world(id)
    local p=positions[id] or {0,0,0}
    local x,z=rotate(10+scale*(id*.2+p[1]),5-scale*(id*.3+p[2]))
    return {100+x,80+scale*(id*.1+p[3]),200+z}
end
function Move(id,a,v,s)assert(s>=0);positions[id]=positions[id] or {0,0,0};positions[id][a]=v end
function Turn(id,a,v,s)rotations[id]=rotations[id] or {0,0,0};rotations[id][a]=v end
function StopSpin(id,a)if id==textSpinner then assert(a==3);spin=nil end end
function Spin(id,a,v)assert(id==textSpinner and a==3);spin=v end
function ShowReg(id)visible[id]=true end
function HideReg(id)visible[id]=nil end
function hideTReg(ids)for _,id in ipairs(ids)do HideReg(id)end end
function restoreMessageOriginalPosition(ids,p)
    restored=restored+1
    for _,id in ipairs(ids)do
        for a=1,3 do near(positions[id][a],0);near(rotations[id][a],0);Move(id,a,p[id][a],0)end
        ShowReg(id)
    end
end
Spring={
    GetUnitPosition=function()return 100,0,200 end,
    GetUnitVectors=function()
        local fx,fz=rotate(0,1);local rx,rz=rotate(-1,0)
        return {fx,0,fz},{0,1,0},{rx,0,rz}
    end,
    GetUnitPieceMap=function()return {text_spin=textSpinner}end,
    GetUnitPieceInfo=function()return {parent='text_spin',min={-20,-120,-40},max={20,120,360}}end,
    GetUnitPieceMatrix=function(_,id)
        if mode=='missing' then return end
        local p=positions[id] or {0,0,0}
        if mode=='tilted' then return scale,0,0,0,0,scale,0,0,0,0,scale,0,10,80,5,1 end
        return scale,0,0,0,0,0,-scale,0,0,scale,0,0,
            10+(id~=99 and scale*(id*.2+p[1]) or 0),
            80+(id~=99 and scale*(id*.1+p[3]) or 0),
            5-(id~=99 and scale*(id*.3+p[2]) or 0),1
    end,
    GetGroundHeight=function(x,z)return 7+.02*x+.03*z end,
}
function Sleep(ms)
    time=time+ms
    if ms==34 or mode~='normal' then return end
    assert(not spin,'hotel sign must not orbit while world targets are cached')
    local count=0
    for id in pairs(visible)do
        count=count+1
        for a=1,3 do near(rotations[id][a],0)end
        local w=world(id)
        local x,z=rotate(10+scale*.2,5-scale*.3);x,z=100+x,200+z
        near(w[1],x);near(w[3],z)
        local base=Spring.GetGroundHeight(x,z)+180*scale
        local slot=6-(w[2]-base)/(480*scale)
        near(slot,math.floor(slot+.5));seen[id..':'..math.floor(slot+.5)]=true
        assert((id==1 and (math.abs(slot-1)<1e-5 or math.abs(slot-4)<1e-5)) or
            (id==2 and math.abs(slot-2)<1e-5) or (id==3 and math.abs(slot-6)<1e-5),'reading order/word gap changed')
        if id==3 then near(w[2]-40*scale,Spring.GetGroundHeight(x,z)+140*scale)end
    end
    if count==0 then off=off+1 elseif count==3 then full=full+1 else partial=partial+1 end
end
dofile('scripts/lib_textFx.lua')
assert(getAllTextFx().neonHotelText==neonHotelText)
for _,s in ipairs({.0254,.1,1})do for _,h in ipairs({0,math.pi/2,math.pi})do
for _,upright in ipairs({false,true})do for _,m in ipairs({'normal','missing','tilted'})do
    positions,rotations,visible={}, {}, {};scale,heading,mode=s,h,m
    spin,restored,time,seen,full,partial,off,reports=.3,0,0,{},0,0,0,0
    local spacing,leases=allocateHologramSlots('AB A C ',{A={1},B={2},C={3}})
    local p={unitID=7,spacing=spacing,leases=leases,slotByPiece={[1]=1,[2]=2,[3]=6},
        boolUpright=upright,spinnerSpeed=.3,debugTextFx=function()reports=reports+1 end}
    for id=1,3 do p[id]={0,-id*321,id*350}end
    assert(canProjectTextFx('neonHotelText',p))
    neonHotelText({1,2,3},p)
    assert(restored==1 and spin==.3)
    for id=1,3 do for a=1,3 do near(positions[id][a],p[id][a])end end
    if mode=='normal' then
        assert(reports==0 and time>10000 and time<14000)
        assert(seen['1:1'] and seen['1:4'] and seen['2:2'] and seen['3:6'],'logical letter slots lost')
        assert(full>0 and partial>0 and off>0,'missing bright hold, faulty tube or power outage')
    else assert(reports==1 and time<100,'bad export was silently corrected or did not exit')end
end end end end
print('PASS: neon hotel street clearance, upright reading order, leases, flicker, 54 transforms/layout/fallback cases and cleanup')
