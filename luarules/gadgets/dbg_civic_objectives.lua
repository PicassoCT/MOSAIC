function gadget:GetInfo()
    return {
        name = "Civic objective preview",
        desc = "Cheat-only placement of the eight civic objective prototypes",
        author = "Mosaic contributors", layer = 60, enabled = true,
    }
end
if not gadgetHandler:IsSyncedCode() then return end

local specs = VFS.Include("luarules/configs/civic_objectives.lua")

local function spawn(_, _, words)
    if not Spring.IsCheatingEnabled() then
        Spring.Echo("Civic objectives: enable /cheat first.")
        return true
    end
    words = words or {}
    local x = tonumber(words[1]) or Game.mapSizeX / 2
    local z = tonumber(words[2]) or Game.mapSizeZ / 2
    if x ~= x or z ~= z or x == math.huge or z == math.huge
        or x == -math.huge or z == -math.huge then return true end
    local placed = 0
    for i, spec in ipairs(specs) do
        local px = x + ((i - 1) % 4 - 1.5) * 192
        local pz = z + (math.floor((i - 1) / 4) - .5) * 192
        local low, high = math.huge, -math.huge
        if px > 64 and pz > 64 and px < Game.mapSizeX - 64 and pz < Game.mapSizeZ - 64 then
            for dx = -64, 64, 64 do
                for dz = -64, 64, 64 do
                    local h = Spring.GetGroundHeight(px + dx, pz + dz)
                    low, high = math.min(low, h), math.max(high, h)
                end
            end
            if low >= 0 and high - low <= 12 and #Spring.GetUnitsInCylinder(px, pz, 92) == 0 then
                local id = Spring.CreateUnit(spec.name, px, Spring.GetGroundHeight(px,pz), pz, 0, Spring.GetGaiaTeamID())
                if id then placed = placed + 1 end
            end
        end
    end
    Spring.Echo("Civic objectives: placed " .. placed .. "/8. Occupied, wet, steep or out-of-map plots were skipped.")
    return true
end

function gadget:Initialize()
    gadgetHandler:AddChatAction("civicobjectives", spawn, "[x z]: preview eight Gaia objectives on clear, dry ground (requires cheats)")
end

function gadget:Shutdown()
    gadgetHandler:RemoveChatAction("civicobjectives")
end
