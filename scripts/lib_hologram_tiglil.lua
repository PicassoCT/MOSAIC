-- Shared lifecycle for both western hologram models. The animation library's
-- child threads also carry SIG_TIGLIL, so stopping a show stops hair/gestures.
return function(options)
    local playing = false
    local function registry()
        GG.TiglilHoloTable = GG.TiglilHoloTable or {}
        GG.TiglilHoloTable[unitDefID] = GG.TiglilHoloTable[unitDefID] or {}
        return GG.TiglilHoloTable[unitDefID]
    end

    local function stop()
        Signal(SIG_TIGLIL)
        playing = false
        registry()[unitID] = nil
        for _, id in pairs(options.pieces) do
            HideReg(id)
            for axis = 1, 3 do
                StopSpin(id, axis, 0)
                Move(id, axis, 0, 0)
                Turn(id, axis, 0, 0)
            end
        end
        hideTReg(options.glowSticks)
        if options.skimpy then HideReg(options.skimpy) end
    end

    local function perform()
        SetSignalMask(SIG_CORE + SIG_TIGLIL)
        local animations = options.animations
        while options.available() do
            -- Do not let subordinate poses overlap the next animation.
            Signal(SIG_HAIR)
            Signal(SIG_GESTE)
            Signal(SIG_TALKHEAD)
            Signal(SIG_INCIRCLE)
            TigLilSetup()
            if options.techno then
                local sticks = options.glowSticks or {}
                if #sticks > 0 then
                    ShowReg(sticks[math.random(1, #sticks)])
                    ShowReg(sticks[math.random(1, #sticks)])
                end
            end
            Sleep(math.random(512, 4096))
            if options.available() then
                animations[math.random(1, #animations)](options.techno)
            end
        end
    end

    local function run()
        SetSignalMask(SIG_CORE)
        if unitID % 3 ~= 0 or #options.animations == 0 then return end
        -- Readiness checks prevent an incomplete model from starting a show.
        local pieceMap = Spring.GetUnitPieceMap(unitID)
        for _, name in ipairs({"tigLil", "tlHead", "tlarm", "tlarmr",
                                "tllegUp", "tllegLow", "tllegUpR", "tllegLowR"}) do
            if not pieceMap[name] then return end
        end
        while true do
            local performers = registry()
            local now, count = Spring.GetGameFrame(), 0
            for id, expiry in pairs(performers) do
                if not Spring.ValidUnitID(id) or Spring.GetUnitIsDead(id) or expiry <= now then
                    performers[id] = nil
                else
                    count = count + 1
                end
            end
            if options.available() then
                if playing then
                    performers[unitID] = now + 90
                elseif count < 3 then
                    performers[unitID] = now + 90
                    playing = true
                    if options.skimpy and maRa() then ShowReg(options.skimpy) end
                    StartThread(perform)
                end
            elseif playing then
                stop()
            end
            Sleep(1000)
        end
    end

    return {run = run, stop = stop}
end
