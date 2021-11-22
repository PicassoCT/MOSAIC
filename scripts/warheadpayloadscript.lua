include "createCorpse.lua"
include "lib_OS.lua"
include "lib_UnitScript.lua"
include "lib_Animation.lua"

TablesOfPiecesGroups = {}
defuseCapableUnitTypes = getOperativeTypeTable(Unitdefs)
GameConfig = getGameConfig()

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
    Spring.SetUnitAlwaysVisible(unitID, true)
    -- Spring.MoveCtrl.Enable(unitID,true)
    -- x,y,z =Spring.GetUnitPosition(unitID)
    -- Spring.MoveCtrl.SetPosition(unitID, x,y+500,z)
     StartThread(defuseDetect)
     hideT(TablesOfPiecesGroups["ProgressBars"])
    StartThread(PlaySoundByUnitDefID, myDefID,
                            "sounds/icons/warhead_created.ogg", 1,
                            500, 2)
end

boolDefuseThreadRunning = false
function defuseThread(id)
    timeInMs = 0
    while doesUnitExistAlive(id) == true do
        -- Defused succesfully
        if timeInMs > GameConfig.WarheadDefusalTimeMs then
            Spring.DestroyUnit(unitID, false, true)
            return
        end

        -- if distance gets to big
        if distanceUnitToUnit(id, unitID) > GameConfig.WarheadDefusalStartDistance then
            hideT(TablesOfPiecesGroups["ProgressBars"])
            boolDefuseThreadRunning = false
            return
        end

        -- display the Progressbars
        progressBarIndex = #TablesOfPiecesGroups["ProgressBars"]- math.ceil(#TablesOfPiecesGroups["ProgressBars"]* (timeInMs/GameConfig.WarheadDefusalTimeMs))
        hideT(TablesOfPiecesGroups["ProgressBars"])
        showT(TablesOfPiecesGroups["ProgressBars"], 1, math.max(1,progressBarIndex))
        if runningTimeInMS < 10000 then
StartThread(PlaySoundByUnitDefID, myDefID,
                            "sounds/icons/warhead_defusal"..math.random(1,2)..".ogg", 1,
                            20000, 2)
        end

        Sleep(100)
        timeInMs = timeInMs +100
    end
    boolDefuseThreadRunning = false
end

function defuseDetect()
    myTeamID = Spring.GetUnitTeam(unitID)
    while true do
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

