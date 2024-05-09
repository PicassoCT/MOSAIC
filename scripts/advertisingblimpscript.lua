include "createCorpse.lua"
include "lib_OS.lua"
include "lib_UnitScript.lua"
include "lib_Animation.lua"
include "lib_mosaic.lua"

local TablesOfPiecesGroups = {}
local myDefID = Spring.GetUnitDefID(unitID)
local myTeamID = Spring.GetUnitTeam(unitID)
local gaiaTeamID = Spring.GetGaiaTeamID()
local GameConfig = getGameConfig()
local advertisingFilePath = "sounds/advertising/"
local civilianWalkingTypeTable = getCultureUnitModelTypes(  GameConfig.instance.culture, 
                                                            "civilian", UnitDefs)
local maxSoundFiles = 65
HoloCenter = piece("HoloCenter")

function defineMaxSoundFiles()
    fileList = VFS.DirList(advertisingFilePath, "advertisement*.ogg")
    maxSoundFiles = math.max(maxSoundFiles,  #fileList)
    Spring.Echo("maxSoundFiles: "..maxSoundFiles)
end

function showOne(T, bNotDelayd)
    if not T then return end
    dice = math.random(1, count(T))
    c = 0
    for k, v in pairs(T) do
        if k and v then c = c + 1 end
        if c == dice then            
            Show(v)            
            return v
        end
    end
end

function showOneOrNone(T)
    if not T then return end
    if math.random(1, 100) > 50 then
        return showOne(T, true)
    else
        return
    end
end

function setUnitActive(boolWantActive)
    if boolWantActive == true then
        Spring.UnitScript.SetUnitValue(COB.ACTIVATION, 1)
    else
        Spring.UnitScript.SetUnitValue(COB.ACTIVATION, 0)
    end
end

function script.Create()
    defineMaxSoundFiles()
    --echo(UnitDefs[myDefID].name.."has placeholder script called")
    Spring.SetUnitAlwaysVisible(unitID, true)
    setUnitActive(unitID, false)
    setUnitActive(unitID, true)
     --Spring.SetUnitNoSelect(unitID, true)
     TablesOfPiecesGroups = getPieceTableByNameGroups(false, true)
     hideT(TablesOfPiecesGroups["Blimp"])
     showOne(TablesOfPiecesGroups["Blimp"])
     StartThread(Advertising)
     StartThread(LightsBlink)
     StartThread(flyTowardsPerson)
     StartThread(advertisingLoop)
     StartThread(limitToMapLimits)
end

function advertiseTimeOfDay(hour)
    if hour > 2 and hour < 7 then
        return false
    end
   return true
end

function advertisingLoop()
    rest= (math.random(2,5)+(unitID%3))*10000
    Sleep(rest)
    StartThread(attachHologram)

    while true do
        soundFile = advertisingFilePath.."advertisement"..math.random(1,maxSoundFiles)..".ogg"
        loudness= 1.0
        hours, minutes, seconds, percent = getDayTime()
        if maRa() == maRa() and advertiseTimeOfDay(hours) then
            soundFile = "sounds/advertising/blimp.ogg"
            loudness= math.random(5,9)/10
        end
        StartThread(PlaySoundByUnitDefID, myDefID, soundFile, loudness, 20000, 2)
        minimum, maximum = 5*60*1000, 10*60*1000
        restTime = math.random(minimum, maximum)
        Sleep(restTime)
    end
end

function limitToMapLimits()
    Sleep(3000)
    Spring.AddUnitImpulse(unitID, 0.0, 1.0, 0.0)
    Spring.SetUnitMoveGoal(unitID, math.random(1,Game.mapSizeX), 150, math.random(1,Game.mapSizeZ))                 
    while true do
        Sleep(1000)
        x,y,z = Spring.GetUnitPosition(unitID)
        cx = clamp(1,x, Game.mapSizeX-1)
        cz = clamp(1,z, Game.mapSizeZ-1)
        if y and cx and cx ~= x or cz ~= z then
            Spring.MoveCtrl.Enable(unitID)
            Spring.MoveCtrl.SetPosition(cx, y, cz)
            Spring.MoveCtrl.Disable(unitID) 
            Spring.AddUnitImpulse(unitID, 0.0, 1.0, 0.0)
            Spring.SetUnitMoveGoal(unitID, math.random(1,Game.mapSizeX), y, math.random(1,Game.mapSizeZ))                 
        end
    end
end
function attachHologram()
    holoID = moveCtrlHologramToUnitPiece(unitID, "advertising_blimp_hologram", HoloCenter, 0)
    isblocking= false
    isSolidObjectCollidable=false
    isProjectileCollidable= false
    isRaySegmentCollidable = false
    crushable = false
    blockEnemyPushing= false
    blockHeightChanges = false
    Spring.SetUnitBlocking(unitID, isblocking, isSolidObjectCollidable, isProjectileCollidable, isRaySegmentCollidable, crushable, blockEnemyPushing, blockHeightChanges ) 
    
    while true do
        Sleep(45)
        px,py,pz = Spring.GetUnitPosition(unitID)
        Spring.MoveCtrl.SetPosition(holoID, px+1,py-1,pz+1)
    end
end

boolTurnLeft= false
boolTurning = false
boolMoving = false
function headingChangeDetector(unitID)
    assert(unitID)
    TurnCount = 0
    headingOfOld = Spring.GetUnitHeading(unitID)
    while true do
        Sleep(250)
 
        tempHead = Spring.GetUnitHeading(unitID)
        if tempHead ~= headingOfOld then
            TurnCount = TurnCount + 1
            if TurnCount > 3 then
                boolTurning = true
            end
        else
            TurnCount = 0
            boolTurning = false
        end
        if tempHead ~= nil then
            boolTurnLeft = headingOfOld > tempHead
            headingOfOld = tempHead
        end
    end
end

function controlDirectionRotors()
    boolTurnLeft = false
    boolTurning = false
    StartThread(headingChangeDetector, unitID)
    while true do
        if boolTurning then
            for i=1,#TablesOfPiecesGroups["Control"] do
                if i % 2 == 0 then
                    Turn(TablesOfPiecesGroups["Control"][i],y_axis, math.rad(10), 10)
                else
                    Turn(TablesOfPiecesGroups["Control"][i],y_axis, math.rad(-10), 10)
                end
            end
        else
            if boolMoving then
                turnT(TablesOfPiecesGroups["Control"][i],y_axis, 10, 10)
            else
                resetT(TablesOfPiecesGroups["Control"], 0.5)
            end
        end
        WaitForTurns(TablesOfPiecesGroups["Control"])
        Sleep(500)
    end
end

function HoloGrams()    
    local brothelFlickerGroup = TablesOfPiecesGroups["BrothelFlicker"]
    local CasinoflickerGroup = TablesOfPiecesGroups["CasinoFlicker"]
    local JoyFlickerGroup = {}

    JoyFlickerGroup[#JoyFlickerGroup+1] = Joy
    JoyFlickerGroup[#JoyFlickerGroup+1] = JoyRide
    hideT(brothelFlickerGroup)
    hideT(CasinoflickerGroup)
    hideT(JoyFlickerGroup)
    hideT(TablesOfPiecesGroups["JoySpin"])

    Sleep(15000)
    --sexxxy time
    px,py,pz = Spring.GetUnitPosition(unitID)
    if maRa() then
        StartThread(flickerScript, brothelFlickerGroup, 5, 250, 4, true)
    else
        StartThread(flickerScript, JoyFlickerGroup, 5, 250, 4, true)
        StartThread(JoyAnimation)
    end
    val = math.random(5, 12)*randSign()
    Spin(BrothelSpin, z_axis, math.rad(val), 0.1)
    StartThread(flickerScript, CasinoflickerGroup, 5, 250, 4, true)
    val = math.random(5, 12)*randSign()
    Spin(CasinoSpin, z_axis,  math.rad(val), 0.1)
end

function script.HitByWeapon(x, z, weaponDefID, damage)
    hp = Spring.GetUnitHealth(unitID)
    if hp and hp - damage < 0 then
        Spring.SetUnitCrashing(unitID, true)
        SetUnitValue(COB.CRASHING, 1)
        Spring.SetUnitNeutral(unitID, true)
        Spring.SetUnitNoSelect(unitID, true)
        return 0
    end
    return damage
end

function JoyAnimation()
    offsetValue = -70
    turnVal= -17
    animStepTime = 1000
    JoySpinOrigin = TablesOfPiecesGroups["JoySpin"][1]

    while true do

        hours, minutes, seconds, percent = getDayTime()
        if (hours > 17 or hours < 7) then
            Spin(JoySpinOrigin, z_axis, math.rad(17*3), 0)
            Show(JoySpinOrigin)
            Sleep(2000)

            scalar = 0.125*0.5*0.1
            for i=2, #TablesOfPiecesGroups["JoySpin"] do
                offset = i* offsetValue
                Show(TablesOfPiecesGroups["JoySpin"][i])
                rootDistance = i* 70 * 2
                Move(JoySpinOrigin, z_axis, rootDistance,speed(rootDistance, animStepTime*scalar))
                Move(TablesOfPiecesGroups["JoySpin"][i],z_axis, offsetValue, speed(offsetValue, animStepTime*scalar))
                Turn(TablesOfPiecesGroups["JoySpin"][i],z_axis, math.rad(turnVal), speed(turnVal, animStepTime))

                WaitForTurns(TablesOfPiecesGroups["JoySpin"][i])
                WaitForMoves(TablesOfPiecesGroups["JoySpin"][i])
            end
            WaitForMoves(JoySpinOrigin)
        end

        hideT(TablesOfPiecesGroups["JoySpin"])
        for i=1, #TablesOfPiecesGroups["JoySpin"] do
            reset(TablesOfPiecesGroups["JoySpin"][i],0)
        end
        StopSpin(JoySpinOrigin,z_axis,0)
        WaitForTurns(TablesOfPiecesGroups["JoySpin"])
        WaitForMoves(TablesOfPiecesGroups["JoySpin"])   
        DownDist = -70* #TablesOfPiecesGroups["JoySpin"] * 2
        WMove(JoySpinOrigin,z_axis, DownDist, 0)
        Sleep(10)
    end
end


function flickerScript(flickerGroup,  errorDrift, timeoutMs, maxInterval, boolDayLightSavings)
    assert(flickerGroup)
    local fGroup = flickerGroup

    flickerIntervall = math.ceil(1000/25)
    
    while true do
        hideT(fGroup)
        --assertRangeConsistency(fGroup, "flickerGroup")
        Sleep(500)
        hours, minutes, seconds, percent = getDayTime()
        if (hours > 17 or hours < 7) then
            toShowTableT= {}
            for x=1,math.random(1,3) do
                toShowTableT[#toShowTableT+1] = fGroup[math.random(1,#fGroup)]
            end

            for i=1,(3000/flickerIntervall) do
                if i % 2 == 0 then  showT(toShowTableT) else hideT(toShowTableT) end
                if maRa()==maRa() then showT(toShowTableT) end 
                for ax=1,3 do
                    moveT(fGroup, ax, math.random(-1*errorDrift,errorDrift),100)
                end
                Sleep(flickerIntervall)
            end
            hideT(toShowTableT)
        end
        breakTime = math.random(1,maxInterval)*timeoutMs
        Sleep(breakTime)
    end
end

function flyTowardsPerson()
    Sleep(10)
    while true do  
            T= foreach(Spring.GetTeamUnits(gaiaTeamID),
                function(id)
                    defID = Spring.GetUnitDefID(id)
                    if civilianWalkingTypeTable[defID] then
                        return id
                    end
                end
             )
            if #T > 1 then
                id = T[math.random(1,#T)]
                px,py,pz = Spring.GetUnitPosition(id)
                if maRa() then
                    Spring.SetUnitMoveGoal(unitID, px,py,pz)
                    Spring.GiveOrderToUnit(unitID, CMD.PATROL, { px, py , pz }, { })     
                else
                    Spring.GiveOrderToUnit(unitID, CMD.PATROL, { px, py , pz }, { "shift"})     
                end                          
            end
        Sleep(25000)
    end
end

function LightsBlink()
    while true do
        hideT(TablesOfPiecesGroups["LightOn"])
        showT(TablesOfPiecesGroups["LightOff"])
        Sleep(3000)
        hideT(TablesOfPiecesGroups["LightOff"])
        showT(TablesOfPiecesGroups["LightOn"])
        Sleep(6000)
    end
end

function Advertising()
    seperator = 19
    while true do
        hideT(TablesOfPiecesGroups["Screen"])
        dice = math.random(1,seperator)
        Show(TablesOfPiecesGroups["Screen"][dice])
        if TablesOfPiecesGroups["Screen"][seperator + dice] then
            Show(TablesOfPiecesGroups["Screen"][seperator + dice])
        end
        hideT(TablesOfPiecesGroups["Deco"])
        showOneOrNone(TablesOfPiecesGroups["Deco"])
        showOneOrNone(TablesOfPiecesGroups["Deco"])
        Sleep(10000)
    end
end

function script.Killed(recentDamage, _)
    Spring.SetUnitCrashing ( unitID, true) 
    return 1
end


function script.StartMoving() 
    boolMoving = true
end

function script.StopMoving()
    boolMoving = false
 end

function script.Activate() return 1 end

function script.Deactivate() return 0 end

