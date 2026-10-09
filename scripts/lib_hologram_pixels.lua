-- Short RGB interruptions, using only the model's existing pixel pieces.
-- One owner per unit, two interruptions city-wide, and one playful interlude
-- at a time. All scheduling is synced; local /weatherman visuals cannot steer it.
return function(groups, show, hide, available, raining)
    local colours = {"R", "G", "B"}
    local pools, pieces, origins, centres = {}, {}, {}, {}
    local seed = (unitID * 7919 + 104729) % 2147483647
    local function random(lo, hi)
        seed = (seed * 16807) % 2147483647
        return lo + seed % (hi - lo + 1)
    end

    for c = 1, 3 do
        pools[c] = {}
        for _, id in pairs(groups[colours[c]] or {}) do
            pools[c][#pools[c] + 1] = id
        end
        table.sort(pools[c])
        for _, id in ipairs(pools[c]) do pieces[#pieces + 1] = id end
    end
    if #pieces < 9 then return function() end end

    local width = math.min(8, math.floor(math.sqrt(#pieces)))
    local height = width
    local info = Spring.GetUnitPieceInfo(unitID, pieces[1])
    -- Native pixel proportions determine the board's size, not house radius.
    local size = 64
    if info and info.min and info.max then
        size = math.max(info.max[1] - info.min[1], info.max[2] - info.min[2], 1)
    end
    for _, id in ipairs(pieces) do
        local bounds = Spring.GetUnitPieceInfo(unitID, id)
        local centre = {0, 0, 0}
        if bounds and bounds.min and bounds.max then
            for axis = 1, 3 do centre[axis] = (bounds.min[axis] + bounds.max[axis]) * 0.5 end
        end
        centres[id] = centre
    end
    local spacing = size * 1.25
    local visible = {}

    local function clear()
        for _, id in ipairs(pieces) do
            hide(id)
            for axis = 1, 3 do
                Move(id, axis, 0, 0)
                Turn(id, axis, 0, 0)
            end
        end
        visible = {}
    end

    -- Align the authored pixels to one common origin before drawing a board.
    -- Spring's piece-position X convention is opposite UnitScript.Move X.
    local function prepare()
        clear()
        local ax, ay, az = Spring.GetUnitPiecePosition(unitID, pieces[1])
        if not ax then return false end
        local anchor = centres[pieces[1]]
        for _, id in ipairs(pieces) do
            local x, y, z = Spring.GetUnitPiecePosition(unitID, id)
            if not x then return false end
            local centre = centres[id]
            origins[id] = {x - ax + anchor[1] - centre[1],
                ay - y + anchor[2] - centre[2], az - z + anchor[3] - centre[3]}
        end
        return true
    end

    local function cell(board, x, y, colour)
        if x >= 1 and x <= width and y >= 1 and y <= height then
            board[(y - 1) * width + x] = colour
        end
    end

    local function render(board, depth)
        local used, cursor = {}, {1, 1, 1}
        for index = 1, width * height do
            local colour = board[index]
            if colour then
                local id
                for offset = 0, 2 do
                    local c = (colour - 1 + offset) % 3 + 1
                    id = pools[c][cursor[c]]
                    if id then
                        cursor[c] = cursor[c] + 1
                        break
                    end
                end
                if id then
                    local x = (index - 1) % width + 1
                    local y = math.floor((index - 1) / width) + 1
                    local origin = origins[id]
                    Move(id, x_axis, origin[1] + (x - (width + 1) / 2) * spacing, 0)
                    Move(id, y_axis, origin[2] + y * spacing, 0)
                    Move(id, z_axis, origin[3] + (depth or 0), 0)
                    if not visible[id] then show(id) end
                    used[id] = true
                end
            end
        end
        for id in pairs(visible) do if not used[id] then hide(id) end end
        visible = used
    end

    local function frame(board, ms, depth)
        if not available() then return false end
        render(board, depth)
        Sleep(ms)
        return available()
    end

    local function glitch(wet)
        -- Torn scan lines and dropped RGB packets; rain adds falling tails.
        local row = random(1, height)
        for tick = 1, (wet and 12 or 6) do
            local board = {}
            for x = 1, width do
                if random(1, 4) > 1 then cell(board, x, row, random(1, 3)) end
                if wet then
                    local head = (height + x - tick) % height + 1
                    cell(board, x, head, (x + tick) % 3 + 1)
                    if x % 2 == 0 then cell(board, x, head + 1, 2) end
                end
            end
            if not frame(board, 120, random(-1, 1) * size) then return end
            row = (row + random(0, 2)) % height + 1
        end
    end

    local function life()
        -- Conway B3/S23, finite board. Gliders and a blinker seed the advert.
        local board = {}
        for _, p in ipairs({{2, 2}, {3, 3}, {1, 4}, {2, 4}, {3, 4},
                            {6, 5}, {6, 6}, {6, 7}}) do
            cell(board, p[1], p[2], 2)
        end
        for generation = 1, 20 do
            if not frame(board, 280) then return end
            local nextBoard, alive = {}, 0
            for y = 1, height do
                for x = 1, width do
                    local neighbours = 0
                    for dy = -1, 1 do
                        for dx = -1, 1 do
                            local nx, ny = x + dx, y + dy
                            if (dx ~= 0 or dy ~= 0) and nx >= 1 and nx <= width
                                and ny >= 1 and ny <= height
                                and board[(ny - 1) * width + nx] then
                                neighbours = neighbours + 1
                            end
                        end
                    end
                    local index = (y - 1) * width + x
                    if neighbours == 3 or (board[index] and neighbours == 2) then
                        nextBoard[index] = board[index] and 2 or generation % 3 + 1
                        alive = alive + 1
                    end
                end
            end
            board = nextBoard
            if alive == 0 then return end
        end
    end

    local shapes = {
        {{0, 0}, {1, 0}, {2, 0}, {3, 0}},
        {{0, 0}, {1, 0}, {0, 1}, {1, 1}},
        {{0, 0}, {1, 0}, {2, 0}, {1, 1}},
        {{0, 0}, {0, 1}, {1, 0}, {2, 0}},
    }
    local function blocks()
        local settled = {}
        -- Leave a four-cell gap: the first bar completes and clears a line.
        for x = 5, width do cell(settled, x, 1, 3) end
        for drop = 1, 3 do
            local shape = shapes[drop == 1 and 1 or random(1, #shapes)]
            local column = drop == 1 and 1 or random(1, math.max(1, width - 3))
            local function fits(y)
                for _, p in ipairs(shape) do
                    local x, cy = column + p[1], y + p[2]
                    if x > width or cy < 1 or cy > height
                        or settled[(cy - 1) * width + x] then return false end
                end
                return true
            end
            local y = height - 1
            if not fits(y) then return end
            while true do
                local board = {}
                for index, colour in pairs(settled) do board[index] = colour end
                for _, p in ipairs(shape) do cell(board, column + p[1], y + p[2], drop) end
                if not frame(board, 220) then return end
                if not fits(y - 1) then
                    settled = board
                    break
                end
                y = y - 1
            end
            local row = 1
            while row <= height do
                local full = true
                for x = 1, width do
                    if not settled[(row - 1) * width + x] then full = false end
                end
                if full then
                    for x = 1, width do cell(settled, x, row, 1) end
                    if not frame(settled, 180) then return end
                    for cy = row, height do
                        for x = 1, width do
                            settled[(cy - 1) * width + x] = settled[cy * width + x]
                        end
                    end
                else
                    row = row + 1
                end
            end
        end
        frame(settled, 500)
    end

    local function scanner()
        -- A corporate eye briefly looks back, then loses its signal.
        for tick = 1, 24 do
            local board = {}
            local scan = (tick - 1) % width + 1
            for x = 1, width do
                local edge = (x == 1 or x == width) and 0 or 1
                cell(board, x, 3 - edge, 3)
                cell(board, x, height - 2 + edge, 3)
            end
            for y = 3, height - 2 do cell(board, scan, y, 1) end
            if not frame(board, 180) then return end
        end
        glitch(false)
    end

    local function digitalRain()
        for tick = 1, 30 do
            local board = {}
            for x = 1, width do
                local head = (height + x * 3 - tick) % (height + 3) + 1
                cell(board, x, head, x % 3 + 1)
                cell(board, x, head + 1, 2)
                cell(board, x, head + 2, 3)
            end
            if not frame(board, 170) then return end
        end
    end

    local fillers = width >= 7 and {life, blocks, scanner, digitalRain} or {digitalRain}
    local lastFiller = 0

    local function groundSplash()
        if #pieces < 48 or not raining() then return end
        local splashX, splashZ
        local probe = pieces[1]
        local origin = origins[probe]
        -- Try four sides of the sign, rejecting water and occupied ground.
        -- Only performed for this very rare effect, not by the idle scheduler.
        local phase = random(0, 359) * math.pi / 180
        for attempt = 1, 4 do
            local angle = phase + attempt * math.pi * 0.5
            local x = math.cos(angle) * spacing * (width / 2 + 3)
            local z = math.sin(angle) * spacing * (width / 2 + 3)
            Move(probe, x_axis, origin[1] + x, 0)
            Move(probe, z_axis, origin[3] + z, 0)
            local wx, _, wz = Spring.GetUnitPiecePosDir(unitID, probe)
            if wx and wx > spacing * 3.5 and wx < Game.mapSizeX - spacing * 3.5
                and wz > spacing * 3.5 and wz < Game.mapSizeZ - spacing * 3.5
                and Spring.GetGroundHeight(wx, wz) >= 0 then
                local blocked = false
                for _, id in ipairs(Spring.GetUnitsInCylinder(wx, wz, spacing * 3.5) or {}) do
                    if id ~= unitID and Spring.GetUnitBlocking(id) then blocked = true end
                end
                if not blocked then splashX, splashZ = x, z; break end
            end
        end
        if not splashX then return end

        local function draw(points)
            if not available() or not raining() then return false end
            local used, cursor = {}, {1, 1, 1}
            for _, p in ipairs(points) do
                local id
                for offset = 0, 2 do
                    local c = (p[4] - 1 + offset) % 3 + 1
                    id = pools[c][cursor[c]]
                    if id then cursor[c] = cursor[c] + 1; break end
                end
                if id then
                    local o = origins[id]
                    Move(id, x_axis, o[1] + splashX + p[1] * spacing, 0)
                    Move(id, z_axis, o[3] + splashZ + p[3] * spacing, 0)
                    Move(id, y_axis, 0, 0)
                    -- These sign models are upright. Query the actual world
                    -- position after horizontal placement, so rotated signs
                    -- and uneven terrain do not put the crown underground.
                    local wx, wy, wz = Spring.GetUnitPiecePosDir(unitID, id)
                    if not wx then return false end
                    local ground = Spring.GetGroundHeight(wx, wz)
                    if ground < 0 then return false end
                    Move(id, y_axis, ground - wy - centres[id][2]
                        + size * 0.55 + math.max(0, p[2]) * spacing, 0)
                    if not visible[id] then show(id) end
                    used[id] = true
                end
            end
            for id in pairs(visible) do if not used[id] then hide(id) end end
            visible = used
            Sleep(120)
            return true
        end

        -- Fall, then a short held crown silhouette, separating beads and a
        -- receding ring. Analytic curves suggest fluid complexity without a sim.
        for tick = 1, 12 do
            local t = tick / 12
            local y = 5 * (1 - t * t)
            if not draw({{0, y, 0, 3}, {0, y + 0.7, 0, 2},
                         {0.45, y + 0.2, 0, 1}, {-0.45, y + 0.2, 0, 3}}) then return end
        end
        for tick = 1, 28 do
            -- Spend extra time near peak height to sell the slow-motion reveal.
            local t = tick <= 10 and tick / 20
                or (tick <= 17 and 0.5 or 0.5 + (tick - 17) / 22)
            local rise = math.sin(math.pi * t)
            local radius = 0.65 + 1.55 * t
            local points = {}
            for i = 1, 12 do
                local angle = i * math.pi / 6
                local c, s = math.cos(angle), math.sin(angle)
                points[#points + 1] = {c * radius, 0.15, s * radius, 3}
                points[#points + 1] = {c * radius, rise * 0.9, s * radius, 2}
                points[#points + 1] = {c * radius, rise * (1.6 + i % 2 * 0.3), s * radius, 1}
                if t > 0.35 then
                    local r = radius + (t - 0.35) * 1.1
                    local y = math.max(0, rise * 2.8 - (t - 0.5)^2 * 3)
                    points[#points + 1] = {c * r, y, s * r, i % 3 + 1}
                end
            end
            if not draw(points) then return end
        end
        for tick = 1, 12 do
            local points = {}
            local radius = 2.2 + tick / 12
            for i = 1, 24 do
                if tick < 7 or i % 2 == tick % 2 then
                    local angle = i * math.pi / 12
                    points[#points + 1] = {math.cos(angle) * radius, 0,
                        math.sin(angle) * radius, i % 3 + 1}
                end
            end
            if not draw(points) then return end
        end
    end

    local function acquire(filler)
        local now = Spring.GetGameFrame()
        GG.HologramPixelSlots = GG.HologramPixelSlots or {}
        local slots = GG.HologramPixelSlots
        local count = 0
        for id, expiry in pairs(slots) do
            if expiry <= now or not Spring.ValidUnitID(id) or Spring.GetUnitIsDead(id) then
                slots[id] = nil
            else
                count = count + 1
            end
        end
        if count >= 2 or (filler and now < (GG.HologramPixelFillerNextFrame or 0)) then
            return false
        end
        slots[unitID] = now + 300 -- bounded sequences finish in under ten seconds
        if filler then GG.HologramPixelFillerNextFrame = now + random(60, 100) * 30 end
        return true
    end

    return function()
        local now = Spring.GetGameFrame()
        local nextGlitch = now + random(25, 90) * 30
        local nextFiller = now + random(120, 300) * 30
        local nextSplash = now + random(180, 360) * 30
        while true do
            now = Spring.GetGameFrame()
            if available() then
                local wet = raining()
                if not wet then nextSplash = now + random(180, 360) * 30 end
                if wet and now >= nextSplash then
                    nextSplash = now + random(900, 1800) * 30
                    if now >= (GG.HologramPixelSplashNextFrame or 0) and acquire(true) then
                        GG.HologramPixelSplashNextFrame = now + random(360, 600) * 30
                        if prepare() then groundSplash() end
                        clear()
                        GG.HologramPixelSlots[unitID] = nil
                    end
                elseif now >= nextFiller then
                    nextFiller = now + random(210, 420) * 30
                    if acquire(true) then
                        if prepare() then
                            local index = random(1, #fillers)
                            if index == lastFiller then index = index % #fillers + 1 end
                            lastFiller = index
                            fillers[index]()
                        end
                        clear()
                        GG.HologramPixelSlots[unitID] = nil
                    end
                elseif now >= nextGlitch then
                    nextGlitch = now + random(wet and 18 or 80, wet and 45 or 180) * 30
                    if acquire(false) then
                        if prepare() then glitch(wet) end
                        clear()
                        GG.HologramPixelSlots[unitID] = nil
                    end
                end
            else
                if next(visible) then clear() end
                -- Re-arm across dawn/blackout, avoiding a city-wide dusk burst.
                nextGlitch = now + random(25, 90) * 30
                nextFiller = now + random(120, 300) * 30
                nextSplash = now + random(180, 360) * 30
            end
            Sleep(2000 + unitID % 7 * 100)
        end
    end
end
