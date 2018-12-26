local armorDefs = {
	satellite = {
	},
	
}

local DEFS = _G.DEFS
for unitName, unitDef in pairs(DEFS.unitDefs) do
	local cp = unitDef.customparams
	local basicType = cp.baseclass

	local typeString  = basicType

end


local system = VFS.Include('gamedata/system.lua')  

return system.lowerkeys(armorDefs)
