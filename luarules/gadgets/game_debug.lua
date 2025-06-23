function gadget:GetInfo()
    return {
        name = "Debug",
        desc = "This gadget surveils memory conditions",
        author = "Picasso",
        date = "Sep. 2022",
        license = "GNU GPL, v2 or later",
        layer = 1,
        enabled = true
    }
end

if (gadgetHandler:IsSyncedCode()) then
    VFS.Include("scripts/lib_OS.lua")
    VFS.Include("scripts/lib_UnitScript.lua")
    VFS.Include("scripts/lib_Animation.lua")
    VFS.Include("scripts/lib_debug.lua")
    VFS.Include("scripts/lib_mosaic.lua")
    VFS.Include("scripts/lib_debug.lua")

    --Optimization
   

    function gadget:GameFrame(frame)
        checkGlobalTable(frame)
        checkUnitScriptEnvironmentSize(frame)
    end
end