include "createCorpse.lua"
include "lib_UnitScript.lua"
include "lib_Animation.lua"
include "lib_mosaic.lua"

local Animations = include('animations_civilian_female.lua')
local signMessages = include('protestSignMessages.lua')
local peacfulProtestSignMessages = include('PeacefullProtestSignMessages.lua')
local spGetUnitDefID = Spring.GetUnitDefID
local spGetUnitIsTransporting = Spring.GetUnitIsTransporting

local TablesOfPiecesGroups = {}

SIG_ANIM = 1
SIG_UP = 2
SIG_LOW = 4
SIG_COVER_WALK = 8
SIG_BEHAVIOUR_STATE_MACHINE = 16
SIG_PISTOL = 32
SIG_MOLOTOW = 64
SIG_INTERNAL = 128
SIG_RPG = 256

local center = piece('center');
local Feet1 = piece('Feet1');
local Feet2 = piece('Feet2');
local Head1 = piece('Head1');
local MilitiaMask = nil
local LowArm1 = piece('LowArm1');
local LowArm2 = piece('LowArm2');
local LowLeg1 = piece('LowLeg1');
local LowLeg2 = piece('LowLeg2');
local trolley = piece('trolley');
local root = piece('root');
local UpArm1 = piece('UpArm1');
local UpArm2 = piece('UpArm2');
local UpBody = piece('UpBody');
local UpLeg1 = piece('UpLeg1');
local UpLeg2 = piece('UpLeg2');
local cigarett = piece('cigarett');
local Handbag = piece('Handbag');
local SittingBaby = piece('SittingBaby');
local ak47 = piece('ak47')
local cofee = nil
local ProtestSign = piece "ProtestSign"
local cellphone1 = piece "cellphone1"
local cellphone2 = piece "cellphone2"
local molotow = piece "molotow"
local ShoppingBag = piece "ShoppingBag"
local RPG7
local RPG7Rocket
local map = Spring.GetUnitPieceMap(unitID);
gunsTable =  {}
gunsTable[#gunsTable+1] = ak47
local walkMotionExcludeTable = {}
if UnitDefs[unitDefID].name == "civilian_western0" then
    gunsTable[#gunsTable + 1 ] = piece('Pistol')
    walkMotionExcludeTable[ShoppingBag]=ShoppingBag
    walkMotionExcludeTable[Handbag]=Handbag
end

local scriptEnv = {
    Handbag = Handbag,
    trolley = trolley,
    SittingBaby = SittingBaby,
    center = center,
    Feet1 = Feet1,
    Feet2 = Feet2,
    Head1 = Head1,
    LowArm1 = LowArm1,
    LowArm2 = LowArm2,
    LowLeg1 = LowLeg1,
    LowLeg2 = LowLeg2,
    cigarett = cigarett,
    cofee = cofee,
    root = root,
    UpArm1 = UpArm1,
    UpArm2 = UpArm2,
    UpBody = UpBody,
    UpLeg1 = UpLeg1,
    UpLeg2 = UpLeg2,
    x_axis = x_axis,
    y_axis = y_axis,
    z_axis = z_axis
}

local spGetUnitTeam = Spring.GetUnitTeam
local myTeamID = spGetUnitTeam(unitID)
local gaiaTeamID = Spring.GetGaiaTeamID()
local spGetUnitPosition = Spring.GetUnitPosition
local loc_doesUnitExistAlive = doesUnitExistAlive
GameConfig = getGameConfig()
local civilianWalkingTypeTable = getCultureUnitModelTypes(
                                     GameConfig.instance.culture, "civilian",
                                     UnitDefs)



local eAnimState = getCivilianAnimationStates()
local upperBodyPieces = {
    [Head1] = Head1,
    [LowArm1] = LowArm1,
    [LowArm2] = LowArm2,
    [UpBody] = UpBody,
    [UpArm1] = UpArm1,
    [UpArm2] = UpArm2
}

local lowerBodyPieces = {
    [center] = center,
    [UpLeg1] = UpLeg1,
    [UpLeg2] = UpLeg2,
    [LowLeg1] = LowLeg1,
    [LowLeg2] = LowLeg2,
    [Feet1] = Feet1,
    [Feet2] = Feet2
}

local lowerBodyPiecesNoCenter = {
    [UpLeg1] = UpLeg1,
    [UpLeg2] = UpLeg2,
    [LowLeg1] = LowLeg1,
    [LowLeg2] = LowLeg2,
    [Feet1] = Feet1,
    [Feet2] = Feet2
}
catatonicBodyPieces = lowerBodyPieces
catatonicBodyPieces[UpBody] = UpBody
-- equipmentname: cellphone, shoppingbags, crates, baby, cigarett, food, stick, demonstrator sign, molotow cocktail

local boolWalking = false
local boolDecoupled = false
local boolAiming = false

home = {}

loadMax = 8
local damagedCoolDown = 0
local bodyConfig = {}
local TruckTypeTable = getCultureUnitModelTypes(GameConfig.instance.culture, "truck", UnitDefs)
local NORMAL_WALK_SPEED =  0.65625
SPRINT_SPEED = 1.0

iShoppingConfig = math.random(0, 8)
function variousBodyConfigs()
    bodyConfig.boolShoppingLoaded = (iShoppingConfig <= 1)
    bodyConfig.boolCarrysBaby = (iShoppingConfig == 2)
    bodyConfig.boolTrolley = (iShoppingConfig == 3)
    bodyConfig.boolHandbag = (iShoppingConfig == 4)
    bodyConfig.boolLoaded = (iShoppingConfig < 5)
    bodyConfig.boolProtest = GG.GlobalGameState == GameConfig.GameState.anarchy and maRa()
end

orgHousePosTable = {}

rpgCarryingTypeTable = getRPGCarryingCivilianTypes(UnitDefs)
myName = UnitDefs[unitDefID].name
local myGun = ak47
UnitPieces = Spring.GetUnitPieceMap(unitID)
function script.Create()
   
    Move(root, y_axis, -3, 0)
    TablesOfPiecesGroups = getPieceTableByNameGroups(false, true)
    if not TablesOfPiecesGroups["MilitiaMask"] then
        MilitiaMask = piece("MilitiaMask")
    else
        MilitiaMask = TablesOfPiecesGroups["MilitiaMask"][math.random(1,#TablesOfPiecesGroups["MilitiaMask"])]
    end
    if maRa() and MilitiaMask then Show(MilitiaMask) end
    if map["cofee"] then
        cofee = piece('cofee')
    else
        if TablesOfPiecesGroups["cofee"] then
            cofee = TablesOfPiecesGroups["cofee"][(unitID % #TablesOfPiecesGroups["cofee"])+1] 
        end
    end

    if #gunsTable > 1 then myGun = gunsTable[math.random(1,#gunsTable)] else myGun = gunsTable[1] end
    makeWeaponsTable(myGun)

    variousBodyConfigs()

    bodyConfig.boolArmed = false 
    bodyConfig.boolRPGArmed = false
    bodyConfig.boolWounded = false
    bodyConfig.boolInfluenced = false
    bodyConfig.boolCoverWalk = false
    bodyConfig.boolRPGCarrying = rpgCarryingTypeTable[unitDefID] ~= nil 
    home.x, home.y, home.z = Spring.GetUnitPosition(unitID)
    bodyBuild()

    setupAnimation()

    setOverrideAnimationState(eAnimState.standing, eAnimState.standing, true, nil, false)

    StartThread(threadStarter)
    StartThread(threadStateStarter)
    StartThread(headAnimationLoop)
    StartThread(speedControl)
    StartThread(noCapesControl, LowArm1, LowArm2)
  
    orgHousePosTable = sharedComputationResult("orgHousePosTable",
                                               computeOrgHouseTable, UnitDefs,
                                               math.huge, GameConfig)
    StartThread(rainyDayCare)
end

function umbrellaCondition(boolSunUmbrella)
    return isANormalDay() and (isRaining() or boolSunUmbrella and not isNight())
end

function rainyDayCare()
    if not TablesOfPiecesGroups["Umbrella"] then return end
    umbrellaIndex = (unitID % #TablesOfPiecesGroups["Umbrella"] )+1
    local Umbrella = TablesOfPiecesGroups["Umbrella"][umbrellaIndex]
    local boolSunUmbrella = randChance(10)

    while Umbrella do
        if umbrellaCondition(boolSunUmbrella) then
            while umbrellaCondition(boolSunUmbrella) do
                Show(Umbrella)
                Sleep(15000)
            end
            Hide(Umbrella)
        end
        Sleep(10000)
    end
end

function getVectorTable(pieceName)
    ex, ey, ez = Spring.GetUnitPiecePosition(unitID, pieceName)
    return {x=ex,y=ey, z=ez}
end

function noCapesControl( leftPiece, rightPiece)
if not TablesOfPiecesGroups["Coat"] then return end

coatMap= {
    single= {
        left = {
            start = 2,
            ends = 4,
            degStart=100,
            degEnd= 30
        },
        right = {
           start = 5,
           ends = 7,
            degStart=-100,
            degEnd= -30

        }
    },
both = {
    start = 8,
    ends= 10
        }

}

getIntervalOrDefault = function(pieceID, name)
    vR = getVectorTable(pieceID)
    degVal =  math.deg(math.atan2(vR.x,vR.z))

        intervals = coatMap.single[name].ends - coatMap.single[name].start
        arc = math.abs(coatMap.single[name].degStart -  coatMap.single[name].degEnd)
        arcseg = arc/intervals
        if math.abs(degVal-coatMap.single[name].degStart) < 10 then return false, 1 end 

    for i=0, intervals do
        if inLimit(i*arcseg, degVal,(i+1)*arcseg) == true then
            return true, coatMap.single[name].start+i
        end
    end

  return false, 1
end

hideT(TablesOfPiecesGroups["Coat"])
defaultCoat = TablesOfPiecesGroups["Coat"][1]
Show(defaultCoat)
while true do
    leftValue, leftIndex = getIntervalOrDefault( leftPiece, "left")
    rightValue, rightIndex = getIntervalOrDefault ( rightPiece, "right")
    
    hideT(TablesOfPiecesGroups["Coat"])
    if not leftValue and not rightValue then Show(defaultCoat) end
    if leftValue and not rightValue then Show(TablesOfPiecesGroups["Coat"][leftIndex]) end
    if not leftValue and  rightValue then Show(TablesOfPiecesGroups["Coat"][rightIndex]) end

    if leftValue and rightValue then
        leftIndex = leftIndex - coatMap.single.left.start
        rightIndex = rightIndex - coatMap.single.right.start
        midIndex = math.min(coatMap.both.start + math.floor((leftIndex+rightIndex)/2), coatMap.both.ends)
        Show(TablesOfPiecesGroups["Coat"][midIndex])
    end
Sleep(250)
end

end

function speedControl()
    Sleep(100)
    setSpeedIntern(unitID, NORMAL_WALK_SPEED) 
    while true do

    if damagedCoolDown > 0 then
        setSpeedIntern(unitID, SPRINT_SPEED) 
        while damagedCoolDown > 0 do
            Sleep(100)
            damagedCoolDown = damagedCoolDown -10

        end
        setSpeedIntern(unitID, NORMAL_WALK_SPEED) 
    end

    if GG.GlobalGameState ~= GameConfig.GameState.normal  then
        setSpeedIntern(unitID, 0.85)
        while GG.GlobalGameState ~= GameConfig.GameState.normal do
            Sleep(1000)
            if  GG.DamageHeatMap and GG.DamageHeatMap.getDangerAtLocation then
                x,y, z = Spring.GetUnitPosition(unitID)
                normalizedDanger =GG.DamageHeatMap:getDangerAtLocation(x,z)
                if normalizedDanger > 0.5 then
                    setSpeedIntern(unitID, normalizedDanger)
                end
            end
        end
        setSpeedIntern(unitID, NORMAL_WALK_SPEED) 
    end

    Sleep(500)
    end
end

function headAnimationLoop()
    while true do
        if boolAiming == false then
            WaitForTurns(Head1)
            headTurnValue = math.random(-10,10)
            if TablesOfPiecesGroups["Eye"] then
                rx,ry,rz = math.random(-40,40)/10, math.random(-40,40)/10, math.random(-40,40)/10
                tP(TablesOfPiecesGroups["Eye"][1],rx,ry,rz, 16)
                tP(TablesOfPiecesGroups["Eye"][2],rx,ry,rz, 16)
            end
            Turn(Head1,y_axis, math.rad(headTurnValue), 1)
            WaitForTurns(Head1)
        end
    interval = math.random(500, 5000)
    Sleep(interval)
    end
end

function attachLoot()
    transportID =  Spring.GetUnitIsTransporting(unitID) 
    if not transportID then 
       val = math.random(1,25)
       Sleep(val)
       lootID = createUnitAtUnit(myTeamID, "civilianloot", unitID)
       if lootID then
       Spring.UnitAttach( unitID, lootID, UpBody)
       end
    end
end

function throwPayloads()
    if lootID and doesUnitExistAlive(lootID) then Spring.UnitDetach(lootID) end
    Hide(ShoppingBag)
    Hide(SittingBaby)
    Hide(trolley)
    Hide(Handbag)
end


function bodyBuild()
    hideAll(unitID)
    Show(UpBody)
    Show(center)
    showT(TablesOfPiecesGroups["UpLeg"])
    showT(TablesOfPiecesGroups["LowLeg"])
    showT(TablesOfPiecesGroups["LowArm"])
    showT(TablesOfPiecesGroups["UpArm"])
    showOnePiece(TablesOfPiecesGroups["Head"], unitID)
    showT(TablesOfPiecesGroups["Feet"])
    if TablesOfPiecesGroups["Hand"] then showT(TablesOfPiecesGroups["Hand"]) end
    if TablesOfPiecesGroups["Suit"] and not (maRa() == maRa()) then showT(TablesOfPiecesGroups["Suit"]) end
    if TablesOfPiecesGroups["Eye"] then showT(TablesOfPiecesGroups["Eye"]) end


    if math.random(0, 4) > 3 or GG.GlobalGameState ~=  GameConfig.GameState.normal then Show(MilitiaMask) end

    if bodyConfig.boolArmed == true then
        Show(MilitiaMask) 
        if bodyConfig.boolRPGCarrying == true then
            bodyConfig.boolRPGArmed = true
            RPG7 = piece("RPG7")
            RPG7Rocket = piece("RPG7Rocket")

            Show(RPG7)
            Show(RPG7Rocket)
        else
            Show(myGun)
            Show(molotow)
        end
        return
    end

  
    if GG.GlobalGameState == GameConfig.GameState.normal  then
       dropLoot()
    end
 

    if bodyConfig.boolLoaded == true and bodyConfig.boolWounded == false then

        if iShoppingConfig == 1 then
            Show(ShoppingBag);
            return
        end

        if iShoppingConfig == 2 then
            Show(SittingBaby);
            return
        end

        if iShoppingConfig == 3 then
            Show(trolley);
            return
        end

        if iShoppingConfig == 4 then
            Show(Handbag);
            return
        end
    end
end

function hideAllProps()
    Hide(MilitiaMask)
    Hide(ak47)    
    hideT(TablesOfPiecesGroups["Weapons"])
    Hide(molotow)
    bodyConfig.boolLoaded = false
    bodyConfig.boolWounded = false
    hideT(TablesOfPiecesGroups["cellphone"])
    Hide(cofee)
    Hide(cigarett)
    Hide(ShoppingBag)
    Hide(SittingBaby)
    Hide(trolley)
    Hide(Handbag)
end
---------------------------------------------------------------------ANIMATIONLIB-------------------------------------
---------------------------------------------------------------------ANIMATIONLIB-------------------------------------
---------------------------------------------------------------------ANIMATIONS-------------------------------------
-- +STOPED+---------------------------------------------------+    +----------------------------+
-- |                                                          |    |Aiming/Assaultanimation:    |
-- |  +--------------+         +----------------------------+ |    |Stick                       |
-- |  |Transfer Pose |         |Idle Animations:            | |    |Molotowcocktail             |
-- |  +--------+----++         |talk Cycle, debate-intensity| |    |Fist                        |
-- |           ^    ^          |stand alone idle:           | |    |                            |
-- |           |    |          |cellphone,                  | |    |                            |
-- |           |    |          |smoking, squatting          | |    |                            |
-- |           |    +--------->+prayer                      | |    |                            |
-- |           |    |          |sleep on street             | |    |                            |
-- |           |    |          +----------------------------+ |    +----------------------------+
-- |           |    |          +----------------------------+ |
-- |           |    |          |   ReactionAnimation:       | |    +----------------------------+
-- |           |    |          |           Catastrophe:     | |    | Hit-Animation              |
-- |           |    |          |             filming        | |    |touch Wound/ hold wound     |
-- |           |    +--------->+             whailing       | |    |                            |
-- |           |    |          |             Protesting     | |    |                            |
-- |           |    |          +----------------------------+ |    |                            |
-- |           |    |          +-------------------------+    |    |                            |
-- |           |    +----------> Hit Animation           |    |    |                            |
-- |           |               | touch Wound/ hold wound |    |    +----------------------------+
-- +----------------------------------------------------------+
-- +-Walking+-------------------------------------------------+  +-------------------------------------+
-- |           v                                              |  |Death Animation                      |
-- | +---------+-------------------------+                    |  |Blasteded                            |
-- | |Transfer Pose|TransferPose Wounded +<--+                |  |Swirlingng                           |
-- | +-----------------------------------+   |                |  |Suprised                             |
-- +-----------------------------------------v----------------+  Collapsing, Shivering, Coiling Up     |
-- |    Walk Animation:                                       |  |                                     |
-- |walk Cycles: Normal/ Wounded/ Carrying/ Cowering/Run      |  +-------------------------------------+
-- |-----------------------------------------------------------

-- Animation StateMachine
-- Every Animation optimized for fast blending
-- Health movement loops
-- Allows for External Override
-- AnimationStates have abort Condition
-- Animations can be diffrent depending on buildScript (State_Idle/Walk Animation loaded)
-- Usually the Lower animation state is the master- but the upper can detach, so seperate upper Body Animations are possible

uppperBodyAnimations = {
    [eAnimState.aiming] = {[1] = "UPBODY_AIMING"},
    [eAnimState.slaved] = {[1] = "SLAVED"},
    [eAnimState.idle] = {
        [1] = "SLAVED",
        [2] = "UPBODY_PHONE",
        [3] = "UPBODY_CONSUMPTION"
    },
    [eAnimState.filming] = {[1] = "UPBODY_FILMING", [2] = "UPBODY_PHONE"},
    [eAnimState.wailing] = {[1] = "UPBODY_WAILING1", [2] = "UPBODY_WAILING2"},
    [eAnimState.talking] = {
        [1] = "UPBODY_AGGRO_TALK",
        [2] = "UPBODY_NORMAL_TALK"
    },
    [eAnimState.walking] = {[1] = "UPBODY_LOADED"},
    [eAnimState.protest] = {[1] = "UPBODY_PROTEST"},
    [eAnimState.handsup] = {[1] = "UPBODY_HANDSUP"}
}

lowerBodyAnimations = {
    [eAnimState.walking] = {[1] = "WALKCYCLE_UNLOADED"},
    [eAnimState.wounded] = {[1] = "WALKCYCLE_WOUNDED"},
    [eAnimState.coverwalk] = {[1] = "WALKCYCLE_COVERWALK"},
    [eAnimState.trolley] = {[1] = "WALKCYCLE_ROLLY"}

}


accumulatedTimeInSeconds = 5


function script.HitByWeapon(x, z, weaponDefID, damage)
    transportID = spGetUnitIsTransporting(unitID)
    if  transportID then --if holds loot        
        Spring.UnitDetach(transportID)
    end
    clampedDamage = math.max(math.min(damage, 10), 35)
    StartThread(delayedWoundedWalkAfterCover, clampedDamage)
    accumulatedTimeInSeconds = accumulatedTimeInSeconds + clampedDamage
    bodyConfig.boolCoverWalk = true
    bodyConfig.boolLoaded = false
    bodyConfig.boolWounded = true
    if damage > 10 and randChance(10) then
        echo("Damage to civilian drawing blood at "..locationstring(unitID))
        bloodyHell= {"bloodspray", "bloodslay"}
        StartThread(spawnCegAtPiece, unitID, Head, bloodyHell[math.random(1,2)])
    end
    bodyBuild()
    --Set coverwalk or wounded walk
    StartThread(setAnimationState, getWalkingState(), getWalkingState())
    damagedCoolDown = damagedCoolDown + (damage )
end

STATE_STARTED = "STARTED"
STATE_ENDED = "ENDED"
function setCivilianUnitInternalStateMode(unitID, State)
     if not GG.CivilianUnitInternalLogicActive then GG.CivilianUnitInternalLogicActive = {} end
     
     GG.CivilianUnitInternalLogicActive[unitID] = State 
 end

filmLocation = {}
boolStartFilming = false
function startFilmLocation(ux, uy, uz, time)
    setCivilianUnitInternalStateMode(unitID, STATE_STARTED)
    filmLocation.x=ux
    filmLocation.y=uy
    filmLocation.z=uz
    filmLocation.time = time
    boolStartFilming = true
    return true
end

wailingTime = 0
boolStartWailing = false
function startWailing(time)
    setCivilianUnitInternalStateMode(unitID, STATE_STARTED)
    wailingTime = time
    boolStartWailing = true
    return true
end

chattingTime = 0
boolStartChatting = false
function startChatting(time)
    setCivilianUnitInternalStateMode(unitID, STATE_STARTED)
    chattingTime = time
    boolStartChatting = true
    return true
end

attackerID = 0
boolStartFleeing = false 
function startFleeing(enemyID)
    attackerID = enemyID
--    echo("Start fleeing called in civilian")
    setCivilianUnitInternalStateMode(unitID, STATE_STARTED)
    boolStartFleeing = true
    return true
end

boolStartPeaceFullProtest = false
socialEngineerID = nil
function startPeacefullProtest( id)
    setCivilianUnitInternalStateMode(unitID, STATE_STARTED)
	socialEngineerID= id
    boolStartPeaceFullProtest = true
    return true
end

function peacefullProtest()
    Signal(SIG_INTERNAL)
    SetSignalMask(SIG_INTERNAL)
    if maRa()== true then
	   makeProtestSign(8, 3, 34, 62, peacfulProtestSignMessages[socialEngineerID % #peacfulProtestSignMessages+ 1], playerName)
    end

    myOffsetX = (math.random(0,15)+ (unitID % 15))*randSign()
    myOffsetZ = (math.random(0,15)+ (unitID % 5))*randSign()

    while doesUnitExistAlive(socialEngineerID) == true do
        PlayAnimation("UPBODY_PROTEST", lowerBodyPieces, 1.0)        
		WaitForTurns(upperBodyPieces)
		pos = {}
		pos.x,_,pos.z = Spring.GetUnitPosition(socialEngineerID)
        if pos.x then
            pos.x = myOffsetX + pos.x 
            pos.z = myOffsetZ + pos.z
        end
		Command(unitID, "go", {x = pos.x, y = 0, z = pos.z})
        Sleep(3000)
    end
	GG.SocialEngineeredPeople[unitID] = nil
    resetT(upperBodyPieces,2.0, false, true)
	hideProtestSign()
    setCivilianUnitInternalStateMode(unitID, STATE_ENDED)
end


boolStartPraying = false
function startPraying()
    setCivilianUnitInternalStateMode(unitID, STATE_STARTED)
    boolStartPraying = true
    return true
end

--
function pray()
    Signal(SIG_INTERNAL)
    SetSignalMask(SIG_INTERNAL)
    prayTime= 12000
    setSpeedEnv(unitID, 0.0)
    interpolation= 0.1
    orgRotation = Spring.GetUnitRotation(unitID)
    while prayTime > 0 do
        PlayAnimation("UPBODY_PRAY", lowerBodyPieces, 1.0)         
        WaitForTurns(upperBodyPieces)
        if not GG.PrayerRotationRad then 
            val = math.random(0,360)
            GG.PrayerRotationRad =  math.rad(val)
         end
         targetRotation = mix( GG.PrayerRotationRad, orgRotation,interpolation)
         Spring.SetUnitRotation(unitID, 0, targetRotation, 0)
         interpolation = math.min(1.0,interpolation + 0.1)
        prayTime = prayTime - 500
        WaitForTurns(upperBodyPieces)
        WaitForTurns(lowerBodyPieces)
        Sleep(500)
    end
    setSpeedEnv(unitID, NORMAL_WALK_SPEED)
    resetT(upperBodyPieces,2.0, false, true)
    Move(center,z_axis, 0, 2500)
    setCivilianUnitInternalStateMode(unitID, STATE_ENDED)
end

boolStartAnarchyBehaviour = false
function startAnarchyBehaviour()
    setCivilianUnitInternalStateMode(unitID, STATE_STARTED)
    boolStartAnarchyBehaviour = true
    return true
end

function anarchyBehaviour()   
    oldBehaviourState = GameConfig.GameState.normal
    newState = GG.GlobalGameState

    if not GG.AnarchySexCoupleSpawnFrame  then GG.AnarchySexCoupleSpawnFrame = Spring.GetGameFrame() - 1 end

    if GG.AnarchySexCoupleSpawnFrame  + GameConfig.anarchySexCouplesEveryNSeconds * 30 < Spring.GetGameFrame() and math.random(1,100) == 69 and maRa() ==true then
        StartThread(haveSexTimeDelayed)
        return
    end


    while GG.GlobalGameState ~= GameConfig.GameState.normal do
        normalBehavourStateMachine[newState](oldBehaviourState, GG.GlobalGameState, unitID)
        oldBehaviourState = GG.GlobalGameState
        Sleep(250)
    end

    setCivilianUnitInternalStateMode(unitID, STATE_ENDED)
end

function haveSexTimeDelayed()
    GG.AnarchySexCoupleSpawnFrame = Spring.GetGameFrame() - 1
    id ,pos = randDict(GG.BuildingTable)
    while distanceUnitToUnit(unitID, id ) > 200 do
        Command(unitID, "go", { x=pos.x, y= 0, z= pos.z})
        Command(unitID, "go", { x=pos.x, y= 0, z= pos.z}, "shift")
        Sleep(500)
    end
    GG.AnarchySexCoupleSpawnFrame = Spring.GetGameFrame() - 1
    createUnitAtUnit(unitID, "civilian_orgy_pair", unitID, 0, 0, 0)
    Spring.DestroyUnit(unitID, true, false)
end

boolStartAerosolBehaviour = false
aeroSolType = "undefinedAerosolState"
function startAerosolBehaviour(extAerosolStateToSet)
    boolStartAerosolBehaviour= true
    aeroSolType = extAerosolStateToSet
    setCivilianUnitInternalStateMode(unitID, STATE_STARTED)
end

function aeroSolStateBehaviour()
   -- Spring.Echo("Civilian "..unitID.. " starting internal aerosol behaviour")
    centerCopy= center
    if  spGetUnitDefID(unitID) == UnitDefNames["civilian_arab4"] then
        centerCopy = Head1
    end

    influencedStateMachine = getAerosolInfluencedStateMachine(UnitID, UnitDefs, aeroSolType, center, UpArm1, UpArm2, Head1)
    assert(influencedStateMachine)
    hideAllProps(bodyConfig)
    bodyConfig.boolInfluenced = true
    newState = aeroSolType
    oldBehaviourState = aeroSolType
      while newState ~= "Exit" do
        newState = influencedStateMachine(oldBehaviourState, newState, unitID)
        Sleep(250)
        oldBehaviourState = newState
    end
    Spring.DestroyUnit(unitID, true, false)
end

function wailing()
    Signal(SIG_INTERNAL)
    SetSignalMask(SIG_INTERNAL)
    throwPayloads()

    while wailingTime > 0 do
        throwArmsUp()
        PlayAnimation("UPBODY_WAILING"..math.random(1,2), lowerBodyPieces, 1.0)
       wailingTime = wailingTime - 1500
        Sleep(100)
    end
    setCivilianUnitInternalStateMode(unitID, STATE_ENDED)
end

function alignToPersonNearby()
    Result= foreach(
        getAllNearUnit(unitID, GameConfig.groupChatDistance + 100),
        function(id)
            if id~=unitID and civilianWalkingTypeTable[spGetUnitDefID(id)] then return id end
        end
        )
    if Result and Result[1] then
        Command(unitID,"go",  Result[1], {})
        return true
    end
    return false
end

function chatting()
    Signal(SIG_INTERNAL)
    SetSignalMask(SIG_INTERNAL)

   if not alignToPersonNearby() then
        setCivilianUnitInternalStateMode(unitID, STATE_ENDED)
        return
   end

    repeatCounter = 0
    while chattingTime > 0 do
        if maRa() == true then
            PlayAnimation("UPBODY_NORMAL_TALK", lowerBodyPieces, math.random(10,20)/10)
        else
            PlayAnimation("UPBODY_AGGRO_TALK", lowerBodyPieces, math.random(10,30)/10)
        end     
        

       headVal = math.random(-20,20)
       if maRa() == maRa() then
            T = foreach(getAllNearUnit(unitID, 150, gaiaTeamID),
                        function(id)
                            defID = spGetUnitDefID(id)
                            if civilianWalkingTypeTable[id] then
                                return id
                            end
                        end
                        )
            if #T > 1 then
                lookAtHim = T[math.random(1, #T)]
                x,y,z = spGetUnitPosition(lookAtHim)
                mx,my,mz = spGetUnitPosition(unitID)
                _,myRotation,_ = Spring.GetUnitRotation(unitID)
                headVal = math.deg(myRotation -(math.atan2(x-mx, z-mz)))
                echo(unitID.." looking at ".. lookAtHim.." with ".. headVal)
            end

       end

       headVal = clamp(-20, headVal, 20)
       Turn(Head1,y_axis,math.rad(headVal),1.5)
       WaitForTurns(Head1)

       chattingTime = chattingTime - 500
       repeatCounter = repeatCounter + 1
        Sleep(100)
        if repeatCounter % 2 == 0 then
            if not alignToPersonNearby() then
                setCivilianUnitInternalStateMode(unitID, STATE_ENDED)
                return
            end  
        end  
    end
    Spring.Echo("civilian "..unitID.. " chat has ended")
    playUpperBodyIdleAnimation()
    resetT(TablesOfPiecesGroups["UpArm"], math.pi, false, true)
    setCivilianUnitInternalStateMode(unitID, STATE_ENDED)
end

function filmingLocation()
    Signal(SIG_INTERNAL)
    SetSignalMask(SIG_INTERNAL)
    Show(cellphone1)
    while filmLocation.time > 0 do
        PlayAnimation("UPBODY_FILMING", lowerBodyPieces, 1.0)
        filmLocation.time = filmLocation.time - 2000
        setUnitRotationToPoint(unitID, filmLocation.x, filmLocation.y, filmLocation.z)
        Sleep(100)
    end
    setCivilianUnitInternalStateMode(unitID, STATE_ENDED)
end

function throwArmsUp()
    valr = math.random(80,115)
    vall = math.random(80,115)*-1
    Turn(UpArm1, z_axis, math.rad(valr), 50)
    Turn(UpArm2, z_axis, math.rad(vall), 50)
end

function fleeEnemy(enemyID)
    Signal(SIG_INTERNAL)
    SetSignalMask(SIG_INTERNAL)
    --echo("Actually fleeing a enemy")
    if not enemyID then 
        setCivilianUnitInternalStateMode(unitID, STATE_ENDED)
        return 
    end  
    throwPayloads()
      
    flightTime =  GameConfig.civilian.MaxFlightTimeMS
    while doesUnitExistAlive(enemyID) == true and flightTime > 0 and distanceUnitToUnit(unitID, enemyID) < GameConfig.civilian.PanicRadius do
        throwArmsUp()
        runAwayFrom(unitID, enemyID, GG.GameConfig.civilian.FleeDistance)
        distribution = math.random(1,10)
        Sleep(125 + distribution)
        flightTime = flightTime - 125
    end

    setCivilianUnitInternalStateMode(unitID, STATE_ENDED)
end

function delayedWoundedWalkAfterCover(timeInSeconds)
    setSpeedEnv(unitID, SPRINT_SPEED)
    Signal(SIG_COVER_WALK)
    SetSignalMask(SIG_COVER_WALK)
    Sleep(accumulatedTimeInSeconds * 1000)
    bodyConfig.boolWounded = true
    bodyConfig.boolCoverWalk = false
    setSpeedEnv(unitID, NORMAL_WALK_SPEED)
end

-- Civilian
-- Props:
-- -Abstract Female and Male Skeletton
-- - Bags, Luggage, Crates, Trolleys, Rucksack
-- - Cellphones, Handbags
-- Animation:
-- Walk Animation:
-- - walk Cycle
-- - cowering run Cycle
-- - run Cycle
-- - Carrying Animation

-- Idle-Animation:
-- - talk Cycle, debate-intensity
-- - stand alone idle: cellphone, smoking, squatting
-- - prayer
-- sleep on street
-- ReactionAnimation:
-- Catastrophe:
-- - filming
-- - whailing
-- - Protesting
-- Hit Animation:
-- - touch Wound/ hold wound

-- AttackAnimation:
-- - punching
-- - hitting with stick
-- - throwing molotow cocktail

-- Death Animation:
-- - Blasted
-- - Swirling
-- - Suprised 
-- -Collapsing, Shivering, Coiling Up

function setupAnimation()

    local switchAxis = function(axis)
        if axis == z_axis then return y_axis end
        if axis == y_axis then return z_axis end
        return axis
    end

    local offsets = constructSkeleton(unitID, map.center, {0, 0, 0});

    for a, anim in pairs(Animations) do
        for i, keyframe in pairs(anim) do
            local commands = keyframe.commands;
            for k, command in pairs(commands) do
                if command.p and type(command.p) == "string" then
                    if not  map[command.p] then                        
                        commands[k] = nil                        
                    else
                        command.p = map[command.p]

                        if (command.c == "move") then
                            local adjusted = command.t - (offsets[command.p][command.a]);
                            Animations[a][i]['commands'][k].t =
                                command.t - (offsets[command.p][command.a]);
                        end

                        Animations[a][i]['commands'][k].a = switchAxis(command.a)        
                    end
                end
                -- commands are described in (c)ommand,(p)iece,(a)xis,(t)arget,(s)peed format
                -- the t attribute needs to be adjusted for move commands from blender's absolute values
                
            end
        end
    end
end

local animCmd = {['turn'] = Turn, ['move'] = Move};

local axisSign = {[x_axis] = 1, [y_axis] = 1, [z_axis] = 1}

function PlayAnimation(animname, piecesToFilterOutTable, speed)
    local speedFactor = speed or 1.0
    if not piecesToFilterOutTable then piecesToFilterOutTable = {} end
    assert(animname, "animation name is nil")
    assert(type(animname) == "string",
           "Animname is not string " .. toString(animname))
    assert(Animations[animname], "No animation with name ")

    local anim = Animations[animname];
    local randoffset
    for i = 1, #anim do
        local commands = anim[i].commands;
        for j = 1, #commands do
            local cmd = commands[j];
            randoffset = 0.0
            if cmd.r then
                randVal = cmd.r * 100
                randoffset = math.random(-randVal, randVal) / 100
            end

            if cmd.ru or cmd.rl then
                randUpVal = (cmd.ru or 0.01) * 100
                randLowVal = (cmd.rl or 0) * 100
                randoffset = math.random(randLowVal, randUpVal) / 100
            end

            if not piecesToFilterOutTable[cmd.p] then
                animCmd[cmd.c](cmd.p, cmd.a,
                               axisSign[cmd.a] * (cmd.t + randoffset),
                               cmd.s * speedFactor)

            end
        end
        if (i < #anim) then
            local t = anim[i + 1]['time'] - anim[i]['time'];
            Sleep(t * 33 * math.abs(1 / speedFactor)); -- sleep works on milliseconds
        end
    end
end

function constructSkeleton(unit, piece, offset)
    if (offset == nil) then offset = {0, 0, 0}; end

    local bones = {};

    local info = Spring.GetUnitPieceInfo(unit, piece);

    for i = 1, 3 do info.offset[i] = offset[i] + info.offset[i]; end

    bones[piece] = info.offset;
    local map = Spring.GetUnitPieceMap(unit);
    local children = info.children;

    if (children) then
        for i, childName in pairs(children) do
            local childId = map[childName];
            local childBones = constructSkeleton(unit, childId, info.offset);
            for cid, cinfo in pairs(childBones) do
                bones[cid] = cinfo;
            end
        end
    end
    return bones;
end

local locAnimationstateUpperOverride
local locAnimationstateLowerOverride
local locBoolInstantOverride
local locConditionFunction
local boolStartThread = false

function attachToTruckNearby()
    T = foreach(getAllNearUnit(unitID, 100),
                        function(id)
                            if TruckTypeTable[spGetUnitDefID(id)] then
                                return id
                            end
                        end
                        )
                if T and #T > 0 then
                    assert(T[1])
                    assert(type(T[1])=="number")
                    Spring.UnitAttach (T[1], unitID, getPieceNrByName(T[1], "attachPoint") )
                end
    end


function tacticalAnarchy()

    currentPositionClusters = sharedComputationResult(
                                  "civilianAnarchyPositionClusters",
                                  computateClusterNodes, orgHousePosTable, 15,
                                  GameConfig)

    myPos = {}
    myPos.x, myPos.y, myPos.z = Spring.GetUnitPosition(unitID)
    nearestClusterNode = {}
    smallestDistance = math.huge
    foreach(currentPositionClusters, -- get nearest cluster
    function(cluster)
        if distance(myPos, cluster) < smallestDistance then
            smallestDistance = distance(myPos, cluster)
            nearestClusterNode = cluster
        end
    end)
    nearestClusterNode.x, nearestClusterNode.z =
        nearestClusterNode.x +
            math.random(-1 * GameConfig.demonstrationMarchRadius,
                        GameConfig.demonstrationMarchRadius),
        nearestClusterNode.z +
            math.random(-1 * GameConfig.demonstrationMarchRadius,
                        GameConfig.demonstrationMarchRadius)
    Command(unitID, "go", nearestClusterNode, {})

    Sleep(1000)

    if bodyConfig.boolArmed == true then

        T = foreach(getAllNearUnit(unitID, 512), function(id)
            if isUnitEnemy(myTeamID, id) == true and Spring.GetUnitIsCloaked(id) ==  false then 
                return id 
            end
        end)

        if T and #T > 0 then
            ed = randT(T) or Spring.GetUnitNearestEnemy(unitID)
            if ed then Command(unitID, "attack", ed, {}) end
        end
    end

end

normalBehavourStateMachine = {
    [GameConfig.GameState.launchleak] = function(lastState, currentState)
        -- init clause
        if lastState ~= currentState then
            if bodyConfig.boolLoaded == false then
                PlayAnimation("UPBODY_PHONE", lowerBodyPieces)
            end
        end

        -- Going home   
        Command(unitID, "go", {x = home.x, y = home.y, z = home.z}, {})
        Command(unitID, "go", {x = home.x, y = home.y, z = home.z}, {"shift"})

    end,
    [GameConfig.GameState.anarchy] = function(lastState, currentState)
        -- init clause
        if lastState ~= currentState then
            -- Spring.Echo("Civilian entering gamestate anarchy")
            Spring.SetUnitNeutral(unitID, false)
            Spring.SetUnitNoSelect(unitID, true)
            if not Spring.GetUnitIsTransporting(unitID)  and  GG.GlobalGameState ~= GameConfig.GameState.normal and math.random(1,5) == 5 then
                StartThread(attachLoot)
            end

            bodyConfig.boolArmed = (math.random(1, 100) > GameConfig.chanceCivilianArmsItselfInHundred)
                Hide(ShoppingBag)
                Hide(Handbag)
                Hide(cofee)
            if bodyConfig.boolArmed == true then
                Show(myGun)
                Show(MilitiaMask)
                if maRa()  then
                    attachToTruckNearby()
                end
            else
                bodyConfig.boolProtest = (math.random(1, 10) > 5)
                if bodyConfig.boolProtest == true then
                    playerName = getRandomPlayerName()
                    makeProtestSign(8, 3, 34, 62, signMessages[math.random(1,#signMessages)],playerName)
                    Show(MilitiaMask)
                    Show(molotow)
                    setOverrideAnimationState(eAnimState.protest, eAnimState.walking, false)
                end
            end

            -- pick a side - depending on the money
            if fairRandom("JoinASide", 5) == true then
                enemy = Spring.GetUnitNearestEnemy(unitID)
                if enemy then
                    targetTeamID = Spring.GetUnitTeam(enemy)
                    if targetTeamID then
                        Spring.TransferUnit(unitID, targetTeamID)
                    end
                end
            end
        end
        tacticalAnarchy()
        Sleep(500)

    end,
    [GameConfig.GameState.postlaunch] = function(lastState, currentState)
        Spring.SetUnitNeutral(unitID, true)
        Spring.TransferUnit(unitID, gaiaTeamID)

            setOverrideAnimationState(eAnimState.wailing, eAnimState.walking,
                                      true, nil, true)
            x, y, z = Spring.GetUnitPosition(unitID)
            if maRa()== true then
                Command(unitID, "go", {
                    x = x + math.random(-100, 100),
                    y = y,
                    z = z + math.random(-100, 100)
                })
            else
                runAwayFromPlace(unitID, Game.mapSizeX/2, 0, Game.mapSizeZ/2, 4096)
            end


    end,
    [GameConfig.GameState.gameover] = function(lastState, currentState)
        setOverrideAnimationState(eAnimState.catatonic, eAnimState.slaved, true,
                                  nil, false)
        setSpeedEnv(unitID, 0)
    end,
    [GameConfig.GameState.pacification] = function(lastState, currentState)
        if lastState ~= currentState then
            dropLoot()
            Spring.TransferUnit(unitID, gaiaTeamID)
            Spring.SetUnitNeutral(unitID, true)
            if bodyConfig.boolArmed == true then
                Hide(myGun)
                Explode(myGun, SFX.FALL + SFX.NO_HEATCLOUD)
                bodyConfig.boolArmed = false
            end

            if bodyConfig.boolProtest == true then
                Explode(ProtestSign, SFX.FALL + SFX.SHATTER + SFX.NO_HEATCLOUD)
            end
            reset(UpBody, 60)
            reset(center, 45)
            Move(center, y_axis, 0, 60)

            PlayAnimation("UPBODY_HANDSUP")
            setSpeedEnv(unitID, NORMAL_WALK_SPEED)
           
            bodyConfig.boolArmed = false
            bodyConfig.boolProtest = false
            bodyBuild(bodyConfig)
            Command(unitID, "stop")
        end

    end
}

function threadStarter()
    Sleep(100)
    while true do
        if boolStartThread == true then
            boolStartThread = false
            StartThread(deferedOverrideAnimationState,
                        locAnimationstateUpperOverride,
                        locAnimationstateLowerOverride, locBoolInstantOverride,
                        locConditionFunction)
            while boolStartThread == false do Sleep(33) end
        end
        Sleep(33)
    end
end

function threadStateStarter()
    Sleep(100)
    while true do
        if boolStartFilming == true then
            boolStartFilming = false
            echo("Starting filming at location "..locationstring(unitID))
            StartThread(filmingLocation)
        end
        if boolStartWailing == true then
            boolStartWailing = false
            StartThread(wailing)
        end

        if boolStartChatting == true then
            boolStartChatting = false
            StartThread(chatting)
            echo("Starting chatting at location "..locationstring(unitID).." for ".. chattingTime.. " ms")
        end

        if boolStartFleeing == true then
            boolStartFleeing = false
            StartThread(fleeEnemy, attackerID)
        end

        if boolStartPraying == true then
            boolStartPraying = false
            StartThread(pray)
        end
		
		if boolStartPeaceFullProtest == true then
			boolStartPeaceFullProtest = false
			StartThread(peacefullProtest)
		end

        if boolStartAnarchyBehaviour == true then
            boolStartAnarchyBehaviour = false
            StartThread(anarchyBehaviour)
        end
        --TODO: Hunt revealed antagon agents?

         if boolStartAerosolBehaviour == true then
            boolStartAerosolBehaviour = false
             StartThread(aeroSolStateBehaviour)
             while true do Sleep(10000); end
        end
        Sleep(250)   
    end
end


function deferedOverrideAnimationState(AnimationstateUpperOverride,
                                       AnimationstateLowerOverride,
                                       boolInstantOverride, conditionFunction)

    if boolInstantOverride == true then
        if AnimationstateUpperOverride then
            -- echo(unitID.." Starting new Animation State Machien Upper")
            UpperAnimationState = AnimationstateUpperOverride
            StartThread(animationStateMachineUpper, UpperAnimationStateFunctions)
        end
        if AnimationstateLowerOverride then
            -- echo(unitID.." Starting new Animation State Machien Lower")
            LowerAnimationState = AnimationstateLowerOverride
            StartThread(animationStateMachineLower, LowerAnimationStateFunctions)
        end

    else
        StartThread(setAnimationState, AnimationstateUpperOverride,
                    AnimationstateLowerOverride)
    end

    if conditionFunction then StartThread(conditionFunction) end
end

function setAnimationState(AnimationstateUpperOverride,
                           AnimationstateLowerOverride)
    -- if we are already animating correctly early out
    if AnimationstateUpperOverride == UpperAnimationState and
        AnimationstateLowerOverride == LowerAnimationState then return end

    Signal(SIG_ANIM)
    SetSignalMask(SIG_ANIM)

    if AnimationstateUpperOverride then boolUpperStateWaitForEnd = true end
    if AnimationstateLowerOverride then boolLowerStateWaitForEnd = true end

    while AnimationstateLowerOverride and boolLowerAnimationEnded == false or
        AnimationstateUpperOverride and boolUpperAnimationEnded == false do
        Sleep(30)
        if AnimationstateUpperOverride == true then
            boolUpperStateWaitForEnd = true
        end

        if AnimationstateLowerOverride == true then
            boolLowerStateWaitForEnd = true
        end

        Sleep(30)
    end

    if AnimationstateUpperOverride then
        UpperAnimationState = AnimationstateUpperOverride
    end
    if AnimationstateLowerOverride then
        LowerAnimationState = AnimationstateLowerOverride
    end
    if boolUpperStateWaitForEnd == true then boolUpperStateWaitForEnd = false end
    if boolLowerStateWaitForEnd == true then boolLowerStateWaitForEnd = false end
end

-- <Exposed Function>
function setOverrideAnimationState(AnimationstateUpperOverride,
                                   AnimationstateLowerOverride,
                                   boolInstantOverride, conditionFunction,
                                   boolDecoupledStates)
    boolDecoupled = boolDecoupledStates
    locAnimationstateUpperOverride = AnimationstateUpperOverride
    locAnimationstateLowerOverride = AnimationstateLowerOverride
    locBoolInstantOverride = boolInstantOverride or false
    locConditionFunction = conditionFunction or (function() return true end)
    boolStartThread = true
end

-- </Exposed Function>
function conditionalFilterOutUpperBodyTable()
    if boolDecoupled == true or boolAiming == true then
        return upperBodyPieces
    else
        return walkMotionExcludeTable
    end
end

function cigarettGlowAndSmoke()
    if isTransported(unitID) then return end
    Sleep(500)
    spawnCegAtPiece(unitID, cigarett, "cigarettglowsmoke")
end

function showHideProps(selectedIdleFunction, bShow)
    -- 1 slaved
    if selectedIdleFunction == 2 then
        index = unitID % (#TablesOfPiecesGroups["cellphone"])
        index = math.min(#TablesOfPiecesGroups["cellphone"], math.max(1, index))
        showHide(TablesOfPiecesGroups["cellphone"][index], bShow)
    elseif selectedIdleFunction == 3 then -- consumption
        if unitID % 2 == 1 then
            showHide(cigarett, bShow)
            StartThread(cigarettGlowAndSmoke)
        else
            showHide(cofee, bShow)
        end
    end

end

function playUpperBodyIdleAnimation()
    if bodyConfig.boolLoaded == false then
        selectedIdleFunction =
            (unitID % #uppperBodyAnimations[eAnimState.idle]) + 1
        showHideProps(selectedIdleFunction, true)
        PlayAnimation(
            uppperBodyAnimations[eAnimState.idle][selectedIdleFunction])
        showHideProps(selectedIdleFunction, false)
    end
end

UpperAnimationStateFunctions = {
    [eAnimState.catatonic] = function()
        PlayAnimation(randT(uppperBodyAnimations[eAnimState.wailing]),
                      catatonicBodyPieces)
        return eAnimState.catatonic
    end,
    [eAnimState.talking] = function()
        if bodyConfig.boolLoaded == false then
            PlayAnimation(randT(uppperBodyAnimations[eAnimState.talking]))
        end
        return eAnimState.talking
    end,
    [eAnimState.standing] = function()
        Sleep(30)
        if bodyConfig.boolInfluenced then
            PlayAnimation("UPBODY_STANDING_ZOMBIE")
            return eAnimState.walking
        end

        if bodyConfig.boolArmed == true then
            PlayAnimation(randT(uppperBodyAnimations[eAnimState.aiming]),
                          lowerBodyPieces)
            return eAnimState.standing
        end

        if bodyConfig.boolProtest == true then
            PlayAnimation(randT(uppperBodyAnimations[eAnimState.protest]),
                          lowerBodyPieces)
            return eAnimState.standing
        end

        if bodyConfig.boolLoaded == true then return eAnimState.standing end

        if bodyConfig.boolLoaded == false then
            Turn(LowArm1, y_axis, math.rad(12), 1)
            Turn(LowArm2, y_axis, math.rad(-12), 1)
            WaitForTurns(TablesOfPiecesGroups["LowArm"])
        end

        if boolDecoupled == true then
            if math.random(1, 10) > 5 then
                playUpperBodyIdleAnimation()
                resetT(TablesOfPiecesGroups["UpArm"], math.pi, false, true)
            end
        end

        return eAnimState.standing
    end,
    [eAnimState.walking] = function()
        if bodyConfig.boolInfluenced then
            PlayAnimation("UPBODY_WALK_ZOMBIE", walkMotionExcludeTable)
            return eAnimState.walking
        end

        if bodyConfig.boolArmed == true then
            PlayAnimation("UPBODY_LOADED", walkMotionExcludeTable)
            return eAnimState.walking
        end

        if bodyConfig.boolProtest == true then return eAnimState.protest end

        if bodyConfig.boolLoaded == true then
            PlayAnimation("UPBODY_LOADED", walkMotionExcludeTable)
            return eAnimState.walking
        end

        if bodyConfig.boolLoaded == false then

            if math.random(1, 100) > 75 then
                playUpperBodyIdleAnimation()
                WaitForTurns(upperBodyPieces)
                -- resetT(upperBodyPieces, math.pi,false, true)
                return eAnimState.walking
            else
                GameFrame = Spring.GetGameFrame()
                Turn(UpArm1, z_axis, math.rad(-25), math.pi)
                Turn(UpArm2, z_axis, math.rad(25), math.pi)
                Turn(UpArm1, x_axis,
                     math.rad(25 * math.sin(unitID + GameFrame / 15)),
                     math.pi * 2)
                Turn(UpArm2, x_axis,
                     math.rad(25 * math.cos(unitID + GameFrame / 15)),
                     math.pi * 2)
                WaitForTurns(upperBodyPieces)
                return eAnimState.walking
            end
        end

        return eAnimState.walking
    end,
    [eAnimState.filming] = function()
        cellID = (unitID % 2) + 1
        Show(TablesOfPiecesGroups["cellphone"][cellID])
        PlayAnimation(randT(uppperBodyAnimations[eAnimState.filming]))
        Hide(TablesOfPiecesGroups["cellphone"][cellID])
        return eAnimState.filming
    end,
    [eAnimState.wailing] = function()
        PlayAnimation(randT(uppperBodyAnimations[eAnimState.filming]))

        return eAnimState.wailing
    end,
    [eAnimState.handsup] = function()
        PlayAnimation(randT(uppperBodyAnimations[eAnimState.handsup]))
        return eAnimState.handsup
    end,

    [eAnimState.protest] = function()

        PlayAnimation(randT(uppperBodyAnimations[eAnimState.protest]))
        return eAnimState.protest
    end,

    [eAnimState.slaved] = function()
        Sleep(100)
        return eAnimState.slaved
    end,
    [eAnimState.coverwalk] = function()
        Hide(ShoppingBag);
        Hide(SittingBaby);
        Hide(trolley);
        Hide(Handbag);

        Sleep(100)
        Turn(UpArm1, z_axis, math.rad(0), 7)
        Turn(UpArm1, y_axis, math.rad(0), 7)
        Turn(UpArm1, x_axis, math.rad(-120), 7)

        Turn(LowArm1, y_axis, math.rad(0), 7)
        Turn(LowArm1, x_axis, math.rad(-60), 7)
        Turn(LowArm1, z_axis, math.rad(-45), 7)

        Turn(UpArm2, x_axis, math.rad(-120), 7)
        Turn(UpArm2, y_axis, math.rad(0), 7)
        Turn(UpArm2, z_axis, math.rad(0), 7)

        Turn(LowArm2, x_axis, math.rad(-60), 7)
        Turn(LowArm2, y_axis, math.rad(0), 7)
        Turn(LowArm2, z_axis, math.rad(45), 7)
        return eAnimState.coverwalk
    end,
    [eAnimState.wounded] = function()
        Sleep(100)
        return eAnimState.wounded
    end,

    [eAnimState.aiming] = function()
        Sleep(100)
        PlayAnimation(randT(uppperBodyAnimations[eAnimState.aiming]),
                      lowerBodyPieces)
        return eAnimState.aiming
    end

}

LowerAnimationStateFunctions = {
    [eAnimState.standing] = function()
        if bodyConfig.boolInfluenced then
            PlayAnimation("LOWBODY_STANDING_ZOMBIE")
            return eAnimState.walking
        end

        -- Spring.Echo("Lower Body standing")
        WaitForTurns(lowerBodyPieces)
        resetT(lowerBodyPiecesNoCenter, math.pi, false, true)
        WaitForTurns(lowerBodyPiecesNoCenter)
        Sleep(10)
        return eAnimState.standing
    end,
    [eAnimState.aiming] = function()

        WaitForTurns(lowerBodyPieces)
        resetT(lowerBodyPieces, math.pi, false, true)
        WaitForTurns(lowerBodyPieces)
        Sleep(10)
        return eAnimState.aiming
    end,
    [eAnimState.walking] = function()
        if bodyConfig.boolInfluenced then
            if maRa() == true then
                PlayAnimation("LOWBODY_WALKING_ZOMBIE")
                return eAnimState.walking
            else
                PlayAnimation(randT(lowerBodyAnimations[eAnimState.wounded],
                                    conditionalFilterOutUpperBodyTable()))
                return eAnimState.walking
            end
        end

        if bodyConfig.boolArmed == true then
            PlayAnimation(randT(lowerBodyAnimations[eAnimState.walking]),
                          conditionalFilterOutUpperBodyTable())
            return eAnimState.walking
        end

        Turn(center, y_axis, math.rad(0), 12)

        if bodyConfig.boolWounded == true then
            PlayAnimation(randT(lowerBodyAnimations[eAnimState.wounded],
                                conditionalFilterOutUpperBodyTable()))
            return eAnimState.walking
        end

        if bodyConfig.boolProtest == true then
            PlayAnimation(randT(lowerBodyAnimations[eAnimState.walking]),
                          upperBodyPieces)
            return eAnimState.walking
        end

        if bodyConfig.boolTrolley == true then
            PlayAnimation(randT(lowerBodyAnimations[eAnimState.walking]),
                          conditionalFilterOutUpperBodyTable())
        else
            PlayAnimation(randT(lowerBodyAnimations[eAnimState.walking]),
                          conditionalFilterOutUpperBodyTable())
        end

        return eAnimState.walking
    end,
    [eAnimState.transported] = function()
        --echo("TODO: Civilian State transported")
        return eAnimState.transported
    end,
    [eAnimState.slaved] = function()
        Sleep(100)
        return eAnimState.slaved
    end,
    [eAnimState.coverwalk] = function()
        PlayAnimation(randT(lowerBodyAnimations[eAnimState.wounded]),
                      upperBodyPieces)

        return eAnimState.coverwalk
    end,

    [eAnimState.wounded] = function()
        PlayAnimation(randT(lowerBodyAnimations[eAnimState.wounded]))
        return eAnimState.wounded
    end,
    [eAnimState.trolley] = function()

        PlayAnimation(randT(lowerBodyAnimations[eAnimState.trolley]))

        return eAnimState.trolley
    end,
    [eAnimState.aiming] = function()
        AimDelay = AimDelay + 100
        if boolWalking == true or AimDelay < 1000 then
            AimDelay = 0
            PlayAnimation(randT(lowerBodyAnimations[eAnimState.walking]),
                          upperBodyPieces)
        elseif AimDelay > 1000 then

            PlayAnimation(randT(lowerBodyAnimations[eAnimState.standing]),
                          upperBodyPieces)
        end
        Sleep(100)
        return eAnimState.aiming
    end

}

AimDelay = 0
LowerAnimationState = eAnimState.standing
boolLowerStateWaitForEnd = false
boolLowerAnimationEnded = false

function animationStateMachineLower(AnimationTable)
    Signal(SIG_LOW)
    SetSignalMask(SIG_LOW)

    boolLowerStateWaitForEnd = false

    local animationTable = AnimationTable
    -- Spring.Echo("lower Animation StateMachine Cycle")
    while true do
        assert(LowerAnimationState)
        assert(animationTable[LowerAnimationState],
               "Animationstate not existing " .. LowerAnimationState)
        LowerAnimationState = animationTable[LowerAnimationState]()

        -- Sync Animations
        -- echoNFrames("Unit "..unitID.." :LStatMach :"..LowerAnimationState, 500)
        if boolLowerStateWaitForEnd == true then
            boolLowerAnimationEnded = true
            while boolLowerStateWaitForEnd == true do
                Sleep(33)
                -- echoNFrames("Unit "..unitID.." :LWaitForEnd :"..LowerAnimationState, 500)
                -- Spring.Echo("lower Animation Waiting For End")
            end
            boolLowerAnimationEnded = false
        end
        Sleep(33)
    end
end

UpperAnimationState = eAnimState.standing
boolUpperStateWaitForEnd = false
boolUpperAnimationEnded = false

function animationStateMachineUpper(AnimationTable)
    Signal(SIG_UP)
    SetSignalMask(SIG_UP)

    boolUpperStateWaitForEnd = false
    local animationTable = AnimationTable

    while true do
        assert(UpperAnimationState)
        assert(animationTable[UpperAnimationState],
               "Upper Animationstate not existing " .. UpperAnimationState)

        UpperAnimationState = animationTable[UpperAnimationState]()
        -- echoNFrames("Unit "..unitID.." :UStatMach :"..UpperAnimationState, 500)
        -- Sync Animations
        if boolUpperStateWaitForEnd == true then
            boolUpperAnimationEnded = true
            while boolUpperStateWaitForEnd == true do
                Sleep(10)
                -- echoNFrames("Unit "..unitID.." :UWaitForEnd :"..UpperAnimationState, 500)
            end
            boolUpperAnimationEnded = false
        end
        Sleep(33)
    end
end

function delayedStop()
    Signal(SIG_STOP)
    SetSignalMask(SIG_STOP)
    Sleep(250)
    boolWalking = false
    -- Spring.Echo("Stopping")
    setOverrideAnimationState(eAnimState.standing, eAnimState.standing, true, nil, true)

    Sleep(2500)
    _,h, _ = Spring.GetUnitPosition(unitID)
    if h < -5 and not  GG.DisguiseCivilianFor[unitID] then
        Spring.DestroyUnit(unitID, false, true)
    end

end

function getWalkingState()
    if bodyConfig.boolCoverWalk == true then return eAnimState.coverwalk end
    if bodyConfig.boolWounded == true then return eAnimState.wounded end

    return eAnimState.walking
end

function script.StartMoving()
    boolWalking = true
    setOverrideAnimationState(eAnimState.walking, eAnimState.walking, true, nil, true)
end

function script.StopMoving() StartThread(delayedStop) end
---------------------------------------------------------------------ANIMATIONS-------------------------------------
function script.Activate() return 1 end

function script.Deactivate() return 0 end

function script.QueryBuildInfo() return center end

function hideProtestSign()
    for i = 1, 26 do
        charOn = string.char(64 + i)
        if TablesOfPiecesGroups[charOn] then
            resetT(TablesOfPiecesGroups[charOn])
            hideT(TablesOfPiecesGroups[charOn])
        end
    end
    hideT(TablesOfPiecesGroups["Quest"])
    resetT(TablesOfPiecesGroups["Quest"])
    hideT(TablesOfPiecesGroups["Exclam"])
    resetT(TablesOfPiecesGroups["Exclam"])
	Hide(ProtestSign)
end

function makeProtestSign(xIndexMax, zIndexMax, sizeLetterX, sizeLetterZ,
                         sentence, personification)
	hideProtestSign()
    index = 0
    Show(ProtestSign)
    alreadyUsedLetter = {}
    sentence = string.gsub(sentence, "Ü", personification or "")

    for i = 1, #sentence do
        letter = string.upper(string.sub(sentence, i, i))
        if letter == "!" then letter = "Exclam" end
        if letter == "?" then letter = "Quest" end

        if letter == "&" then
            index = (index + xIndexMax) - ((index + xIndexMax) % xIndexMax);
        else
            local pieceToMove
            if TablesOfPiecesGroups[letter] then
                if not alreadyUsedLetter[letter] then
                    alreadyUsedLetter[letter] = 1;
                    pieceToMove =
                        TablesOfPiecesGroups[letter][alreadyUsedLetter[letter]]
                else
                    alreadyUsedLetter[letter] = alreadyUsedLetter[letter] + 1;
                    if TablesOfPiecesGroups[letter][alreadyUsedLetter[letter]] then
                        pieceToMove =
                            TablesOfPiecesGroups[letter][alreadyUsedLetter[letter]]
                    end
                end
            end

            if letter == " " then
                index = index + 1
            elseif pieceToMove ~= nil then
                -- place and show letter
                assert(pieceToMove)
                Show(pieceToMove)

                xIndex = index % xIndexMax
                zIndex = math.floor((index / xIndexMax))
                Turn(pieceToMove, z_axis, math.rad(math.random(-2, 2)), 0)
                Move(pieceToMove, z_axis, zIndex * sizeLetterZ, 0)
                Move(pieceToMove, x_axis, xIndex * sizeLetterX, 0)
                index = index + 1
                if zIndex > zIndexMax then return end
            end

        end
    end

end

function akAimFunction(weaponID, heading, pitch)
    if bodyConfig.boolArmed == false or bodyConfig.boolRPGArmed == true  then return false end
    if (myTeamID == gaiaTeamID and oldBehaviourState ~= GameConfig.GameState.anarchy) then 
         return false 
     end

    boolAiming = true
    setOverrideAnimationState(eAnimState.aiming, eAnimState.standing, true, nil,
                              false)
    WTurn(center, y_axis, heading, 22)
    WaitForTurns(UpArm1, UpArm2, LowArm1, LowArm2)
    boolAiming = false
    return allowTarget(weaponID)
end

function molotowAimFunction(weaponID, heading, pitch)
   if (myTeamID == gaiaTeamID and oldBehaviourState ~= GameConfig.GameState.anarchy) then 
        return false 
    end
        
    return allowTarget(weaponID) and bodyConfig.boolArmed == true and bodyConfig.boolRPGArmed == false
end

function rgpAimFunction(weaponID, heading, pitch)
    
    if bodyConfig.boolArmed == false or bodyConfig.boolRPGArmed == false or GG.GlobalGameState ~=
        GameConfig.GameState.anarchy then
         return false 
    end

    Show(RPG7Rocket)
    boolAiming = true
    setOverrideAnimationState(eAnimState.aiming, eAnimState.standing, true, nil, false)
    WTurn(center, y_axis, heading, 22)
    WaitForTurns(UpArm1, UpArm2, LowArm1, LowArm2)
    boolAiming = false
    return allowTarget(weaponID)
end

function akFireFunction(weaponID, heading, pitch)
    boolAiming = false
    return true
end

function molotowFireFunction(weaponID, heading, pitch) return true end

function rgpFireFunction(weaponID, heading, pitch) 
    Hide(RPG7Rocket)
    return true 
end

WeaponsTable = {}
function makeWeaponsTable(myGun)
    WeaponsTable[1] = {
        aimpiece = center,
        emitpiece = myGun,
        aimfunc = akAimFunction,
        firefunc = akFireFunction,
        signal = SIG_PISTOL
    }
    
    WeaponsTable[2] = {
        aimpiece = Head1,
        emitpiece = cellphone1,
        aimfunc = molotowAimFunction,
        firefunc = molotowFireFunction,
        signal = SIG_MOLOTOW
    }

     WeaponsTable[3] = {
        aimpiece = Head1,
        emitpiece = cellphone1,
        aimfunc = rgpAimFunction,
        firefunc = rgpFireFunction,
        signal = SIG_RPG
    }
end

function script.AimFromWeapon(weaponID)
    if WeaponsTable[weaponID] then
        return WeaponsTable[weaponID].aimpiece
    else
        return myGun 
    end
end

function script.QueryWeapon(weaponID)
    if WeaponsTable[weaponID] then
        return WeaponsTable[weaponID].emitpiece
    else
        return myGun 
    end
end

function script.AimWeapon(weaponID, heading, pitch)
    if WeaponsTable[weaponID] then
        if WeaponsTable[weaponID].aimfunc then
            return WeaponsTable[weaponID].aimfunc(weaponID, heading, pitch)
        else
            WTurn(WeaponsTable[weaponID].aimpiece, y_axis, heading, turretSpeed)
            WTurn(WeaponsTable[weaponID].aimpiece, x_axis, -pitch, turretSpeed)
            return allowTarget(weaponID)
        end
    end
    return false
end

function allowTarget(weaponID) 
    return true 
end

function dropLoot()
    if spGetUnitIsTransporting(unitID) then
        transportID = spGetUnitIsTransporting(unitID)
        Spring.UnitDetach(transportID)
    end
end

function script.Killed(recentDamage, _)
    setSpeedEnv(unitID, 0)
    dropLoot()
    val = 5*randSign()
    Turn(root,y_axis,math.rad(val),0.8)
    for i=1,3 do
        turnTableRand(TablesOfPiecesGroups["UpArm"], i, 90, -90, 1.4)
        turnTableRand(TablesOfPiecesGroups["LowArm"], i, 90, -90, 1.4)
    end
    val = 90*randSign()
    WTurn(root,x_axis, math.rad(val),1.4)

    return 1
end
