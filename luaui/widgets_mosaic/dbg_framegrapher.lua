-- Frame intervals are wall-clock measurements, not CPU/GPU or call-stack profiles.
-- Do not infer sim/update/swap durations from LuaUI callback ordering: MOSAIC does
-- not dispatch GameFramePost, and rendering and simulation need not run 1:1.

function widget:GetInfo()
	return {
		name = "Frame Grapher",
		desc = "Frame-time history with mean, p95, peak and a 40 ms / 25 FPS target",
		author = "Beherith, MOSAIC contributors",
		license = "GNU GPL, v2 or later",
		layer = -200001,
		hidden = false,
		enabled = false,
	}
end

local HISTORY_SIZE = 512
local TARGET_MS = 40
local STATS_INTERVAL_MS = 500
local GetTimer = Spring.GetTimer
local DiffTimers = Spring.DiffTimers
local ceil, min, max = math.ceil, math.min, math.max

local samples, sorted = {}, {}
local count, head = 0, 0
local previousTimer
local statsElapsed, peakMS = 0, 0
local statsText = "Waiting for two rendered frames..."
local detailText = ""
local viewX, viewY = 0, 0
local ready = false

local function UpdateStats()
	local total = 0
	for i = 1, count do
		sorted[i] = samples[i]
		total = total + samples[i]
	end

	table.sort(sorted)
	peakMS = sorted[count]
	local mean = total / count
	statsText = string.format("Mean %.1f ms (%.1f FPS)", mean, 1000 / mean)
	detailText = string.format("p95 %.1f ms  |  peak %.1f ms  |  %d frames",
		sorted[ceil(count * 0.95)], peakMS, count)
	statsElapsed = 0
end

local function Sample(now)
	if previousTimer then
		-- DiffTimers returns seconds by default; use matching GetTimer handles.
		local elapsed = DiffTimers(now, previousTimer) * 1000
		if elapsed > 0 and elapsed < math.huge then
			head = head % HISTORY_SIZE + 1
			samples[head] = elapsed
			count = min(count + 1, HISTORY_SIZE)
			statsElapsed = statsElapsed + elapsed
			-- Refresh immediately for new peaks: startup stalls must stay visible.
			if count == 1 or statsElapsed >= STATS_INTERVAL_MS or elapsed > peakMS then
				UpdateStats()
			end
		end
	end
	previousTimer = now
end

local function DrawBars(left, bottom, width, height, scaleMS)
	local step = width / HISTORY_SIZE
	local gap = step >= 2 and 0.5 or 0
	for i = 1, count do
		local index = (head - count + i - 1) % HISTORY_SIZE + 1
		local elapsed = samples[index]
		local x = left + (HISTORY_SIZE - count + i - 1) * step
		local top = bottom + elapsed / scaleMS * height
		if elapsed <= TARGET_MS then
			gl.Color(0.25, 0.85, 0.45, 0.9)
		elseif elapsed <= 2 * TARGET_MS then
			gl.Color(1, 0.7, 0.2, 0.9)
		else
			gl.Color(1, 0.3, 0.25, 0.9)
		end
		gl.Vertex(x, bottom)
		gl.Vertex(x + step - gap, bottom)
		gl.Vertex(x + step - gap, top)
		gl.Vertex(x, top)
	end
end

function widget:ViewResize(vsx, vsy)
	viewX, viewY = vsx, vsy
end

function widget:Initialize()
	if not GetTimer or not DiffTimers then
		Spring.Echo("Frame Grapher: engine timer API unavailable")
		widgetHandler:RemoveWidget(self)
		return
	end
	viewX, viewY = Spring.GetViewGeometry()
	ready = true
end

function widget:DrawScreen()
	if not ready then return end
	if Spring.IsGUIHidden() or viewX < 360 or viewY < 256 then
		-- Do not turn time spent with the graph hidden into a fake long frame.
		previousTimer = nil
		return
	end
	Sample(GetTimer())

	local width = min(640, viewX - 32)
	local left, bottom = viewX - width - 16, 40
	local graphLeft, graphBottom = left + 12, bottom + 28
	local graphWidth, graphHeight = width - 24, 100
	local scaleMS = max(100, ceil(peakMS / 20) * 20)

	gl.Texture(false)
	gl.DepthTest(false)
	gl.Blending(GL.SRC_ALPHA, GL.ONE_MINUS_SRC_ALPHA)
	gl.Color(0.04, 0.05, 0.07, 0.88)
	gl.Rect(left, bottom, left + width, bottom + 206)
	gl.BeginEnd(GL.QUADS, DrawBars, graphLeft, graphBottom, graphWidth, graphHeight, scaleMS)

	local targetY = graphBottom + TARGET_MS / scaleMS * graphHeight
	gl.Color(0.7, 0.85, 1, 0.85)
	gl.Rect(graphLeft, targetY, graphLeft + graphWidth, targetY + 1)
	gl.Color(1, 1, 1, 1)
	gl.Text("Frame Grapher - frame intervals", graphLeft, bottom + 184, 14, "o")
	gl.Text(statsText, graphLeft, bottom + 164, 12, "o")
	gl.Text(detailText, graphLeft, bottom + 146, 11, "o")
	gl.Text(string.format("Target 40 ms / 25 FPS  |  scale 0-%.0f ms", scaleMS),
		graphLeft, bottom + 10, 11, "o")
	gl.Color(1, 1, 1, 1)
end
