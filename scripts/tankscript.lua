include "createCorpse.lua"
include "lib_OS.lua"
include "lib_UnitScript.lua"
include "lib_Animation.lua"
--include "lib_Build.lua"

TablesOfPiecesGroups = {}
FireEmit= piece"FireEmit"
DustEmit= piece"DustEmit"
center = piece "Body1"
aimpiece = piece "Turret1"
Cannon1 = piece "Cannon1"
Shell = piece"Shell"
SIG_RESETAIM = 1

myTeamID = Spring.GetUnitTeam(unitID)
gaiaTeamID = Spring.GetGaiaTeamID()
lastTurretRotation = 0

function delayedResetFirestate()
 orgstate = getFireState(unitID)
 Sleep(7500)
 setFireState(unitID, orgstate)
end

function script.HitByWeapon(x, z, weaponDefID, damage) 
    StartThread(delayedResetFirestate)
    setFireState(unitID, "fireatwill")
return damage
end

isStealthTank = Spring.GetUnitDefID(unitID) == UnitDefNames["ground_tank_day"].id and randChance(10)
dayMoveStealthTable = {}
nightMoveStealthTable = {}
local camoRulesAccess = {inlos = true}
local activeCamoPieces

-- Only the visible canopy meshes are redrawn by the unsynced renderer. Publishing
-- through LOS-scoped rules params also works after a LuaRules reload / late join.
local function publishCamoPieces(pieces)
    if activeCamoPieces == pieces then return end
    activeCamoPieces = pieces
    for i, id in ipairs(pieces or {}) do
        Spring.SetUnitRulesParam(unitID, "tank_camo_piece_" .. i, id, camoRulesAccess)
    end
    Spring.SetUnitRulesParam(unitID, "tank_camo_count", pieces and #pieces or 0, camoRulesAccess)
end

function hideAllStealth()
    hideT(TablesOfPiecesGroups["MoveStealth"])
    hideT(TablesOfPiecesGroups["StealthShieldFold"])
    hideT(TablesOfPiecesGroups["StealthEvening"])
    publishCamoPieces(nil)
end

Halterung = nil
StealthBase = nil

function setup()
    -- The equipment already has a 10% variant roll. A second roll here used to
    -- leave almost every equipped tank with a permanently inactive canopy.
    boolCloaked = true
    Halterung = piece("Halterrung")
    StealthBase = piece("StealthBase")
    Show(Halterung)
    Show(StealthBase)
    dayMoveStealthTable = {TablesOfPiecesGroups["StealthShieldFold"]}
    for _, id in ipairs(TablesOfPiecesGroups["MoveStealth"] or {}) do
        dayMoveStealthTable[#dayMoveStealthTable + 1] = {id}
    end
    nightMoveStealthTable = {}
    for _, id in ipairs(TablesOfPiecesGroups["StealthEvening"] or {}) do
        nightMoveStealthTable[#nightMoveStealthTable + 1] = {id}
    end
end

local function showCamoPieces(pieces)
    if activeCamoPieces == pieces then return end
    hideAllStealth()
    showT(pieces)
    publishCamoPieces(pieces)
end

function runCloakAnimations()
    local moveIndex, previousNight = 1, nil
    while boolCloaked do
        local night = isNight()
        local frames = night and nightMoveStealthTable or dayMoveStealthTable
        if #frames == 0 then frames = dayMoveStealthTable end
        if night ~= previousNight or not boolMoving then
            moveIndex = 1
        elseif night then
            moveIndex = math.min(moveIndex + 1, #frames)
        else
            moveIndex = moveIndex % #frames + 1
        end
        previousNight = night
        showCamoPieces(frames[moveIndex])
        Sleep(night and boolMoving and 5000 or 1000)
    end
end

function hideCloakAnimation()
    local panels = TablesOfPiecesGroups["StealthShieldFold"] or {}
    if #panels == 0 then return end
    showCamoPieces(panels)
    for _, id in ipairs(panels) do
        Turn(id, x_axis, math.rad(-360 / #panels), 0.65)
    end
    for _, id in ipairs(panels) do WaitForTurn(id, x_axis) end
    hideAllStealth()
end

function showCloakAnimation()
    local panels = TablesOfPiecesGroups["StealthShieldFold"] or {}
    if #panels == 0 then return end
    Show(Halterung)
    for _, id in ipairs(panels) do
        Turn(id, x_axis, math.rad(-360 / #panels), 0)
    end
    showCamoPieces(panels)
    for _, id in ipairs(panels) do Turn(id, x_axis, 0, 0.65) end
    for _, id in ipairs(panels) do WaitForTurn(id, x_axis) end
end

function rotateCloake(PayloadCenter, DetectPiece)
    local spGetUnitPiecePosDir = Spring.GetUnitPiecePosDir
    local spGetGroundHeight = Spring.GetGroundHeight
    turnRatePerSecondDegree = (300*0.16)/4
    _,lastOrientation,_  = Spring.UnitScript.GetPieceRotation(PayloadCenter)
    px,py,pz = spGetUnitPiecePosDir(unitID, DetectPiece)
    val  = 0
    oldPitch, oldYaw, OldRoll = Spring.GetUnitRotation(unitID)
    while true do
        px,py,pz = Spring.GetUnitPiecePosDir(unitID, DetectPiece)
        pitch,yaw,roll = Spring.GetUnitRotation(unitID)
       -- echo("Unit  "..pitch.."/"..yaw.."/"..roll)
        if boolMoving == true  then          
            x, y, z = Spring.UnitScript.GetPieceRotation(PayloadCenter)
            goal = math.ceil(y * 0.95)
            Turn(PayloadCenter,y_axis, goal, 1.125)
            lastOrientation = goal
        else
            if boolTurning == true then                
                x,y,z = spGetUnitPiecePosDir(unitID, PayloadCenter)
                dx,  dz = px-x, pz-z
                if boolTurnLeft then
                    headRad = -math.pi + math.atan2(dz, dx)
                else
                    headRad = math.pi - math.atan2(dx, dz)
                end
                Turn(PayloadCenter,y_axis, headRad, 1)
                lastOrientation = headRad
            else    
                Turn(PayloadCenter,y_axis, lastOrientation, 0)   
            end
        end     

        if boolMoving == true then
            Sleep(125)
        else
            Sleep(50)
        end
        oldPitch, oldYaw, OldRoll = pitch, yaw, roll
    end
end

function optionalStealth()
    if isStealthTank then
    Halterung = piece("Halterrung")
    StealthBase = piece("StealthBase")
        StartThread(rotateCloake, Halterung, FireEmit)
        setup()
        hideAllStealth()    
        
        while isStealthTank do
            if boolCloaked then
                showCloakAnimation()
                runCloakAnimations()
                hideCloakAnimation()
            end   
       
            Sleep(1000)
        end
    end
end

function script.Create()

    Show(center)
    Show(aimpiece)
    Show(Cannon1)
    Hide(DustEmit)
    Hide(FireEmit)    
    Hide(Shell)

    TablesOfPiecesGroups = getPieceTableByNameGroups(false, true)

    -- Finish the initial reset before the unfolding thread starts turning panels.
    resetAll(unitID)
    hideAllStealth()
    local pieceMap = Spring.GetUnitPieceMap(unitID)
    if pieceMap.Halterrung then Hide(pieceMap.Halterrung) end
    if pieceMap.StealthBase then Hide(pieceMap.StealthBase) end
    Spring.SetUnitRulesParam(unitID, "tank_camo_count", 0, camoRulesAccess)
    StartThread(optionalStealth)
    if gaiaTeamID == myTeamID then
        Spring.SetUnitAlwaysVisible(unitID, true)
    end
    StartThread(emitDustRotateWheels)
end

function script.Killed(recentDamage, _)
    boolCloaked = false
    isStealthTank = false
    publishCamoPieces(nil)
    for groupname, list in pairs (TablesOfPiecesGroups) do
        if list then
            for i=1,#list do
                if list[i] then
                Explode(list[i], SFX.EXPLODE + SFX.SMOKE + SFX.FIRE)
                end
            end
        end
    end

    createTankCorpse(unitID, recentDamage, lastTurretRotation + 180)
    return 1
end

boolMoving= false
function emitDustRotateWheels()
    while true do
    Sleep(100)
        while (boolMoving == true) do
            de = math.ceil(math.random(240, 360))
            Sleep(de)
            EmitSfx(DustEmit, 1024)
        end
    end

end
--- -aimining & fire weapon
function script.AimFromWeapon1() return aimpiece end

function script.QueryWeapon1() return Cannon1 end

boolNoLongerAiming = true

function noLongerAiming()
    Signal(SIG_RESETAIM)
    SetSignalMask(SIG_RESETAIM)
    boolNoLongerAiming = false
    Sleep(10000)
    boolNoLongerAiming = true
    if maRa() then
        StartThread(PlaySoundByUnitDefID, unitDefID, "sounds/tank/rotate.ogg", 0.2,
                    1000, 1)
        WTurn(aimpiece, 2, 0, 0.5)
        WTurn(Cannon1, 1, 0, 0.5)
        lastTurretRotation = 0
    end
end

boolBarelyMoved = false
function script.AimWeapon1(Heading, pitch)
    -- aiming animation: instantly turn the gun towards the enemy
    startFrame = Spring.GetGameFrame()
    if not boolBarelyMoved  then
        StartThread(PlaySoundByUnitDefID, unitDefID, "sounds/tank/rotate.ogg", 0.25, 1000, 1)
    end
    StartThread(noLongerAiming)
    WTurn(aimpiece, 2, Heading, 0.7)
    lastTurretRotation = math.deg(Heading)
    WTurn(Cannon1, 1, -pitch, 0.7)
    endFrame = Spring.GetGameFrame()
    boolBarelyMoved = (endFrame -startFrame) < 5
    return true
end


function script.FireWeapon1()
    tP(FireEmit,5*45,0,10,0)
    Explode(Shell, SFX.FALL)
    EmitSfx(FireEmit, 1026)
    EmitSfx(FireEmit, 1024)
    spawnCegAtPieceGround(unitID, FireEmit,"tankfireshockwave",0, 20, 0)
    spawnCegAtPieceGround(unitID, FireEmit,"bigbulletimpact",0, 20, 0)

 return true 
end

function script.StartMoving()
    StartThread(PlaySoundByUnitDefID, unitDefID, "sounds/tank/drive_4_30.ogg",
                0.2, 30000, 1)
    boolMoving = true
end

function script.StopMoving() boolMoving=false end

function script.Activate() return 1 end

function script.Deactivate() return 0 end

function script.QueryBuildInfo() return center end

Spring.SetUnitNanoPieces(unitID, {center})

