function gadget:GetInfo()
    return {
        name = "Raidicon Rendering Settings ",
        desc = " ",
        author = "Picasso",
        date = "3rd of May 2010",
        license = "GPL3",
        layer = 0,
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
    iconTypeTable = getIconTypes(UnitDefs)
    local GameConfig = getGameConfig()


    function gadget:UnitCreated(unitID, unitDefID)
        if iconTypeTable[unitDefID] then
            Spring.Echo("Icon Type " .. UnitDefs[unitDefID].name .. " created")
            SendToUnsynced("setUnitLuaDraw", unitID, unitDefID)
        end
    end

else -- unsynced
    local iconTables = {}

    local function setUnitLuaDraw(callname, unitID, typeDefID)
        iconTables[unitID] = typeDefID
        Spring.UnitRendering.SetUnitLuaDraw(unitID, true)
    end

    function gadget:Initialize()
        Spring.Echo(GetInfo().name .. " Initialization started")
        gadgetHandler:AddSyncAction("setUnitLuaDraw", setUnitLuaDraw)
        Spring.Echo(GetInfo().name .. " Initialization ended")
    end

    local glUnitRaw = gl.UnitRaw
    local glBlending = gl.Blending
    local glScale = gl.Scale
    local GL_SRC_ALPHA           = GL.SRC_ALPHA
    local GL_ONE                = GL.ONE
    local GL_ZERO               = GL.ZERO
    local GL_ONE_MINUS_SRC_ALPHA = GL.ONE_MINUS_SRC_ALPHA

    function gadget:DrawUnit(unitID, drawMode)
        if iconTables[unitID]  then
           glBlending(GL_SRC_ALPHA, GL_ONE)
            glUnitRaw(unitID, true)
            return true
        end
    end
end
