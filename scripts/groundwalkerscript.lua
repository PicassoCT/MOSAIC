include "createCorpse.lua"
include "lib_UnitScript.lua"
include "lib_Animation.lua"

local Animations = include('animations_ground_walker.lua')
include "lib_mosaic.lua"

local TablesOfPiecesGroups = {}

local Muzzle
local boolIsMgGroundWalker = false
if unitDefID == UnitDefNames["ground_walker_mg"].id then
    Muzzle = piece "Muzzle"
    boolIsMgGroundWalker = true
end
local aimrot = piece "aimrot"
local emitfire = piece "emitfire"
local center = piece "center"
local uparm01 = piece "uparm01"
local uparm002 = piece "uparm002"
local uparm003 = piece "uparm003"
local uparm004 = piece "uparm004"

local lowarm01 = piece "lowarm01"
local lowarm002 = piece "lowarm002"
local lowarm003 = piece "lowarm003"
local lowarm004 = piece "lowarm004"

local lowleg01 = piece "lowleg01"
local lowleg002 = piece "lowleg002"
local lowleg003 = piece "lowleg003"
local lowleg004 = piece "lowleg004"
local Parachute = piece "Parachute"
local upleg01 = piece "upleg01"
local upleg002 = piece "upleg002"
local upleg003 = piece "upleg003"
local upleg004 = piece "upleg004"
root = aimrot

local scriptEnv = {
    center = center,
    aimrot = aimrot,
    emitfire = emitfire,


    upleg01 = upleg01,
    upleg002 = upleg002,
    upleg003 = upleg003,
    upleg004 = upleg004,

    uparm01 = uparm01,
    uparm002 = uparm002,
    uparm003 = uparm003,
    uparm004 = uparm004,

    lowarm01 = lowarm01,
    lowarm002 = lowarm002,
    lowarm003 = lowarm003,
    lowarm004 = lowarm004,

    lowleg01 = lowleg01,
    lowleg002 = lowleg002,
    lowleg003 = lowleg003,
    lowleg004 = lowleg004,

    Parachute = Parachute,

    x_axis = x_axis,
    y_axis = y_axis,
    z_axis = z_axis
}

local allPieces = {
    center = center,
    aimrot = aimrot,
    emitfire = emitfire,


    upleg01 = upleg01,
    upleg002 = upleg002,
    upleg003 = upleg003,
    upleg004 = upleg004,

    uparm01 = uparm01,
    uparm002 = uparm002,
    uparm003 = uparm003,
    uparm004 = uparm004,

    lowarm01 = lowarm01,
    lowarm002 = lowarm002,
    lowarm003 = lowarm003,
    lowarm004 = lowarm004,

    lowleg01 = lowleg01,
    lowleg002 = lowleg002,
    lowleg003 = lowleg003,
    lowleg004 = lowleg004,

    Parachute = Parachute
}

local SIG_AIM = 1
local SIG_IDLE = 2


function gunRecoilMotion()
    if not Muzzle then return end
    Move(Muzzle, z_axis, -50, 50)
    Sleep(300)
    WMove(Muzzle, z_axis, -50, 200)
    WMove(Muzzle, z_axis, 0, 400)
    WMove(Muzzle, z_axis, -50, 200)
    WMove(Muzzle, z_axis, 0, 400)
    WMove(Muzzle, z_axis, -50, 200)
    WMove(Muzzle, z_axis, 0, 400)
end

function script.HitByWeapon(x, z, weaponDefID, damage) end

center = piece "center"
aimpiece = piece "center"
boolTurnLeft = false
boolTurning = false
boolUpdateRequestFlag = false

function ManualTriggeredHeadingChangeDetector()
    TurnCount = 0
    headingOfOld = Spring.GetUnitHeading(unitID)
    while true do
        Sleep(250)
        while boolManualUpdate == false do
            Sleep(15)
        end
        boolManualUpdate = false
        tempHead = Spring.GetUnitHeading(unitID)
        Spring.Echo("Current Heading"..tempHead) 
        if tempHead ~= headingOfOld then
            boolManualUpdate= true
            TurnCount = TurnCount + 1
            if TurnCount > 2 then
                boolManualUpdate = false
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


function script.Create()
    TablesOfPiecesGroups = getPieceTableByNameGroups(false, true)
    setupAnimation()
    Hide(aimrot)
    Hide(emitfire)
    StartThread(walkAnimationLoop)
    StartThread(ManualTriggeredHeadingChangeDetector, unitID, boolTurnLeft, boolTurning, boolUpdateRequestFlag)
    StartThread(resetHeadingIfNotAiming)

end

function resetHeadingIfNotAiming()
    while true do
        Sleep(1000)
        if boolAiming == false then
            WTurn(aimrot, y_axis, math.rad(0), math.pi)
        end
    end
end


boolTransported = false
function Landing()
    while Spring.GetUnitTransporter(unitID) do
        boolTransported= true
        Sleep(500)
    end
    boolTransported = false
    PlayAnimation("UPRIGHT", nil, 5.0)
    boolGotIdleTokken = getIdleTokken()
    while(boolWalking == false and boolAiming == false and boolGotIdleTokken) do
        speedO = math.random(5,25)/10
        PlayAnimation("IDLE", nil, speedO )
        Sleep(100)
    end
    if boolGotIdleTokken == true then returnIdleTokken(); boolGotIdleTokken = false end
end

boolIdleRunning = false
function SignalIdle()
    Signal(SIG_IDLE)
    SetSignalMask(SIG_IDLE)
    Sleep(1)
    varSpeed= math.random(10,30)/10
    PlayAnimation("IDLE", nil, varSpeed)
    Sleep(100)
    boolIdleRunning = false
end

boolForward = true
boolGotIdleTokken = false
function walkAnimationLoop()
    waitTillComplete(unitID)
    StartThread(PlaySoundByUnitDefID, unitDefID, "sounds/walker/boot.wav",1.0, 1000, 1)
    Landing()

    while true do
        if boolAiming == false and boolWalking == true then
            while boolAiming == false and boolWalking == true do
                if boolForward == true then
                    PlayAnimation("RUNNING", nil, 1.0)
                else
                    PlayAnimation("REVERSE", nil, 1.0)
                end
            end

            if boolAiming == false then
                PlayAnimation("UPRIGHT", nil, 10.0)
                rSleep= math.random(5,25)*1000
                while boolAiming== false and boolWalking == false and rSleep> 0 do
                Sleep(100)
                rSleep = rSleep -100
                end

                if boolWalking == false then
                    boolGotIdleTokken = getIdleTokken()
                    if boolGotIdleTokken == true then -- idle animation

                        while(boolWalking == false and boolAiming == false) do
                            if boolIdleRunning == false then
                                boolIdleRunning = true
                                StartThread(SignalIdle)
                            end
                            Sleep(50)
                        end
                        Signal(SIG_IDLE)
                        returnIdleTokken()
                    else --shutdown
                        if math.random(0, 4) < 2 then
                            PlayAnimation("SIT", nil, 2.0)
                             while boolAiming== false and boolWalking == false do Sleep(50) end
                             PlayAnimation("UPRIGHT", nil, 10.0)
                        end
                    end

                end
            end
        end

        if Spring.GetUnitTransporter(unitID) then
            boolTransported = true
             PlayAnimation("SIT", nil, 2.0)
             while(Spring.GetUnitTransporter(unitID)) do
                Sleep(100)
            end
            boolTransported = false
            PlayAnimation("UPRIGHT", nil, 2.0)
        end
        Sleep(100)
    end
end

function setupAnimation()
    local map = Spring.GetUnitPieceMap(unitID);
      local switchAxis = function(axis)
        if axis == z_axis then return y_axis end
        if axis == x_axis then return x_axis end
        if axis == y_axis then return z_axis end
        return axis
    end

    local offsets = constructSkeleton(unitID, map.center, {0, 0, 0});

    for a, anim in pairs(Animations) do
        for i, keyframe in pairs(anim) do
            local commands = keyframe.commands;
            for k, command in pairs(commands) do
   		       if command.p and type(command.p) == "string" then
                    local name = command.p
                    command.p = map[command.p]
                    if not command.p then Spring.Echo("Animationsetup: Piece unknown for name:"..name) end
                end
                -- commands are described in (c)ommand,(p)iece,(a)xis,(t)arget,(s)peed format
                -- the t attribute needs to be adjusted for move commands from blender's absolute values
                if (command.c == "move") then
 		  local adjusted = command.t - (offsets[command.p][command.a]);
                    Animations[a][i]['commands'][k].t =
                        command.t - (offsets[command.p][command.a]);
                end

                Animations[a][i]['commands'][k].a = switchAxis(command.a)
            end
        end
    end

   -- echo("End setupAnimation groundwalker")
end

local animCmd = {['turn'] = Turn, ['move'] = Move};

local axisSign = {[x_axis] = 1, [y_axis] = 1, [z_axis] = 1}

function PlayAnimation(animname, piecesToFilterOutTable, speed)
    if animname == "FIRING" then StartThread(gunRecoilMotion) end
    local speedFactor = speed or 1.0
    if not piecesToFilterOutTable then piecesToFilterOutTable = {} end
    assert(animname, "animation name is nil")
    assert(type(animname) == "string",
           "Animname is not string " .. toString(animname))
    assert(Animations[animname], "No animation with name "..animname)

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

    for i = 1, 3 do
        info.offset[i] = offset[i] + info.offset[i];
        assert(info.offset[i])
    end

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

function script.Killed(recentDamage, _)
    PlayAnimation("UPRIGHT", nil, math.pi)
    if boolGotIdleTokken == true then returnIdleTokken() end
    for k, v in pairs(TablesOfPiecesGroups) do
        explodeT(v, SFX.SHATTER)
        hideT(v)
    end
    return 1
end
boolAiming = false

-- aimining & fire weapon
function script.AimFromWeapon1() return aimpiece end
function script.AimFromWeapon2() return aimpiece end

function script.QueryWeapon1() return aimpiece end
function script.QueryWeapon2() return aimpiece end

boolPrioritizeGround = false

function script.AimWeapon1(Heading, pitch)
    if boolTransported == true then return false end

    StartThread(delayedDeactivateAiming)
    boolAiming = true
    boolPrioritizeGround = true
    if boolWalking == true then
        boolUpdateRequestFlag = true
        while boolUpdateRequestFlag == true do Sleep(100) end
        if boolTurning == true then
            if boolTurnLeft == true then
                PlayAnimation("SIDEWALK_RIGHT", nil, 2.0)
            else
                 PlayAnimation("SIDEWALK_LEFT", nil, 2.0)
            end
        else
            PlayAnimation("RUNNING", nil, 4.0)
        end
    end

    WTurn(aimrot, y_axis, Heading, math.pi)

    return true
end

function script.AimWeapon2(Heading, pitch)
    if boolPrioritizeGround == true  then return false end

    return boolPrioritizeGround == false
end

function delayedDeactivateAiming()
    Signal(SIG_AIM)
    SetSignalMask(SIG_AIM)
    Sleep(500)
    boolAiming = false
    boolPrioritizeGround = false
end

function fireFlash()
    for i=1,10 do
        EmitSfx(emitfire, 1024)
        Sleep(125)
        EmitSfx(Parachute, 1025)
    end     
end
function script.FireWeapon1()
    if boolIsMgGroundWalker == true then
       StartThread(fireFlash)
    end

    if boolWalking == false then         
        PlayAnimation("FIRING", nil, 3.0) end
    return true
end

function script.FireWeapon2()
    if boolWalking == false then PlayAnimation("FIRE_HIGH", nil, 3.0) end
    return true
end

boolWalking = false
function script.StartMoving(boolReverse)
    boolForward =  (boolReverse == 0)
    StartThread(PlaySoundByUnitDefID, unitDefID, "sounds/walker/servo"..math.random(1,7)..".ogg", 0.75, 3000, 2)
    boolWalking = true 
end

function script.StopMoving() boolWalking = false end

function script.Activate()
    PlayAnimation("UPRIGHT", nil, 2.0)
    return 1
end

function script.Deactivate()
    resetAll(unitID, 3.0)
    return 0
end
