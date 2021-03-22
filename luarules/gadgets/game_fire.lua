function gadget:GetInfo()
    return {
        name = "on Fire",
        desc = "Kills the infected ",
        author = "zwzsg",
        date = "3rd of May 2010",
        license = "Free",
        layer = 0,
        version = 1,
        enabled = true,
        hidden = true
    }
end

-- modified the script: only corpses with the customParam "featuredecaytime" will disappear

if (gadgetHandler:IsSyncedCode()) then
    local spSpawnCEG = Spring.SpawnCEG
    local spGetPosition = Spring.GetUnitPosition
    local spIsUnitDead = Spring.GetUnitIsDead
    local spAddUnitDamage = Spring.AddUnitDamage
    local spGetGroundNormal =Spring.GetGroundNormal

    VFS.Include("scripts/lib_OS.lua", nil, VFSMODE)
    VFS.Include("scripts/lib_UnitScript.lua", nil, VFSMODE)
    VFS.Include("scripts/lib_Build.lua", nil, VFSMODE)
    VFS.Include("scripts/lib_mosaic.lua", nil, VFSMODE)
    local UnitID = 1
    local Heat = 2
    local disDance = 7
    local STATE_STARTED = "STARTED"
    local STATE_ENDED = "ENDED"
    local GameConfig = getGameConfig()
    local isPanicAble = getCultureUnitModelTypes(
                                     GameConfig.instance.culture, "civilian",
                                     UnitDefs)

    function gadget:GameFrame(frame)
        if frame % disDance == 0 and GG.OnFire ~= nil and #GG.OnFire > 0 then
            local onFireUpInHere = GG.OnFire
            --- -Spring.Echo("Gfire:Test")
            -- disDance=math.ceil(math.random(60,170))
            for i = 1, table.getn(GG.OnFire), 1 do
                --check if not nil
                if GG.OnFire[i] ~= nil then
                    if GG.OnFire[i][UnitID] then
                        if GG.OnFire[i][Heat] >= 0 then
                            GG.OnFire[i][Heat] = GG.OnFire[i][Heat] - disDance

                            if not GG.OnFire[i].DontPanic then GG.OnFire[i].DontPanic = (isPanicAble[Spring.GetUnitDefID(GG.OnFire[i][UnitID])] ~= nil) end
                            if spIsUnitDead(GG.OnFire[i][UnitID]) == false then

                                x, y, z = spGetPosition(GG.OnFire[i][UnitID])
                                if GG.OnFire[i].DontPanic == true then
                                    Spring.SetUnitNoSelect(GG.OnFire[i][UnitID], true)
                                    Spring.SetUnitMoveGoal(GG.OnFire[i][UnitID], x + math.random(-20, 20), y, z + math.random(-20, 20))
                                end
                                additional = math.random(3, 9)
                                addx = math.random(0, 4)
                                addz = math.random(0, 4)
                                xd = math.random(-1, 1)
                                zd = math.random(-1, 1)

                                dx,dy,dz= spGetGroundNormal(x + addx * xd, z + addz * zd, true)
                                    spSpawnCEG("flames", x + addx * xd, y + additional, z + addz * zd, dx, dy, dz, 50, 0)
                                if frame % 3 == 0 then
                                    spSpawnCEG("vortflames", x + addx * xd, y + additional, z + addz * zd, 0, 1, 0, 50, 0)
                                end
                                spAddUnitDamage(GG.OnFire[i][UnitID], 1)
                            end
                        else
                            Spring.SetUnitNoSelect(GG.OnFire[i][UnitID], false)
                            setCivilianUnitInternalStateMode(UnitID, STATE_ENDED)
                            GG.OnFire[i][UnitID] = nil
                        end
                    end
                end
            end
        end

        if frame % 5000 == 0 and GG.OnFire ~= nil then
            y = table.getn(GG.OnFire)
            countTen = 0
            for i = 1, y, 1 do
                if GG.OnFire[i] ~= nil and GG.OnFire[i][UnitID] ~= nil and i ~= 1 and y ~= 1 then
                    table.remove(GG.OnFire, i)
                    i = i - 1
                    y = y - 1
                    countTen = countTen + 1
                end
                if countTen == 10 then break end
            end
        end
    end
end
