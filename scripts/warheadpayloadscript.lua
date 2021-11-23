include "createCorpse.lua"
include "lib_OS.lua"
include "lib_UnitScript.lua"
include "lib_Animation.lua"

TablesOfPiecesGroups = {}
defuseCapableUnitTypes = getOperativeTypeTable(Unitdefs)
GameConfig = getGameConfig()

--Explode on Impact
function script.HitByWeapon(x, z, weaponDefID, damage) 
    hp,maxHp= Spring.GetUnitHealth(unitID)
        if hp -damage < maxHp/2 then
            x,y,z = Spring.GetUnitPosition(unitID)
            weaponDefID = WeaponDefs["godrod"].id
                        local params = {
                            pos = { x,  y + 10,  z},
                           ["end"] = { x,  y+ 5,  z},
                        speed = {0,0,0},
                        spread = {0,0,0},
                        error = {0,0,0},
                        owner = unitID,
                        team = myTeamID,
                        ttl = 1,
                        gravity = 1.0,
                        tracking = unitID,
                        maxRange = 9000,
                        startAlpha = 0.0,
                        endAlpha = 0.1,
                        model = "emptyObjectIsEmpty.s3o",
                        cegTag = ""

                        }

                        id=Spring.SpawnProjectile ( weaponDefID, param) 
                        Spring.SetProjectileAlwaysVisible (id, true)
        end
return damage
end
local spGetUnitTeam = Spring.GetUnitTeam
local spGetUnitDefID = Spring.GetUnitDefID
local myDefID = spGetUnitDefID(unitID)


function script.Create()
    -- generatepiecesTableAndArrayCode(unitID)
    TablesOfPiecesGroups = getPieceTableByNameGroups(false, true)

    -- Spring.MoveCtrl.Enable(unitID,true)
    -- x,y,z =Spring.GetUnitPosition(unitID)
    -- Spring.MoveCtrl.SetPosition(unitID, x,y+500,z)
     StartThread(defuseStateMachine)
     hideT(TablesOfPiecesGroups["ProgressBars"])
     hideT(TablesOfPiecesGroups["Rotor"])
    StartThread(PlaySoundByUnitDefID, myDefID,
                            "sounds/icons/warhead_created.ogg", 1,
                            500, 2)
end

if boolDefuseThreadRunning == false then
    process(getAllNearUnit(unitID, GameConfig.WarheadDefusalStartDistance ),
           function(id)
               defID = spGetUnitDefID(id)
                   if boolDefuseThreadRunning == false and
                       spGetUnitTeam(id) ~= myTeamID and
                       defuseCapableUnitTypes[defID] then
                       StartThread(defuseThread, id)
                       boolDefuseThreadRunning = true 

                   end
            end)
end

boolDefuseThreadRunning = false
defuseStatesMachine = {
    dormant =   function(oldState, frame)

                    nextState = "dormant"
                    return targetState
                end,
    defuse_in_progress= function(oldState, frame)

        nextState = "defuse_in_progress"
        return targetState
    end,
    decay_in_progress= function(oldState, frame)

        nextState = "decay_in_progress"
        return targetState
    end,
    defused = function(oldState, frame)
        
        nextState = "defused"
        return targetState
    end,
}

--Reveal Productionplace, Propagandaplus

function defuseStateMachine()
    myTeamID = Spring.GetUnitTeam(unitID)
    currentState = "dormant"
    while true do
      
        Sleep(250)
    end
end

function script.Killed(recentDamage, _)

    -- createCorpseCUnitGeneric(recentDamage)
    return 1
end



function script.StartMoving() end

function script.StopMoving() end

function script.Activate() return 1 end

function script.Deactivate() return 0 end

-- function script.QueryBuildInfo()
-- return center
-- end

-- Spring.SetUnitNanoPieces(unitID, { center })

