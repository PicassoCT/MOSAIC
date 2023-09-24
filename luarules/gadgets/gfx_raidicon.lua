function gadget:GetInfo()
    return {
        name = "Icon Rendering ",
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
    VFS.Include("scripts/lib_UnitScript.lua")
    VFS.Include("scripts/lib_mosaic.lua")
    local iconTypeTable = getIconTypes(UnitDefs)
    local GameConfig = getGameConfig()

    function gadget:UnitCreated(unitID, unitDefID)
        if iconTypeTable[unitDefID] then
            --Spring.Echo("Icon Type " .. UnitDefs[unitDefID].name .. " created")
            SendToUnsynced("setUnitLuaDraw", unitID, unitDefID)
            SendToUnsynced("unsetUnitLuaDraw", unitID, unitDefID)
        end
    end

else -- unsynced


    local SO_NODRAW_FLAG = 0
    local SO_OPAQUE_FLAG = 1
    local SO_ALPHAF_FLAG = 2
    local SO_REFLEC_FLAG = 4
    local SO_REFRAC_FLAG = 8
    local SO_SHOPAQ_FLAG = 16
    local SO_SHTRAN_FLAG = 32
    local SO_DRICON_FLAG = 128

    local iconTables = {}
    local isRaidIconTable = {}

    local function setUnitLuaDraw(callname, unitID, typeDefID)
        iconTables[unitID] = typeDefID
        Spring.UnitRendering.SetUnitLuaDraw(unitID, true)
        local drawMask = SO_OPAQUE_FLAG + SO_ALPHAF_FLAG +SO_REFLEC_FLAG  +SO_REFRAC_FLAG + SO_DRICON_FLAG
        Spring.SetUnitEngineDrawMask(unitID, drawMask)
    end

    local function unsetUnitLuaDraw(callname, unitID, typeDefID)
        iconTables[unitID] = nil
        Spring.UnitRendering.SetUnitLuaDraw(unitID, false)
    end

    function gadget:Initialize()
        --Spring.Echo(GetInfo().name .. " Initialization started")
        gadgetHandler:AddSyncAction("setUnitLuaDraw", setUnitLuaDraw)
        gadgetHandler:AddSyncAction("unsetUnitLuaDraw", unsetUnitLuaDraw)
        --Spring.Echo(GetInfo().name .. " Initialization ended")
    end

    local glUnitRaw = gl.UnitRaw
    local glBlending = gl.Blending
    local GL_SRC_ALPHA           = GL.SRC_ALPHA
    local GL_ONE                 = GL.ONE
    local GL_ONE_MINUS_SRC_ALPHA = GL.ONE_MINUS_SRC_ALPHA

    function gadget:DrawUnit(unitID, drawMode)
        if drawMode == 1 and iconTables[unitID] then --transparent draw

            gl.DepthTest(true)
            gl.DepthMask(true)
            glBlending(GL_SRC_ALPHA, GL_ONE)
            glUnitRaw(unitID, true)
            glBlending(GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA)
            return true
        end
    end
end
