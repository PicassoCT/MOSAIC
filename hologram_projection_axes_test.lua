-- Use the production header's aliases, not conventional x=1/y=2/z=3 mocks.
assert(_VERSION=='Lua 5.1')
local function read(path)
    local file=assert(io.open(path));local source=file:read('*a');file:close();return source
end
local header=read('gamedata/unit_script_header.lua')
local aliases={}
for _,name in ipairs({'x_axis','y_axis','z_axis'}) do
    aliases[#aliases+1]=assert(header:match('local '..name..' = %d+'))
end
sizeSpacingLetter,sizeDownLetter=321,350
textSpinner=99
local positions,angles,sleeps,moves,waits={},{},{},{},{}
local spinSpeeds,spinEvents,sleepObserver={},{},nil
local visible={}
function Move(id,axis,target,speed)
    positions[id]=positions[id] or {0,0,0};positions[id][axis]=target
    moves[#moves+1]={id,axis,target,speed}
end
function Turn(id,axis,angle,speed)
    angles[id]=angles[id] or {0,0,0};angles[id][axis]=angle
end
function Spin(id,axis,speed)
    spinSpeeds[id]=spinSpeeds[id] or {};spinSpeeds[id][axis]=speed
    spinEvents[#spinEvents+1]={id,axis,speed}
end
function StopSpin(id,axis)
    if spinSpeeds[id] then spinSpeeds[id][axis]=nil end
end
function reset(id)
    for axis=1,3 do Move(id,axis,0,0);Turn(id,axis,0,0) end
end
function foreach(ids,fn) for _,id in ipairs(ids) do fn(id) end end
function ShowReg(id) visible[id]=true end
function HideReg(id) visible[id]=nil end
function hideTReg(ids) for _,id in ipairs(ids) do HideReg(id) end end
function showTReg(ids) for _,id in ipairs(ids) do ShowReg(id) end end
function WaitForMove(id,axis) waits[#waits+1]={id,axis} end
function WaitForMoves(id) for axis=1,3 do WaitForMove(id,axis) end end
function Sleep(ms)
    sleeps[#sleeps+1]=ms
    if sleepObserver then sleepObserver(ms) end
end
function restoreMessageOriginalPosition(ids,pos)
    for _,id in ipairs(ids) do for axis=1,3 do Move(id,axis,pos[id][axis],0) end end
end
assert(loadstring(table.concat(aliases,'\n')..'\n'..read('scripts/lib_textFx.lua')))()
local function near(a,b) assert(math.abs(a-b)<1e-7,tostring(a)..' ~= '..tostring(b)) end
local ids={20,21,22}
local pos={spacing={20,' ',21,' ',22},slotByPiece={[20]=1,[21]=3,[22]=5},
    slotPositions={{15,25,35}},[20]={15,25,35},[21]={15,25,35},[22]={15,25,35}}
-- Exported text_spin maps (X,Y,Z) -> (X,Z,-Y): component 3 is
-- world height, and turning around it must leave the glyph's up unchanged.
for _,factor in ipairs({1,2.5}) do
    for _,id in ipairs(ids) do positions[id]={0,0,777};angles[id]={0,0,0} end
    sleeps={};moves={}
    circleProject(ids,pos,factor,true,true)
    local radius=#pos.spacing*sizeSpacingLetter*factor/math.pi
    for _,id in ipairs(ids) do
        local theta=math.pi*(pos.slotByPiece[id]-1)/#pos.spacing
        near(positions[id][1],radius*math.cos(theta))
        near(positions[id][2],radius*math.sin(theta))
        near(positions[id][3],777) -- fireworks altitude survives expansion
        near(angles[id][1],0);near(angles[id][2],0)
        near(angles[id][3],math.pi+theta)
    end
    assert(#sleeps==0)
    for _,move in ipairs(moves) do assert(move[2]~=3,'circle changes world height') end
end
sleeps={};circleProject(ids,pos)
assert(sleeps[1]==15000,'normal circle hold changed')
for _,id in ipairs(ids) do near(positions[id][3],0) end
-- Full readable rings use the actual Y/Z text plane, cover all quadrants,
-- keep glyphs unturned, and preserve logical gaps and parent spin state.
for _,count in ipairs({1,4,5,11,40}) do
    for _,sparse in ipairs({false,true}) do
        for _,speed in ipairs({0,0.2,-0.2}) do
            local letters,p={}, {spacing={},slotByPiece={},slotPositions={{15,25,35}},
                spinnerSpeed=speed~=0 and speed or nil}
            for slot=1,count do
                local id=500+slot
                p.spacing[slot]=' '
                if not sparse or slot%3~=0 then
                    letters[#letters+1]=id;p.spacing[slot]=id;p.slotByPiece[id]=slot;p[id]={15,25,35}
                    angles[id]={0.5,0.8,-0.4}
                end
            end
            spinEvents={};sleeps={};waits={};spinSpeeds[textSpinner]={[3]=speed}
            sleepObserver=function(ms)
                assert(ms==15000 and #waits==3*#letters,'ring hold starts before moves settle')
                assert(not spinSpeeds[textSpinner][3],'ring rotates away during readable hold')
            end
            ringProject(letters,p)
            sleepObserver=nil
            assert(#sleeps==1)
            if speed==0 then assert(#spinEvents==0)
            else assert(#spinEvents==1);near(spinSpeeds[textSpinner][3],speed) end
            local radius=count>1 and math.max((#letters+10)*sizeDownLetter/(2*math.pi),
                math.max(sizeSpacingLetter,sizeDownLetter)*1.15/(2*math.sin(math.pi/count))) or 0
            local covered={}
            for _,id in ipairs(letters) do
                local theta=2*math.pi*(p.slotByPiece[id]-1)/count
                near(positions[id][1],15)
                near(positions[id][2],25-radius*math.sin(theta))
                near(positions[id][3],35+radius+radius*math.cos(theta))
                for axis=1,3 do near(angles[id][axis],0) end
                covered[math.floor(theta/(math.pi/2))]=true
                assert(positions[id][3]>=35-1e-7,'ring drops below its original baseline')
            end
            if not sparse and count>=4 then
                for quadrant=0,3 do assert(covered[quadrant],'ring only covers an arch') end
            end
        end
    end
end
for _,upright in ipairs({false,true}) do
    pos.boolUpright=upright
    archProject(ids,pos)
    for _,id in ipairs(ids) do
        near(positions[id][1],15)
        for axis=1,3 do near(angles[id][axis],0) end
    end
    local radius=5*sizeSpacingLetter/math.pi
    for _,id in ipairs(ids) do
        local theta=math.pi*(pos.slotByPiece[id]-0.5)/#pos.spacing
        near(positions[id][2],25-radius+radius*math.cos(theta))
        near(positions[id][3],35+radius*math.sin(theta))
    end
end
-- Even arc lengths, upright glyphs, and a second row exactly above the limit.
-- Include sparse physical glyphs: unavailable characters still reserve slots.
for _,count in ipairs({1,2,20,21,22,41,80}) do
    for _,sparse in ipairs({false,true}) do
        local letters,p={}, {spacing={},slotByPiece={},slotPositions={{15,25,35}}}
        for slot=1,count do
            local id=100+slot
            p.spacing[slot]=' '
            if not sparse or slot%3~=0 then
                letters[#letters+1]=id;p.spacing[slot]=id;p.slotByPiece[id]=slot;p[id]={15,25,35}
            end
        end
        archProject(letters,p)
        local rows=count>20 and 2 or 1
        local firstCount=math.ceil(count/rows)
        local radius=firstCount>1 and firstCount*sizeSpacingLetter/math.pi or 0
        local previous={}
        for _,id in ipairs(letters) do
            local slot=p.slotByPiece[id]-1
            local row=slot>=firstCount and 1 or 0
            local rowCount=row==0 and firstCount or count-firstCount
            local base=35+(rows-1-row)*(radius+sizeDownLetter*1.25)
            local y,z=positions[id][2]-(25-radius),positions[id][3]-base
            near(positions[id][1],15)
            near(y*y+z*z,radius*radius)
            for axis=1,3 do near(angles[id][axis],0) end
            if radius>0 then
                local theta=math.atan2(z,y)
                if previous[row] then
                    local last=previous[row]
                    near((theta-last.angle)/(slot-last.slot),math.pi/rowCount)
                end
                previous[row]={angle=theta,slot=slot}
            else
                near(positions[id][2],25);near(positions[id][3],35)
            end
        end
        if rows==2 then
            local lowerTop,upperBottom=-math.huge,math.huge
            for _,id in ipairs(letters) do
                if p.slotByPiece[id]<=firstCount then upperBottom=math.min(upperBottom,positions[id][3])
                else lowerTop=math.max(lowerTop,positions[id][3]) end
            end
            assert(upperBottom-lowerTop>=sizeDownLetter*1.25,'arches overlap vertically')
        end
    end
end
-- A cube has four vertical faces, with outward normals and constant row
-- height. Check both wrap counts, short phrases, gaps and long phrases.
for _,count in ipairs({1,2,4,5,10,20,21,24,40,81}) do
    for _,sparse in ipairs({false,true}) do
        local letters,p={}, {spacing={},slotByPiece={},slotPositions={{15,25,35}}}
        for slot=1,count do
            local id=200+slot
            p.spacing[slot]=' '
            if not sparse or slot%3~=0 then
                letters[#letters+1]=id;p.spacing[slot]=id;p.slotByPiece[id]=slot;p[id]={15,25,35}
            end
        end
        sleeps={};cubeProject(letters,p)
        assert(#sleeps==1 and sleeps[1]==35000,'cube hold changed')
        local rows=count>20 and 2 or 1
        local firstCount=math.ceil(count/rows)
        local half=math.ceil(firstCount/4)*sizeSpacingLetter/2
        local faces,previous,seen={},{},{}
        for _,id in ipairs(letters) do
            local slot=p.slotByPiece[id]-1
            local row=slot>=firstCount and 1 or 0
            local x,y,z=positions[id][1]-15,positions[id][2]-25,positions[id][3]-35
            near(math.max(math.abs(x),math.abs(y)),half)
            assert(math.min(math.abs(x),math.abs(y))<half,'glyph sits on corner')
            near(z,(rows-1-row)*sizeDownLetter*1.25)
            near(angles[id][1],0);near(angles[id][2],0)
            local yaw=angles[id][3]
            local wallAngle=yaw-math.pi
            local face=math.floor(-wallAngle/(math.pi/2)+0.5)
            assert(face>=0 and face<=3)
            near(yaw,-face*math.pi/2+math.pi)
            -- Requested 180-degree facing flip; wall positions stay unchanged.
            near(x*math.cos(yaw)+y*math.sin(yaw),-half)
            faces[row]=faces[row] or {};faces[row][face]=true
            local last=previous[row]
            if last then
                assert(face>=last.face,'phrase reverses around the cube')
                if face==last.face then
                    local dx,dy=x-last.x,y-last.y
                    assert(math.sqrt(dx*dx+dy*dy)>=sizeSpacingLetter-1e-7,'letters crowded on face')
                    assert(dx*math.sin(wallAngle)-dy*math.cos(wallAngle)>0,'slot order changed')
                end
            end
            previous[row]={face=face,x=x,y=y}
            local key=string.format('%.6f,%.6f,%.6f',x,y,z)
            assert(not seen[key],'cube stacks two letters');seen[key]=true
        end
        if not sparse and count>=4 then
            for row=0,rows-1 do
                for face=0,3 do assert(faces[row][face],'cube omits a face') end
            end
        end
    end
end
-- DNA pairs share a height and opposite positions, with the requested
-- 180-degree glyph-facing flip relative to their radial placement.
-- The parent alone rotates around the exported model's true vertical axis.
for _,count in ipairs({1,2,3,10,11,24}) do
    for _,upright in ipairs({false,true}) do
        for _,speed in ipairs({0,math.rad(20),math.rad(-20)}) do
            local letters,p={}, {spacing={},slotByPiece={},slotPositions={{15,25,35}},
                boolUpright=upright,spinnerSpeed=speed~=0 and speed or nil}
            for i=1,count do
                local id=400+i
                letters[i]=id;p[id]={15,25,35}
                -- Deliberate gaps: pair actual glyphs rather than empty slots.
                p.spacing[#p.spacing+1]=' ';p.spacing[#p.spacing+1]=id
                p.slotByPiece[id]=#p.spacing
            end
            spinEvents={};sleeps={}
            local expectedSpeed=speed~=0 and speed or math.rad(20)
            sleepObserver=function(ms)
                assert(ms==15000)
                near(spinSpeeds[textSpinner][3],expectedSpeed)
                assert(not spinSpeeds[textSpinner][1] and not spinSpeeds[textSpinner][2],
                    'parent rotation tips staircase over')
            end
            dnaHelix(letters,p)
            sleepObserver=nil
            assert(#sleeps==1 and #spinEvents==1)
            assert(spinEvents[1][1]==textSpinner and spinEvents[1][2]==3,
                'DNA spins individual glyphs instead of the whole staircase')
            if speed==0 then
                assert(not spinSpeeds[textSpinner][3],'default spin leaks into next effect')
                near(angles[textSpinner][3],0)
            else near(spinSpeeds[textSpinner][3],speed) end
            local radius=7*sizeSpacingLetter/(2*math.pi)
            for i,id in ipairs(letters) do
                local x,y,z=positions[id][1]-15,positions[id][2]-25,positions[id][3]-35
                local step=math.floor((i-1)/2)
                near(z,step*sizeDownLetter)
                near(x*x+y*y,radius*radius)
                near(angles[id][1],0);near(angles[id][2],0)
                local theta=angles[id][3]
                near(x*math.cos(theta)+y*math.sin(theta),-radius)
                if i%2==0 then
                    local partner=letters[i-1]
                    near(x+positions[partner][1]-15,0)
                    near(y+positions[partner][2]-25,0)
                    near(positions[id][3],positions[partner][3])
                    near(theta-angles[partner][3],math.pi)
                elseif i>1 then
                    near(theta-angles[letters[i-2]][3],math.pi/7)
                end
            end
        end
    end
end
spinEvents={};sleeps={};dnaHelix({},pos)
assert(#spinEvents==0 and #sleeps==0,'empty DNA changes parent state')
-- Spiral must always reproduce the first, approved vertical version,
-- regardless of the initial layout flag or production header aliases.
for _,upright in ipairs({false,true}) do
    pos.boolUpright=upright
    spiralProject(ids,pos)
    local radius=7*sizeSpacingLetter/(2*math.pi)
    for _,id in ipairs(ids) do
        local slot=pos.slotByPiece[id]-1
        near(positions[id][1],radius*math.cos(slot*math.pi/7))
        near(positions[id][2],radius*math.sin(slot*math.pi/7))
        near(positions[id][3],slot*sizeDownLetter)
        near(angles[id][3],math.pi-slot*math.pi/7)
        near(angles[id][1],0);near(angles[id][2],0)
    end
end
-- A cone grows in radius with height, orbits its glyphs continuously, then
-- restores the phrase and the caller's chosen spin (including no spin).
for _,speed in ipairs({0,0.3,-0.3}) do
    for _,upright in ipairs({false,true}) do
        local letters,p={}, {spacing={},slotByPiece={},slotPositions={{15,25,35}},
            boolUpright=upright,spinnerSpeed=speed~=0 and speed or nil}
        for slot=1,17 do
            local id=600+slot
            p.spacing[slot]=' '
            if slot%3~=0 then
                letters[#letters+1]=id;p.spacing[slot]=id;p.slotByPiece[id]=slot
                p[id]={15,25-(slot-1)*sizeSpacingLetter,35}
            end
        end
        local sawCone,hold,ticks=false,0,0
        sleepObserver=function(ms)
            if ms==34 then return end
            if ms==33 then
                sawCone=true;ticks=ticks+1
                assert(not spinSpeeds[textSpinner][3],'parent must stay still during local orbit')
                local lastRadius=0
                for _,id in ipairs(letters) do
                    local x,y,z=positions[id][1]-15,positions[id][2]-25,positions[id][3]-35
                    local radius=math.sqrt(x*x+y*y)
                    near(radius,sizeSpacingLetter*1.5+z*0.35)
                    assert(radius>lastRadius,'cone does not widen upward');lastRadius=radius
                    local theta=(p.slotByPiece[id]-1)*math.pi/4+(speed<0 and -1 or 1)*math.rad(60)*ticks/30
                    near(x,radius*math.cos(theta));near(y,radius*math.sin(theta))
                    near(angles[id][3],theta+math.pi)
                    near(angles[id][1],0);near(angles[id][2],0)
                end
            else
                assert(ms==500 and sawCone);hold=hold+ms
                assert(not spinSpeeds[textSpinner][3],'tornado keeps whirling during phrase hold')
                for _,id in ipairs(letters) do
                    for axis=1,3 do near(positions[id][axis],p[id][axis]);near(angles[id][axis],0) end
                end
            end
        end
        letterTornado(letters,p);sleepObserver=nil
        assert(sawCone and ticks==450 and hold==3000)
        if speed==0 then assert(not spinSpeeds[textSpinner][3]) else near(spinSpeeds[textSpinner][3],speed) end
    end
end
-- A moving pressure wave affects a small neighbouring group, changes only
-- depth and leaves each slot back at the same straight baseline.
local waveLetters,wavePos={}, {spacing={},slotByPiece={},slotPositions={{15,25,35}},spinnerSpeed=-0.2}
for slot=1,9 do
    local id=700+slot
    wavePos.spacing[slot]=' '
    if slot~=5 then
        waveLetters[#waveLetters+1]=id;wavePos.spacing[slot]=id;wavePos.slotByPiece[id]=slot
        wavePos[id]={15,25-(slot-1)*sizeSpacingLetter,35}
    end
end
local tick,peaks,groupSeen=0,{},false
sleepObserver=function(ms)
    if ms==100 then
        tick=tick+1
        local pushed=0
        for _,id in ipairs(waveLetters) do
            near(positions[id][2],wavePos[id][2]);near(positions[id][3],35)
            local offset=positions[id][1]-15
            assert(offset>=-1e-7 and offset<=sizeSpacingLetter*0.75+1e-7)
            if offset>1e-6 then pushed=pushed+1 end
            if not peaks[id] or offset>peaks[id].value then peaks[id]={value=offset,tick=tick} end
            for axis=1,3 do near(angles[id][axis],0) end
        end
        assert(pushed<=4,'wave moves the entire phrase at once')
        groupSeen=groupSeen or pushed>=2
    else
        assert(ms==500)
        for _,id in ipairs(waveLetters) do near(positions[id][1],15) end
    end
end
syncToFrontLetters(waveLetters,wavePos);sleepObserver=nil
assert(groupSeen);near(spinSpeeds[textSpinner][3],-0.2)
local previousTick=0
for _,id in ipairs(waveLetters) do
    near(peaks[id].value,sizeSpacingLetter*0.75)
    assert(peaks[id].tick>previousTick,'wave does not travel along phrase')
    previousTick=peaks[id].tick
end
-- Heart monitor is a separate vertical ECG pulse; the push wave still
-- changes depth only. Both beats must pass every slot and return to baseline.
local beat,beatTick=1,0
local beatPeaks,beatDips={{},{}},{{},{}}
sleepObserver=function(ms)
    if ms==75 then
        beatTick=beatTick+1
        for _,id in ipairs(waveLetters) do
            near(positions[id][1],15);near(positions[id][2],wavePos[id][2])
            local displacement=positions[id][3]-35
            if not beatPeaks[beat][id] or displacement>beatPeaks[beat][id].value then
                beatPeaks[beat][id]={value=displacement,tick=beatTick}
            end
            beatDips[beat][id]=math.min(beatDips[beat][id] or 0,displacement)
            for axis=1,3 do near(angles[id][axis],0) end
        end
    else
        for _,id in ipairs(waveLetters) do near(positions[id][3],35) end
        if ms==600 then beat,beatTick=2,0 else assert(ms==500 and beat==2) end
    end
end
heartMonitor(waveLetters,wavePos);sleepObserver=nil
for b=1,2 do
    local lastPeak=0
    for _,id in ipairs(waveLetters) do
        assert(beatPeaks[b][id].value>sizeDownLetter and beatDips[b][id]<-sizeDownLetter*0.15)
        assert(beatPeaks[b][id].tick>lastPeak,'ECG pulse does not travel left to right')
        lastPeak=beatPeaks[b][id].tick
    end
end
near(spinSpeeds[textSpinner][3],-0.2)
-- Matrix uses the exact console-roll path, but three times, faster and down
-- engine component 3; ordinary console timing and layout are unchanged.
pos.boolUpright=false;moves={};sleeps={};waits={}
consoleLetters(ids,pos)
assert(#sleeps==2 and sleeps[1]==100 and sleeps[2]==10000)
for _,m in ipairs(moves) do if m[4]>0 then assert(m[4]==150);near(m[3],pos[m[1]][m[2]]) end end
pos.boolUpright=true;moves={};sleeps={};waits={}
assert(canProjectTextFx('matrixTextFx',pos),'matrix cannot be selected for upright signs')
matrixTextFx(ids,pos)
assert(#sleeps==6 and #waits==3*3*#ids)
for i=1,6,2 do assert(sleeps[i]==100 and sleeps[i+1]==150) end
for _,m in ipairs(moves) do
    if m[4]>0 then
        assert(m[4]==1200)
        local expected=pos.slotPositions[1][m[2]]
        if m[2]==3 then expected=expected-(pos.slotByPiece[m[1]]-1)*sizeDownLetter end
        near(m[3],expected)
    end
end
pos.boolUpright=false;sleeps={};matrixTextFx(ids,pos);assert(#sleeps==0)
assert(not canProjectTextFx('matrixTextFx',pos),'matrix selected for horizontal layout')
-- Smile has exactly two eyes above a U-shaped mouth, with no outline/nose.
-- A tiny phrase borrows spare meshes and returns every borrowed piece hidden.
for _,count in ipairs({1,5,11}) do
    local letters,p={}, {spacing={},slotByPiece={},slotPositions={{15,25,35}}}
    local groups={A={901,902,903,904,905}}
    for slot=1,count do
        local id=900+slot
        letters[slot]=id;p.spacing[slot]=id;p.slotByPiece[id]=slot;p[id]={15,25-(slot-1)*321,35}
    end
    visible={};local sawFace=false
    sleepObserver=function(ms)
        assert(ms==7000);sawFace=true
        local total=math.max(5,count)
        local radius=math.max(sizeSpacingLetter*1.5,(total-3)*sizeSpacingLetter/math.pi)
        local eyes=0
        for id in pairs(visible) do
            near(positions[id][1],15)
            if positions[id][3]>35+radius then eyes=eyes+1
            else
                local y,z=positions[id][2]-25,positions[id][3]-(35+radius)
                near(y*y+z*z,radius*radius)
                assert(z<=1e-7,'mouth bends into a frown')
            end
            for axis=1,3 do near(angles[id][axis],0) end
        end
        assert(eyes==2)
        near(positions[901][2]-25,-(positions[902][2]-25))
    end
    smilingFace(letters,p,groups);sleepObserver=nil
    assert(sawFace)
    for id=900+count+1,905 do assert(not visible[id],'borrowed face glyph left visible') end
    for _,id in ipairs(letters) do for axis=1,3 do near(positions[id][axis],p[id][axis]) end end
end
-- Crossword: CAT and TAR intersect at their middle A, drawn once, with
-- four arms, upright glyphs and no random scattering. Also check fallbacks.
for _,phrase in ipairs({'CAT TAR','ABC DEF','A','A A'}) do
    local slots,leases=allocateHologramSlots(phrase,{A={801,802},B={803},C={804},D={805},E={806},F={807},T={808,809},R={810}})
    local letters,p={}, {spacing=slots,leases=leases,slotByPiece={},slotPositions={},myMessage=phrase}
    for slot,id in ipairs(slots) do
        p.slotPositions[slot]={0,-(slot-1)*sizeSpacingLetter,0}
        if id~=' ' then letters[#letters+1]=id;p[id]=p.slotPositions[slot];p.slotByPiece[id]=slot end
    end
    visible={};local hold=0
    sleepObserver=function(ms)
        assert(ms==500);hold=hold+ms
        if phrase=='CAT TAR' then
            assert(visible[801] and not visible[802],'intersection duplicates the shared A')
            near(positions[801][2],0);near(positions[801][3],sizeDownLetter)
            near(positions[804][2],sizeSpacingLetter);near(positions[808][2],-sizeSpacingLetter)
            near(positions[809][3],2*sizeDownLetter);near(positions[810][3],0)
            for id in pairs(visible) do for axis=1,3 do near(angles[id][axis],0) end end
        end
    end
    CrossLetters(letters,p);sleepObserver=nil
    assert(hold==7000)
    for _,id in ipairs(letters) do for axis=1,3 do near(positions[id][axis],p[id][axis]) end end
end
-- Fireworks terrain contact and grouped world-space animation have their
-- own production-matrix regression in hologram_fireworks_test.lua.
print('hologram projections with production axis aliases: PASS')
