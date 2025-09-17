function gadget:GetInfo()
    return {
        name = "game_daycycle",
        desc = "controlls the sun rising and sinking",
        author = "PicassoCT",
        date = "12.02.2083",
        version = "v0.1",
        license = "GPL v3.0 or later",
        layer = -1,
        enabled = (Spring.SetSunLighting ~= nil)
    }
end

if gadgetHandler:IsSyncedCode() then
    -------------------------------------
    ---------------- SYNCED---------------
    VFS.Include("scripts/lib_mosaic.lua")
    VFS.Include("scripts/lib_UnitScript.lua")
    VFS.Include("scripts/lib_Type.lua")
    local GameConfig = getGameConfig()

    local DAYLENGTH = GameConfig.daylength
    local EVERY_NTH_FRAME = 32
    local REGIONAL_MAX_ALTITUDE = 70
    local EquatorialDirectionSign = 1
    -- ==========================WhereTheSunDontShines============================
    -- Initialses the sun control and sets the inital arc
    function gadget:GameStart()
        -- Spring.SetSunManualControl(true)
        REGIONAL_MAX_ALTITUDE, EquatorialDirectionSign = getAzimuthByRegion(GameConfig.instance.culture, getDetermenisticMapHash(Game))
        echo("game_daycycle: sun anzimuth:"..REGIONAL_MAX_ALTITUDE)
        echo("game_daycycle: equatorial direction sign:"..EquatorialDirectionSign)
    end

    -- multiplies all members of a table by a factor
    function factor(value, fac)
        for key, val in pairs(value) do value[key] = value[key] * fac end

        return value
    end


    assert(GameConfig.instance.culture)
    assert(getDetermenisticMapHash(Game))
    local regDayCol = getRegionDayColorBy(GameConfig.instance.culture, getDetermenisticMapHash(Game))
    echo("Regional Day Colors: r:"..regDayCol.x .. " g: ".. regDayCol.y .. " b:".. regDayCol.z)

    -- if you want diffrent colours for your day, modify this table
    sunCol = {}
    -- night
    LengthOfNightDay = 12
    for i = 1, LengthOfNightDay do
        sunCol[#sunCol + 1] = mixTable(makeVector(54, 72, 126), makeVector(64, 84, 80), math.random(1,100)/100)  
    end

    sunCol[#sunCol + 1] = makeVector(49, 66, 115)
    sunCol[#sunCol + 1] = makeVector(41, 56, 97)
    sunCol[#sunCol + 1] = makeVector(31, 43, 74)
    sunCol[#sunCol + 1] = makeVector(25, 34, 59)
    sunCol[#sunCol + 1] = makeVector(45, 25, 35)
    sunCol[#sunCol + 1] = makeVector(65, 18, 25)

    -- sunrise
    sunCol[#sunCol + 1] = makeVector(88, 28, 0)
    sunCol[#sunCol + 1] = makeVector(120, 39, 0)
    sunCol[#sunCol + 1] = makeVector(156, 51, 0)
    sunCol[#sunCol + 1] = makeVector(175, 57, 0)
    sunCol[#sunCol + 1] =  mixclampTable(regDayCol,makeVector(192, 73, 0), 0.12)
    sunCol[#sunCol + 1] =  mixclampTable(regDayCol,makeVector(222, 83, 0), 0.33)

    --blend towards day
    sunCol[#sunCol + 1] = mixclampTable(regDayCol, makeVector(246, 92, 0), 0.66)
    sunCol[#sunCol + 1] = mixclampTable(regDayCol, makeVector(246, 100, 0), 0.88)

    --daytime
    for i = 1, LengthOfNightDay + 2  do
        sunCol[#sunCol + 1] = regDayCol
    end

    -- zenit
    -- mirrored sunrise aka sunset
    size = #sunCol
    for i = 1, size do sunCol[#sunCol + 1] = sunCol[size - i] end
    -- factor to divide the rgb values
    divFactor = 255
    -- Calculates the suns color depending on daytime
    function getsunColor(percent)
        percent = clamp(percent, 0, 1)
        pMin = math.floor(percent * (#sunCol))
        pMax = math.min(pMin + 1, #sunCol)
        -- clamp
        pMax = math.max(2, math.min(pMax, #sunCol))
        pMin = math.min(pMax - 1, math.max(1, pMin))

        onePart = 1 / #sunCol
        diff = math.abs(percent - (pMin * onePart)) / onePart

        return {
            r = math.abs(math.mix(sunCol[pMin].x, sunCol[pMax].x, diff)) /
                divFactor,
            g = math.abs(math.mix(sunCol[pMin].y, sunCol[pMax].y, diff)) /
                divFactor,
            b = math.abs(math.mix(sunCol[pMin].z, sunCol[pMax].z, diff)) /
                divFactor,
            a = 0.5
        }
    end
    --echo("Suncolor: "..toString(sunCol))

    -- Various Atmosphere and Sun setting getters
    local function getDefaultConfg(rgba)
        confg = {
            groundAmbientColor = {rgba.r, rgba.r, rgba.r},
            groundDiffuseColor = {rgba.r, rgba.r, rgba.r},
            groundSpecularColor = {rgba.r, rgba.r, rgba.r},
            unitAmbientColor = {rgba.r, rgba.r, rgba.r},
            unitDiffuseColor = {rgba.r, rgba.r, rgba.r},
            unitSpecularColor = {rgba.r, rgba.r, rgba.r},
            specularExponent = 0.007,
            sunColor = {rgba.r, rgba.r, rgba.r, rgba.r},
            skyColor = {rgba.r, rgba.r, rgba.r, rgba.r},
            cloudColor = {rgba.r, rgba.r, rgba.r, rgba.r},
            fogStart = 0.25,
            fogEnd = 0.75,
            fogColor = {1.0, 1.0, 1.0, 0.5}
        }

        return confg
    end

    local function PushSunConfig(self, ...) self[#self + 1] = {...} end

    if GG.SunConfig == nil then
        GG.SunConfig = {
            PushSunConfig = PushSunConfig,
            getDefaultConfg = getDefaultConfg
        }
    end

    function getgroundAmbientColor(percent)
        return factor(getsunColor(percent), 0.66)
    end

    function getgroundDiffuseColor(percent)
        return factor(getsunColor(percent), 0.75)
    end

    function getgroundSpecularColor(percent)
        return factor(getsunColor(percent), 0.95)
    end

    function getunitAmbientColor(percent)
        return factor(getsunColor(percent), 0.9)
    end

    function getunitDiffuseColor(percent)
        return factor(getsunColor(percent), 0.98)
    end

    function getunitSpecularColor(percent)
        rgba = getsunColor(percent)
        rgba.r = math.min(rgba.r, rgba.r * 0.8)
        return rgba
    end

    function getspecularExponent(percent)
        return {r = 0, g = 0, b = 0, a = percent * 100}
    end

    function getFogColor(percent) return factor(getsunColor(percent), 0.9) end

    function getskyColor(percent)
        rgba = getsunColor(percent)
        rgba = factor(rgba, 0.6)
        rgba.b = rgba.b + 0.05
        return rgba
    end

    function getcloudColor(percent) return factor(getsunColor(percent), 0.3) end

    function normalizeVector(vec)
        local length = math.sqrt(vec.x^2 + vec.y^2 + vec.z^2)
        vec.x = vec.x/length
        vec.y = vec.y/length
        vec.z = vec.z/length
        return vec
    end

    function setSunArc(daytimeFrames)
        
        local dayPercent = (daytimeFrames % DAYLENGTH) /DAYLENGTH
        if dayPercent < 0.25 or dayPercent > 0.75 then   --night and thus moon rollover          
            --[[
            if dayPercent < 0.25  then
                dayPercent = 0.25 + dayPercent -- 0.25 - 0.5
            else
                dayPercent = dayPercent -0.25 -- 0.5 -0.75
            end
            ]]
        end 
        dayPercent = (dayPercent - 0.25) * 2.0

        local SUN_MOVE_SPEED = 360.0 / (DAYLENGTH / 2.0)  -- Degrees per second

        -- Calculate azimuth angle based on time of day
        local azimuth = (daytimeFrames * SUN_MOVE_SPEED) % 360.0

        -- Adjust elevation angle for sunrise and sunset effect 
        local elevation = math.abs(math.sin(dayPercent*math.pi))* REGIONAL_MAX_ALTITUDE 

        elevation = math.max(1, math.min(90.0, math.abs(elevation)))

        -- Convert to Cartesian coordinates
        local rElevation = math.rad(elevation)
        local rAzimuth = math.rad(azimuth)
        local resultVec = {
            x= math.cos(rElevation) * math.cos(rAzimuth),
            z= math.cos(rElevation) * math.sin(rAzimuth), --
            y= math.abs(math.sin(rElevation))
            }

        -- Normalize the vector
        local resultVec = normalizeVector(resultVec)
--        Spring.Echo(getDayTimeString(daytimeFrames, DAYLENGTH).."REG:"..REGIONAL_MAX_ALTITUDE.." -> ("..resultVec.x.."/"..resultVec.y .."/"..resultVec.z..")")
        Spring.SetSunDirection(resultVec.x, resultVec.y, resultVec.z)
    end

    -- calculates a fog curve with peak at midnight and zero at dawn and dusk
    function getFogFactor(percent)
        cosFac = (percent * 2 * math.pi) - math.pi
        invCosRes = math.cos(cosFac) * -1
        if invCosRes < 0 then invCosRes = 0 end
        return invCosRes
    end

    -- sets the sunconfiguration given to it
    function setSun(c, totalPercent)

        Spring.SetSunLighting({
            groundAmbientColor = {
                c.groundAmbientColor[1], c.groundAmbientColor[2],
                c.groundAmbientColor[3], c.groundAmbientColor[4]
            }
        })
        Spring.SetSunLighting({
            groundDiffuseColor = {
                c.groundDiffuseColor[1], c.groundDiffuseColor[2],
                c.groundDiffuseColor[3], c.groundDiffuseColor[4]
            }
        })
        Spring.SetSunLighting({
            groundSpecularColor = {
                c.groundSpecularColor[1], c.groundSpecularColor[2],
                c.groundSpecularColor[3], c.groundSpecularColor[4]
            }
        })
        Spring.SetSunLighting({
            unitAmbientColor = {
                c.unitAmbientColor[1], c.unitAmbientColor[2],
                c.unitAmbientColor[3], c.unitAmbientColor[4]
            }
        })
        Spring.SetSunLighting({
            unitDiffuseColor = {
                c.unitDiffuseColor[1], c.unitDiffuseColor[2],
                c.unitDiffuseColor[3], c.unitDiffuseColor[4]
            }
        })
        Spring.SetSunLighting({
            unitSpecularColor = {
                c.unitSpecularColor[1], c.unitSpecularColor[2],
                c.unitSpecularColor[3], c.unitSpecularColor[4]
            }
        })
        Spring.SetSunLighting({specularExponent = c.specularExponent})

        Spring.SetAtmosphere({
            sunColor = {
                c.sunColor[1], c.sunColor[2], c.sunColor[3], c.sunColor[4]
            }
        }) -- c.sunColor[4]
        Spring.SetAtmosphere({
            skyColor = {
                c.skyColor[1], c.skyColor[2], c.skyColor[3], c.skyColor[4]
            }
        })
        Spring.SetAtmosphere({
            cloudColor = {
                c.cloudColor[1], c.cloudColor[2], c.cloudColor[3],
                c.cloudColor[4]
            }
        })
        -- Spring.SetAtmosphere ({fogStart = c.fogStart, fogEnd =c.fogEnd, fogColor = {c.fogColor[1], c.fogColor[2], c.fogColor[3], c.fogColor[4]}})
    end



    -- Creates a DayString
    function getDayTimeString(now, total)
        Frame = now % total
        percent = Frame / DAYLENGTH
        hours = math.floor((Frame / DAYLENGTH) * 24)
        minutes = math.ceil((((Frame / DAYLENGTH) * 24) - hours) * 60)
        seconds = 60 - ((24 * 60 * 60 - (hours * 60 * 60) - (minutes * 60)) % 60)
        if minutes < 10 then minutes = "0"..minutes end
        if hours < 10 then hours = "0"..hours end
        return hours .. ":" .. minutes
    end

    local dampenFactor = 1.0
    function dampenSunColorIfRaining(rgba)
        if isRaining() then
            dampenFactor = math.max(0.25, dampenFactor -0.01)
        else
            dampenFactor = math.min(1.0, dampenFactor + 0.01)
        end
        return {r= rgba.r * dampenFactor, g = rgba.g * dampenFactor, b = rgba.b* dampenFactor, a= rgba.a}
    end

    -- gets a config and sets the time of day as sun
    function aDay(timeFrame, WholeDay)
        --echo("Daytime:"..getDayTimeString(timeFrame%WholeDay, WholeDay))
        percent = ((timeFrame % (WholeDay)) / (WholeDay))

        if math.random(1, 10) > 5 and (timeFrame == DAWN_FRAME or timeFrame == DUSK_FRAME) then

            if (GameConfig.instance.culture == "arabic") then    
            Spring.PlaySoundFile("sounds/civilian/arabic/callToPrayer" .. math.random(1, 6) .. ".ogg", 0.9)
            end
            if (GameConfig.instance.culture == "international") then    
            Spring.PlaySoundFile("sounds/civilian/international/callToPrayer" .. math.random(1, 4) .. ".ogg", 0.9)
            end
        end
        config = getDefaultConfg({r = 0.5, g = 0.5, b = 0.5, a = 0.5})
        -- if GG.SunConfig and GG.SunConfig[1] then
        -- config= GG.SunConfig[1]
        -- GG.SunConfig[1].lifeTime= GG.SunConfig[1].lifeTime-32
        -- if GG.SunConfig[1].lifeTime <= 0 then
        -- GG.SunConfig[1]= nil
        -- end
        -- else

        rgba = getgroundAmbientColor(percent)

        config.groundAmbientColor = {rgba.r, rgba.g, rgba.b}
        rgba = getgroundDiffuseColor(percent)
        config.groundDiffuseColor = {rgba.r, rgba.g, rgba.b}
        rgba = getgroundSpecularColor(percent)
        config.groundSpecularColor = {rgba.r, rgba.g, rgba.b}
        rgba = getunitAmbientColor(percent)
        config.unitAmbientColor = {rgba.r, rgba.g, rgba.b}
        rgba = getunitDiffuseColor(percent)
        config.unitDiffuseColor = {rgba.r, rgba.g, rgba.b}
        rgba = getunitSpecularColor(percent)

        config.unitSpecularColor = {rgba.r, rgba.g, rgba.b}
        rgba = getspecularExponent(percent)
        config.specularExponent = rgba.a
        rgba = dampenSunColorIfRaining(getsunColor(percent))
        config.sunColor = {rgba.r, rgba.g, rgba.b, rgba.a}
        rgba = getskyColor(percent)
        config.skyColor = {rgba.r, rgba.g, rgba.b, rgba.a}
        rgba = getcloudColor(percent)
        config.cloudColor = {rgba.r, rgba.g, rgba.b, rgba.a}

        config.fogStart = 2048 * (1.001 - getFogFactor(percent))
        config.fogEnd = 8192 * (1.001 - getFogFactor(percent))
        rgba = getFogColor(percent)
        config.fogColor = {rgba.r, rgba.g, rgba.b, rgba.a}
        -- end

        setSun(config, percent)
    end

    DAWN_FRAME = math.ceil((DAYLENGTH / EVERY_NTH_FRAME) * 0.25) *
                     EVERY_NTH_FRAME
    DUSK_FRAME = math.ceil((DAYLENGTH / EVERY_NTH_FRAME) * 0.75) *
                     EVERY_NTH_FRAME
    local HALF_DAY_OFFSET = DAYLENGTH * 0.5
    -- set the sun
    function gadget:GameFrame(n)
        if n % EVERY_NTH_FRAME == 0 then
            aDay(n + HALF_DAY_OFFSET, DAYLENGTH)
        end
        setSunArc(n + HALF_DAY_OFFSET)
    end
end
