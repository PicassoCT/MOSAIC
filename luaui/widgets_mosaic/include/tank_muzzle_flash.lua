-- A tank's short-lived forward flash and its light share one shot envelope.
-- Source membership and all visual dimensions live in lib_mosaic's config set.
local M = {}
function M.ActiveFrame(Spring, id, profile, frame)
    local born = Spring.GetUnitRulesParam(id, profile.shotParam)
    if type(born) ~= 'number' or born < 0 then return end
    local age = frame - born
    if age < 0 or age >= profile.durationFrames then return nil, nil, born, age end
    return born, age, born, age
end

function M.Collect(Spring, id, record, frame)
    local p = record.profile
    local born, age, observed, observedAge = M.ActiveFrame(Spring, id, p, frame)
    local trace = record.trace
    local firstObservation = observed and record.traceObserved ~= observed
    if observed then
        record.traceShot = observed
        if trace then trace.Log(id, observed, 'tank_shot_observed',
            {sample_frame=frame, age=observedAge, duration_frames=p.durationFrames,
                first_observation=firstObservation}) end
        record.traceObserved = observed
    end
    if not born then
        if trace then trace.Log(id, observed or 'waiting', 'tank_muzzle_rejected',
            {reason=observed and (observedAge < 0 and 'future_stamp' or 'expired_stamp') or 'no_shot_stamp',
                sample_frame=frame, age=observedAge,
                expired_on_first_observation=observed and observedAge >= p.durationFrames
                    and not not firstObservation}) end
        return
    end
    if not record.pieces then
        local map = Spring.GetUnitPieceMap(id)
        if map and map[p.piece] and map[p.directionPiece] then
            record.pieces = {map[p.piece], map[p.directionPiece]}
        end
        if trace then trace.Log(id, born, 'tank_muzzle_anchors',
            {piece_name=p.piece, direction_piece_name=p.directionPiece,
                piece=map and map[p.piece], direction_piece=map and map[p.directionPiece],
                available=not not record.pieces, reason=not record.pieces and
                    (map and 'missing_named_piece' or 'missing_piece_map') or nil}) end
    end
    if not record.pieces then
        if trace then trace.Log(id, born, 'tank_muzzle_rejected', {reason='missing_anchors', age=age}) end
        return
    end
    local x,y,z = Spring.GetUnitPiecePosDir(id, record.pieces[1])
    local bx,by,bz = Spring.GetUnitPiecePosDir(id, record.pieces[2])
    if not x or not bx then
        if trace then trace.Log(id, born, 'tank_muzzle_rejected',
            {reason='missing_piece_position', piece=record.pieces[1], direction_piece=record.pieces[2], age=age}) end
        return
    end
    -- FireEmit is deliberately rotated for the legacy CEG. Its position is
    -- correct, but its local forward vector is not the cannon's firing axis.
    local dx,dy,dz = x-bx,y-by,z-bz
    local barrelLength = math.sqrt(dx*dx+dy*dy+dz*dz)
    if barrelLength < 0.001 then
        if trace then trace.Log(id, born, 'tank_muzzle_rejected',
            {reason='degenerate_direction', barrel_length=barrelLength, age=age}) end
        return
    end
    dx,dy,dz = dx/barrelLength,dy/barrelLength,dz/barrelLength
    local ux,uy,uz = Spring.GetUnitPosition(id)
    if Spring.GetUnitViewPosition then
        local vx,vy,vz = Spring.GetUnitViewPosition(id)
        if ux and vx then x,y,z = x+vx-ux,y+vy-uy,z+vz-uz end
    end
    x,y,z = x+dx*p.clearance,y+dy*p.clearance,z+dz*p.clearance
    local length = math.max(p.minLength, math.min(p.maxLength, barrelLength*p.lengthFactor))
    local width = length*p.widthFactor
    local fade = (1-age/p.durationFrames)^1.5
    local ribbon = {
        unitID=id, x=x,y=y,z=z, direction={dx,dy,dz},
        length=length,width=width,scale=1,
        speed=p.speed,curl=p.curl,seed=(id*37+born)%10000,strands=p.strands,
        colorStart=p.colorStart,colorEnd=p.colorEnd,emission=p.emission,
        sourceGlow=p.sourceGlow,opacity=fade,distanceFactor=p.distanceFactor,
        windInfluence=0.08,trailTime=0.05,
    }
    if trace then
        trace.Log(id, born, 'tank_muzzle_source_ready',
            {sample_frame=frame, age=age, piece=record.pieces[1], direction_piece=record.pieces[2],
                x=x, y=y, z=z, dx=dx, dy=dy, dz=dz, length=length, width=width, opacity=fade})
        ribbon.executionTrace = {logger=trace, unitID=id, cycle=born,
            stagePrefix='tank_muzzle', piece=record.pieces[1]}
    end
    return {x=x,y=y,z=z, radius=length*p.radiusFactor,color=p.color,
        strength=p.strength*fade,ribbon=ribbon}
end
return M
