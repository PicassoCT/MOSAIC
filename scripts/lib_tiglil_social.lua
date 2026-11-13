-- Short, non-contact projection performances addressed to one pedestrian.
-- Embrace/kiss silhouettes are approximate on a rigid-arm, fixed-face rig.
local relaxed={{0,-8,62},{0,8,-62}}
local open={{0,-35,8},{0,35,-8}}
local function p(cue,body,arms,head,travel,hold,left,right)
    return {cue=cue,body=body or {0,0,0},arms=arms or relaxed,head=head or {0,0,0},
        travel=travel or {0,0},hold=hold or 0,beats=1,
        left=left or {-4,0,-3,8},right=right or {-4,0,3,8}}
end
return {
    greeting={beat=700,headings={0},frames={
        p('notice pedestrian',{0,-5,0},relaxed,{0,5,0}),
        p('wave hello',{0,0,-2},{{0,-15,-45},{0,12,-55}},{-3,0,0}),
        p('open welcome',{0,0,0},open),
        p('dance step left',{2,-8,-3},{{0,-35,35},{0,25,-50}},{0,8,0},{.55,0},0,{-5,0,-3,10},{-18,0,3,30}),
        p('gather step',{0,0,0},open),
        p('dance step right',{2,8,3},{{0,-25,50},{0,35,-35}},{0,-8,0},{-.55,0},0,{-18,0,-3,30},{-5,0,3,10}),
        p('overhead flourish',{-3,0,0},{{0,-15,-60},{0,15,60}}),
        p('open flourish',{0,0,0},open,nil,nil,.3),
        p('friendly bow',{8,0,0},{{0,-25,40},{0,25,-40}},{-3,0,0}),
        p('farewell wave',{0,0,0},{{0,-15,-35},{0,12,-55}}),
        p('greeting finish'),
    }},
    embrace={beat=800,headings={0},distance=4.8,frames={
        p('offer embrace',{0,0,0},open,nil,nil,.25),
        p('approach embrace',{3,0,0},{{0,-50,5},{0,50,-5}},{0,0,5},{0,-.2}),
        p('close embrace',{5,0,0},{{0,-70,5},{0,70,-5}},{-3,8,8},{0,-.4}),
        p('hold embrace',{5,0,0},{{0,-70,5},{0,70,-5}},{-3,8,8},{0,-.4},.5),
        p('gentle embrace sway',{4,0,2},{{0,-68,5},{0,68,-5}},{-2,6,6},{.12,-.4}),
        p('release embrace',{2,0,0},open,{0,0,0},{0,-.2}),
        p('step back',{0,0,0},open),
        p('warm nod',{0,0,0},relaxed,{5,0,0}),
        p('embrace finish'),
    }},
    kiss={beat=700,headings={0},distance=2.8,frames={
        p('greet closely',{0,0,0},open,{0,5,4},nil,.2),
        p('incline toward cheek',{6,0,0},{{0,-35,45},{0,35,-45}},{3,8,8},{.15,-.15}),
        p('cheek kiss gesture',{12,0,0},{{0,-45,40},{0,25,-50}},{6,12,12},{.25,-.3}),
        p('brief cheek hold',{12,0,0},{{0,-45,40},{0,25,-50}},{6,12,12},{.25,-.3},.55),
        p('withdraw from cheek',{4,0,0},open,{0,6,4},{.1,-.1}),
        p('meet gaze',{0,0,0},relaxed,{0,0,0},nil,.3),
        p('small farewell',{0,0,-2},{{0,-15,-25},{0,15,-55}},{-2,0,0}),
        p('kiss finish'),
    }},
    invitation={beat=800,headings={0},frames={
        p('catch attention',{0,-8,-2},relaxed,{0,8,4},nil,.3),
        p('inviting wave',{0,0,-3},{{0,-25,-20},{0,15,-55}},{-3,0,4}),
        p('beckon outward',{2,0,0},{{0,-70,10},{0,20,-55}},{0,0,0}),
        p('beckon inward',{-2,0,-2},{{0,-25,40},{0,15,-55}},{-4,0,4}),
        p('slow sway left',{0,-10,-4},{{0,-15,-45},{0,20,-55}},{0,10,0},{.45,0},0,{-6,0,-4,12},{-12,0,3,24}),
        p('slow sway right',{0,10,4},{{0,-20,55},{0,15,45}},{0,-10,0},{-.45,0},0,{-12,0,-3,24},{-6,0,4,12}),
        p('open invitation',{-3,0,0},open,{0,0,0},nil,.3),
        p('turn with glance',{0,35,-2},{{0,-20,50},{0,25,-20}},{0,-35,5}),
        p('step aside',{0,35,-2},{{0,-20,50},{0,25,0}},{0,-35,5},{.65,.35}),
        p('hold invitation',{0,35,-2},{{0,-20,50},{0,25,0}},{0,-35,5},{.65,.35},.5),
        p('return to mark',{0,0,0},open),
        p('parting glance',{0,-8,-2},relaxed,{0,8,5},nil,.3),
        p('invitation finish'),
    }},
}
