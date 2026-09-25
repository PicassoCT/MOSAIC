-- Roots follow the artist's emitter pieces; orientation follows the existing rig.
return function(unitID, groups, useTailWind)
    if not GG.SmokeRibbon then return 0, false end
    local map = Spring.GetUnitPieceMap(unitID) or {}
    local emitters = groups.hairemit or {}
    local tail = groups.Tail or {}
    local driven = useTailWind == true and tail[1] ~= nil and map.TailRotator ~= nil
    local directionPiece = driven and tail[1] or map.Head
    local count = 0
    for i=1,3 do
        -- DAE exports may mix unpadded and zero-padded piece suffixes.
        local emitter = emitters[i] or map['hairemit'..i]
            or map[string.format('hairemit%02d',i)]
            or map[string.format('hairemit%03d',i)]
        if emitter ~= nil then
            local ok = GG.SmokeRibbon.Set(unitID,'hair'..i,emitter,{
                mode='hair', directionSpace='piece', directionPiece=directionPiece,
                direction={0,0,-1}, rootOffset={0,0,0},
                length=({2.6,2.8,3.0})[i], width=0.55, strands=1,
                stiffness=0.65, gravity=0.18, curl=0.08,
                -- Tail1 already includes TailRotator yaw, lift and head animation.
                -- Adding engine wind again would pull the two effects apart.
                windAffected=not driven, motionAffected=true, motionInfluence=0.35,
                distanceFactor=100, seed=i*7.13,
            })
            if ok then count = count+1 end
        end
    end
    -- Models without the named emitters retain their polygon hair unchanged.
    return count, driven and count > 0
end
