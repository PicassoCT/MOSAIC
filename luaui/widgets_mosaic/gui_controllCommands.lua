
function widget:GetInfo()
	return {
		name = "gui_controllwindow",
		desc = "Displays BasicCommands",
		author = "PicassoCT",
		date = "2016-6-2",
		license = "GNU GPL, v2 or later",
		layer = 0,
		enabled = false,
		hidden = true,
		handler = true 
	}
end

--Shared Data
local Chili
local Button
local Label
local Window
local Panel
local Image
local Progressbar
local screen0
local testIrregular
local imageDirComands = 'luaui/images/commands/'
local onoffTexture = {imageDirComands .. 'states/off.png', imageDirComands .. 'states/on.png'}
local selectedUnits = {}
local controllCommand_window
local activeCommand = 0
local	main_menu_grid 
updateRequired = false

local ignoreCMDs = {
	timewait=true,
	deathwait=true,
	squadwait=true,
	gatherwait=true,
	loadonto=true,
}
targetCommands = VFS.Include("LuaUI/ressources/guiEnums.lua")
VFS.Include("LuaUI/ressources/gui_helper.lua")
VFS.Include("scripts/lib_UnitScript.lua")
---------------------------------------------------------------------------------------

controllCommand_window_height = "30%"
controllCommand_window_width = "30%"
controllCommand_window_positionX = "70%"
controllCommand_window_positionY = "70%"

---------------------------------------------------------------------------------------

local spGetUnitDefID = Spring.GetUnitDefID
local spGetSelectedUnits = Spring.GetSelectedUnits


if not WG.SelectedCommand then WG.SelectedCommand ={} end
playerID= Spring.GetMyPlayerID()
if not WG.SelectedCommand[playerID] then WG.SelectedCommand[playerID] ={} end
boolQueueOverride = false

BaseCol={0.1,0.8,0.8,1}
WeapCol={0.3,0.6,0.8,1}
BeanCol={0.3,0.6,0.8,0.6}
UpgCol={0.1,0.5,0.6,1}
texCol={0,0,0,1}

selectedTextColor=	 {160/255, 238/255, 255/255, 0.85}	
unselectedTextColor= {1/255, 28/255, 75/255, 1}
--selectedTextColor={math.random(0,255)/255, math.random(0,255)/255, math.random(0,255)/255, 1}	
holoCommandCol={163/255, 229/255, 243/255, 0.65}	
backgroundColExtended = {90/255, 174/255, 208/255, 0.5}
--lowerMenueBackgroundCol={0/255, 43/255, 109/255, 0.45} 
lowerMenueBackgroundCol={40/255, 121/255, 177/255, 0.4} 
backgroundColExtended=lowerMenueBackgroundCol
defaultBorderColor={0, 0, 0.1, 1}
defaultJourneymanBorderColor={236/255, 229/255, 226/255, 0.856}

genericActiveColor = {163/255, 229/255, 243/255, 0.75}
genericFocusColor={163/255, 229/255, 243/255, 0.5}
genericStateTriColor = {
	[1]={245/255,64/255,9/255, 0.6},
	[2]={24/255,238/255,191/255, 0.6},
	[3]={27/255,234/255,31/255, 0.6}
}

function ActionCommand(self, x, y, button, mods) 
		selectedUnits = Spring.GetSelectedUnits()
		if not selectedUnits  or type(selectedUnits) ~= "table" or type(selectedUnits[1]) ~= "number" then Spring.Echo("Abort ActionCommand" );return end
	
		local index = Spring.GetCmdDescIndex(self.cmdID)
		if index then
			local left, right = (button == 1), (button == 3)
			local alt, ctrl, meta, shift = mods.alt, mods.ctrl, mods.meta, mods.shift
			Spring.SetActiveCommand(index, button, left, right, alt, ctrl, meta, shift)
		end
		self:SetSelected(true)

end

local boolGlobalShiftOverrideActive= false
local boolOverrideShiftOn = false
function StateCommand(self, x, y, button, mods)
	-- Spring.Echo("StateCommand:Cloak")
--	if not self.boolSelectable or self.boolSelectable == false then Spring.Echo("Non-Selectable");return end

  local opt = {}
  if mods.alt   then push(opt,"alt")   end
  if mods.ctrl  then push(opt,"ctrl")  end
  if mods.meta  then push(opt,"meta")  end
  if mods.shift then push(opt,"shift") end
  
  if boolOverrideShiftOn == true then mods.shift = boolOverrideShiftOn end


	selectedUnits = Spring.GetSelectedUnits()
	if not selectedUnits  or type(selectedUnits) ~= "table" or type(selectedUnits[1]) ~= "number" then return end
	
	states = Spring.GetUnitStates(selectedUnits[1])	
	
	-- CLOAK
		
	if self.cmdID == CMD.CLOAK and states.cloak then		
	Spring.Echo("State Command Cloak")
	paramTable={[1]=0}
	if state.cloak == false then  paramTable={[1]=1};	end
	
		if states.cloak == true  then 			 
			self:SetCaption( "CLOAK")
		else
			self:SetCaption( "REVEAL")
		end
		
		self:SetState( paramTable[1] + 1 , 2)	
		state = Spring.GetUnitStates(selectedUnits[1])
	
			for i=1,#selectedUnits do	
				Spring.GiveOrderToUnit(selectedUnits[i], CMD.CLOAK, paramTable, opt)
			end
	end

	--FIRE_STATE
	
	if self.cmdID == CMD.FIRE_STATE then --and states.firestate > -1 then
		Spring.Echo("State Command FIRE_STATE"..states.firestate)
		self:SetState( inc(states.firestate ) , 3)
		state = Spring.GetUnitStates(selectedUnits[1])			
		paramTable={[1]= inc(state.firestate)%3}
		
		stateCaption = {[0]="|FIRE STATE \n HOLD\n FIRE",[1]= "|FIRE STATE \n RETURN\n FIRE",[2]="|FIRE STATE \n FIRE\n AT\n WILL",[3]="|FIRE STATE \n OPEN\n UP" }
		self:SetCaption( upByRow(stateCaption[paramTable[1]],1))
		
		for i=1,#selectedUnits do			
			Spring.GiveOrderToUnit(selectedUnits[i], CMD.FIRE_STATE, paramTable, opt)
		end
	end		
	
	if self.cmdID == CMD.MOVE_STATE then

		self:SetState( inc(states.movestate) , 3)
		state = Spring.GetUnitStates(selectedUnits[1])			
		paramTable={[1]= inc(state.movestate)%3}
			Spring.Echo("MoveState changed to ".. self.currentState)
		stateCaption = {[0]="|MOVE MODE\nHOLD\nPOSITION",[1]= "|MOVE MODE\nAREA\nDEFENSE",[2]="|MOVE MODE\nSEARCH&\nDESTROY"}
		self:SetCaption( stateCaption[paramTable[1]])
		
		for i=1,#selectedUnits do			
			Spring.GiveOrderToUnit(selectedUnits[i], CMD.MOVE_STATE, paramTable, opt)
		end
	end	
	
	--Modifier
	if self.name == "statebutton_optshift" and states.opt_shift then
		boolGlobalShiftOverrideActive=true
		boolOverrideShiftOn = not boolOverrideShiftOn
		self:SetState( inc(states.opt_shift) , 1)
	end	

	if self.cmdID == CMD.REPEAT and states["repeat"] ~= nil then		
		paramTable={[1]= 1 } 	
		
		if states["repeat"] == true  then 
			paramTable={[1]= 0 }	
			self:SetCaption("|MONO\nCOMMAND")
		else
			self:SetCaption("|REPEAT\nCOMMAND")	
		end
		
		self:SetState( 	paramTable[1] , 2)	
		state = Spring.GetUnitStates(selectedUnits[1])

		for i=1,#selectedUnits do	
			Spring.GiveOrderToUnit(selectedUnits[i], CMD.REPEAT, paramTable, opt)
		end
	end
end




--[[extendedMenue[CMD.RECLAIM] ={		
	triStrip={
		{x= 0, y = 0},			
		{x= 160, y = 20},
		{x= 0, y = 70},
		{x= 160, y = 70},		
		{x= 220, y = 70}		
	},
	
	caption="RECLAIM",
	
	cmdID = CMD.RECLAIM ,
	name= "orderbutton_reclaim",
	OnMouseUp = {ActionCommand}
}
--]]
--[[extendedMenue[CMD.RESTORE] ={		
	triStrip={	
		{x= 0	, y = 10},
		{x= 160	, y = 10},			
		{x= 0	, y = 50},
		{x= 180	, y = 50},		
		{x= 220	, y = 60}		
	},
	
	caption= "RESTORE",	
	cmdID = CMD.RESTORE ,
	name= "orderbutton_restore",
	OnMouseUp = {ActionCommand}
}	--]]


MainMenue={}

function getCommandTarget()
	x,z=Spring.GetMouseState()
	return Spring.TraceScreenRay(x,z)
end

function formHexagonTripStrip(offx,offy, scale)
	offset ={x=offx, y= offy}

return{
		{x= -50, y = 0},			
		{x= -25, y = 50},
		{x= 25, y = 50},
		{x= 50, y = 0},			
		{x= 25, y = -50},			
		{x= -25, y = -50},

		offset= offset,
		scale = scale,
		}	
end

local strip = formHexagonTripStrip( 10, 0 , 0.75)

MainMenue[CMD.ATTACK] ={		
	triStrip = strip,
	outline = strip,
	activeColor={163/255, 229/255, 243/255, 0.75},
	backgroundColor = lowerMenueBackgroundCol,
	caption=	"|ATTAC",
	
	cmdID = CMD.ATTACK ,
	name= "orderbutton_attack",
	OnMouseUp = {ActionCommand}
}

local strip = formHexagonTripStrip( 0, 0 , 1)
MainMenue[CMD.STOP] ={
	triStrip=strip,
	outline = strip,
	activeColor={58/255, 172/255, 226/255, 0.75}	,
	backgroundColor = lowerMenueBackgroundCol,
	caption="|STOP",	
	
	cmdID = CMD.STOP ,
	name= "orderbutton_stop",
	OnMouseUp = {ActionCommand}
}	
local strip = formHexagonTripStrip( 0, 0 , 1)

MainMenue[CMD.MOVE] ={
	triStrip ={},
	outline = strip,
	activeColor={35/255, 124/255, 166/255, 0.75}		,
	backgroundColor = lowerMenueBackgroundCol,
	caption=upByRow("|MOVE",2),
	
	cmdID = CMD.MOVE ,
	name= "orderbutton_move",
	OnMouseUp = {ActionCommand}
}	
local strip = formHexagonTripStrip( 0, 0 , 1)
MainMenue[CMD.FIRE_STATE] ={		
	triStrip ={},
	outline = strip,
	activeColor={52/255, 167/255, 222/255, 0.75},
	backgroundColor = lowerMenueBackgroundCol,
	caption=upByRow("|FIRE STATE ",3),
	stateOffset= 1,
	cmdID = CMD.FIRE_STATE ,
	name= "statebutton_fire",
	OnMouseUp = {StateCommand}
}	

local strip = formHexagonTripStrip( 0, 0 , 1)
MainMenue[CMD.REPEAT] ={
	triStrip ={},
	outline = strip,
	activeColor={52/255, 167/255, 222/255, 0.75}	,
	backgroundColor = lowerMenueBackgroundCol,
	caption="|REPEAT\nCOMMAND",
	stateOffset= 1,
	
	cmdID = CMD.REPEAT ,
	name= "statebutton_repeat",
	OnMouseUp = {StateCommand}
}	

local strip = formHexagonTripStrip( 0, 0 , 1)
MainMenue[CMD.MOVE_STATE] ={
	triStrip ={},
	outline = strip,
	activeColor={35/255, 124/255, 166/255, 0.75},
	backgroundColor = lowerMenueBackgroundCol,
	caption= "|MOVE MODE\nSEARCH&\nDESTROY",
	stateOffset= 1,
	
	cmdID = CMD.MOVE_STATE ,
	name= "statebutton_move",
	OnMouseUp = {StateCommand}
}	

local strip = formHexagonTripStrip( 0, 0 , 1)
MainMenue[CMD.REPAIR] ={
	triStrip ={},
	outline = strip,
	activeColor={163/255, 229/255, 243/255, 0.75},
	backgroundColor = lowerMenueBackgroundCol,
	caption= upByRow("|REPAIR ",4),
	
	cmdID = CMD.REPAIR ,
	name= "orderbutton_repair",
	OnMouseUp = {ActionCommand}
}	

local strip = formHexagonTripStrip( 0, 0 , 1)
MainMenue[CMD.PATROL] ={
	triStrip ={},
	outline = strip,
	activeColor={52/255, 167/255, 222/255, 0.75},
	backgroundColor = lowerMenueBackgroundCol,
	caption=upByRow("|PATROL",4),
	
	cmdID = CMD.PATROL ,
	name= "orderbutton_patrol",
	OnMouseUp = {ActionCommand}
}	

local strip = formHexagonTripStrip( 0, 0 , 1)
MainMenue[CMD.GUARD] ={
	triStrip ={},
	outline = strip,
	
	caption="|GUARD",
	
	cmdID = CMD.GUARD ,
	name= "orderbutton_guard",
	OnMouseUp = {ActionCommand},
}	


MainMenue[CMD.LOAD_UNITS] ={
	triStrip ={},
	outline = strip,
	caption =	"LOAD",	
	name = "orderbutton_load",
	cmdID = CMD.LOAD_UNITS,
	OnMouseUp = {ActionCommand}
}
MainMenue[CMD.UNLOAD_UNITS] ={
	triStrip ={},
	outline = strip,
	
	caption=	"DROP",	
	cmdID = CMD.UNLOAD_UNITS ,
	name= "orderbutton_unload",
	OnMouseUp = {ActionCommand}
	
}

MainMenue[CMD.CLOAK] ={
	triStrip ={},
	outline = strip,
	name = "statebutton_cloak",
	caption= "CLOAK",
	OnMouseUp = {StateCommand}	
}	

MainMenue[CMD.OPT_SHIFT] ={
	triStrip ={},
	outline = strip,
	caption= "QUEUE",	
	cmdID = CMD.OPT_SHIFT ,
	name= "statebutton_optshift",
	OnMouseUp= {StateCommand}
}



function setDefaultCommandButtonAttributes()
	
	--generic attributes

	
	--defaults
	for comandID,MenueDescriptor in pairs(MainMenue) do
		MenueDescriptor.focusColor = 	MenueDescriptor.focusColor or	{52/255, 167/255, 222/255, 0.75}
		MenueDescriptor.backgroundColor = 	MenueDescriptor.backgroundColor or	 {0.1, 0.2, 0.3, 0.5}
		MenueDescriptor.selectedTextColor=		 	 		MenueDescriptor.selectedTextColor or	selectedTextColor --selectedTextColor
		MenueDescriptor.unselectedTextColor=		 MenueDescriptor.unselectedTextColor or	unselectedTextColor
		MenueDescriptor.focusColor=		 	 		genericFocusColor
		MenueDescriptor.activeColor =	MenueDescriptor.activeColor or	 genericActiveColor
		MenueDescriptor.stateColors = genericStateTriColor
		MenueDescriptor.boolBorder 		= MenueDescriptor.boolBorder --	or true
		MenueDescriptor.borderType 		=  static --MenueDescriptor.borderType or "organic"
		MenueDescriptor.borderColor 		= MenueDescriptor.borderColor or  defaultBorderColor-- defaultJourneymanBorderColor
	end	
	
	
end



function updateAllButtonsInside()
	updateRequired = true
end

bRelativePixelSize = false
function widget:Initialize()
	assert(true == false)
	--Spring.SendCommands("hideinterface 1")
	-- setup Chili
	Chili = WG.Chili
	Button = Chili.Button
	Label = Chili.Label
	Window = Chili.Window
	StackPanel = Chili.StackPanel
	Grid = Chili.Grid
	TextBox = Chili.TextBox
	Image = Chili.Image
	Progressbar = Chili.Progressbar
	Panel = Chili.Panel
	screen0 = Chili.Screen0
	
	function createHabanero(HabaneroDescriptor, Parent )
		outline ={}		
		if not HabaneroDescriptor.outline then HabaneroDescriptor.outline = {}end


		return 	Chili.HabaneroButton:New{
			outline = HabaneroDescriptor.outline,
			triStrip=	HabaneroDescriptor.triStrip	,
			name= HabaneroDescriptor.name,
			caption= HabaneroDescriptor.caption,
			cmdID = HabaneroDescriptor.cmdID,
			parent= Parent,
			backgroundColor = HabaneroDescriptor.backgroundColor,
			activeColor = HabaneroDescriptor.activeColor,
			focusColor = HabaneroDescriptor.focusColor,
			textColor = HabaneroDescriptor.unselectedTextColor, 
			selectedTextColor = HabaneroDescriptor.selectedTextColor, 
			unselectedTextColor = HabaneroDescriptor.unselectedTextColor, 
			stateColors = HabaneroDescriptor.stateColors,
			OnMouseUp = HabaneroDescriptor.OnMouseUp,
			boolBorder = HabaneroDescriptor.boolBorder,
			borderType = HabaneroDescriptor.borderType,
			borderColor = HabaneroDescriptor.borderColor
		}
		
	end

	
	setDefaultCommandButtonAttributes()
	
		
	Habaneros={ }
	
	controllCommand_window = Window:New{
		padding = {3,3,3,3,},
		dockable = true,
		caption = '',
		textColor = {0.9,1,1,0.7},
		name = "controllCommand_window",
		x = controllCommand_window_positionX, 
		y = controllCommand_window_positionY,
		width = controllCommand_window_width,
		height = controllCommand_window_height,
		parent = screen0,
		draggable = false,
		tweakDraggable = true,
		tweakResizable = true,
		resizable = false,
		dragUseGrip = false,
		dockable = true,
		color = {0,0,0,0},
		
		children = {			
		},
	}
	
	main_menu_grid = Grid:New{
		x= 0,
		y = 20,
		padding = {5,5,5,5},
		itemPadding = {0, 0, 0, 0},
		itemMargin = {0, 0, 0, 0},
		width = '100%',
		height = '100%',
		resizeItems = true,	
		autosize=true,		
		orientation = 'vertical',
		centerItems = false,
		columns = 5,
		rows= 3,
		parent =controllCommand_window,
		children={			
		}
	}
		
	for comandID,MenueDescriptor in pairs(MainMenue) do
		Habaneros[comandID] = createHabanero(
		MenueDescriptor,
		main_menu_grid
		)		
		Habaneros[comandID]:Init(bRelativePixelSize)
	end
	
end


function forAllButtonsDo( functionToExecute )
	local executable= functionToExecute

	for i= 1, #main_menu_grid.children do
		main_menu_grid.children[i] = executable(main_menu_grid.children[i])	
	end	
end



function widget:MouseRelease(x, y, mButton)
		-- Only left click
		Spring.Echo(mButton)
	if (mButton == 1) then 	
		forAllButtonsDo(function(self) self.boolSelected = false; self:setCurrentColorByState(); return self; end)	
	end
	
end

function TraverseCmd(cmd)
	bIsStateButton = false
	bIsOrderButton = false
	if UnitDefNames[cmd.name] then
		-- UnitBuyButton
	elseif #cmd.params > 1 then
		-- state
		bIsStateButton = true
	else
		-- order
		bIsOrderButton = true
	end
	
	if not bIsStateButton and not bIsOrderButton then return end
		
	for i= 1, #main_menu_grid.children do
		local command = main_menu_grid.children[i]
		if cmd.id == command.cmdID then
			if bIsOrderButton == true or bIsStateButton == true then
				main_menu_grid.children[i]:SetSelectable(true)
			end
		end
	end	

	
end

local shiftKeyAscii = 15
function widget:KeyReleased(key)
	if key == shiftKeyAscii then
	boolGlobalShiftOverrideActive =false
	end
end
function widget:KeyPressed(key)
	if key == shiftKeyAscii then
	boolGlobalShiftOverrideActive =false
	end
end


function ParseCmds()
	forAllButtonsDo(function(self) self:SetSelectable(false); return self; end)
	-- go over all menuebuttons and find them inside the active cmds 
	--set either
	--active
	-- passive
	--selected
	--updateStateButtonsColoursAndCaption
	
	local cmds = Spring.GetActiveCmdDescs()
	for _,cmd in ipairs(cmds) do
		if cmd.name ~= '' and not (ignoreCMDs[cmd.name] or ignoreCMDs[cmd.action]) then
			TraverseCmd(cmd)
		end
	end
	
	forAllButtonsDo(function(self) self:setCurrentColorByState(); return self; end)
end

function widget:GameFrame(n)

	if n % 8 == 0 then 
		updateRequired= true
	end
end

function widget:CommandsChanged()
	updateRequired = true -- the active cmd descs haven't changed yet; wait until the next widget:Update
	selectedUnits= Spring.GetSelectedUnits()
	if not selectedUnits or #selectedUnits < 1 then
		forAllButtonsDo(function(self) self:SetSelectable(false); self:SetSelected(false); return self; end)
	end
end


function widget:Update()

	if  updateRequired == true then
		ParseCmds()
		updateRequired = false
	end
end


function widget:Shutdown()
	Spring.SendCommands("hideinterface 0")
end
