-- Civilian rigs are Z-up beneath their baked root transform. Script Y lowers
-- shoulders; script Z swings them forward. Calibrate each model's A/T bind pose.
local M = {}
local names = {'Head1','UpBody','UpArm1','UpArm2','LowArm1','LowArm2'}
local armPieces = {'UpArm1','UpArm2','LowArm1','LowArm2','Hand1','Hand2'}
local profiles = {
    {name='relaxed', drop=78, shoulder=0, forward=3, elbow=-12, fold=0},
    {name='crossed_arms', drop=85, shoulder=-35, forward=5, elbow=-20, fold=95, stagger=true},
    {name='hands_on_hips', drop=42, shoulder=0, forward=0, elbow=0, fold=105},
    {name='one_hand_on_hip', drop=78, shoulder=0, forward=3, elbow=-12, fold=0, oneHip=true},
    {name='hands_clasped', drop=72, shoulder=-8, forward=20, elbow=-12, fold=55},
}
M.profiles = profiles

function M.calibrate(Spring, unitID)
    local map = Spring.GetUnitPieceMap(unitID)
    local result = {axisSigns={}}
    for side=1,2 do
        local info = map['LowArm'..side] and Spring.GetUnitPieceInfo(unitID,map['LowArm'..side])
        local offset = info and info.offset
        result[side] = offset and math.deg(math.atan2(-offset[3],math.abs(offset[1]))) or 45
    end
    -- Some imported limbs have a reflected local Y basis (civilian_arab4).
    -- Read bind matrices before Create starts animating, relative to the torso.
    -- Rotations are axial vectors: reflecting Y reverses X/Z rotation signs.
    if Spring.GetUnitPieceMatrix and map.UpBody then
        local body = {Spring.GetUnitPieceMatrix(unitID,map.UpBody)}
        if #body==16 then
            for _,name in ipairs(armPieces) do
                local matrix = map[name] and {Spring.GetUnitPieceMatrix(unitID,map[name])}
                if matrix and #matrix==16 then
                    local basis = {}
                    for axis=1,3 do
                        local first=(axis-1)*4+1
                        local dot=0
                        for i=first,first+2 do dot=dot+matrix[i]*body[i] end
                        basis[axis]=dot<0 and -1 or 1
                    end
                    result.axisSigns[name]={basis[2]*basis[3],basis[1]*basis[3],basis[1]*basis[2]}
                end
            end
        end
    end
    return result
end

function M.correctAnimationAxes(animations, calibration)
    -- Source Y/Z will be swapped by setupAnimation; convert signs likewise.
    local sourceAxes = {[x_axis]=1,[y_axis]=3,[z_axis]=2}
    for _,clip in pairs(animations) do
        for _,frame in ipairs(clip) do
            for _,cmd in ipairs(frame.commands) do
                local signs = calibration.axisSigns and calibration.axisSigns[cmd.p]
                if cmd.c=='turn' and signs and signs[sourceAxes[cmd.a]]==-1 then
                    cmd.t=-cmd.t
                    if cmd.rl or cmd.ru then cmd.rl,cmd.ru=-(cmd.ru or .01),-(cmd.rl or 0) end
                end
            end
        end
    end
end

function M.conversationRest(calibration)
    -- Source keyframes swap Y/Z in setupAnimation: source Z becomes script Y.
    return {UpArm1={0,0,-(78-calibration[1])},UpArm2={0,0,78-calibration[2]}}
end

function M.apply(pieces, unitID, speed, turn, calibration, carrying)
    local profile = carrying and profiles[1] or profiles[(unitID % #profiles)+1]
    local values = {Head1={0,0,0},UpBody={0,0,0}}
    for side=1,2 do
        local sign = side==1 and -1 or 1
        local arm = profile.oneHip and side==2 and profiles[3] or profile
        values['UpArm'..side]={arm.shoulder,sign*(arm.drop-calibration[side]),-sign*arm.forward}
        values['LowArm'..side]={arm.elbow+(arm.stagger and sign*8 or 0),sign*arm.fold,0}
    end
    local axes = {pieces.x_axis,pieces.y_axis,pieces.z_axis}
    for _, name in ipairs(names) do
        if pieces[name] then
            for axis, degrees in ipairs(values[name]) do
                local signs = calibration.axisSigns and calibration.axisSigns[name]
                turn(pieces[name], axes[axis], math.rad(degrees)*(signs and signs[axis] or 1), speed or 3)
            end
        end
    end
    return profile.name
end
return M
