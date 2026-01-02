function gadget:GetInfo()
    return {
        name = "Handles mortally dependent units",
        desc = "Handles damage modfiers/omitters to Units",
        author = "PicassoCT",
        date = "3rd of May 2010",
        license = "GPL3",
        layer = 0,
        version = 1,
        enabled = true
    }
end

if (gadgetHandler:IsSyncedCode()) then

    if not GG.mortallyDependant then GG.mortallyDependant = {} end
    if not GG.houseHasSafeHouseTable then GG.houseHasSafeHouseTable = {} end

    function  gadget:UnitDestroyed(unitID, unitDefID)
        if GG.mortallyDependant[unitID] then
            for i=1, #GG.mortallyDependant[unitID] do
                local dependent = GG.mortallyDependant[unitID][i]
                if doesUnitExistAlive(dependent.id) then
                    Spring.DestroyUnit(dependent.id, dependent.boolSelfDestruct, dependent.boolReclaimed)
                end
            end
            GG.mortallyDependant[unitID] = nil --consumed
        end

        if GG.houseHasSafeHouseTable[unitID] then
            if doesUnitExistAlive(GG.houseHasSafeHouseTable[unitID] ) then
                Spring.DestroyUnit( GG.houseHasSafeHouseTable[unitID], true, false)
                GG.houseHasSafeHouseTable[unitID] = nil
            end
        end
    end
end
