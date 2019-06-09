-- Author: Tobi Vollebregt
-- License: GNU General Public License v2

-- Do not limit units spawned through LUA! (infantry that is build in platoons,
-- deployed supply trucks, deployed guns, etc.)

-- On easy, limit both engineers and buildings until I've made an economy
-- manager that can tell the AI whether it has sufficient income to build
-- (and sustain) a particular building (factory).
-- (AI doesn't use resource cheat in easy)

-- On medium, limit engineers (much) more then on hard.

-- On hard, losen restrictions a bit more.

-- Format: unitname = { easy limit, medium limit, hard limit }
local unitLimits = UnitBag{
	-- engineers
	operativepropagator        = { 1, 1, 3 },
	operativeinvestigator = { 1, 1, 3 },
	
}

-- Convert to format expected by C.R.A.I.G., based on the difficulty.
local difficultyTable = { easy = 1, medium = 2, hard = 3 }
local difficultyIndex = difficultyTable[gadget.difficulty] or 3
gadget.unitLimits = {}
for k,v in pairs(unitLimits) do
	if (type(v) == "table") then
		gadget.unitLimits[k] = v[difficultyIndex]
	else
		gadget.unitLimits[k] = v
	end
end
