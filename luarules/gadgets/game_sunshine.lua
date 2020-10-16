function gadget:GetInfo()
    return {
        name = "game_daycycle",
        desc = "controlls the sun rising and sinking",
        author = "PicassoCT",
        date = "12.02.2083",
        version = "v0.1",
        license = "GPL v3.0 or later",
        layer = -1,
        enabled = (Spring.SetSunLighting ~= nil) ,
    }
end


if gadgetHandler:IsSyncedCode() then
    -------------------------------------
    ---------------- SYNCED---------------
    VFS.Include("scripts/lib_mosaic.lua")
    VFS.Include("scripts/lib_UnitScript.lua")
	GameConfig = getGameConfig()
	
    DAYLENGTH = GameConfig.daylength
	local EVERY_NTH_FRAME =32
    --==========================WhereTheSunDontShines============================
    --Initialses the sun control and sets the inital arc
    function gadget:GameStart()
        --Spring.SetSunManualControl(true)
        setSunArc(1)
    end

    --multiplies all members of a table by a factor
    function factor(value, fac)
        for key, val in pairs(value) do
            value[key] = value[key] * fac
        end

        return value
    end


    --if you want diffrent colours for your day, modify this table
    sunCol = {}
    --night
    LengthOfNightDay = 9
    for i = 1, LengthOfNightDay do
        sunCol[#sunCol + 1] = makeVector(54, 106, 144)
    end
    sunCol[#sunCol + 1] = makeVector(49, 95, 125)
    sunCol[#sunCol + 1] = makeVector(41, 72, 120)
    sunCol[#sunCol + 1] = makeVector(27, 37, 100)
    sunCol[#sunCol + 1] = makeVector(24, 50, 80)
    sunCol[#sunCol + 1] = makeVector(27, 37, 80) 
    sunCol[#sunCol + 1] = makeVector(75, 18, 25)
    --sunrise
    sunCol[#sunCol + 1] = makeVector(88, 28, 0)
    sunCol[#sunCol + 1] = makeVector(120, 39, 0)
    sunCol[#sunCol + 1] = makeVector(156, 51, 0)
    sunCol[#sunCol + 1] = makeVector(175, 57, 0)
    sunCol[#sunCol + 1] = makeVector(223, 73, 0)
    sunCol[#sunCol + 1] = makeVector(246, 66, 0)
    sunCol[#sunCol + 1] = makeVector(255, 128, 0)
    sunCol[#sunCol + 1] = makeVector(255, 199, 0)
    --noon
    sunCol[#sunCol + 1] = makeVector(188, 193, 210)
    sunCol[#sunCol + 1] = makeVector(203, 175, 167)
    redShift = math.random(1, 45)
    constLight = 210 + redShift
    blueShift = 45 - redShift
    for i = 1, LengthOfNightDay do
        lightOffset = math.random(-5, 0)
        sunCol[#sunCol + 1] = makeVector(constLight + lightOffset, 232 + lightOffset, 210 + blueShift + lightOffset)
    end
    --zenit
    --mirrored sunrise
    size = #sunCol
    for i = 1, size do
        sunCol[#sunCol + 1] = sunCol[size - i]
    end
    --factor to divide the rgb values
    divFactor = 255
    -- Calculates the suns color depending on daytime
    function getsunColor(percent)
        percent = clamp(percent, 0, 1)
        pMin = math.floor(percent * (#sunCol))
        pMax = math.min(pMin + 1, #sunCol)
        --clamp
        pMax = math.max(2, math.min(pMax, #sunCol))
        pMin = math.min(pMax - 1, math.max(1, pMin))

        onePart = 1 / #sunCol
        diff = math.abs(percent - (pMin * onePart)) / onePart


        return {
            r = math.abs(math.mix(sunCol[pMin].x, sunCol[pMax].x, diff)) / divFactor,
            g = math.abs(math.mix(sunCol[pMin].y, sunCol[pMax].y, diff)) / divFactor,
            b = math.abs(math.mix(sunCol[pMin].z, sunCol[pMax].z, diff)) / divFactor,
            a = 0.5
        }
    end

    --Various Atmosphere and Sun setting getters
    local function getDefaultConfg(rgba)
        confg = {
            groundAmbientColor = { rgba.r, rgba.r, rgba.r },
            groundDiffuseColor = { rgba.r, rgba.r, rgba.r },
            groundSpecularColor = { rgba.r, rgba.r, rgba.r },
            unitAmbientColor = { rgba.r, rgba.r, rgba.r },
            unitDiffuseColor = { rgba.r, rgba.r, rgba.r },
            unitSpecularColor = { rgba.r, rgba.r, rgba.r },
            specularExponent = 0.007,
            sunColor = { rgba.r, rgba.r, rgba.r, rgba.r },
            skyColor = { rgba.r, rgba.r, rgba.r, rgba.r },
            cloudColor = { rgba.r, rgba.r, rgba.r, rgba.r },
            fogStart = 0.25,
            fogEnd = 0.75,
            fogColor = { 1.0, 1.0, 1.0, 0.5 }
        }

        return confg
    end

    local function PushSunConfig(self, ...)
        self[#self + 1] = { ... }
    end

    if GG.SunConfig == nil then GG.SunConfig = { PushSunConfig = PushSunConfig, getDefaultConfg = getDefaultConfg } end

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
        return { r = 0, g = 0, b = 0, a = percent * 100 }
    end

    function getFogColor(percent)
        return factor(getsunColor(percent), 0.9)
    end

    function getskyColor(percent)
        rgba = getsunColor(percent)
        rgba = factor(rgba, 0.6)
        rgba.b = rgba.b + 0.05
        return rgba
    end

    function getcloudColor(percent)
        return factor(getsunColor(percent), 0.3)
    end

    function setSunArc(frame)
        local resultVec = makeVector(0.5, math.abs(math.cos((frame % DAYLENGTH)/DAYLENGTH)), 0.3)
		Spring.SetSunDirection(resultVec.x, resultVec.y, resultVec.z)
    end

    -- calculates a fog curve with peak at midnight and zero at dawn and dusk
    function getFogFactor(percent)
        cosFac = (percent * 2 * math.pi) - math.pi
        invCosRes = math.cos(cosFac) * -1
        if invCosRes < 0 then invCosRes = 0 end
        return invCosRes
    end

    --sets the sunconfiguration given to it
    function setSun(c, totalPercent)

        Spring.SetSunLighting({ groundAmbientColor = { c.groundAmbientColor[1], c.groundAmbientColor[2], c.groundAmbientColor[3], c.groundAmbientColor[4] } })
        Spring.SetSunLighting({ groundDiffuseColor = { c.groundDiffuseColor[1], c.groundDiffuseColor[2], c.groundDiffuseColor[3], c.groundDiffuseColor[4] } })
        Spring.SetSunLighting({ groundSpecularColor = { c.groundSpecularColor[1], c.groundSpecularColor[2], c.groundSpecularColor[3], c.groundSpecularColor[4] } })
        Spring.SetSunLighting({ unitAmbientColor = { c.unitAmbientColor[1], c.unitAmbientColor[2], c.unitAmbientColor[3], c.unitAmbientColor[4] } })
        Spring.SetSunLighting({ unitDiffuseColor = { c.unitDiffuseColor[1], c.unitDiffuseColor[2], c.unitDiffuseColor[3], c.unitDiffuseColor[4] } })
        Spring.SetSunLighting({ unitSpecularColor = { c.unitSpecularColor[1], c.unitSpecularColor[2], c.unitSpecularColor[3], c.unitSpecularColor[4] } })
        Spring.SetSunLighting({ specularExponent = c.specularExponent })

        Spring.SetAtmosphere({ sunColor = { c.sunColor[1], c.sunColor[2], c.sunColor[3], c.sunColor[4] } }) --c.sunColor[4]
        Spring.SetAtmosphere({ skyColor = { c.skyColor[1], c.skyColor[2], c.skyColor[3], c.skyColor[4] } })
        Spring.SetAtmosphere({ cloudColor = { c.cloudColor[1], c.cloudColor[2], c.cloudColor[3], c.cloudColor[4] } })
       -- Spring.SetAtmosphere ({fogStart = c.fogStart, fogEnd =c.fogEnd, fogColor = {c.fogColor[1], c.fogColor[2], c.fogColor[3], c.fogColor[4]}})
    end

    --Creates a DayString
    function getDayTime(now, total)
        hours = math.floor((now / total) * 24) 
        minutes = math.ceil((((now / total) * 24) - hours) * 60) 
        return hours .. ":" .. minutes
    end

    --gets a config and sets the time of day as sun
    function aDay(timeFrame, WholeDay)
			--echo(getDayTime(timeFrame%WholeDay, WholeDay))
        percent = ((timeFrame % (WholeDay)) / (WholeDay))
		
		
		if math.random(1,10) > 5 and (timeFrame == DAWN_FRAME or timeFrame == DUSK_FRAME) and GameConfig.instance.culture == "arabic" then
			Spring.PlaySoundFile("sounds/civilian/arabic/callToPrayer"..math.random(1,3)..".ogg", 0.9)
		end
	
        config = getDefaultConfg({ r = 0.5, g = 0.5, b = 0.5, a = 0.5 })
        -- if GG.SunConfig and GG.SunConfig[1] then
        -- config= GG.SunConfig[1]
        -- GG.SunConfig[1].lifeTime= GG.SunConfig[1].lifeTime-32
			-- if GG.SunConfig[1].lifeTime <= 0 then
			-- GG.SunConfig[1]= nil
			-- end
        -- else

        rgba = getgroundAmbientColor(percent)

        config.groundAmbientColor = { rgba.r, rgba.g, rgba.b }
        rgba = getgroundDiffuseColor(percent)
        config.groundDiffuseColor = { rgba.r, rgba.g, rgba.b }
        rgba = getgroundSpecularColor(percent)
        config.groundSpecularColor = { rgba.r, rgba.g, rgba.b }
        rgba = getunitAmbientColor(percent)
        config.unitAmbientColor = { rgba.r, rgba.g, rgba.b }
        rgba = getunitDiffuseColor(percent)
        config.unitDiffuseColor = { rgba.r, rgba.g, rgba.b }
        rgba = getunitSpecularColor(percent)

        config.unitSpecularColor = { rgba.r, rgba.g, rgba.b }
        rgba = getspecularExponent(percent)
        config.specularExponent = rgba.a
        rgba = getsunColor(percent)
        config.sunColor = { rgba.r, rgba.g, rgba.b, rgba.a }
        rgba = getskyColor(percent)
        config.skyColor = { rgba.r, rgba.g, rgba.b, rgba.a }
        rgba = getcloudColor(percent)
        config.cloudColor = { rgba.r, rgba.g, rgba.b, rgba.a }

        config.fogStart = 2048 * (1.001 - getFogFactor(percent))
        config.fogEnd = 8192 * (1.001 - getFogFactor(percent))
        rgba = getFogColor(percent)
        config.fogColor = { rgba.r, rgba.g, rgba.b, rgba.a }
        --end

        setSun(config, percent)
    end
	startMorningOffset= DAYLENGTH/2
	DAWN_FRAME= math.ceil((DAYLENGTH/EVERY_NTH_FRAME)*0.25)*EVERY_NTH_FRAME
	DUSK_FRAME= math.ceil((DAYLENGTH/EVERY_NTH_FRAME)*0.75)*EVERY_NTH_FRAME
    --set the sun
    function gadget:GameFrame(n)
        if n % EVERY_NTH_FRAME == 0 then
			-- Spring.Echo(getDayTime((n + startMorningOffset)%DAYLENGTH, DAYLENGTH))
            aDay(n + startMorningOffset, DAYLENGTH)
        end
            setSunArc(n)
    end
end