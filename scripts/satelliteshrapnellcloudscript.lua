include "createCorpse.lua"
include "lib_OS.lua"
include "lib_UnitScript.lua"
include "lib_Animation.lua"
--include "lib_Build.lua"

TablesOfPiecesGroups = {}

function script.HitByWeapon(x, z, weaponDefID, damage) end

GameConfig = getGameConfig()
local spGetUnitDefID = Spring.GetUnitDefID
local myDefID = spGetUnitDefID(unitID)
center = piece "center"
Icon = piece "Icon"
Packed = piece "Packed"
Line001 = piece "Line001"

function script.Create()
    Hide(Line001)
    Spin(center, y_axis, math.rad(1), 0.5)
    if Icon then
        Move(Icon, y_axis, GameConfig.Satellite.iconDistance, 0);
        Show(Icon)
    end
    TablesOfPiecesGroups = getPieceTableByNameGroups(false, true)
    hideT(TablesOfPiecesGroups["Particle"])
    StartThread(dealDamageAnimate)
    Spring.SetUnitAlwaysVisible(unitID, true)
    Spring.SetUnitNoSelect(unitID,true)
end

function script.Killed(recentDamage, _)
    return 1
end

function getRandShrapMoveVal()
    factor = 10
    return math.random(-GameConfig.Satellite.shrapnellDistance * factor,
                       GameConfig.Satellite.shrapnellDistance * factor)
end
activeParticles = {}
function dealDamageAnimate()
    Explode(center, SFX.SHATTER)
    Hide(center)
    Hide(Icon)
    Hide(Packed)
    spinRand(center, -42, 42, 42)
    foreach(TablesOfPiecesGroups["Particle"],
            function(id) spinRand(id, -42, 42, 42) end)
    StartThread(doDamageCyclic)

    foreach(TablesOfPiecesGroups["Particle"], 
        function(id)
        activeParticles[id] = "active"
        StartThread(
            function(id)
            while activeParticles[id] == "active" do
                Show(id)
                mP(id, getRandShrapMoveVal(), getRandShrapMoveVal(), getRandShrapMoveVal(), 2048)
                WaitForMoves(id)
                Hide(id)
                mP(id, getRandShrapMoveVal(), getRandShrapMoveVal(), getRandShrapMoveVal(), 0)
                Sleep(100)
            end         
            if activeParticles[id] == "cooked" then
                EmitSfx(id, 1024)
            else
                EmitSfx(id, 1025)
            end
            end, id)
        end)
    while true do Sleep(1000) end
end

function doDamageCyclic()
    local LifeTime = GameConfig.Satellite.shrapnellLifeTime
    local DamagePerSecondTenth = GameConfig.Satellite.shrapnellDamagePerSecond / 100
    local SatelliteShrapnellDistance = GameConfig.Satellite.shrapnellDistance

    Spring.SetUnitNoSelect(unitID, true)
    while LifeTime > 0 do
        foreach(getAllNearUnitSpherical(unitID, SatelliteShrapnellDistance),
                function(id) 
                    defID = spGetUnitDefID(id)
                    if id ~= unitID and defID ~= myDefID then 
                        return id end 
                end,
                function(id)
                    Spring.AddUnitDamage(id, DamagePerSecondTenth)
                end)
        Sleep(100)
        LifeTime = LifeTime - 100

        hp, mHp = Spring.GetUnitHealth(unitID)
        factorHealth= hp/mHp
        factorLifetime = LifeTime/GameConfig.SatelliteShrapnellLifeTime
        smallestFactor = 1.0 - math.min(factorHealth, factorLifetime)
        for i=1, (#TablesOfPiecesGroups["Particle"]*smallestFactor) do
            if factorHealth < factorLifetime then
                activeParticles[TablesOfPiecesGroups["Particle"][i]] = "cooked"
            else
                activeParticles[TablesOfPiecesGroups["Particle"][i]] = "meteor"
            end
        end
    end
    Spring.DestroyUnit(unitID, false, true)
end
