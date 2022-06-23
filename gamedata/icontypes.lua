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
    distance = 200,
},
assembly = {
bitmap = "icons/assembly.png",
size =1.5,
radiusadjust = true,
    distance = 200,
},

civilianagent = {
bitmap = "icons/civilianagent.png",
size =1.5,
radiusadjust = true,
    distance = 200,
},
doubleagent = {
bitmap = "icons/doubleagent.png",
size =1.5,
radiusadjust = true,
    distance = 200,
},
house = {
bitmap = "icons/house.png",
size =2,
radiusadjust = true,
    distance = 200,
},
interrogationicon = {
bitmap = "icons/interrogationicon.png",
size =1.5,
radiusadjust = true,
    distance = 200,
},
stealvehicleicon = {
bitmap = "icons/StealVehicleIcon.png",
size =1.5,
radiusadjust = true,
    distance = 200,
},
nimrod = {
bitmap = "icons/nimrod.png",
size =1.5,
radiusadjust = true,
    distance = 200,
},
operativeasset = {
bitmap = "icons/operativeasset.png",
size =1.5,
radiusadjust = true,
    distance = 200,
},
operativeinvestigator = {
bitmap = "icons/operativeinvestigator.png",
size =1.5,
radiusadjust = true,
    distance = 200,
},
operativepropagator = {
bitmap = "icons/operativepropagator.png",
size =1.5,
radiusadjust = true,
    distance = 200,
},
propagandaserver = {
bitmap = "icons/propagandaserver.png",
size =1.5,
radiusadjust = true,
    distance = 200,
},
protagonsafehouse = {
bitmap = "icons/protagonsafehouse.png",
size =1.5,
radiusadjust = true,
    distance = 200,
},
raidicon = {
bitmap = "icons/raidicon.png",
size =1.5,
radiusadjust = true,
    distance = 200,
},
recruitcivilian = {
bitmap = "icons/recruitcivilian.png",
size =1.5,
radiusadjust = true,
    distance = 200,
},
truck = {
bitmap = "icons/truck.png",
size =1.5,
radiusadjust = true,
    distance = 200,
},
}
--TODO: Make context dependent
for i=1,nrOfCivilianTypes do
	iconTypes["civilian_arab"..i] = {
	bitmap = "icons/civilian.png",
	size =1.5,
	radiusadjust = true,
		distance = 200,
	}
end

for i=1,nrOfTruckTypes do
	iconTypes["truck_arab"..i] = {
	bitmap = "icons/truck.png",
	size =1.5,
	radiusadjust = true,
		distance = 200,
	}
end

return iconTypes