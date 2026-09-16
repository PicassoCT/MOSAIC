function gadget:GetInfo()
    return {
        name = "Mobile assembly doctrine",
        desc = "Mobile factories preserve faction production asymmetry, including after capture",
        author = "MOSAIC contributors",
        license = "GPL3",
        layer = 5,
        enabled = true,
    }
end

if not gadgetHandler:IsSyncedCode() then return end

local mobileDefID = UnitDefNames.transportedassembly.id
local doctrine = VFS.Include("luarules/configs/mobile_assembly_doctrine.lua")
local allowed = {common = {}, protagon = {}, antagon = {}}
for group, names in pairs(doctrine) do
    for _, name in ipairs(names) do
        local def = UnitDefNames[name]
        if def then allowed[group][def.id] = true end
    end
end

local function canBuild(teamID, unitDefID)
    if allowed.common[unitDefID] then return true end
    local side = select(5, Spring.GetTeamInfo(teamID, false))
    local faction = type(side) == "string" and allowed[side:lower()]
    return faction ~= nil and faction[unitDefID] == true
end

local function updateMenu(unitID, unitDefID, teamID)
    if unitDefID ~= mobileDefID then return end
    for _, defID in ipairs(UnitDefs[mobileDefID].buildOptions) do
        local index = Spring.FindUnitCmdDesc(unitID, -defID)
        if index then
            Spring.EditUnitCmdDesc(unitID, index, {disabled = not canBuild(teamID, defID)})
        end
    end
end

function gadget:Initialize()
    for _, unitID in ipairs(Spring.GetAllUnits()) do
        updateMenu(unitID, Spring.GetUnitDefID(unitID), Spring.GetUnitTeam(unitID))
    end
end

function gadget:UnitCreated(unitID, unitDefID, teamID)
    updateMenu(unitID, unitDefID, teamID)
end

function gadget:UnitFinished(unitID, unitDefID, teamID)
    updateMenu(unitID, unitDefID, teamID)
end

function gadget:UnitGiven(unitID, unitDefID, newTeam)
    updateMenu(unitID, unitDefID, newTeam)
end

function gadget:AllowCommand(unitID, unitDefID, teamID, cmdID, cmdParams)
    if unitDefID ~= mobileDefID then return true end
    if cmdID == CMD.INSERT then cmdID = cmdParams[2] end
    if cmdID and cmdID < 0 then return canBuild(teamID, -cmdID) end
    return true
end

function gadget:AllowUnitCreation(unitDefID, builderID, teamID)
    if builderID and Spring.GetUnitDefID(builderID) == mobileDefID then
        return canBuild(teamID, unitDefID)
    end
    return true
end
