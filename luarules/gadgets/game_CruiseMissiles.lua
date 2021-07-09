function gadget:GetInfo()
    return {
        name = "CruiseMissile Management",
        desc = "SetProjectileTarget etc",
        author = "PicassoCT",
        date = "Mar 2020",
        license = "later horses dont be mean.",
        layer = 0,
        enabled = true --      loaded by default?
    }
end

if (not gadgetHandler:IsSyncedCode()) then return end

VFS.Include("scripts/lib_OS.lua")
VFS.Include("scripts/lib_UnitScript.lua")
VFS.Include("scripts/lib_Animation.lua")
VFS.Include("scripts/lib_Build.lua")
VFS.Include("scripts/lib_mosaic.lua")
GameConfig = getGameConfig()

local cruiseMissileWeapons = {}
cruiseMissileWeapons[WeaponDefNames["cm_airstrike"].id] = true
cruiseMissileWeapons[WeaponDefNames["cm_walker"].id] = true
cruiseMissileWeapons[WeaponDefNames["cm_antiarmor"].id] = true
cruiseMissileWeapons[WeaponDefNames["cm_turret_ssied"].id] = true
TruckTypeTable = getTruckTypeTable(UnitDefs)

onImpact = {
    [WeaponDefNames["cm_airstrike"].id] = function(projID, tx, ty, tz)
        Spring.SetProjectileTarget(projID, tx, Spring.GetGroundHeight(tx, tz), tz)
    end,
    [WeaponDefNames["cm_walker"].id] = function(projID, tx, ty, tz)
        px, py, pz = Spring.GetProjectilePosition(projID)
        teamID = Spring.GetProjectileTeamID(projID)
        for i = 1, 2, 1 do
            unitID = Spring.CreateUnit("ground_walker_mg", px, py, pz, 1, teamID)
            giveParachutToUnit(unitID, px, py, pz)
        end
        Spring.DeleteProjectile(projID)
    end,
    [WeaponDefNames["cm_antiarmor"].id] = function(projID, tx, ty, tz)
        Spring.SetProjectileTarget(projID, tx, Spring.GetGroundHeight(tx, tz),  tz)
    end,
    [WeaponDefNames["cm_turret_ssied"].id] = function(projID)
        px, py, pz = Spring.GetProjectilePosition(projID)
        teamID = Spring.GetProjectileTeamID(projID)
         Spring.CreateUnit("air_copter_ssied", px, py, pz, 1, teamID)
         Spring.CreateUnit("air_copter_ssied", px, py, pz, 1, teamID)
        unitID = Spring.CreateUnit("ground_turret_mg", px, py, pz, 1, teamID)
        giveParachutToUnit(unitID, px, py, pz)

        Spring.DeleteProjectile(projID)
    end
}

onLastPointBeforeImpactSetTargetTo = {
    [WeaponDefNames["cm_airstrike"].id] = function(projID) end,
    [WeaponDefNames["cm_walker"].id] = function(projID) end,
    [WeaponDefNames["cm_antiarmor"].id] = function(projID) 
             tx,ty,tz =  getProjectileTargetXYZ(projID)
             px, py, pz = Spring.GetProjectilePosition(projID)
                    teamID = Spring.GetProjectileTeamID(projID)
                    projectileTeamID = Spring.GetProjectileTeamID(projID)
                    collateralTable = {}
                    allHardTargetsInRange = process(
                                            getAllInCircle(tx,tz, GameConfig.cruiseMissileAntiArmorDroplettRange),
                                            function(id)
                                                teamID = Spring.GetUnitTeam(id)
                                                defID = Spring.GetUnitDefID(id)

                                                if teamID == gaiaTeamID and TruckTypeTable[defID] then
                                                    collateralTable[#collateralTable+1] = id
                                                    return
                                                end

                                                if teamID == projectileTeamID then return end

                                                if UnitDefs[defID].speed > 0 then
                                                    return id
                                                end
                                            end,
                                            function(id)
                                                hp, maxHp = Spring.GetUnitHealth(id)
                                                if maxHp > 1000 then 
                                                    return id
                                                end
                                            end)

                    v = {x=0, y= 1, z= 0}

                    for i = 1, 6 do
                        javelinProjID = Spring.SpawnProjectile(WeaponDefNames["javelinrocket"].id, {
                            pos = {
                                px + math.random(-2, 2), py + math.random(0, 5),
                                pz + math.random(-2, 2)
                            },
                            ["end"] = {tx, ty, tz},
                            -- speed = {number x, number y, number z},
                            spread = {10, 10, 10},
                            speed = { v.x, v.y, v.z },
                            -- owner = pOwner,
                            team = teamID,
                            ttl = 30 * 30,
                            error = {0, 5, 0},
                            maxRange = 1200,
                            gravity = Game.gravity,
                            startAlpha = 1,
                            endAlpha = 1,
                            model = "air_copter_antiarmor_projectile.s3o"
                        })        
                        Spring.SetProjectileAlwaysVisible(javelinProjID, true)
                        if #allHardTargetsInRange > 1 then
                            assert(Spring.SetProjectileTarget(javelinProjID, allHardTargetsInRange[((i-1) % #allHardTargetsInRange)+  1], 'u') == true)
                        elseif #allHardTargetsInRange > 0 then
                            assert(Spring.SetProjectileTarget(javelinProjID, allHardTargetsInRange[1], 'u') == true)
                        else
                            if #collateralTable > 0 then
                                 if #collateralTable > 1 then
                                    assert(Spring.SetProjectileTarget(javelinProjID, collateralTable[((i-1) % #collateralTable)+  1], 'u') == true)
                                elseif #collateralTable > 0 then
                                    assert(Spring.SetProjectileTarget(javelinProjID, collateralTable[1], 'u') == true)
                                end
                            else
                                ax, ay, az = tx + math.random(50,512)*randSign(), 0, tz + math.random(50,512)*randSign()
                                Spring.SetProjectileTarget(projID, ax, Spring.GetGroundHeight(ax, az),  az)
                            end
                        end
                    end
            end,    
[WeaponDefNames["cm_turret_ssied"].id] = function(projID) end
}

function getWeapondefByName(name) return WeaponDefs[WeaponDefNames[name].id] end

local SSied_Def = getWeapondefByName("ssied")
local CM_Def = getWeapondefByName("cruisemissile")

assert(CM_Def)
assert(CM_Def.range)
assert(CM_Def.projectilespeed)

local redirectProjectiles = {} -- [frame][projectileID] = table with .targetType .targetX .targetY .targetZ .targetID

function gadget:Initialize()
    Spring.Echo(GetInfo().name .. " Initialization started")
    for id, boolActive in pairs(cruiseMissileWeapons) do
        Script.SetWatchWeapon(id, true)
    end
    Spring.Echo(GetInfo().name .. " Initialization ended")
end

cruiseMissileFunction = function(evtID, frame, persPack, startFrame)
    projID = persPack.projID
    px, py, pz = Spring.GetProjectilePosition(projID)

    if not px then
        -- echo("Projectile died")
        return nil, persPack
    end

    -- check if close to next target
    nextTarget = persPack.redirectList[persPack.redirectIndex]
    dist = distance(px, py, pz, nextTarget.targetX, nextTarget.targetY,
                    nextTarget.targetZ)

    -- if close to target
    if dist < 50 then
        -- if lasttarget
        if persPack.redirectIndex == #persPack.redirectList then
            -- if pre last target
            persPack.on_Impact(projID, nextTarget.targetX, nextTarget.targetY,
                               nextTarget.targetZ)
            -- echo("Projectile ready to die")
            return nil, persPack
        elseif persPack.redirectIndex + 1 == #persPack.redirectList then
            persPack.on_LastPointBeforeImpactSetTargetTo(projID)
        end

        persPack.redirectIndex = math.min(#persPack.redirectList,
                                          persPack.redirectIndex + 1)
        -- echo("Setting next target:" .. frame .. " to target " .. persPack.redirectIndex)
        nextTarget = persPack.redirectList[persPack.redirectIndex]
        dist = distance(px, py, pz, nextTarget.targetX, nextTarget.targetY,
                        nextTarget.targetZ)
    end

    FramesToTarget = math.max(2, math.ceil(dist / CM_Def.projectilespeed) - 2)
    setTargetTable(projID, persPack.redirectList[persPack.redirectIndex])
    -- echo("game_cruiseMissiles:" .. (FramesToTarget / 30) .. " seconds till waypoint " .. persPack.redirectIndex)
    return frame + FramesToTarget, persPack
end

redirectedProjectiles = {}
function gadget:ProjectileCreated(proID, proOwnerID, proWeaponDefID)
    if (cruiseMissileWeapons[proWeaponDefID] or
        cruiseMissileWeapons[Spring.GetProjectileDefID(proID)]) then
        -- echo("Cruise Missile registered")
        redirectedProjectiles[proID] = proWeaponDefID

        local tx, ty, tz = getProjectileTargetXYZ(proID)
        local x, y, z = Spring.GetUnitPosition(proOwnerID)
        local resolution = 10
        local preCog = 1
        redirectList = {}

        for i = 1, resolution - 1, 1 do
            rx, rz = mix(tx, x, i / resolution), mix(tz, z, i / resolution)
            interpolate_Y = 0
            for add = 0, preCog, 1 do
                it = math.max(1, math.min(resolution, i + add))
                ix, iz = mix(tx, x, it / resolution),
                         mix(tz, z, it / resolution)
                interpolate_Y = math.max(Spring.GetSmoothMeshHeight(ix, iz),
                                         interpolate_Y)
            end

            redirectList[#redirectList + 1] =
                {
                    targetX = rx,
                    targetY = interpolate_Y +
                        GameConfig.CruiseMissilesHeightOverGround,
                    targetZ = rz,
                    targetType = string.byte("g")
                }
        end

        GG.EventStream:CreateEvent(cruiseMissileFunction, {
            -- persistance Pack
            redirectIndex = 1,
            redirectList = redirectList,
            projID = proID,
            weaponDefID = proWeaponDefID,
            on_Impact = onImpact[proWeaponDefID],
            on_LastPointBeforeImpactSetTargetTo = onLastPointBeforeImpactSetTargetTo[proWeaponDefID]
        }, Spring.GetGameFrame() + 1)

        return true
    end
end

function getProjectileTargetXYZ(proID)
    local targetTypeInt, target = Spring.GetProjectileTarget(proID)
    if targetTypeInt == string.byte("g") then
        return target[1], target[2], target[3]
    end
    if targetTypeInt == string.byte("u") then
        return Spring.GetUnitPosition(target)
    end
    if targetTypeInt == string.byte("f") then
        return Spring.GetFeaturePosition(target)
    end
    if targetTypeInt == string.byte("p") then
        return Spring.GetProjectilePosition(target)
    end
end

function addProjectileRedirect(proID, targetTable, delay, boolImpact)
    local f = Spring.GetGameFrame() + delay
    if not redirectProjectiles[f] then redirectProjectiles[f] = {} end

    redirectProjectiles[f][proID] = targetTable
end

function setTargetTable(proID, targetTable)
    if targetTable.targetType == string.byte("g") then
        Spring.SetProjectileTarget(proID, targetTable.targetX,
                                   targetTable.targetY, targetTable.targetZ)
    else
        Spring.SetProjectileTarget(proID, targetTable.targetID,
                                   targetTable.targetType)
    end
end
