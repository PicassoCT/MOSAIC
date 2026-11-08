-- Run from the repository root: texlua tests/frame_grapher.lua (or Lua 5.2+).
local f = assert(io.open("luaui/widgets_mosaic/dbg_framegrapher.lua"))
local source = f:read("*a")
f:close()

local clock, hidden, vertices, texts = 0, false, {}, {}
local removed, timerCalls = false, 0
local viewX, viewY = 1280, 720
local function noop() end
local env = setmetatable({
	widget = {},
	Spring = {
		GetTimer = function() timerCalls = timerCalls + 1; return clock end,
		DiffTimers = function(a, b) return a - b end,
		GetViewGeometry = function() return viewX, viewY end,
		IsGUIHidden = function() return hidden end,
		Echo = noop,
	},
	gl = { -- Deliberately no LuaShader, InstanceVBOTable, or GetTimerMicros.
		Texture = noop, DepthTest = noop, Blending = noop, Color = noop,
		Rect = function(x1, y1, x2, y2)
			assert(x1 >= 0 and x2 <= viewX and y1 >= 0 and y2 <= viewY)
		end,
		Text = function(text) texts[#texts + 1] = text end,
		BeginEnd = function(_, draw, ...) draw(...) end,
		Vertex = function(x, y)
			assert(x >= 0 and x <= viewX and y >= 0 and y <= viewY)
			vertices[#vertices + 1] = {x, y}
		end,
	},
	GL = {QUADS = 1, SRC_ALPHA = 2, ONE_MINUS_SRC_ALPHA = 3},
	widgetHandler = {RemoveWidget = function() removed = true end},
}, {__index = _G})

assert(load(source, "frame grapher", "t", env))()
local widget = env.widget
assert(widget:GetInfo().enabled == false and not widget:GetInfo().hidden)
assert(timerCalls == 0, "discovery must not start recording or allocate GPU resources")
widget:Initialize()
assert(not removed)

local function draw(delta)
	clock = clock + (delta or 0)
	vertices, texts = {}, {}
	widget:DrawScreen()
	return table.concat(texts, "\n")
end

assert(draw(5):find("Waiting"), "startup before first render is not a frame")
local text = draw(0.04)
assert(text:find("Mean 40.0 ms %(25.0 FPS%)"), "timer unit conversion or mean is wrong")
assert(#vertices == 4)
text = draw(0.75)
assert(text:find("peak 750.0 ms"), "long stalls must not disappear")
assert(text:find("p95 750.0 ms"))
assert(text:find("Mean 395.0 ms %(2.5 FPS%)"), "average FPS must use total elapsed time")
assert(#vertices == 8 and vertices[7][2] > vertices[3][2], "spike height must exceed normal frame")

-- Mixed durations, including ring wraparound: stats and bars describe the same
-- most recent frames; the original shader silently discarded >200 ms frames.
for i = 1, 1024 do draw(i % 2 == 0 and 0.08 or 0.04) end
text = draw(0.08) -- force a stats refresh below without inserting another spike
for i = 1, 7 do text = draw(0.08) end
assert(#vertices == 512 * 4, "history must be bounded")
assert(text:find("p95 80.0 ms") and text:find("peak 80.0 ms"), "expired spike remained in stats")
local function height(index) return vertices[index + 2][2] - vertices[index][2] end
assert(math.abs(height(1) - 40) < 0.001 and math.abs(height(5) - 80) < 0.001,
	"oldest-to-newest order after wraparound is wrong")
assert(math.abs(height(#vertices - 3) - 80) < 0.001)

local barCount = #vertices
hidden = true
assert(draw(20) == "" and #vertices == 0)
hidden = false
text = draw(20)
assert(#vertices == barCount and not text:find("40000"), "hidden time was recorded as a stall")
text = draw(0.08)
assert(text:find("peak 80.0 ms"))

viewX, viewY = 480, 360
widget:ViewResize(viewX, viewY)
draw(0.04)
viewX, viewY = 360, 256
widget:ViewResize(viewX, viewY)
draw(0.04)
viewX, viewY = 360, 240
widget:ViewResize(viewX, viewY)
assert(draw(5) == "", "graph must not overflow tiny viewports")

-- Missing timers should disable cleanly instead of failing during discovery.
env.widget, env.Spring.GetTimer = {}, nil
assert(load(source, "frame grapher without timers", "t", env))()
env.widget:Initialize()
assert(removed)
env.widget:DrawScreen()
print("PASS: helper-free loading, timer units, long stalls, rolling history, hidden UI and resizing")
