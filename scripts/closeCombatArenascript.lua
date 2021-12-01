include "createCorpse.lua"
include "lib_OS.lua"
include "lib_UnitScript.lua"
include "lib_Animation.lua"
--include "lib_Build.lua"

TablesOfPiecesGroups = {}
TablesOfPiecesGroups = getPieceTableByNameGroups(false, true)
local move1 = TablesOfPiecesGroups["move"][1]
local turn1 = TablesOfPiecesGroups["rot"][1]
local move2 = TablesOfPiecesGroups["move"][2]
local turn2 = TablesOfPiecesGroups["rot"][2]
local arena = piece"arena"

function script.HitByWeapon(x, z, weaponDefID, damage) return damage end

function script.Create()
    -- generatepiecesTableAndArrayCode(unitID)
    Spring.MoveCtrl.Enable(unitID,true)
    x,y,z =Spring.GetUnitPosition(unitID)
    Spring.MoveCtrl.SetPosition(unitID, x,y,z)
    StartThread(fightAnimation)
end

function script.Killed(recentDamage, _)
    -- createCorpseCUnitGeneric(recentDamage)
    return 1
end

function script.TransportDrop(passengerID, x, y, z)
end

function fightAnimation()
    intensity = 0
    time= 0
    speed= 2
    while true do
        initiative= math.random(1,2)
        initivativeSign= -1 
        StopSpin( arena,z_axis, 0.1)
        for k=0, initiative do initivativeSign= initivativeSign *-1 end
        attackPulses = math.random(1,5)
        
        intensityMultiplicator = math.max(1,1 + math.abs(math.cos(intensity*math.pi/4))+(math.sin(time/60000)*0.5))
        restInterval = math.ceil(2000/((intensity%5)+2))
        for i=1,attackPulses do
             Spin(arena,z_axis, math.rad(4.2*randSign()),0.2)
            if initiative == 1 then
                Move(move1,x_axis,initivativeSign*i*100, 400*intensityMultiplicator*speed)
                Sleep(250)
                WMove(move2,x_axis,initivativeSign*i*100*0.75, 200*intensityMultiplicator*speed)
                val= math.random(-10,10)
                Turn(turn2,z_axis, math.rad(val), 150)
                Turn(turn2,y_axis, math.rad(5)*randSign(), 150)
            else
                Move(move2,x_axis,initivativeSign*i*100, 400*intensityMultiplicator*speed)
                Sleep(250)
                WMove(move1,x_axis,initivativeSign*i*100*0.75, 200*intensityMultiplicator*speed)
                val= math.random(-10,10)
                Turn(turn1,z_axis, math.rad(val), 150)
                Turn(turn1,y_axis, math.rad(5)*randSign(), 150)
            end
            Sleep(restInterval)
            reset(turn1, 150)
            reset(turn2, 150)
        end
       Spin(arena,z_axis, math.rad(42*randSign()),4.2)
        --circling break& catch breath, reset Flee roll, places Change
        if initiative ~= 1 then
                Move(move1,x_axis,0, 1500)
                Sleep(150)
                WMove(move2,x_axis,0, 1500)
        else
            Move(move2,x_axis,0, 1500)
            Sleep(150)
            WMove(move1,x_axis,0, 1500)
        end

        Sleep(100)
         time= time + (2000/intensity)*attackPulses + 500*attackPulses
         time= time + 100
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
        Spring.UnitAttach(unitID, passengerID, TablesOfPiecesGroups["attach"][1])
        fighterOne = passengerID
        return
    end

     if not fighterTwo then 
        Spring.UnitAttach(unitID, passengerID, TablesOfPiecesGroups["attach"][2])
        fighterTwo = passengerID
        StartThread(combatHealth)
        return
    end   
end

