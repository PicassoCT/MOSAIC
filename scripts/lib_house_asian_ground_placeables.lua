-- Included in each unit-script environment: one terrain/road/movement path.
-- The catalogue supplies authored bounds and parent-space movement axes.
return function(placeablePlanner, options)
    local ux, uy, uz = Spring.GetUnitPosition(unitID)
    local front, _, right = Spring.GetUnitVectors(unitID)
    local scale = placeablePlanner.catalogue.scale
    local function world(x,z)
        -- Spring's model matrix uses -right, up, front as its basis.
        return ux+scale*(-right[1]*x+front[1]*z), uz+scale*(-right[3]*x+front[3]*z)
    end
    local roads=placeablePlanner.localRoads(GG.CityRoadNetwork,function(x,z)
        local dx,dz=x-ux,z-uz
        return (-right[1]*dx-right[3]*dz)/scale,(front[1]*dx+front[3]*dz)/scale
    end,math.max(options.halfExtent or 0, options.cell*3)+options.cell*6)
    local placements = placeablePlanner.plan({
        seed=options.seed,
        cell=options.cell, halfExtent=options.halfExtent, pieces=options.pieces, roads=roads,
        roadWidth=options.roadWidth or placeablePlanner.roadWidth,
        accept=function(candidate)
            local x,z=world(candidate.x,candidate.z)
            local ground=Spring.GetGroundHeight(x,z)
            if ground<0 then return false end
            -- Reject steep/wet patches instead of leaving a large kiosk floating.
            local low,high=ground,ground
            for _,px in ipairs({candidate.minX,candidate.maxX}) do
                for _,pz in ipairs({candidate.minZ,candidate.maxZ}) do
                    local wx,wz=world(px,pz)
                    if (Game.mapSizeX and (wx<0 or wx>Game.mapSizeX))
                        or (Game.mapSizeZ and (wz<0 or wz>Game.mapSizeZ)) then return false end
                    local h=Spring.GetGroundHeight(wx,wz)
                    if h<0 then return false end
                    low,high=math.min(low,h),math.max(high,h)
                end
            end
            if high-low>2 then return false end
            candidate.ground=low
            return true
        end,
    })
    for _,p in ipairs(placements) do
        local offsets={p.moveX,p.moveY+(p.ground-uy)/scale,p.moveZ}
        local basis=placeablePlanner.catalogue.moveBasis
        for axis=1,3 do
            local value=offsets[axis]
            if basis then
                value=0
                for j=1,3 do value=value+basis[axis][j]*offsets[j] end
            end
            Move(p.id,axis,value,0)
        end
        Turn(p.id,3,p.rotation,0)
        options.addToShowTable(p.id)
        Show(p.id)
        SetRadiancePlaceables({p.id},true)
        if options.onPlaced then options.onPlaced(p) end
    end
    return placements
end
