function gadget:GetInfo()
    return {
        name = "Transparent Icon Rendering",
        desc = "Transparent unit-based icons for Spring 105 and Recoil",
        author = "Picasso",
        date = "3rd of May 2010",
        license = "GPL3",
        layer = math.huge,
        version = 2,
        enabled = true
    }
end

if gadgetHandler:IsSyncedCode() then
    VFS.Include("scripts/lib_mosaic.lua")

    local transparentTypeTable = getIconTypes(UnitDefs)

    function gadget:UnitCreated(unitID, unitDefID)
        if transparentTypeTable[unitDefID] then
            SendToUnsynced("setIconLuaDraw", unitID, unitDefID)
        end
    end

    function gadget:UnitDestroyed(unitID, unitDefID)
        if transparentTypeTable[unitDefID] then
            SendToUnsynced("unsetIconLuaDraw", unitID, unitDefID)
        end
    end

else
    local iconUnits = {}

    ---------------------------------------------------------------------------
    -- Engine selection
    --
    -- Spring 105.0 and earlier:
    --     Preserve the original DrawUnit interception.
    --
    -- Recoil 105.1 and later:
    --     Hide the engine-rendered model and explicitly redraw it during
    --     DrawWorld with additive transparency.
    ---------------------------------------------------------------------------

    local engineVersionString = Engine.version or "0"
    local engineMajorMinor =
        tonumber(engineVersionString:match("^(%d+%.?%d*)")) or 0

    local useLegacyDrawUnit = engineMajorMinor <= 105.0

    ---------------------------------------------------------------------------
    -- Cached API functions
    ---------------------------------------------------------------------------

    local spValidUnitID = Spring.ValidUnitID
    local spSetUnitNoDraw = Spring.SetUnitNoDraw
    local spSetUnitLuaDraw = Spring.UnitRendering.SetUnitLuaDraw
    local spSetUnitAlwaysUpdateMatrix = Spring.SetUnitAlwaysUpdateMatrix

    local glUnit = gl.Unit
    local glUnitRaw = gl.UnitRaw
    local glBlending = gl.Blending
    local glDepthMask = gl.DepthMask

    local GL_SRC_ALPHA = GL.SRC_ALPHA
    local GL_ONE = GL.ONE
    local GL_ONE_MINUS_SRC_ALPHA = GL.ONE_MINUS_SRC_ALPHA

    ---------------------------------------------------------------------------
    -- Icon registration
    ---------------------------------------------------------------------------

    local function setIconLuaDraw(_, unitID, unitDefID)
        iconUnits[unitID] = unitDefID

        if useLegacyDrawUnit then
            -- Original Spring 105 rendering path.
            spSetUnitLuaDraw(unitID, true)
        else
            -- Recoil path.
            --
            -- SetUnitNoDraw prevents the normal opaque unit render.
            -- AlwaysUpdateMatrix is required because otherwise a noDraw unit's
            -- render matrix can remain at identity, placing gl.Unit at 0/0.
            spSetUnitLuaDraw(unitID, false)
            spSetUnitAlwaysUpdateMatrix(unitID, true)
            spSetUnitNoDraw(unitID, true)
        end
    end

    local function unsetIconLuaDraw(_, unitID)
        iconUnits[unitID] = nil

        if spValidUnitID(unitID) then
            spSetUnitLuaDraw(unitID, false)

            if not useLegacyDrawUnit then
                spSetUnitNoDraw(unitID, false)
                spSetUnitAlwaysUpdateMatrix(unitID, false)
            end
        end
    end

    function gadget:Initialize()
        gadgetHandler:AddSyncAction(
            "setIconLuaDraw",
            setIconLuaDraw
        )

        gadgetHandler:AddSyncAction(
            "unsetIconLuaDraw",
            unsetIconLuaDraw
        )

        Spring.Echo(
            "[Transparent Icon Rendering] Engine:",
            engineVersionString,
            useLegacyDrawUnit and "legacy DrawUnit path"
                or "Recoil DrawWorld path"
        )
    end

    ---------------------------------------------------------------------------
    -- Spring 105.0 and earlier
    ---------------------------------------------------------------------------

    function gadget:DrawUnit(unitID, drawMode)
        if not useLegacyDrawUnit then
            return
        end

        if not iconUnits[unitID] then
            return
        end

        glDepthMask(false)
        glBlending(GL_SRC_ALPHA, GL_ONE)

        -- DrawUnit already provides the unit transformation, hence UnitRaw.
        glUnitRaw(unitID, true)

        glBlending(GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA)
        glDepthMask(true)

        -- Suppress the normal engine rendering of this unit.
        return true
    end

    ---------------------------------------------------------------------------
    -- Recoil 105.1 and later
    ---------------------------------------------------------------------------

    function gadget:DrawWorld()
        if useLegacyDrawUnit then
            return
        end

        glDepthMask(false)
        glBlending(GL_SRC_ALPHA, GL_ONE)

        for unitID in pairs(iconUnits) do
            if spValidUnitID(unitID) then
                -- DrawWorld does not provide a unit transformation.
                -- gl.Unit applies the maintained unit render matrix.
                glUnit(unitID, false)
            else
                iconUnits[unitID] = nil
            end
        end

        glBlending(GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA)
        glDepthMask(true)
    end

    ---------------------------------------------------------------------------
    -- Cleanup
    ---------------------------------------------------------------------------

    function gadget:Shutdown()
        gadgetHandler:RemoveSyncAction("setIconLuaDraw")
        gadgetHandler:RemoveSyncAction("unsetIconLuaDraw")

        for unitID in pairs(iconUnits) do
            if spValidUnitID(unitID) then
                spSetUnitLuaDraw(unitID, false)

                if not useLegacyDrawUnit then
                    spSetUnitNoDraw(unitID, false)
                    spSetUnitAlwaysUpdateMatrix(unitID, false)
                end
            end
        end
    end
end