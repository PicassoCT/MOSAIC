--Define the wheel pieces
include "createCorpse.lua"
include "lib_OS.lua"
include "lib_UnitScript.lua" 
include "lib_Animation.lua"
include "lib_Build.lua"
--Define the pieces of the weapon

local SIG_RESET = 2
center = piece"center"
buildspot = piece"buildspot"
teamID = Spring.GetUnitTeam(unitID)
TablesOfPiecesGroups ={}

function getDistance(cmd, x, z)
    val = ((cmd.params[1] - x) ^ 2 + (cmd.params[3] - z) ^ 2) ^ 0.5

    return val
end

function transferCommands()

    while true do
	Sleep(150)
        if GG.Factorys and GG.Factorys[unitID] and GG.Factorys[unitID][1] then

            CommandTable = Spring.GetUnitCommands(unitID, -1)
            first = false

            for _, cmd in pairs(CommandTable) do

                if Spring.ValidUnitID(GG.Factorys[unitID][1]) == true then
                    if #CommandTable ~= 0 then
                        if first == false then
                            first = true
                            x, y, z = Spring.GetUnitPosition(unitID)
                            if cmd.id == CMD.MOVE and getDistance(cmd, x, z) > 160 then
                                Spring.GiveOrderToUnit(GG.Factorys[unitID][1], cmd.id, cmd.params, {})
                            elseif cmd.id == CMD.STOP then
                                Spring.GiveOrderToUnit(GG.Factorys[unitID][1], CMD.STOP, {}, {})
                            end
                        else
                            Spring.GiveOrderToUnit(GG.Factorys[unitID][1], cmd.id, cmd.params, { "shift" })
                        end
                    else
                        Spring.GiveOrderToUnit(GG.Factorys[unitID][1], CMD.STOP, {}, {})
                    end
                end
            end
        end
   
    end
end

function script.Create()
  TablesOfPiecesGroups = getPieceTableByNameGroups(false, true)

	Turn(center, y_axis,math.rad(270),0)
	foldPosition(0)
	hideT(TablesOfPiecesGroups["Deco"])
	 --hideAll(unitID)
    StartThread(transferCommands)
    StartThread(whileMyThreadGentlyWeeps)


    if GG.Factorys == nil then GG.Factorys = {} end
    GG.Factorys[unitID] = {}
end

function foldPosition(speed)


end

function unfoldPosition(speed)


end

function workLoop()


end

function script.QueryBuildInfo()
    return center
end

Spring.SetUnitNanoPieces(unitID, { buildspot })


function script.Activate()
    SetUnitValue(COB.YARD_OPEN, 1)
    SetUnitValue(COB.INBUILDSTANCE, 1)
    SetUnitValue(COB.BUGGER_OFF, 1)
    return 1
end


function script.Deactivate()
    Signal(SIG_UPGRADE)
    SetUnitValue(COB.YARD_OPEN, 0)
    SetUnitValue(COB.INBUILDSTANCE, 0)
    SetUnitValue(COB.BUGGER_OFF, 0)
    return 0
end


function delayedBuildEnd()
    SetSignalMask(SIG_RESET)
    Sleep(1500)
    if GG.Factorys[unitID] then
        GG.Factorys[unitID][2] = false
    end
end


function script.StartBuilding()
  
    --animation
    Signal(SIG_RESET)
    if GG.Factorys[unitID] then
        GG.Factorys[unitID][2] = true
    end
end

boolDoIt = false
function whileMyThreadGentlyWeeps()
    while true do
	 Sleep(150)
        if boolDoIt == true then
            boolDoIt = false
            StartThread(delayedBuildEnd)
        end
       
    end
end

function script.StopBuilding()
    boolDoIt = true
end

function script.Killed(endh, _)
    GG.Factorys[unitID] = nil -- check for correct syntax
    return 1
end