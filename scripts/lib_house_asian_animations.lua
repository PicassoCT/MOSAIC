-- Event-driven lifetime of selected Asian-house machinery. No polling thread.
-- Hiding restarts a sequence from its assembled pose on the next reveal.
local jobs, byPiece = {}, {}
local nextSignal = 8 -- 2 is the house animation group; 4 belongs to stun.
local native = Spring.UnitScript
local pieceMap

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

function M.start()
    for _, job in ipairs(jobs) do
        if not job.started and not job.retired and not IsBuildingPieceDetached(job.root) then
            job.started = true
            StartThread(function()
                SetSignalMask(2 + job.signal)
                if job.restart then
                    -- A hide/show pair can arrive in the same simulation tick.
                    -- Let the replacement stop commands finish before restoring.
                    for _, pose in ipairs(job.poses) do
                        for axis=1,3 do
                            WaitForMove(pose.piece, axis)
                            WaitForTurn(pose.piece, axis)
                        end
                    end
                    for _, pose in ipairs(job.poses) do
                        if not IsBuildingPieceDetached(pose.piece) then
                            for axis=1,3 do
                                Move(pose.piece, axis, pose.position[axis], 0)
                                Turn(pose.piece, axis, pose.rotation[axis], 0)
                            end
                            if pose.visible then Show(pose.piece) else Hide(pose.piece) end
                        end
                    end
                end
                job.run()
            end)
        end
    end
end

function M.stop(hide, permanent)
    for _, job in ipairs(jobs) do
        stop(job, hide)
        if permanent then job.retired = true end
    end
end

function M.detach(pieces)
    for _, p in ipairs(pieces) do
        local job = byPiece[p]
        if job and not job.retired then
            stop(job, false)
            job.retired = true
        end
    end
end
return M
