include "createCorpse.lua"
include "lib_OS.lua"
include "lib_UnitScript.lua"
include "lib_Animation.lua"
include "lib_mosaic.lua"

local Animations = include('animations_police.lua')
local GameConfig = getGameConfig()
local center = piece"center"
local Torso = piece"Torso"
local UpLeg2 = piece"UpLeg2"
local LowLeg2 = piece"LowLeg2"
local UpLeg1 = piece"UpLeg1"
local LowLeg1 = piece"LowLeg1"
local UpBody = piece"UpBody"
local UpArm2 = piece"UpArm2"
local LowArm2 = piece"LowArm2"
local Hand2 = piece"Hand2"
local BeatDown = piece"BeatDown"
local UpArm1 = piece"UpArm1"
local LowArm1 = piece"LowArm1"
local Hand1 = piece"Hand1"
local Head = piece"Head"
local Shield = piece"Shield"
local Visor = piece"Visor"

TablesOfPiecesGroups = {}
myDefID = Spring.GetUnitDefID(unitID)
function script.HitByWeapon(x, z, weaponDefID, damage) end

function showRiotCop()
  Show(Visor)
  Show(BeatDown)
  Show(Shield)
  Turn(Visor,x_axis, math.rad(90), 15)
end

function showCop()
  Show(BeatDown)
end

local timeTotal = GameConfig.LifeTimeRiotPoliceSeconds *1000
function script.Create()
    setupPrintf(unitID)
    TablesOfPiecesGroups = getPieceTableByNameGroups(false, true)
    setupAnimation()
    hideT(TablesOfPiecesGroups["Riot-Face_"])
    showOnePiece(TablesOfPiecesGroups["Riot-Face_"], math.random(1,100))
    Hide(RiotShield)
    Hide(center)
    Hide(Visor)
    Hide(BeatDown)
    showRiotCop()
    StartThread(lifeTime, unitID, timeTotal  - 5000 -1000, false, true)
end

function setupAnimation()
    local map = Spring.GetUnitPieceMap(unitID);
    local switchAxis = function(axis)
        if axis == z_axis then return y_axis end
        if axis == y_axis then return z_axis end
        return axis
    end

    local offsets = constructSkeleton(unitID, center, {0, 0, 0});

    for a, anim in pairs(Animations) do
        echo("Setting up animation "..a)
        for i, keyframe in pairs(anim) do
            local commands = keyframe.commands;
            for k, command in pairs(commands) do

                if command.p and type(command.p) == "string" then
                    if not map[command.p] then
                        echo("Piecemap does not contain ".. command.p )
                    else
                        command.p = map[command.p]
                    end
                end
                -- -Spring.Echo("Piece "..command.p.." maps to "..getUnitPieceName(unitID, command.p))
                -- commands are described in (c)ommand,(p)iece,(a)xis,(t)arget,(s)peed format
                -- the t attribute needs to be adjusted for move commands from blender's absolute values
                if (command.c == "move") then
                    local adjusted = command.t - (offsets[command.p][command.a]);
                    Animations[a][i]['commands'][k].t =
                        command.t - (offsets[command.p][command.a]);
                end

                --Animations[a][i]['commands'][k].a = switchAxis(command.a)
            end
        end
    end
end

local animCmd = {['turn'] = Turn, ['move'] = Move}
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

            if not cmd.t then cmd.t = 0 end

            if not piecesToFilterOutTable[cmd.p] then
                if type(cmd.p) == "string" then
                    echo("Unit piece is not valid: " ..cmd.p)
                else
                    animCmd[cmd.c](cmd.p, cmd.a, axisSign[cmd.a] * (cmd.t + randoffset),  cmd.s * speedFactor)
                end
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
      if not map[childName] then assert(false, childName) end
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
    PlayAnimation("FULLBODY_DEATH")
    return 1
end

SIG_ANIMATION = 2
function animationLoop(name, speeds)
  Signal(SIG_ANIMATION)
  SetSignalMask(SIG_ANIMATION)
  while true do
    PlayAnimation(name,{}, speeds)
    Sleep(1)
  end
end


function walkAnimation(speed)
    Signal(SIG_WALK)
    SetSignalMask(SIG_WALK)
    while true do
        Turn(UpArm1, z_axis, math.rad(60), speed)
        Turn(UpArm2, z_axis, math.rad(-60), speed)

        valRangeLeft = math.random(35, 45)
        Turn(UpLeg2,x_axis, math.rad(-valRangeLeft), speed)
        Turn(LowLeg2,x_axis, math.rad(valRangeLeft *0.6), speed)
        valRangeRight = math.random(15, 25)
        Turn(UpLeg1,x_axis, math.rad(valRangeRight), speed)
        Turn(LowLeg1,x_axis, math.rad(valRangeRight * 0.8), speed)
        Turn(UpArm1, y_axis, math.rad(30), speed*0.5)
        Turn(UpArm2, y_axis, math.rad(-30), speed*0.5)

        WaitForTurns({ LowLeg1, LowLeg2})
        Sleep(250)
        valRangeRight = math.random(35, 45)
        Turn(UpLeg1,x_axis, math.rad(-valRangeRight), speed)
        Turn(LowLeg1,x_axis, math.rad(valRangeRight *0.6), speed)
        valRangeLeft = math.random(15, 25)
        Turn(UpLeg2,x_axis, math.rad(valRangeLeft), speed)
        Turn(LowLeg2,x_axis, math.rad(valRangeLeft * 0.8), speed)
        Turn(UpArm1, y_axis, math.rad(-30), speed*0.5)
        Turn(UpArm2, y_axis, math.rad(30), speed*0.5)

        WaitForTurns({ LowLeg1, LowLeg2})
        Sleep(250)
    end
end

function script.StartMoving() 
    StartThread(walkAnimation, 60)
end

function script.StopMoving() 
  Signal(SIG_WALK)
  StartThread(animationLoop, "FULLBODY_STANDING_IDLE",math.random(75,100)/100)
end

function script.Activate() return 1 end

function script.Deactivate() return 0 end

function script.AimFromWeapon1() return BeatDown end

function script.QueryWeapon1() return BeatDown end

function script.AimWeapon1(Heading, pitch) return true end

function script.FireWeapon1()
  Signal(SIG_ANIMATION)
  PlayAnimation("FULLBODY_BEATDOWN",{},math.random(80,150)/50)
  return true 

end


function script.AimFromWeapon2() return BeatDown end

function script.QueryWeapon2() return BeatDown end

function script.AimWeapon2(Heading, pitch) return false end

function script.FireWeapon2()
  return true 
end
