-- NOTES:
--   games that rely on custom model shaders are SOL
--
--   this config-structure silently assumes a LightDef
--   does not get used by more than one WeaponDef, but
--   copy-pasting is always an option (see below)
--
--   for projectile lights, ttl values are arbitrarily
--   large to make the lights survive until projectiles
--   die (see ProjectileDestroyed() for the reason why)
--
--   for "propelled" projectiles (rockets/missiles/etc)
--   ttls should be the actual ttl-values so attached
--   lights die when their "engine" cuts out, but this
--   gets complex (eg. flighttime is not available)
--
--   general rule: big things take priority over small
--   things, for example nuke explosion > bertha shell
--   impact > mobile artillery shell impact (and trail
--   lights should obey the same relation)
--
--   Explosion() occurs before ProjectileDestroyed(),
--   so for best effect maxDynamic{Map, Model}Lights
--   should be >= 2 (so there is "always" room to add
--   the explosion light while a projectile light has
--   not yet been removed)
--   we work around this by giving explosion lights a
--   (slighly) higher priority than the corresponding
--   projectile lights

VFS.Include("scripts/lib_mosaic.lua")
local allDynLightDefs = include("LuaRules/Configs/gfx_dynamic_lighting_defs.lua")
local modDynLightDefs = allDynLightDefs[Game.gameShortName] or {}
local weaponLightDefs = modDynLightDefs.weaponLightDefs or {}
local buildingLightDefs = modDynLightDefs.buildingLightDefs or {}

-- shared synced/unsynced globals
local PROJECTILE_GENERATED_EVENT_ID = 10001
local PROJECTILE_DESTROYED_EVENT_ID = 10002
local PROJECTILE_EXPLOSION_EVENT_ID = 10003
local UNIT_CREATED_EVENT_ID         = 10004
local UNIT_DESTROYED_EVENT_ID       = 10005
local UPDATE_LIGHTS_9SEC_EVENT_ID   = 10006
local hologramTypes = getHologramTypes()

if (gadgetHandler:IsSyncedCode()) then
    -- register/deregister for the synced Projectile*/Explosion call-ins
    function gadget:Initialize()
        for weaponDefName, _ in pairs(weaponLightDefs) do
            local weaponDef = WeaponDefNames[weaponDefName]

            if (weaponDef ~= nil) then
                Script.SetWatchWeapon(weaponDef.id, true)
            end
        end
    end
    function gadget:Shutdown()
        for weaponDefName, _ in pairs(weaponLightDefs) do
            local weaponDef = WeaponDefNames[weaponDefName]

            if (weaponDef ~= nil) then
                Script.SetWatchWeapon(weaponDef.id, false)
            end
        end
    end
    function gadget:UnitCreated(unitID, unitDefID, unitTeam, builderID)
        if hologramTypes[unitDefID] then
            SendToUnsynced(UNIT_CREATED_EVENT_ID, unitID, unitDefID, unitTeam)
        end
    end
    function gadget:UnitDestroyed(unitID, unitDefID, unitTeam, attackerID)
        if hologramTypes[unitDefID] then
            SendToUnsynced(UNIT_DESTROYED_EVENT_ID, unitID, unitDefID, unitTeam)
        end
    end
    function gadget:GameFrame(frame)
        if frame % 270 == 0 then
        SendToUnsynced(UPDATE_LIGHTS_9SEC_EVENT_ID, frame)
        end
    end

    function gadget:ProjectileCreated(projectileID, projectileOwnerID,
                                      projectileWeaponDefID)
        SendToUnsynced(PROJECTILE_GENERATED_EVENT_ID, projectileID,
                       projectileOwnerID, projectileWeaponDefID)
    end

    function gadget:ProjectileDestroyed(projectileID)
        SendToUnsynced(PROJECTILE_DESTROYED_EVENT_ID, projectileID)
    end

    function gadget:Explosion(weaponDefID, posx, posy, posz, ownerID)
        SendToUnsynced(PROJECTILE_EXPLOSION_EVENT_ID, weaponDefID, posx, posy,
                       posz)
        return false -- noGFX
    end

else

    local projectileLightDefs = {} -- indexed by unitDefID
    local explosionLightDefs = {} -- indexed by weaponDefID
    local buildingLightDefs = {} -- indexed by buildingDefID
    local projectileLights = {} -- indexed by projectileID
    local explosionLights = {} -- indexed by "explosionID"
    local buildingLights = {} -- indexed by "unitID"

    local unsyncedEventHandlers = {}

    local SpringGetProjectilePosition = Spring.GetProjectilePosition
    local SpringAddMapLight = Spring.AddMapLight
    local SpringAddModelLight = Spring.AddModelLight
    local SpringSetMapLightTrackingState = Spring.SetMapLightTrackingState
    local SpringSetModelLightTrackingState = Spring.SetModelLightTrackingState
    local SpringUpdateMapLight = Spring.UpdateMapLight
    local SpringUpdateModelLight = Spring.UpdateModelLight

    local function LoadLightDefs()
        -- type(v) := {[1] = number, [2] = number, [3] = number}
        -- type(s) := number
        local function vector_scalar_add(v, s)
            return {v[1] + s, v[2] + s, v[3] + s}
        end
        local function vector_scalar_mul(v, s)
            return {v[1] * s, v[2] * s, v[3] * s}
        end
        local function vector_scalar_div(v, s)
            return {v[1] / s, v[2] / s, v[3] / s}
        end

        for weaponDefName, weaponLightDef in pairs(weaponLightDefs) do
            local weaponDef = WeaponDefNames[weaponDefName]
            local projectileLightDef = weaponLightDef.projectileLightDef
            local explosionLightDef = weaponLightDef.explosionLightDef

            if (weaponDef ~= nil) then
                projectileLightDefs[weaponDef.id] = projectileLightDef
                explosionLightDefs[weaponDef.id] = explosionLightDef

                -- NOTE: these rates are not sensible if the decay-type is exponential
                -- Spring.Echo("pld :" .. projectileLightDef)
                -- Spring.Echo("pld.dft :" .. projectileLightDef.decayFunctionType)

                if (projectileLightDef ~= nil and
                    projectileLightDef.decayFunctionType ~= nil) then
                    projectileLightDefs[weaponDef.id].ambientDecayRate =
                        vector_scalar_div(
                            projectileLightDef.ambientColor or {0.0, 0.0, 0.0},
                            projectileLightDef.ttl or 1.0)
                    projectileLightDefs[weaponDef.id].diffuseDecayRate =
                        vector_scalar_div(
                            projectileLightDef.diffuseColor or {0.0, 0.0, 0.0},
                            projectileLightDef.ttl or 1.0)
                    projectileLightDefs[weaponDef.id].specularDecayRate =
                        vector_scalar_div(
                            projectileLightDef.specularColor or {0.0, 0.0, 0.0},
                            projectileLightDef.ttl or 1.0)
                end

                if (explosionLightDef ~= nil and
                    explosionLightDef.decayFunctionType ~= nil) then
                    explosionLightDefs[weaponDef.id].ambientDecayRate =
                        vector_scalar_div(
                            explosionLightDef.ambientColor or {0.0, 0.0, 0.0},
                            explosionLightDef.ttl or 1.0)
                    explosionLightDefs[weaponDef.id].diffuseDecayRate =
                        vector_scalar_div(
                            explosionLightDef.diffuseColor or {0.0, 0.0, 0.0},
                            explosionLightDef.ttl or 1.0)
                    explosionLightDefs[weaponDef.id].specularDecayRate =
                        vector_scalar_div(
                            explosionLightDef.specularColor or {0.0, 0.0, 0.0},
                            explosionLightDef.ttl or 1.0)
                end
            end
        end 

        for buildingName, buildingLightDef in pairs(buildingLightDefs) do
            local buildingDef = UnitDefNames[buildingName]
            local holoLightDef = buildingLightDef.holoLightDefs

            if (buildingDef ~= nil) then
                buildingLightDefs[buildingDef] = holoLightDef
   
                -- NOTE: these rates are not sensible if the decay-type is exponential
                -- Spring.Echo("pld :" .. projectileLightDef)
                -- Spring.Echo("pld.dft :" .. projectileLightDef.decayFunctionType)

                if (buildingLightDef ~= nil and
                    buildingLightDef.decayFunctionType ~= nil) then
                    buildingLightDefs[buildingDef].ambientDecayRate =
                        vector_scalar_div(
                            buildingLightDef.ambientColor or {0.0, 0.0, 0.0},
                            buildingLightDef.ttl or 1.0)
                    buildingLightDefs[buildingDef].diffuseDecayRate =
                        vector_scalar_div(
                            buildingLightDef.diffuseColor or {0.0, 0.0, 0.0},
                            buildingLightDef.ttl or 1.0)
                    buildingLightDefs[buildingDef].specularDecayRate =
                        vector_scalar_div(
                            buildingLightDef.specularColor or {0.0, 0.0, 0.0},
                            buildingLightDef.ttl or 1.0)
                end
            end
        end
    end
    
        function getDayTime(frame)
            local DAYLENGTH = 28800
            morningOffset = (DAYLENGTH / 2)
            Frame = (frame + morningOffset) % DAYLENGTH
            percent = Frame / DAYLENGTH
            hours = math.floor((Frame / DAYLENGTH) * 24)
            minutes = math.ceil((((Frame / DAYLENGTH) * 24) - hours) * 60)
            seconds = 60 - ((24 * 60 * 60 - (hours * 60 * 60) - (minutes * 60)) % 60)
            return hours, minutes, seconds, percent 
        end

    local function isNight(frame)
        hours, minutes, seconds, percent = getDayTime(frame)         
        return hours > 19 and hours < 6, percent
    end
    
    local function mixColor(coloarA, colorB, factor)
        return {
                coloarA[1] * factor + colorB[1] * (1.0 -factor), 
                coloarA[2] * factor + colorB[2] * (1.0 -factor), 
                coloarA[3] * factor + colorB[3] * (1.0 -factor)
                }
    end

    local function mixPulseColors(colorsArray, id, everyNinthFrame, percent)
        local startIndex = (math.ceil(id + percent * everyNinthFrame/(28800*0.5)) % #colorsArray) + 1
        local endIndex = (startIndex % #colorsArray) + 1
        return mixColor(colorsArray[startIndex], colorsArray[endIndex], percent)
    end

    local function UpdateNightLightsEveryNineSeconds(everyNinthFrame)
        local boolIsNight, percent = isNight(everyNinthFrame) 
        if boolIsNight == true then
            for id, defID in pairs(holoLightUnitRegister) do
                if defID then
                    local name = UnitDefs[defID].name
                    local buildingLightDef = buildingLightDefs[name]

                    buildingLightDef.diffuseColor = mixPulseColors(buildingLightDef.diffuseColors, id, everyNinthFrame, percent)
                    buildingLightDef.specularColor = mixPulseColors(buildingLightDef.specularColors, id, everyNinthFrame, percent)
                    buildingLights[id] = 
                    {
                        [1] = SpringAddMapLight(buildingLightDef),
                        [2] = SpringAddModelLight(buildingLightDef)
                    }


                    SpringSetMapLightTrackingState(buildingLights[id][1],id, false, false)
                    SpringSetModelLightTrackingState(buildingLights[id][2],id, false, false)
                end
            end
        end
    end

    holoLightUnitRegister = {}
    local function UnitCreated(unitID, unitDefId, teamID)
        local buildingLightDef =  buildingLightDefs[unitDefId]
        if (buildingLightDef == nil) then return end
        holoLightUnitRegister[unitID] = {defID = unitDefID, timeOffsetFrames = unitID*100 }
    end

    local function UnitDestroyed(unitID, unitDefId, teamID)
        if holoLightUnitRegister[unitID] then
            holoLightUnitRegister[unitID] = nil
        end
    end

    local function ProjectileCreated(projectileID, projectileOwnerID,
                                     projectileWeaponDefID)
        local projectileLightDef = projectileLightDefs[projectileWeaponDefID]

        if (projectileLightDef == nil) then return end

        projectileLights[projectileID] =
            {
                [1] = SpringAddMapLight(projectileLightDef),
                [2] = SpringAddModelLight(projectileLightDef)             
            }


        SpringSetMapLightTrackingState(projectileLights[projectileID][1],
                                       projectileID, true, false)
        SpringSetModelLightTrackingState(projectileLights[projectileID][2],
                                         projectileID, true, false)
    end

    local function ProjectileDestroyed(projectileID)
        if (projectileLights[projectileID] == nil) then return end

        -- set the TTL to 0 upon the projectile's destruction
        -- (since all projectile lights start with arbitrarily
        -- large values, which ensures we don't have to update
        -- ttls manually to keep our lights alive) so the light
        -- gets marked for removal
        local projectileLightPos = {SpringGetProjectilePosition(projectileID)} -- {ppx, ppy, ppz}
        local projectileLightTbl = {position = projectileLightPos, ttl = 0}

        -- NOTE: unnecessary (death-dependency system take care of it)
        -- SpringSetMapLightTrackingState(projectileLights[projectileID][1], projectileID, false, false)
        -- SpringSetModelLightTrackingState(projectileLights[projectileID][2], projectileID, false, false)

        SpringUpdateMapLight(projectileLights[projectileID][1],
                             projectileLightTbl)
        SpringUpdateModelLight(projectileLights[projectileID][2],
                               projectileLightTbl)

        -- get rid of this light
        projectileLights[projectileID] = nil
    end

    local function ProjectileExplosion(weaponDefID, posx, posy, posz)
        local explosionLightDef = explosionLightDefs[weaponDefID]

        if (explosionLightDef == nil) then return end

        local explosionLightAlt = explosionLightDef.altitudeOffset or 0.0
        local explosionLightPos = {posx, posy + explosionLightAlt, posz}
        -- NOTE: explosions are non-tracking, so need to supply position
        -- FIXME:? explosion "ID"'s would require bookkeeping in :Update
        local explosionLightTbl = {position = explosionLightPos}
        local numExplosions = 1

        explosionLights[numExplosions] =
            {
                [1] = SpringAddMapLight(explosionLightDef),
                [2] = SpringAddModelLight(explosionLightDef)
            }

        SpringUpdateMapLight(explosionLights[numExplosions][1],
                             explosionLightTbl)
        SpringUpdateModelLight(explosionLights[numExplosions][2],
                               explosionLightTbl)
    end

    function gadget:GetInfo()
        return {
            name = "gfx_dynamic_lighting.lua",
            desc = "dynamic lighting in the Spring RTS engine",
            author = "Kloot",
            date = "January 15, 2011",
            license = "GPL v2",
            enabled = true
        }
    end

    function gadget:Initialize()
        local maxMapLights = Spring.GetConfigInt("MaxDynamicMapLights")
        local maxMdlLights = Spring.GetConfigInt("MaxDynamicModelLights")

        if (maxMapLights <= 0 and maxMdlLights <= 0) then
            Spring.Echo("[" .. (self:GetInfo()).name ..
                            "] client has disabled dynamic lighting")
            gadgetHandler:RemoveGadget(self)
            return
        end

        unsyncedEventHandlers[PROJECTILE_GENERATED_EVENT_ID] = ProjectileCreated
        unsyncedEventHandlers[PROJECTILE_DESTROYED_EVENT_ID] = ProjectileDestroyed
        unsyncedEventHandlers[PROJECTILE_EXPLOSION_EVENT_ID] = ProjectileExplosion
        unsyncedEventHandlers[UNIT_CREATED_EVENT_ID]         = UnitCreated
        unsyncedEventHandlers[UNIT_DESTROYED_EVENT_ID]       = UnitDestroyed
        unsyncedEventHandlers[UPDATE_LIGHTS_9SEC_EVENT_ID]   = UpdateNightLightsEveryNineSeconds

        -- fill the {projectile, explosion}LightDef tables
        LoadLightDefs()
    end

    function gadget:RecvFromSynced(eventID, arg0, arg1, arg2, arg3)
        local eventHandler = unsyncedEventHandlers[eventID]

        if (eventHandler ~= nil) then
            eventHandler(arg0, arg1, arg2, arg3)
        end
    end
end

