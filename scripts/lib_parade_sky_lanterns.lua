-- Bounded, world-anchored sky releases. Street-level rituals remain separate.
local M = {}
local function smooth(t)t=math.max(0,math.min(1,t));return t*t*(3-2*t)end
function M.Update(state,station,seconds,config,release)
    if not config or config.enabled==false then return {} end
    if not state.lastSeen or seconds<state.lastSeen or seconds-state.lastSeen>3 then
        state.flights={};state.lastRelease=nil
    end
    state.lastSeen=seconds
    local flights=state.flights or {};state.flights=flights
    for i=#flights,1,-1 do
        if seconds-flights[i].born>=config.lifetime then table.remove(flights,i) end
    end
    if station and not station.retired then
        local age=seconds-station.born-config.releaseDelay
        local generation=math.floor(age/config.releaseInterval)
        if age>=0 and station.skyGeneration~=generation then
            station.skyGeneration=generation
            if (not state.lastRelease or seconds-state.lastRelease>=config.releaseInterval-.05)
                and #flights<config.maxPerPayload then
                local flight=release(station,generation)
                if flight then
                    flight.born=seconds
                    flights[#flights+1]=flight;state.lastRelease=seconds
                end
            end
        end
    end
    return flights
end
function M.Pose(flight,seconds,config)
    local age=math.max(0,seconds-flight.born)
    local ascent=smooth(age/config.riseSeconds)
    local y=flight.y+(flight.ceiling-flight.y)*ascent
    -- Keep the launch over the curb until the whole lantern clears the roof.
    local driftAge=math.max(0,age-flight.clearTime)
    local windFade=smooth(driftAge/4)
    local phase=flight.phase or 0
    local x=flight.x+math.sin(age*.47+phase)*.65*ascent+(flight.windX or 0)*driftAge*windFade
    local z=flight.z+math.sin(age*.31+phase)*.65*ascent+(flight.windZ or 0)*driftAge*windFade
    local opacity=config.opacity*smooth(age/config.fadeIn)*smooth((config.lifetime-age)/config.fadeOut)
    opacity=opacity*(.97+.03*math.sin(age*1.3+phase))
    return {x=x,y=y,z=z,yaw=phase*57.2958+age*1.5,tilt=2.5*math.sin(age*.6+phase),
        roll=1.5*math.sin(age*.43+phase),headTilt=0,opacity=opacity,visible=age<config.lifetime,
        scale=config.scale,activity='sky_lantern'}
end
return M
