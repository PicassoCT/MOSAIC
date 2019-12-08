function gadget:GetInfo()
	return {
		name = "Zeppelin Physics",
		desc = "Forces Zeppelin-type units to obey their cruisealt and prevents them from pitching",
		author = "Анархид",
		date = "2.2.2009",
		license = "GPL2.1",
		layer = 50,
		enabled = true
	}
end

zeppelins={
		[UnitDefNames["satellitescan"].id]=true,	
		[UnitDefNames["satellitegodrod"].id]=true,	
		[UnitDefNames["satelliteanti"].id]=true,	
		}
zeppelin={}

--SYNCED
if (gadgetHandler:IsSyncedCode()) then

 function gadget:Initialize()
	 for id,unitDef in pairs(UnitDefs) do
		if unitDef.myGravity == 0 and
		   unitDef.maxElevator == 0 then
			Spring.Echo(unitDef.name.." is a zeppelin with cruisealt "..unitDef.wantedHeight)
			zeppelins[id]={
				pitch=unitDef.maxPitch,
				alt=unitDef.wantedHeight,
				name= unitDef.name,
			}
		end
	 end
 end

 function gadget:UnitCreated(UnitID, whatever)
 	local type=Spring.GetUnitDefID(UnitID);
	if zeppelins[type] then
		zeppelin[UnitID]=type
	end
 end

 function gadget:UnitDestroyed(UnitID, whatever)
 	local type=Spring.GetUnitDefID(UnitID);
	if zeppelins[type] then
		zeppelin[UnitID]=nil
	end
 end

 local function sign(num)
 if num < 0 then return -1 end
 return 1
 end

 function gadget:GameFrame(f)
	if f%20<1 then
		for zid,zepp in pairs(zeppelin) do
			local x,y,z=Spring.GetUnitVectors(zid)
			local ux, uy, uz= Spring.GetUnitPosition(zid)
			local vx, vy, vz= Spring.GetUnitVelocity(zid)
			local dx, dy, dz=Spring.GetUnitDirection(zid)
			local altitude=uy-Spring.GetGroundHeight(ux,uz)
			local wanted=zeppelins[zepp].alt
			if math.abs(altitude-wanted)>10 then
				Spring.SetUnitVelocity(zid,vx,vy+sign(wanted-altitude),vz)
			end

			if dy>0 then
				local h=math.asin(-dx/math.sqrt(dx*dx+dz*dz))
				Spring.SetUnitRotation(zid,0,h,0)
			end
		end--for
	end--iff
  end--fn

end--sync