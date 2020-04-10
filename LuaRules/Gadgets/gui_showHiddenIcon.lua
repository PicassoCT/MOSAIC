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


    function gadget:UnitCloaked( unitID, unitDefID, teamID)
        env = Spring.UnitScript.GetScriptEnv(unitID)
        if env and env.showHideIcon then
			Spring.UnitScript.CallAsUnit(unitID, env.showHideIcon, true)
        end
    end
    function gadget:UnitDecloaked( unitID, unitDefID, teamID)
        env = Spring.UnitScript.GetScriptEnv(unitID)
          if env and env.showHideIcon then
			Spring.UnitScript.CallAsUnit(unitID, env.showHideIcon, false)
        end
    end
end
