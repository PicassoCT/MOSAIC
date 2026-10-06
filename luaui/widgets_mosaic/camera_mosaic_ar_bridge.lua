function widget:GetInfo()
    return {
        name      = "MOSAIC AR Bridge",
        desc      = "Pairs a local ARCore device over Wi-Fi and drives a Recoil camera from its pose",
        author    = "PicassoCT / OpenAI",
        date      = "2026-10-06",
        license   = "GNU GPL, v2 or later",
        layer     = 100000,
        enabled   = false,
    }
end

-- This is intentionally unsynced LuaUI. It must never alter simulation state.
-- Runtime network traffic is local-LAN UDP only.
local spEcho           = Spring.Echo
local spGetCameraState = Spring.GetCameraState
local spSetCameraState = Spring.SetCameraState
local spGetGroundHeight= Spring.GetGroundHeight

local PROTOCOL = "MOSAICAR/2"
local LEGACY_PREFIX = "SPRINGAR;"
local PORT = 9000
local PAIR_TIMEOUT = 3.0
local POSE_TIMEOUT = 0.75
local ANNOUNCE_INTERVAL = 1.0
local DEFAULT_TABLE_WIDTH_M = 1.20

local udp
local pairedIP
local pairedPort
local pairToken
local lastPacketAt = -math.huge
local lastAnnounceAt = -math.huge
local previousCamera
local enabled = false
local runtime = 0
local streamStarted = false
local mapScale = Game.mapSizeX / DEFAULT_TABLE_WIDTH_M
local mapCenterX = Game.mapSizeX * 0.5
local mapCenterZ = Game.mapSizeZ * 0.5

local function now()
    return runtime
end

local function makeToken()
    local t = tostring(os.clock()):gsub("%D", "")
    return tostring(Spring.GetGameFrame() or 0) .. "-" .. t:sub(-8)
end

local function splitSemi(s)
    local out = {}
    for item in s:gmatch("([^;]+)") do
        out[#out + 1] = item
    end
    return out
end

local function kvFields(s)
    local out = {}
    for token in s:gmatch("([^;]+)") do
        local k, v = token:match("^([^=]+)=(.*)$")
        if k then out[k] = v end
    end
    return out
end

local function numsCSV(s, expected)
    local out = {}
    if not s then return nil end
    for n in s:gmatch("[^,]+") do
        local v = tonumber(n)
        if not v then return nil end
        out[#out + 1] = v
    end
    if expected and #out ~= expected then return nil end
    return out
end

local function localAddressFor(ip, port)
    if not socket or not socket.udp then return nil end
    local probe = socket.udp()
    if not probe then return nil end
    probe:settimeout(0)
    local ok = probe:setpeername(ip, port or PORT)
    if not ok then probe:close(); return nil end
    local localIP = probe:getsockname()
    probe:close()
    return localIP
end

local function send(msg, ip, port)
    if not udp then return end
    local ok, err = udp:sendto(msg, ip or "255.255.255.255", port or PORT)
    if not ok and err ~= "timeout" then
        spEcho("[MOSAIC AR] UDP send failed:", err)
    end
end

local function stopFrameStream()
    if streamStarted and Spring.StopFrameStream then
        Spring.StopFrameStream()
    end
    streamStarted = false
end

local function startFrameStream(ip)
    if streamStarted or not Spring.StartFrameStream then return end
    local ok = Spring.StartFrameStream({
        address = ip,
        port = 9001,
        width = 640,
        height = 360,
        fps = 20,
    })
    streamStarted = ok and true or false
    if streamStarted then
        spEcho("[MOSAIC AR] framebuffer stream ->", ip .. ":9001")
    else
        spEcho("[MOSAIC AR] framebuffer stream unavailable; pose bridge remains active")
    end
end

local function unpair(reason)
    stopFrameStream()
    if pairedIP then
        spEcho("[MOSAIC AR] disconnected:", reason or "unknown")
    end
    pairedIP, pairedPort = nil, nil
    lastPacketAt = -math.huge
    if previousCamera then
        spSetCameraState(previousCamera, 0)
        previousCamera = nil
    end
end

local function pair(ip, port, token)
    if pairedIP and pairedIP ~= ip then
        send(PROTOCOL .. ";BUSY;", ip, port)
        return false
    end
    pairedIP, pairedPort = ip, port
    pairToken = token or pairToken
    lastPacketAt = now()
    startFrameStream(pairedIP)
    send(PROTOCOL .. ";PAIRED;TOKEN=" .. pairToken .. ";MAP=" .. Game.mapName ..
         ";MAPX=" .. Game.mapSizeX .. ";MAPZ=" .. Game.mapSizeZ ..
         ";SCALE=" .. string.format("%.6f", mapScale) .. ";", pairedIP, pairedPort)
    spEcho("[MOSAIC AR] paired with", pairedIP .. ":" .. pairedPort)
    return true
end

local function normalize(x, y, z)
    local l = math.sqrt(x*x + y*y + z*z)
    if l < 1e-6 then return nil end
    return x/l, y/l, z/l
end

local function applyPose(px, py, pz, dx, dy, dz, fov, scale)
    scale = scale or mapScale

    -- ARCore world: +X right, +Y up, camera looks toward -Z.
    -- Spring world: +X east, +Y up, +Z south.
    local sx = mapCenterX + px * scale
    local sy = py * scale
    local sz = mapCenterZ - pz * scale

    local sdx, sdy, sdz = normalize(dx, dy, -dz)
    if not sdx then return end

    local gh = spGetGroundHeight(sx, sz)
    sy = math.max(gh + 4, gh + sy)

    if not previousCamera then
        previousCamera = spGetCameraState()
    end

    spSetCameraState({
        name = "free",
        mode = 4,
        px = sx,
        py = sy,
        pz = sz,
        dx = sdx,
        dy = sdy,
        dz = sdz,
        fov = fov or 45,
        gndLock = 0,
        gravity = 0,
        slide = 0,
        autoTilt = 0,
        vx = 0, vy = 0, vz = 0,
        avx = 0, avy = 0, avz = 0,
    }, 0)
end

local function handleV2(data, ip, port)
    local fields = kvFields(data)

    if data:find("^" .. PROTOCOL:gsub("([^%w])", "%%%1") .. ";HELLO;") then
        local token = fields.TOKEN
        if token == pairToken then
            pair(ip, port, token)
        else
            send(PROTOCOL .. ";PAIR_REQUIRED;TOKEN=" .. pairToken .. ";", ip, port)
        end
        return
    end

    if not pairedIP or ip ~= pairedIP then return end
    lastPacketAt = now()

    if data:find(";" .. "BYE" .. ";", 1, true) then
        unpair("device closed session")
        return
    end

    if data:find(";" .. "CONFIG" .. ";", 1, true) then
        local tw = tonumber(fields.TABLEWIDTHM)
        if tw and tw > 0.20 and tw < 10.0 then
            mapScale = Game.mapSizeX / tw
        end
        send(PROTOCOL .. ";CONFIG_OK;SCALE=" .. string.format("%.6f", mapScale) .. ";", ip, port)
        return
    end

    if data:find(";" .. "POSE" .. ";", 1, true) then
        local p = numsCSV(fields.POS, 3)
        local d = numsCSV(fields.DIR, 3)
        local fov = tonumber(fields.FOV)
        local scale = tonumber(fields.SCALE)
        if p and d then
            applyPose(p[1], p[2], p[3], d[1], d[2], d[3], fov, scale)
        end
    end
end

local function handleLegacy(data, ip, port)
    -- Compatibility with the 2018 ARDev APK while the Android side is being modernized.
    if data:find("^SPRINGAR;RESET;") then
        unpair("legacy reset")
        send("SPRINGAR;RESET_COMPLETE;", ip, port)
        return
    end

    if data:find("^SPRINGAR;BROADCAST;ARDEVICE;") then
        pair(ip, port, pairToken)
        send("SPRINGAR;REPLY;HOSTIP=" .. (localAddressFor(ip, port) or ip), ip, port)
        return
    end

    if data:find("^SPRINGAR;CFG;") then
        pair(ip, port, pairToken)
        send("SPRINGAR;CFG;RECIEVED;", ip, port)
        return
    end

    if not pairedIP or ip ~= pairedIP then return end
    lastPacketAt = now()

    if data:find("^SPRINGAR;DATA;") then
        local matrixText = data:match("MATRICE=([^R]+)")
        local rotationText = data:match("ROTATION=(.*)$")
        if matrixText and rotationText then
            local m = {}
            for n in matrixText:gmatch("[-+%d%.eE]+") do m[#m + 1] = tonumber(n) end
            local r = {}
            for n in rotationText:gmatch("[-+%d%.eE]+") do r[#r + 1] = tonumber(n) end
            if #m >= 16 and #r >= 3 then
                -- Android matrices are column-major; translation is [13..15].
                -- The 2018 APK sends +Z axis (camera-back), so negate it for forward.
                applyPose(m[13], m[14], m[15], -r[1], -r[2], -r[3], 45, mapScale)
            end
        end
    end
end

local function receiveAll()
    if not udp then return end
    while true do
        local data, ip, port = udp:receivefrom()
        if not data then break end
        if data:sub(1, #PROTOCOL) == PROTOCOL then
            handleV2(data, ip, port)
        elseif data:sub(1, #LEGACY_PREFIX) == LEGACY_PREFIX then
            handleLegacy(data, ip, port)
        end
    end
end

function widget:Initialize()
    if not socket or not socket.udp then
        spEcho("[MOSAIC AR] Recoil LuaSocket is unavailable; disabling widget")
        widgetHandler:RemoveWidget(self)
        return
    end

    udp = assert(socket.udp())
    udp:settimeout(0)
    udp:setoption("reuseaddr", true)
    udp:setoption("broadcast", true)

    local ok, err = udp:setsockname("*", PORT)
    if not ok then
        spEcho("[MOSAIC AR] cannot bind UDP port", PORT, err)
        widgetHandler:RemoveWidget(self)
        return
    end

    pairToken = makeToken()
    enabled = true
    spEcho("[MOSAIC AR] bridge enabled on UDP", PORT, "pair token", pairToken)
    spEcho("[MOSAIC AR] open companion app on same Wi-Fi; no Internet service is used")
end

function widget:Shutdown()
    enabled = false
    if pairedIP then
        send(PROTOCOL .. ";HOST_BYE;", pairedIP, pairedPort)
    end
    unpair("widget disabled")
    if udp then udp:close(); udp = nil end
end

function widget:Update(dt)
    if not enabled then return end
    runtime = runtime + (dt or 0)
    receiveAll()

    local t = now()
    if not pairedIP and (t - lastAnnounceAt) >= ANNOUNCE_INTERVAL then
        lastAnnounceAt = t
        send(PROTOCOL .. ";OFFER;TOKEN=" .. pairToken ..
             ";GAME=MOSAIC;MAP=" .. Game.mapName ..
             ";MAPX=" .. Game.mapSizeX .. ";MAPZ=" .. Game.mapSizeZ .. ";")
    end

    if pairedIP and (t - lastPacketAt) > POSE_TIMEOUT then
        unpair("pose timeout")
    end
end

function widget:TextCommand(command)
    local cmd, arg = command:match("^(%S+)%s*(.*)$")
    if cmd ~= "mosaicar" and cmd ~= "ar" then return false end

    if arg == "status" or arg == "" then
        spEcho("[MOSAIC AR]", pairedIP and ("paired " .. pairedIP) or "waiting",
               "token=" .. tostring(pairToken),
               "scale=" .. string.format("%.2f", mapScale) .. " elmos/m")
    elseif arg == "reset" then
        unpair("manual reset")
        pairToken = makeToken()
    else
        spEcho("[MOSAIC AR] commands: /luaui mosaicar status | reset")
    end
    return true
end
