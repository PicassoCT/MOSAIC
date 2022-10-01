include "createCorpse.lua"
include "lib_OS.lua"
include "lib_UnitScript.lua"
include "lib_Animation.lua"
--include "lib_Build.lua"
center = piece("center")

TablesOfPiecesGroups = {}
myDefID = Spring.GetUnitDefID(unitID)
myTeamID = Spring.GetUnitTeam(unitID)
local ecmIconTypes = getECMIconTypes(UnitDefs)
function script.HitByWeapon(x, z, weaponDefID, damage) end
GameConfig= getGameConfig()
speedfactor = 2.0

function script.Create()
    -- generatepiecesTableAndArrayCode(unitID)
    TablesOfPiecesGroups = getPieceTableByNameGroups(false, true)
    hideT(TablesOfPiecesGroups["Data"])
    Spring.SetUnitNeutral(unitID,true)
    Spring.SetUnitBlocking(unitID,false)

     StartThread(hoverAboveGrounds, GameConfig.iconHoverGroundOffset, 5*speedfactor, true)    
     StartThread(eatAIcon)
end


function eatAIcon()
    boolFoundSomething = false
    while true do
        foreach(getAllNearUnit(unitID, 100),
            function (id)
                defID = Spring.GetUnitDefID(id)
                if ecmIconTypes[defID] then
                    return id
                end
            end,
            function (id)
                if Spring.GetUnitTeam(id) ~= myTeamID then
                    Explode(center,  SFX.SHATTER)
                    Spring.DestroyUnit(id, false, true)

                end
            end
            )
        Sleep(500)
    end
end

function script.Killed(recentDamage, _)
    Explode(center,  SFX.SHATTER)

    -- createCorpseCUnitGeneric(recentDamage)
    return 1
end

function moveParticle(pieceID, distances, speed)
    reset(pieceID)
    Show(pieceID)
    WMove(pieceID, y_axis, -distances, speed)
    Hide(pieceID)
end

onMoveCounter = 0
SIG_PARTICLE = 1
function showParticles()
    Signal(SIG_PARTICLE)
    SetSignalMask(SIG_PARTICLE)
    while true do
        if maRa() then
            step=math.random(2,10)
            for i=1, #TablesOfPiecesGroups["Data"], step do
            distance = math.random(2500,6000)
            StartThread(moveParticle,TablesOfPiecesGroups["Data"][i], distance, 7500*speedfactor)
            end
            Sleep(100)
        else
            dice = math.random(1, #TablesOfPiecesGroups["Data"])
            distance = math.random(2500,6000)
            StartThread(moveParticle,TablesOfPiecesGroups["Data"][dice], distance, 7500*speedfactor)
            Sleep(30)
        end
    end
end

function hoverAboveGrounds( distanceToHover, step, boolTurnTowardsGoal)
    if not step then step = 0.1 end
    local spGetGroundHeight = Spring.GetGroundHeight
    local spGetUnitPosition = Spring.GetUnitPosition
    Spring.MoveCtrl.Enable(unitID, true)
    Spring.MoveCtrl.SetRotation(unitID, 0,0,0)
    boolAlreadyStarted = false
    while true do
        x,y,z = spGetUnitPosition(unitID)
        orgx, orgz = x,z
        CommandTable = Spring.GetUnitCommands(unitID, 1)
        if CommandTable and CommandTable[1] then
            gx,_, gz = GetCommandPos(CommandTable[1]) 
           
            if gx and gx ~= -10 or gz and gz ~= -10 then
              if math.abs(gx - x) > 10 then
                        if gx < x then
                            x = x -step
                        elseif gx > x then
                             x = x +step
                        end
                onMoveCounter = onMoveCounter + 1
              end
              if math.abs(gz - z) > 10 then
                if gz < z then
                    z = z -step
                elseif gz > z then
                     z = z +step
                end
                onMoveCounter = onMoveCounter +1
              end
            end
        else
              onMoveCounter = onMoveCounter-1
        end

        if onMoveCounter > 0 and boolAlreadyStarted == false then
            boolAlreadyStarted = true
            StartThread(showParticles)
        end

        if onMoveCounter <=  0 and boolAlreadyStarted == true then
            boolAlreadyStarted = false
            Signal(SIG_PARTICLE)
            hideT(TablesOfPiecesGroups["Data"])
        end

        if boolTurnTowardsGoal then
            _,orgRot,_ = Spring.GetUnitRotation(unitID ) 
            rot = math.atan2(orgx-x, -(orgz-z))
            rot = mix(rot, orgRot, 0.95)
            Spring.MoveCtrl.SetRotation(unitID, 0,rot,0)
        end
        
        gh = spGetGroundHeight(x,z)
        Spring.MoveCtrl.SetPosition(unitID, x, math.max(0,gh) + distanceToHover, z)
        Sleep(29)
    end
end

function script.StartMoving() 
 
end

function script.StopMoving() 

end

function script.Activate() return 1 end

function script.Deactivate() return 0 end

function script.AimFromWeapon1() return center end

function script.QueryWeapon1() return center end

function script.AimWeapon1(Heading, pitch) return false end

function script.FireWeapon1() return false end


