-- Called by the drone's existing spray loop. No extra simulation thread.
local Config=VFS.Include('luarules/gadgets/include/cloud_volume_config.lua')
return function(id,piece,kind)
    local color=assert(Config.aerosolColors[kind], 'unknown aerosol '..tostring(kind))
    local slot='aerosol-spray'
    local running,dead,nextPuff=false,false,0
    local self={}
    function self.Stop()
        if running and GG.SmokeRibbon then GG.SmokeRibbon.Remove(id,slot) end
        running=false
    end
    function self.Update()
        if dead then return end
        if not running and GG.SmokeRibbon then
            running=GG.SmokeRibbon.Set(id,slot,piece,{
                direction={0,-1,0}, directionSpace='world',
                length=120, width=42, curl=.85, speed=.8, strands=3,
                colorStart={color[1],color[2],color[3],.65},
                colorEnd={color[1],color[2],color[3],0}, emission={3,1.6},
                windAffected=true, windInfluence=.7, motionAffected=true,
                motionInfluence=.7, trailTime=1.2,
            })
        end
        local frame=Spring.GetGameFrame()
        if frame>=nextPuff and GG.CloudVolume then
            local x,y,z=Spring.GetUnitPiecePosDir(id,piece)
            if x and GG.CloudVolume.Burst('aerosol_'..kind,x,y-24,z) then
                -- At most eight live puffs per spraying drone; detached puffs
                -- remain behind the moving emitter and fade after it stops.
                nextPuff=frame+math.ceil((Game.gameSpeed or 30)*.8)
            end
        end
    end
    function self.Shutdown() dead=true;self.Stop() end
    return self
end
