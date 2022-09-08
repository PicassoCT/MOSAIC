function gadget:GetInfo()
    return {
        name = "gui Show/ Hide 3D Icons",
        desc = "Coordinates Traffic ",
        author = "Picasso",
        date = "3rd of May 2010",
        license = "GPL3",
        layer = 3,
        version = 1,
        enabled = true
    }
end

if (gadgetHandler:IsSyncedCode()) then
    VFS.Include("scripts/lib_OS.lua")
    VFS.Include("scripts/lib_UnitScript.lua")
    VFS.Include("scripts/lib_Animation.lua")
    VFS.Include("scripts/lib_Build.lua")
    VFS.Include("scripts/lib_mosaic.lua")

    local showHideIconTypes = getShowHideIconTypes(UnitDefs)

    function gadget:UnitCloaked(unitID, unitDefID, teamID)
        if showHideIconTypes[unitDefID] then
            env = Spring.UnitScript.GetScriptEnv(unitID)
            if env and env.showHideIcon then
                Spring.UnitScript.CallAsUnit(unitID, env.showHideIcon, true)
            end
        end
    end
    
    function gadget:UnitDecloaked(unitID, unitDefID, teamID)
        if showHideIconTypes[unitDefID] then
            env = Spring.UnitScript.GetScriptEnv(unitID)
            if env and env.showHideIcon then
               -- Spring.Echo("Calling Decloak for "..UnitDefs[unitDefID].name)
                Spring.UnitScript.CallAsUnit(unitID, env.showHideIcon, false)
            end
        end
    end
end
