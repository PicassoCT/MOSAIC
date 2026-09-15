function gadget:GetInfo()
    return {
        name = "Transparent Icon Rendering",
        desc = "Transparent unit-based icons for Spring 105 and Recoil",
        author = "Picasso",
        date = "3rd of May 2010",
        license = "GPL3",
        layer = math.huge,
        version = 3,
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

    function gadget:Initialize()
        -- Re-register units when LuaRules is reloaded in a running match.
        for _, unitID in ipairs(Spring.GetAllUnits()) do
            self:UnitCreated(unitID, Spring.GetUnitDefID(unitID))
        end
    end

else
    local iconUnits = {}
    local iconShader
    local uniforms = {}
    local emcDefID = UnitDefNames.icon_emc.id

    ---------------------------------------------------------------------------
    -- Engine selection
    --
    -- Spring 105.0 and earlier:
    --     Preserve the original DrawUnit interception.
    --
    -- Recoil 105.1 and later:
    --     Hide the engine-rendered model and explicitly redraw it during
    --     DrawWorld with explicitly bound model textures and alpha blending.
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

        -- Keep the engine model visible if shader compilation failed.
        if not useLegacyDrawUnit and not iconShader then return end

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
        if not useLegacyDrawUnit then
            iconShader = gl.CreateShader({
                vertex = VFS.LoadFile("luarules/gadgets/shaders/iconAlpha.vert"),
                fragment = VFS.LoadFile("luarules/gadgets/shaders/iconAlpha.frag"),
                uniformInt = { diffuseTex = 0, shadingTex = 1 },
            })
            if iconShader then
                for _, name in ipairs({"teamColor", "opacity", "time", "glitch", "seed"}) do
                    uniforms[name] = gl.GetUniformLocation(iconShader, name)
                end
            else
                Spring.Echo("[Transparent Icon Rendering] Shader failed; using engine models:",
                    gl.GetShaderLog() or "no shader log")
            end
        end

        gadgetHandler:AddSyncAction(
            "setIconLuaDraw",
            setIconLuaDraw
        )

        gadgetHandler:AddSyncAction(
            "unsetIconLuaDraw",
            unsetIconLuaDraw
        )

        -- Also recover units whose creation messages predate this gadget.
        VFS.Include("scripts/lib_mosaic.lua")
        local iconTypes = getIconTypes(UnitDefs)
        for _, unitID in ipairs(Spring.GetAllUnits()) do
            local unitDefID = Spring.GetUnitDefID(unitID)
            if iconTypes[unitDefID] then
                setIconLuaDraw(nil, unitID, unitDefID)
            end
        end

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

    -- Older Recoil builds do not expose GetUnitDrawPosition.
    -- GetUnitPosition supplies the world-space root position in that case.
    local spGetUnitDrawPosition = Spring.GetUnitDrawPosition or Spring.GetUnitPosition

    local glPushMatrix = gl.PushMatrix
    local glPopMatrix = gl.PopMatrix
    local glTranslate = gl.Translate
    function gadget:DrawWorld()
        if useLegacyDrawUnit or not iconShader then
            return
        end

        -- noDraw models still need explicit LOS and cloak filtering.
        local _, fullView = Spring.GetSpectatingState()
        local allyTeamID = Spring.GetMyAllyTeamID()
        local cx, cy, cz = Spring.GetCameraPosition()
        local visible = {}
        for unitID, unitDefID in pairs(iconUnits) do
            if not spValidUnitID(unitID) then
                iconUnits[unitID] = nil
            elseif Spring.IsUnitInView(unitID) and not Spring.GetUnitIsCloaked(unitID) then
                local los = Spring.GetUnitLosState(unitID, allyTeamID)
                if fullView or (los and los.los) then
                    local x, y, z = spGetUnitDrawPosition(unitID)
                    if x then
                        visible[#visible + 1] = {
                            id = unitID, def = unitDefID, x = x, y = y, z = z,
                            distance = (x-cx)^2 + (y-cy)^2 + (z-cz)^2,
                        }
                    end
                end
            end
        end
        if #visible == 0 then return end
        table.sort(visible, function(a, b)
            if a.distance == b.distance then return a.id < b.id end
            return a.distance > b.distance
        end)

        gl.PushAttrib(GL.ALL_ATTRIB_BITS)
        gl.DepthTest(true)
        glDepthMask(false)
        gl.Culling(false)
        glBlending(GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA)
        gl.UseShader(iconShader)
        gl.Uniform(uniforms.opacity, 0.65)
        gl.Uniform(uniforms.time, Spring.GetGameSeconds())

        for _, unit in ipairs(visible) do
            local r, g, b = Spring.GetTeamColor(Spring.GetUnitTeam(unit.id))
            gl.Uniform(uniforms.teamColor, r, g, b)
            gl.Uniform(uniforms.glitch, unit.def == emcDefID and 1 or 0)
            gl.Uniform(uniforms.seed, unit.id)
            gl.Texture(0, string.format("%%%d:0", unit.def))
            gl.Texture(1, string.format("%%%d:1", unit.def))

            glPushMatrix()
            glTranslate(unit.x, unit.y, unit.z)
            -- Preserve the explicit world position that fixed icons at 0/0.
            -- UnitRaw supplies the animated local-piece transforms only.
            glUnitRaw(unit.id, true)
            glPopMatrix()
        end

        gl.Texture(1, false)
        gl.Texture(0, false)
        gl.UseShader(0)
        gl.PopAttrib()
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
        if iconShader then gl.DeleteShader(iconShader) end
    end
end
