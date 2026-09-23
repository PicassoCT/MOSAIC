function widget:GetInfo()
    return {name='Mosaic Performance Capture', desc='Opt-in frame pacing and LuaUI call-in capture',
        author='Mosaic contributors', layer=100000, handler=true, enabled=false}
end

local run, serial = nil, 0
local hooks, effects = {}, {}
local allowed = {clouds=true, smoke=true, holograms=true}
local timer, diff = Spring.GetTimer, Spring.DiffTimers
local function echo(s) Spring.Echo('[MosaicPerf] '..s) end
local function enabled(name) return effects[name] ~= false end
local function clean(s) return tostring(s):gsub('[\r\n,]', ' ') end
local function restore()
    for _,h in ipairs(hooks) do
        if h.owner[h.name] == h.wrapper then h.owner[h.name] = h.original end
    end
    hooks = {}
end
local function metadata()
    local out = {}
    local function add(k,v) out[#out+1] = clean(k)..'='..clean(v) end
    add('engine', Engine and Engine.version or 'unknown')
    add('game', Game.gameVersion or Game.modName or 'unknown'); add('map',Game.mapName)
    add('game_frame', Spring.GetGameFrame())
    if Spring.GetVisibleUnits then add('visible_non_icon_units',#(Spring.GetVisibleUnits(-1,nil,false) or {})) end
    if Spring.GetAllUnits then add('accessible_units',#(Spring.GetAllUnits() or {})) end
    local sx,sy = Spring.GetViewGeometry(); add('viewport',tostring(sx)..'x'..tostring(sy))
    if Spring.GetGameSpeed then
        local wanted,actual,paused=Spring.GetGameSpeed()
        add('speed_wanted',wanted);add('speed_actual',actual);add('paused',paused)
    end
    for k,v in pairs(Spring.GetCameraState() or {}) do
        if type(v)~='table' then add('camera_'..k,v) end
    end
    for _,k in ipairs({'gpu','gpuVendor','glVersion','cpu','osFamily'}) do
        if Platform and Platform[k] then add(k,Platform[k]) end
    end
    for _,k in ipairs({'VSync','Shadows','ShadowMapSize','MSAALevel','AllowDeferredMapRendering','AllowDeferredModelRendering'}) do
        if Spring.GetConfigInt then add(k,Spring.GetConfigInt(k,-1)) end
    end
    for k in pairs(allowed) do add('effect_'..k, enabled(k)) end
    for _,w in ipairs(widgetHandler.widgets) do add('widget', w.whInfo.name) end
    table.sort(out)
    return out
end
local function install(r)
    -- Snapshot of currently registered call-ins. No handler dispatch replacement.
    local seen = {}
    for listName,list in pairs(widgetHandler) do
        local name=type(listName)=='string' and listName:match('^(.-)List$')
        if name and type(list)=='table' and name~='Shutdown' and name~='Initialize' then
            for _,w in ipairs(list) do
                seen[w]=seen[w] or {}
                if w~=widget and not seen[w][name] and type(w[name])=='function' then
                    seen[w][name]=true
                    local original=w[name]
                    local stat={widget=w.whInfo.name,callin=name,calls=0,total=0,max=0}
                    r.stats[#r.stats+1]=stat
                    local function finish(t,...)
                        local ms=diff(timer(),t)*1000
                        stat.calls=stat.calls+1;stat.total=stat.total+ms;stat.max=math.max(stat.max,ms)
                        return ...
                    end
                    local function wrapper(...)
                        if run~=r or not r.collecting then return original(...) end
                        local t=timer()
                        return finish(t,original(...))
                    end
                    hooks[#hooks+1]={owner=w,name=name,original=original,wrapper=wrapper}
                    w[name]=wrapper
                end
            end
        end
    end
end
local function stop(reason)
    local r=run
    if not r then return end
    run=nil;restore()
    if #r.frames==0 then echo('No complete frame intervals captured ('..reason..').');return end
    local sorted={}
    for i,v in ipairs(r.frames) do sorted[i]=v end
    table.sort(sorted)
    local function percentile(p) return sorted[math.max(1,math.ceil(#sorted*p))] end
    local avg=r.total/#r.frames
    local summary=string.format('%s: %.2f FPS; mean %.2f ms; p50 %.2f; p95 %.2f; p99 %.2f; max %.2f; %d intervals (%s)',
        r.label,1000/avg,avg,percentile(.5),percentile(.95),percentile(.99),sorted[#sorted],#sorted,reason)
    echo(summary)
    table.sort(r.stats,function(a,b) return a.total>b.total end)
    for i=1,math.min(12,#r.stats) do
        local s=r.stats[i]
        if s.calls>0 then echo(string.format('LuaUI %s:%s %.3f ms/frame; %.3f ms/call; max %.3f ms; %d calls',
            s.widget,s.callin,s.total/#r.frames,s.total/s.calls,s.max,s.calls)) end
    end
    local lines={'# '..summary,'# Lua timings are inclusive CPU/driver wall time, NOT GPU time.'}
    for _,v in ipairs(r.meta) do lines[#lines+1]='# start '..v end
    for _,v in ipairs(metadata()) do lines[#lines+1]='# end '..v end
    lines[#lines+1]='frame_interval,ms'
    for i,v in ipairs(r.frames) do lines[#lines+1]=string.format('%d,%.6f',i,v) end
    lines[#lines+1]='widget,callin,calls,total_ms,ms_per_frame,max_call_ms'
    for _,s in ipairs(r.stats) do
        lines[#lines+1]=string.format('%s,%s,%d,%.6f,%.6f,%.6f',clean(s.widget),s.callin,s.calls,s.total,s.total/#r.frames,s.max)
    end
    local ok,err=pcall(function()
        Spring.CreateDir('MosaicPerf')
        local path='MosaicPerf/'..r.label..'_'..os.date('%Y%m%d_%H%M%S')..'_'..serial..'.csv'
        local f=assert(io.open(path,'w'))
        local written,why=f:write(table.concat(lines,'\n')..'\n');f:close()
        assert(written,why);echo('Saved '..path)
    end)
    if not ok then echo('CSV unavailable: '..tostring(err)..'; summary retained in infolog.txt') end
end
function widget:Initialize()
    widgetHandler:RegisterGlobal(self,'MosaicPerfDrawEnabled',enabled)
    echo('Ready: /mosaicperf start 30 zoomout [lua]; /mosaicperf effect clouds|smoke|holograms on|off; /mosaicperf reset')
end
function widget:TextCommand(command)
    if not command:match('^mosaicperf%s') and command~='mosaicperf' then return false end
    local seconds,label,mode=command:match('^mosaicperf start (%d+) ([%w_-]+)%s*(%w*)$')
    if seconds and (mode=='' or mode=='lua') then
        if run then echo('Capture already running; use /mosaicperf stop first.');return true end
        for _,w in ipairs(widgetHandler.widgets) do
            if w.whInfo.name=='Widget Profiler' then echo('Disable Widget Profiler before capturing.');return true end
        end
        serial=serial+1
        run={seconds=math.max(5,math.min(120,tonumber(seconds))),label=label:sub(1,64),mode=mode,
            start=timer(),frames={},stats={},total=0,meta=metadata()}
        if mode=='lua' then install(run) end
        echo('3-second warmup, then '..run.seconds..' seconds: '..run.label..' ('..(mode=='' and 'frame pacing only' or 'LuaUI timing')..')')
        return true
    end
    if command=='mosaicperf stop' then stop('manual');return true end
    if command=='mosaicperf reset' then stop('reset');effects={};echo('All diagnostic effect gates restored.');return true end
    local effect,state=command:match('^mosaicperf effect (%w+) (o[nf]+)$')
    if allowed[effect] and (state=='on' or state=='off') then
        if run then echo('Stop capture before changing an effect.');return true end
        effects[effect]=state=='on';echo(effect..' '..state..' (local draw only)');return true
    end
    echo('Usage: /mosaicperf start 30 label [lua] | stop | reset | effect clouds|smoke|holograms on|off')
    return true
end
function widget:DrawScreenPost()
    local r=run
    if not r then return end
    local now=timer()
    if diff(now,r.start)<3 then return end
    local frame=Spring.GetDrawFrame()
    if frame==r.lastFrame then return end
    r.lastFrame=frame
    if r.last then
        local ms=diff(now,r.last)*1000
        if ms>0 then r.frames[#r.frames+1]=ms;r.total=r.total+ms end
    end
    r.last=now;r.collecting=true
    if r.total>=r.seconds*1000 or #r.frames>=120000 then stop('complete') end
end
function widget:Shutdown()
    stop('widget shutdown');restore();effects={}
    widgetHandler:DeregisterGlobal(self,'MosaicPerfDrawEnabled')
end
