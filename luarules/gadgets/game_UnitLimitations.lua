function gadget:GetInfo()
    return {
        name = "Unit Limitations",
        desc = "Implements a limitation of units",
        author = "PicassoCT",
        date = "Juli. 2017",
        license = "GNU GPL, v2 or later",
        layer = 0,
        version = 1,
        enabled = false
    }
end

if (gadgetHandler:IsSyncedCode()) then
    VFS.Include("scripts/lib_mosaic.lua")
    VFS.Include("scripts/lib_UnitScript.lua")

    local UnitsLimited = {
        [UnitDefNames["hivemind"].id] = 1,
        [UnitDefNames["aicore"].id] = 1,
    }

    local UnitCount = {}

    function gadget:UnitCreated(unitID, unitDefID, unitTeam)

        if UnitsLimited[unitDefID] then
            if not UnitCount[unitTeam] then UnitCount[unitTeam] = {} end
            if not UnitCount[unitTeam][unitDefID] then
                UnitCount[unitTeam][unitDefID] = 0
            end

            if UnitCount[unitTeam][unitDefID] + 1 > UnitsLimited[unitDefID] then
                GG.UnitsToKill:PushKillUnit(unitID, true, true)
            else
                UnitCount[unitTeam][unitDefID] =  UnitCount[unitTeam][unitDefID] + 1
            end
        end
    end

    function gadget:UnitTaken(unitID, unitDefID, unitTeam, newTeam)
        if UnitsLimited[unitDefID] then
            UnitCount[unitTeam][unitDefID] =
                math.max(UnitCount[unitTeam][unitDefID] - 1, 0)
            if UnitCount[newTeam][unitDefID] + 1 > UnitsLimited[unitDefID] then
                GG.UnitsToKill:PushKillUnit(unitID, true, true)
            else
                UnitCount[unitTeam][unitDefID] = UnitCount[unitTeam][unitDefID] + 1
            end
        end
    end

    function gadget:UnitDestroyed(unitID, unitDefID, unitTeam)
        if UnitsLimited[unitDefID] then
            if not UnitCount[unitTeam] then UnitCount[unitTeam] = {} end
            if not UnitCount[unitTeam][unitDefID] then
                UnitCount[unitTeam][unitDefID] = 0
            end

            UnitCount[unitTeam][unitDefID] =   math.max(UnitCount[unitTeam][unitDefID] - 1, 0)
        end
    end
end
