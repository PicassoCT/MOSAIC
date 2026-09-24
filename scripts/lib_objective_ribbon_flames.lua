-- Independent named ribbon emitters per objective, driven by existing animation events.
local presets = {
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
    },
}
return function(unitID, kind)
    local preset=assert(presets[kind], 'unknown objective ribbon preset')
    local slot='objective-'..kind
    local dead=false
    local self={}
    function self.Start(piece)
        if dead or not GG.SmokeRibbon then return false end
        local options={directionSpace='world',strands=3,motionAffected=false}
        for name,value in pairs(preset) do options[name]=value end
        local ok,err=GG.SmokeRibbon.Set(unitID,slot,piece,options)
        if not ok then Spring.Echo('Objective ribbon flame: '..tostring(err)) end
        return ok
    end
    function self.Stop()
        if GG.SmokeRibbon then GG.SmokeRibbon.Remove(unitID,slot) end
    end
    function self.Shutdown() dead=true;self.Stop() end
    return self
end
