function gadget:GetInfo()
	return {
		name = "Aersoldrones Gadget",
		desc = "Keeps Track of Aerosoldrones ",
		author = "Picasso",
		date = "3rd of May 2010",
		license = "GPL3",
		layer = 4,
		version = 1,
		enabled = true
	}
end

if (not gadgetHandler:IsSyncedCode()) then
    return false
end

	VFS.Include("scripts/lib_OS.lua")
	VFS.Include("scripts/lib_UnitScript.lua")
	VFS.Include("scripts/lib_Animation.lua")
	VFS.Include("scripts/lib_Build.lua")
	VFS.Include("scripts/lib_mosaic.lua")
	
	local GameConfig = getGameConfig()
	local UnitDefNames = getUnitDefNames(UnitDefs)
	
	aeroSolDroneDefID = UnitDefNames["air_copter_aerosol"].id
	aeroSolUnits = {}
	
function gadget:UnitCreated(unitID, unitDefID)
	if aeroSolDroneDefID == unitDefID then
		aeroSolUnits[unitID] = unitDefID
	end
end

function gadget:UnitDestroyed(unitID)
	if aeroSolUnits[unitID] then aeroSolUnits[unitID] = nil end
end

function gadget:Initialize()
	if not GG.SelectedAerosol then GG.SelectedAerosol = {} end
end

TaeroSolAffectableUnits= getAersolAffectableUnits()

function gadget:GameFrame(n)

	if n % 33 == 1 then
		for unitID, unitDefID in pairs(aeroSolUnits) do
			if unitID and unitDefID and isUnitActive(unitID) == true then
					aerosolTypeOfUnit  = getUnitVariable(unitID, "aerosoltype")
					if GG.SelectedAerosol then
						aerosolTypeOfUnit =  GG.SelectedAerosol[unitID]
					end
					
					-- if unit is activate 
					if getUnitValueEnv(unitID, "ACTIVATION") == 1 then
					
						T = getAllNearUnit(unitID, GameConfig.aerosolDistance)
						process(T,
								function(id)
									if TaeroSolAffectableUnits[Spring.GetUnitDefID(id)] and not GG.AerosolAffectedCivilians[id] then
										setCivilianBehaviourMode(id, true, aerosolTypeOfUnit)
										if not GG.AerosolAffectedCivilians then GG.AerosolAffectedCivilians = {} end
										GG.AerosolAffectedCivilians[id] = aerosolTypeOfUnit 
									end
								end
								)
					end
			end
		end
	end
end

