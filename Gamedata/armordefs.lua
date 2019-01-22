local armorDefs = {
	satellite = {
	"scansatellite",
	"comsatellite"
	},
	
}

local DEFS = _G.DEFS
for unitName, unitDef in pairs(DEFS.unitDefs) do
	local cp = unitDef.customparams
	local basicType = cp.baseclass

	local typeString  = basicType
end


for categoryName, categoryTable in pairs(armorDefs) do
  local t = {}
  for _, unitName in pairs(categoryTable) do
    t[unitName] = 1
  end
  armorDefs[categoryName] = t
end


local system = VFS.Include('Gamedata/system.lua')  

return system.lowerkeys(armorDefs)
