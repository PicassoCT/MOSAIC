-- Tool poses calibrated against house_asian.dae's four actual arm chains.
-- y_axis is native Z (vertical) on this rig. Entries are base yaw, shoulder, elbow,
-- wrist (degrees); the seam samples follow the raw vehicle frame, not random
-- joint targets. See the external model/contact regression before re-exporting.
local profiles = {
    {
        park={89.6635,5.2337,-93.8857,0.0},
        approach={11.5619,50.3296,-133.6877,0.0},
        clearEnd={6.8421,-1.5725,-97.2324,0.0},
        seam={
            {11.562,48.6909,-149.138,0.0},
            {9.8604,29.478,-137.5962,0.0},
            {8.5952,14.1451,-126.6482,0.0},
            {7.6184,0.9662,-115.7137,0.0},
            {6.8421,-10.9882,-104.4382,0.0},
        },
    },
    {
        park={84.529,3.8867,-99.9604,0.0},
        approach={-170.7506,20.6086,-118.1559,0.0},
        clearEnd={-169.0862,30.4737,-127.7605,0.0},
        seam={
            {-170.3077,9.4151,-125.8994,0.0},
            {-169.9043,11.3612,-128.1821,0.0},
            {-169.4718,13.3507,-130.4663,0.0},
            {-169.0078,15.3913,-132.7561,0.0},
            {-168.5097,17.492,-135.056,0.0},
        },
    },
    {
        park={-90.3382,5.2364,-100.7287,0.0},
        approach={166.3445,22.1169,-120.0792,0.0},
        clearEnd={164.834,32.7329,-130.2436,0.0},
        seam={
            {166.3446,10.0722,-126.9504,0.0},
            {165.9954,12.1352,-129.3378,0.0},
            {165.6282,14.2525,-131.7332,0.0},
            {165.2416,16.4342,-134.1421,0.0},
            {164.8342,18.6924,-136.5706,0.0},
        },
    },
    {
        park={-90.3405,2.8162,-99.4441,0.0},
        approach={-13.7785,40.9126,-127.4618,0.0},
        clearEnd={-6.7589,-8.0437,-90.6535,0.0},
        seam={
            {-13.7784,36.5823,-141.3584,0.0},
            {-11.3081,20.4016,-130.7628,0.0},
            {-9.4267,6.6424,-120.1836,0.0},
            {-7.9489,-5.6681,-109.3052,0.0},
            {-6.7589,-17.1829,-97.8401,0.0},
        },
    },
}

local M = {}
function M.robotChain(base)
    assert(base, 'vehicle assembly: missing robot base')
    local map = Spring.GetUnitPieceMap(unitID)
    local chain = {base}
    for joint=2,6 do
        local info = Spring.GetUnitPieceInfo(unitID, chain[joint-1])
        assert(info and info.children and #info.children==1,
            'vehicle assembly: robot must have six joints in a single chain')
        local child = info.children[1]
        chain[joint] = assert(type(child)=='number' and child or map[child],
            'vehicle assembly: missing robot joint')
    end
    return chain
end

local allArms, workingPairs = {1,2,3,4}, {{1,4},{2,3}}
local function replacePose(p)
    -- Move/Turn with speed zero alone leave old native destinations queued.
    for axis=1,3 do
        StopSpin(p,axis,0)
        Move(p,axis,0,1);Turn(p,axis,0,1)
        Move(p,axis,0,0);Turn(p,axis,0,0)
    end
end

function M.run(set)
    local arms = {set.robot1T,set.robot2T,set.robot3T,set.robot4T}
    local endpoints = {1,1,1,1}
    local axes = {y_axis,x_axis,x_axis,x_axis}
    local function commandArm(i, pose, seconds)
        for joint=1,4 do
            local p,axis = arms[i][joint+1],axes[joint]
            local rotation = {Spring.UnitScript.GetPieceRotation(p)}
            local target = math.rad(pose[joint])
            local delta = (target-rotation[axis]+math.pi)%(2*math.pi)-math.pi
            Turn(p,axis,target,math.max(.01,math.abs(delta)/seconds))
        end
    end
    local function poseArms(ids, name, seconds, sample)
        for _,i in ipairs(ids) do
            local pose = profiles[i][name]
            commandArm(i,sample and pose[sample] or pose,seconds)
        end
        Sleep(seconds*1000)
        for _,i in ipairs(ids) do
            for joint=1,4 do WaitForTurn(arms[i][joint+1],axes[joint]) end
        end
    end
    local function clearTools(ids, seconds)
        for _,i in ipairs(ids) do
            commandArm(i,profiles[i][endpoints[i]==1 and 'approach' or 'clearEnd'],seconds)
        end
        Sleep(seconds*1000)
        for _,i in ipairs(ids) do
            for joint=1,4 do WaitForTurn(arms[i][joint+1],axes[joint]) end
        end
    end
    local function doors(angle)
        -- The two hinges face opposite ways. Both panels open upward.
        Turn(set.doors[1],x_axis,math.rad(-angle),.65)
        Turn(set.doors[2],x_axis,math.rad(angle),.65)
        for _,p in ipairs(set.doors) do WaitForTurn(p,x_axis) end
    end

    Hide(set.finalWorks)
    replacePose(set.finalWorks)
    for _,arm in ipairs(arms) do
        for _,p in ipairs(arm) do Show(p);replacePose(p) end
    end
    Show(set.elevator)
    for _,p in ipairs(set.doors) do Show(p) end
    Sleep(34)
    while true do
        Move(set.elevator,y_axis,0,10)
        WaitForMove(set.elevator,y_axis)
        doors(0)
        Show(set.rawWorks)
        poseArms(allArms,'park',2)
        poseArms(allArms,'approach',2)
        poseArms(allArms,'seam',1,1)
        endpoints={1,1,1,1}

        -- Front and rear opposing pairs alternate: one pair holds the frame
        -- while the other traverses its seam. Keep the original 7--15-pass
        -- variation, with variable tool roll, feed rate and inspection pauses.
        local workSteps = math.random(7,15)
        for pass=1,workSteps do
            local ids = workingPairs[(pass-1)%2+1]
            local from = endpoints[ids[1]]
            local direction = from==1 and 1 or -1
            local feed = math.random(250,450)/1000
            for _,i in ipairs(ids) do
                Turn(arms[i][6],y_axis,math.rad(math.random(-60,60)),1)
            end
            for sample=from+direction,from==1 and 5 or 1,direction do
                poseArms(ids,'seam',feed,sample)
            end
            local endpoint = from==1 and 5 or 1
            for _,i in ipairs(ids) do endpoints[i]=endpoint end
            Sleep(math.random(300,650))
            if pass%3==0 then
                clearTools(ids,.6)
                Sleep(math.random(200,450))
                poseArms(ids,'seam',.6,endpoint)
            end
        end

        clearTools(allArms,1)
        poseArms(allArms,'park',2)
        Hide(set.rawWorks)
        Show(set.finalWorks)
        doors(110)
        Move(set.elevator,y_axis,85,10)
        WaitForMove(set.elevator,y_axis)

        -- The VTOL is parented to the elevator. Hold the platform until the
        -- entire departure has finished, otherwise lowering it drags the craft.
        Move(set.finalWorks,y_axis,150,35)
        WaitForMove(set.finalWorks,y_axis)
        Turn(set.finalWorks,x_axis,math.rad(-20),.1)
        Move(set.finalWorks,z_axis,720,100)
        Move(set.finalWorks,y_axis,600,100)
        WaitForMove(set.finalWorks,z_axis)
        WaitForMove(set.finalWorks,y_axis)
        WaitForTurn(set.finalWorks,x_axis)
        Hide(set.finalWorks)
        replacePose(set.finalWorks)
        Sleep(34)
        Move(set.elevator,y_axis,0,10)
        WaitForMove(set.elevator,y_axis)
        doors(0)
        Sleep(5000)
    end
end
return M

