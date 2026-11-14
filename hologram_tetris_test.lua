-- Execute real falling blocks, collision placement, two-row clear and gravity.
-- Geometry runs under multiple imported scales and unit headings.
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

local snapshots,clears,settles,falls,shared
local function grid()
    local result,occupied={},{}
    local ax,az=rotate(10+scale*.2,5-scale*.3);ax,az=100+ax,200+az
    local dx,dz=rotate(0,1)
    local base=math.max(80+scale*.1,Spring.GetGroundHeight(ax,az)+400*scale*1.15*.4+40*scale)
    for id in pairs(visible)do
        local w=world(id)
        local x=((w[1]-ax)*dx+(w[3]-az)*dz)/(321*scale*1.15)+2.5
        local y=(w[2]-base)/(400*scale*1.15)
        near(x,math.floor(x+.5));near(y,math.floor(y+.5))
        assert(x>-.001 and x<5.001 and y>-.001,'piece escaped board')
        local key=math.floor(y+.5)*6+math.floor(x+.5)
        assert(not occupied[key],'locked blocks overlap');occupied[key]=true
        result[id]={x=x,y=y}
        for axis=1,3 do near(rotations[id][axis],0)end
    end
    return result
end
function Sleep(ms)
    time=time+ms
    if ms==34 or mode~='normal' then return end
    assert(not spin,'board rotates during a fall')
    if ms==60 then falls=falls+1 end
    if ms==240 then snapshots[#snapshots+1]=grid() end
end
dofile('scripts/lib_textFx.lua')
for _,s in ipairs({.0254,.1,1})do for _,h in ipairs({0,math.pi/2,math.pi})do
for _,upright in ipairs({false,true})do for _,repeatGlyph in ipairs({false,true})do
    positions,rotations,visible={}, {}, {};scale,heading,mode=s,h,'normal'
    spin,restored,time=.3,0,0;snapshots,clears,settles,falls={},{},{},0;shared=repeatGlyph
    local ids,p={}, {unitID=7,spacing={},leases={},slotByPiece={},boolUpright=upright,spinnerSpeed=.3}
    for i=1,24 do
        local id=repeatGlyph and ((i-1)%4+1) or i
        p.spacing[i]=id;p.leases[id]=p.leases[id] or {};p.leases[id][#p.leases[id]+1]=i
        if not p[id] then ids[#ids+1]=id;p[id]={0,-i*321,i*350};p.slotByPiece[id]=i end
    end
    p.debugTextFx=function(message)
        local n=message:match('clearing (%d+) rows')
        if n then clears[#clears+1]=tonumber(n) end
        if message:find('settled after row clear',1,true)then settles[#settles+1]=grid()end
    end
    assert(canProjectTextFx('tetrisText',p))
    tetrisText(ids,p)
    assert(restored==1 and spin==.3 and #snapshots==6 and falls>=66)
    assert(clears[1]==2 and #settles>=1,'new O block did not clear the two built rows')
    if not repeatGlyph then
        assert(#snapshots[4]==16)
        for id=9,12 do near(snapshots[4][id].y,2);near(settles[1][id].y,0)end
        for id=1,8 do assert(not settles[1][id],'cleared row survived')end
    end
    assert(time>6000 and time<18000,'unbounded animation')
    for _,id in ipairs(ids)do for a=1,3 do near(positions[id][a],p[id][a])end end
end end end end
-- Small and empty phrases, and a malformed axis, must finish without a wait.
local lengths={}
for n=0,19 do lengths[#lengths+1]=n end
lengths[#lengths+1]=32;lengths[#lengths+1]=65
for _,count in ipairs(lengths)do
    positions,rotations,visible={}, {}, {};scale,heading,mode=.1,0,'short'
    spin,restored,time=.3,0,0
    local ids,p={}, {unitID=7,spinnerSpeed=.3}
    for id=1,count do ids[id]=id;p[id]={0,0,0}end
    tetrisText(ids,p)
    assert(time<3000+count*1600 and restored==(count==0 and 0 or 1))
end
for _,bad in ipairs({'tilted','missing'})do
    positions,rotations,visible={}, {}, {};mode=bad;spin,restored,time=.3,0,0
    local reported=false
    tetrisText({1},{unitID=7,spinnerSpeed=.3,[1]={0,0,0},debugTextFx=function()reported=true end})
    assert(reported and restored==1 and time<100,'bad model was silently corrected')
end
print('PASS: Tetris landing, two-row clear, settling, scarce glyph leases, 36 scaled/rotated layouts, short phrases and cleanup')
