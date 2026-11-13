-- Solo choreography in Journeywar body units: X sideways, Y up, Z forward.
-- Rotations are authored pitch/yaw/roll; the caller maps them to the DAE axes.
local M={}
local function pose(body,left,right,arms,travel,beats,hold)
    return {body=body,left=left,right=right,arms=arms,travel=travel or {0,0},beats=beats or 1,hold=hold or 0}
end
-- Leg tuples: hip pitch, yaw, roll, knee bend. Arms are rigid shoulder-to-hand
-- pieces: use open silhouettes instead of pretending the rig has elbows.
M.styles={
    -- Adapted from the overhead reach, arm sweeps, hip rocks and turning steps
    -- in the source linked by the user's Reddit post: youtube.com/watch?v=6Ov9EL709cc.
    -- Tiglil has no elbow joints: shoulder arcs preserve the silhouette.
    joi={beat=360,turnBeats=8,headings={0,90,180,270},frames={
        pose({-3,-8,-5},{-6,0,-5,12},{-12,0,4,24},{{0,-20,55},{-8,12,80}},{.5,0}),
        pose({-2,0,4},{-12,0,-4,24},{-6,0,5,12},{{-8,-12,-40},{0,12,65}},{-.5,0}),
        pose({-3,8,5},{-12,0,-4,24},{-6,0,5,12},{{-8,-12,-80},{0,20,-55}},{-.5,0}),
        pose({2,-8,-4},{-6,0,-5,12},{-12,0,4,24},{{0,-25,-45},{8,40,-40}},{.5,0}),
        pose({4,-15,-6},{-10,0,-7,20},{-6,0,3,12},{{10,-30,50},{-5,30,-45}},{.65,-.15}),
        pose({0,10,6},{-6,0,-3,12},{-10,0,7,20},{{-5,-40,45},{10,30,-50}},{-.65,.15}),
        pose({7,15,2},{-18,0,-4,36},{-18,0,4,36},{{0,-65,10},{0,65,-10}},{0,-.2}),
        pose({-3,5,-3},{-7,0,-4,14},{-9,0,4,18},{{-8,-45,25},{-8,45,-25}},{.3,0}),
        pose({3,-12,-5},{-8,0,-5,16},{-12,0,3,24},{{0,-78,0},{0,78,0}},{.5,-.25}),
        pose({-2,12,5},{-12,0,-3,24},{-8,0,5,16},{{8,-35,48},{8,35,-48}},{-.5,.25}),
        pose({3,18,5},{-10,-8,-3,20},{-6,8,5,12},{{0,-60,20},{-8,25,-35}},{-.55,-.1}),
        pose({0,-18,-5},{-6,-8,-5,12},{-10,8,3,20},{{-8,-25,35},{0,60,-20}},{.55,.1}),
        pose({5,-10,-4},{-14,0,-5,28},{-7,0,3,14},{{8,-45,50},{0,40,-35}},{.4,-.2}),
        pose({-2,10,4},{-7,0,-3,14},{-14,0,5,28},{{0,-40,35},{8,45,-50}},{-.4,.2}),
        pose({1,8,3},{-8,0,-3,16},{-8,0,3,16},{{-8,-20,-20},{-8,20,20}},{-.3,0}),
        pose({-2,-8,-3},{-6,0,-4,12},{-10,0,4,20},{{0,-20,45},{-8,12,65}},{.3,0}),
    }},

    solo={beat=420,headings={30,-30,60,-60,30,0},frames={
        pose({3,-8,-3},{-24,0,-4,32},{12,0,2,12},{{-12,-35,35},{8,25,-58}},{.35,-1},2),
        pose({1,4,2},{-8,0,-2,12},{-18,0,4,30},{{8,-20,58},{-12,35,-35}},{-.25,-.4}),
        pose({2,10,3},{15,0,-3,18},{-28,0,3,36},{{10,-25,52},{-18,40,-25}},{-.4,1},2),
        pose({0,-4,-2},{-18,0,-3,28},{-6,0,2,12},{{-12,-40,25},{8,25,-52}},{.3,.4}),
        pose({3,-12,-4},{-8,-12,-10,18},{-4,6,5,10},{{-8,-25,20},{10,20,-50}},{.65,0}),
        pose({2,12,4},{-4,-6,-5,10},{-8,12,10,18},{{10,-20,50},{-8,25,-20}},{-.65,0}),
        pose({5,0,-2},{-18,8,-3,28},{-8,-8,3,16},{{0,-45,25},{0,45,-25}},{0,-.2}),
        pose({0,0,0},{-5,0,0,10},{-5,0,0,10},{{0,-15,58},{0,15,-58}},{0,0}),
    }},
    shuffle={beat=300,headings={15,-15,15,0},frames={
        pose({5,-6,-3},{-35,0,-3,65},{15,0,2,8},{{-10,-25,55},{15,25,-55}},{.25,-.4}),
        pose({3,0,1},{-22,0,-2,12},{12,0,2,18},{{12,-25,55},{-10,25,-55}},{0,.3}),
        pose({5,6,3},{15,0,-2,8},{-35,0,3,65},{{15,-25,55},{-10,25,-55}},{-.25,-.4}),
        pose({3,0,-1},{12,0,-2,18},{-22,0,2,12},{{-10,-25,55},{12,25,-55}},{0,.3}),
        pose({4,-12,-3},{-18,-20,-10,22},{5,12,5,12},{{-12,-35,45},{15,25,-55}},{.55,0}),
        pose({3,6,2},{-10,16,4,18},{-6,-12,-3,14},{{10,-20,58},{-12,35,-45}},{.1,0}),
        pose({4,12,3},{5,-12,-5,12},{-18,20,10,22},{{15,-25,55},{-12,35,-45}},{-.55,0}),
        pose({3,-6,-2},{-6,12,3,14},{-10,-16,-4,18},{{-12,-35,45},{10,20,-58}},{-.1,0}),
    }},
    disco={beat=400,headings={0,20,-20,0},frames={
        pose({-2,-12,-5},{-8,0,-8,16},{-4,0,3,8},{{0,-20,-55},{10,25,-65}},{.65,0}),
        pose({4,8,4},{-4,0,-3,8},{-12,0,8,24},{{15,-65,35},{0,20,-65}},{-.55,0}),
        pose({-2,-12,-5},{-8,0,-8,16},{-4,0,3,8},{{0,-20,-55},{10,25,-65}},{.65,0}),
        pose({4,8,4},{-4,0,-3,8},{-12,0,8,24},{{15,-65,35},{0,20,-65}},{-.55,0}),
        pose({-2,12,5},{-4,0,-3,8},{-8,0,8,16},{{10,-25,65},{0,20,55}},{-.65,0}),
        pose({4,-8,-4},{-12,0,-8,24},{-4,0,3,8},{{0,-20,65},{15,65,-35}},{.55,0}),
        pose({0,-10,-3},{-6,-12,-7,12},{-6,12,7,12},{{0,-20,0},{0,20,0}},{.35,0}),
        pose({0,10,3},{-6,12,-7,12},{-6,-12,7,12},{{0,-35,55},{0,35,-55}},{-.35,0}),
    }},
    popping={beat=420,headings={0,-25,25,0},frames={
        pose({-5,0,0},{-8,0,-4,16},{-8,0,4,16},{{0,-60,10},{0,60,-10}},{0,0},1,.55),
        pose({5,0,0},{-14,0,-4,28},{-14,0,4,28},{{15,-30,55},{15,30,-55}},{0,0},1,.55),
        pose({0,-18,-4},{-6,0,-8,12},{-10,0,3,20},{{-25,-30,0},{12,45,-55}},{.5,0},1,.55),
        pose({0,18,4},{-10,0,-3,20},{-6,0,8,12},{{12,-45,55},{-25,30,0}},{-.5,0},1,.55),
        pose({-4,-12,0},{-10,-15,-4,20},{-6,15,4,12},{{-20,-15,-30},{10,55,-30}},{0,-.2},1,.55),
        pose({4,12,0},{-6,15,-4,12},{-10,-15,4,20},{{10,-55,30},{-20,15,30}},{0,.2},1,.55),
        pose({0,-10,-5},{-12,0,-6,24},{-6,0,3,12},{{0,-60,20},{0,25,-60}},{.45,0},1,.55),
        pose({0,10,5},{-6,0,-3,12},{-12,0,6,24},{{0,-25,60},{0,60,-20}},{-.45,0},1,.55),
    }},
}

-- The three exported rigs share these hip/knee offsets and 35 unique lower-leg vertices.
-- Match body height to the lower foot at each pose, instead of the old -5-unit
-- bob which buried the supporting leg. No translations detach limb joints.
local legs={
    {hip={.5128,0,.1285},knee={.9676,.2649,-6.7023}},
    {hip={-.4438,.064,.1435},knee={-1.1117,.2009,-6.7174}},
}
local footVertices={
    {-0.43421,0.04449,0.00866},
    {-0.37037,0.04789,-0.45919},
    {-0.2283,0.03649,0.18147},
    {-0.22697,0.66602,-3.58004},
    {-0.22345,0.75618,-3.62921},
    {-0.21659,0.12463,-2.93681},
    {-0.10026,0.48296,-4.48957},
    {-0.09766,0.54935,-4.52578},
    {-0.03261,-0.59056,0.00752},
    {-0.01229,-0.30509,0.18086},
    {-0.00881,-0.52384,-0.46021},
    {0.02496,0.32415,-5.24956},
    {0.02625,0.35724,-5.26761},
    {0.05956,-0.3789,-2.93771},
    {0.08246,-0.03104,-3.9457},
    {0.09498,0.66962,-4.12524},
    {0.09813,0.34934,0.19174},
    {0.12761,0.14938,-4.67845},
    {0.13682,0.48562,-4.89105},
    {0.13854,0.15787,-5.34371},
    {0.14313,0.32547,-5.44968},
    {0.17267,0.62612,0.02777},
    {0.17601,0.57153,-0.44198},
    {0.21784,0.03586,0.19861},
    {0.22234,0.58581,-2.92166},
    {0.25775,0.82134,-3.17241},
    {0.26518,0.28585,-5.23042},
    {0.26765,0.34804,-5.26633},
    {0.35652,0.12371,-2.91153},
    {0.37638,0.04685,-0.43049},
    {0.38167,0.40613,-4.45117},
    {0.38663,0.5309,-4.52321},
    {0.39523,0.04333,0.04054},
    {0.42747,0.31761,-3.63706},
    {0.43421,0.73112,-3.62572},
}
-- Shared rigid-leg geometry for grounded floor choreography.
M.legGeometry,M.footVertices=legs,footVertices
local function rotate(v,a)
    local x,y,z=math.rad(a[1]),math.rad(a[3]),math.rad(a[2])
    local cx,sx,cy,sy,cz,sz=math.cos(x),math.sin(x),math.cos(y),math.sin(y),math.cos(z),math.sin(z)
    local xx,yy=cz*v[1]-sz*v[2],sz*v[1]+cz*v[2]
    local zz=sx*yy+cx*v[3];yy=cx*yy-sx*v[3]
    return {cy*xx+sy*zz,yy,-sy*xx+cy*zz}
end
function M.height(p)
    local lowest=math.huge
    for side,angles in ipairs({p.left,p.right}) do
        local leg=legs[side]
        for _,point in ipairs(footVertices) do
            local v=rotate({point[1]*(side==1 and 1 or -1),point[2],point[3]},{angles[4],0,0})
            for k=1,3 do v[k]=v[k]+leg.knee[k] end
            v=rotate(v,angles)
            for k=1,3 do v[k]=v[k]+leg.hip[k] end
            v=rotate(v,p.body)
            lowest=math.min(lowest,v[3])
        end
    end
    return -12-lowest
end
local neutral=pose({0,0,0},{0,0,0,0},{0,0,0,0},{{0,0,68},{0,0,-68}})
function M.play(name,api)
    local style=assert(M.styles[name],'unknown solo dance: '..tostring(name))
    local sign=math.random(0,1)==0 and -1 or 1
    local function mirrored(a) return {a[1],a[2]*sign,a[3]*sign,a[4]} end
    local function perform(source,ms)
        local p={body=mirrored(source.body),travel={source.travel[1]*sign,source.travel[2]}}
        p.left=mirrored(sign==1 and source.left or source.right)
        p.right=mirrored(sign==1 and source.right or source.left)
        local arms={mirrored(source.arms[sign==1 and 1 or 2]),mirrored(source.arms[sign==1 and 2 or 1])}
        api.move('tigLil',{p.travel[1],M.height(p),p.travel[2]},ms)
        api.turn('tigLil',p.body,ms)
        api.turn('tlHead',{-p.body[1]*.65,-p.body[2]*.6,-p.body[3]*.5},ms)
        api.turn('tlhairup',{-65-p.body[1],-p.body[2]*.3,-p.body[3]*.5},ms)
        api.turn('tlhairdown',{-19-p.body[1]*.4,0,0},ms)
        api.turn('tlarm',arms[1],ms);api.turn('tlarmr',arms[2],ms)
        api.turn('tllegUp',p.left,ms);api.turn('tllegLow',{p.left[4],0,0},ms)
        api.turn('tllegUpR',p.right,ms);api.turn('tllegLowR',{p.right[4],0,0},ms)
    end
    api.turn('deathpivot',{0,0,0},600)
    api.turn('dancepivot',{0,0,0},600)
    perform(neutral,600);api.sleep(650)
    for _,heading in ipairs(style.headings) do
        api.turn('deathpivot',{0,heading*sign,0},style.beat*(style.turnBeats or 2))
        for _,p in ipairs(style.frames) do
            local duration=style.beat*p.beats
            perform(p,duration*(1-p.hold))
            api.sleep(duration)
        end
    end
    api.turn('deathpivot',{0,0,0},600)
    perform(neutral,600);api.sleep(650)
    api.finish()
end
return M
