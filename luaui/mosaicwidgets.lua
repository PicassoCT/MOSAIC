-- $Id: widgets.lua 4261 2009-03-31 16:34:36Z licho $
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
--
--  file:    widgets.lua
--  brief:   the widget manager, a call-in router
--  author:  Dave Rodgers
--
--  modified by jK and quantum, merged with BAR-Version by Picasso (who hated every second of that)
--
--  Copyright (C) 2007,2008.
--  Licensed under the terms of the GNU GPL, v2 or later.
--
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
Spring.Echo("widgets.lua::Custom Widgethandler starts loading")

local vfsInclude = VFS.Include
local vfsGame = VFS.GAME
local spSendCommands = Spring.SendCommands

function pwl() -- ???  (print widget list)
  for k,v in ipairs(widgetHandler.widgets) do
      print(k, v.whInfo.layer, v.whInfo.name)
  end
end

function widgetEcho(strings)
  Spring.Echo("widgets.lua::"..strings)
end


Spring.Utilities = {}
widgetEcho("tablefunctions")
VFS.Include("luarules/utilities/tablefunctions.lua")
widgetEcho("versionCompare")
VFS.Include("luarules/utilities/versionCompare.lua")
widgetEcho("loading widgethandlers internals")
local reverseCompat = not Spring.Utilities.IsCurrentVersionNewerThan(100, 0)

if (select == nil) then
  select = function(n,...) 
    local arg = arg
    if (not arg) then arg = {...}; arg.n = #arg end
    return arg[((n=='#') and 'n')or n]
  end
end

assert(LUAUI_DIRNAME)
local ignorelist = {count = 0, ignorees = {} } -- Ignore workaround for WG table.
vfsInclude(LUAUI_DIRNAME.."keysym.lua"    , nil, vfsGame)
vfsInclude(LUAUI_DIRNAME.."utils.lua"    , nil, vfsGame)
vfsInclude(LUAUI_DIRNAME.."system.lua"    , nil, vfsGame)
vfsInclude(LUAUI_DIRNAME.."callins.lua"    , nil, vfsGame)
vfsInclude(LUAUI_DIRNAME.."savetable.lua"    , nil, vfsGame)


local gl = gl
local modShortUpper = Game.modShortName:upper()
local ORDER_FILENAME     = LUAUI_DIRNAME .. 'configs/' .. modShortUpper .. '_order.lua'
local CONFIG_FILENAME    = LUAUI_DIRNAME .. 'configs/' .. modShortUpper .. '_data.lua'
local WIDGET_DIRNAME     = LUAUI_DIRNAME .. 'widgets_mosaic/'
local WIDGET_DIRNAME_MAP = LUAUI_DIRNAME .. 'Widgets_Map/'

local HANDLER_BASENAME = "widgets.lua"
local SELECTOR_BASENAME = 'widget_selector.lua'

local SAFEWRAP = 1
-- 0: disabled
-- 1: enabled, but can be overriden by widget.GetInfo().unsafe
-- 2: always enabled

local SAFEDRAW = false  -- requires SAFEWRAP to work
local glPopAttrib  = gl.PopAttrib
local glPushAttrib = gl.PushAttrib
local pairs = pairs
local ipairs = ipairs

-- read local widgets config
local localWidgetsFirst = false
local localWidgets = false

if VFS.FileExists(CONFIG_FILENAME) then --check config file whether user want to use localWidgetsFirst
  local cadata = VFS.Include(CONFIG_FILENAME)
  if cadata and cadata["Local Widgets Config"] then
    localWidgetsFirst = cadata["Local Widgets Config"].localWidgetsFirst
    localWidgets = cadata["Local Widgets Config"].localWidgets
  end
end

local VFSMODE
VFSMODE = localWidgetsFirst and VFS.RAW_FIRST
VFSMODE = VFSMODE or localWidgets and VFS.ZIP_FIRST
VFSMODE = VFSMODE or VFS.ZIP

local detailLevel = Spring.GetConfigInt("widgetDetailLevel", 3)

--------------------------------------------------------------------------------

-- install bindings for TweakMode and the Widget Selector

Spring.SendCommands({
  "unbindkeyset  Any+f11",
  "unbindkeyset Ctrl+f11",
  "bind    f11  luaui selector",
  "bind  C+f11  luaui tweakgui",
  "echo LuaUI: bound F11 to the widget selector",
  "echo LuaUI: bound CTRL+F11 to tweak mode"
})


--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
--
--  the widgetHandler object
--

local allowuserwidgets = true
if Spring.GetModOptions and (tonumber(Spring.GetModOptions().allowuserwidgets) or 1) == 0 then
  allowuserwidgets = false
end

widgetHandler = {

  widgets = {},

  configData = {},
  orderList = {},

  knownWidgets = {},
  knownCount = 0,
  knownChanged = true,

  commands = {},
  customCommands = {},
  inCommandsChanged = false,
  allowUserWidgets = true,


  actionHandler = include("actions.lua"),
  
  WG = WG or {}, -- shared table for widgets

  globals = {}, -- global vars/funcs

  mouseOwner = nil,
  ownedButton = 0,

  tweakMode = false,

  xViewSize    = 1,
  yViewSize    = 1,
  xViewSizeOld = 1,
  yViewSizeOld = 1,
}


-- these call-ins are set to 'nil' if not used
-- they are setup in UpdateCallIns()
local flexCallIns = {
  'GamePreload',
  'GameStart',
  'GameOver',
  'GameFrame',
  'GameProgress',
  'GameSetup',
  'GamePaused',
  'TeamDied',
  'TeamChanged',
  'PlayerAdded',
  'PlayerRemoved',
  'PlayerChanged',
  'ShockFront',
  'WorldTooltip',
  'MapDrawCmd',
  'GameSetup',
  'DefaultCommand',
  'UnitCreated',
  'UnitFinished',
  'UnitReverseBuilt',
  'UnitFromFactory',
  'UnitDestroyed',
  'UnitDestroyedByTeam',
  'UnitExperience',
  'UnitTaken',
  'UnitGiven',
  'UnitIdle',
  'UnitCommand',
  'UnitCmdDone',
  'UnitDamaged',
  'UnitStunned',
  'UnitEnteredRadar',
  'UnitEnteredLos',
  'UnitLeftRadar',
  'UnitLeftLos',
  'UnitEnteredWater',
  'UnitEnteredAir',
  'UnitLeftWater',
  'UnitLeftAir',
  'UnitSeismicPing',
  'UnitLoaded',
  'UnitUnloaded',
  'UnitCloaked',
  'UnitDecloaked',
  'UnitMoveFailed',
  'RecvLuaMsg',
  'StockpileChanged',
  'SelectionChanged',
  'DrawGenesis',
  'DrawWorld',
  'DrawWorldPreUnit',
  'DrawWorldPreParticles',
  'DrawWorldShadow',
  'DrawWorldReflection',
  'DrawWorldRefraction',
  'DrawUnitsPostDeferred',
  'DrawFeaturesPostDeferred',
  'DrawScreenEffects',
  'DrawScreenPost',
  'DrawInMiniMap',
  'RecvSkirmishAIMessage',
  'SelectionChanged',
  'SunChanged',
  'FeatureCreated',
  'FeatureDestroyed',
  'UnsyncedHeightMapUpdate',
}
local flexCallInMap = {}
for _,ci in ipairs(flexCallIns) do
  flexCallInMap[ci] = true
end

local callInLists = {
  'GamePreload',
  'GameStart',
  'Shutdown',
  'Update',
  'TextCommand',
  'CommandNotify',
  'AddConsoleLine',
  'ViewResize',
  'DrawScreen',
  'KeyPress',
  'KeyRelease',
  'TextInput',
  'MousePress',
  'MouseWheel',
  'JoyAxis',
  'JoyHat',
  'JoyButtonDown',
  'JoyButtonUp',
  'IsAbove',
  'GetTooltip',
  'GroupChanged',
  'GameProgress',
  'CommandsChanged',
  'TweakMousePress',
  'TweakMouseWheel',
  'TweakIsAbove',
  'TweakGetTooltip',
  'GameProgress',
  --'UnsyncedHeightMapUpdate',
-- these use mouseOwner instead of lists
--  'MouseMove',
--  'MouseRelease',
--  'TweakKeyPress',
--  'TweakKeyRelease',
--  'TweakMouseMove',
--  'TweakMouseRelease',

-- uses the DrawScreenList
--  'TweakDrawScreen',
}

-- append the flex call-ins
for _,uci in ipairs(flexCallIns) do
  table.insert(callInLists, uci)
end


-- initialize the call-in lists
do
  for _,listname in ipairs(callInLists) do
    widgetHandler[listname..'List'] = {}
  end
end


--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
--
--  Reverse integer iterator for drawing
--

local function rev_iter(t, key)
  if (key <= 1) then
    return nil
  else
    local nkey = key - 1
    return nkey, t[nkey]
  end
end

local function ripairs(t)
  return rev_iter, t, (1 + #t)
end

-- String helper to split by delimiter (userinfo)

function string:split(delimiter)
  local result = { }
  local from  = 1
  local delim_from, delim_to = string.find( self, delimiter, from  )
  while delim_from do
    table.insert( result, string.sub( self, from , delim_from-1 ) )
    from  = delim_to + 1
    delim_from, delim_to = string.find( self, delimiter, from  )
  end
  table.insert( result, string.sub( self, from  ) )
  return result
end

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------


function widgetHandler:LoadOrderList()
  local chunk, err = loadfile(ORDER_FILENAME)
  if (chunk == nil) then
    self.orderList = {} -- safety
    return {}
  else
    local tmp = {}
    setfenv(chunk, tmp)
    self.orderList = chunk()

    if (not self.orderList) then
      self.orderList = {
        version = 0
      } -- safety
    end

  	if (self.orderList.version or 0) < ORDER_VERSION then 
  		self.orderList = {}
  		self.orderList.version = ORDER_VERSION
  	end 
  	local detailLevel = Spring.GetConfigInt("widgetDetailLevel", 2)
  	if (self.orderList.lastWidgetDetailLevel ~= detailLevel) then
  		resetWidgetDetailLevel = true
  		self.orderList.lastWidgetDetailLevel = detailLevel
  	end 
  end
end


function widgetHandler:SaveOrderList()
  -- update the current order
  for i,w in ipairs(self.widgets) do
    self.orderList[w.whInfo.name] = i
  end
  table.save(self.orderList, ORDER_FILENAME,
             '-- Widget Order List  (0 disables a widget)')
end


--------------------------------------------------------------------------------
function widgetHandler:LoadConfigData()
	local chunk, err = loadfile(CONFIG_FILENAME)
	if (chunk == nil) or (err) then
		if err then
			Spring.Log("widgets.lua", LOG.INFO, err)
		end
	
	return {}
	elseif (chunk() == nil) then
		Spring.Log("widgets.lua", LOG.ERROR, 'Luaui config file was blank')
		return {}
	end
	
		

    local tmp = {}
    setfenv(chunk, tmp)
    self.orderList = chunk().order
    self.configData = chunk().data
    self.allowUserWidgets = chunk().allowUserWidgets
    if (not self.orderList) then
		self.orderList = {} -- safety
		self.orderList.version = ORDER_VERSION
    end
    
     if (not self.configData) then
		self.configData = {} -- safety
     end
  end



function widgetHandler:SaveConfigData()
  self:LoadConfigData()
  local filetable = {}
  for _,w in ipairs(self.widgets) do
    if (w.GetConfigData) then
      local ok, err = pcall(function() 
		self.configData[w.whInfo.name] = w:GetConfigData()
	  end)
	  if not ok then Spring.Log(HANDLER_BASENAME, LOG.ERROR, "Failed to GetConfigData from: " .. w.whInfo.name.." ("..err..")") end 
    end
  self.orderList[w.whInfo.name] = i
  end
  filetable.order = self.orderList
  filetable.data = self.configData
  filetable.allowUserWidgets = self.allowUserWidgets
  table.save(filetable, CONFIG_FILENAME,  '-- Widget Custom data and order, order = 0 disabled widget')
end


function widgetHandler:SendConfigData()
  self:LoadConfigData()
  for _,w in ipairs(self.widgets) do
    local data = self.configData[w.whInfo.name]
    if (w.SetConfigData and data) then
      w:SetConfigData(data)
    end
  end
end


--------------------------------------------------------------------------------

local function GetWidgetInfo(name, mode)

  -- do return end -- FIXME

  local lines = VFS.LoadFile(name, mode)

  local infoLines = {}

  for line in lines:gmatch('([^\n]*)\n') do
    if (not line:find('^%s*%-%-')) then
      if (line:find('[^\r]')) then
        break -- not commented, not a blank line
      end
    end
    local s, e, source = line:find('^%s*%-%-%>%>(.*)')
    if (source) then
      table.insert(infoLines, source)
    end
  end

  local info = {}
  local chunk, err = loadstring(table.concat(infoLines, '\n'))
  if (not chunk) then
    Spring.Echo('not loading ' .. name .. ': ' .. err)
  else
    setfenv(chunk, info)
    local success, err = pcall(chunk)
    if (not success) then
      Spring.Echo('not loading ' .. name .. ': ' .. err)
    end
  end

  for k,v in pairs(info) do
    Spring.Echo(name, k, 'type: ' .. type(v), '<'..tostring(v)..'>')
  end
end


local zipOnly = {
    ["Widget Selector"] = true,
    ["Widget Profiler"] = true,
}



function widgetHandler:Initialize()
	self:LoadConfigData()
	
	-- do we allow userland widgets
	if self.allowUserWidgets==nil then
		self.allowUserWidgets = true
	end
	if self.allowUserWidgets and allowuserwidgets then
		Spring.Echo("LuaUI: Allowing User Widgets")
	else
		Spring.Echo("LuaUI: Disallowing User Widgets")
	end
	
  -- Add ignorelist --
  local customkeys = select(10, Spring.GetPlayerInfo(Spring.GetMyPlayerID()))
  if customkeys and type(customkeys)== "table" and customkeys["ignored"] then
    if string.find(customkeys["ignored"],",") then
      local newignorelist = string.gsub(customkeys["ignored"],","," ")
      Spring.Echo("Setting Serverside ignorelist: " .. newignorelist)
      for ignoree in string.gmatch(newignorelist,"%S+") do
        ignorelist.ignorees[ignoree] = true
        ignorelist.count = ignorelist.count + 1
      end
      newignorelist = nil
    elseif string.len(customkeys["ignored"]) > 1 then
      ignorelist.ignorees[customkeys["ignored"]] = true
      ignorelist.count = ignorelist.count + 1
    end
  end
  
  customkeys = nil
  self:LoadOrderList()
  self:LoadConfigData()

  if self.allowUserWidgets==nil then
    self.allowUserWidgets = true
  end
  if self.allowUserWidgets and allowuserwidgets then
    Spring.Echo("LuaUI: Allowing User Widgets")
  else
    Spring.Echo("LuaUI: Disallowing User Widgets")
  end

  -- create the "luaui/Config" directory
  Spring.CreateDir("LuaUI/" .. 'Config')

  local unsortedWidgets = {}

  -- stuff the widgets into unsortedWidgets
  if self.allowUserWidgets and allowuserwidgets then
     local widgetFiles = VFS.DirList(WIDGET_DIRNAME, "*.lua", VFS.RAW)
    for k,wf in ipairs(widgetFiles) do
      GetWidgetInfo(wf, VFS.RAW)
      local widget = self:LoadWidget(wf, false)
      if (widget) and not zipOnly[widget.whInfo.name] then
        table.insert(unsortedWidgets, widget)
      end
    end
  end
 local widgetFiles = VFS.DirList(WIDGET_DIRNAME, "*.lua", VFS.ZIP)
  for k,wf in ipairs(widgetFiles) do
    GetWidgetInfo(wf, VFS.ZIP)
    local widget = self:LoadWidget(wf, true)
    if (widget) then
      table.insert(unsortedWidgets, widget)
    end
  end

  -- stuff the map widgets into unsortedWidgets
  local widgetFiles = VFS.DirList(WIDGET_DIRNAME_MAP, "*.lua", VFS.MAP)
  for k,wf in ipairs(widgetFiles) do
    GetWidgetInfo(wf, VFS.MAP)
    local widget = self:LoadWidget(wf, true)
    if (widget) then
      table.insert(unsortedWidgets, widget)
    end
  end
  
  -- sort the widgets  
  table.sort(unsortedWidgets, function(w1, w2)
    local l1 = w1.whInfo.layer
    local l2 = w2.whInfo.layer
    if (l1 ~= l2) then
      return (l1 < l2)
    end
    local n1 = w1.whInfo.name
    local n2 = w2.whInfo.name
    local o1 = self.orderList[n1]
    local o2 = self.orderList[n2]
    if (o1 ~= o2) then
      return (o1 < o2)
    else
      return (n1 < n2)
    end
  end)

  -- add the widgets  
  for _,w in ipairs(unsortedWidgets) do
    local name = w.whInfo.name
    local basename = w.whInfo.basename
    local source = self.knownWidgets[name].fromZip and "mod: " or "user:"
    Spring.Echo(string.format("Loading widget from %s  %-18s  <%s> ...", source, name, basename))

    widgetHandler:InsertWidget(w)
  end

  -- save the active widgets, and their ordering
  self:SaveOrderList()
  self:SaveConfigData()
end


function widgetHandler:LoadWidget(filename, fromZip)
  fromZipTrue = "from Zip true"
  if fromZip == false then fromZipTrue = "from Zip false"end

  fromZip = fromZip or VFSMODE

  local basename = Basename(filename) 
  filename = filename:gsub("LuaUI","luaui")
  --Spring.Echo("Trying to load "..filename.." -> with".. fromZipTrue)
    
  local text = VFS.LoadFile(filename, fromZip and VFS.ZIP or VFS.RAW)
  if (text == nil) then
    Spring.Echo('Failed to load: ' .. basename .. '  (missing file: ' .. filename ..')')
    return nil
  end
  local chunk, err = loadstring(text, filename)
  if (chunk == nil) then
    Spring.Echo('Failed to load: ' .. basename .. '  (' .. err .. ')')
    return nil
  end
  
  local widget = widgetHandler:NewWidget()
  setfenv(chunk, widget)
  local success, err = pcall(chunk)
  if (not success) then
    Spring.Echo('Failed to load: ' .. basename .. '  (' .. err .. ')')
    return nil
  end
  if (err == false) then
    return nil -- widget asked for a silent death
  end

  -- raw access to widgetHandler
  if (widget.GetInfo and widget:GetInfo().handler) then
    widget.widgetHandler = self
  end

 -- Spring.Echo("Finalizing Widget: "..filename)
  self:FinalizeWidget(widget, filename, basename)
  local name = widget.whInfo.name
  if (basename == SELECTOR_BASENAME) then
    self.orderList[name] = 1  -- always load the widget selector
  end

  --Spring.Echo("ValidateWidget : "..basename)
  err = self:ValidateWidget(widget)
  if (err) then
    Spring.Echo(' Failed to load: ' .. basename .. '  (' .. err .. ')')
    return nil
  end

  local knownInfo = self.knownWidgets[name]
  if (knownInfo) then
    if (knownInfo.active) then
      Spring.Log(HANDLER_BASENAME, LOG.ERROR, 'Failed to load: ' .. basename .. '  (duplicate name)')
      return nil
    end
  else
    -- create a knownInfo table
    knownInfo = {}
    knownInfo.desc     = widget.whInfo.desc
    knownInfo.author   = widget.whInfo.author
    knownInfo.basename = widget.whInfo.basename
    knownInfo.filename = widget.whInfo.filename
    knownInfo.fromZip  = fromZip
    self.knownWidgets[name] = knownInfo
    self.knownCount = self.knownCount + 1
    self.knownChanged = true
  end
  knownInfo.active = true

  if (widget.GetInfo == nil) then
    Spring.Log(HANDLER_BASENAME, LOG.ERROR, 'Failed to load: ' .. basename .. '  (no GetInfo() call)')
    return nil
  end

    -- Get widget information
     local info  = widget:GetInfo()

    -- Enabling
    local order = self.orderList[name]
    if order then
        if order <= 0 then
           order = nil
        end
    else
        if info.enabled and (knownInfo.fromZip or (self.allowUserWidgets and not allowuserwidgets)) then
            order = 12345
        end
    end

    if order then
        self.orderList[name] = order
    else
        self.orderList[name] = 0
        self.knownWidgets[name].active = false
        return nil
    end


  -- load the config data  
  local config = self.configData[name]
  if (widget.SetConfigData and config) then
    widget:SetConfigData(config)
  end
    
  return widget
end


function widgetHandler:NewWidget()
  local widget = {}
  if (true) then
    -- copy the system calls into the widget table
    for k,v in pairs(System) do
      widget[k] = v
    end
  else
    -- use metatable redirection
    setmetatable(widget, {
      __index = System,
      __metatable = true,
    })
  end
  widget.WG = self.WG    -- the shared table
  widget.widget = widget -- easy self referencing

  -- wrapped calls (closures)
  widget.widgetHandler = {}
  local wh = widget.widgetHandler
  local self = self
  widget.include  = function (f) return include(f, widget) end
  wh.ForceLayout  = function (_) self:ForceLayout() end
  wh.RaiseWidget  = function (_) self:RaiseWidget(widget) end
  wh.LowerWidget  = function (_) self:LowerWidget(widget) end
  wh.RemoveWidget = function (_) self:RemoveWidget(widget) end
  wh.GetCommands  = function (_) return self.commands end
  wh.InTweakMode  = function (_) return self.tweakMode end
  wh.GetViewSizes = function (_) return self:GetViewSizes() end
  wh.GetHourTimer = function (_) return self:GetHourTimer() end
  wh.IsMouseOwner = function (_) return (self.mouseOwner == widget) end
  wh.DisownMouse  = function (_)
    if (self.mouseOwner == widget) then
      self.mouseOwner = nil
    end
  end
  wh.Ignore = function (_,name) if not ignorelist.ignorees[name] then ignorelist.ignorees[name] = true;ignorelist.count = ignorelist.count + 1 end end
  wh.Unignore = function (_,name) ignorelist.ignorees[name] = nil;ignorelist.count = ignorelist.count - 1 end
  wh.GetIgnoreList = function (_) return ignorelist["ignorees"],ignorelist.count end

  wh.UpdateCallIn = function (_, name)
    self:UpdateWidgetCallIn(name, widget)
  end
  wh.RemoveCallIn = function (_, name)
    self:RemoveWidgetCallIn(name, widget)
  end

  wh.AddAction    = function (_, cmd, func, data, types)
    return self.actionHandler:AddAction(widget, cmd, func, data, types)
  end
  wh.RemoveAction = function (_, cmd, types)
    return self.actionHandler:RemoveAction(widget, cmd, types)
  end

  wh.AddLayoutCommand = function (_, cmd)
    if (self.inCommandsChanged) then
      table.insert(self.customCommands, cmd)
    else
      Spring.Echo("AddLayoutCommand() can only be used in CommandsChanged()")
    end
  end

  wh.RegisterGlobal = function(_, name, value)
    return self:RegisterGlobal(widget, name, value)
  end
  wh.DeregisterGlobal = function(_, name)
    return self:DeregisterGlobal(widget, name)
  end
  wh.SetGlobal = function(_, name, value)
    return self:SetGlobal(widget, name, value)
  end
 

  wh.ConfigLayoutHandler = function(_, d) self:ConfigLayoutHandler(d) end
 -- Spring.Echo("Done Instantiating widget")
  return widget
end


function widgetHandler:FinalizeWidget(widget, filename, basename)
  local wi = {}


    wi.filename = filename
    wi.basename = basename
  if (widget.GetInfo == nil) then
    wi.name  = basename
    wi.layer = 0
  else
    local info = widget:GetInfo()
    wi = info
    wi.filename = filename
    wi.basename = basename
    wi.name     = wi.name    or basename
    wi.layer    = wi.layer   or 0
    wi.desc     = wi.desc    or ""
    wi.author   = wi.author  or ""
    wi.license  = wi.license or ""
    wi.enabled  = wi.enabled or false
    wi.api      = wi.api or false

    -- exprimental widget
    -- change name for separate settings and disable by default
    if info.experimental and isStable then
      wi.name = wi.name .. " (experimental)"
      wi.enabled = false
    end

  end

  widget.whInfo = {}  --  a proxy table
  local mt = {
    __index = wi,
    __newindex = function() error("whInfo tables are read-only") end,
    __metatable = "protected"
  }
  setmetatable(widget.whInfo, mt)
end


function widgetHandler:ValidateWidget(widget)
  if (widget.GetTooltip and not widget.IsAbove) then
    return "Widget has GetTooltip() but not IsAbove()"
  end
  if (widget.TweakGetTooltip and not widget.TweakIsAbove) then
    return "Widget has TweakGetTooltip() but not TweakIsAbove()"
  end
  return nil
end


--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

local function SafeWrapFuncNoGL(func, funcName)
  local wh = widgetHandler

  return function(w, ...)

    local r = { pcall(func, w, ...) }

    if (r[1]) then
      table.remove(r, 1)
      return unpack(r)
    else
      if (funcName ~= 'Shutdown') then
        widgetHandler:RemoveWidget(w)
      else
        Spring.Echo('Error in Shutdown()')
      end
      local name = w.whInfo.name
      Spring.Echo(r[1])
      Spring.Echo('Error in ' .. funcName ..'(): ' .. tostring(r[2]))
      Spring.Echo('Removed widget: ' .. name)
      return nil
    end
  end
end

local function HandleError(widget, funcName, status, ...)
  if (status) then
    return ...
  end

  if not widget then
    return ...
  end

  if (funcName ~= 'Shutdown') then
    widgetHandler:RemoveWidget(widget)
  else
    Spring.Echo(HANDLER_BASENAME, LOG.ERROR, 'Error in Shutdown()')
  end
  local name = widget.whInfo.name
  local error_message = select(1,...)
  Spring.Echo(HANDLER_BASENAME, LOG.ERROR, 'Error in ' .. funcName ..'(): ' .. tostring(error_message))
  Spring.Echo(HANDLER_BASENAME, LOG.ERROR, 'Removed widget: ' .. name)
  return nil
end

local function SafeWrapFuncNoGL(func, funcName)
  return function(w, ...)
    return HandleError(w, funcName, pcall(func, w, ...))
  end
end


local function SafeWrapFuncGL(func, funcName)
  local wh = widgetHandler

  return function(w, ...)

    glPushAttrib(GL.ALL_ATTRIB_BITS)
    local r = { pcall(func, w, ...) }
    glPopAttrib()

    if (r[1]) then
      table.remove(r, 1)
      return unpack(r)
    else
      if (funcName ~= 'Shutdown') then
        widgetHandler:RemoveWidget(w)
      else
        Spring.Echo('Error in Shutdown()')
      end
      local name = w.whInfo.name
      Spring.Echo('Error in ' .. funcName ..'(): ' .. tostring(r[2]))
      Spring.Echo('Removed widget: ' .. name)
      return nil
    end
  end
end


local function SafeWrapFunc(func, funcName)
  if (not SAFEDRAW) then
    return SafeWrapFuncNoGL(func, funcName)
  else
    if (string.sub(funcName, 1, 4) ~= 'Draw') then
      return SafeWrapFuncNoGL(func, funcName)
    else
      return SafeWrapFuncGL(func, funcName)
    end
  end
end


local function SafeWrapWidget(widget)
  if (SAFEWRAP <= 0) then
    return
  elseif (SAFEWRAP == 1) then
    if (widget.GetInfo and widget.GetInfo().unsafe) then
      Spring.Echo(HANDLER_BASENAME, LOG.ERROR, 'LuaUI: loaded unsafe widget: ' .. widget.whInfo.name)
      return
    end
  end

  for _,ciName in ipairs(callInLists) do
    if (widget[ciName]) then
      widget[ciName] = SafeWrapFunc(widget[ciName], ciName)
    end
    if (widget.Initialize) then
      widget.Initialize = SafeWrapFunc(widget.Initialize, 'Initialize')
    end
  end
end


--------------------------------------------------------------------------------

local function ArrayInsert(t, f, w)
  if (f) then
    local layer = w.whInfo.layer
    local index = 1
    for i,v in ipairs(t) do
      if (v == w) then
        return -- already in the table
      end
      if (layer >= v.whInfo.layer) then
        index = i + 1
      end
    end
    table.insert(t, index, w)
  end
end


local function ArrayRemove(t, w)
  for k,v in ipairs(t) do
    if (v == w) then
      table.remove(t, k)
      -- break
    end
  end
end


function widgetHandler:InsertWidget(widget)
  if (widget == nil) then
    return
  end

  SafeWrapWidget(widget)

  ArrayInsert(self.widgets, true, widget)
  for _,listname in ipairs(callInLists) do
    local func = widget[listname]
    if (type(func) == 'function') then
      ArrayInsert(self[listname..'List'], func, widget)
    end
  end
  self:UpdateCallIns()

  if (widget.Initialize) then
    widget:Initialize()
  end
end


function widgetHandler:RemoveWidget(widget)
  if (widget == nil) or (widget.whInfo == nil) then
    return
  end

  local name = widget.whInfo.name
    if (widget.GetConfigData) then

      local ok, err = pcall(function() self.configData[name] = widget:GetConfigData()  end)

  	   if not ok then Spring.Log(HANDLER_BASENAME, LOG.ERROR, "Failed to GetConfigData: " .. name.." ("..err..")") end 
    end

  self.knownWidgets[name].active = false
  if (widget.Shutdown) then
    widget:Shutdown()
  end
  ArrayRemove(self.widgets, widget)
  self:RemoveWidgetGlobals(widget)
  self.actionHandler:RemoveWidgetActions(widget)
  for _,listname in ipairs(callInLists) do
    ArrayRemove(self[listname..'List'], widget)
  end
  self:UpdateCallIns()
end


--------------------------------------------------------------------------------

function widgetHandler:UpdateCallIn(name)
  local listName = name .. 'List'
  if ((name == 'Update')     or
      (name == 'DrawScreen')) then
    return
  end

  if ((#self[listName] > 0) or
      (not flexCallInMap[name]) or
      ((name == 'GotChatMsg')     and actionHandler.HaveChatAction()) or
      ((name == 'RecvFromSynced') and actionHandler.HaveSyncAction())) then
    -- always assign these call-ins
    local selffunc = self[name]
    _G[name] = function(...)
      return selffunc(self, ...)
    end
  else
    _G[name] = nil
  end
  Script.UpdateCallIn(name)
end


function widgetHandler:UpdateWidgetCallIn(name, w)
  local listName = name .. 'List'
  local ciList = self[listName]
  if (ciList) then
    local func = w[name]
    if (type(func) == 'function') then
      ArrayInsert(ciList, func, w)
    else
      ArrayRemove(ciList, w)
    end
    self:UpdateCallIn(name)
  else
    Spring.Echo(HANDLER_BASENAME, LOG.ERROR, 'UpdateWidgetCallIn: bad name: ' .. name)
  end
end


function widgetHandler:RemoveWidgetCallIn(name, w)
  local listName = name .. 'List'
  local ciList = self[listName]
  if (ciList) then
    ArrayRemove(ciList, w)
    self:UpdateCallIn(name)
  else
    Spring.Echo(HANDLER_BASENAME, LOG.ERROR, 'RemoveWidgetCallIn: bad name: ' .. name)
  end
end


function widgetHandler:UpdateCallIns()
  for _,name in ipairs(callInLists) do
    self:UpdateCallIn(name)
  end
end


--------------------------------------------------------------------------------

function widgetHandler:IsWidgetKnown(name)
  return self.knownWidgets[name] and true or false
end


function widgetHandler:EnableWidget(name)
  local ki = self.knownWidgets[name]
  if (not ki) then
    Spring.Echo(HANDLER_BASENAME, LOG.ERROR, "EnableWidget(), could not find widget: " .. tostring(name))
    return false
  end
  if (not ki.active) then
    Spring.Echo('Loading:  '..ki.filename)
    local order = widgetHandler.orderList[name]
    if (not order or (order <= 0)) then
      self.orderList[name] = 1
    end
    local w = self:LoadWidget(ki.filename)
    if (not w) then return false end
    self:InsertWidget(w)
    self:SaveConfigData()
    self:SaveOrderList()
  end
  return true
end


function widgetHandler:DisableWidget(name)
  local ki = self.knownWidgets[name]
  if (not ki) then
    Spring.Echo(HANDLER_BASENAME, LOG.ERROR, "DisableWidget(), could not find widget: " .. tostring(name))
    return false
  end
  if (ki.active) then
    local w = self:FindWidget(name)
    if (not w) then return false end
    Spring.Echo('Removed:  '..ki.filename)
    self:RemoveWidget(w)     -- deactivate
    self.orderList[name] = 0 -- disable
    self:SaveOrderList()
  end
  return true
end

function widgetHandler:ToggleWidget(name)
  if self.orderList[name] == nil then
    self.orderList[name] = 0
  end

  local ki = self.knownWidgets[name]
  if (not ki) then
    Spring.Echo(HANDLER_BASENAME, LOG.ERROR, "ToggleWidget(), could not find widget: " .. tostring(name))
    return
  end
  if (ki.active) then
    return self:DisableWidget(name)
  elseif (self.orderList[name] <= 0) then
    return self:EnableWidget(name)
  else
    -- the widget is not active, but enabled; disable it
    self.orderList[name] = 0
    self:SaveOrderList()
    self:SaveConfigData()
  end
  return true
end

--------------------------------------------------------------------------------

local function FindWidgetIndex(t, w)
  for k,v in ipairs(t) do
    if (v == w) then
      return k
    end
  end
  return nil
end


local function FindLowestIndex(t, i, layer)
  for x = (i - 1), 1, -1 do
    if (t[x].whInfo.layer < layer) then
      return x + 1
    end
  end
  return 1
end


function widgetHandler:RaiseWidget(widget)
  if (widget == nil) then
    return
  end
  local function Raise(t, f, w)
    if (f == nil) then return end
    local i = FindWidgetIndex(t, w)
    if (i == nil) then return end
    local n = FindLowestIndex(t, i, w.whInfo.layer)
    if (n and (n < i)) then
      table.remove(t, i)
      table.insert(t, n, w)
    end
  end
  Raise(self.widgets, true, widget)
  for _,listname in ipairs(callInLists) do
    Raise(self[listname..'List'], widget[listname], widget)
  end
end


local function FindHighestIndex(t, i, layer)
  local ts = #t
  for x = (i + 1),ts do
    if (t[x].whInfo.layer > layer) then
      return (x - 1)
    end
  end
  return (ts + 1)
end


function widgetHandler:LowerWidget(widget)
  if (widget == nil) then
    return
  end
  local function Lower(t, f, w)
    if (f == nil) then return end
    local i = FindWidgetIndex(t, w)
    if (i == nil) then return end
    local n = FindHighestIndex(t, i, w.whInfo.layer)
    if (n and (n > i)) then
      table.insert(t, n, w)
      table.remove(t, i)
    end
  end
  Lower(self.widgets, true, widget)
  for _,listname in ipairs(callInLists) do
    Lower(self[listname..'List'], widget[listname], widget)
  end
end


function widgetHandler:FindWidget(name)
  if (type(name) ~= 'string') then
    return nil
  end
  for k,v in ipairs(self.widgets) do
    if (name == v.whInfo.name) then
      return v,k
    end
  end
  return nil
end


--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
--
--  Global var/func management
--



function widgetHandler:RegisterGlobal(owner, name, value)
  if ((name == nil)        or
      (_G[name])           or
      (self.globals[name]) or
      (CallInsMap[name])) then
	  Spring.Echo("Error: Callin did not succesfull register for callin "..name)
    return false
  end

  --[[if value then--]]
     _G[name] = value
    self.globals[name] = owner
--[[  else
    _G[owner] = name
    self.globals[owner] = self
  end
--]]


  return true
end


function widgetHandler:DeregisterGlobal(owner, name)
  if ((name == nil) or (self.globals[name] and (self.globals[name] ~= owner))) then
    return false
  end
  _G[name] = nil
  self.globals[name] = nil
  return true
end


function widgetHandler:SetGlobal(owner, name, value)
  if ((name == nil) or (self.globals[name] ~= owner)) then
    return false
  end
  _G[name] = value
  return true
end


function widgetHandler:RemoveWidgetGlobals(owner)
  local count = 0
  for name, o in pairs(self.globals) do
    if (o == owner) then
      _G[name] = nil
      self.globals[name] = nil
      count = count + 1
    end
  end
  return count
end


--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
--
--  Helper facilities
--

local hourTimer = 0


function widgetHandler:GetHourTimer()
  return hourTimer
end

function widgetHandler:GetViewSizes()
  return self.xViewSize, self.yViewSize
end

function widgetHandler:ForceLayout()
  forceLayout = true  --  in main.lua
end


function widgetHandler:ConfigLayoutHandler(data)
  ConfigLayoutHandler(data)
end

function widgetHandler:isStable()
  return isStable
end

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
--
--  The call-in distribution routines
--

function widgetHandler:Shutdown()
  Spring.Echo("Start widgetHandler:Shutdown")
  self:SaveOrderList()
  Spring.Echo("Shutdown - SaveOrderList Complete")
  self:SaveConfigData()
  Spring.Echo("Shutdown - SaveConfigData Complete")

  for _,w in ipairs(self.ShutdownList) do
    local name = w.whInfo.name or "UNKNOWN NAME"
	Spring.Echo("Shutdown Widget - " .. name)
	w:Shutdown()
  end
  Spring.Echo("End widgetHandler:Shutdown")
  
  return
end

function widgetHandler:Update()
  local deltaTime = Spring.GetLastUpdateSeconds()  
  -- update the hour timer
  hourTimer = (hourTimer + deltaTime) % 3600
  for _,w in ipairs(self.UpdateList) do
    w:Update(deltaTime)
  end
  return
end


function widgetHandler:ConfigureLayout(command)
  if (command == 'tweakgui') then
    self.tweakMode = true
    Spring.Echo("LuaUI TweakMode: ON")
    return true
  elseif (command == 'reconf') then
    self:SendConfigData()
    return true
  elseif (command == 'selector') then
    for _,w in ipairs(self.widgets) do
      if (w.whInfo.basename == SELECTOR_BASENAME) then
        return true  -- there can only be one
      end
    end
    local sw = self:LoadWidget(WIDGET_DIRNAME .. SELECTOR_BASENAME, VFS.RAW_FIRST)
    self:InsertWidget(sw)
    self:RaiseWidget(sw)
    return true
  elseif (string.find(command, 'togglewidget') == 1) then
    self:ToggleWidget(string.sub(command, 14))
    return true
  elseif (string.find(command, 'enablewidget') == 1) then
    self:EnableWidget(string.sub(command, 14))
    return true
  elseif (string.find(command, 'disablewidget') == 1) then
    self:DisableWidget(string.sub(command, 15))
    return true
  end

  if (self.actionHandler:TextAction(command)) then
    return true
  end

  for _,w in ipairs(self.TextCommandList) do
    if (w:TextCommand(command)) then
      return true
    end
  end
  return false
end


function widgetHandler:CommandNotify(id, params, options)
  for _,w in ipairs(self.CommandNotifyList) do
    if (w:CommandNotify(id, params, options)) then
      return true
    end
  end
  return false
end


function widgetHandler:AddConsoleLine(msg, priority)
  for _,w in ipairs(self.AddConsoleLineList) do
    w:AddConsoleLine(msg, priority)
  end
  return
end


function widgetHandler:GroupChanged(groupID)
  for _,w in ipairs(self.GroupChangedList) do
    w:GroupChanged(groupID)
  end
  return
end


function widgetHandler:CommandsChanged()
  widgetHandler:UpdateSelection() -- for selectionchanged
  self.inCommandsChanged = true
  self.customCommands = {}  
  for _,w in ipairs(self.CommandsChangedList) do
    w:CommandsChanged()
  end
  self.inCommandsChanged = false
  return
end


--------------------------------------------------------------------------------
--
--  Drawing call-ins
--
function widgetHandler:SetViewSize(vsx, vsy)
  self.xViewSize = vsx
  self.yViewSize = vsy
  if ((self.xViewSizeOld ~= vsx) or
      (self.yViewSizeOld ~= vsy)) then
    widgetHandler:ViewResize(vsx, vsy)
    self.xViewSizeOld = vsx
    self.yViewSizeOld = vsy
  end
end


function widgetHandler:ViewResize(vsx, vsy)
  if (type(vsx) == 'table') then
    vsy = vsx.viewSizeY
    vsx = vsx.viewSizeX
    print('real ViewResize') -- FIXME
  end

  for _,w in ipairs(self.ViewResizeList) do
    w:ViewResize(vsx, vsy)
  end
  return
end


function widgetHandler:DrawScreen()
  if (self.tweakMode) then
    gl.Color(0, 0, 0, 0.5)
    local sx, sy = self.xViewSize, self.yViewSize
    gl.Shape(GL.QUADS, {
      {v = {  0,  0 }}, {v = { sx,  0 }}, {v = { sx, sy }}, {v = {  0, sy }}
    })
    gl.Color(1, 1, 1)
  end
  for _,w in ripairs(self.DrawScreenList) do
    w:DrawScreen()
    if (self.tweakMode and w.TweakDrawScreen) then
      w:TweakDrawScreen()
    end
  end
  return
end


function widgetHandler:DrawGenesis()
  for _,w in ripairs(self.DrawGenesisList) do
    w:DrawGenesis()
  end
  return
end


function widgetHandler:DrawWorld()
  for _,w in ripairs(self.DrawWorldList) do
    w:DrawWorld()
  end
  return
end

function widgetHandler:DrawWorldPreUnit()
  for _,w in ripairs(self.DrawWorldPreUnitList) do
    w:DrawWorldPreUnit()
  end
  return
end


function widgetHandler:DrawWorldPreParticles()
  for _,w in ripairs(self.DrawWorldPreParticlesList) do
    w:DrawWorldPreParticles()
  end
  return
end


function widgetHandler:DrawWorldShadow()
  for _,w in ripairs(self.DrawWorldShadowList) do
    w:DrawWorldShadow()
  end
  return
end


function widgetHandler:DrawWorldReflection()
  for _,w in ripairs(self.DrawWorldReflectionList) do
    w:DrawWorldReflection()
  end
  return
end


function widgetHandler:DrawWorldRefraction()
  for _,w in ripairs(self.DrawWorldRefractionList) do
    w:DrawWorldRefraction()
  end
  return
end


function widgetHandler:DrawUnitsPostDeferred()
  for _,w in ripairs(self.DrawUnitsPostDeferredList) do
    w:DrawUnitsPostDeferred()
  end
  return
end


function widgetHandler:DrawFeaturesPostDeferred()
  for _,w in ripairs(self.DrawFeaturesPostDeferredList) do
    w:DrawFeaturesPostDeferred()
  end
  return
end


function widgetHandler:DrawScreenEffects(vsx, vsy)
  for _,w in ripairs(self.DrawScreenEffectsList) do
    w:DrawScreenEffects(vsx, vsy)
  end
  return
end


function widgetHandler:DrawScreenPost()
  for _,w in ripairs(self.DrawScreenPostList) do
    w:DrawScreenPost()
  end
  return
end


function widgetHandler:DrawInMiniMap(xSize, ySize)
  for _,w in ripairs(self.DrawInMiniMapList) do
    w:DrawInMiniMap(xSize, ySize)
  end
  return
end

function widgetHandler:SunChanged()
  for _,w in ripairs(self.SunChangedList) do
    w:SunChanged()
  end
  return
end

--------------------------------------------------------------------------------
--
--  Keyboard call-ins
--

function widgetHandler:KeyPress(key, mods, isRepeat, label, unicode)
  if (self.tweakMode) then
    local mo = self.mouseOwner
    if (mo and mo.TweakKeyPress) then
      mo:TweakKeyPress(key, mods, isRepeat, label, unicode)
    end
    return true
  end

  if (self.actionHandler:KeyAction(true, key, mods, isRepeat)) then
    return true
  end

  for _,w in ipairs(self.KeyPressList) do
    if (w:KeyPress(key, mods, isRepeat, label, unicode)) then
      return true
    end
  end
  return false
end


function widgetHandler:KeyRelease(key, mods, label, unicode)
  if (self.tweakMode) then
    local mo = self.mouseOwner
    if (mo and mo.TweakKeyRelease) then
      mo:TweakKeyRelease(key, mods, label, unicode)
    elseif (key == KEYSYMS.ESCAPE) then
      Spring.Echo("LuaUI TweakMode: OFF")
      self.tweakMode = false
    end
    return true
  end

  if (self.actionHandler:KeyAction(false, key, mods, false)) then
    return true
  end

  for _,w in ipairs(self.KeyReleaseList) do
    if (w:KeyRelease(key, mods, label, unicode)) then
      return true
    end
  end
  return false
end

function widgetHandler:TextInput(utf8, ...)
  if (self.tweakMode) then
    return true
  end
  
  for _,w in ipairs(self.TextInputList) do
    if (w:TextInput(utf8, ...)) then
      return true
    end
  end
  return false
end


--------------------------------------------------------------------------------
--
--  Mouse call-ins
--

do
  local lastDrawFrame = 0
  local lastx,lasty = 0,0
  local lastWidget

  local spGetDrawFrame = Spring.GetDrawFrame

  -- local helper (not a real call-in)
  function widgetHandler:WidgetAt(x, y)
    local drawframe = spGetDrawFrame()
    if (lastDrawFrame == drawframe)and(lastx == x)and(lasty == y) then
      return lastWidget
    end

    lastDrawFrame = drawframe
    lastx = x
    lasty = y
 
    if (not self.tweakMode) then
      for _,w in ipairs(self.IsAboveList) do
        if (w:IsAbove(x, y)) then
          lastWidget = w
          return w
        end
      end
    else
      for _,w in ipairs(self.TweakIsAboveList) do
        if (w:TweakIsAbove(x, y)) then
          lastWidget = w
          return w
        end
      end
    end
    lastWidget = nil
    return nil
  end
end

function widgetHandler:MousePress(x, y, button)
  local mo = self.mouseOwner
  if (not self.tweakMode) then
    if (mo) then
      mo:MousePress(x, y, button)
      return true  --  already have an active press
    end
    for _,w in ipairs(self.MousePressList) do
      if (w:MousePress(x, y, button)) then
        if (not mo) then
          self.mouseOwner = w
        end
        return true
      end
    end
    return false
  else
    if (mo) then
      mo:TweakMousePress(x, y, button)
      return true  --  already have an active press
    end
    for _,w in ipairs(self.TweakMousePressList) do
      if (w:TweakMousePress(x, y, button)) then
        self.mouseOwner = w
        return true
      end
    end
    return true  --  always grab the mouse
  end
end


function widgetHandler:MouseMove(x, y, dx, dy, button)
  local mo = self.mouseOwner
  if (not self.tweakMode) then
    if (mo and mo.MouseMove) then
      return mo:MouseMove(x, y, dx, dy, button)
    end
  else
    if (mo and mo.TweakMouseMove) then
      mo:TweakMouseMove(x, y, dx, dy, button)
    end
    return true
  end
end


function widgetHandler:MouseRelease(x, y, button)
  local mo = self.mouseOwner
  local mx, my, lmb, mmb, rmb = Spring.GetMouseState()
  if (not (lmb or mmb or rmb)) then
    self.mouseOwner = nil
  end

  if (not self.tweakMode) then
    if (mo and mo.MouseRelease) then
      return mo:MouseRelease(x, y, button)
    end
    return -1
  else
    if (mo and mo.TweakMouseRelease) then
      mo:TweakMouseRelease(x, y, button)
    end
    return -1
  end
end


function widgetHandler:MouseWheel(up, value)
  if (not self.tweakMode) then
    for _,w in ipairs(self.MouseWheelList) do
      if (w:MouseWheel(up, value)) then
        return true
      end
    end
    return false
  else
    for _,w in ipairs(self.TweakMouseWheelList) do
      if (w:TweakMouseWheel(up, value)) then
        return true
      end
    end
    return false -- FIXME: always grab in tweakmode?
  end
end

function widgetHandler:JoyAxis(axis, value)
	for _,w in ipairs(self.JoyAxisList) do
		if (w:JoyAxis(axis, value)) then
		return true
		end
	end
	return false
end

function widgetHandler:JoyHat(hat, value)
	for _,w in ipairs(self.JoyHatList) do
		if (w:JoyHat(hat, value)) then
		return true
		end
	end
	return false
end

function widgetHandler:JoyButtonDown(button, state)
	for _,w in ipairs(self.JoyButtonDownList) do
		if (w:JoyButtonDown(button, state)) then
		return true
		end
	end
	return false
end

function widgetHandler:JoyButtonUp(button, state)
	for _,w in ipairs(self.JoyButtonUpList) do
		if (w:JoyButtonUp(button, state)) then
		return true
		end
	end
	return false
end

function widgetHandler:IsAbove(x, y)
  if (self.tweakMode) then
    return true
  end
  return (widgetHandler:WidgetAt(x, y) ~= nil)
end


function widgetHandler:GetTooltip(x, y)
  if (not self.tweakMode) then
    for _,w in ipairs(self.GetTooltipList) do
      if (w:IsAbove(x, y)) then
        local tip = w:GetTooltip(x, y)
        if ((type(tip) == 'string') and (#tip > 0)) then
          return tip
        end
      end
    end
    return ""
  else
    for _,w in ipairs(self.TweakGetTooltipList) do
      if (w:TweakIsAbove(x, y)) then
        local tip = w:TweakGetTooltip(x, y) or ''
        if ((type(tip) == 'string') and (#tip > 0)) then
          return tip
        end
      end
    end
    return "Tweak Mode  --  hit ESCAPE to cancel"
  end
end


--------------------------------------------------------------------------------
--
--  Game call-ins
--

function widgetHandler:GamePreload()
  for _,w in ipairs(self.GamePreloadList) do
    w:GamePreload()
  end
  return
end

function widgetHandler:GameStart()
  for _,w in ipairs(self.GameStartList) do
    w:GameStart()
  end

	local plist = ""
	gaiaTeam = Spring.GetGaiaTeamID()
	for _, teamID in ipairs(Spring.GetTeamList()) do
		local teamLuaAI = Spring.GetTeamLuaAI(teamID)
		if ((teamLuaAI == nil or teamLuaAI == "") and teamID ~= gaiaTeam) then
			local _,_,_,ai,side,ally = Spring.GetTeamInfo(teamID)
			if (not ai) then 
				for _, pid in ipairs(Spring.GetPlayerList(teamID)) do
					local name, active, spec = Spring.GetPlayerInfo(pid)
					if active and not spec then plist = plist .. "," .. name end
				end
			end	
		end
	end
--	Spring.Echo("STATS:plist"..plist)
  return
end

function widgetHandler:GameOver(winners)
  for _,w in ipairs(self.GameOverList) do
    w:GameOver(winners)
  end
  return
end


function widgetHandler:GamePaused(playerID, paused)
  for _,w in ipairs(self.GamePausedList) do
    w:GamePaused(playerID, paused)
  end
  return
end


function widgetHandler:TeamDied(teamID)
  for _,w in ipairs(self.TeamDiedList) do
    w:TeamDied(teamID)
  end
  return
end


function widgetHandler:TeamChanged(teamID)
  for _,w in ipairs(self.TeamChangedList) do
    w:TeamChanged(teamID)
  end
  return
end


function widgetHandler:PlayerAdded(playerID, reason) --when player Join Lobby
 -- MessageProcessor:AddPlayer(playerID)
  --ListMutedPlayers()
  for _,w in ipairs(self.PlayerAddedList) do
    w:PlayerAdded(playerID, reason)
  end
  return
end


function widgetHandler:PlayerChanged(playerID) --when player Change from Spectator to Player or Player to Spectator.
 -- MessageProcessor:UpdatePlayer(playerID)
  for _,w in ipairs(self.PlayerChangedList) do
    w:PlayerChanged(playerID)
  end
  return
end


function widgetHandler:PlayerRemoved(playerID, reason) --when player Left a Running Game.
  for _,w in ipairs(self.PlayerRemovedList) do
    w:PlayerRemoved(playerID, reason)
  end
  return
end


function widgetHandler:GameFrame(frameNum)
  for _,w in ipairs(self.GameFrameList) do
    w:GameFrame(frameNum)
  end
  return
end


-- local helper (not a real call-in)
local oldSelection = {}
function widgetHandler:UpdateSelection()
  local changed
  local newSelection = Spring.GetSelectedUnits()
  if (#newSelection == #oldSelection) then
    for i = 1, #oldSelection do
      if (newSelection[i] ~= oldSelection[i]) then -- it seems the order stays
        changed = true
        break
      end
    end
  else
    changed = true
  end
  if (changed) then
    local subselection = true
    if #newSelection > #oldSelection then
      subselection = false
    else
      local newSeen = 0
      local oldSelectionMap = {}
      for i = 1, #oldSelection do
        oldSelectionMap[oldSelection[i]] = true
      end
      for i = 1, #newSelection do
        if not oldSelectionMap[newSelection[i]] then
          subselection = false
          break
        end
      end
    end
    if widgetHandler:SelectionChanged(newSelection, subselection) then
      -- selection changed, don't set old selection to new selection as it is soon to change.
      return true
    end
  end
  oldSelection = newSelection
  return false
end

function widgetHandler:SelectionChanged(selectedUnits, subselection)
  for _,w in ipairs(self.SelectionChangedList) do
    if widgetHandler.WG['smartselect'] and not widgetHandler.WG['smartselect'].updateSelection then return end
      local unitArray = w:SelectionChanged(selectedUnits, subselection)
      if (unitArray) then
        Spring.SelectUnitArray(unitArray)
        return true
      end
  end
  return false
end

function widgetHandler:GameProgress(serverFrameNum)
  for _,w in ipairs(self.GameProgressList) do
    w:GameProgress(serverFrameNum)
  end
  return
end

function widgetHandler:ShockFront(power, dx, dy, dz)
  for _,w in ipairs(self.ShockFrontList) do
    w:ShockFront(power, dx, dy, dz)
  end
  return
end

function widgetHandler:RecvSkirmishAIMessage(aiTeam, dataStr)
  for _,w in ipairs(self.RecvSkirmishAIMessageList) do
    local dataRet = w:RecvSkirmishAIMessage(aiTeam, dataStr)
    if (dataRet) then
      return dataRet
    end
  end
end

function widgetHandler:WorldTooltip(ttType, ...)
  for _,w in ipairs(self.WorldTooltipList) do
    local tt = w:WorldTooltip(ttType, ...)
    if ((type(tt) == 'string') and (#tt > 0)) then
      return tt
    end
  end
  return
end


function widgetHandler:MapDrawCmd(playerID, cmdType, px, py, pz, ...)
  local customkeys = select(10, Spring.GetPlayerInfo(playerID))
  if  (ignorelist.ignorees and ignorelist.ignorees[select(1,Spring.GetPlayerInfo(playerID))]) or (customkeys and type(customkeys)=="table" and customkeys.muted) then
    return true
  end
  
  local retval = false
  for _,w in ipairs(self.MapDrawCmdList) do
    local takeEvent = w:MapDrawCmd(playerID, cmdType, px, py, pz, ...)
    if (takeEvent) then
      retval = true
    end
  end
  return retval
end


function widgetHandler:GameSetup(state, ready, playerStates)
  for _,w in ipairs(self.GameSetupList) do
    local success, newReady = w:GameSetup(state, ready, playerStates)
    if (success) then
      return true, newReady
    end
  end
  return false
end


function widgetHandler:DefaultCommand(...)
  for _,w in ripairs(self.DefaultCommandList) do
    local result = w:DefaultCommand(...)
    if (type(result) == 'number') then
      return result
    end
  end
  return nil  --  not a number, use the default engine command
end


--------------------------------------------------------------------------------
--
--  Unit call-ins
--

function widgetHandler:UnitCreated(unitID, unitDefID, unitTeam, builderID)
  for _,w in ipairs(self.UnitCreatedList) do
    w:UnitCreated(unitID, unitDefID, unitTeam, builderID)
  end
  return
end


function widgetHandler:UnitFinished(unitID, unitDefID, unitTeam)
  for _,w in ipairs(self.UnitFinishedList) do
    w:UnitFinished(unitID, unitDefID, unitTeam)
  end
  return
end

function widgetHandler:UnitReverseBuilt(unitID, unitDefID, unitTeam)
  for _,w in ipairs(self.UnitReverseBuiltList) do
    w:UnitReverseBuilt(unitID, unitDefID, unitTeam)
  end
  return
end

function widgetHandler:UnitFromFactory(unitID, unitDefID, unitTeam,
                                       factID, factDefID, userOrders)
  for _,w in ipairs(self.UnitFromFactoryList) do
    w:UnitFromFactory(unitID, unitDefID, unitTeam,
                      factID, factDefID, userOrders)
  end
  return
end


function widgetHandler:UnitDestroyed(unitID, unitDefID, unitTeam, pre)
  if pre == false then return end
  for _,w in ipairs(self.UnitDestroyedList) do
    w:UnitDestroyed(unitID, unitDefID, unitTeam)
  end
  return
end


function widgetHandler:UnitDestroyedByTeam(unitID, unitDefID, unitTeam, attTeamID)
  for _,w in ipairs(self.UnitDestroyedByTeamList) do
    w:UnitDestroyedByTeam(unitID, unitDefID, unitTeam, attTeamID)
  end
  return
end


function widgetHandler:UnitExperience(unitID,     unitDefID,     unitTeam,
                                      experience, oldExperience)
  for _,w in ipairs(self.UnitExperienceList) do
    w:UnitExperience(unitID,     unitDefID,     unitTeam,
                    experience, oldExperience)
  end
  return
end


function widgetHandler:UnitTaken(unitID, unitDefID, unitTeam, newTeam)
  for _,w in ipairs(self.UnitTakenList) do
    w:UnitTaken(unitID, unitDefID, unitTeam, newTeam)
  end
  return
end


function widgetHandler:UnitGiven(unitID, unitDefID, unitTeam, oldTeam)
  for _,w in ipairs(self.UnitGivenList) do
    w:UnitGiven(unitID, unitDefID, unitTeam, oldTeam)
  end
  return
end


function widgetHandler:UnitIdle(unitID, unitDefID, unitTeam)
  for _,w in ipairs(self.UnitIdleList) do
    w:UnitIdle(unitID, unitDefID, unitTeam)
  end
  return
end


function widgetHandler:UnitCommand(unitID, unitDefID, unitTeam,
                                   cmdId, cmdParams, cmdOpts, cmdTag, playerID, fromSynced, fromLua) --cmdTag available in Spring 95
  assert(cmdId)
 --[[ Spring.Echo("widgets.lua::Routing Unit Command")--]]
  if reverseCompat then
    cmdOpts, cmdParams = cmdParams, cmdOpts
  end
  for _,w in ipairs(self.UnitCommandList) do
    w:UnitCommand(unitID, unitDefID, unitTeam,
                  cmdId, cmdParams, cmdOpts, cmdTag, playerID, fromSynced, fromLua)
  end
  return
end


function widgetHandler:UnitCmdDone(unitID, unitDefID, unitTeam, cmdID, cmdParams, cmdOptions, cmdTag) --cmdParams & cmdOptions available in Spring 95
  if reverseCompat then
    cmdOptions, cmdParams = cmdParams, cmdOptions
  end
  
  for _,w in ipairs(self.UnitCmdDoneList) do
    w:UnitCmdDone(unitID, unitDefID, unitTeam, cmdID, cmdParams, cmdOptions, cmdTag)
  end
  return
end


function widgetHandler:UnitDamaged(unitID, unitDefID, unitTeam,
                                   damage, paralyzer)
  for _,w in ipairs(self.UnitDamagedList) do
    w:UnitDamaged(unitID, unitDefID, unitTeam, damage, paralyzer)
  end
  return
end

function widgetHandler:UnitStunned(unitID, unitDefID, unitTeam, stunned)
  for _,w in ipairs(self.UnitStunnedList) do
    w:UnitStunned(unitID, unitDefID, unitTeam, stunned)
  end
  return
end

function widgetHandler:UnitEnteredRadar(unitID, unitTeam)
  for _,w in ipairs(self.UnitEnteredRadarList) do
    w:UnitEnteredRadar(unitID, unitTeam)
  end
  return
end


function widgetHandler:UnitEnteredLos(unitID, unitTeam)
  for _,w in ipairs(self.UnitEnteredLosList) do
    w:UnitEnteredLos(unitID, unitTeam)
  end
  return
end


function widgetHandler:UnitLeftRadar(unitID, unitTeam)
  for _,w in ipairs(self.UnitLeftRadarList) do
    w:UnitLeftRadar(unitID, unitTeam)
  end
  return
end


function widgetHandler:UnitLeftLos(unitID,  unitTeam)
  for _,w in ipairs(self.UnitLeftLosList) do
    w:UnitLeftLos(unitID,  unitTeam)
  end
  return
end


function widgetHandler:UnitEnteredWater(unitID, unitDefID, unitTeam)
  for _,w in ipairs(self.UnitEnteredWaterList) do
    w:UnitEnteredWater(unitID, unitDefID, unitTeam)
  end
  return
end


function widgetHandler:UnitEnteredAir(unitID, unitDefID, unitTeam)
  for _,w in ipairs(self.UnitEnteredAirList) do
    w:UnitEnteredAir(unitID, unitDefID, unitTeam)
  end
  return
end


function widgetHandler:UnitLeftWater(unitID, unitDefID, unitTeam)
  for _,w in ipairs(self.UnitLeftWaterList) do
    w:UnitLeftWater(unitID, unitDefID, unitTeam)
  end
  return
end


function widgetHandler:UnitLeftAir(unitID, unitDefID, unitTeam)
  for _,w in ipairs(self.UnitLeftAirList) do
    w:UnitLeftAir(unitID, unitDefID, unitTeam)
  end
  return
end


function widgetHandler:UnitSeismicPing(x, y, z, strength)
  for _,w in ipairs(self.UnitSeismicPingList) do
    w:UnitSeismicPing(x, y, z, strength)
  end
  return
end


function widgetHandler:UnitLoaded(unitID, unitDefID, unitTeam,
                                  transportID, transportTeam)
  for _,w in ipairs(self.UnitLoadedList) do
    w:UnitLoaded(unitID, unitDefID, unitTeam,
                 transportID, transportTeam)
  end
  return
end


function widgetHandler:UnitUnloaded(unitID, unitDefID, unitTeam,
                                    transportID, transportTeam)
  for _,w in ipairs(self.UnitUnloadedList) do
    w:UnitUnloaded(unitID, unitDefID, unitTeam,
                   transportID, transportTeam)
  end
  return
end


function widgetHandler:UnitCloaked(unitID, unitDefID, unitTeam)
  for _,w in ipairs(self.UnitCloakedList) do
    w:UnitCloaked(unitID, unitDefID, unitTeam)
  end
  return
end


function widgetHandler:UnitDecloaked(unitID, unitDefID, unitTeam)
  for _,w in ipairs(self.UnitDecloakedList) do
    w:UnitDecloaked(unitID, unitDefID, unitTeam)
  end
  return
end


function widgetHandler:UnitMoveFailed(unitID, unitDefID, unitTeam)
  for _,w in ipairs(self.UnitMoveFailedList) do
    w:UnitMoveFailed(unitID, unitDefID, unitTeam)
  end
  return
end


function widgetHandler:RecvLuaMsg(msg, playerID)
  local retval = false
  for _,w in ipairs(self.RecvLuaMsgList) do
    if (w:RecvLuaMsg(msg, playerID)) then
      retval = true
    end
  end
  return retval  --  FIXME  --  another actionHandler type?
end


function widgetHandler:StockpileChanged(unitID, unitDefID, unitTeam,
                                        weaponNum, oldCount, newCount)
  for _,w in ipairs(self.StockpileChangedList) do
    w:StockpileChanged(unitID, unitDefID, unitTeam,
                       weaponNum, oldCount, newCount)
  end
  return
end


-- local helper (not a real call-in)
local oldSelection = {}
function widgetHandler:UpdateSelection()
	local changed
	local newSelection = Spring.GetSelectedUnits()
	if (#newSelection == #oldSelection) then
		for i = 1, #oldSelection do
			if (newSelection[i] ~= oldSelection[i]) then -- it seems the order stays
				changed = true
				break
			end                                          
		end
	else
		changed = true
	end
	if (changed) then
		local subselection = true
		if #newSelection > #oldSelection then
			subselection = false
		else
			local newSeen = 0
			local oldSelectionMap = {}
			for i = 1, #oldSelection do
				oldSelectionMap[oldSelection[i]] = true
			end
			for i = 1, #newSelection do
				if not oldSelectionMap[newSelection[i]] then
					subselection = false
					break
				end
			end
		end
		if widgetHandler:SelectionChanged(newSelection, subselection) then
			-- selection changed, don't set old selection to new selection as it is soon to change.
			return true
		end
	end
	oldSelection = newSelection
	return false
end


function widgetHandler:SelectionChanged(selectedUnits, subselection)
  for _,w in ipairs(self.SelectionChangedList) do
    local unitArray = w:SelectionChanged(selectedUnits, subselection)
    if (unitArray) then
      Spring.SelectUnitArray(unitArray)
      return true
    end
  end
  return false
end


function widgetHandler:GameProgress(frame)
  for _,w in ipairs(self.GameProgressList) do
    w:GameProgress(frame)
  end
  return
end

--Feature call-ins


function widgetHandler:FeatureCreated(featureID, allyTeam)
  for _,w in ipairs(self.FeatureCreatedList) do
    w:FeatureCreated(featureID, allyTeam)
  end
  return
end


function widgetHandler:FeatureDestroyed(featureID, allyTeam)
  for _,w in ipairs(self.FeatureDestroyedList) do
    w:FeatureDestroyed(featureID, allyTeam)
  end
  return
end

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

widgetHandler:Initialize()

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

Spring.Echo("widgets.lua: Custom Widgethandler completes loading")











