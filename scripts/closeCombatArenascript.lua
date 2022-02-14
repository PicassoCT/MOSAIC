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
local arena = piece "arena"
boolStartFight = false
local fighterOne 
local fighterTwo 
local GameConfig = getGameConfig()
local houseTypeTable = getCultureUnitModelTypes(GameConfig.instance.culture, "house", UnitDefs)

attach1 = piece"attach1"
attach2 = piece"attach2"

function script.HitByWeapon(x, z, weaponDefID, damage)
    attackerID = Spring.GetUnitLastAttacker(unitID)
    if attackerID then
        teamID = Spring.GetUnitTeam(attackerID)
        if doesUnitExistAlive(fighterOne) and teamID == Spring.GetUnitTeam(fighterOne) then
            sapHealth(fighterTwo, damage)
            return 0
        end

        if doesUnitExistAlive(fighterTwo) and teamID == Spring.GetUnitTeam(fighterTwo) then
            sapHealth(fighterOne, damage)
            return 0
        end
    end

    myHp = Spring.GetUnitHealth(unitID)
    sapHealth(fighterTwo, damage / 2)
    sapHealth(fighterOne, damage / 2)
    return 0
end

function script.Create()
    --echo("CloseCombatArena Created")
    hideAll(unitID)
    Spring.SetUnitAlwaysVisible(unitID, true)
    Spring.SetUnitBlocking(unitID, false)
    
    --Spring.MoveCtrl.Enable(unitID, true)
    StartThread(combatHealthOS)
    StartThread(randomMove)
end

function randomMove()
    while true do
        x,y,z =Spring.GetUnitPosition(unitID)
        x,z = x + math.random(0,GameConfig.houseSizeX*2)*randSign(), z+ math.random(0,GameConfig.houseSizeX*2)*randSign()

        houses = foreach(
                    getAllInCircle(x,z, GameConfig.houseSizeX),
                    function(id)
                        if houseTypeTable[Spring.GetUnitDefID(id)] then return id end
                    end
                    )

        if #houses == 0 then
            Command(unitID, "go", {x,y,z}, {})
        end
        Sleep(4000)
    end
end

function script.Killed(recentDamage, _)
 -- echo("Close Combat Arena ended")
    -- createCorpseCUnitGeneric(recentDamage)
    return 1
end


center = piece"center"

function fightAnimation()
    intensity = 0
    time = 0
    speed = 2
    scale = 0.1
    Turn(turn1, z_axis, math.rad(90), 0)
    Turn(turn2, z_axis, math.rad(-90 ), 0)
    Move(move1, z_axis, -5, 0)
    Move(move2, z_axis, -5, 0)
    twoZeroOffset = -400
    while true do 
        StartThread(PlaySoundByUnitDefID, myDefID, "sounds/cqb/cqb"..math.random(1,4)..".ogg", 1.0, 22000, 1)
        initiative = math.random(1, 2)
        initivativeSign = -1
        StopSpin(arena, z_axis, 0.1)
        for k = 0, initiative do
            initivativeSign = initivativeSign * -1
        end
        attackPulses = math.random(1, 5)

        intensityMultiplicator =
            math.max(1, 1 + math.abs(math.cos(intensity * math.pi / 4)) + (math.sin(time / 60000) * 0.5))
        restInterval = math.ceil(2000 / ((intensity % 5) + 2))
        for i = 1, attackPulses do
            Spin(arena, z_axis, math.rad(4.2 * randSign()), 0.2)
            if initivativeSign == -1 then
                Move(move2, 
                    x_axis, 
                    scale * initivativeSign * i * 100, 
                    400 * intensityMultiplicator * speed * scale)
                Sleep(100)
                if i==1 then  spawnCegAtPiece(unitID, move2, "dirt"); spawnCegAtPiece(unitID, move1, "dirt")  end
                Turn(turn1, x_axis, math.rad(-5) * initivativeSign, 70)
                WMove(
                    move1,
                    x_axis,
                    scale * initivativeSign * i * 100*1.1 ,
                    400 * intensityMultiplicator * speed * scale*1.4
                )
                val = math.random(-10, 10)
                Turn(turn2, z_axis, math.rad(-90 + val), 150)
                Turn(turn2, y_axis, math.rad(5) * randSign(), 150) 
                Turn(turn1, x_axis, math.rad(0) , 6)
                if i==1 then  spawnCegAtPiece(unitID, move2, "dirt"); spawnCegAtPiece(unitID, move1, "dirt")  end
            else
                Move(move1,
                 x_axis, 
                 scale * initivativeSign * i * 100,
                 400 * intensityMultiplicator * speed * scale)
                Sleep(100)
                if i==1 then  spawnCegAtPiece(unitID, move2, "dirt"); spawnCegAtPiece(unitID, move1, "dirt")  end
                Turn(turn2, x_axis, math.rad(5) * initivativeSign, 70)
                WMove(
                    move2,
                    x_axis,
                    scale * initivativeSign * i * 100*1.1,
                    400 * intensityMultiplicator * speed * scale*1.4
                )
                val = math.random(-10, 10)
                Turn(turn1, z_axis, math.rad(90 + val), 150)
                Turn(turn1, y_axis, math.rad(5)*randSign(), 150)    
                Turn(turn2, x_axis, math.rad(0) , 6)
                if i==1 then  spawnCegAtPiece(unitID, move2, "dirt"); spawnCegAtPiece(unitID, move1, "dirt")  end
            end
              if i == 1 then 
                stopSpins(center,0.1)
                reset(center, 3)
             end
            Sleep(restInterval)
            if i==1 then  spawnCegAtPiece(unitID, move2, "dirt"); spawnCegAtPiece(unitID, move1, "dirt")  end
           if math.random(1,10) > 9  then spawnCegAtPiece(unitID, move1, "bloodslay") end
        end
        Spin(arena, z_axis, math.rad(42 * randSign()), 4.2)
       
        --circling break& catch breath, reset Flee roll, places Change
        spinRand(center,-120, 120, 25)
        if initiative == 1 then
            Move(move1, x_axis, 0, 1500 * scale)
            WMove(move2, x_axis, 0, 1500 * scale)
        else
            Move(move2, x_axis, 0, 1500 * scale)
            WMove(move1, x_axis, 0, 1500 * scale)
        end
      
        Sleep(100)

        time = time + (2000 / intensity) * attackPulses + 500 * attackPulses
        time = time + 100
        intensity = intensity + 1
        spawnCegAtUnit(unitID, "dirt")
    end
end

function sapHealth(id, amount)
    hp = Spring.GetUnitHealth(id)
    if not hp then return false end
    Spring.SetUnitHealth(id, hp - amount)
    return hp - amount <= 0
end


function combatHealthOS()
    amount = GameConfig.closeCombatHealthLosPerSecond/2
   -- echo("Close Combat Arena created")
    while boolStartFight == false do
        Sleep(100)
    end

    Spring.UnitAttach(unitID, fighterOne,  attach2)
    Sleep(1)
    Spring.UnitAttach(unitID, fighterTwo, attach1)
    Sleep(1)

    StartThread(fightAnimation)
    repeat
        sapHealth(fighterOne, amount)
        sapHealth(fighterTwo, amount)
        Sleep(500)

        if  doesUnitExistAlive(fighterOne) == false then          
            Spring.UnitDetach(fighterTwo)
            Spring.SetUnitAlwaysVisible(fighterTwo, false)
        end

        if  doesUnitExistAlive(fighterTwo) == false then
                Spring.UnitDetach(fighterOne)
                Spring.SetUnitAlwaysVisible(fighterOne, false)
        end

    until (not (doesUnitExistAlive(fighterOne) and doesUnitExistAlive(fighterTwo)))
    --echo("Close Combat Arena ending")
    Sleep(10)
    Spring.DestroyUnit(unitID, true, false)
end




function addCloseCombatants(fighterA, fighterB)
   -- echo("Arena Adding close combant involved")
    if doesUnitExistAlive(fighterA) and  doesUnitExistAlive(fighterB)  then
        fighterOne = fighterA
        fighterTwo = fighterB
        --[[Spring.UnitAttach(unitID, fighterA, attach2)  --]]
        Spring.SetUnitAlwaysVisible(fighterA, true)  

        --[[Spring.UnitAttach(unitID, fighterB, attach1)--]]
        Spring.SetUnitAlwaysVisible(fighterB, true)
        boolStartFight = true
        return
    end
end

function script.TransportPickup(passengerID)
   -- Spring.Echo("TransportPickup Unit "..passengerID)
    if doesUnitExistAlive(fighterTwo) then
        return false
    end

    if fighterOne == nil then
            fighterOne = passengerID
        Spring.UnitAttach(unitID, fighterOne, attach1)    
        env = Spring.UnitScript.GetScriptEnv(fighterOne)       
        if env and env.isNowInCloseCombat then
            Spring.UnitScript.CallAsUnit(fighterOne, env.isNowInCloseCombat,  unitID)
        end
        return true
    end

    if  fighterTwo == nil then
        fighterTwo = passengerID
        Spring.UnitAttach(unitID, fighterTwo, attach2)
        env = Spring.UnitScript.GetScriptEnv(fighterTwo)       
        if env and env.isNowInCloseCombat then
            Spring.UnitScript.CallAsUnit(fighterTwo, env.isNowInCloseCombat,  unitID)
        end

        boolStartFight = true
        return true
    end
end

function script.TransportDrop(passengerID, x, y, z)
 --   Spring.Echo("TransportDrop Unit "..passengerID)
end