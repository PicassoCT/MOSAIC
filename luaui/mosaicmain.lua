-- $Id: main.lua 3171 2008-11-06 09:06:29Z det $
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
--
--  file:    main.lua
--  brief:   the entry point from gui.lua, relays call-ins to the widget manager
--  author:  Dave Rodgers
--
--  Copyright (C) 2007.
--  Licensed under the terms of the GNU GPL, v2 or later.
--
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------


Spring.Echo("◘◘◘◘ mosaicmain.lua :: Start Loading ◘◘◘◘")

local vfsInclude = VFS.Include
local vfsGame = VFS.GAME
local spSendCommands = Spring.SendCommands
LUAUI_DIRNAME =  "luaui/"
local LUAUI_DIRNAME = LUAUI_DIRNAME or "luaui/"


spSendCommands({"ctrlpanel " .. LUAUI_DIRNAME .. "ctrlpanel.txt"})
spSendCommands("echo " .. LUAUI_VERSION)

vfsInclude(LUAUI_DIRNAME.."utils.lua"    , nil, vfsGame)
vfsInclude(LUAUI_DIRNAME.."setupdefs.lua", nil, vfsGame)
vfsInclude(LUAUI_DIRNAME.."savetable.lua", nil, vfsGame)
vfsInclude(LUAUI_DIRNAME.."debug.lua"    , nil, vfsGame)
vfsInclude(LUAUI_DIRNAME.."modfonts.lua"    , nil, vfsGame)
vfsInclude(LUAUI_DIRNAME.."layout.lua"   , nil, vfsGame)   -- contains a simple LayoutButtons()
vfsInclude(LUAUI_DIRNAME.."mosaicwidgets.lua", nil, vfsGame)  -- the widget handler


--------------------------------------------------------------------------------
--
-- print the header
--

if (RestartCount == nil) then
  RestartCount = 0
else 
  RestartCount = RestartCount + 1
end

do
  local restartStr = ""
  if (RestartCount > 0) then
    restartStr = "  (" .. RestartCount .. " Restarts)"
  end
  Spring.SendCommands({"echo " .. LUAUI_VERSION .. restartStr})
end


--------------------------------------------------------------------------------

local gl = Spring.Draw  --  easier to use


-------------------------------------------------------------------------------
-------------------------------------------------------------------------------
--
--  A few helper functions
--

function Say(msg)
  Spring.SendCommands({'say ' .. msg})
end


-------------------------------------------------------------------------------
-------------------------------------------------------------------------------
--
--  Update()  --  called every frame
--

activePage = 0

forceLayout = true


function Update()
  local currentPage = Spring.GetActivePage()
  if (forceLayout or (currentPage ~= activePage)) then
    Spring.ForceLayoutUpdate()  --  for the page number indicator
    forceLayout = false
  end
  activePage = currentPage

  fontHandler.Update()

  widgetHandler:Update()

  return
end


-------------------------------------------------------------------------------
-------------------------------------------------------------------------------
--
--  WidgetHandler fixed calls
--

function Shutdown()
  return widgetHandler:Shutdown()
end

function ConfigureLayout(command)
  return widgetHandler:ConfigureLayout(command)
end

function CommandNotify(id, params, options)
  return widgetHandler:CommandNotify(id, params, options)
end

function DrawScreen(vsx, vsy)
  return widgetHandler:DrawScreen()
end

function KeyPress(key, mods, isRepeat)
  return widgetHandler:KeyPress(key, mods, isRepeat)
end

function KeyRelease(key, mods)
  return widgetHandler:KeyRelease(key, mods)
end

function TextInput(utf8, ...)
  return widgetHandler:TextInput(utf8, ...)
end

function MouseMove(x, y, dx, dy, button)
  return widgetHandler:MouseMove(x, y, dx, dy, button)
end

function MousePress(x, y, button)
  return widgetHandler:MousePress(x, y, button)
end

function MouseRelease(x, y, button)
  return widgetHandler:MouseRelease(x, y, button)
end

function IsAbove(x, y)
  return widgetHandler:IsAbove(x, y)
end

function GetTooltip(x, y)
  return widgetHandler:GetTooltip(x, y)
end

function AddConsoleLine(msg, priority)
  return widgetHandler:AddConsoleLine(msg, priority)
end

function GroupChanged(groupID)
  return widgetHandler:GroupChanged(groupID)
end

--
-- The unit (and some of the Draw) call-ins are handled
-- differently (see luaui/widgets.lua / UpdateCallIns())
--


--------------------------------------------------------------------------------

Spring.Echo("◘◘◘◘ mosaicmain.lua :: End Loading ◘◘◘◘")
