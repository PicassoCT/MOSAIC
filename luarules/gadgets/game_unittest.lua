function gadget:GetInfo()
    return {
        name = "Unit test",
        desc = "Implements a unit test",
        author = "PicassoCT",
        date = "Juli. 2017",
        license = "GNU GPL, v2 or later",
        layer = 0,
        version = 1,
        enabled = true
    }
end

if (gadgetHandler:IsSyncedCode()) then
    VFS.Include("scripts/lib_mosaic.lua")
    VFS.Include("scripts/lib_UnitScript.lua")

    function checkTruckTypeTable()
        T= getTruckTypeTable(UnitDefs)
        assert(T)
        assert(type(T) == "table")
        assert(T[UnitDefNames["truck_arab7"].id])
    end

    function runTests()
        checkTruckTypeTable()        
    end

    function gadget:Initalization()
       runTests()
    end
end
