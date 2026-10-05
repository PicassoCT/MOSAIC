include "createCorpse.lua"
include "lib_OS.lua"
include "lib_UnitScript.lua"
include "lib_Animation.lua"

local TablesOfPiecesGroups = {}
local GameConfig = getGameConfig()
local spGetUnitDefID = Spring.GetUnitDefID

center = piece "center"
Icon = piece "Icon"
Packed = piece "Packed"
Line001 = piece "Line001"

function script.HitByWeapon(x, z, weaponDefID, damage) end

local fragmentState = {}
local retiredFragments = {}

local function makeFragmentState(pieceID, index)
    local sign = (index % 2 == 0) and 1 or -1
    return {
        phase = math.rad((index * 137 + unitID * 17) % 360),
        angularSpeed = math.rad(4 + ((index * 11 + unitID) % 15)) * sign,
        radius = 650 + ((index * 313 + unitID * 7) % 2600),
        expansion = 10 + ((index * 29 + unitID) % 45),
        eccentricity = 0.55 + ((index * 17) % 40) / 100,
        verticalAmplitude = 120 + ((index * 47) % 650),
        verticalPhase = math.rad((index * 83) % 360),
        verticalRate = 0.27 + ((index * 7) % 20) / 100,
        spinX = math.rad(5 + ((index * 19) % 55)) * sign,
        spinY = math.rad(7 + ((index * 23) % 67)) * -sign,
        spinZ = math.rad(3 + ((index * 31) % 43)) * sign,
    }
end

local function initializeFragments()
    local particles = TablesOfPiecesGroups["Particle"] or {}
    for i = 1, #particles do
        local pieceID = particles[i]
        fragmentState[pieceID] = makeFragmentState(pieceID, i)
        retiredFragments[pieceID] = false
        Show(pieceID)

        local f = fragmentState[pieceID]
        Spin(pieceID, x_axis, f.spinX, math.abs(f.spinX) * 0.35)
        Spin(pieceID, y_axis, f.spinY, math.abs(f.spinY) * 0.35)
        Spin(pieceID, z_axis, f.spinZ, math.abs(f.spinZ) * 0.35)
    end
end

local function animateFragments(elapsedSeconds, lifeFactor)
    local particles = TablesOfPiecesGroups["Particle"] or {}
    local retained = math.ceil(#particles * math.max(0, math.min(1, lifeFactor)))

    for i = 1, #particles do
        local pieceID = particles[i]
        if i <= retained and not retiredFragments[pieceID] then
            local f = fragmentState[pieceID]
            local angle = f.phase + elapsedSeconds * f.angularSpeed
            local radius = f.radius + elapsedSeconds * f.expansion

            -- A shearing ellipse reads as shared orbital momentum rather than
            -- Brownian motion. The slow secondary sine tilts the debris plane.
            local x = math.cos(angle) * radius
            local z = math.sin(angle) * radius * f.eccentricity
            local y = math.sin(
                f.verticalPhase + elapsedSeconds * f.verticalRate
            ) * f.verticalAmplitude

            Move(pieceID, x_axis, x, math.max(30, f.expansion * 6))
            Move(pieceID, y_axis, y, math.max(20, f.verticalAmplitude * 0.6))
            Move(pieceID, z_axis, z, math.max(30, f.expansion * 6))
            Show(pieceID)
        elseif not retiredFragments[pieceID] then
            retiredFragments[pieceID] = true
            Hide(pieceID)
            EmitSfx(pieceID, 1025)
        end
    end
end

local function damageNearbySatellites()
    local radius = GameConfig.military.satellites.shrapnel.radius
    local damagePerTick =
        GameConfig.military.satellites.shrapnel.damagePerSecond / 100

    foreach(
        getAllNearUnitSpherical(unitID, radius),
        function(id)
            local defID = spGetUnitDefID(id)
            if id ~= unitID and defID ~= unitDefID then
                return id
            end
        end,
        function(id)
            Spring.AddUnitDamage(id, damagePerTick)
        end
    )
end

function dealDamageAnimate()
    Explode(center, SFX.SHATTER)
    Hide(center)
    Hide(Icon)
    Hide(Packed)

    initializeFragments()

    local lifetime = GameConfig.military.satellites.shrapnel.lifetimeMs
    local remaining = lifetime
    local elapsed = 0

    Spring.SetUnitNoSelect(unitID, true)
    Spring.SetUnitAlwaysVisible(unitID, true)

    while remaining > 0 do
        local hp, maxHp = Spring.GetUnitHealth(unitID)
        if not hp or not maxHp then return end

        local healthFactor = math.max(0, math.min(1, hp / maxHp))
        local timeFactor = math.max(0, remaining / lifetime)
        local lifeFactor = math.min(healthFactor, timeFactor)

        animateFragments(elapsed / 1000, lifeFactor)
        damageNearbySatellites()

        Spring.SetUnitRulesParam(
            unitID,
            "orbital_debris_life",
            lifeFactor,
            {public = true}
        )

        Sleep(100)
        elapsed = elapsed + 100
        remaining = remaining - 100
    end

    local particles = TablesOfPiecesGroups["Particle"] or {}
    for i = 1, #particles do
        local pieceID = particles[i]
        if not retiredFragments[pieceID] then
            retiredFragments[pieceID] = true
            Hide(pieceID)
            EmitSfx(pieceID, 1025)
        end
    end

    Spring.DestroyUnit(unitID, false, true)
end

function script.Create()
    Hide(Line001)
    Hide(Icon)
    TablesOfPiecesGroups = getPieceTableByNameGroups(false, true)
    hideT(TablesOfPiecesGroups["Particle"])
    Spring.SetUnitAlwaysVisible(unitID, true)
    Spring.SetUnitNoSelect(unitID, true)
    StartThread(dealDamageAnimate)
end

function script.Killed(recentDamage, _)
    return 1
end
