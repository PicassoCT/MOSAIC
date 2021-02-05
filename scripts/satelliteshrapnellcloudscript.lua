include "createCorpse.lua"
include "lib_OS.lua"
include "lib_UnitScript.lua"
include "lib_Animation.lua"
include "lib_Build.lua"

TablesOfPiecesGroups = {}

function script.HitByWeapon(x, z, weaponDefID, damage)
end

GameConfig = getGameConfig()

center = piece "center"
Icon = piece "Icon"

function script.Create()
	Spin(center,y_axis,math.rad(1),0.5)
	 if Icon then  Move(Icon,y_axis, GameConfig.SatelliteIconDistance, 0);	Show(Icon) end
    TablesOfPiecesGroups = getPieceTableByNameGroups(false, true)
    hideT(TablesOfPiecesGroups["Particle"])
end


function script.Killed(recentDamage, _)
	shatterUnit(unitID, Icon, UnitScript)
    return 1
end


function getRandShrapMoveVal()
    return math.random(-GameConfig.SatelliteShrapnellDistance, GameConfig.SatelliteShrapnellDistance)
end

function dealDamageAnimate()
Explode(center, SFX.SHATTER)
Hide(center)
spinRand(center, -42, 42, 42)
  process(TablesOfPiecesGroups["Particle"],
        function(id)
            spinRand(id, -42, 42, 42)
        end)
StartThread(doDamageCyclic)
while true do
  process(TablesOfPiecesGroups["Particle"],
    function(id)
    StartThread(
        function(id)
            Show(id)
            mP(id, getRandShrapMoveVal(), getRandShrapMoveVal(), getRandShrapMoveVal(), 42)
            WaitForMoves(id)
            Explode(id,SFX.SHATTER)
            Hide(id)
            mP(id, getRandShrapMoveVal(), getRandShrapMoveVal(), getRandShrapMoveVal(), 0)
        end,
        id)
    end)
    WaitForMoves(TablesOfPiecesGroups["Particle"])
    Sleep(10)
end

end

function doDamageCyclic()
local LifeTime = GameConfig.SatelliteShrapnellLifeTime
local DamagePerSecondTenth= GameConfig.SatelliteShrapnellDamagePerSecond/100
local SatelliteShrapnellDistance = GameConfig.SatelliteShrapnellDistance

    Spring.SetUnitNoSelect(unitID, true)
    while LifeTime > 0 do
        process(
                getAllNearUnit(unitID, SatelliteShrapnellDistance),
               function(id)
                    Spring.AddUnitDamage(id, DamagePerSecondTenth)
               end
                )
        Sleep(100)
        LifeTime = LifeTime -100
    end
    Spring.DestroyUnit(unitID, false,true)
end

--- -aimining & fire weapon
function script.AimFromWeapon1() return firepiece end

function script.QueryWeapon1() return firepiece end

function script.AimWeapon1(Heading, pitch)
    -- aiming animation: instantly turn the gun towards the enemy

    return boolOnlyOnce
end
boolOnlyOnce = true

function script.FireWeapon1()
    if boolOnlyOnce== true then
        boolOnlyOnce = false
        StartThread(dealDamageAnimate)
    end

    return true
end

      