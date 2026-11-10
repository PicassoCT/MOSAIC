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
            -- Relax cosmetic siting on pass two, but never water/map bounds.
            -- Permit a 20% slope instead of 4%; cliffs remain unsuitable.
            local grade=candidate.relaxed and 0.20 or 0.04
            local low=ground
            local samples={{x=x,z=z,h=ground}}
            for _,px in ipairs({candidate.minX,candidate.maxX}) do
                for _,pz in ipairs({candidate.minZ,candidate.maxZ}) do
                    local wx,wz=world(px,pz)
                    if (Game.mapSizeX and (wx<0 or wx>Game.mapSizeX))
                        or (Game.mapSizeZ and (wz<0 or wz>Game.mapSizeZ)) then return false end
                    local h=Spring.GetGroundHeight(wx,wz)
                    if h<0 then return false end
                    for _,sample in ipairs(samples) do
                        local dx,dz=wx-sample.x,wz-sample.z
                        if math.abs(h-sample.h)>math.max(2,grade*math.sqrt(dx*dx+dz*dz)) then
                            return false
                        end
                    end
                    samples[#samples+1]={x=wx,z=wz,h=h}
                    low=math.min(low,h)
                end
            end
            -- Centre/corners alone can straddle a river. Sample the footprint
            -- at terrain-square spacing, including its edges, on both passes.
            local step=Game.squareSize or 8
            local nx=math.max(1,math.ceil((candidate.maxX-candidate.minX)*scale/step))
            local nz=math.max(1,math.ceil((candidate.maxZ-candidate.minZ)*scale/step))
            for ix=0,nx do
                for iz=0,nz do
                    local wx,wz=world(candidate.minX+(candidate.maxX-candidate.minX)*ix/nx,
                        candidate.minZ+(candidate.maxZ-candidate.minZ)*iz/nz)
                    local h=Spring.GetGroundHeight(wx,wz)
                    if h<0 then return false end
                    local dx,dz=wx-x,wz-z
                    if math.abs(h-ground)>math.max(2,grade*math.sqrt(dx*dx+dz*dz)) then return false end
                    low=math.min(low,h)
                end
            end
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
