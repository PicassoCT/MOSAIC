-- Scaled/rotated glyph fixture shared by the kinetic typography regressions.
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
local F={}
local observer,phase,logicalTime,phaseStart
local function center(id)
    local w=world(id);local angle=rotations[id] and rotations[id][2] or 0
    -- Fixture bounds centre = (0, 0, 160), rotated around native baseline Y.
    local x,z=rotate(math.sin(angle)*160*scale,0)
    return {w[1]+x,w[2]+math.cos(angle)*160*scale,w[3]+z}
end
function Sleep(ms)
    time=time+ms
    local logical=ms*GetHologramTextFxSpeed();logicalTime=logicalTime+logical
    if math.abs(logical-34)<1e-7 then return end
    if mode~='normal' then return end
    assert(not spin,'parent moved cached world targets')
    local sample={time=logicalTime,phaseTime=logicalTime-phaseStart,phase=phase,points={}}
    local rx,rz=rotate(0,1);local nx,nz=rotate(1,0)
    for id in pairs(visible)do
        local c=center(id)
        sample.points[id]={x=c[1]*rx+c[3]*rz,y=c[2],z=c[1]*nx+c[3]*nz,world=c,angle=rotations[id][2]}
    end
    F.samples[#F.samples+1]=sample
    if observer then observer(sample,F)end
end
unitID,unitDefID=7,1
UnitDefs={[1]={customParams={text_fx_speed=1}}}
Spring.GetUnitTeam=function()return 0 end
Spring.UnitScript={Move=Move,Turn=Turn,Spin=Spin,StopSpin=StopSpin,Sleep=Sleep}
local function read(path)local f=assert(io.open(path));local s=f:read('*a');f:close();return s end
assert(loadstring(read('gamedata/unit_script_header.lua')..'\n'..read('scripts/lib_textFx.lua')))()
F.near=near
function F.run(name,options,inspect)
    options=options or {}
    scale,heading,mode=options.scale or .0254,options.heading or 0,options.mode or 'normal'
    positions,rotations,visible={},{},{}
    spin,restored,time,logicalTime,phaseStart=.3,0,0,0,0
    F.samples={};F.scale=scale;F.step=321*scale*1.2;F.height=400*scale
    phase,observer=nil,inspect
    local phrase=options.phrase or 'AB CDEFGHIJKLMNOABCD'
    local groups,ids={},{}
    for letter in phrase:gmatch('.')do
        if letter~=' ' and not groups[letter] then ids[#ids+1]=#ids+1;groups[letter]={#ids}end
    end
    local spacing,leases=allocateHologramSlots(phrase,groups)
    local p={unitID=7,spacing=spacing,leases=leases,slotByPiece={},spinnerSpeed=.3,boolUpright=options.upright}
    F.slots=#spacing;F.leases=leases
    for i,id in ipairs(spacing)do if id~=' ' then p[id]={0,-i*321,i*350};p.slotByPiece[id]=i end end
    p.debugTextFx=function(message)phase=message;phaseStart=logicalTime end
    assert(canProjectTextFx(name,p))
    local fn=assert(getAllTextFx()[name])
    runHologramTextFx(fn,ids,p,nil,options.speed or 1)
    assert(spin==.3,'parent spin was not restored')
    assert(restored==(#ids==0 and 0 or 1),'original phrase was not restored exactly once')
    for _,id in ipairs(ids)do for axis=1,3 do near(positions[id][axis],p[id][axis])end end
    if mode~='normal' then assert(phase:find('skipped',1,true) and logicalTime<100,'malformed export was corrected silently')end
    F.time,F.logicalTime=time,logicalTime
    return F
end
return F
