nrOfCivilianTypes = 4
nrOfTruckTypes = 8

local iconTypes = {
  default = {
    size = 1,
    radiusadjust = true,
  },
  

antagonsafehouse = {
bitmap = "icons/antagonsafehouse.png",
size =1.5,
radiusadjust = true,
    distance = 100,
},
assembly = {
bitmap = "icons/assembly.png",
size =1.5,
radiusadjust = true,
    distance = 100,
},

civilianagent = {
bitmap = "icons/civilianagent.png",
size =1.5,
radiusadjust = true,
    distance = 100,
},
doubleagent = {
bitmap = "icons/doubleagent.png",
size =1.5,
radiusadjust = true,
    distance = 100,
},
house = {
bitmap = "icons/house.png",
size =2,
radiusadjust = true,
    distance = 100,
},
interrogationicon = {
bitmap = "icons/interrogationicon.png",
size =1.5,
radiusadjust = true,
    distance = 100,
},
stealvehicleicon = {
bitmap = "icons/StealVehicleIcon.png",
size =1.5,
radiusadjust = true,
    distance = 100,
},
nimrod = {
bitmap = "icons/nimrod.png",
size =1.5,
radiusadjust = true,
    distance = 100,
},
operativeasset = {
bitmap = "icons/operativeasset.png",
size =1.5,
radiusadjust = true,
    distance = 100,
},
operativeinvestigator = {
bitmap = "icons/operativeinvestigator.png",
size =1.5,
radiusadjust = true,
    distance = 100,
},
operativepropagator = {
bitmap = "icons/operativepropagator.png",
size =1.5,
radiusadjust = true,
    distance = 100,
},
propagandaserver = {
bitmap = "icons/propagandaserver.png",
size =1.5,
radiusadjust = true,
    distance = 100,
},
protagonsafehouse = {
bitmap = "icons/protagonsafehouse.png",
size =1.5,
radiusadjust = true,
    distance = 100,
},
raidicon = {
bitmap = "icons/raidicon.png",
size =1.5,
radiusadjust = true,
    distance = 100,
},
recruitcivilian = {
bitmap = "icons/recruitcivilian.png",
size =1.5,
radiusadjust = true,
    distance = 100,
},
truck = {
bitmap = "icons/truck.png",
size =1.5,
radiusadjust = true,
    distance = 100,
},
}
--TODO: Make context dependent
for i=1,nrOfCivilianTypes do
	iconTypes["civilian_arab"..i] = {
	bitmap = "icons/civilian.png",
	size =1.5,
	radiusadjust = true,
		distance = 100,
	}
end

for i=1,nrOfTruckTypes do
	iconTypes["truck_arab"..i] = {
	bitmap = "icons/truck.png",
	size =1.5,
	radiusadjust = true,
		distance = 100,
	}
end

return iconTypes