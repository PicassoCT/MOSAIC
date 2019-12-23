--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

function widget:GetInfo()
  return {
    name      = "debugging_gui",
    desc      = "GUI for debuggin",
    author    = "PicassoCT",
    date      = "WIP",
    license   = "GPL",
    layer     = 1,
    enabled   = false,  --  loaded by default?
	hidden = true
  }
end


--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

-- gui elements
local window0
local window01
local gridWindow0
local gridWindow1
local windowImageList
local window1
local window2
local window3
local window4

function widget:Initialize()
	Chili = WG.Chili

	local function ToggleOrientation(self)
		local panel = self:FindParent"layoutpanel"
		panel.orientation = ((panel.orientation == "horizontal") and "vertical") or "horizontal"
		panel:UpdateClientArea()
	end
	command = "SetGameState:!"

	--------------------------------------------------------------------------------
	--------------------------------------------------------------------------------

	--------------------------------------------------------------------------------
	--------------------------------------------------------------------------------

	local cs = {
		Chili.Button:New{
			x      = 20,
			y      = 20,
			caption = "Normal",
			OnClick = {function(self)
						self.font:SetColor(0,1,0,1);
						Spring.SendLuaRulesMsg(command:gsub("!", "normal"));
						end},
		},
			Chili.Button:New{
			x      = 20,
			y      = 20,
			caption = "LaunchLeak",
			OnClick = {function(self) 
					Spring.SendLuaRulesMsg(command:gsub("!", "launchleak"));
					self.font:SetColor(0,1,1,1);
					end},
		},	
		Chili.Button:New{
			x      = 20,
			y      = 20,
			caption = "Anarchy",
			OnClick = {function(self) 
					Spring.SendLuaRulesMsg(command:gsub("!", "anarchy"));
					self.font:SetColor(0,1,1,1);
					end},
					
		},
			Chili.Button:New{
			x      = 20,
			y      = 20,
			caption = "PostLaunch",
			OnClick = {function(self) 
					Spring.SendLuaRulesMsg(command:gsub("!", "postlaunch"));
					self.font:SetColor(1,0.5,0.5,1);
					end},
		},
		Chili.Button:New{
			x      = 20,
			y      = 20,
			caption = "Pacification",
			OnClick = {function(self) 
					Spring.SendLuaRulesMsg(command:gsub("!","pacification"));
					self.font:SetColor(1,0.5,0.5,1);
					end},
		},
		
	}

	-- we need a container that supports margin if the control inside uses margins
	window01 = Chili.Window:New{
		caption = "Game States:",
		x = 200,
		y = 200,
		clientWidth  = 200,
		clientHeight = 200,
		parent = Chili.Screen0,
	}

	local panel1 = Chili.StackPanel:New{
		width = 200,
		height = 200,
		--resizeItems = false,
		x=0, right=0,
		y=0, bottom=0,
		margin = {10, 10, 10, 10},
		parent = window01,
		children = cs,
	}

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
end --Initialize


function widget:Update()

end


function widget:Shutdown()
	window01:Dispose()
	
end

