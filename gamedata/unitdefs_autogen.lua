local morphInclude = VFS.Include("luarules/configs/morph_defs.lua")

local getSideName = VFS.Include("luarules/includes/sides.lua")

local function getTemplate()
	return  	{
					canmove = true, -- required to pass orders
					category = "NOTARGET",
					explodeas = "noweapon",
					footprintx = 1,
					footprintz = 1,
					idleautoheal = 0,
					maxdamage = 1e+06,
					maxvelocity = 0.01,
					movementclass = "QUADRUPED", -- as is this
					objectname = "emptyObjectIsEmpty.S3O",
					script = "null.lua",
					selfdestructas = "noweapon",
					shownanoframe			= false,
					shownanospray			= false,
					stealth = true,
					
					customparams = {
						isupgrade			= true,
						dontcount			= 1,
						normaltex			= "",
					},
				}
end

local function isFactory(unitDef)
	local yardmap = unitDef.yardmap
	local velocity = unitDef.maxVelocity or unitDef.maxvelocity
	local workerTime = unitDef.workerTime or unitDef.workertime
	return yardmap and (not velocity or velocity <= 0) and workerTime and workerTime > 0
end

for unitName, unitMorphs in pairs(morphInclude) do
	local unitDef = UnitDefs[unitName]
	if not unitDef then
		Spring.Echo("unitdefs_autogen.lua ERROR", unitName, unitDef) -- useful to debug bad/missing unitdefs causing this code to crash(!)
	elseif isFactory(unitDef) then
		for i = 1, #unitMorphs do
			local unitMorphData = unitMorphs[i]
			local intoDef = UnitDefs[unitMorphData.into] or {}
			local autoUnit = getTemplate()
			local tmpSide = getSideName(unitName, "protagon")
			local autoUnitName = tmpSide .. "_morph_" .. unitName .. "_" .. unitMorphData.into
			local buildOptions = unitDef.buildoptions or unitDef.buildOptions or {}
			unitDef.buildoptions = buildOptions
			autoUnit.name = "Become a "..intoDef.name
			autoUnit.description = intoDef.description
			autoUnit.buildcostmetal = unitMorphData.metal
			autoUnit.buildcostenergy = unitMorphData.energy
			autoUnit.buildpic = intoDef.buildpic
			if autoUnit.buildpic == '<NAME>.png' then
				autoUnit.buildpic = unitMorphData.into .. '.png'
			end
			autoUnit.buildtime = (unitDef.workerTime or unitDef.workertime) * unitMorphData.time
			autoUnit.side = intoDef.side
			table.insert(buildOptions, autoUnitName)
			UnitDefs[autoUnitName] = autoUnit
		end
	end
end
