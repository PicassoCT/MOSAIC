-- Editable behind-glass placeholder for the rigid-armed Tiglil rig.
-- Authored axes: X sideways, Y up, Z forward; angles: pitch/yaw/roll.
-- The imaginary pane is 4.2 body units forward of the resting body centre.
-- With zero arm pitch, shoulder yaw fixes palm depth while roll slides the
-- hand up/down the pane. Small torso rolls preserve that depth too. The rig
-- has no wrist joint, so palm orientation is only an approximation.
local paneDepth=-4.2
local shoulderDepth=-.45105
local palmLength,palmDepth=5.1,-.2
local yaw=math.deg(math.asin((paneDepth-shoulderDepth)/
    math.sqrt(palmLength^2+palmDepth^2))-math.atan(palmDepth/palmLength))

local function held(cue,lean,leftReach,rightReach,head)
    return {
        cue=cue,
        body={0,0,lean},
        left={-4,0,-3,8},right={-4,0,3,8},
        arms={{0,yaw,leftReach},{0,-yaw,rightReach}},
        head=head or {0,0,-lean*.5},travel={0,0},
        beats=3,hold=.5, -- 1.5-second transition, 1.5-second hold.
    }
end

return {beat=1000,headings={0},frames={
    held('hands against pane',0,-12,12),
    held('slide hands upward',0,-55,55,{-4,0,0}),
    held('left shoulder stretch',-3,-60,20,{0,-20,3}),
    held('left held silhouette',-3,-35,12,{0,-30,3}),
    held('centred stretch',0,-45,45,{-3,0,0}),
    held('right shoulder stretch',3,-20,60,{0,20,-3}),
    held('right held silhouette',3,-12,35,{0,30,-3}),
    held('settle at pane',0,-12,12),
}}
