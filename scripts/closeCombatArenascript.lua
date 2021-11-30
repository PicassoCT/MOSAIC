include "createCorpse.lua"
include "lib_OS.lua"
include "lib_UnitScript.lua"
include "lib_Animation.lua"
--include "lib_Build.lua"

TablesOfPiecesGroups = {}

function script.HitByWeapon(x, z, weaponDefID, damage) end


function script.Create()
    -- generatepiecesTableAndArrayCode(unitID)
    TablesOfPiecesGroups = getPieceTableByNameGroups(false, true)
    Spring.MoveCtrl.Enable(unitID,true)
    x,y,z =Spring.GetUnitPosition(unitID)
    Spring.MoveCtrl.SetPosition(unitID, x,y,z)
    -- StartThread(AnimationTest)
end


function script.Killed(recentDamage, _)

    -- createCorpseCUnitGeneric(recentDamage)
    return 1
end


function script.TransportDrop(passengerID, x, y, z)

end
function fightAnimation()
    move1 = TablesOfPiecesGroups["move"][1]
    turn1 = TablesOfPiecesGroups["rot"][1]
    move2 = TablesOfPiecesGroups["move"][2]
    turn2 = TablesOfPiecesGroups["rot"][2]
    intensity = 0
    while true do
        initiative= math.random(1,2)
        initivativeSign= 1 for k=0, initiative do initivativeSign= initivativeSign *1 end
        attackPulses = math.random(1,5)
        for i=1,attackPulses do
            if initiative == 1 then
                Move(move1,x_axis,initivativeSign*i*100, 400)
                Move(move2,x_axis,initivativeSign*i*100*0.75, 300)
            else
                Move(move1,x_axis,initivativeSign*i*100*0.75, 300)
                Move(move2,x_axis,initivativeSign*i*100, 400)
            end
            Sleep(2000/intensity)
        end
        --circling break& catch breath, reset Flee roll, places Change
        WMove(move1,x_axis, 0, 1500)
        WMove(move2,x_axis, 0, 1500)
        Sleep(500)
        intensity= intensity+1
    end
end

function sapHealth(id, amount)
    hp = Spring.GetUnitHealth(id)
    Spring.SetUnitHealth(id, hp - amount)
    return hp-amount <= 0
end

function combatHealth()
    amount= 50
    StartThread(fightAnimation)
    while true do
        if doesUnitExistAlive(fighterOne) then
            isDead = sapHealth(fighterOne, amount)
          
            if isDead == true then   Spring.DetachUnit(fighterTwo); break end
        end

        if doesUnitExistAlive(fighterTwo) then
            isDead = sapHealth(fighterTwo, amount)

            if isDead == true then  Spring.DetachUnit(fighterOne); break end
        end 
    Sleep(500)
    end
    Spring.DestroyUnit(unitID, false, true)
end

local fighterOne
local fighterTwo
function script.TransportPickup(passengerID)
    if doesUnitExistAlive(fighterTwo) then return false end

    if not fighterOne then 
        Spring.AttachUnit(passengerID, unitID, TablesOfPiecesGroups["attach"][1])
        fighterOne = passengerID
        return
    end

     if not fighterTwo then 
        Spring.AttachUnit(passengerID, unitID, TablesOfPiecesGroups["attach"][2])
        fighterTwo = passengerID
        return
    end   
end

