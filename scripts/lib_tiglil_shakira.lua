-- Shakira-inspired solo vocabulary, adapted to a single rigid torso and arms.
-- Knee changes and small root arcs suggest hip isolation; head counter-rotation
-- keeps the gaze steady. No elbow, waist or wrist joints are assumed.
local style={beat=400,headings={0},frames={}}
local function add(cue,body,leftKnee,rightKnee,arms,travel,beats,hold)
    style.frames[#style.frames+1]={cue=cue,body=body,
        left={-leftKnee*.5,0,-4,leftKnee},right={-rightKnee*.5,0,4,rightKnee},
        arms=arms,travel=travel or {0,0},beats=beats or 1,hold=hold or 0,
        head={-body[1]*.7,-body[2]*.8,-body[3]*.8}}
end
local open={{0,-18,12},{0,18,-12}}
local crown={{0,-15,-65},{0,15,65}}

-- Alternating weight accents with enough time to read each silhouette.
for i=1,8 do
    local s=i%2==1 and 1 or -1
    add('hip isolation',{0,-5*s,-4*s},16-6*s,16+6*s,open,{.3*s,0},1.25,.2)
end
-- Two small horizontal figure-eights, with knee-driven weight changes.
for i=1,16 do
    local phase=i*math.pi/4
    local side,depth=math.sin(phase),math.sin(phase*2)
    add('figure eight',{0,7*depth,-3*side},14-4*side,14+4*side,
        crown,{.4*side,.12*depth},.65)
end
-- Short, shallow knee alternations read as a shimmy without tipping the body.
for i=1,16 do
    local s=i%2==1 and 1 or -1
    add('shimmy',{0,2*s,-1.5*s},12-3*s,12+3*s,open,nil,.4)
end
local wave={{-5,8},{0,14},{7,24},{4,28},{-3,16},{0,10}}
for _,p in ipairs(wave)do
    add('torso wave',{p[1],0,0},p[2],p[2],{{0,-35,25},{0,35,-25}},nil,1.5)
end
-- Raise the rigid arms in a continuous shoulder arc, then hold the finish.
for i=1,8 do
    local u=i/8
    local s=math.sin(u*math.pi*2)
    add('overhead sweep',{0,5*s,-2*s},12-3*s,12+3*s,
        {{0,-18,12-77*u},{0,18,-12+77*u}},nil,1,i==8 and .35 or 0)
end
return style
