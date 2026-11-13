-- Business-advertisement choreography. Registration is deliberately separate
-- from ordinary, casino, brothel and blimp animation pools.
-- Same authored axes/body units as lib_tiglil_dance; arms have no elbow joints.
local M={}
local relaxed={{0,-8,64},{0,8,-64}}
local open={{0,-20,12},{0,20,-12}}
local overhead={{0,-12,-55},{0,12,55}}
local standL,standR={-3,0,-2,6},{-3,0,2,6}
local function pose(cue,body,arms,head,travel,beats,hold,left,right)
    return {cue=cue,body=body or {0,0,0},arms=arms or relaxed,
        head=head or {0,0,0},travel=travel or {0,0},beats=beats or 1,
        hold=hold or 0,left=left or standL,right=right or standR}
end
M.sales={beat=800,headings={0},frames={
    pose('welcome',{0,0,0},open),
    pose('greet audience',{0,-6,-2},{{0,-12,-35},{0,15,-55}},{-4,6,0}),
    pose('look toward display',{0,-10,-2},relaxed,{0,-18,0}),
    pose('present display',{0,-12,-2},{{0,-25,0},{0,15,-58}},{0,-15,0},nil,1.25,.3),
    pose('explain feature',{2,-8,-1},{{0,-60,10},{0,20,-50}},{4,8,0}),
    pose('affirm feature',{0,-8,-1},{{0,-60,10},{0,20,-50}},{-3,8,0}),
    pose('unveil offer',{0,0,0},open,{0,0,0},nil,1.25,.3),
    pose('look toward second display',{0,10,2},relaxed,{0,18,0}),
    pose('present second display',{0,12,2},{{0,-15,58},{0,25,0}},{0,15,0},nil,1.25,.3),
    pose('explain second feature',{2,8,1},{{0,-20,50},{0,60,-10}},{4,-8,0}),
    pose('affirm second feature',{0,8,1},{{0,-20,50},{0,60,-10}},{-3,-8,0}),
    pose('invite audience',{3,0,0},{{0,-65,15},{0,65,-15}},{-2,0,0}),
    pose('open invitation',{0,0,0},open,{0,0,0},nil,1.25,.4),
    pose('thank audience',{8,0,0},{{0,-25,45},{0,25,-45}},{-3,0,0}),
    pose('ready for next offer',{0,0,0},relaxed),
}}

-- Two phases per small step: a lifted passing foot, then a straightened
-- placement. Translate with the stride rather than cycling legs on the spot.
local function walk(frames,z,heading,steps,direction,runway)
    for step=1,steps do
        local leftFirst=step%2==1
        local side=leftFirst and 1 or -1
        local passing=pose('passing step',{1,heading,side*(runway and 2 or 1)},
            {{-side*7,-8,64},{side*7,8,-64}},{0,0,0},{side*.12,z+direction},.55)
        local support={-2,0,0,4}
        local swing={-15,0,0,32}
        passing.left=leftFirst and swing or support
        passing.right=leftFirst and support or swing
        frames[#frames+1]=passing
        z=z+direction*2
        local lead,trail={-6,0,runway and side*2 or 0,4},{6,0,0,4}
        frames[#frames+1]=pose('place step',{0,heading,-side*(runway and 2 or 1)},
            {{side*6,-8,64},{-side*6,8,-64}},{0,0,0},{-side*.12,z},.55,0,
            leftFirst and lead or trail,leftFirst and trail or lead)
    end
    return z
end
local function add(frames,...)frames[#frames+1]=pose(...)end
local runway={pose('runway preparation')}
local z=walk(runway,0,0,4,-1,true)
add(runway,'front runway mark',{0,-12,-3},{{0,-10,60},{0,15,-48}},{0,12,0},{0,z},1.5,.5)
add(runway,'show left profile',{0,55,-2},{{0,-12,58},{0,12,-58}},{0,-30,0},{0,z},1.25,.25)
add(runway,'show right profile',{0,-55,2},{{0,-12,58},{0,12,-58}},{0,30,0},{0,z},1.25,.25)
add(runway,'return to front',{0,0,0},relaxed,{0,0,0},{0,z})
add(runway,'runway pivot half',{0,90,0},relaxed,{0,0,0},{0,z})
add(runway,'runway pivot finish',{0,180,0},relaxed,{0,0,0},{0,z})
z=walk(runway,z,180,4,1,true)
add(runway,'close runway walk',{0,180,0},relaxed,{0,0,0},{0,z})
add(runway,'face audience half',{0,90,0})
add(runway,'final model pose',{0,0,-3},{{0,-10,60},{0,15,-48}},{0,0,2},nil,1.5,.5)
add(runway,'runway finish')
M.runway={beat=750,headings={0},frames=runway}

local presenter={pose('presenter entrance')}
z=walk(presenter,0,0,2,-1,false)
add(presenter,'gala welcome',{0,0,0},open,{0,0,0},{0,z},1.25,.2)
add(presenter,'address audience',{2,-7,-1},{{0,-65,15},{0,20,-52}},{3,7,0},{0,z})
add(presenter,'speaking emphasis',{0,5,1},{{0,-50,5},{0,35,-30}},{-3,-5,0},{0,z})
add(presenter,'include far audience',{1,12,0},{{0,-20,52},{0,55,-10}},{2,10,0},{0,z})
add(presenter,'look toward guest',{0,-18,0},relaxed,{0,-20,0},{0,z})
add(presenter,'introduce guest',{0,-25,-2},{{0,-15,0},{0,20,-55}},{0,-15,0},{0,z},1.5,.4)
add(presenter,'return to audience',{0,0,0},open,{0,0,0},{0,z})
add(presenter,'closing remark',{2,6,0},{{0,-20,52},{0,65,-15}},{3,-6,0},{0,z})
add(presenter,'closing nod',{0,0,0},open,{-4,0,0},{0,z})
add(presenter,'thank guests',{7,0,0},relaxed,{-2,0,0},{0,z})
add(presenter,'leave stage half',{0,90,0},relaxed,{0,0,0},{0,z})
add(presenter,'leave stage turn',{0,180,0},relaxed,{0,0,0},{0,z})
z=walk(presenter,z,180,2,1,false)
add(presenter,'finish exit',{0,180,0},relaxed,{0,0,0},{0,z})
add(presenter,'reset heading half',{0,90,0})
add(presenter,'presenter finish')
M.presenter={beat=750,headings={0},frames=presenter}
return M
