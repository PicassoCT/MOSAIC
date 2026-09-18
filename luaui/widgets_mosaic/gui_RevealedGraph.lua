-- Presentation only: consumes the existing RevealedGraphChanged payload.
-- Recruitment, discovery, position updates and expiry remain owned by LuaRules.
function widget:GetInfo()
    return {name = "highlightRevealedUnitGraph", desc = "Revealed recruitment network",
        author = "Picasso, visual overhaul", date = "2026", license = "GNU GPL v2 or later",
        layer = 15, enabled = true, handler = true, hidden = true}
end

local locations, appearances = {}, {}
local sourceColor = {0.20, 0.96, 0.99}
local parentColor = {0.68, 0.36, 1.0}
local childColor = {1.0, 0.62, 0.20}
local pi, sin, cos, sqrt = math.pi, math.sin, math.cos, math.sqrt
local max, min = math.max, math.min
local function clamp(v, lo, hi) return max(lo, min(hi, v)) end
local function color(c, a) gl.Color(c[1], c[2], c[3], a) end
local function validPosition(p)
    return type(p) == "table" and type(p.x) == "number"
        and type(p.y) == "number" and type(p.z) == "number"
end
local function sourceKey(loc)
    return table.concat({loc.teamID or -1, loc.x, loc.y, loc.z, loc.endFrame}, ":")
end
local function receive(payload)
    if type(payload) ~= "string" then return end
    local chunk = loadstring(payload)
    if not chunk then return end
    -- The producer sends a serialized table, never executable UI instructions.
    setfenv(chunk, {})
    local ok, decoded = pcall(chunk)
    if not ok or type(decoded) ~= "table" then return end
    locations = decoded
end

local function getDetermenisticHash()
  local accumulated = 0
  local mapName = Game.mapName
  local mapNameLength = string.len(mapName)

  for i=1, mapNameLength do
    accumulated = accumulated + string.byte(mapName,i)
  end

  accumulated = accumulated + Game.mapSizeX
  accumulated = accumulated + Game.mapSizeZ
  return accumulated
end

local function getCountryByCulture()
  local culture =  Spring.GetGameRulesParam ("culture") 
  if not culture then return "Atlantian" end
  local hash = getDetermenisticHash()
  local region_countryMap = {}
  region_countryMap ={
    Africa = {"Chad","Central African Republic","Senegal","Lesotho","Congo","Ghana","Botswana","Togo","Swaziland","South Africa","Eritrea","Zimbabwe","Algeria","Malawi","Sierra Leone","Liberia","Zambia","Kenya","Ethiopia","Guinea","Djibouti","Burkina Faso","Nigeria","Uganda","Comoros","Saint Helena","Guinea-Bissau","Namibia","Gambia","Benin","Gabon","Trinidad And Tobago","Niger","Cameroon","Angola","Cabo Verde","Burundi","Somalia","Mali","Tanzania","Rwanda","Mozambique","Côte D’Ivoire","Madagascar","Saint Martin"},
    MiddleEast = {"Tunisia","Libya","Sudan","Syria","Saudi Arabia","Jordan","Kuwait","Brunei","Algeria","Turkey","Iran","Lebanon","Qatar","West Bank","United Arab Emirates","Israel","Bahrain","Gaza Strip","Armenia","Iraq","Oman","Yemen","Egypt","Morocco","Pakistan", "Western Sahara", "Mauritania"},
    CentralAsia = {"Bhutan","Tajikistan","Iran","Georgia","Nepal","Azerbaijan","Russia","Kyrgyzstan","Afghanistan","Turkmenistan","Pakistan","Uzbekistan","Mongolia","Kazakhstan"},
    Europe = {"Cyprus","Belarus","Slovakia","Greece","Hungary","Montenegro","Macedonia","Kosovo","Sweden","Luxembourg","Belgium","Slovenia","Albania","Turkey","Serbia","Ukraine","France","Liechtenstein","United Kingdom","Iceland","Italy","Czechia","Andorra","Poland","Netherlands","Croatia","Russia","Malta","Germany","Ireland","Portugal","Monaco","Norway","Vatican City","Finland","Bulgaria","Moldova","Estonia","Lithuania","Latvia", "Switzerland","Romania","San Marino","Isle Of Man","Spain","Denmark","Austria","Gibraltar","Bosnia And Herzegovina"},
    NorthAmerica = {"United States","Panama","Canada","Greenland","Jersey","Village of Islands","El Salvador","Mexico",},
    SouthAmerica = {"Belize","Jamaica","Venezuela","Guyana","Equatorial Guinea","Argentina","Brazil","Peru","Ecuador","Honduras","Nicaragua","Bermuda","Bolivia","Cuba","Puerto Rico","Cayman Islands","Chile","Uruguay","Dominican Republic","Costa Rica","French Guiana","Sint Maarten","Mauritius","Saint Lucia","New Caledonia","Paraguay","Guatemala","Barbados","Colombia","French Polynesia",},
    SouthEastAsia = {"Bangladesh","Papua New Guinea","Myanmar","Cambodia","Australia","Thailand","Korea","China","Vietnam","New Zealand","Sri Lanka","Guadeloupe","Taiwan","Malaysia","Macau", "Wallis And Futuna","Grenada","Laos","Anguilla","Christmas Island","Pitcairn Islands","Guam","Singapore","Hong Kong","Japan","Philippines","Indonesia" }
  }

  if culture == "arabic" then
    if hash % 3 == 0 then
      return region_countryMap.MiddleEast[((hash*69) % #region_countryMap.MiddleEast) +1 ]
    end
    if hash % 3 == 1 then
      return region_countryMap.CentralAsia[((hash*69) % #region_countryMap.CentralAsia) +1 ]
    end
    if hash % 3 == 2 then
      return region_countryMap.Africa[((hash*69) % #region_countryMap.Africa) +1 ]
    end
  end

  if culture == "western" then 
    if hash % 3 == 0 then
      return region_countryMap.Europe[((hash*69) % #region_countryMap.Europe) +1 ]
    end
    if hash % 3 == 1 then
      return region_countryMap.NorthAmerica[((hash*69) % #region_countryMap.NorthAmerica) +1 ]
    end
    if hash % 3 == 2 then
      return region_countryMap.SouthAmerica[((hash*69) % #region_countryMap.SouthAmerica) +1 ]
    end
  end

  if culture == "asian" then
    if hash % 2 == 0 then
      return region_countryMap.SouthEastAsia[((hash*69) % #region_countryMap.SouthEastAsia) +1 ]
    end
    if hash % 2 == 1 then
      return region_countryMap.CentralAsia[((hash*69) % #region_countryMap.CentralAsia) +1 ]
    end
  end

  if culture == "international" then
    local internationalCityStates = {"Dubai", "Singapore", "Monaco"}
    return internationalCityStates[((hash*69) % #internationalCityStates) +1]
  end
end

local function stringToHash(hashString)
    local totalValue = 0
    for i = 1, string.len(hashString) do
        local c = hashString:sub(i, i)
        totalValue = totalValue + string.byte(c, 1)
    end

    return totalValue
end

-- Preserve the original map/culture-based fictional telephone format. The old
-- random city offset is now keyed by unit ID, stable across redraws/UI reloads.
local mapHash = getDetermenisticHash()
local phoneCulture, phonePrefix
local function phoneNumber(id)
    local culture = Spring.GetGameRulesParam("culture")
    if phonePrefix == nil or culture ~= phoneCulture then
        phoneCulture = culture
        local country = getCountryByCulture()
        phonePrefix = country and ("+0" .. (stringToHash(country) % 170) .. "-") or ""
    end
    local city = mapHash + ((id + mapHash) % 11) - 5
    local subscriber = (id ~= 0 and (9999 % id) or 0) + math.abs(id - 9999)
    return phonePrefix .. city .. "/" .. subscriber
end

function widget:Initialize()
    widgetHandler:RegisterGlobal(widget, "RevealedGraphChanged", receive)
end
function widget:Shutdown()
    widgetHandler:DeregisterGlobal("RevealedGraphChanged")
end

local function line(x1, y1, x2, y2, width, c, alpha)
    gl.LineWidth(width)
    color(c, alpha)
    gl.BeginEnd(GL.LINES, function()
        gl.Vertex(x1, y1); gl.Vertex(x2, y2)
    end)
end
local function arc(x, y, radius, fraction, width, c, alpha)
    gl.LineWidth(width)
    color(c, alpha)
    gl.BeginEnd(GL.LINE_STRIP, function()
        local segments = max(2, math.ceil(48 * fraction))
        for i = 0, segments do
            local a = pi * 0.5 - 2 * pi * fraction * i / segments
            gl.Vertex(x + cos(a) * radius, y + sin(a) * radius)
        end
    end)
end
local dark = {0.015, 0.022, 0.035}
local white = {0.91, 0.96, 1.0}
local secondary = {0.63, 0.73, 0.80}
local function connection(a, b, c, alpha, progress, scale)
    local dx, dy = b.x - a.x, b.y - a.y
    local length = sqrt(dx * dx + dy * dy)
    if length < 40 * scale then return end
    local ux, uy = dx / length, dy / length
    local start = 19 * scale
    local finish = start + (length - 38 * scale) * progress
    local x1, y1 = a.x + ux * start, a.y + uy * start
    local x2, y2 = a.x + ux * finish, a.y + uy * finish
    line(x1, y1, x2, y2, 6 * scale, dark, alpha * 0.7)
    line(x1, y1, x2, y2, 4 * scale, c, alpha * 0.12)
    line(x1, y1, x2, y2, 1.5 * scale, c, alpha * 0.9)
    if progress >= 0.99 then
        local size = 7 * scale
        line(x2, y2, x2 - ux * size - uy * size * 0.55,
            y2 - uy * size + ux * size * 0.55, 1.7 * scale, c, alpha)
        line(x2, y2, x2 - ux * size + uy * size * 0.55,
            y2 - uy * size - ux * size * 0.55, 1.7 * scale, c, alpha)
    end
end

-- Convex polygon pieces, in marker-local coordinates. No font glyphs or assets.
local chessShapes = {
    pawn = {
        {-3,5, -2,8, 2,8, 3,5, 2,2, -2,2},
        {-2,1, 2,1, 4,-6, -4,-6},
    },
    king = {
        {-4,-6, 4,-6, 2,1, -2,1}, {-4,1, 4,1, 5,4, -5,4},
        {-1,4, 1,4, 1,10, -1,10}, {-3,6, 3,6, 3,8, -3,8},
    },
    queen = {
        {-4,-6, 4,-6, 3,1, -3,1}, {-4,1, 4,1, 5,4, -5,4},
        {-5,3, -6,9, -2,4}, {-2,3, 0,10, 2,3}, {2,4, 6,9, 5,3},
    },
    rook = {
        {-4,-6, 4,-6, 3,4, -3,4}, {-5,3, 5,3, 5,6, -5,6},
        {-5,6, -3,6, -3,9, -5,9}, {-1,6, 1,6, 1,9, -1,9},
        {3,6, 5,6, 5,9, 3,9},
    },
    bishop = {
        {-4,-6, 4,-6, 2,0, -2,0}, {-4,0, 4,0, 3,2, -3,2},
        {-3,3, 0,2, 3,4, 3,6, 0,10, -3,6},
    },
    knight = {
        {-5,-6, 5,-6, 5,2, 1,4, -2,0},
        {-2,0, -6,2, -6,4, 0,9, 4,7, 5,2}, {0,8, 1,11, 3,8},
    },
}
local function polygon(x, y, s, points)
    gl.BeginEnd(GL.TRIANGLE_FAN, function()
        for i = 1, #points, 2 do
            gl.Vertex(x + points[i]*s, y + points[i+1]*s)
        end
    end)
end
local function chessRole(defID)
    local ud = UnitDefs[defID]
    local name = ud and (ud.name or ""):lower() or ""
    if name == "operativepropagator" then return "king" end
    if name == "operativeinvestigator" then return "queen" end
    if name == "operativeasset" then return "bishop" end
    if name:find("safehouse", 1, true) then return "rook" end
    -- Armed civilian-derived units must be checked before ordinary civilians.
    if name == "civilianagent" then return "pawn" end
    if name == "civilian_suicidebomber" or name:match("^civilian_truck_")
        or name:match("^ground_") or name:match("^air_")
        or name:match("^satellite") or name == "nimrod" or name == "noone" or name == "policetruck" then return "knight" end
    if name:match("^civilian") then return "pawn" end
    -- Unknown/support types retain a neutral symbol rather than a false role.
    return nil
end
local function icon(x, y, piece, c, alpha, s)
    color(c, alpha)
    if not piece then
        gl.LineWidth(1.5*s)
        gl.BeginEnd(GL.LINE_LOOP, function()
            gl.Vertex(x, y+7*s); gl.Vertex(x+6*s, y)
            gl.Vertex(x, y-7*s); gl.Vertex(x-6*s, y)
        end)
        return
    end
    for _, shape in ipairs(chessShapes[piece]) do polygon(x, y, s, shape) end
    gl.Rect(x-6*s, y-9*s, x+6*s, y-7*s)
    if piece == "bishop" then
        line(x, y+4*s, x+3*s, y+7*s, 1.4*s, dark, alpha)
    elseif piece == "knight" then
        color(dark, alpha); gl.Rect(x-s, y+5*s, x+s, y+6.5*s)
    end
end

local function project(p, lift)
    local x, y, z = Spring.WorldToScreenCoords(p.x, p.y + lift, p.z)
    if not x or not z or z < 0 or z > 1 then return end
    return {x = x, y = y}
end
local function isBuilding(defID)
    local ud = UnitDefs[defID]
    return ud and (ud.isBuilding or ud.isFactory or ud.speed == 0) or false
end
local function displayName(value)
    -- Strip Spring text-color escapes and controls from producer-provided names.
    return tostring(value or "UNKNOWN"):gsub("\255...", ""):gsub("[%c]", " "):upper()
end
local function groupsForFrame()
    local frame, groups, alive = Spring.GetGameFrame(), {}, {}
    for _, loc in pairs(locations) do
        if validPosition(loc) and type(loc.endFrame) == "number"
            and loc.endFrame > frame and loc.teamID and type(loc.revealedUnits) == "table" then
            local key = sourceKey(loc)
            alive[key] = true
            local state = appearances[key]
            if not state then
                state = {first = frame, duration = max(1, loc.endFrame - frame)}
                appearances[key] = state
            end
            local group = {loc = loc, key = key, nodes = {}, remaining = loc.endFrame - frame,
                age = max(0, frame - state.first), duration = state.duration}
            for id, data in pairs(loc.revealedUnits) do
                if type(id) == "number" and type(data) == "table" and validPosition(data.pos)
                    and not Spring.GetUnitIsDead(id) then
                    group.nodes[#group.nodes + 1] = {id = id, data = data}
                end
            end
            table.sort(group.nodes, function(a, b) return a.id < b.id end)
            groups[#groups + 1] = group
        end
    end
    for key in pairs(appearances) do if not alive[key] then appearances[key] = nil end end
    table.sort(groups, function(a, b) return a.key < b.key end)
    return groups
end

local function overlap(a, b, gap)
    return a.x < b.x+b.w+gap and a.x+a.w+gap > b.x
        and a.y < b.y+b.h+gap and a.y+a.h+gap > b.y
end
local function placeCard(node, occupied, sw, sh, s)
    local w, h, gap = 230*s, 62*s, 6*s
    local bx, by = node.screen.x + 24*s, node.screen.y - h*0.5
    local best, bestScore
    for side = 1, 2 do
        for step = 0, 8 do
            local offset = math.ceil(step/2) * (h+gap) * (step%2 == 0 and 1 or -1)
            local box = {x = clamp(side == 1 and bx or node.screen.x-24*s-w, gap, max(gap, sw-w-gap)),
                y = clamp(by+offset, gap, max(gap, sh-h-gap)), w = w, h = h}
            local score = math.abs(offset) + (side-1)*10*s
            for _, other in ipairs(occupied) do
                if overlap(box, other, gap) then score = score + 10000 end
            end
            if not bestScore or score < bestScore then best, bestScore = box, score end
        end
    end
    occupied[#occupied+1] = best
    return best
end
local function fitText(text, size, width)
    if gl.GetTextWidth(text)*size <= width then return text end
    while #text > 0 and gl.GetTextWidth(text .. "...")*size > width do
        text = text:sub(1, -2)
    end
    return text .. "..."
end

function widget:DrawScreen()
    if Spring.IsGUIHidden and Spring.IsGUIHidden() then return end
    local sw, sh = gl.GetViewSizes()
    local s = clamp(sh/1080, 0.8, 1.4)
    local mx, my = Spring.GetMouseState()
    local cards, occupied = {}, {}
    gl.DepthTest(false)
    gl.Blending(GL.SRC_ALPHA, GL.ONE_MINUS_SRC_ALPHA)
    for _, group in ipairs(groupsForFrame()) do
        local loc = group.loc
        local origin = project(loc, 70)
        local alpha = min(1, group.age/9) * min(1, group.remaining/30)
        local function addNode(pos, screen, c, role, name, building, source, id, defID)
            if not screen or screen.x < -20 or screen.x > sw+20 or screen.y < -20 or screen.y > sh+20 then return end
            local node = {screen = screen, base = project(pos, 3), c = c, role = role,
                name = displayName(name), building = building, source = source,
                alpha = alpha, group = group, pos = pos, id = id,
                piece = chessRole(defID), phone = id and phoneNumber(id)}
            node.box = placeCard(node, occupied, sw, sh, s)
            cards[#cards+1] = node
        end
        if origin then
            addNode(loc, origin, sourceColor, "SOURCE", "REVEALED LOCATION", false, true)
        end
        for _, entry in ipairs(group.nodes) do
            local data = entry.data
            local target = project(data.pos, 70)
            local building = isBuilding(data.defID)
            local c = data.boolIsParent and parentColor or childColor
            if origin and target then
                local progress = clamp(group.age/21, 0, 1)
                if data.boolIsParent then
                    connection(target, origin, c, alpha, progress, s)
                else
                    connection(origin, target, c, alpha, progress, s)
                end
            end
            addNode(data.pos, target, c, data.boolIsParent and "RECRUITER" or
                (building and "BUILT" or "RECRUITED"), data.name, building, false, entry.id, data.defID)
        end
    end
    for _, node in ipairs(cards) do
        local p, b, c, a = node.screen, node.box, node.c, node.alpha
        if node.base then
            line(p.x, p.y-17*s, node.base.x, node.base.y, s, c, a*0.45)
            arc(node.base.x, node.base.y, 5*s, 1, s, c, a*0.65)
        end
        line(p.x, p.y, clamp(p.x, b.x, b.x+b.w), clamp(p.y, b.y, b.y+b.h), s, c, a*0.4)
        arc(p.x, p.y, 16*s, 1, 5*s, dark, a*0.9)
        arc(p.x, p.y, 16*s, 1, 1.5*s, c, a)
        if node.source then
            -- The source payload identifies a location, not a unit type.
            arc(p.x, p.y, 5*s, 1, 2*s, c, a)
        else
            icon(p.x, p.y, node.piece, c, a, s)
        end
        if node.source then
            arc(p.x, p.y, 21*s, clamp(node.group.remaining/node.group.duration, 0, 1), 3*s, c, a)
        end
        color(dark, a*0.88); gl.Rect(b.x, b.y, b.x+b.w, b.y+b.h)
        color(c, a); gl.Rect(b.x, b.y+4*s, b.x+3*s, b.y+b.h-4*s)
        color(white, a)
        gl.Text(node.role, b.x+11*s, b.y+44*s, 12*s, "o")
        color(secondary, a)
        gl.Text(fitText(node.name, 10*s, b.w-20*s), b.x+11*s, b.y+28*s, 10*s, "o")
        color(c, a*0.9)
        local detail = node.phone and ("TEL " .. node.phone) or
            string.format("POS %d / %d", node.pos.x, node.pos.z)
        gl.Text(fitText(detail, 10*s, b.w-20*s), b.x+11*s, b.y+11*s, 10*s, "o")
        if node.source then
            color(c, a)
            gl.Text(math.ceil(node.group.remaining/30).." s", b.x+b.w-9*s, b.y+44*s, 11*s, "or")
        end
        if mx and mx >= b.x and mx <= b.x+b.w and my >= b.y and my <= b.y+b.h then
            color(white, a)
            local detail = node.name .. (node.id and ("  ID " .. node.id) or "")
            if node.piece then detail = detail .. "  " .. node.piece:upper() end
            gl.Text(detail, b.x, b.y+b.h+23*s, 12*s, "o")
            gl.Text((node.phone and ("TEL " .. node.phone .. "  ") or "") ..
                string.format("POS %d / %d / %d", node.pos.x, node.pos.y, node.pos.z),
                b.x, b.y+b.h+7*s, 10*s, "o")
        end
    end
    gl.LineWidth(1)
    gl.Color(1, 1, 1, 1)
end

