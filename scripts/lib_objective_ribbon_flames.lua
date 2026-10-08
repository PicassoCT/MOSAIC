-- Independent named ribbon emitters per objective, driven by existing animation events.
local presets = {
    sulfur = {
        -- A long, narrow sulfur-coloured aerosol trail, not a luminous flame.
        direction={0,1,0}, length=1100, width=7, curl=0.28, speed=0.55,
        colorStart={0.86,0.78,0.28,0.55}, colorEnd={0.73,0.72,0.47,0},
        emission={0,0}, strands=2, windAffected=true, windInfluence=2.0, trailTime=4,
        distanceFactor=20,
    },
    pump = {
        direction={0,1,0}, length=120, width=20, curl=0.75, speed=2.1,
        colorStart={1,0.72,0.24,0.85}, colorEnd={0.85,0.12,0.025,0},
        emission={3,0.5}, windAffected=true, windInfluence=1.2, trailTime=1.2,
    },
    industrial = {
        direction={0,1,0}, length=85, width=16, curl=0.65, speed=1.8,
        colorStart={1,0.82,0.38,0.75}, colorEnd={0.9,0.18,0.03,0},
        emission={2.5,0.3}, windAffected=true, windInfluence=0.5, trailTime=0.8,
    },
    slagheap = {
        direction={0,1,0}, length=65, width=24, curl=.9, speed=1.3,
        colorStart={1,.5,.12,.7}, colorEnd={.65,.12,.025,0},
        emission={2,.15}, windAffected=true, windInfluence=.7, trailTime=1,
    },
    slagcrane = {
        direction={0,1,0}, length=48, width=12, curl=.7, speed=1.7,
        colorStart={1,.75,.25,.8}, colorEnd={.85,.15,.02,0},
        emission={2.5,.2}, windAffected=true, windInfluence=.5, trailTime=.7,
        motionAffected=true,
    },
    launch = {
        direction={0,-1,0}, length=320, width=42, curl=0.3, speed=3,
        colorStart={0.65,0.8,1,0.95}, colorEnd={1,0.25,0.04,0},
        emission={4,1}, windAffected=true, windInfluence=0.15, trailTime=0.5,
        -- The animated ship climbs far beyond its stationary unit's bounds.
        distanceCulling=false, drawInIcon=true,
    },
}
return function(unitID, kind)
    local preset=assert(presets[kind], 'unknown objective ribbon preset')
    local slot='objective-'..kind
    local dead=false
    local self={}
    function self.Start(piece, pad)
        if dead or not GG.SmokeRibbon then return false end
        local options={directionSpace='world',strands=3,motionAffected=false}
        for name,value in pairs(preset) do options[name]=value end
        if kind == 'sulfur' then
            -- The blimp pivot is inside its hull. Emit just beyond its long-axis
            -- tip, using the piece basis so the outlet follows the wind animation.
            local bounds = Spring.GetUnitPieceInfo(unitID, piece)
            if bounds and bounds.min and bounds.max then
                local axis = 1
                for i=2,3 do
                    if bounds.max[i]-bounds.min[i] > bounds.max[axis]-bounds.min[axis] then axis=i end
                end
                options.rootOffset = {}
                options.direction = {0,0,0}
                for i=1,3 do options.rootOffset[i]=(bounds.min[i]+bounds.max[i])*.5 end
                options.rootOffset[axis]=bounds.max[axis]+(bounds.max[axis]-bounds.min[axis])*.01
                options.direction[axis]=1
                options.directionSpace='piece'
            end
        end
        local ok,err=GG.SmokeRibbon.Set(unitID,slot,piece,options)
        if not ok then Spring.Echo('Objective ribbon flame: '..tostring(err)) end
        if ok and kind == 'launch' then
            -- Keep the original airborne exhaust. Only this extra slot reacts
            -- with the deck, and the renderer fades it out as the ship lifts away.
            local padOptions={}
            for name,value in pairs(options) do padOptions[name]=value end
            padOptions.mode='pad'
            padOptions.padPiece=pad
            padOptions.length=640;padOptions.width=84;padOptions.curl=0.65;padOptions.strands=4
            local padOK,padErr=GG.SmokeRibbon.Set(unitID,slot..'-pad',piece,padOptions)
            if not padOK then Spring.Echo('Objective pad streamers: '..tostring(padErr)) end
        end
        return ok
    end
    function self.Stop()
        if GG.SmokeRibbon then GG.SmokeRibbon.Remove(unitID,slot) end
        if kind == 'launch' and GG.SmokeRibbon then GG.SmokeRibbon.Remove(unitID,slot..'-pad') end
    end
    function self.Shutdown() dead=true;self.Stop() end
    return self
end
