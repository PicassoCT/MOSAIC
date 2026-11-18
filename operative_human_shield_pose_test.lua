-- Run through run.sh with Lua 5.1+. Model-local alignment and transform cleanup.
local compile = loadstring or load
local function read(path)
    local file = assert(io.open(path)); local text = file:read('*a'); file:close(); return text
end
local source = read('scripts/lib_human_shield_pose.lua')
local header = read('gamedata/unit_script_header.lua')
local actualAxes = {
    tonumber(assert(header:match('local x_axis = (%d+)'))),
    tonumber(assert(header:match('local y_axis = (%d+)'))),
    tonumber(assert(header:match('local z_axis = (%d+)'))),
}
local function run(axes, missingAnchor)
    local moves, turns, originalMoves, originalTurns = {}, {}, {}, {}
    local moveTargets, turnTargets = {}, {}
    local writes = 0
    local pieces = {
        root=1, center=2, UpBody=3, Head1=4, UpArm1=5, UpArm2=6,
        LowArm1=7, LowArm2=8, UpLeg1=9, UpLeg2=10, LowLeg1=11,
        LowLeg2=12, Feet1=13, Feet2=14,
    }
    for id=1,14 do
        moves[id]={id/10,-3,id/20}; turns[id]={id/30,id/40,id/50}
        originalMoves[id]={unpack(moves[id])}; originalTurns[id]={unpack(turns[id])}
        -- An ordinary walking animation already has unfinished native targets.
        moveTargets[id]={9,8,7}; turnTargets[id]={6,5,4}
    end
    local anchor = missingAnchor and {0,0,0} or {2,14,-1}
    local env = setmetatable({x_axis=axes[1],y_axis=axes[2],z_axis=axes[3]}, {__index=_G})
    env.Spring = {
        UnitScript = {
            GetPieceTranslation=function(p) return unpack(moves[p]) end,
            GetPieceRotation=function(p) return unpack(turns[p]) end,
        },
        GetUnitPieceMap=function() return missingAnchor and {} or {center=99} end,
        GetUnitPiecePosition=function(id,p)
            assert(not missingAnchor and id==42 and p==99, 'read the carrier anchor')
            return unpack(anchor)
        end,
        GetUnitCollisionVolumeData=function(id)
            if id==42 then return 10,40,10 end
            return 10,25,10
        end,
    }
    env.Move=function(p,a,t,speed)
        writes=writes+1
        if speed==0 then moves[p][a]=t else moveTargets[p][a]=t end
    end
    env.Turn=function(p,a,t,speed)
        writes=writes+1
        if speed==0 then turns[p][a]=t else turnTargets[p][a]=t end
    end
    local function finishNativeAnimations()
        for id=1,14 do
            for axis=1,3 do
                moves[id][axis]=moveTargets[id][axis]
                turns[id][axis]=turnTargets[id][axis]
            end
        end
    end
    local makePose
    if setfenv then makePose=setfenv(assert(compile(source)),env)()
    else makePose=assert(load(source,'human shield pose','t',env))() end
    local pose=makePose(17,pieces)
    assert(writes==0, 'constructing a pose performs no engine mutations')
    pose:Capture(42)
    for axis=1,3 do
        -- Engine positions/translations use native XYZ; animation aliases may
        -- swap Y/Z in the exported civilian rig but must not rotate placement.
        local forward=axis==3 and 8 or 0
        local expected=originalMoves[1][axis]-anchor[axis]+forward
        assert(math.abs(moves[1][axis]-expected)<1e-9,
            'root offset and anchor compensation must use actual axis '..axis..': '..moves[1][axis]..' ~= '..expected)
    end
    assert(turns[5][axes[1]]<0 and turns[6][axes[1]]<0, 'both arms visibly held up')
    local capturedMoves, capturedTurns = {}, {}
    for id=1,14 do
        capturedMoves[id]={unpack(moves[id])}; capturedTurns[id]={unpack(turns[id])}
    end
    finishNativeAnimations()
    for id=1,14 do
        for axis=1,3 do
            assert(moves[id][axis]==capturedMoves[id][axis] and turns[id][axis]==capturedTurns[id][axis],
                'previous native animations must not drift the held pose')
        end
    end
    local capturedWrites=writes
    pose:Capture(42)
    assert(writes==capturedWrites, 'duplicate capture preserves original transform snapshot')
    pose:Release()
    finishNativeAnimations()
    for id=1,14 do
        for axis=1,3 do
            assert(moves[id][axis]==originalMoves[id][axis], 'all translations restored')
            assert(turns[id][axis]==originalTurns[id][axis], 'all rotations restored')
        end
    end
    local restoredWrites=writes
    pose:Release()
    assert(writes==restoredWrites, 'duplicate release is inert')
    pose:Capture(42); pose:Release(); finishNativeAnimations()
    for id=1,14 do
        for axis=1,3 do
            assert(moves[id][axis]==originalMoves[id][axis] and turns[id][axis]==originalTurns[id][axis],
                'recapture must snapshot the restored pose')
        end
    end
end
run(actualAxes, false)
run({1,2,3}, false)
run(actualAxes, true)
print('PASS: Human Shield pose uses production model axes, compensates carrier anchor, scales spacing, cancels native motion, preserves snapshots and restores all transforms')
