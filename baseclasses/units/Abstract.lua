-- Abstract class ----
local Abstract = Unit:New{
	footprintX			= 1,
	footprintZ 			= 1,
	iconType			= "none",
	moveState			= 0, -- Hold Position
	onoffable           = true,
	
	customparams = {
		baseclass		= "Abstract",
    },
}

return {
	Abstract = Abstract
}
