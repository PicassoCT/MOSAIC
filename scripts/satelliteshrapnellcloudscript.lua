include "createCorpse.lua"
include "lib_OS.lua"
include "lib_UnitScript.lua"
include "lib_Animation.lua"
include "lib_Build.lua"

TablesOfPiecesGroups = {}

function script.HitByWeapon(x, z, weaponDefID, damage) end

GameConfig = getGameConfig()

center = piece "center"
Icon = piece "Icon"
Packed = piece "Packed"

function script.Create()
    Spin(center, y_axis, math.rad(1), 0.5)
    if Icon then
        Move(Icon, y_axis, GameConfig.SatelliteIconDistance, 0);
        Show(Icon)
    end
    TablesOfPiecesGroups = getPieceTableByNameGroups(false, true)
    hideT(TablesOfPiecesGroups["Particle"])
    StartThread(dealDamageAnimate)
    Spring.SetUnitAlwaysVisible(unitID, true)
end

function script.Killed(recentDamage, _)
    for i = 1, #TablesOfPiecesGroups["Particle"] do
        Explode(TablesOfPiecesGroups["Particle"][i], SFX.FIRE + SFX.FALL)
    end
    return 1
end

function getRandShrapMoveVal()
    factor = 10
    return math.random(-GameConfig.SatelliteShrapnellDistance * factor,
                       GameConfig.SatelliteShrapnellDistance * factor)
end

function dealDamageAnimate()
    Explode(center, SFX.SHATTER)
    Hide(center)
    Hide(Icon)
    Hide(Packed)
    spinRand(center, -42, 42, 42)
    process(TablesOfPiecesGroups["Particle"],
            function(id) spinRand(id, -42, 42, 42) end)
    StartThread(doDamageCyclic)

    process(TablesOfPiecesGroups["Particle"], function(id)
        StartThread(function(id)
            while true do
                Show(id)
                mP(id, getRandShrapMoveVal(), getRandShrapMoveVal(),
                   getRandShrapMoveVal(), 2048)
                WaitForMoves(id)
                Hide(id)
                mP(id, getRandShrapMoveVal(), getRandShrapMoveVal(),
                   getRandShrapMoveVal(), 0)
                Sleep(100)
            end
        end, id)
    end)
    while true do Sleep(1000) end
end

function doDamageCyclic()
    local LifeTime = GameConfig.SatelliteShrapnellLifeTime
    local DamagePerSecondTenth = GameConfig.SatelliteShrapnellDamagePerSecond /
                                     100
    local SatelliteShrapnellDistance = GameConfig.SatelliteShrapnellDistance

    Spring.SetUnitNoSelect(unitID, true)
    while LifeTime > 0 do
        process(getAllNearUnit(unitID, SatelliteShrapnellDistance),
                function(id) if id ~= unitID then return id end end,
                function(id)
            Spring.AddUnitDamage(id, DamagePerSecondTenth)
        end)
        Sleep(100)
        LifeTime = LifeTime - 100
    end
    Spring.DestroyUnit(unitID, false, true)
end
