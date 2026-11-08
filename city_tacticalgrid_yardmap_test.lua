-- The old tactical grid must remain discoverable without painting over city roads.
local env = setmetatable({
    widget={}, VFS={FileExists=function(path)
        assert(path=='scripts/lib_city_roads.lua');return true
    end},
}, {__index=_G})
env._G=env
setfenv(assert(loadfile('luaui/widgets_mosaic/gui_tacticalgrid.lua')),env)()
assert(type(env.widget.GetInfo)=='function','legacy grid must provide metadata')
local info=env.widget:GetInfo()
assert(info.enabled==false,'city roads must own grid rendering')
assert(env.widget.DrawWorld==nil and env.widget.DrawScreen==nil,'legacy grid must not draw')
local source=assert(io.open('units/neutral/House_arab.lua','rb')):read('*a')
local cells=assert(source:match('YardMap%s*=%s*%[%[(.-)%]%]')):gsub('%s+','')
assert(#cells==36 and not cells:find('[^y]'),'house_arab0 yardmap must match FootprintX/Z 6')
print('PASS city roads legacy handoff and 6x6 Arab house yardmap')
