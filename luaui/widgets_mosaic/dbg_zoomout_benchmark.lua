function widget:GetInfo()
    return {name="Mosaic Zoom-out Benchmark", desc="Run /luaui zoomoutbench from the slow camera", author="Mosaic contributors", layer=100000, enabled=true}
end

local sequence = {"baseline", "no_holograms", "no_shadows", "restored"}
local gate = "MosaicBenchmarkHideHolograms"
local suite
local function log(s) Spring.Echo("[ZoomoutBench] "..s) end

local function restore(s)
    if s.gated then widgetHandler:DeregisterGlobal(gate); s.gated=false end
    if s.changedShadows then
        Spring.SendCommands("shadows "..s.shadows)
        s.changedShadows=false
    end
end

local function finish(reason)
    local s=suite
    if not s then return end
    suite=nil
    restore(s)
    if s.file then
        local ok,err=s.file:close()
        if not ok then log("CSV close failed: "..tostring(err));s.file=nil end
    end
    log(reason..(s.file and ("; results: "..s.path) or "; see infolog.txt"))
end

local function append(s,line)
    if not s.file then return end
    local ok=s.file:write(line.."\n") and s.file:flush()
    if not ok then s.file:close(); s.file=nil; log("CSV write failed; continuing in infolog.txt") end
end

local function phase(s)
    restore(s)
    s.index=s.index+1
    local name=sequence[s.index]
    if not name then finish("Complete"); return end
    if name=="no_shadows" then
        if s.shadows<=0 then
            log("Skipping no_shadows: shadows were already off")
            append(s,"no_shadows,already_off")
            return phase(s)
        end
        s.changedShadows=true
        Spring.SendCommands("shadows 0")
    elseif name=="no_holograms" then
        if not widgetHandler:RegisterGlobal(gate,function() return true end) then
            finish("Hologram gate unavailable; aborted"); return
        end
        s.gated=true
    end
    s.frames={}; s.sum=0; s.last=nil; s.start=Spring.GetTimer()
    log(string.format("%d/%d %s: warming up for 3 s, then sampling for 30 s",s.index,#sequence,name))
end

function widget:TextCommand(cmd)
    if cmd=="zoomoutbench cancel" then finish("Cancelled"); return true end
    if cmd~="zoomoutbench" then return false end
    if suite then log("Already running"); return true end
    local s={index=0, shadows=Spring.GetConfigInt("Shadows",0)}
    suite=s
    local ok,err=pcall(function()
        Spring.CreateDir("MosaicPerf")
        s.path=string.format("MosaicPerf/zoomout_suite_%s_%d.csv",os.date("%Y%m%d_%H%M%S"),Spring.GetDrawFrame())
        s.file=assert(io.open(s.path,"w"))
    end)
    if not ok then log("CSV unavailable: "..tostring(err)) end
    append(s,"phase,status,intervals,seconds,fps,mean_ms,p50_ms,p95_ms,p99_ms,max_ms,start_game_frame,end_game_frame,shadow_mode")
    phase(s)
    return true
end

function widget:DrawScreenPost()
    local s=suite
    if not s then return end
    local frame=Spring.GetDrawFrame()
    if frame==s.draw then return end
    s.draw=frame
    local now=Spring.GetTimer()
    if not s.last then
        if Spring.DiffTimers(now,s.start)<3 then return end
        s.mode=Spring.GetConfigInt("Shadows",0)
        local expected=sequence[s.index]=="no_shadows" and 0 or s.shadows
        if s.mode~=expected then finish("Unexpected shadow mode "..s.mode.."; aborted");return end
        s.firstGameFrame=Spring.GetGameFrame()
        s.last=now;return
    end
    local dt=Spring.DiffTimers(now,s.last)*1000
    s.last=now
    if dt<=0 then return end
    local a=s.frames
    a[#a+1]=dt; s.sum=s.sum+dt
    if s.sum<30000 then return end
    table.sort(a)
    local n=#a
    local function q(p) return a[math.ceil(n*p)] end
    local mean=s.sum/n
    local line=string.format("%s,ok,%d,%.3f,%.2f,%.2f,%.2f,%.2f,%.2f,%.2f,%d,%d,%d",
        sequence[s.index],n,s.sum/1000,1000/mean,mean,q(.5),q(.95),q(.99),a[n],s.firstGameFrame,Spring.GetGameFrame(),s.mode)
    append(s,line)
    log(string.format("%s: %.2f FPS, %.2f ms mean, %.2f ms p95",sequence[s.index],1000/mean,mean,q(.95)))
    phase(s)
end

function widget:Shutdown() finish("Stopped on widget shutdown") end
