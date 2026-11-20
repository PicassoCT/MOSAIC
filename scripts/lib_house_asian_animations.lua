-- Selected machinery owns its subtree; one low-frequency supervisor recovers
-- crashed workers and motion stalls without restarting healthy neighbours.
-- Hiding restarts a sequence from its assembled pose on the next reveal.
local jobs, byPiece = {}, {}
local nextSignal = 8 -- 2 is the house animation group; 4 belongs to stun.
local native = Spring.UnitScript
local pieceMap
local enabled, supervising = false, false

local function freeze(p)
    for axis = 1, 3 do
        if native.IsInSpin(p, axis) then StopSpin(p, axis, 0) end
        if native.IsInTurn(p, axis) then
            local rotation = {native.GetPieceRotation(p)}
            -- On the old engine speed=0 changes the pose without replacing
            -- the queued animation. A nonzero speed replaces its destination;
            -- because that destination is the current pose it ends next tick.
            native.Turn(p, axis, rotation[axis], 1)
        end
        if native.IsInMove(p, axis) then
            local position = {native.GetPieceTranslation(p)}
            native.Move(p, axis, position[axis], 1)
        end
    end
end

local function stop(job, hide)
    if job.started then
        Signal(job.signal)
        for _, pose in ipairs(job.poses) do freeze(pose.piece) end
        job.started = false
        job.restart = true
    end
    if hide then
        for _, pose in ipairs(job.poses) do Hide(pose.piece) end
    end
end

local M = {}
function M.owns(p) return byPiece[p] ~= nil end

function M.add(root, run)
    if byPiece[root] or IsBuildingPieceDetached(root) then return end
    assert(nextSignal <= 2^30, 'too many Asian house animation workers')
    local job = {root=root, run=run, signal=nextSignal, poses={}}
    nextSignal = nextSignal * 2
    pieceMap = pieceMap or Spring.GetUnitPieceMap(unitID)
    job.name=tostring(root)
    for name,p in pairs(pieceMap) do if p==root then job.name=name;break end end
    local function collect(p)
        if byPiece[p] then return end
        byPiece[p] = job
        job.poses[#job.poses+1] = {piece=p,
            position={native.GetPieceTranslation(p)},
            rotation={native.GetPieceRotation(p)},
            visible=IsBuildingPieceVisible(p)}
        local info = Spring.GetUnitPieceInfo(unitID, p)
        for _, child in ipairs(info and info.children or {}) do
            collect(type(child)=='number' and child or assert(pieceMap[child]))
        end
    end
    collect(root)
    jobs[#jobs+1] = job
end

local function restore(job)
    -- Replace queued destinations before snapping; speed=0 alone does not
    -- cancel a previous native animation. Never wait on the failed movement.
    for _, pose in ipairs(job.poses) do
        if not IsBuildingPieceDetached(pose.piece) then
            for axis=1,3 do
                Move(pose.piece, axis, pose.position[axis], 1)
                Turn(pose.piece, axis, pose.rotation[axis], 1)
                Move(pose.piece, axis, pose.position[axis], 0)
                Turn(pose.piece, axis, pose.rotation[axis], 0)
            end
            if pose.visible then Show(pose.piece) else Hide(pose.piece) end
        end
    end
end

local function start(job)
    job.started, job.completed, job.thread = true, false, nil
    job.quiet, job.sample, job.healthy = 0, nil, 0
    StartThread(function()
        job.thread = coroutine.running()
        SetSignalMask(2 + job.signal)
        if job.restart then Sleep(34);restore(job) end
        job.run()
        -- A completed setup (for example a continuous native Spin or the
        -- deliberately invisible crane) is healthy, not an abandoned worker.
        job.completed = true
    end)
end

local function moved(job)
    local sample, changed = {}, job.sample == nil
    for _, pose in ipairs(job.poses) do
        local position = {native.GetPieceTranslation(pose.piece)}
        local rotation = {native.GetPieceRotation(pose.piece)}
        for axis=1,3 do
            sample[#sample+1] = position[axis]
            -- Continuous spins must not mask a stuck translation or turn.
            sample[#sample+1] = native.IsInSpin(pose.piece,axis) and 0 or rotation[axis]
        end
    end
    if job.sample then
        for i,v in ipairs(sample) do
            if math.abs(v-job.sample[i])>1e-6 then changed=true;break end
        end
    end
    job.sample=sample
    return changed
end

local function supervise()
    SetSignalMask(2)
    while enabled do
        Sleep(1000)
        local needed=false
        for _,job in ipairs(jobs) do
            if not job.retired and not IsBuildingPieceDetached(job.root) then
                if job.retry then
                    needed=true;job.retry=job.retry-1000
                    if job.retry<=0 then job.retry=nil;start(job) end
                elseif job.started and not job.completed then
                    needed=true
                    local reason
                    if job.thread and coroutine.status(job.thread)=='dead' then
                        reason='worker terminated unexpectedly (see preceding Lua error)'
                    else
                        job.quiet=moved(job) and 0 or job.quiet+1000
                        job.healthy=job.healthy+1000
                        if job.quiet>=30000 then reason='no movement progress for 30 seconds'
                        elseif job.healthy>=60000 and job.quiet==0 then job.failures=0 end
                    end
                    if reason then
                        stop(job,false)
                        job.failures=(job.failures or 0)+1
                        job.retry=math.min(30000,1000*2^math.min(5,job.failures-1))
                        if Spring.Echo then Spring.Echo('Asian house '..unitID..' animation '..job.name..': '..reason
                            ..'; restoring assembled pose and retrying in '..job.retry..' ms') end
                    end
                end
            end
        end
        if not needed then break end
    end
    supervising=false
end

function M.start()
    enabled=true
    for _, job in ipairs(jobs) do
        if not job.started and not job.retired and not IsBuildingPieceDetached(job.root) then
            job.retry=nil;start(job)
        end
    end
    if not supervising then supervising=true;StartThread(supervise) end
end

function M.stop(hide, permanent)
    enabled, supervising=false, false
    Signal(2)
    for _, job in ipairs(jobs) do
        stop(job, hide)
        job.retry=nil
        if permanent then job.retired = true end
    end
end

function M.detach(pieces)
    for _, p in ipairs(pieces) do
        local job = byPiece[p]
        if job and not job.retired then
            stop(job, false)
            job.retry=nil
            job.retired = true
        end
    end
end
return M
