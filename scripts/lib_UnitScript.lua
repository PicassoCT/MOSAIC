VFS.Include("scripts/lib_type.lua", nil, VFS.DEF_MODE)

--[[
Section: Team Information Getters/Setters 
Section: Unit Information Getters/Setters 
Section: Initializing Functions
Section: Landscape/Pathing Getter/Setters
Section: Syntax additions and Tableoperations
Section: Geometry/Math functions
Section : Code Generation 
Section : String Operations
Section: Debug Tools 
Section: Random 
Section: Physics 
Section: Sound
Section: Ressources
Section: Unit Commands
Section: Sfx Operations
]]
--[[
This library is free software; you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation; either version 2 of the License, or
(at your option) any later version.

This library is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
GNU General Public License for more details.

You should have received a copy of the GNU General Public License
along with this library; if not, write to the Free Software
Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston,
MA 02110-1301, USA.


]] -- test

-------------- DEBUG HEADER
-- Central Debug Header Controlled in UnitScript
-------------- DEBUG HEADER
lib_boolDebug = false --
if GG then
	GG.BoolDebug = lib_boolDebug
end
--======================================================================================
--Section: Team Information Getters/Setters 
--======================================================================================
--> get all EnemyTeams of a teamID 
function getAllEnemyTeams(teamID, boolIncludeGaia)
gaiaTeamID= Spring.GetGaiaTeamID()

return process(Spring.GetTeamList(),
			function(tid)
				if Spring.AreTeamsAllied(tid,teamID)==false and
				boolIncludeGaia == true or boolIncludeGaia == false and tid ~= gaiaTeamID then
					return tid
				end			
			end
			) or {}

end


--> Grabs every Unit in a circle, filters out the unitid or teamid if given
function getAllInCircle(x, z, Range, unitID, teamid)
	if not x or not z then
		return {}
	end
	if not Range then assert(Range) end
	
	T = {}
	if teamid then
		T = Spring.GetUnitsInCylinder(x, z, Range, teamid)
	else
		T = Spring.GetUnitsInCylinder(x, z, Range)
	end
	
	if unitID and T and #T > 1 and type(unitID) == 'number' then
		for num, id in ipairs(T) do
			if id == unitID then
				table.remove(T, num)
			end
		end
	end
	return T
end

--> Grabs every Unit in a circle, filters out the unitid or teamid if given
function getAllInSphere(x, y, z, Range, unitID, teamid)
	if not x or not z then
		return {}
	end
	if not Range then assert(Range) end
	
	T = {}
	if teamid then
		T = Spring.GetUnitsInSphere(x, y, z, Range, teamid)
	else
		T = Spring.GetUnitsInSphere(x, y, z, Range)
	end
	
	if unitID and T and #T > 1 and type(unitID) == 'number' then
		for num, id in ipairs(T) do
			if id == unitID then
				table.remove(T, num)
			end
		end
	end
	return T
end



--> Removes Units of a Team from a table
function removeUnitsOfTeam(TableOfUnits, teamid)
	returnTable = {}
	for i = 1, #TableOfUnits, 1 do
		tid = Spring.GetUnitTeam(TableOfUnits[i])
		if tid ~= teamid then returnTable[#returnTable + 1] = TableOfUnits[i] end
	end
	return returnTable
end

--> Gets one Unit of one Type
function getTeamUnitOfType(teamID, typeID)
	allUnitsOfTeam = Spring.GetTeamUnits(eTeam)
	local	spGetUnitDefID = Spring.GetUnitDefID
	for i=1, #allUnitsOfTeam do
		if spGetUnitDefID(allUnitsOfTeam[i]) == typeID then
			return allUnitsOfTeam[i]
		end
	end
	
end

function getTeamSide(teamid)
	teamID, leader, isDead, isAiTeam, side, allyTeam, customTeamKeys, incomeMultiplier = Spring.GetTeamInfo(teamid)
	return side, teamID, leader, isDead, isAiTeam, allyTeam, customTeamKeys, incomeMultiplier
end

--> Grabs every Feature in a circle, filters out the featureID
function getAllFeatureNearUnit(unitID, Range)
	px, py, pz = Spring.GetUnitPosition(unitID)
	return Spring.GetFeaturesInCylinder(px, pz, Range)
end

--> Grabs every Unit in a circle, filters out the unitid
function getAllNearPiece(unitID, Piece, Range)
	px, py, pz = Spring.GetUnitPiecePosDir(unitID, Piece)
	return getAllInCircle(px, pz, Range, unitID)
end

--> Grabs every Unit in a circle, filters out the unitid
function getAllNearUnit(unitID, Range)
	px, py, pz = Spring.GetUnitPosition(unitID)
	return getAllInCircle(px, pz, Range, unitID)
end
--======================================================================================
--Section: Unit Information Getters/Setters 
--======================================================================================

--> Attaches a Unit to a Piece near a Impact side
function AttachUnitToPieceNearImpact(toAttachUnitID, AttackerID, px, py, pz, range)
	T = getAllInCircle(px, pz, range)
	boolFirstMatch = false
	process(T,
	function(id)
		if Spring.GetUnitLastAttacker(id) == AttackerID then
			return id
		end
	end,
	function(id)
		if boolFirstMatch == true then return end
		
		lastAttackedPiece = Spring.GetUnitLastAttackedPiece(id)
		if lastAttackedPiece then
			boolFirstMatch = true
			Spring.UnitAttach(id, toAttachUnitID, lastAttackedPiece)
		end
	end)
end

--> is a Unit Piece above ground
function isPieceAboveGround(unitID,pieceName)
	x,y,z =Spring.GetUnitPiecePosDir(unitID,pieceName)
	gh= Spring.GetGroundHeight(x,z)
	if gh < y then 
		return true 
	end
	return false
end

--> Gets the MaxSpeed Of A unit
function getMaxSpeed(unitID, UnitDefs)
	uDefID = Spring.GetUnitDefID(unitID)
	return UnitDefs[uDefID].speed
end

--> resets the speed of a unit
function reSetSpeed(unitID, UnitDefs)
	setSpeedEnv(unitID, 1.0)
end

--> returns a Units metal and energycosts
function getUnitCost(id)
	defID= Spring.GetUnitDefID(id)
	
	return 	UnitDefs[defID].buildCostMetal,UnitDefs[defID].buildCostEnergy
end

--> Sets the Speed of a Unit
function setSpeedEnv(k, val)
	val = math.max(0.000000001, math.min(val, 1.0))
	env = Spring.UnitScript.GetScriptEnv(k)
	
	if env then
		udef = Spring.GetUnitDefID(k)
		Spring.UnitScript.CallAsUnit(k, Spring.UnitScript.SetUnitValue, COB.MAX_SPEED, math.ceil(UnitDefs[udef].speed * val * 2184.53))
	end
end


-->Generate a Description Text for a Unit
function unitDescriptionGenerator(Unit, UnitDefNames)
	local ud = UnitDefNames[Unit]
	stringBuilder = ""
	lB = "\n"
	
	function unitDefToStr(ud)
		str = "normal"
		if ud.reclaimable == true then str = str .. ", reclaimable" end
		if ud.capturable == true then str = str .. ", capturable" end
		if ud.repairable == true then str = str .. ", repairable" end
		return str
	end
	
	function boolToString(bool)
		if bool == false then return "not" end
		return " "
	end
	
	function reStr(val, str1, str2)
		str2 =str2 or ""
		if str2 ~= "" then str2 = str2 .. lB end
		
		if not val then return str1..lB end
		return str2
	end
	
	function cStr(bool, str, alt )
		alt = alt or ""
		if alt ~= "" then alt = alt..lB end
		
		if bool and bool == true then
			return str..lB
		else
			return alt 
		end
		return ""
	end
	
	utype = generateTypeString(ud)
	ud.utype=generateTypeString(ud)
	Uname = trim(string.lower(name))
	ud.Uname = string.upper(string.sub(Uname,1,2))..string.sub(Uname,2,#Uname)
	ud.lB = lB
	ud.ustatus = generateStatusString(ud)
	stringBuilder= {}
	
	stringBuilder[#stringBuilder+1]=""..
	"=== Unit: "..ud.name.." ==="..ud.lB..
	"The unit "..ud.name.." is a "..ud.utype.." unit."..
	"Internally also described as "..ud.description..", the "..ud.name.." has "..ud.maxDamage.." Hitpoints."..
	"To build a "..ud.name.." costs "..ud.buildCostMetal.." metal and "..ud.buildCostEnergy.." energy."..
	"The "..ud.name.." is a "..ud.ustatus.. " unit."..
	reStr(ud.harvestStorage, "This harvester can store "..ud.harvestStorage.." in internal holds.")..
	reStr(ud.metalStorage, "The "..ud.name.."s storage contributes "..ud. metalStorage.." to the teams metal storage.")..
	reStr(ud.metalStorage, "The "..ud.name.."s storage contributes "..ud. energyStorage.." to the teams energy storage.")..
	reStr(ud.extractsMetal, "The "..ud.name.." extracts "..ud.extractsMetal.." from the ground.")..
	reStr(ud.windGenerator, "It is able to convert gas-currents into energy at a rate of "..ud.windGenerator)..
	reStr(ud.tidalGenerator, "Tidal forces can be converted to energy up too "..ud.tidalGenerator .. " per Unit.")..
	reStr(ud.metalUse, "The unit uses up to "..ud.metalUse .. " metal.")..
	reStr(ud.metalUpkeep,metalUpkeep.. " is used once the"..ud.name.. " is activated.")..
	reStr(ud.energyUse,energyUse.. " units of energy are used once the"..ud.name.. " is activated.")..
	reStr(ud.metalMake," The "..ud.name.. " generates "..ud.metalMake.." uncoditionally every gametick.")..
	reStr(ud.energyMake," Further the "..ud.name.. " is constantly generating "..ud.energyMake.." of energy.")..
	reStr(ud.makesMetal," In Addition the "..ud.name.. " cpmverts "..ud.makesMetal.." units of energy into metal.")..
	reStr(ud.onOffable,"A "..ud.name.. " special abilitys can "..trueStr(onOffable).." be toggled via GUI. By default the special Ability is "..trueStr(activateWhenBuilt).." active.")
	stringBuilder[#stringBuilder+1]=""..reStr(ud.sightDistance,"The "..ud.name.. " can, depending on terrain, see as far as "..ud.sightDistance.." at day and night.")
	..reStr(ud.airSightDistance,"The "..ud.name.. " can set Air Units as far as "..ud.airSightDistance..".")
	..reStr(ud.losEmitHeight,""..ud.name.. " viewpoint is "..ud.losEmitHeight.." over ground.")
	..reStr(ud.radarEmitHeight," Radar is emitted at "..ud.radarEmitHeight.." over ground with a distance of "..ud.radarDistance.."by the "..ud.name)
	..reStr(ud.radarDistanceJam," Radar is jammed in a range of "..ud.radarDistanceJam.." elmos.")
	..reStr(ud.sonarDistance,""..ud.name.." detects Submarines/Ships in a Range of "..ud.sonarDistance.." around itself.")
	..reStr(ud.sonarDistanceJam," Other ships sonar is d Submarines/Ships in a Range of "..ud.sonarDistance.." around itself.")
	..reStr(ud.stealth,"The "..ud.name.." s a stealth unit.")
	..reStr(ud.sonarStealth,"Capable of hidding from Sonarunits.")
	..reStr(ud.seismicDistance,"And able to detect enemys via seismic Signatures at a distance of "..ud.seismicDistance.." .")
	..reStr(ud.seismicSignature ,"The "..ud.name.." itself emits a seismic signature detectable up to "..ud.seismicSignature *15 .." elmos.")
	..reStr(ud.canCloak,"The "..ud.name.." is clokable with costs of "..ud.cloakCost.." per second to uphold and "..reStr(ud.cloakCostMoving," and additional costs of "..ud.cloakCostMoving.. " while moving."..reStr(ud.initCloaked, " The "..ud.name.." is cloaked from the start.")))
	..reStr(ud.canCloak,"The "..ud.name.." is clokable with costs of "..ud.cloakCost.." per second to uphold and "..reStr(ud.cloakCostMoving," and additional costs of "..ud.cloakCostMoving.. " while moving."..reStr(ud.initCloaked, " The "..ud.name.." is cloaked from the start.")))
	..reStr(ud.decloakOnFire,"If the "..ud.name.." fires its weapon, it will "..trueStr(ud.decloakOnFire).."decloak.")
	stringBuilder[#stringBuilder+1]=""..reStr(ud.cloakTimeout,"To recloak the "..ud.name.." will have to wait for "..ud.cloakTimeout.." seconds.")
	.."Among the commands for the Unit are"..
	cStr(ud.canMove," move,")..
	cStr(ud.canAttack, " attack,")..
	cStr(ud.canFight, " fight,")..
	cStr(ud.canPatrol, " patrol,")..
	cStr(ud.canGuard, " guard,")..
	cStr(ud.canCloak, " cloak,").." and "..
	cStr(ud.canRepeat, " repeat ").."."..
	"In Addition the "..ud.name.." can be orders to "..
	cStr(ud.canSelfDestruct, " selfdestruct,")..
	cStr(ud.moveState ~= -1, " switch between move states,")..
	cStr(ud.noAutoFire, " switch between the fire state,")..
	cStr(ud.fireState ~= -1, " with "..ud.fireState.." as default ")..
	cStr(ud.canManualFire, " and the order to manfual fire ").."."..	
	cStr(ud.builder, name.." is a builder that can be orders to ")..
	cStr(ud.canRestore, " restore ")..
	cStr(ud.canRepair, " repair ")..
	cStr(ud.canReclaim, " relcaim")..
	cStr(ud.canResurrect," and ressurect ")..
	cStr(ud.canCapture, " or capture. ").."other units."..
	"The "..ud.name.." can built up to a distance of "..cStr(ud.buildDistance).." away "..cStr(ud.buildRange3D, "in 3D").."." 
	..cStr(ud.workerTime> 0, " A busy little beaver,the "..ud.name.." has a workerTime of: "..ud.workerTime.." .")
	..cStr(ud.repairSpeed> 0, ud.Uname.." can repair its companions with a rate of "..ud.repairSpeed.." .")
	..cStr(ud.reclaimSpeed > 0, "Hungry as a "..ud.name.." as they say, this unit can consume at a rate of "..ud.reclaimSpeed.. " what remained of the maimed.")
	..cStr(ud.resurrectSpeed > 0, "With a resurectionSpeed of "..ud. resurrectSpeed .." the "..ud.name.." is a great pal to be around, when disaster strikes.")
	..cStr(ud.captureSpeed > 0, "With a capture Speed of "..ud. captureSpeed .." the "..ud.name.." is able to turn envitorys.")
	..cStr(ud.terraformSpeed > 0, ud.Uname.."s are great scapers of land with a terraformSpeed of "..ud. terraformSpeed..".")
	stringBuilder[#stringBuilder+1]=""..cStr(ud.canAssist , ud.Uname.."s will help guarded units to archieve there build targets.")
	..cStr(ud.canBeAssisted , ud.Uname.."s can accept help from other builders.")
	..cStr(ud.canSelfRepair , "Help thyself, so good shall help, seems to be "..ud.Uname.."s family motto.")
	..cStr(ud.showNanoSpray , "During the buildprocess- nanospray might be visible.")
	..cStr(ud.levelGround, "To start construction, the ground has to be leveld for a "..ud.name..".")
	..cStr(ud.fullHealthFactory, ud.Uname.." is a full health factory, nothing leaves Nanos-kitchen, before it is not 100 % fit.", ud.Uname.." is a normal factory shipping in various stages of disrepair.")
	..cStr(ud.isAirbase, ud.Uname.." In Addition serves as a airbase for air Units.")
	..cStr(ud.isAirbase, ud.Uname.." In Addition serves as a airbase for air Units.")
	..lB..	"The "..ud.Uname.." has a Footprint of "..ud.footprX.." in X and "..ud.footprZ.." in Z."
	..cStr(ud.movementClass, "The "..ud.Uname.." is of the following movement class :"..ud.movementClass..". ")
	..cStr(ud.canHover, ud.Uname.."s can hover.")
	..cStr(ud.floater , ud.Uname.."s is floating on the surface.", ud.Uname.."s craw along the seafloor." )
	..cStr(ud.upright , ud.Uname.."s is a upright walker with a maxslope of "..ud.maxSlope, ud.Uname.." is a ground hugger with a maxslope of "..ud.maxSlope )
	..cStr(ud.minWaterDepth , "The "..ud.Uname.." needs at least a waterdepth of "..ud.minWaterDepth..".")
	..cStr(ud.maxWaterDepth , "The "..ud.Uname.." needs at least a waterdepth of "..ud.minWaterDepth..".")
	..cStr(ud.waterline > 0.0, "A "..ud.name.." is "..ud.waterline.." submerged beneath the waves.")		
	..cStr(ud.minCollisionSpeed, "When at "..ud. minCollisionSpeed.." the "..ud.name.." will suffer damage on collission.")
	..cStr(ud.pushResistant, "This unit is pushed around.","This unit is push resistant.")
	stringBuilder[#stringBuilder+1]=""..cStr(ud.maxVelocity> 0.0, ud.Uname.."s maximum speed is "..ud.maxVelocity.." attained at "..cStr(ud.acceleration> 0, acceleration))
	..cStr(ud.maxReverseVelocity> 0.0, "The reverse velocity is"..ud. maxReverseVelocity)
	..cStr(ud.brakeRate, "The "..ud.name.." brakes with a rate of "..ud.brakeRate..".")
	..cStr(ud.myGravity, "As a aircraft-unit the "..ud.name.." has a custom gravity of "..ud.myGravity)
	..cStr(ud.turnRate, ud.Uname.." turns "..cStr(ud.turnInPlace," in place ").."with a speed of "..ud.turnRate.. " degrees per second")
	..cStr(ud.turnInPlaceSpeedLimit, "When turning in place the "..ud.name.." is bound by a speedlimit of "..ud.turnInPlaceSpeedLimit..".")
	..cStr(ud.turnInPlaceAngleLimit, "It can bank during turn by "..ud.turnInPlaceAngleLimit.." degrees.")
	..cStr(ud.blocking, "The "..ud.Uname.." blocks the movement of other Units.")
	..cStr(ud.crushResistance, "Crush resistant up to"..ud. curshResistance..".")
	..cStr(ud.myGravity, "As a aircraft-unit the "..ud.name.." has a custom gravity of "..ud.myGravity)
	..cStr(ud.blocking, "The "..ud.Uname.." blocks the movement of other Units.")
	..cStr(ud.Flanking, "When Flanking the "..ud.name.."s bonus is "..ud.selStr(Flanking, {"no flanking bonus","a build up of the ability to move over time, and swings to face attacks","also can swing, but moves with the unit as it turns", "stays with the unit as it turns and otherwise doesn't move"}))
	..cStr(ud.flankingBonusMax, "The Bonus applied to the armour main direction is "..ud.flankingBonusMax)
	..cStr(ud.flankingBonusMin, "The Bonus applied to the armour minimal directions is "..ud.flankingBonusMin)
	..cStr(ud.canFly, ud.Uname.." is a aircraft.")
	..cStr(ud.canSubmerge, ud.Uname.." can submerge itself beneath water.")
	..cStr(ud.factoryHeadingTakeoff, ud.Uname.." will lift off from a runway.",Uname.." will lift off straigth up - VTOL style.")
	..cStr(ud.collide,"The "..ud.name.." will collide with air-units.", "The "..ud.name.." has collission turned off." )
	..cStr(ud.hoverAttack,"Enemys will be attacked while attacked hovering in place by "..ud.name..".", "Enemys will be attacked with approach and flight over by "..ud.name.."." )
	..cStr(ud.airStrafe and ud.hoverAttack, "Enemy fire is avoided with strafing motion" )
	stringBuilder[#stringBuilder+1]=""..cStr(ud.cruiseAlt, "Default cruise height is "..ud.cruiseAlt.." in elmos for the "..ud.name..".")
	..cStr(ud.airHoverFactor < 0, "It is capable of landing.", "It will hover on the spot moving about "..ud.airHoverFactor..".")
	..cStr(ud.bankingAllowed, "When turning the unit banks.", "It cant bank worth a damn.")
	..cStr(ud.maxBank, "At max the "..ud.name.." will bank by "..ud.maxBank )
	..cStr(ud.maxPitch, "The maxpitch before loosing lift is "..ud.maxPitch.." ." )
	..cStr(ud.useSmoothMesh, "The "..ud.name.." follows a smooth out heigthmap during fleigth.", "The "..ud.name.." uses the actual heigthmap to navigate.")
	..cStr(ud.maxFuel, "The "..ud.name.." has a muxfuel of "..ud.maxFuel)
	..cStr(ud.refuelTime, "It takes "..ud.refuelTime.." seconds to fill this baby up - with fuel.")
	..cStr(ud.canLoopbackAttack, "A "..ud.name.." can perform a Immelmann turn.")
	..cStr(ud.wingDrag, "The wings of "..ud.name.." have a drag due to the wingdrag of "..ud.wingDrag..".")
	..cStr(ud.wingAngle, "The wings of "..ud.name.." have a angle of"..ud.wingAngle..".")
	..cStr(ud.frontToSpeed, ud.Uname.."s lineup speed and front of plane with a speed of"..ud.frontToSpeed)
	..cStr(ud.crashDrag, ud.Uname.."s have a air-resistance of "..ud.crashDrag.." when going down for good.")
	..cStr(ud.turnRadius, "The unit has a turnradius of "..ud.turnRadius.. " in elmo.")
	..cStr(ud.verticalSpeed, "The "..ud.name.." has a vertical speed of "..ud.verticalSpeed.. " taking off.")
	..cStr(ud.maxAileron, "Z-Axis turnspeed maximum of a "..ud.name.." is "..ud.maxAileron..".")
	..cStr(ud.maxElevator, "Y-Axis turnspeed maximum of a "..ud.name.." is "..ud.maxAileron..".")
	..cStr(ud.maxRudder, "X-Axis turnspeed maximum of a "..ud.name.." is "..ud.maxAileron..".")
	..cStr(ud.maxAcc, "The maximum Acceleration of a "..ud.name.." aircraft.")
	..cStr(ud.Flares, "Under fire by rockets, the "..ud.name.." drops flares.")
	..cStr(ud.flareReload, "Reloading these flares costs "..ud.flareReload.." seconds time.")
	..cStr(ud.flareDelay, " Fired flares are delayed by a factor of "..ud.flareDelay.." * random(1,16)." )
	..cStr(ud.flareEfficiency, " Enemy missiles will be distracted by the flare with a chance of "..ud.flareEfficiency..".")
	stringBuilder[#stringBuilder+1]=""..cStr(ud.lifetime, " A dropped flare will burn for "..(ud.flareTime/30).." seconds.")
	..cStr(ud.flareSalvoSize, " One salvo contains "..ud.flareSalvoSize.." flares.")
	..cStr(ud.flareSalvoDelay, " Each flare of a salvo is delayed by "..(ud.flareSalvoDelay/30).." seconds.")	
	..cStr(ud.transportSize>0, ud.Uname.." can carry up to "..ud.transportSize.." passengers.")
	..cStr(ud.mransportSize and ud.transportCapacity, "Any picked up unit, must be between "..ud.mransportSize.." and "..ud.transportCapacity/ud.transportSize )
	..cStr(ud.mransportMass and ud.transportMass, "Any picked up mass, must be between "..ud.mransportMass.." and "..ud.transportMass )
	..cStr(ud.loadingRadius, "A "..ud.name.." will load in a radius of "..ud.loadingRadius.." around itself.")
	..cStr(ud.unloadSpread, "When the passengers are unloaded a distance of"..ud. unloadSpread.." times passengersize is kept." )
	..cStr(ud.isFirePlatform, " All loaded units can fire on there designated targets from there docking position.")
	..cStr(ud.holdSteady, "Passengerdirection is slaved to the transport piece.","Passengerdirection is slaved to the transport direction.")
	..cStr(ud.releaseHeld, "On death the "..ud.name .." releases its transported units.","On death the "..ud.name .." makes the final ferryman for its passengers.")
	..cStr(ud.transportByEnemy, ud.Uname.."s regularly are refused transportation service for non-discrimination reasons.")
	..cStr(ud.cantBeTransported, ud.Uname.."s can be taken for a ride by enemy transport.")
	..selStr(ud.transportUnloadMethod,{[0 ] =" Land to unload individually", [1] = "Flyover drop (i.e. Parachute)", [2] = "Land and flood unload all passengers."})
	..cStr(ud.fallSpeed, "Deployed Paratroopers will fall with a speed of "..ud.fallSpeed)
	..cStr(ud.category, "The "..ud.name.." belongs to the following categories:"..ud.category)
	..cStr(ud.noChaseCategory, "It will not chase targets of category: "..ud.noChaseCategory..".")
	..cStr(ud.leaveTracks, "Recognizeable tracks called "..ud.trackType.." show wherever " ..ud.name.." went." )
	..cStr(ud.trackWidth and ud.trackOffset, "Said tracks are "..ud.trackWidth.." in width and "..ud.trackOffset.." in length.")
	..cStr(ud.trackStrength, "Tracks will be ".. ud.trackStrength.." persistent and visible.")
	..cStr(ud.useBuildingGroundDecal ~= nil and ud.buildingGroundDecalType ~= nil, Uname.."s have a Grounddecal called: "..ud.buildingGroundDecalType)
	..cStr(ud.buildingGroundDecalSizeX, "This Grounddecal is "..ud.buildingGroundDecalSizeX.." x "..ud.buildingGroundDecalSizeY.." in size and decays with a factor of "..ud.buildingGroundDecalDecaySpeed)
	stringBuilder[#stringBuilder+1]=""..cStr(ud.highTrajectory, "Trajectory weapons are fired in ".. selStr(ud.highTrajectory, {[0]="a high trajectory.",[1] = " a low trajectory.", [2]= "in the user selected mode (high/low)."}))
	..cStr(ud.kamikaze," Good to know is also, that "..ud.name.."is a kamikaze unit, sacrificing it all for the greater good.")
	..cStr(ud.kamikazeDistance, "To get to heaven, a "..ud.name.." needs to get as close as "..ud.kamikazeDistance.." virgins, side by side.")
	..cStr(ud.kamikaze,cStr(ud.kamikazeUseLOS, "Only eye-contact prevents a kamikaze attack from beeing perceived as impersonal.", "Shrapnell contact for a first kamikaze impression is close enough."))
	..cStr(ud.strafeToAttack, "When not finding the target in range, a "..ud.name.." will move until it is.")
	..cStr(ud.selfDestructCountdown, ud.selfDestructCountdown.." seconds is all it takes before a "..ud.name.." self-destructs once the command has been issued.")
	..cStr(ud.decoyFor, Uname.." is a decoy for "..UnitDefs[ud.decoyFor].name..".")
	..cSTr(ud.damageModifier, "Should the "..ud.name.." raise its amour, a modifier of "..ud.damageModifier.." is applied to all recived damage.")
	..cStr(ud.isTargetingUpgrade, ud.Uname.." is a targetting facility, enhancing other units out-of-los accuracy.")
	..cStr(ud.isFeature, " This unit turns into a feature upon creation." )
	..cStr(ud.hideDamage," Damage a "..ud.name.." recives is hidden from the enemys eyes.")
	..cStr(ud.showPlayerName,"The "..ud.name.." is the players avatara.")
	..cStr(ud.showNanoFrame," During the buildprocess a classic OTA Nanoframe is shown")
	..cStr(ud.unitRestricted," The Unit "..ud.name.." is restricted to maximal "..ud.unitRestricted.." total.")
	..cStr(ud.power, ud.Uname..": This unit relative power is "..ud.power..".")
	OfTheString=""
	for i=1,#stringBuilder do
		OfTheString= OfTheString..stringBuilder[i]
	end
	
	return OfTheString
end


--> checks wether a piece is below another piece
function recPieceBelow(hierarchy, currentPiece, endPiece, reTable)
	boolBelow = false
	
	if not hierarchy[currentPiece] then return nil end
	for k, pieceNumber in pairs(hierarchy[currentPiece]) do
		local retTable = reTable
		
		if pieceNumber == endPiece then
			retTable[#retTable + 1] = endPiece
			return true, retTable
		end
		
		retTable[#retTable + 1] = pieceNumber
		boolFound, T = recPieceBelow(hierarchy, pieceNumber, endPiece, retTable)
		if boolFound == true then
			return true, T
		end
	end
	return false
end

-->returns a chain of pieces from startPiece to endPiece going over a hierarchy
function getPieceChain(hierarchy, startPiece, endPiece)
	pieceChain = {}
	pieceChain[1] = startPiece
	boolBelow, pieceChain = recPieceBelow(hierarchy, startPiece, endPiece, pieceChain)
	return pieceChain
end

function getPiecePosDir(unitID, Peace)
	
	px,py,pz, dx,dy,dz= Spring.GetUnitPiecePosDir(unitID, Peace)
	return {x=px,y=py,z=pz}, {x=dx,y=dy,z=dz}
	
end

--> creates a hierarchical table of pieces, descending from root
function getPieceHierarchy(unitID, pieceFunction)
	
	rootname, children = getRoot(unitID)
	rootNumber = pieceFunction(rootname)
	hierarchy = {}
	hierarchy[rootNumber] = {}
	openTable = {}
	for k, pieceName in pairs(children) do
		hierarchy[rootNumber][#hierarchy[rootNumber] + 1] = pieceFunction(pieceName)
		table.insert(openTable, pieceFunction(pieceName))
	end
	
	while table.getn(openTable) > 0 do
		for num, pieceNumber in pairs(openTable) do
			tables = Spring.GetUnitPieceInfo(unitID, pieceNumber)
			if not hierarchy[pieceNumber] then hierarchy[pieceNumber] = {} end
			if tables and tables.children then
				for num, pieceName in pairs(tables.children) do
					newPieceNumber = pieceFunction(pieceName)
					hierarchy[pieceNumber][#hierarchy[pieceNumber] + 1] = newPieceNumber
					table.insert(openTable, pieceFunction(pieceName))
				end
				table.remove(openTable, num)
			end
		end
	end
	
	
	return hierarchy, rootname
end


--> returns a skelett table via recursion (Expensive)
function recMapDown(unitID, Result, pieceMap, Name)
	if type(Name) == "number" then
		Name = getUnitPieceName(unitID, Name)
	end
	
	if pieceMap[Name] then
		for _, pieceNumber in pairs(pieceMap[Name]) do
			info = Spring.GetUnitPieceInfo(unitID, pieceNumber)
			Result[#Result + 1] = pieceNumber
			if info and pieceMap[info.name] and info.children then
				Result = recMapDown(unitID, Result, pieceMap, info.name)
			end
		end
	end
	return Result
end

-->Returns all Pieces in a Hierarchy below the named point
function getPiecesBelow(unitID, PieceName, pieceFunction)
	pieceMap = getPieceHierarchy(unitID, pieceFunction)
	return recMapDown(unitID, {}, pieceMap, PieceName)
end

--Hashmap of pieces --> with accumulated Weight in every Node
--> Every Node also holds a bendLimits which defaults to ux=-45 x=45, uy=-180 y=180,uz=-45 z=45
function recursiveAddTable(T, piecename, parent, piecetable)
	if not piecename then return T, 0 end
	
	C, max = getPieceChildrenTable(piecename, piecetable)
	
	if not T[parent] then T[parent] = {} end
	
	if C and #C > 0 then
		for i = 1, #C do
			T, nr = recursiveAddTable(T, C[i], piecename, piecetable)
		end
		bendLimits = computateBendLimits(piecename, parent)
		T[parent].bendLimits = bendLimits
		T[parent].weight = max[1] * max[2] * max[3]
		T[parent].nr = #C
	else
		
		if not T[parent][piecename] then T[parent][piecename] = {} end
		computateBendLimits(piecename, parent)
		T[parent].bendLimits = bendLimits
		T[parent][piecename].weight = 1
	end
	return T
end
-->Helperfunction of recursiveAddTable
function getPieceChildrenTable(pieceNum, piecetable)
	if not pieceNum then return end
	T = Spring.GetUnitPieceInfo(unitID, pieceNum)
	children = T.children
	if children then
		for i = 1, #children do children[i] = piecetable[children[i]] end
	end
	return children, T.max
end

--> returns the root Piece of a units skeletton
function getRoot(unitID)
	pieceMap = Spring.GetUnitPieceMap(unitID)
	for name, number in pairs(pieceMap) do
		infoTable = Spring.GetUnitPieceInfo(unitID, number)
		if (infoTable.parent == "[null]") then return name, infoTable.children end
	end
end

--> kill All Units near Pieces Volume
function killAtPiece(unitID, piecename, selfd, reclaimed, sfxfunction)
	px, py, pz = Spring.GetUnitPieceCollisionVolumeData(unitID, piecename)
	tpx, tpy, tpz = Spring.GetUnitPiecePosDir(unitID, piecename)
	if px and tpx then
		size = square(px, py, pz)
		if size then
			T = getAllInCircle(tpx, tpz, size / 2, unitID)
			
			if T and #T > 0 then
				
				if sfxfunction then
					for i = 1, #T do
						ux, uy, uz = Spring.GetUnitPosition(T[i])
						sfxfunction(ux, uz, uz)
						Spring.DestroyUnit(T[i], selfd, reclaimed)
					end
					
				else
					for i = 1, #T do
						Spring.DestroyUnit(T[i], selfd, reclaimed)
					end
				end
			end
		end
	end
end

-->Returns a Unit from the Game without killing it
function removeFromWorld(unit, offx, offy, offz)	 
	hideUnit(unit)

	--TODO - keepStates in general and commandqueu
	pox, poy, poz = Spring.GetUnitPosition(unit)
	Spring.SetUnitAlwaysVisible(unit, false)
	Spring.SetUnitBlocking(unit, false, false, false)
	Spring.SetUnitNoSelect(unit, true)
	Spring.MoveCtrl.Enable(unit, true)
		if offx then
		Spring.SetUnitPosition(unit, offx, offy, offz)
	end
end

-->Removes a Unit from the Game without killing it
function returnToWorld(unit, px, py, pz)
	showUnit(unit)
	Spring.MoveCtrl.Disable(unit)
	if px then
		Spring.SetUnitPosition(unit, px, py, pz)
	end
	Spring.SetUnitAlwaysVisible(unit, true)
	Spring.SetUnitBlocking(unit, true, true, true)
	Spring.SetUnitNoSelect(unit, false)
end


--> Shows all Pieces of a a Unit in 
function showAll(id)
	if not unitID then unitID = id end
	pieceMap = Spring.GetUnitPieceMap(unitID)
	for k,v in pairs(pieceMap) do
		Show(v)
	end
end
--> Hide all Pieces of a Unit
function hideAll(id)
	if not unitID then unitID = id end
	
	pieceMap = Spring.GetUnitPieceMap(unitID)
	for k,v in pairs(pieceMap) do
		Hide(v)
	end
end
--> reveal a Unit 
function showUnit(unit)
	Spring.SetUnitCloak(unit, false, 1)
	Spring.SetUnitLosState(unit,0, {los=true, prevLos=true, contRadar=true, radar=true})
end

--> hide a Unit
function hideUnit(unit)
	Spring.SetUnitCloak(unit, true, 4)
	Spring.SetUnitLosState(unit,0, {los=false, prevLos=false, contRadar=false, radar=false})

end

--> GetDistanceNearestEnemy
function distanceNearestEnemy(id)
	ed = Spring.GetUnitNearestEnemy(id)
	return distanceUnitToUnit(id, ed)
end

--> returns the gh, the units heigth and wether the unit is underground
function getGroundHeigthAtPiece(uID, pieceName)
	px, py, pz = Spring.GetUnitPiecePosDir(uID, pieceName)
	gh = Spring.GetGroundHeight(px, pz)
	
	return gh, py, py < gh
end

--> get the Groundheigth at a Units position
function getUnitGroundHeigth(unitID)
	px, py, pz = Spring.GetUnitPosition(unitID)
	
	if px then
		h = Spring.GetGroundHeight(px, pz)
		if h then
			return h
		end
	end
end

--> Grabs every Unit in a circle, filters out the unitid
function getInCircle(unitID, Range, teamid)
	
	x, _, z = Spring.GetUnitBasePosition(unitID)
	return getAllInCircle(x,z, Range, unitID, teamid)
	
end

--> Returns the nearest Enemy 
function getNearestGroundEnemy(id, UnitDefs)
	ed = Spring.GetUnitNearestEnemy(id)
	if ed then
		--early out
		eType = Spring.GetUnitDefID(ed)
		
		if UnitDef[eType].isAirUnit == false then return ed end
		eTeam = Spring.GetUnitTeam()
		allUnitsOfTeam = Spring.GetTeamUnits(eTeam)
		mindist = math.huge
		foundUnit = nil
		if Spring.GetUnitIsDead(id) == true or Spring.GetUnitIsDead(ied) == true then return nil end 
		
		process(allUnitsOfTeam,
		function(ied)					
			if ied ~= ed then
				distUnit = distanceUnitToUnit(id, ied)
				if distUnit and distUnit < mindist then
					if UnitDef[Spring.GetUnitDefID(ied)].isAirUnit == false then
						mindist = distUnit
						foundUnit = ied
					end
				end
			end
		end)
		if Spring.ValidUnitID(foundUnit) == true then return foundUnit end
	end
end

--> return the Name of a UnitPiece as String
function getUnitPieceName(unitID,pieceNum)
	
	pieceList= Spring.GetUnitPieceList(unitID)
	return pieceList[pieceNum]
end

--> Returns a Map of Pieces and there Position in World Coords
function getPiecePositionMap(id)
	
	dpiecesTable = Spring.GetUnitPieceMap(id)
	ux, uy, uz = Spring.GetUnitPosition(id)
	tpiecesTable = {}
	i = 1
	for k, v in pairs(dpiecesTable) do
		x, y, z = Spring.GetUnitPiecePosDir(id, v)
		tpiecesTable[i] = {}
		tpiecesTable[i].pid = v
		tpiecesTable[i].x = x or ux
		tpiecesTable[i].y = y or uy
		tpiecesTable[i].z = z or uz
		i = i + 1
	end
	return tpiecesTable
end

--> returns a table of all unitnames a unit can build
function getUnitCanBuild(unitName,closedT)
	closedTable = closedT or {}
	unitDef= {}
	if type(unitName)=="string" and UnitDefNames then
		unitDef = UnitDefNames[unitName]
	else
		unitDef = UnitDefs[unitName]
	end
	
	T = {}
	if unitDef.isFactory or unitDef.isBuilder and unitDef.buildOptions then	
		for i = 1, #unitDef.buildOptions do
			local buildID = UnitDefs[unitDef.buildOptions[i]].id
			T[#T+1] = buildID
		end
	end
	closedTable[unitDef.id] = true
	return T, closedTable
end


-->Stuns a Unit
function stunUnit(k, factor)
	hp = Spring.GetUnitHealth(k)
	if hp then Spring.SetUnitHealth(k, { paralyze = hp * factor }) end
end

--> Transfer UnitStats
function transferUnitStatusToUnit(unitID, targetID)
	exP = Spring.GetUnitExperience(unitID)
	hp, maxHP, para, cap, bP = Spring.GetUnitHealth(unitID)
	newhp, newmaxHP, _, _, _ = Spring.GetUnitHealth(unitID)
	Spring.SetUnitExperience(targetID, exP)
	
	factor = 1 / (hp / maxHP)
	hp = math.ceil(newmaxHP * factor)
	
	Spring.SetUnitHealth(targetID, { health = hp, capture = cap, paralyze = para, build = bP })
end

function transferUnitTeam(id, targetTeam)
	Spring.TransferUnit(id, targetTeam)
end
--> Create a Unit at Piece of another Unit
function createUnitAtPiece(unitID, typeID, Piece, team)
	x,y,z,_,_,_ =Spring.GetUnitPiecePosDir(unitID, Piece)
	teamID= team or Spring.GetUnitTeam(unitID)
	return Spring.CreateUnit(typeID, x, y, z, math.ceil(math.random(0, 3)), teamID)
end
--> Create a Unit at another Unit
function createUnitAtUnit(teamID, typeID, otherID,ox,oy,oz)
	x,y,z,_,_,_ =Spring.GetUnitPosition(otherID)
	return Spring.CreateUnit(typeID, x+ox, y+oy, z+oz, math.ceil(math.random(0, 3)), teamID)
end

--> Transforms a selected unit into another type
function transformUnitInto(oldID, unitType, setVel, boolKill)
	x, y, z = Spring.GetUnitPosition(oldID)
	teamID = Spring.GetUnitTeam(oldID)
	vx, vy, vz, vl = Spring.GetUnitVelocity(oldID)
	rotx, roty, rotz = Spring.GetUnitRotation(oldID)
	currHp, oldMaxHp = Spring.GetUnitHealth(oldID)
	
	id = Spring.CreateUnit(unitType, x, y, z, math.ceil(math.random(0, 3)), teamID)
	if id then
		transferUnitStatusToUnit(oldID, id)
		transferOrders(oldID, id)
		Spring.SetUnitPosition(id, x, y, z)
		
		if  vx and rotx then		
			if setVel then
				Spring.SetUnitVelocity(id, vx * vl, vy * vl, vz * vl)
			end
			Spring.SetUnitRotation(id, rotx, roty, rotz)
		end
	end
	if not boolKill or boolKill == true then
		Spring.DestroyUnit(oldID, false, true)
	end
	
	return id
end

--> Get Unit Target if a Move.Cmd was issued
function getUnitMoveGoal(unitID)
	cmds = Spring.GetCommandQueue(unitID, 4)
	for i = #cmds, 1, -1 do
		if cmds[i].id and cmds[i].id == CMD.MOVE and cmds[i].params then
			return cmds[i].params[1], cmds[i].params[2], cmds[i].params[3]
		end
	end
end

function destroyUnitConditional(id, selfd, reclaimed )
	if  doesUnitExistAlive(id) == true then
		Spring.DestroyUnit(id,selfd,reclaimed)
	end
end

function doesUnitExistAlive(id)
	valid = Spring.ValidUnitID(id)
	if valid == nil or valid == false then
		--echo("doesUnitExistAlive::Invalid ID")
		return false 
	end
	
	dead = Spring.GetUnitIsDead(id)
	if  dead == nil or dead == true then 
	--echo("doesUnitExistAlive::Dead Unit")
	return false 
	end
	
	return true	
end

-->Unit Verfication
function isAlive(unitid)
	validUnit = Spring.GetUnitIsDead(unitid)
	if validUnit and validUnit == true then return true end
	
	return false
end

function confirmUnit(id)
	if doesUnitExistAlive(id)== true then return id end
end


-->Validates that a table of UnitIds or a UnitID still exist and is alive
-->Non existant ids are silently filtered out
function affirm(T)
	if type(T) == "number" then t1 = T; T = { [1] = t1 } end
	resulT = process(T,
	function(id)
		if isAlive(id) == true then return id end
	end)
	if resulT then
		if #resulT > 1 then
		return resulT else
			return resulT[1]
		end
	end
end

function delayedHide(piece, timeT)
	Sleep(timeT)
	Hide(piece)
end

function delayedShow(piece, timeT)
	Sleep(timeT)
	Show(piece)
end

--> That thing, has a huge thing, and it its cumint towards you..
function getUnitBiggestPiece(unit, cache)
	defID= Spring.GetUnitDefID(unit)
	if cache and cache[defID] then return cache[defID], cache end
	
	volumeMax = -math.huge
	biggestPieceSoFar= nil
	pieceMap= Spring.GetUnitPieceMap(unit)
	
	for name,number in pairs(pieceMap) do
		volume = getUnitPieceVolume(unit, number)
		if volume > volumeMax then
			biggestPieceSoFar= number
			volumeMax = volume 
		end
	end
	if cache then 	cache[defID] = biggestPieceSoFar end
	return biggestPieceSoFar, cache or {}
end

function getUnitPieceVolume(unit, Piece)
	vx, vy, vz = Spring.GetUnitPieceCollisionVolumeD
	if vx then
		return math.abs(vx*vy*vz) 
	end
	return 0
end

--> finds GenericNames and Creates Tables with them
function getPieceTableByNameGroups(boolMakePiecesTable, boolSilent)
	
	boolSilentRun = boolSilent or true
	pieceMap = Spring.GetUnitPieceMap(unitID)
	piecesTable = Spring.GetUnitPieceList(unitID)
	
	TableByName = {}
	NameAndNumber = {}
	ReturnTable = {}
	
	for i = 1, #piecesTable, 1 do
		s = string.reverse(piecesTable[i])
		
		for w in string.gmatch(s, "%d+") do
			if w then
				s = string.sub(s, string.len(w), string.len(s))
				NameAndNumber[i] = {
					name = string.sub(piecesTable[i], 1, string.len(piecesTable[i]) - string.len(w)),
					number = string.reverse(w)
				}
				
				if TableByName[NameAndNumber[i].name] then
					TableByName[NameAndNumber[i].name] = TableByName[NameAndNumber[i].name] + 1
				else
					TableByName[NameAndNumber[i].name] = 1
				end
				break
			end
		end
		if not NameAndNumber[i] then NameAndNumber[i] = { name = string.reverse(s) } end
	end
	
	
	if boolSilentRun == false then
		for k, v in pairs(TableByName) do
			if v > 1 then
				Spring.Echo(k .. " = {}")
			end
		end
		
		
		for k, v in pairs(NameAndNumber) do
			
			if v and v.number then
				Spring.Echo(v.name .. v.number .. " = piece\"" .. v.name .. v.number .. "\"")
				Spring.Echo(v.name .. "[" .. v.number .. "]= " .. v.name .. v.number)
			else
				Spring.Echo(v.name .. " = piece(" .. v.name .. ")")
			end
		end
		
		if boolMakePiecesTable and boolMakePiecesTable == true then
			generatepiecesTableAndArrayCode(unitID)
		end
		
	else
		
		--pack the piecesTables in a UeberTable by Name
		for tableName, _ in pairs(TableByName) do
			local PackedAllNames = {}
			--Add the Pieces to the Table
			for k, v in pairs(NameAndNumber) do
				
				if v and v.number and v.name == tableName then
					piecename = v.name .. v.number
					if lib_boolDebug == true then
						if lib_boolDebug == true and pieceMap[piecename] then
							Spring.Echo(v.name .. "[" .. v.number .. "] = " .. piecename .. " Piecenumber: " .. pieceMap[piecename])
						else
							Spring.Echo("pieceMap contains no piece named " .. piecename)
						end
					end
					convertToNumber = tonumber(v.number)
					PackedAllNames[convertToNumber] = pieceMap[piecename]
				end
			end
			ReturnTable[tableName] = PackedAllNames
		end
		
		return ReturnTable
	end
end

-->generates a Pieces List 
function generatepiecesTableAndArrayCode(unitID, boolLoud)
	bLoud = boolLoud or false
	
	if bLoud == true then
		Spring.Echo("")
		Spring.Echo("--PIECESLIST::BEGIN |>----------------------------")
		Spring.Echo("piecesTable={}")
		piecesTable = {}
		piecesTable = Spring.GetUnitPieceList(unitID)
		--Spring.Echo("local piecesTable={}")
		if piecesTable ~= nil then
			for i = 1, #piecesTable, 1 do
				workingString = piecesTable[i]
				Spring.Echo("" .. piecesTable[i] .. " = piece(\"" .. piecesTable[i] .. "\")\n piecesTable[#piecesTable+1]= " .. piecesTable[i])
			end
		end
		
		Spring.Echo("PIECESLIST::END |>-----------------------------")
	end
	
	
	return getPieceTable(unitID)
end
function getPieceTable(unitID)
	RetT = {}
	piecesTable = Spring.GetUnitPieceMap(unitID)
	for k, v in pairs(piecesTable) do
		RetT[#RetT + 1] = v
	end
	return RetT
end


-->generates a Pieces List Keyed to the PieceName
function getNamePieceNumDict(unitID, piecefunction)
	
	returnTable = {}
	piecesTable = Spring.GetUnitPieceList(unitID)
	
	if piecesTable ~= nil then
		for i = 1, #piecesTable, 1 do
			returnTable[piecesTable[i]] = piecefunction(piecesTable[i])
		end
	end
	return returnTable
end

-->Gets the Height of a Unit
function getunitHeight(UnitId)
	_, y, _ = Spring.GetUnitPosition(unitID)
	return y
end


--> Returns a Units side as string
function getUnitSide(unitID)
	teamid = Spring.GetUnitTeam(unitID)
	return select(1, getTeamSide(teamid))
end

--> returns a Units Name as String
function getUnitName( UnitDefID)
	if not UnitDefNames then echo("getUnitName: No UnitDefNames"); return "" end
	for name, def in pairs(UnitDefNames) do
		if def.id == UnitDefID then
			return name
		end
	end
	return "UnitName not found in UnitDefID:: UnitParsing Errors"
end

--======================================================================================
--Section: Initializing Functions
--======================================================================================
function lifeTime (unitID, lifeTime, boolReclaimed, boolSelfdestroyed,finalizeFunction)
	boolReclaimed, boolSelfdestroyed = boolReclaimed or false, boolSelfdestroyed or false
	Sleep(lifeTime)
	if finalizeFunction then finalizeFunction()end
	Spring.DestroyUnit(unitID, boolReclaimed, boolSelfdestroyed)
end

function getPieceMap(unitID)
	List = Spring.GetUnitPieceMap(unitID)
	return List 
end

function waitTillComplete(unitID)
	while not buildProgress and hp ~= mHp do
	hp, mHp, _, _, _, buildProgress = Spring.GetUnitHealth(unitID)
	Sleep(500)
	end
	
	while buildProgress and buildProgress < 0 do
        hp, mHp, _, _, _, buildProgress = Spring.GetUnitHealth(unitID)
        Sleep(500)
   end
   
	return bP ~=nil
end

function createUnit_TerrainTest(uType, x,y,z, orientation, teamID, acceptableIncline)

loc_acceptableDecline= acceptableIncline or 0.35
tx,ty,tz,slope = Spring.GetGroundNormal(x,z)

	--Spring.Echo("createUnit_TerrainTest: slope = "..slope.. " < ".. loc_acceptableDecline )
	if slope < loc_acceptableDecline then
	
		return Spring.CreateUnit(uType, x,y,z, orientation, teamID)
	end

		Spring.Echo("createUnit_TerrainTest:"..slope.. " > ".. loc_acceptableDecline )
end

function breakUnitIntoProjectilePieces(id)
	
	explodeFunction = function()
		T = getPieceTable(id)
		for i=1,#T do
			Spring.UnitScript.Explode(T[i],1 + 128)
		end
	end
	
	env = Spring.UnitScript.GetScriptEnv(id)		
	if env then
		Spring.UnitScript.CallAsUnit(id, explodeFunction)
	end
	
	Spring.DestroyUnit(id,false, true)
end
--======================================================================================
--Section: Landscape/Pathing Getter/Setters
--======================================================================================

--> every PixelPiecetable consists of a List of Pieces, a selectFunction and a PlaceFunction
-- both recive a List of allready in Pixel Placed Pieces and the relative Heigth they are at, 
-- and gives back a piece, and its heigth, the Selector returns nil upon Complete 
function createLandscapeFromFeaturePieces(pixelPieceTable, drawFunctionTable)
	echo("TODO:createLandscapeFromFeaturePieces")
end

function createExtrema()

    emin, emax = Spring.GetGroundExtremes()
    if emin and emax then
			
        if math.abs(emax) > math.abs(emin) then
						GG.Extrema = emax
						else
						 GG.Extrema =emin
						end
    else
        GG.Extrema = 250
    end
end

--> Does not remove the grass
function removeGrass(startX,endX,startY,endY)
	
	for x = startX, endX, 16 do
		for z = startY, endY, 16 do
			Spring.RemoveGrass(x, z)
		end
	end
end
--> Gets a List of Geovents + Positions
function getGeoventList()
	
	features = Spring.GetAllFeatures()
	GeoventList = {}
	for i = 1, #features do
		id = features[i]
		defID = Spring.GetFeatureDefID(id)
		if defID == FeatureDefNames["geovent"].id then
			fx, fy, fz = Spring.GetFeaturePosition(id)
			GeoventList[#GeoventList + 1] = { x = fx, y = fy, z = fz, id = id }
		end
	end
	return GeoventList
end

function getADryWalkAbleSpot()
	smin, smax = Spring.GetGroundExtremes()
	if smax <= 0 then return end
	cond = function(i, j, chunkSizeX, chunkSizeZ)
		h = Spring.GetGroundHeight(i * chunkSizeX, chunkSizeZ * j)
		if h > 0 then
			v = {}
			v.x, v.y, v.z = Spring.GetGroundNormal(i * chunkSizeX, chunkSizeZ * j)
			v = normVector(v)
			if v.y > 0.3 or math.abs(v.x) < 0.3 or math.abs(v.z) < 0.3 then
				return math.ceil(i * chunkSizeX), math.ceil(i * chunkSizeZ)
			end
		end
	end
	return getPathPointFullfillingConditions(cond, 64)
end


-->finds a spot on the map that is dry, and walkable
function getPathPointFullfillingConditions(condition, maxRes, filterTable, mapSizeX, mapSizeZ)
	if type(condition) ~= "function" then echo("getPathPointFullfillingConditions recived not a valid function") end
	
	
	probeResolution = 4.0
	local spGetGroundHeight = Spring.GetGroundHeight
	assert(Game.mapSizeX)
	assert(Game.mapSizeZ)
	while true do
		
		local chunkSizeX = (Game.mapSizeX - 1) / probeResolution
		local chunkSizeZ = (Game.mapSizeZ - 1) / probeResolution
		xRand, zRand = math.floor(sanitizeRandom(1, probeResolution - 1)), math.floor(sanitizeRandom(1, probeResolution - 1))
		
		for i = xRand, probeResolution, 1 do
			for j = zRand, probeResolution, 1 do
				ax, ay, az = condition(i, j, chunkSizeX, chunkSizeZ, filterTable)
				if ax then return ax, ay, az end
			end
		end
		
		
		for i = 1, xRand, 1 do
			for j = 1, zRand, 1 do
				ax, ay, az = condition(i, j, chunkSizeX, chunkSizeZ, filterTable)
				if ax then return ax, ay, az end
			end
		end
		
		probeResolution = probeResolution * 2
		if probeResolution > maxRes then
					if boolDebug == true then 
						Spring.Echo("Aborting Due to High Probe Resolution"); 
					end
			return 
		end
	end
end

-->ConditionFunctions
function GetSpot_condDeepSea(x, y, chunkSizeX, chunkSizeZ, filterTable)
	h = Spring.GetGroundHeight(x * chunkSizeX, y * chunkSizeZ)
	if h < filterTable.minBelow and h > filterTable.maxAbove then return x * chunkSizeX, y * chunkSizeZ end
end

--> convert Unit to Heightmap
function UnitToHeightMap(unitID)
	bx,by,bz = Spring.GetUnitBasePosition(unitID)
	unitPieceList= Spring.GetUnitPieceMap(unitID)
	processedPieces = {}
	--TODO add Unit rotation, add Piecerotation
	process(unitPieceList,
	function(pieceNumber)
		
		resulT= Spring.GetUnitPieceInfo(unitID,pieceNumber)
		px,py,pz= Spring.GetUnitPiecePosition(unitID,pieceNumber)
		size = {
			x =resulT.max[1],
			y =resulT.max[2],
			z =resulT.max[3]								
		}
		
		processedPieces[pieceNumber] = {
			pos = {x= px,y= py,z= pz},
			p1 = vector:new(size.x,py,size.y) ,
			p2 = vector:new(-size.x,py,size.y) ,
			p3 = vector:new(-size.x,py,-size.y),
			p4 = vector:new(size.x,py,-size.y) ,
			
			
		}
	end
	)
end

--> multiplies a deformation map with a factor
function multiplyHeigthmapByFactor(map, factor)
	for o = 1, #map, 1 do
		for i = 1, #map[o], 1 do
			map[o][i] = map[o][i] * factor
		end
	end
	return map
end

--> blend Heigthmap
function blendToValueHeigthmap(map, dimension, blendStartRadius, blendEndRadius, ValueToBlend)
	center = { x = math.ceil(dimension / 2), z = math.ceil(dimension / 2) }
	total = blendEndRadius - blendStartRadius
	
	for o = 1, dimension, 1 do
		for i = 1, dimension, 1 do
			ldist = distance(center.x, 0, center.z, o, 0, i)
			if ldist > blendStartRadius and ldist < blendEndRadius then
				factor = (ldist - blendStartRadius) / total
				map[o][i] = map[o][i] * (1 - factor) + ValueToBlend * (factor)
			end
		end
	end
	return map
end

--> takes any given MapTable and nullifys the value outside and inside the circle
function circularClampHeigthmap(map, dimension, radius, boolInside, overWriteValue)
	center = { x = math.ceil(dimension / 2), z = math.ceil(dimension / 2) }
	for o = 1, dimension, 1 do
		for i = 1, dimension, 1 do
			
			if distance(center.x, 0, center.z, o, 0, i) > radius then -- we are Outside
				if boolInside == false then
					map[o][i] = overWriteValue
				end
			else
				if boolInside == true then
					map[o][i] = overWriteValue
				end
			end
		end
	end
	return map
end

--> creates a heightmap distortion table
function prepareCupTable(size, height, innerdiameter, percentage)
	if not size or not height then return nil end
	cent = math.ceil(size / 2)
	T = {}
	for o = 1, size, 1 do
		T[o] = {}
		for i = 1, size, 1 do
			--default
			T[o][i] = 0
			distcent = math.sqrt((cent - i) ^ 2 + (cent - o) ^ 2)
			if distcent < cent - 1 then
				T[o][i] = (cent - distcent) * height
				if distcent < innerdiameter then
					T[o][i] = (cent - distcent) * ( height * percentage)
					
				end
			end
		end
	end
	
	return T
end

--> creates a heightmap distortion table
function prepareHalfSphereTable(size, height)
	if not size or not height then return nil end
	cent = math.ceil(size / 2)
	T = {}
	for o = 1, size, 1 do
		T[o] = {}
		for i = 1, size, 1 do
			--default
			T[o][i] = 0
			distcent = math.sqrt((cent - i) ^ 2 + (cent - o) ^ 2)
			if distcent < cent - 1 then
				T[o][i] = (cent - distcent) * height
			end
		end
	end
	
	return T
end


--> creates a heightmap distortion table that averages the height 
function smoothGroundHeigthmap(size, x, z)
	gh = Spring.GetGroundHeight(x, z)
	if not size then return nil end
	
	T = {}
	for o = 1, size, 1 do
		T[o] = {}
		for i = 1, size, 1 do
			lgh = Spring.GetGroundHeight(x + ((o - (size / 2)) * 8), z + ((i - (size / 2)) * 8))
			sign = -1
			if lgh < gh then sign = 1 end
			--default
			T[o][i] = math.abs(gh - lgh) * sign
		end
	end
	return T
end
--> This function process result of Spring.PathRequest() to say whether target is reachable or not
function IsTargetReachable(moveID, ox, oy, oz, tx, ty, tz, radius)
	local result, lastcoordinate, waypoints
	local path = Spring.RequestPath(moveID, ox, oy, oz, tx, ty, tz, radius)
	if path then
		local waypoint = path:GetPathWayPoints() --get crude waypoint (low chance to hit a 10x10 box). NOTE; if waypoint don't hit the 'dot' is make reachable build queue look like really far away to the GetWorkFor() function.
		local finalCoord = waypoint[#waypoint]
		if finalCoord then --unknown why sometimes NIL
			local dx, dz = finalCoord[1] - tx, finalCoord[3] - tz
			local dist = math.sqrt(dx * dx + dz * dz)
			if dist <= radius + 20 then --is within radius?
				result = true
				lastcoordinate = finalCoord
				waypoints = waypoint
			else
				result = false
				lastcoordinate = finalCoord
				waypoints = waypoint
			end
		end
	else
		result = true
		lastcoordinate = nil
		waypoints = nil
	end
	
	return result, lastcoordinate, waypoints
end

-->gets the original Mapheight
function getHistoricHeight(UnitId)
	tempX, tempY, tempZ = Spring.GetUnitPosition(UnitId)
	tempY = Spring.GetGroundOrigHeight(tempX, tempZ)
	return tempY
end

-->Get the Ground Normal, uses a handed over function and returns a corresponding Table
function getGroundMapTable(Resolution, HandedInFunction)
	ReT = {}
	local spGetGroundNormal = Spring.GetGroundNormal
	for x = 1, Game.mapSizeX, Resolution do
		ReT[x] = {}
		for y = 1, Game.mapSizeY, Resolution do
			dx, dy, dz = spGetGroundNormal(x, y)
			ReT[x][y] = Helperfunction(dx, dy, dz)
		end
	end
	return ReT
end

-->Generalized map processing Function
-->Get the Ground Normal, uses all handed over functions for processing and returns a corresponding Table
function doForMapPos(Resolution, ...)
	local arg = arg; if (not arg) then arg = { ... }; arg.n = #arg end
	
	for k, v in pairs(arg) do if type(v) ~= "function" then return Spring.Echo(" Argument is not a processing function") end end
	
	ReT = {}
	for x = 1, Game.mapSizeX, Resolution do
		ReT[x] = {}
		for y = 1, Game.mapSizeY, Resolution do
			res = {}
			for k, v in pairs(arg) do
				res = arg(x, y, res)
			end
			ReT[x][y] = res
		end
	end
	return ReT
end

--======================================================================================
--Section: Syntax additions and Tableoperations
--======================================================================================
function toBool(val)
  local t = type(val)
  if (t == 'nil') then
    return false
  elseif (t == 'boolean') then
    return val
  elseif (t == 'number') then
    return (val ~= 0)
  elseif (t == 'string') then
    return ((val ~= '0') and (val ~= 'false'))
  end
  return false
end


function axToKey(axis)
	if axis == 1 then return "x" end
	if axis == 2 then return "y" end
	if axis == 3 then return "z" end
end

function selectExecute(selector, ...)
	
	local arg = arg; if (not arg) then arg = { ... }; arg.n = #arg end
	if arg[selector] then return selector() end
	
end
-->selects a element from a table
function selStr(index, t)
	if not t[index] then return "" end
	
	return toString(t[index])
end

-->Inserts a Value only if it is not found
function TableInsertUnique(Table, Value)
	for i = 1, #Table do
		if Table[i] == Value then return Table end
	end
	table.insert(Table, Value)
	return Table
end

-->Sanitizes a Variable for a table
function sanitizeItterator(Data, Min, Max)
	return math.max(Min, math.min(Max, math.floor(Data)))
end

-->Splits a Table into Two Tables
function splitTable(T, breakP, breakEnd)
	breakPoint = breakP or math.ceil(#T / 2)
	breakPoint = sanitizeItterator(breakPoint, 1, table.getn(T))
	local T1 = {}
	
	for i = breakPoint, breakEnd, 1 do
		T1[#T1 + 1] = T[i]
	end
	
	return T1
end



function binaryInsertTable(Table, Value, ToInsert, key)
	i = math.floor(table.getn(Table) / 2)
	upLim, loLim = table.getn(Table), 1
	previousi = 1
	if key then ToInsert = { value = ToInsert, key = key }
		
		while true do
			if Value > Table[i] and Table[i + 1] and Value > Table[i + 1] then
				previousi = i
				i = i + math.floor((upLim - loLim) / 2)
				loLim = previousi
			elseif Value < Table[i] and Table[i - 1] and Value < Table[i - 1] then
				previousi = i
				i = i - math.floor((upLim - loLim) / 2)
				uplim = previousi
			else
				table.insert(Table, ToInsert, i)
				return Table, i
			end
		end
	end
end


--> check on the Lock Infrastructur
function checkLocks(Lock)
	if Lock then return Lock end
	
	id= unitID or getUniqueID()
	if not GG.Lock then GG.Lock = {} end
	if not GG.Lock[id] then GG.Lock[id] = {} end
	Lock = Lock or GG.Lock[id]
	return Lock, id
end

--> getUniqueID
--> Takes a Table of Locks and locks it if the lock is free 
function TestSetLock(Lock, number)
	Lock, uid = checkLocks(Lock)
	
	if TestLocks(number) == true then
		Lock[number] = true
		return true, uid
	end
	return false, uid
end

-->Test a rows of locks up to number
function TestLocks(Lock, number)
	Lock = checkLocks(Lock)
	
	for i = 1, table.getn(Lock) do
		if number ~= i and Lock[i] == true then return false end
	end
	return true, uid
end

--> Sets a Lock free
function ReleaseLock(Lock, number)
	Lock,uid = checkLocks(Lock)
	
	Lock[number] = false
	return Lock[number] , uid
end


-->Get the lowest Value in a table
function getLowest(Table)
	lowest = 0
	val = 0
	for k, v in pairs(Table) do
		if v < val then
			val = v
			lowest = k
		end
	end
end

--> Sums up all values in a table
function sumTable(Table)
	a = 0
	for i = 1, #Table do
		a = a + Table[i]
	end
	return a
end

function sumDict(Table)
	a = 0
	for k, v in pairs(Table) do
		a = a + v
	end
	return a
end

function tableToDict(T)
	reT = {}
	if not T then return reT end
	
	for i = 1, #T do
		if T[i] then
			reT[T[i]] = T[i]
		end
	end
	return reT
end

function mergeTables(...)
	local arg = arg; if (not arg) then arg = { ... }; arg.n = #arg end
	Table = {}
	if not arg then return end
	
	for _, v in pairs(arg) do
		if v and type(v) == "table" then
			Table = TableMergeTable(Table, v)
		end
	end
	
	return Table
end

function dictToTable(dict)
	num=1
	T= {}
	for k,v in pairs(dict) do
		if v then
			T[num]= k
			num= num +1
		end
	end
	return T
	
end


function TableMergeTable(TA, TB)
	T = {}
	if #TA >= #TB then
		T = tableToDict(TA)
		
		for i = 1, #TB do
			if not T[TB[i]] then
				TA[#TA + 1] = TB[i]
			end
		end
		return TA
	else
		T = tableToDict(TB)
		for i = 1, #TA do
			if not T[TA[i]] then
				TB[#TB + 1] = TA[i]
			end
		end
		return TB
	end
end


function removeDictFromDict(dA, dB)
	for k, v in pairs(dA) do
		dB[k] = nil
	end
	return dB
end


function pieceToPointT(piecesTable)
	
	if type(piecesTable) == "number" then
		return {[1]=pieceToPoint(piecesTable)}
	end	
	
	if not piecesTable then
		echo("lib_UnitScript::pieceToPointT: No argument recived")
		return
	end
	
	reTab = {}
	
	for i = 1, #piecesTable do
		reTab[i] = {}
		reTab[i].Piece = piecesTable[i]
		x,y,z = Spring.GetUnitPiecePosDir(unitID, piecesTable[i])
		assert(z, "Z not defined for piece"..piecesTable[i].." aka ".. getUnitPieceName(unitID,piecesTable[i]))
		assert(y, "Y not defined for piece"..piecesTable[i].." aka ".. getUnitPieceName(unitID,piecesTable[i]))
		assert(z, "Z not defined for piece"..piecesTable[i].." aka ".. getUnitPieceName(unitID,piecesTable[i]))
		
		reTab[i].x, reTab[i].y, reTab[i].z = x,y,z
		reTab[i].index = i
	end
	
	return reTab
end

function getLowestPointOfSet(Table, axis)
	
	if #Table < 1 then return nil end
	
	local lowIndex = 1
	y = math.huge
	if axis == "y_axis" then
		for i = 1, #Table do
			if Table[i].y < y then
				y = Table[i].y
				lowIndex = i
			end
		end
	end
	if axis == "z_axis" then
		for i = 1, #Table do
			if Table[i].z < z then
				z = Table[i].z
				lowIndex = i
			end
		end
	end
	if axis == "x_axis" then
		for i = 1, #Table do
			if Table[i].x < x then
				x = Table[i].x
				lowIndex = i
			end
		end
	end
	return Table[lowIndex].x, Table[lowIndex].y, Table[lowIndex].z, index
end

function getHighestPointOfSet(Table, axis)
	if type(Table) ~= "table" then
		echo("getHighestPointOfSet:not a table")
		return nil
	end
	
	
	if count(Table) == 0 then
		echo("getHighestPointOfSet:table is empty")
		return nil
	end
	
	index = 1
	y = -math.huge
	if axis == "y_axis" then
		for i = 1, #Table do
			if Table[i].y > y then
				y = Table[i].y
				index = i
			end
		end
	end
	if axis == "z_axis" then
		for i = 1, #Table do
			if Table[i].z > y then
				y = Table[i].z
				index = i
			end
		end
	end
	if axis == "x_axis" then
		for i = 1, #Table do
			if Table[i].x > y then
				y = Table[i].x
				index = i
			end
		end
	end
	
	
	return Table[index].x, Table[index].y, Table[index].z, index
end


function inherit(childClass, parent)
	local orig_type = type(parent)
	local copy = parentClass or {}
	
	for orig_key, orig_value in next, parent, nil do
		copy[deepcopy(orig_key)] = deepcopy(orig_value)
	end
	setmetatable(copy, deepcopy(getmetatable(parent)))
	--add Operators to unitscript
	return copy
end




--> checks wether a value with threshold factor is within range of a second value
function withinRange(value1, value2, treShold)
	if value1 * treShold > value2 or value1 * (1 - treShold) < treShold then
		return true
	else
		return false
	end
end

--> merges two Dictionary Tables with the first having precedence
function mergeDict(l_dA, l_xdB) 
	if l_dA and not l_xdB then return l_dA end
	if l_xdB and not l_dA then return l_xdB end
	local l_dB = l_xdB
	for k,v in pairs(l_dA) do
		l_dB[k] = v
	end
	return l_dB
end

--> returns a subset of Unitdefs by UnitdefID
function selectUnitDefs(l_names)
	local l_retT={}
	
	for num, uDefID in pairs(l_names) do
		
		l_retT[uDefID]= UnitDefs[uDefID]	
	end
	return l_retT
end

--> returns a subset of Unitdefs by name as string 
function UnitDefToUnitDefNames(UnitDef)
	local l_retT = UnitDef
	for defID, T in pairs(UnitDef) do
		l_retT[T.name] = T
	end
	return l_retT
end

--> Encapsulates the Show function for easier debugging
function capShow(l_Num)
	assert(l_Num)
	assertNum(l_Num)
	
	Show(l_Num)
end

--> Encapsulates the Hide function for easier debugging
function capHide(l_Num)
	assert(type(l_Num)=="number")
	Hide(l_Num)
end

--> Encapsulates the hide Table function
function capHideT(l_T)
	for k,v in pairs(l_T) do
		assertNum(v, v)
	end
	hideT(l_T)
end

--> Echos out all the elements of a unitdef Table
function echoUnitDefT(l_defT)
	for k,v in pairs(l_defT) do 
		echo(UnitDefs[v].name)
	end
end

--> Hides a PiecesTable, 
function hideT(l_tableName, l_lowLimit, l_upLimit, l_delay)
	if not l_tableName then return end
	boolDebugActive = (lib_boolDebug == true and l_lowLimit and type(l_lowLimit) ~= "string")
	
	if l_lowLimit and l_upLimit then
		for i = l_upLimit, l_lowLimit, -1 do
			if l_tableName[i] then
				Hide(l_tableName[i])
			elseif boolDebugActive == true then
				echo("In HideT, table " .. l_lowLimit .. " contains a empty entry")
			end
			
			if l_delay and l_delay > 0 then Sleep(l_delay) end
		end
		
	else
		for i = 1, table.getn(l_tableName), 1 do
			if l_tableName[i] then
				Hide(l_tableName[i])
			elseif boolDebugActive == true then
				echo("In HideT, table " .. l_lowLimit .. " contains a empty entry")
			end
		end
	end
end

-->Shows a Pieces Table
function showT(l_tableName, l_lowLimit, l_upLimit, l_delay)
	if not l_tableName then Spring.Echo("No table given as argument for showT") return end
	
	if l_lowLimit and l_upLimit then
		for i = l_lowLimit, l_upLimit, 1 do
			if l_tableName[i] then
				Show(l_tableName[i])
			end
			if l_delay and l_delay > 0 then Sleep(l_delay) end
		end
		
	else
		for i = 1, table.getn(l_tableName), 1 do
			if l_tableName[i] then
				Show(l_tableName[i])
			end
		end
	end
end

function subSetT(T, elementToSelect)
	reT= {}
	
	for i=1, #T do
		reT[#reT+1] = T[i][elementToSelect]
	end
	return reT
end

--> safeAccessTable a table three layers deep on any key/index
function safeAccessTable(T, a, b, c)
	if a and not T[a] then T[a] = {} end
	if b and not T[a][b] then T[a][b] = {} end
	if c and not T[a][b][c] then T[a][b][c] = {} end
	return T
end


function split(str, pattern)
	pattern = pattern or "[^%s]+"
	if pattern:len() == 0 then
		pattern = "[^%s]+"
	end
	local parts = {__index = table.insert}
	setmetatable(parts, parts)
	str:gsub(pattern, parts)
	setmetatable(parts, nil)
	parts.__index = nil
	return parts
end

function stringSplit(String, Seperator)
	if Seperator == nil then sep = "%s" end
	local t={} ; i=1
	for str in string.gmatch(String, "([^"..sep.."]+)") do
		t[i] = str
		i = i + 1
	end
	return t
end

--> Creates Global Tables from a access string e.g. 
-->make a GlobalTableHierarchy From a Set of Arguments - String= Tables, Numbers= Params
-->Example: "TableContaining[key].TableReamining[key].valueName" or [nr] , valueGG.MyGlobalTable.HasASubTable.WithA[Key].ThatHoldsATable
function createGlobalTableFromAcessString(FormatString, assignedValue, ...)
	local arg = arg; if (not arg) then arg = { ... }; arg.n = #arg end
	local PreFix = "GG."
	local formatStringFunction = loadstring(PreFix..FormatString)
	
	-- test for allread existing table
	boolAccessSuccessfull = false
	boolTestDone=false
	attempts= 0
	
	StartThread(function ()	
		if formatStringFunction() then
			loadstring(PreFix..FormatString.." = "..toString(assignedValue))(); 
			boolAccessSuccessfull= true 
		end
		boolTestDone= false
	end
	)
	
	repeat
		Sleep(1)
		attempts= inc(attempts)
	until boolTestDone == true or attempts > 3
	
	if boolAccessSuccessfull == true then return end
	
	
	
	
	--SplitByDot
	
	local SubTables = stringSplit(FormatString, ".")
	
	boolAvoidFutureChecks = false
	for i = 1, #SubT do
		local subTableString = SubT[i]
		if SubT[i] ~= "GG" then
			SubT[i] = string.gsub(SubT[i], ".")
			ExtracedIndex = string.match(SubT[i], "[", "]")
			ExtractedTable = string.gsub(SubT[i], ExtracedIndex, "")
			Terminator = "."
			if ExtractedTable then
				if boolAvoidFutureChecks == true or not loadstring(PreFix .. ExtractedTable)() then
					loadstring(PreFix .. ExtractedTable .. "= {}")
					boolAvoidFutureChecks = true
				end
			else ExtractedTable = ""; Terminator = ""
			end
			if boolAvoidFutureChecks == true or ExtracedIndex and not loadstring(PreFix .. ExtractedTable .. ExtracedIndex)() then
				loadstring(PreFix .. ExtractedTable .. ExtracedIndex .. "={}")()
			end
			
			PreFix = PreFix .. ExtractedTable .. ExtracedIndex .. Terminator
		end
	end
	
	
	loadstring(PreFix .. "=" .. assignedValue)()
	return loadstring(PreFix .. "==" .. asignedValue)()
end

--> Creates a Table and initializes it with default value
function makeTable(default, xDimension, yDimension, zDimension, boolNegativeMirror)
	boolNegativeMirror= boolNegativeMirror or false	
	
	xStartIndex = 1
	yStartIndex = 1
	zStartIndex = 1
	
	if boolNegativeMirror == true then
		xStartIndex = -xDimension
		yStartIndex = -yDimension
		zStartIndex = -zDimension
	end
	
	local RetTable = {}
	if not xDimension then return default end
	
	for x = xStartIndex, xDimension, 1 do
		if yDimension then
			RetTable[x] = {}
		elseif xDimension then
			RetTable[x] = default
		else
			return default
		end
		
		if yDimension then
			for y = yStartIndex, yDimension, 1 do
				if zDimension then
					RetTable[x][y] = {}
				else
					RetTable[x][y] = default
				end
				
				if zDimension then
					for z = zStartIndex, zDimension, 1 do
						RetTable[x][y][z] = default
					end
				end
			end
		end
	end
	return RetTable
end

--> rotate zero Centric Table
function rotateMap(Map, sizeX,sizeZ, degreeRotation, default)
	local rotateCopy= makeTable(default, sizeX, sizeZ, nil, true )
	for x=-sizeX,sizeX do
		for z=-sizeZ,sizeZ do
			if Map[x][z] ~= default then
				rx, rz= Rotate(x, z, math.rad(degreeRotation))
				rotateCopy[rx][rz]= Map[x][z]
			end
		end
	end
	
	return rotateCopy
end


--> shifts a 2d Map by a vector, replaces empty values with default
function shiftMap(Map, sizeX,sizeZ, offX, offZ, default)
	local shiftedMap = makeTable(default, sizeX, sizeZ, nil, true )
	for x=-sizeX, sizeX do
		for z=-sizeZ, sizeZ do
			if Map[x][z] ~= default and shiftedMap[x+offX] and shiftedMap[x+offX][z+offZ] then
				shiftedMap[x+offX][z+offZ]= Map[x][z]
			end
		end
	end
	return shiftedMap
end
-->Creates a table of piecenamed enumerated strings
function makeTableOfPieceNames(l_name, l_nr, l_startnr, l_piecefoonction)
	local T = {}
	l_start = l_startnr or 1
	
	for i = l_start, l_nr do
		namecopy = l_name
		namecopy = namecopy .. i
		T[i] = namecopy
	end
	if l_piecefoonction then
		for i = l_start, l_nr do
			T[i] = l_piecefoonction(T[i])
		end
	end
	return T
end

--> Adds to a Table, argument as keys, subtables
function addTableTables(T, ...)
	local arg = arg; if (not arg) then arg = { ... }; arg.n = #arg end
	String = "T"
	boolOneTimeNil = false
	if arg then
		for k, v in ipairs(arg) do
			String = String .. "[" .. v .. "]"
			
			if boolOneTimeNil == false then
				if loadstring(String) ~= nil then
				else
					boolOneTimeNil = true
				end
			else
				loadstring(String .. "={}")
			end
		end
	end
	return T
end

-->filters out the dead 
function validateUnitTable(T)
	TVeryMuchAlive = {}
	
	for i = #T, 1, -1 do
		boolUnitDead = Spring.GetUnitIsDead(T[i])
		if boolUnitDead and boolUnitDead == false then
			TVeryMuchAlive[#TVeryMuchAlive + 1] = T[i]
		end
	end
	
	return TVeryMuchAlive or {}
end

-->adds a numeric Table to a numeric Table
function TAddT(OrgT, T)
	for i = 1, #T do
		OrgT[#OrgT + i] = T[i]
	end
	return OrgT
end

--> Counts the number of elements in a dictionary
function count(T)
	if not T then return 0 end
	local index = 0
	for k,v in pairs(T) do 
		if v then 
			index= index +1 
		end 
	end
	return index
end


function getNthElementT(T, nth)
	local index = 0
	for k,v in pairs(T) do
		if v then index= index +1 end 
		if index== nth then 
			return k, v1
		end
	end
end

-->Retrieves a random element from a Dictionary
function randDict(Dict)
	if lib_boolDebug == true then
		assert(type(Dict)=="table")
	end
	
	randElement = math.random(1,count(Dict))
	index= 1
	anyElement=1
	for k,v in pairs (Dict) do
		anyElement = k
		if index ==randElement then 
			return k,v
		end
		index=inc(index)
	end
	return anyElement
end

--> randomizes Table Entrys
function shuffleT(T)
	local	randT= {}
	size = count(T)
	allreadyInserted={}
	
	for i = 1, size do
		rIndexStart = math.random(1, size)
		boolFoundSomething = false
		for k = rIndexStart, size do
			if not allreadyInserted[k] then
				key,v = getNthElementT(T, k)
				randT[i] = T[key] 
				allreadyInserted[k]=true				
				boolFoundSomething = true
			end
		end
		
		if boolFoundSomething == false then
			for k = 1, rIndexStart do
				if not allreadyInserted[k] then
					key,v = getNthElementT(T, k)
					randT[i] = T[key] 
					allreadyInserted[k]=true
				end
			end
		end
	end
	
	return randT
end

-->Copys a table
function tableCopy(orig)
	local orig_type = type(orig)
	local copy
	if orig_type == 'table' then
		copy = {}
		for orig_key, orig_value in next, orig, nil do
			copy[tableCopy(orig_key)] = tableCopy(orig_value)
		end
		setmetatable(copy, tableCopy(getmetatable(orig)))
	else
		copy = orig
	end
	return copy
end

--> Destroys A Table of Units
function DestroyTable(T, boolSelfd, boolReclaimed, condFunction, unitID)
	if T then
		for i = 1, #T, 1 do
			if condFunction(T[i]) == true then
				Spring.DestroyUnit(T[i], boolSelfd, boolReclaimed, unitID)
			end
		end
	end
end

--> Explodes a Table of Pieces 
function explodeT(TableOfPieces, Conditions, StepSize)
	lStepSize = StepSize or 1
	for i = 1, #TableOfPieces, lStepSize do
		Explode(TableOfPieces[i], Conditions)
	end
end

--> Recursively Echo a Table out
function echoT(T, layer)
	local l = layer or 0
	if T then
		if type(T) == 'table' then
			Spring.Echo(stringBuilder( l, "-") .. "[]T:")
			for k, v in pairs(T) do
				Spring.Echo(stringBuilder( l, " ").."Key [\""..k.."\"]")					
				echoT(T[k], l + 1)
			end
		else
			Concated = stringBuilder( math.max(1, l) - 1, " ") .. "|-►"
			
			typus = type(T)
			if typus == "number" or typus == "string" then
				Spring.Echo(Concated .. T)
			elseif typus == "boolean" then
				Spring.Echo(Concated .. "boolean" .. ((T == true) and "True"))
			elseif typus == "function" then
				Spring.Echo(Concated .. "function: Result")
				resulT= T()
				if type(resulT)=="table" then
					echoT(resulT,layer)
				else
					echo(resulT)
				end
			end
		end
	end
end

-->Generic to String
function toString(element)
	typeE = type(element)
	
	if typeE == "boolean" then return boolToString(element) end
	if typeE == "number" then return ""..element end
	if typeE == "string" then return element end
	if typeE == "table" then return tableToString(element) end
	
	
end

function echoUnitDefs(unitDefNames)
for k,v in pairs(unitDefNames) do
	for key,values in pairs(v) do
		echoT({key, values})
	end
end

end

function tableToString(tab)
	PostFix = "}"
	PreFix = "{"
	conCat=""..PreFix
	for key, value in pairs(tab) do
		conCat= conCat.."["..toString(key).."] ="..toString(value)..","
	end
	
	return conCat..PostFix
end

--> Converts a stringserialized table back into a data table
function stringToTable(stringT)
	foonction = "function() return "..stringT.." end"
	return loadstring(foonction)
end

--> Converts a boolean to a string value
function boolToString(value)
	if value == true then return "true" else return "false" end
end


function filterTableByTable(T, T2, compareFunc)
	reTable = {}
	for i = 1, #T do
		if compareFunc(T[i], T2) == true then reTable[#reTable + 1] = T[i] end
	end
	return reTable
end



function keyTableToTables(T)
	counter = 1
	TableKey = {}
	TableValue = {}
	counter = 1
	for k, v in pairs(T) do
		TableKey[counter] = k
		TableValue[counter + 1] = v
		counter = counter + 2
	end
	
	return TableKey, TableValue
end

function insertKeysIntoTable(T, T2)
	for i = 1, #T do
		if not T2[T[i]] then
			T2[T[i]] = T[i]
		end
	end
	return T2
end

-->itterates over a table, executing a function with a argumentTable
function elementWise(T, fooNction, ArghT)
	reTable = {}
	
	for k, v in pairs(T) do
		reTable[k] = fooNction(T[k], ArghT)
	end
	
	return reTable
end

-->recursive itterates over a Keytable, executing a function 
function recElementWise(T, fooNction, ArghT)
	reTable = {}
	
	for k, v in pairs(T) do
		if type(T[k]) ~= "table" then
			reTable[k] = fooNction(T[k], ArghT)
		else
			reTable[k] = recElementWise(T[k], fooNction, ArghT)
		end
	end
	
	return reTable
end

-->count Elements in a Dictionary
function countT(T)
	it = 0
	for k, v in pairs(T) do
		it = it + 1
	end
	return it
end

function sortDictKeysNumeric(T)
	local sorT={}
	
	for k,v in pairs(T) do
		for i=1,#sorT do
			if k > sorT[i] then
				table.insert(sortT,i, k)
				break
			end
		end
	end
	return sortT
end

function inLimit(lowLimit,value,upLimit)
	if value < lowLimit or value > upLimit then return false end
	return true
end


--> find in intervallTable, returns the lower, upper Entry, a fractionnumber of upper and lower entry
function findInIntervall(T, discreteValue)
	
	numericSortedKeys = sortDictKeysNumeric(T)
	upperVal= T[numericSortedKeys[#numericSortedKeys]]
	lowerVal= T[numericSortedKeys[1]]
	
	for i=1,#numericSortedKeys do
		key, _ = numericSortedKeys[i], T[numericSortedKeys[i]]
		
		if discreteValue <= key then
			upperVal = key
		end
		
		if discreteValue > key then -- search is done
			lowerVal= key
			disLow, disUp= discreteValue - lowerVal, upperVal - discreteValue
			fraction = disLow/(disLow + disUp)
			return T[lowerVal], T[upperVal], mix( T[lowerVal], T[upperVal], fraction)
		end
	end
end



--> Join Operation on two tables
join = function(id, argT)
	resulT = {}
	for num, idInTable in pairs(argT) do
		resulT[#resulT + 1] = { id = id, obj = idInTable }
	end
	return resulT
end

--> Validator
validator = function(id)
	deadOrAlive = Spring.GetUnitIsDead(id)
	if deadOrAlive and deadOrAlive == false then
		return id
	end
end

--> takes a Table, and executes Function on it
-- non Function Values are handed to the function following it
-- returning nil removes a element from the process chain
function process(Table, ...)
	local arg = { ... }
	local arg = arg; if (not arg) then arg = { ... }; arg.n = #arg end
	T = {}
	if Table then
		T = Table
	else
		if lib_boolDebug == true then
			echo("Lua:lib_UnitScript:Process: No Table handed over")
			return
		end
	end
	if not arg then echo("No args in process") return end
	if type(arg) == "function" then return elementWise(T, arg) end
	
	
	TempArg = {}
	TempFunc = {}
	--if not arg then return Table end
	
	for _, f in pairs(arg) do
		if type(f) == "function" then
			T = elementWise(T, f, TempArg)
			TempArg = {}
		else
			TempArg[#TempArg + 1] = f
		end
	end
	return T
end

-->traverses tables and applys a function to them
function recProcess(Table, ...)
	local arg = { ... }
	local arg = arg; if (not arg) then arg = { ... }; arg.n = #arg end
	T = {}
	if Table then T = Table else echo("Lua:lib_UnitScript:Process: No Table handed over") return end
	if not arg then echo("No args in process") return end
	if type(arg) == "function" then return elementWise(T, arg) end
	
	
	TempArg = {}
	TempFunc = {}
	--if not arg then return Table end
	
	for _, f in pairs(arg) do
		if type(f) == "function" then
			T = recElementWise(T, f, TempArg)
			TempArg = {}
		else
			TempArg[#TempArg + 1] = f
		end
	end
	return T
end

--======================================================================================
--Section: Geometry/Math functions
--======================================================================================

function getNearestPositionOnCircle(pCenter, Radius, pPos)
local rPos={x=0,y=0,z=0}

rPos.x = pCenter.x + Radius* ((pPos.x - pCenter.x)/ math.sqrt((pPos.x-pCenter.x)^2 + (pPos.z- pCenter.z)^2))
rPos.z = pCenter.z + Radius* ((pPos.z- pCenter.z)/ math.sqrt((pPos.x-pCenter.x)^2 + (pPos.z- pCenter.z)^2))
--circle equation solved for z: sqrt( -([(pCenter.z -b)/m]- pCenter.x)^2  + Radius) + pCenter.z =   rPos.z
--circle equation solved for x: x  = sqrt(Radius - (z -pCenter.z)^2) + 


return rPos
end


function computateBendLimits(piecename,parent)
	paPosX,paPosY,paPosZ=Spring.GetUnitPiecePosition(unitID,parent)
	cPosX,cPosY,cPosZ=Spring.GetUnitPiecePosition(unitID,piecename)
	
	--the offset of the piece in relation to its parentpiece
	v={}
	v.x,v.y,v.z=cPosX-paPosX,cPosY-paPosY,cPosZ-paPosZ
	
	pax,pay,paz=Spring.GetUnitPieceCollisionVolumeData(unitID,parent)
	radOfParentSphere=getCubeSphereRad(pax,pay,paz)
	cx,cy,cz=Spring.GetUnitPieceCollisionVolumeData(unitID,piecename)
	radOfPieceSphere=getCubeSphereRad(cx,cy,cz)
	-- rotate the vector so that it aligns with x,y,z origin vectors
	-- computate the orthogonal 
	-- computate the dead degree cube
	wsize=triAngleTwoSided(v.x,v.y)
	-- rotate the computated window inverse to the vector back
	-- voila
	
	--Y-Axis 
	-->TODO:RAGDOLL |_\ -- you approximate the motherpiece with a circle and then do a math.acos( circleradius/distance)
	--defaulting to a maxturn
	return {ux=-15 ,x=15, uy=-180, y=180,uz=-15, z=15}
end
function get2DSquareFormationPosition(nr, size, unitsInRow)
	
	row = math.floor(nr/unitsInRow)
	place = nr % unitsInRow 
	return row*size, place*size
end

function getAveragePosT(T)
	ax,ay,az= 0,0,0
	counter= 0
	process(T,
	function(id)
		ix,iy,iz= Spring.GetUnitPiecePosDir(unitID,id)
		if ix then
			ax,ay,az= ax +ix, ay +iy, az +iz
			counter = counter+1
		end
	end
	)
	return ax/counter,ay/counter,az/counter		
	
end

--> returns the Midpoint of two given points
function getMidPoint(a, b)
	ax, ay, az = a.x, a.y, a.z
	bx, by, bz = b.x.b.y, b.z
	return (ax - bx) / 2 + ax, (ay - by) / 2 + ay, (az - bz) / 2 + az
end

function swingPointOutFromCenterByFrame(ax, ay, az, frame, swing, totalFrame)
	extend = swing * math.sin(frame / totalFrame) * randSign()
	return ax + math.random(math.min(extend, extend * -1), math.abs(extend)),
	ay + math.random(math.min(extend, extend * -1), math.abs(extend)),
	az + math.random(math.min(extend, extend * -1), math.abs(extend))
end


function square(...)
	local arg = arg; if (not arg) then arg = { ... }; arg.n = #arg end
	if not arg then return 0 end
	sum = 0
	for k, v in pairs(arg) do
		if v then
			sum = sum + v ^ 2
		end
	end
	return math.sqrt(sum)
end

--> computes the result of the middleSqreWeylSequence
function middleSquareWeylSequence(itterations)
	
	s = 0xb5ad4ece
	x =0
	w= 0
	
	for i=1,itterations do
		
		
		x =x* x; 
		w= w + s;
		x = x + w;
		x = math.bit_or((x / 2^5), (x * 2 ^5));
		
	end
	
end

--> returns a Unique ID - upper limit is 565939020162275221
function getUniqueID()
	if not GG.GUID then GG.GUID = 0 end
	GG.GUID = GG.GUID + 0.1 / math.pi
	return GG.GUID
end


--> finds the radian in a triangle where only the lenght of two sides are known
function triAngleTwoSided(LowerSide, OpposingSide)
	norm = math.sqrt(LowerSide * LowerSide + OpposingSide * OpposingSide)
	return math.atan2(LowerSide / norm, OpposingSide / norm)
end

function getCubeSphereRad(x, y, z)
	xy, xz, yz = x * y, x * z, y * z
	
	if xy > xz and xy > yz then return math.sqrt(x * x + y * y) end
	
	if xz > xy and xz > yz then return math.sqrt(x * x + z * z) end
	
	if yz > xy and yz > xz then return math.sqrt(y * y + z * z) end
end

function topsideRayTrace(pWorldx,pWorldy, Objects)
	default = -math.huge
	
	for _,obj in pairs(Objects) do
		if isPointInSquare(obj.pos, obj.p1,obj.p2,obj.p3, obj.p4) == true then return obj.pos.py end
		
	end
	
	return default
end

function isPointInSquare(P, s1, s2, s3, s4)
	return pointWithinTriangle(s1.x,s1.y,s2.x,s2.y,s3.x,s3.y,P.x,P.y) or pointWithinTriangle(s3.x,s3.y,s4.x,s4.y,s1.x,s1.y,P.x,P.y)
end

function holdsForAll(Var, fillterConditionString, ...)
	assert(fillterConditionString)
	local arg = arg; if (not arg) then arg = { ... }; arg.n = #arg end
	if arg then
		for k, Val in pairs(arg) do
			if Var and Val then
				condFunction = loadstring("return ("..Var .. fillterConditionString .. Val..")")
				if not condFunction or condFunction() == false then return end
			end
		end
		return true
	end
	return true
end
function makeNewAffirmativeMatrice()
	V = {
		[1] = 1,
		[2] = 0,
		[3] = 0,
		[4] = 0,
		[5] = 0,
		[6] = 1,
		[7] = 0,
		[8] = 0,
		[9] = 0,
		[10] = 0,
		[11] = 1,
		[12] = 0,
		[13] = 0,
		[14] = 0,
		[15] = 0,
		[16] = 1
	}
	function V.Mul(other)
		V[1] = 0; V[2] = 0; V[3] = 0; V[4] = 0;
		V[5] = 0; V[6] = 0; V[7] = 0; V[8] = 0;
		V[9] = 0; V[10] = 0; V[11] = 0; V[12] = 0;
		V[13] = 0; V[14] = 0; V[15] = 0; V[16] = 1
	end
	
	--TODO
	--http://springrts.com/phpbb/viewtopic.php?f=21&t=32246
	return V
end


--> produces a Rotation matrice around axis for a degree in affirmative Coordinates
function makeAffirmativeRotate(axis, deg_)
	V = makeNewAffirmativeMatrice()
	if axis == "x_axis" then
		V[6] = math.cos(-deg_)
		V[7] = -1 * math.sin(-deg_)
		V[10] = math.sin(-deg_)
		V[11] = math.cos(-deg_)
		
	elseif axis == "y_axis" then
		V[1] = math.cos(-deg_)
		V[3] = math.sin(-deg_)
		V[9] = -1 * math.sin(-deg_)
		V[11] = math.cos(-deg_)
	else
		V[1] = math.cos(-deg_)
		V[5] = math.sin(-deg_)
		V[2] = -1 * math.sin(-deg_)
		V[6] = math.cos(-deg_)
	end
	return V
end
-->samples over a given Array around Point x,y, with the samplefunction 
function sample(NumericIndex, x, y, sampleFunction, factor)
	quadNumericIndex = {}
	if type(NumericIndex) == "number" then
		for i = -1 * NumericIndex, NumericIndex do
			for j = -1 * NumericIndex, NumericIndex do
				
				quadNumericIndex[i][j] = { x = i * factor, z = j * factor }
			end
		end
	else
		quadNumericIndex = NumericIndex
	end
	
	for i = 1, #quadNumericIndex, 1 do
		for j = 1, #quadNumericIndex, 1 do
			quadNumericIndex[i][j] = sampleFunction(x + quadNumericIndex[i][j].x, y + (quadNumericIndex[i][j].z or quadNumericIndex[i][j].y))
		end
	end
	return quadNumericIndex
end

--> returns the distance between two heigthvalues
function getGroundHeigthDistance(h1, h2)
	return distance(h1, 0, 0, h2, 0, 0)
end


function pieceToPoint(pieceNumber)
	local reTab = {}
	
	reTab.x, reTab.y, reTab.z = Spring.GetUnitPiecePosition(unitID, pieceNumber)
	reTab.index =1
	return reTab
end

--> Builds the second norm Squareroot over x arguments
function normTwo(...)
	local arg = arg; if (not arg) then arg = { ... }; arg.n = #arg end
	sum = 0
	for k, v in pairs(arg) do
		sum = sum + v * v
	end
	return math.sqrt(sum)
end

--> used to symbolically create shadder matrixes in lua.. fill in, calc, optimize, print out
function matrixLab()
	mA = {
		[1] = "cos(z)",
		[2] = "-sin(z)",
		[3] = "0",
		[4] = "sin(z)",
		[5] = "cos(z)",
		[6] = "0",
		[7] = "0",
		[8] = "0",
		[9] = "1",
	}
	mB = {
		[1] = "-1",
		[2] = "0",
		[3] = "0",
		[4] = "0",
		[5] = "cos(x)",
		[6] = "-sin(x)",
		[7] = "0",
		[8] = "sin(x)",
		[9] = "cos(x)",
	}
	mC = {
		[1] = "cos(y)",
		[2] = "0",
		[3] = "sin(y)",
		[4] = "0",
		[5] = "1",
		[6] = "0",
		[7] = "-sin(y)",
		[8] = "0",
		[9] = "cos(y)",
	}
	
	
	mD = MatrixBuilder3x3(MatrixBuilder3x3(mA, mB), mC)
	--echoT(mD)
end

function getCircleIndex(index)
	if index==1 then return -1,0 end
	if index==2 then return 0,1 end
	if index==3 then return 1,0 end
	if index==4 then return 0,-1 end
end

function mirrorMatriceXAxis(x, y, z)
	--return 360-x,y,z*-1																																							
	
	x = ((-1 * math.cos(z)) * math.cos(y)) + ((-1 * math.sin(z) * -1 * math.sin(x)) * -1 * math.sin(y)) * x + ((-1 * math.sin(z) * math.cos(x))) * y + ((-1 * math.cos(z)) * math.sin(y)) + ((-1 * math.sin(z) * -1 * math.sin(x)) * math.cos(y)) * z
	
	y = ((-1 * math.sin(z)) * math.cos(y)) + ((math.cos(z) * -1 * math.sin(x)) * -1 * math.sin(y)) * x + ((math.cos(z) * math.cos(x))) * y + ((-1 * math.sin(z)) * math.sin(y)) + ((math.cos(z) * -1 * math.sin(x)) * math.cos(y)) * z
	
	z = ((math.cos(x)) * -1 * math.sin(y)) * x + ((math.sin(x))) * y + ((math.cos(x)) * math.cos(y)) * z
	return x, y, z
end




function midVector(PointA, PointB)
	PointA.x, PointA.y, PointA.z = PointA.x + PointB.x, PointA.y + PointB.y, PointA.z + PointB.z
	return divVector(PointA, 2)
end


function checkCenterPastPoint(MidPoint, GatePoint, PrevGatePoint)
	
	OrgPoint = subVector(GatePoint, PrevGatePoint)
	assert(OrgPoint)
	MirrorPointV = mulVector(OrgPoint, -1)
	
	-- if distance to PrevGatePoint < then distance to mirrored Point
	if norm2Vector(subVector(MirrorPointV, MidPoint)) >= norm2Vector(subVector(OrgPoint, MidPoint)) then
		return true
	else
		return false
	end
end

function absVec(vec)
	vec.x = math.abs(vec.x)
	vec.y = math.abs(vec.y)
	vec.z = math.abs(vec.z)
	return vec
end

function eqVec(vecA, vecB)
	return vecA.x == vecB.x and vecA.y == vecB.y and vecA.z == vecB.z
end

-->Counts the digits of a number
function getDigits(number)
	digit = 1
	if number < 0 then digit = 2 end
	while math.abs(number) > 10 do
		number = number / 10
		digit = digit + 1
	end
	return digit
end


--> Transfers a World Position into Unit Space
function worldPosToLocPos(owpX, owpY, owpZ, wpX, wpY, wpZ)
	return wpX - owpX, wpY - owpY, wpZ - owpZ
end

--> returns true if point is within range -returns false if it is on the outside
local previousResult
local previousCubic
local rangeOfOld = -1


--> faster way of finding out wether a point is within a circle
function isWithinCircle(circleRange, xCoord, zCoord)
	newCubic = 0
	if rangeOfOld == circleRange then
		newCubic = previousCubic
	else
		newCubic = 0.7071067811865475 * circleRange
		previousCubic = newCubic
	end
	
	negCircleRange = -1 * circleRange
	
	--checking the most comon cases |Coords Outside the Circlebox
	if xCoord > circleRange or xCoord < negCircleRange then
		return false
	end
	
	if zCoord > circleRange or zCoord < negCircleRange then
		return false
	end
	
	negNewCubic = -1 * newCubic
	
	
	--checking everything within the circle box
	if (xCoord < newCubic and xCoord > negNewCubic) and (zCoord < newCubic and zCoord > negNewCubic) then
		return true
	end
	
	
	-- very few cases make it here.. to the classic, bad old range compare
	if math.sqrt(xCoord ^ 2 + zCoord ^ 2) < circleRange then
		return true
	else
		return false
	end
end

-->Function estimates the relative Position of a Piece to another by comparing ther Coordinates
function piecePositionComperator(myPos, PiecePos, cubicsize)
	
	--[1]=--front
	--[2]=--rear
	--[3]=--side left
	--[4]=	--side right
	--[5]=	--up
	--[6]=	--low
	
	
	if withinRange(myPos.y, PiecePos.y, cubicsize) == true then
		
		if withinRange(myPos.x, PiecPos.x, cubicsize) == true then -- Piece is on the side
			if myPos.z > piecePos.z then return 3 else return 4 end
		else -- Piece is either in front or behind
			if myPos.x > piecePos.x then return 2 else return 1 end
		end
	else -- pos is either above or below the layer 
		if myPos.y > PiecePos.y then return 6 else return 5 end
	end
end

--> Checks wether a Point is within a six sided polygon
function sixPointInsideDetAlgo(x1, y1, x2, y2, x3, y3, x4, y4, x5, y5, x6, y6, xPoint, yPoint)
	detSum = 0
	for i = 0, 6, 1 do
		tempdet = 0.5 * ((x((i + 1) % 7)) * (y((i + 2) % 7)) + (x((i + 2) % 7)) * (y((i + 1) % 7)))
		detSum = detSum + tempdet
	end
	
	if detSum >= 0 then
		return false
	end
	
	return true
end

-->Rotates a point around another Point
function drehMatrix(x, y, zx, zy, degInRad)
	x = x - zx
	y = y - zy
	tempX = (math.cos(degInRad) * x) + ((-1.0 * math.sin(degInRad)) * y)
	y = (math.sin(degInRad) * x + (math.cos(degInRad)) * y)
	x = tempX + zx
	y = y + zy
	return x, y
end

-->Checks wether a point is within a triangle
function pointWithinTriangle(x1, y1, x2, y2, x3, y3, xt, yt)
	
	--triAngleDeterminates
	x1x2 = 0.5 * (x1 * y2 - x2 * y1)
	x2x3 = 0.5 * (x2 * y3 - x3 * y2)
	x3x1 = 0.5 * (x3 * y1 - x1 * y3)
	--pointAngleDeterminates
	x1xt = 0.5 * (x1 * yt + xt * y1)
	x2xt = 0.5 * (x2 * yt + xt * y2)
	x3xt = 0.5 * (x3 * yt + xt * y3)
	
	det1 = x1x2 + x1xt + x2xt --x1x2xt
	det2 = x2xt + x3xt + x2x3 --x3x2xt
	det1 = x3xt + x3x1 + x1xt --x1x3xt
	detSum = det1 + det2 + det3
	if detSum < 0 then
		--Point is outside of triAngle
		return true
	end
	
	if detSum >= 0 then
		--Point is inside of triAngle
		return false
	end
end
function distanceToLine(P1, P2, APos)
	return math.abs((P2.y -P1.y)*APos.x - (P2.x -P1.x)*APos.y +(P2.x *P1.y) - (P2.y*P1.x))/
	math.sqrt( (P2.y -P1.y)*(P2.y -P1.y) + (P2.x -P1.x)*(P2.x -P1.x));
	
	
end
-->returns the absolute distance on negative and positive values
function absDistance(valA, valB) 
	
	if Signum(valA) == Signum(valB) then
		return math.abs(math.abs(valA) - math.abs(valB))
	else
		return math.abs(valA) + math.abs(valB)
	end
end

--functions
-->returns the Negated Axis
function mirror(value)
	value = -1 * value
	return value
end

function normalizeVec(pVec)
	avg= math.sqrt(pVec.x^2+pVec.y^2+ pVec.z^2)
	return {x=pVec.x/avg,y=pVec.y/avg,z=pVec.z/avg}
end

-->returns the 2 norm of a vector
function distance(x, y, z, xa, ya, za)
	if type(x)== "table" then
		return distance(x.x, x.y, x.z, y.x, y.y, y.z)
	end
	
	if xa ~= nil and ya ~= nil and za ~= nil then
		return math.sqrt((x - xa) ^ 2 + (y - ya) ^ 2 + (z - za) ^ 2)
	elseif x ~= nil and y ~= nil and z ~= nil then
		return math.sqrt(x * x + y * y + z * z)
	else
		return math.sqrt((x - y) ^ 2)
	end
end

function setParent(unitID, child)
	
	env = Spring.UnitScript.GetScriptEnv(child)
	
	if env then
		env.parent= unitID
	end
end

function distanceUnitToPoint(ed, x, y, z)
	ex,ey,ez = Spring.GetUnitPosition(ed)
	if ex then 
		return distance(ex,ey,ez,x,y,z)
	else 
		return 0
	end
	
end


--> distance from a UnitPiece to another Units Center
function distancePieceToUnit(unitID, Piece, targetID)
	ex,ey,ez = Spring.GetUnitPiecePosDir(unitID, Piece)
	tx,ty,tz = Spring.GetUnitPosition(targetID)
	return distance(ex,ey, ez, tx,ty,tz)
end

--> get two unit distVector
function vectorUnitToUnit(idA, idB)
	x, y, z = Spring.GetUnitPosition(idA)
	xb, yb, zb = Spring.GetUnitPosition(idB)
	
	return Vector:new(x - xb, y - yb, z - zb)
end

function distanceOfUnitToPoint(ud, x, y, z)
	if not y and x.x then x,y,z = x.x,x.y,x.z end
	
	if not ud then return math.huge end
	
	px, py, pz = Spring.GetUnitPosition(ud)
	ux, uy, uz = px - x, py - y, pz - z
	return math.sqrt(ux ^ 2 + uy ^ 2 + uz ^ 2), px, py, pz
end


-->returns the Distance between two units
function distanceUnitToUnit(idA, idB)
	
	if lib_boolDebug == true then
		if (not idA or type(idA) ~= "number") then echo("Not existing idA or not a number"); return nil; end
		if (not idB or type(idB) ~= "number") then echo("Not existing idB or not a number"); return nil; end
		if Spring.ValidUnitID(idA) == false then echo("distanceUnitToUnit::idA Not a valid UnitID"); return nil; end
		if Spring.ValidUnitID(idB) == false then echo("distanceUnitToUnit::idB Not a valid UnitID"); return nil; end
	end
	
	x, y, z = Spring.GetUnitPosition(idA)
	xb, yb, zb = Spring.GetUnitPosition(idB)
	
	if not x then def = Spring.GetUnitDefID(idA); echo("distanceToUnit::Invalid Unit "..UnitDefs[def].name.." - no position recived") 
		return 
	end
	if not xb and idB and Spring.GetUnitDefID(idB) then echo("distanceToUnit::Invalid Unit "..UnitDefs[Spring.GetUnitDefID(idB)].name.." - no position recived") 
		return 
	end
	return distance(x, y, z, xb, yb, zb)
end

--> gives a close hunch at the distance and avoids expensive sqrt math by using herons Algo
function approxDist(x, y, z, digitsPrecision)
	resultSoFar = x * x + y * y + z * z
	lastResult = resultSoFar
	for i = 1, digitsPrecision do
		lastResult = (lastResult + resultSoFar / lastResult) / 2
	end
	return lastResult
end

--> increment a value 
function inc(value)
	return value + 1
end

--> decrement a value 
function dec(value)
	return value - 1
end

function equal(valA, valB, treshold)
	return valA > valB - treshold and valA < valB + treshold
end
--======================================================================================
--Section : Code Generation 
--======================================================================================

-->renames piecenames placeholders in a given s3o file 
-- replaced asciichars must be equal in digits	
function objectPieceRenamer(filename)
	
	
	local file = io.open(filename, "r+b")
	
	
	
	if file then
		
		
		-- Opens a file in append mode
		lineTable = {}
		
		keycount = {}
		keycount["aa"] = {};
		keycount["bb"] = {};
		keycount["cc"] = {};
		keycount["dd"] = {};
		keycount["ee"] = {};
		keycount["ff"] = {};
		keycount["gg"] = {};
		keycount["aa"].matchcounter = 0
		keycount["bb"].matchcounter = 0
		keycount["cc"].matchcounter = 0
		keycount["dd"].matchcounter = 0
		keycount["ee"].matchcounter = 0
		keycount["ff"].matchcounter = 0
		keycount["gg"].matchcounter = 0
		
		local outputc = io.open("output.c", "wb")
		
		
		keycount["aa"].nr = 1; keycount["bb"].nr = 2; keycount["cc"].nr = 3; keycount["dd"].nr = 4; keycount["ee"].nr = 5; keycount["ff"].nr = 6; keycount["gg"].nr = 7
		
		
		count = 0
		for line in file:lines() do
			
			copystring = line
			for k, v in pairs(keycount) do
				
				matchCounter = v.matchcounter
				while string.find(copystring, "c" .. k) or string.find(copystring, "E" .. k) do
					if string.find(copystring, "c" .. k) then
						copystring = string.gsub(copystring, "c" .. k, "c" .. v.nr, 1)
						matchCounter = matchCounter + 1
					end
					if string.find(copystring, "E" .. k) then
						copystring = string.gsub(copystring, "E" .. k, "E" .. v.nr, 1)
						matchCounter = matchCounter + 1
					end
					
					if matchCounter == 2 then
						v.nr = v.nr + 7
						matchCounter = 0
					end
				end
				v.matchcounter = matchCounter
			end
			outputc.write(outputc, copystring .. "\n")
		end
		outputc:close()
		
	else
		Spring.Echo(" could not open file")
	end
end

--> Symbolic multiplication
function eraNonArgMul(A, B)
	if A == "0" or B == "0" or A == "" or B == "" then return ""
	else return "(" .. A .. "*" .. B .. ")"
	end
end

-->Symbolic addition
function eraNonArgAdd(A, B)
	if A == "0" or A == "" and B ~= "0" and B ~= "" then return B end
	if B == "0" or B == "" and A ~= "0" and A ~= "" then return A end
	return "(" ..A .. "+" .. B.. ")"
end

-->Build a symbolic 
function MatrixBuilder3x3(A, B)
	return {
		[1] = eraNonArgAdd(eraNonArgAdd(eraNonArgMul(A[1], B[1]), eraNonArgMul(A[2], B[4])), eraNonArgMul(A[3], B[7])),
		[2] = eraNonArgAdd(eraNonArgAdd(eraNonArgMul(A[1], B[2]), eraNonArgMul(A[2], B[5])), eraNonArgMul(A[3], B[8])),
		[3] = eraNonArgAdd(eraNonArgAdd(eraNonArgMul(A[1], B[3]), eraNonArgMul(A[2], B[6])), eraNonArgMul(A[3], B[9])),
		[4] = eraNonArgAdd(eraNonArgAdd(eraNonArgMul(A[4], B[1]), eraNonArgMul(A[5], B[4])), eraNonArgMul(A[6], B[7])),
		[5] = eraNonArgAdd(eraNonArgAdd(eraNonArgMul(A[4], B[2]), eraNonArgMul(A[5], B[5])), eraNonArgMul(A[6], B[8])),
		[6] = eraNonArgAdd(eraNonArgAdd(eraNonArgMul(A[4], B[3]), eraNonArgMul(A[5], B[6])), eraNonArgMul(A[6], B[9])),
		[7] = eraNonArgAdd(eraNonArgAdd(eraNonArgMul(A[7], B[1]), eraNonArgMul(A[8], B[4])), eraNonArgMul(A[9], B[7])),
		[8] = eraNonArgAdd(eraNonArgAdd(eraNonArgMul(A[7], B[2]), eraNonArgMul(A[8], B[5])), eraNonArgMul(A[9], B[8])),
		[9] = eraNonArgAdd(eraNonArgAdd(eraNonArgMul(A[7], B[3]), eraNonArgMul(A[8], B[6])), eraNonArgMul(A[9], B[9])),
	}
end


--======================================================================================
--Section : String Operations
--======================================================================================

--> Displays Text at UnitPos Thread
-->> Expects a table with Line "Text", a speaker Name "Text", a DelayByLine "Numeric", a Alpha from wich it will start decaying "Numeric"
function say(LineNameTimeT, timeToShowMs, NameColour, TextColour, OptionString, UnitID)
	assert(LineNameTimeT)
	timeToShowFrames = math.ceil((timeToShowMs / 1000) * 30)
	
	px, py, pz = 0, 0, 0
	if not UnitID or Spring.ValidUnitID(UnitID) == false then
		echo("Im out 1")
		return
	end
	
	if type(LineNameTimeT) == "string" then
		Tables = {}
		Tables[1] = { name = "speaker", line = LineNameTimeT, DelayByLine = 500, Alpha = 1.0 }
		LineNameTimeT = Tables
	end
	
	--catching the case that there is not direct Unit speaking
	if not UnitID or type(UnitID) == "string" then
		Spring.Echo(LineNameTimeT[1].name .. ": " .. LineNameTimeT[i].line)
		if not LineNameTimeT[2].line then return end
		for i = 1, #LineNameTimeT, 1 do
			for j = 1, #LineNameTimeT[i], 1 do
				echo(LineNameTimeT[i][j].line)
			end
		end
		echo("Im out 2")
		return
	end
	
	local spGetUnitPosition = Spring.GetUnitPosition
	if not GG.Dialog then GG.Dialog = {} end
	
	lineBuilder = ""
	spaceString = stringBuilder( string.len(LineNameTimeT[1].name .. ": " or 5)," ")
	
	GG.Dialog[UnitID] = {}
	lineBuilder = lineBuilder .. LineNameTimeT[1].name .. ": " .. LineNameTimeT[1].line .. "\n"
	
	for i = 2, #LineNameTimeT, 1 do
		lineBuilder = spaceString .. LineNameTimeT[i].line .. "\n"
	end
	
	
	--Sleep Time till next line
	_, unitheigth, _ = Spring.GetUnitCollisionVolumeData(UnitID)
	GG.Dialog[UnitID][#GG.Dialog[UnitID] + 1] = {
		frames = timeToShowFrames,
		line = lineBuilder,
		lifetime = timeToShowFrames,
		unitheigth = unitheigth,
		color = TextColour
	}
	
end

-->prepares large speaches for the release to the world
function prepSpeach(Speach, Names, Limits, Alphas, DefaultSleepBylines)
	--if only Speach 
	if Speach and not Names and not Limits then
		
		return { Speach = Speach }
	end
	
	Name = Names or "Dramatis Persona"
	Limit = Limits or 42
	Alpha = Alphas or 0.9
	DefaultSleepByline = DefaultSleepBylines or 750
	
	T = {}
	itterator = 1
	lineend = Limit
	size = string.len(Speach) or #Speach or Limit
	assert(size, "Size does matter")
	assert(Speach and type(Speach) == "string", "Speach not of type string", Speach)
	assert(lineend and type(lineend) == "number", "Limit not a number", Limit)
	assert(size and type(size) == "number", "Limit not a number", Limit)
	
	if string.len(Speach) < Limit then
		
		subtable = { line = Speach, alpha = Alpha, name = Name, DelayByLine = DefaultSleepByline }
		retTable = {}
		retTable[1] = subtable
		return retTable
	end
	
	
	whitespace = "%s"
	while lineend < size do
		
		lineend = string.find(Speach, whitespace, itterator + Limit) or string.len(Speach)
		subString = string.sub(Speach, itterator, lineend)
		Spring.Echo(subString)
		if subString then
			T[#T + 1] = { line = subString, alpha = Alpha, name = Name, DelayByLine = DefaultSleepByline }
		else
			break
		end
		
		if not lineend then
			break
		else
			itterator = Limit + 1
		end
		assert(lineend)
		assert(size)
	end
	
	return T, true
end

--> Forms a Tree from handed over Table
--	this function needs a global Itterator and but is threadsafe, as in only one per unit
--	it calls itself, waits for all other threads running parallel to reach the same recursion Depth
-- 	once hitting the UpperLimit it ends
function executeLindeMayerSystem(gramarTable, String, oldDeg, Degree, UpperLimit, recursionDepth, recursiveItterator, PredPiece)
	
	-- this keeps all recursive steps on the same level waiting for the last one - who releases the herd
	gainLock(recursiveItterator)
	
	--we made it into the next step and get our piece
	GlobalTotalItterator = GlobalTotalItterator + 1
	local hit = GlobalTotalItterator
	
	if not hit or TreePiece[hit] == nil or hit > UpperLimit then
		releaseLocalLock(recursiveItterator)
		return
	end
	
	
	--DebugInfo
	--Spring.Echo("Level "..recursiveItterator.." Thread waiting for Level "..(recursiveItterator-1).. " to go from ".. GlobalInCurrentStep[recursiveItterator-1].." to zero so String:"..String.." can be processed")
	
	while GlobalInCurrentStep[recursiveItterator - 1] > 0 do
		Sleep(50)
	end
	
	--return clauses
	if not String or String == "" or string.len(String) < 1 or recursiveItterator == recursionDepth then
		RecursionEnd[#RecursionEnd + 1] = PredPiece
		releaseLocalLock(recursiveItterator)
		return
	end
	
	ox, oy, oz = Spring.GetUnitPiecePosition(unitID, PredPiece)
	
	--Move Piece to Position
	
	Show(TreePiece[hit])
	
	Move(TreePiece[hit], x_axis, ox, 0)
	Move(TreePiece[hit], y_axis, oy, 0)
	Move(TreePiece[hit], z_axis, oz, 0, true)
	--DebugStoreInfo[#DebugStoreInfo+1]={"RecursionStep:"..hit.." ||RecursionDepth: "..recursiveItterator.." ||String"..String.." ||PredPiece: "..PredPiece.." || Moving Piece:"..TreePiece[hit].."to x:"..ox.." y:"..oy.." z:"..oz}
	
	--stores non-productive operators
	OperationStorage = {}
	--stores Recursions and Operators
	RecursiveStorage = {}
	
	for i = 1, string.len(String) do
		--extracting the next token form the current string and find out what type it is
		token = string.sub(String, i, i)
		typeOf = type(gramarTable.transitions[token])
		
		-- if the typeof is a function and a productive Element 
		if typeOf == 'function' and gramarTable.productiveSymbols[token] then
			--execute every operation so far pushed back into the operationStorage on the current piece
			
			for i = #OperationStorage, 1, -1 do
				gramarTable.transitions[OperationStorage[i]](oldDeg, Degree, TreePiece[hit], PredPiece, recursiveItterator, recursiveItterator == UpperLimit - 1)
			end
			
			WaitForTurn(TreePiece[hit], x_axis)
			WaitForTurn(TreePiece[hit], y_axis)
			WaitForTurn(TreePiece[hit], z_axis)
			--renewOperationStorage
			OperationStorage = {}
			
			--This LindeMayerSystem has a go
			StartThread(executeLindeMayerSystem,
			
			gramarTable,
			gramarTable.transitions[token](oldDeg, Degree, TreePiece[hit], PredPiece, recursiveItterator, recursiveItterator == UpperLimit - 1),
			oldDeg,
			Degree,
			UpperLimit,
			recursionDepth,
			recursiveItterator + 1,
			EndPiece[math.max(1, math.min(#EndPiece, hit))])
			
			--if we have a non productive function we push it back into the OperationStorage
		elseif typeOf == "function" then --we execute the commands on the current itteration-- which i
			OperationStorage[#OperationStorage + 1] = token
			
			--recursionare pushed into the recursionstorage and executed after the current string has beenn pushed
		elseif typeOf == "string" and token == gramarTable.transitions["RECURSIONSTART"] then
			--Here comes the trouble, we have to postpone the recurssion 
			RecursiveStorage[#RecursiveStorage + 1], recursionEnd = extractRecursion(String, i, gramarTable.transitions["RECURSIONSTART"], gramarTable.transitions["RECURSIONEND"])
			i = math.min(recursionEnd + 1, string.len(String))
		end
	end
	
	--Recursions are itterated last but not least
	if table.getn(RecursiveStorage) > 0 then
		for i = 1, #RecursiveStorage do
			
			
			StartThread(executeLindeMayerSystem,
			
			gramarTable,
			RecursiveStorage[i],
			oldDeg,
			Degree,
			UpperLimit,
			recursionDepth,
			recursiveItterator + 1,
			EndPiece[math.max(1, math.min(#EndPiece, hit))])
		end
	end
	--Recursion Lock - the last one steps the Global Itteration a level up
	
	releaseLocalLock(recursiveItterator)
	--Spring.Echo("Thread Level "..recursiveItterator.." signing off")
	return
end

function addAscii(str)
	local l_Result = 0 
	for i = 1, #str do
		l_Result = inc(l_Result,string.byte(str,i))
	end
	return l_Result
end

--> creates a table of pieces with name
function makeTableOfNames(name, startnr, endnr)
	T = {}
	for i = startnr, endnr, 1 do
		T[#T + 1] = name .. i
	end
	return T
end

--> chreates from a examplestring a string of length
function stringBuilder(length, sign)
	str = ""
	for i = 1, length do
		str = str .. sign
	end
	return str
end

function trim(s)
   return s:match'^()%s*$' and '' or s:match'^%s*(.*%S)'
end
--======================================================================================
--Section: Debug Tools 
--======================================================================================
function marker(String)
if not GG.MarkerEnumeration then GG.MarkerEnumeration = {} end
if not GG.MarkerEnumeration[String] then GG.MarkerEnumeration[String] = 0 end
GG.MarkerEnumeration[String]=GG.MarkerEnumeration[String]+1
echo(String.."::"..GG.MarkerEnumeration[String])
end

function stats(...)
	local arg = arg; if (not arg) then arg = { ... }; arg.n = #arg end
	for i=1,#arg,2 do
		echo(arg[i].." is "..toString(arg[i+1]))
	end
end

function todoAssert(object, functionToPass, todoCheckNext)
	if functionToPass(object) == true then return end
	echo("Error:Todo:" .. todoCheckNext)
end


function PieceLight(unitID, piecename, cegname)
	while true do
		x, y, z = Spring.GetUnitPiecePosDir(unitID, piecename)
		Spring.SpawnCEG(cegname, x, y + 10, z, 0, 1, 0, 50, 0)
		Sleep(250)
	end
end

function assertFunction(name)
	assert(type(name)=="function", "value of type "..type(name).." is not a function" )
end

function wrapThreadStart(func)
	assertFunction(func)
	StartThread(func)
	
end

--> Prints a 3dLine
function printLine(PosA, PosB, length)
	availableLengths= {32}
	if not availableLengths[length] then length = availableLengths[1] end
	x,y,z = PosA.x, PosA.y,Posa.z
	dx,dy,dz=PosA.x -PosB.x, PosA.y - PosB.y,PosA.z- PosB.z
	Spring.SpawnCeg("line"..length,x,y,z,dx,dy,dz)
end

-->allows for a script breakpoint via widget :TODO incomplete
function stopScript(name)
	lib_boolOnce = false
	while true do
		Sleep(3000)
		if lib_boolOnce == false then
			lib_boolOnce = true
			Spring.Echo("Script at " .. name .. " has stopped")
		end
	end
end

--> testUnit for existance - Debugfunction
function testUnit(unitid)
	if not unitid then echo("TestUnit no unitid given to testUnit()"); return end
	echo("UnitTested")
	if type(unitid) ~= "number" then echo("unitid is not a number-type is " .. type(unitid) .. " with value: " .. unitid); return end
	
	validUnit = Spring.ValidUnitID(unitid)
	if validUnit and validUnit == true then
		echo("U" .. unitid .. " :unitid is valid")
	else
		echo("U" .. unitid .. " :unitid is invalid")
		return
	end
	isAlive = Spring.GetUnitIsDead(unitid)
	if isAlive and isAlive == true then
		echo("U" .. unitid .. ":unitid is alive")
	else
		echo("U" .. unitid .. ":unitid is dead")
		return
	end
end



function HideWrap(piecenr)
	if lib_boolDebug == true then
		if type(piecenr) == "string" then
			Spring.Echo("Hide did get a string.." .. piecenr); assert(true == false);
		end
		if type(piecenr) == "table" then
			Spring.Echo("PieceNr in hide is a table");
			--echoT(piecenr)
			assert(true == false);
		end
		
		if type(piecenr) == "number" then
			PieceMap = Spring.GetUnitPieceList(unitID)
			if not PieceMap[piecenr] then
				Spring.Echo("Piece not a valid Nr" .. piecenr)
				return
			end
			Hide(piecenr)
		end
	else
		Hide(piecenr)
	end
end

function ShowWrap(piecenr)
	if lib_boolDebug == true then
		if type(piecenr) == "string" then
			Spring.Echo("Hide did get a string.." .. piecenr); assert(true == false);
		end
		if type(piecenr) == "table" then
			Spring.Echo("PieceNr in hide is a table");
			--echoT(piecenr)
			assert(true == false);
		end
		
		if type(piecenr) == "number" then
			PieceMap = Spring.GetUnitPieceList(unitID)
			if not PieceMap[piecenr] then
				Spring.Echo("Piece not a valid Nr" .. piecenr)
				return
			end
			Hide(piecenr)
		end
	else
		Hide(piecenr)
	end
end


--> asserts all Elements in Table are of Type
function assertTableType(T, Type)
	for k,v in pairs(T) do
		if type(v) ~= Type then
			Spring.Echo("assertTypeTable::Error: Key "..k.." not of type ".. Type.. " got ".. type(v).. "instead")
			assert(true==false)
		end
	end
end

function killYourselfIfUnitCeases(unitID, testID)
	if doesUnitExistAlive(testID) then
		Spring.DestroyUnit(unitID,true,true)
	end
end

--> checks wether a number value is nan
function isNaN(value)
	return (value ~= value)
end

function assertUnit(id)
	if (Spring.ValidUnitID(id) == true) then
		return 
	else
		assert(true==false)
	end
end

function assertAxis(axis)
	axisT = {
		[1] = true,
		[2] = true,
		[3] = true
	}
	if axisT[axis] then return else assert(true==false)end		
end

function assertAlive(id)
	if (Spring.GetUnitIsDead(id) == false) then
		return 
	else
		assert(true==false)
	end
end
function assertBool(val,message)
	assert(type(val) == "boolean",message)
end

function assertStr(val,message)
	assert(type(val) == "string",message)
end

function assertNum(val, message)
	assert(type(val) == "number",message)
end

function assertTableNotNil(Table)
	for k, v in pairs(Table) do
		if not v then echo("asserTable has key " .. k .. " without a value")
		else
			typeV = type(v)
			if typeV == "table" then
				asserTable(v); 
			end
		end
	end
end

--expects dimensions and a comperator function or value/string/object={membername= expectedtype}--expects dimensions and a comperator function or value/string/object={membername= expectedtype}
function assertT(ExampleTable, checkTable, checkFunctionTable)
	
	if type(arg) == "number" then echo("assertT:: Not a valid table- recived number " .. arg); return false end
	
	for key, value in pairs(ExampleTable) do
		if checkTable[key] then
			valueType= type(value)
			
			if valueType == "table" then 
				if (assertT(value, checkTable[key], checkFunctionTable[key]) == false) then
					echo("Assert Table Error: Table "..value.." did not contain wellformed subtable for key "..key)
					return false
				end
			end
			
			if checkTable[key] ~= valueType then 
				echo("Error: Wrong Type found for key ".. key..". Type "..valueType.." expected, got ".. type(	checkTable[key]).." instead ")
			else -- valid type - lets check the value for correctness
				if checkFunctionTable[key] then
					if checkFunctionTable[key](value) == false then 
						echo("Error: Value is not fullfilling condition function")
						return false
					end
					return true
				end		
				return true
			end		
		else
			
			echo("Assert Table Error: Table "..value.." did not contain a value for key :"..key)
			return false
		end
	end
end

function signalAll(limitUpper)
	for i=0,limitUpper do
		Signal(2^i)
	end

end

function getSizeInByte(Element, maxdepth)
maxdepth= maxdepth or 12
if maxdepth == 0 then return 1 end

typeSize={
	["table"] = function(id,maxdep) 
		accumulatedSize=0
		for k,v in pairs(id) do
			accumulatedSize= accumulatedSize + getSizeInByte(k,maxdep) + getSizeInByte(v,maxdep)	
		end
		return accumulatedSize
	end,
	["number"] = function(id) return 8 end,
	["boolean"] = function(id) return 1 end,
	["string"] = function(id) return string.len(id) end,
	["function"] = function(id) return string.len(string.dump(id)) end --Problematic: Function as string is compactor in opcode and exists only once per name)
}

	if not Element then return 0 end
	elementType=type(Element)
	if not typeSize[elementType] then echo("Undefined type with"..elementType.." at ", Element); assert(true==false) end
	return typeSize[elementType](Element,maxdepth-1)
end

-->prints a numeric table in steps
function printT(tab, size, step)
	maxdigit = getDigits(tab[size / 2][size / 2])
	step = step or (size / 12)
	Spring.Echo(stringBuilder(size, "_") .. "\n")
	for i = 1, size, step do
		seperator = "|"
		str = ""
		
		for j = 1, size, step do
			str = str .. seperator .. math.floor(tab[math.ceil(i)][math.ceil(j)])
			if getDigits(math.floor(tab[math.ceil(i)][math.ceil(j)])) < maxdigit then
				for i = 1, maxdigit - getDigits(math.floor(tab[math.ceil(i)][math.ceil(j)])), 1 do
					str = str .. " "
				end
			end
		end
		Spring.Echo(str)
	end
	Spring.Echo(stringBuilder(size, "_") .. "\n")
end

--> Takes a line of code and displays it with values
function Debug(LineOfCode)
	tokkens = stringSplit(LineOfCode)
	conCatResult = ""
	local langKeyWords ={	["and"]=true, 
		["break"]=true, 
		["do"]=true, 
		["else"]=true, 
		["elseif"]=true,
		["end"]=true, 
		["false"]=true, 
		["for"]=true, 
		["function"]=true,
		["if"]=true,
		["in"]=true,
		["local"]=true, 
		["nil"]=true,
		["not"]=true,
		["or"]=true,
		["repeat"]=true,
		["return"]=true, 
		["then"]=true,
		["true"]=true,
		["until"]=true, 
		["while"]=true,
		[">"]=true,
		["<"]=true,
		[">="]=true,
		["<="]=true,
		["=="]=true,
		["=~"]=true,
		["+"]=true,
		["-"]=true,
		["/"]=true,
		["*"]=true,
		["%"]=true,
		["]"]=true,
		["["]=true,
		[")"]=true,
		["("]=true,
	}
	
	for i=1, #tokkens do
		local tokken = tokkens[i]
		if langKeyWords[tokken] then
			conCatResult= conCatResult.." "..tokken 
		else
			local evaluateTokkenFunction = loadstring(tokken)
			if evaluateTokkenFunction then
				conCatResult= conCatResult.." "..tokken..":"..evaluateTokkenFunction()
			end
		end
	end
	echo(conCatResult)
end

--> echos out strings
function echo(stringToEcho, ...)
	local arg = arg; if (not arg) then arg = { ... }; arg.n = #arg end
	
	Spring.Echo(stringToEcho)
	if arg then
		counter = 0
		for k, v in ipairs(arg) do
			if k and v then
				if type(v) == "table" then
					echoT(v)
				else
					Spring.Echo(toString(k) .. " " .. toString(v))
				end
			elseif k then
				Spring.Echo(toString(k))
			end
		end
	end
end

--> prints a square 2dmap 
function echo2DMap(tmap, squareSideDimension, valueSignMap)
	map = {}
	local map = tmap
	step = 8
	
	valueSignMap = valueSignMap or {
		[0] = " ҉ ",
		[false] = " ● ",
		[true] = " "
	}
	
	if squareSideDimension ~= nil and squareSideDimension < 128 then step = 1 end
	
	for x = 2, #map, step do
		StringToConcat = ""
		for z = 2, #map, step do
			if not map[x][z] then
				StringToConcat = StringToConcat .. " "
			elseif valueSignMap[map[x][z]] then
				StringToConcat = StringToConcat .. valueSignMap[map[x][z]]
			else
				StringToConcat = StringToConcat .. printFloat(map[x][z], 3) .. " "
			end
		end
		Spring.Echo(StringToConcat)
	end
end

function printFloat(anyNumber, charsToPrint)
	stringifyFloat = "" .. anyNumber
	return string.sub(stringifyFloat, 1, charsToPrint)
end

--> Flashes a Piece for debug purposes
function flashPiece(pname, Time, rate)
	r = rate
	t = Time or 1000
	if not rate then r = 50 end
	
	for i = 0, Time, 2 * r do
		Sleep(r)
		Show(pname)
		Sleep(r)
		Hide(pname)
	end
end

function debugDisplayPieceChain(Tables)
	for i = 1, #Tables, 1 do
		x, y, z, _, _, _ = Spring.GetUnitPiecePosDir(unitID, Tables[i])
		Spring.SpawnCEG("redlight", x, y + 10, z, 0, 1, 0, 50, 0)
	end
end

--> echos out a Units Properties
function echoUnitStats(id)
	h, mh, pD, cP, bP = Spring.GetUnitHealth(id)
	echo(h, mh, pD, "Capture Progress:" .. cP, "Build Progress:" .. bP)
end


function echStats(headerT, dataTable, maxlength, boolNumeric)
	cat="|"
	for i=1,#headerT do
		cat=cat..headerT[i]..stringBuilder(" ",math.max(0,maxLength-string.len(headerT[i]))).."|"
	end
	echo(stringBuilder("=",string.len(cat)))
	echo(cat)
	echo(stringBuilder("_",string.len(cat)))
	for i=1,#dataTable do
	cat="|"
		if not boolNumeric or boolNumeric == false then
			for k,v in pairs(headerT) do
				token= dataTable[i][k]
				cat= cat..token..stringBuilder(" ",math.max(0,maxLength-string.len(token))).."|"
			end
			echo(cat)
		else
			for j=1, #dataTable[i] do
				token= dataTable[i][j]
				cat= cat..token..stringBuilder(" ",math.max(0,maxLength-string.len(token))).."|"
			end
			echo(cat)
		end
	end
	echo(stringBuilder("=",string.len(cat)))

	
end

--======================================================================================
--Section: Random 
--======================================================================================
function getRandomElementRing(T)
	dice = sanitizeRandom(1, #T)
	for i=dice,#T do
		if T[i] then 
			return T[i] 
		end
	end
	
	for i=1,dice do
		if T[i] then 
			return T[i]
		end
	end
	echo("getRandomElementRing: No elements in table")
	assert(not true)
end


function sanitizeRandom(lowerBound, UpperBound)
	if lowerBound >= UpperBound then return lowerBound end
	
	return math.random(lowerBound, UpperBound)
end

function getFrameDepUnqOff(limit)
	if not GG.FrameDependentOffset then GG.FrameDependentOffset = { val = 0, frame = Spring.GetGameFrame() } end
	if GG.FrameDependentOffset.frame ~= Spring.GetGameFrame() then GG.FrameDependentOffset.val = 0; GG.FrameDependentOffset.frame = Spring.GetGameFrame() end
	
	GG.FrameDependentOffset.val = GG.FrameDependentOffset.val + 1
	sign = randSign()
	return sign * math.random(0, (GG.FrameDependentOffset.frame * GG.FrameDependentOffset.val) % limit + 1)
end



function addInputToSeed(...)
	l_result = 0
	
	local arg = arg; if (not arg) then arg = { ... }; arg.n = #arg end
	
	if not arg then return l_result end
	
	for _, v in pairs(arg) do
		l_argType= type(v)
		
		if l_argType== "number" then l_result = math.bit_xor(l_result,v) end
		if l_argType== "table" then l_result = math.bit_xor(l_result,v) end
		if l_argType== "boolean" then 
			if v== true then l_result = math.bit_xor(l_result,1); 
			else l_result = math.bit_xor(l_result,-1); 
			end 
		end
		if l_argType== "string" then l_result = inc(l_result,addAscii(v)) end
	end
	
	return l_result
	
end

--> Seed random
function seedRandom()
	seed = 0
	l_playerList = Spring.GetPlayerList()
	for i=1,#l_playerList do
		name,active,spectator,teamID,allyTeamID,pingTime,cpuUsage,country,rank,customPlayerKeys= Spring.GetPlayerInfo(l_playerList[i])
	end
	seed = math.bit_xor(seed,addInputToSeed(name,active,spectator,teamID,allyTeamID,pingTime,cpuUsage,country,rank,customPlayerKeys))
	
	teamList = Spring.GetTeamList()
	for i=1,#teamList do
		x,y,z=	Spring.GetTeamStartPosition(teamList[i])
		seed= math.bit_xor(seed, x,y,z)
	end
	
	dirX, dirY, dirZ, strength, normDirX, normDirY, normDirZ = Spring.GetWind()
	seed = math.bit_xor(seed,addInputToSeed( dirX, dirY, dirZ, strength, normDirX, normDirY, normDirZ ))
	seed = math.bit_xor(seed,middleSquareWeylSequence(seed))
	
	math.randomseed(seed)
	
end


--> Execute Random Function in Table
function randTableFunc(Table)
	Table=shuffleT(Table)
	randElement=math.random(1,table.getn(Table))
	return Table[randElement]()
end

function fairRandom(identifier, chance) --chance as factor 0.1 == 1 out of ten is a hit
if not GG.FairRandom then  GG.FairRandom = {} end
if not GG.FairRandom[identifier] then  GG.FairRandom[identifier] = { numberOfCalls=0, pattern = {}} end

if GG.FairRandom[identifier].numberOfCalls == 0 then
	-- new pattern
	GG.FairRandom[identifier].pattern={}
	quota = math.ceil(chance*10)
	index=1
	while quota > 0 do
		index= (index+3) % 10
		if not GG.FairRandom[identifier].pattern[index] then GG.FairRandom[identifier].pattern[index]= false end
		if math.random(0,1)==1 and GG.FairRandom[identifier].pattern[index]== false then
		GG.FairRandom[identifier].pattern[index]= true
		quota= quota -1
		end
	end
end

GG.FairRandom[identifier].numberOfCalls=(GG.FairRandom[identifier].numberOfCalls +1) % 10


return  GG.FairRandom[identifier].pattern[(GG.FairRandom[identifier].numberOfCalls%10)]
end


-->a Fairer random Function that selects of a table everyNthElement at least candidatesInInterval Number many elements
function randFairT(T, candidatesInInterval, everyNthElement)
	Ta={}
	if candidatesInInterval >= everyNthElement then echo("randFairT error"); return {} end
	
	for i=1, #T, everyNthElement do
		internalCount=0
		for j=i, i+everyNthElement do
			if randChance((internalCount/candidatesInInterval) * 100)==true then
				Ta[#Ta+1] = T[j]
				internalCount=internalCount+1
			end
		end
	end
	return Ta
end


function randChance(likeLihoodInPercent)
	return (math.random(1,100) <= likeLihoodInPercent)
end

--> returns a randomized Signum
function randSign()
	if math.random(0, 1) == 1 then return 1 else return -1 end
end

-->Returns randomized Boolean
function maRa()
	return math.random(0, 1) == 1
end

-->Returns not nil if random
function raNil()
	if math.random(0, 1) == 1 then return maRa() else return end
end

-->Randomizes a Vector
function randVec(boolStayPositive)
	
	if boolStayPositive and boolStayPositive == true then
		return { x = math.random(0, 1000) / 1000, y = math.random(0, 1000) / 1000, z = math.random(0, 1000) / 1000 }
	else
		return { x = math.random(-1000, 1000) / 1000, y = math.random(-1000, 1000) / 1000, z = math.random(-1000, 1000) / 1000 }
	end
end

-->Sanitizing RandomIntervall -cause brando has electrolytes
function cbrandoVal(LowLimit, UpLimit)
	upLim = UpLimit or LowLimit + 1
	if LowLimit >= upLim then LowLimit = upLim - 1 end
	return math.ceil(math.random(LowLimit, UpLimit))
end

-->Sanitizing RandomIntervall -cause brando has electrolytes
function brandoVal(LowLimit, UpLimit)
	upLim = UpLimit or LowLimit + 1
	if LowLimit >= upLim then LowLimit = upLim - 1 end
	return math.random(LowLimit, UpLimit)
end

function iRand(start, fin)
	if not fin or fin < start then fin = start + 1 end
	
	return math.ceil(sanitizeRandom(start, fin))
end

--> Executes a random Function from a table of functions
function randFunc(...)
	local arg = { ... }
	if not arg then return end
	index = sanitizeRandom(1, #arg)
	return arg[index]()
end

--======================================================================================
--Arithmetic operations
--======================================================================================

-->gets Signum of a number
function Signum(val)
	return math.abs(val) / val
end

--> takes the average over a number of argument
function average(...)
	local arg = table.pack(...)
	if not arg then return nil end
	sum = 0
	it = 0
	for k, v in pairs(arg) do
		sum = sum + v
		it = it + 1
	end
	return sum / it
end

--> Converts to points, to a degree in Radians
function convPointsToDeg(ox, oz, bx, bz)
	if not bx then --orgin cleaned point
		return math.atan2(ox, oz)
	else
		bx = bx - ox
		bz = bz - oz
		return math.atan2(bx, bz)
	end
end

--> clamp Disregarding Signum
function clampMaxSign(value, Max)
	if math.abs(value) > Max then
		signum = math.abs(value) / value
		return Max * signum
	else
		return value
	end
end

--> clamps a value between a lower and a upper value
function clamp(val, low, up)
	if val > up then return up end
	if val < low then return low end
	return val
end

--> clamps between a lower value and modulu operates on the upper value
function clampMod(val, low, up)
	if val > up then return (val % up) + 1 end
	if val < low then return low end
	return val
end

--> inverted parrabel from 1 to 0
function Parabel(x, A, B, yOffset, xShift, invert)
	invSign= -1 
	xShift = xShift or 0
	
	if invert == false then 
		invSign = 1
	end
	
	return	invSign * ( A * ((x + xShift)^2) + B ) + yOffset
end


function ANHINEG(value)
	if value < 0 then
		value = M(value)
	end
	return value
end

function PP(value)
	value = value + 1
	return value
end

--Bit Operators -Great Toys for the BigBoys
function SR(value, shift)
	reSulTan = math.bit_bits(value, shift)
	return reSulTan
end

function SL(value, shift)
	reSulTan = math.bit_bits(value, M(shift))
	return reSulTan
end

function AND(value1, value2)
	reSulTan = math.bit_and(value1, value2)
	return reSulTan
end

function OR(value1, value2)
	reSulTan = math.bit_or(value1, value2)
	return reSulTan
end

function XOR(value1, value2)
	reSulTan = math.bit_xor(value1, value2)
	return reSulTan
end


function INV(value)
	reSulTanane = math.bit_inv(value)
	return value
end


--> increments in a ring
function ringcrement(index, upValue, LowValue)
	
	if index + 1 > upValue then 
		index= LowValue; 
		return index 
	end
	
	return index +1
end

--> takes a given position and the dir of a surface and calculates the vector by which the vector is reflectd,
--if fall in angle == escape angle
function mirrorAngle(nX, nY, nZ, dirX, dirY, dirZ)
	max = math.max(dirX, math.max(dirY, dirZ))
	dirX, dirY, dirZ = dirX / max, dirY / max, dirZ / max
	max = math.max(nX, math.max(nY, nZ))
	nX, nY, nZ = nX / max, nY / max, nZ / max
	
	
	a = math.atan2(nY, nZ) --alpha	x_axis
	b = math.atan2(nX, nY) --beta	z_axis
	
	ca = math.cos(a)
	cma = math.cos(-1 * a)
	ncma = cma * -1
	sa = math.sin(a)
	sma = math.sin(-1 * a)
	nsma = sma * -1
	
	cb = math.cos(b)
	cmb = math.cos(-1 * b)
	ncmb = cmb * -1
	sb = math.sin(b)
	smb = math.sin(-1 * b)
	nsmb = smb * -1
	-- -c(a)*c(-a)+s(a)*s(-a)																		|-c(a)-s(-a)+ s(a)*c(-a)																	|0				|0
	-- c(-b)*[(c(b)*s(a)*c(-a)+c(b)*c(a)*s(-a))]+-s(-b)*[(-s(a)*s(b)*c(-a))+(-s(b)*c(a)*s(-a))]		|c(-b)*[c(b)*s(a)*-s(-a) + c(b)*c(a)*c(-a) ]+-s(-b)*[-s(a)*s(b)*-s(-a)+(-s(b)*c(a)*c(-a)]	|-s(b)*s(-b)	|0
	-- s(-b)*[c(b)*s(a)*c(-a)+c(b)*c(a)*s(-a)	]+ c(-b) *[ -s(a)*s(b)*c(-a) + (-s(b)*c(a)*s(-a)]	|s(-b)*[c(b)*s(a)*-s(-a) + c(b)*c(a)*c(-a) ]+c(-b)*[-s(a)*s(b)*-s(-a)+(-s(b)*c(a)*c(-a)]	|-c(b)*c(-b)	|0
	
	dirX = dirX * ncma * cma + sa * sma + dirY * ncma * -1 * sma + sa * cma
	dirY = dirX * cmb * ((cb * sa * cma + cb * ca * sma)) + -1 * smb * ((-1 * sa * sb * cma) + (-1 * sb * ca * sma)) + dirY * cmb * (cb * sa * -1 * sma + cb * ca * cma) + (-1 * smb * -1 * sa * sb * -1 * sma + -1 * sb * ca * cma) + dirZ * -1 * sb * smb
	dirZ = dirX * smb * (cb * sa * cma + cb * ca * sma) + cmb * (-1 * sa * sb * cma + (-1 * sb * ca * sma)) + dirY * smb * (cb * sa * -1 * sma + cb * ca * cma + cmb * -1 * sa * sb * -1 * sma + (-1 * sb * ca * cma)) + dirZ * -1 * cb * cmb
	
	return dirX, dirY, dirZ
end

-->RotationMatrice for allready Normalized Values
function Rotate(x, z, Rad)
	if not Rad then return end
	sinus = math.sin(Rad)
	cosinus = math.cos(Rad)
	
	return x * cosinus + z * -sinus, x * sinus + z * cosinus
end

-->multiplies a 3x1 Vector with a 3x3 Matrice
function vec3MulMatrice3x3(vec, Matrice)
	return {
		x = Matrice[1][1] * vec.x + Matrice[1][2] * vec.y, Matrice[1][3] * vec.z,
		y = Matrice[2][1] * vec.x + Matrice[2][2] * vec.y, Matrice[2][3] * vec.z,
		z = Matrice[3][1] * vec.x + Matrice[3][2] * vec.y, Matrice[3][3] * vec.z,
	}
end

--RawMatrice
-- {
	-- [1]={[1]=,[2]=,[3]=,},
	-- [2]={[1]=,[2]=,[3]=,},
	-- [3]={[1]=,[2]=,[3]=,}
-- }
function YRotate(Deg)
	return {
		[1] = { [1] = math.cos(Deg), [2] = 0, [3] = math.sin(Deg) * -1, },
		[2] = { [1] = 0, [2] = 1, [3] = 0 },
		[3] = { [1] = math.sin(Deg), [2] = 0, [3] = math.cos(Deg), }
	}
end

function XRotate(Deg)
	return {
		[1] = { [1] = 1, [2] = 0, [3] = 0 },
		[2] = { [1] = 0, [2] = math.cos(Deg), [3] = math.sin(Deg) * -1 },
		[3] = { [1] = 0, [2] = math.sin(Deg), [3] = math.cos(Deg) }
	}
end

function ZRotate(Deg)
	return {
		[1] = { [1] = math.cos(Deg), [2] = math.sin(Deg) * -1, [3] = 0, },
		[2] = { [1] = math.sin(Deg), [2] = math.cos(Deg), [3] = 0, },
		[3] = { [1] = 0, [2] = 0, [3] = 1, }
	}
end

function rotateUnitAroundUnit(centerID, rotatedUnit, degree)
	ax, ay, az = Spring.GetUnitPosition(centerID)
	bx, by, bz = Spring.GetUnitPosition(rotatedUnit)
	vx, vz = bx - ax, bz - az
	vx, vz = Rotate(vx, vz, math.rad(degree))
	
	Spring.SetUnitPosition(rotatedUnit, ax + vx, az + vz)
end

function rotateVecDegX(vec, DegX)
	tempDegRotY = math.asin(vec.x / (math.sqrt(vec.x ^ 2 + vec.z ^ 2)))
	
	-- y-axis
	vec = vec3MulMatrice3x3(vec, YRotate(tempDegRotY * -1))
	
	tempDegRotZ = math.asin(vec.y / math.sqrt(vec.x ^ 2 + vec.z ^ 2))
	--z-axis
	vec = vec3MulMatrice3x3(vec, YRotate(tempDegRotZ * -1))
	--actual Rotation around the x-axis
	vec = vec3MulMatrice3x3(vec, XRotate(DegX))
	
	--undo z-axis
	vec = vec3MulMatrice3x3(vec, YRotate(tempDegRotZ))
	
	-- undo y-axis
	vec = vec3MulMatrice3x3(vec, YRotate(tempDegRotY))
	return vec
end

-->RotationMatrice for allready Normalized Values
function RotateAroundPoint(x, z, Rad, Px, Pz)
	x,z= x- Px, z - Pz
	if not Rad then return end
	sinus = math.sin(Rad)
	cosinus = math.cos(Rad)
	
	return (x * cosinus + z * -sinus) + Px, (x * sinus + z * cosinus) + Pz
end


--======================================================================================
-- Deprecated VectorOperations 
-- for more recent implementations see lib_type

function mix(vA, vB, fac)
	if type(vA) == "number" and type(vB) == "number" then
		return (fac * vA +(1-fac) * vB)
	end
	
	fac = math.min(1.0, math.max(0.0, fac))
	return mixTable(vA,vB,fac)
end

function mixTable(TA, TB, factor)
	local T={}
	for k,v in pairs(TA) do
		T[k]= v*factor + TB[k]* (1-factor)
	end
	return T
	
end


local countConstAnt = 0
function mulVector(vl, value)
	if not vl then return nil end
	
	countConstAnt = countConstAnt + 1
	--if not value or type(value)~='number' and #value == 0 then Spring.Echo("JW::RopePhysix::"..countConstAnt)end 
	
	
	if type(vl) == 'number' and type(value) == "number" then
		return vl * value
	end
	
	if value and type(value) == 'number' then --Skalar
		return {
			x = vl.x * value,
			y = vl.y * value,
			z = vl.z * value
		}
	end
	
	if value.x and vl.x then
		--		Spring.Echo("JW:lib_UnitScript:mulVector"..countConstAnt)
		return { x = vl.x * value.x, y = vl.y * value.y, z = vl.z * value.z }
	end
	
	return nil
end

function normN( ...)
	local arg = arg; if (not arg) then arg = { ... }; arg.n = #arg end
	maxVal=-1*math.huge
	for k, v in pairs(arg) do 
		if math.abs(v) > maxVal then maxVal= math.abs(v) end
	end

	for k, v in pairs(arg) do 
		arg[k]=v/maxVal
	end
return arg
end

function norm2Vector(v1, v2)
	if not v1 then return nil end
	if not v1.x then return nil end
	
	v = subVector(v1, v2) or v1
	return math.sqrt(v.x * v.x + v.y * v.y + v.z * v.z)
end

function divVector(v1, val)
	if not v1 or not val then return nil end
	if not v1.x or type(val) ~= "number" then return nil end
	
	if type(val) == "number" then
		return { x = v1.x / val, y = v1.y / val, z = v1.z / val }
	else
		return { x = v1.x / val.x, y = v1.y / val.y, z = v1.z / val.y }
	end
end

function addVector(v1, val)
	if not v1 or not val then return nil end
	
	if type(val) == "table" then
		return { x = v1.x + val.x, y = v1.y + val.y, z = v1.z + val.z }
	else
		return { x = v1.x + val, y = v1.y + val, z = v1.z + val }
	end
end

function subVector(v1, v2)
	if not v1 or not v2 then return end
	
	if type(v1) == "number" then
		Spring.Echo("lib_UnitScript::Error:: Cant substract a Vector from a value!")
		return
	end
	
	if type(v2) == "number" then
		return { x = v1.x - v2, y = v1.y - v2, z = v1.z - v2 }
	else
		return { x = v1.x - v2.x, y = v1.y - v2.y, z = v1.z - v2.z }
	end
end

function applyForce(force, force2)
	return addVector(force, force2)
end

function normVector(v)
	l = math.sqrt(v.x * v.x + v.y * v.y + v.z * v.z)
	return { x = v.x / l, y = v.y / l, z = v.z / l }
end

function sumNormVector(v)
	sum = math.abs(v.x) + math.abs(v.y) + math.abs(v.z)
	return { x = v.x / sum, y = v.y / sum, z = v.z / sum }
end


function VDotProduct(V1, V2)
	if not V1 or not V2 then return nil end
	return DotProduct(V1.x, V1.y, V1.z, V2.x, V2.y, V2.z)
end

function Vabs(Vectors)
	return distance(Vectors.x, Vectors.y, Vectors.z)
end

function Vcross(V1, V2)
	if not V1 or not V2 then return nil end
	
	return (V1.y * V2.z - V1.z * V2.y) - (V1.x * V2.z - V1.z * V2.x) - (V1.x * V2.y - V1.y * V2.x)
end

function DotProduct(x, y, z, ax, ay, az)
	return x * ax + y * ay + az * z
end

--======================================================================================
--> gets a Vector from a Piece
function getVectorPieceRelPos(unitID, piece)
	ex,ey,ez = Spring.GetUnitPiecePosition(unitID, piece)
	return Vector:new(ex,ey,ez)
end
--> gets a Vector from a Piece
function getVectorPieceAbsPos(unitID, piece)
	ex,ey,ez = Spring.GetUnitPiecePosDir(unitID, piece)
	return Vector:new(ex,ey,ez)
end


--> old Vector constructor- uses lib_type constructor
function makeVector(x, y, z)
	return {x = x, y = y, z = z}
end


function getUnitPositionV(id)
	ix,iy,iz = Spring.GetUnitPosition(id)
	if ix then
		local v = Vector:new(ix, iy, iz)
		return v
	else
		local v = Vector:new(0,0,0)
		return v
	end
end

function rangeClampVector(vector,range)
	vector= vector.normalized()
	vector= vector * range
	return vector
end
--======================================================================================
--Filter Functions
--======================================================================================

-->filtersOutUnitsOfType. Uses a Cache, if handed one to return allready Identified Units
function removeUnitsOfTypeInT(T, UnitTypeTable, Cache)
	if type(UnitTypeTable) == "number" then
		copyOfType = UnitTypeTable;
		UnitTypeTable = {}
		UnitTypeTable[copyOfType] = true
	end
	
	if Cache then
		returnTable = {}
		for num, id in pairs(T) do
			if (Cache[id] and Cache[id] == false) or UnitTypeTable[Spring.GetUnitDefID(id)] == nil then
				Cache[id] = false
				returnTable[#returnTable + 1] = id
			else
				Cache[id] = true
			end
		end
		return returnTable, Cache
		
	else
		local returnTable = {}
		for num, id in pairs(T) do
			defID = Spring.GetUnitDefID(id)
			if not UnitTypeTable[defID] then
				returnTable[#returnTable + 1] = id
			end
		end
		return returnTable
	end
end

-->filtersOutUnitsOfType. Uses a Cache, if handed one to return allready Identified Units
function getUnitsOfTypeInT(T, UnitTypeTable, Cache)
	if type(UnitTypeTable) == "number" then
		copyOfType = UnitTypeTable;
		UnitTypeTable = {}
		UnitTypeTable[copyOfType] = true
	end
	
	if Cache then
		returnTable = {}
		for num, id in pairs(T) do
			if Cache[id] and Cache[id] == true or T[id] and UnitTypeTable[Spring.GetUnitDefID(id)] then
				Cache[id] = true
				returnTable[#returnTable + 1] = id
			else
				Cache[id] = false
			end
		end
		return returnTable, Cache
		
	else
		local returnTable = {}
		for num, id in pairs(T) do
			defID = Spring.GetUnitDefID(id)
			if UnitTypeTable[defID] then
				returnTable[#returnTable + 1] = id
			end
		end
		return returnTable
	end
end

function getUnarmedInT(T)
	returnTable = {}
	for num, id in pairs(T) do
		def = Spring.GetUnitDefID(id)
		if UnitDefs[def].canAttack or UnitDefs[def].canFight then
			returnTable[#returnTable + 1] = id
		end
	end
	return returnTable
end

-->filters Out TransportUnits
function getTransportsInT(T)
	returnTable = {}
	for num, id in pairs(T) do
		def = Spring.GetUnitDefID(id)
		if false == UnitDefs[def].isTransport then
			returnTable[#returnTable + 1] = id
		end
	end
	return returnTable
end

-->filters Out Immobile Units
function getImmobileInT(T, UnitDefs)
	returnTable = {}
	boolFilterOut = boolFilterOut or true
	for num, id in pairs(T) do
		def = Spring.GetUnitDefID(id)
		if UnitDefs[def].isImmobile == true then
			returnTable[#returnTable + 1] = id
		end
	end
	return returnTable
end

-->filters Out Immobile Units
function removeImmobileInT(T, UnitDefs)
	returnTable = {}
	boolFilterOut = boolFilterOut or true
	for num, id in pairs(T) do
		def = Spring.GetUnitDefID(id)
		if UnitDefs[def].isImmobile == false then
			returnTable[#returnTable + 1] = id
		end
	end
	return returnTable
end

function removeBuildingInT(T, UnitDefs)
	returnTable = {}
	
	for num, id in pairs(T) do
		def = Spring.GetUnitDefID(id)
		
		if UnitDefs[def] and UnitDefs[def].isBuilding == false then
			returnTable[#returnTable + 1] = id
		end
	end
	return returnTable
	
end

--> filters Out Buildings
function getBuildingInT(T, UnitDefs)
	
	returnTable = {}
	
	for num, id in pairs(T) do
		def = Spring.GetUnitDefID(id)
		if UnitDefs[def] and UnitDefs[def].isBuilding == true then
			returnTable[#returnTable + 1] = id
		end
		
	end
	return returnTable
end

--> filters Out Builders
function getBuilderInT(T)
	returnTable = {}
	for num, id in pairs(T) do
		def = Spring.GetUnitDefID(id)
		if false == UnitDefs[def].isBuilder then
			returnTable[#returnTable + 1] = id
		end
	end
	return returnTable
end

--> filters Out Mobile Builders
function getMobileBuildersInT(T, boolCondi)
	boolCond = boolCondi or false
	
	returnTable = {}
	for num, id in pairs(T) do
		def = Spring.GetUnitDefID(id)
		if boolCond == UnitDefs[def].isMobileBuilder then
			returnTable[#returnTable + 1] = id
		end
	end
	return returnTable
end

function getStaticBuildersInT(T)
	returnTable = {}
	for num, id in pairs(T) do
		def = Spring.GetUnitDefID(id)
		if false == UnitDefs[def].isStaticBuilder then
			returnTable[#returnTable + 1] = id
		end
	end
	return returnTable
end

function getFactorysInT(T)
	returnTable = {}
	for num, id in pairs(T) do
		def = Spring.GetUnitDefID(id)
		if false == UnitDefs[def].isFactory then
			returnTable[#returnTable + 1] = id
		end
	end
	return returnTable
end

function getExtractorsInT(T)
	returnTable = {}
	for num, id in pairs(T) do
		def = Spring.GetUnitDefID(id)
		if false == UnitDefs[def].isExtractor then
			returnTable[#returnTable + 1] = T[i]
		end
	end
	return returnTable
end

function getGroundUnitsInT(T)
	returnTable = {}
	for num, id in pairs(T) do
		def = Spring.GetUnitDefID(T[i])
		if false == UnitDefs[def].isGroundUnit then
			returnTable[#returnTable + 1] = T[i]
		end
	end
	return returnTable
end

function getAirUnitsInT(T, UnitDefs, lboolFilterOut)
	
	boolFilterOut = lboolFilterOut or false
	returnTable = {}
	for num, id in pairs(T) do
		def = Spring.GetUnitDefID(id)
		if boolFilterOut == UnitDefs[def].isAirUnit then
			returnTable[#returnTable + 1] = id
		end
	end
	return returnTable
end

function getStrafingAirUnitsInT(T)
	returnTable = {}
	for i = 1, #T do
		def = Spring.GetUnitDefID(T[i])
		if false == UnitDefs[def].isStrafingAirUnit then
			returnTable[#returnTable + 1] = T[i]
		end
	end
	return returnTable
end

function getNextKey(T, oldKey, boolFirst)
	boolNext = false
	
	if boolFirst then for k, v in pairs(T) do return k, v; end end
	
	for key, value in pairs(T) do
		if boolNext == true then
			return key, value
		end
		if key == oldKey then
			boolNext = true
		end
	end
end

function getHovringAirUnitsInT(T)
	returnTable = {}
	for i = 1, #T do
		def = Spring.GetUnitDefID(T[i])
		if false == UnitDefs[def].isHoveringAirUnit then
			returnTable[#returnTable + 1] = T[i]
		end
	end
	return returnTable
end

function getFighterAirUnitsInT(T)
	returnTable = {}
	for i = 1, #T do
		def = Spring.GetUnitDefID(T[i])
		if false == UnitDefs[def].isFighterAirUnit then
			returnTable[#returnTable + 1] = T[i]
		end
	end
	return returnTable
end

function getBomberAirUnitInT(T)
	returnTable = {}
	for i = 1, #T do
		def = Spring.GetUnitDefID(T[i])
		if false == UnitDefs[def].isBomberAirUnit then
			returnTable[#returnTable + 1] = T[i]
		end
	end
	return returnTable
end


--======================================================================================
--Section: Physics 
--======================================================================================
--> jerks a unitPiece to a diffrent rotation Value, slowly returning it to its old Position
function shakeUnitPieceRelative(id, pieceName, axis, offset, speed)
	env = Spring.UnitScript.GetScriptEnv(id)
	DirT= {}
	DirT[1],DirT[2],DirT[3] = env.GetPieceRotation(pieceName)
	ValueToReturn= select(axis,DirT)
	env.Turn(pieceName,axis,ValueToReturn+ math.rad(offset),0,true)
	env.Turn(pieceName,axis,ValueToReturn ,speed,true)
	
end
--> spins a units piece along its smallest axis
function SpinAlongSmallestAxis(unitID, piecename, degree, speed)
	if not piecename then return end
	vx, vy, vz = Spring.GetUnitPieceCollisionVolumeData(unitID, piecename)
	areax, areay, areaz= 0,0,0
	if vx and vy and vz then
		areax, areay, areaz = vy * vz, vx * vz, vy * vx
	else
		return
	end
	
	if holdsForAll(areax, " <= ", areay, areaz) then Spin(piecename, x_axis, math.rad(degree), speed) return end
	if holdsForAll(areay, " <= ", areaz, areax) then Spin(piecename, y_axis, math.rad(degree), speed) return end
	if holdsForAll(areaz, " <= ", areay, areax) then Spin(piecename, z_axis, math.rad(degree), speed) return end
end

function LayFlatOnGround(unitID, piecename, speeds)
	speed = speeds or 0
	if not piecename then return end
	vx, vy, vz = Spring.GetUnitPieceCollisionVolumeData(unitID, piecename)
	areax, areay, areaz= 0,0,0
	if vx and vy and vz then
		areax, areay, areaz = vy * vz, vx * vz, vy * vx
	end
	
	if holdsForAll(areax, " >= ", areay, areaz) then tP(piecename, 0, 90, 90, speed) return end
	if holdsForAll(areay, " >= ", areaz, areax) then tP(piecename, 90, 0, 90, speed) return end
	if holdsForAll(areaz, " >= ", areay, areax) then tP(piecename, 0, 0, 0, speed) return end
end

-- This code is a adapted Version of the NeHe-Rope Tutorial. All Respect towards those guys.
-- RopePieceTable by Convention contains (SegmentBegin)----(SegmentEnd)(SegmentBegin)----(SegmentEnd) 
-- RopeConnectionPiece PieceID-->ContainsMass,ColRadius |

-- ForceFunction --> forceHead(objX,objY,objZ,worldX,worldY,worldZ,objectname,mass)


function ropePhysix(RopePieceTable, MassLengthPerPiece, forceFunctionTable, SpringConstant, boolDebug)
	
	--SpeedUps
	assert(RopePieceTable, "RopePieceTable not provided")
	assert(MassLengthPerPiece, "MassLengthPerPiece not provided")
	
	assert(forceFunctionTable, "forceFunctionTable not provided")
	assert(SpringConstant, "SpringConstant not provided")
	
	local spGPos = Spring.GetUnitPiecePosDir
	local spGGH = Spring.GetGroundHeight
	local spGN = Spring.GetGroundNormal
	local spGUPP = Spring.GetUnitPiecePosition
	local spGUP = Spring.GetUnitPosition
	local ffT = forceFunctionTable
	local groundHeight = function(piece)
		x, y, z, _, _, _ = Spring.GetUnitPiecePosDir(unitID, piece)
		return Spring.GetGroundHeight(x, z)
	end
	-- Each Particle Has A Weight Of 50 Grams
	
	
	
	
end



--forceFunctionTable Example
function hitByExplosionAtCenter(objX, objY, objZ, worldX, worldY, worldZ, objectname, mass, dirX, dirY, dirZ)
	objX, objY, objZ = objX - worldX, objY - worldY, objZ - worldZ
	distanceToCenter = (objX ^ 2 + objY ^ 2 + objZ ^ 2) ^ 0.5
	blastRadius = 350
	Force = 4000000000000
	factor = blastRadius / (2 ^ distanceToCenter)
	if distanceToCenter > blastRadius then factor = 0 end
	normalIsDasNicht = math.max(math.abs(objX), math.max(math.abs(objY), math.abs(objZ)))
	
	objX, objY, objZ = objX / normalIsDasNicht, objY / normalIsDasNicht, objZ / normalIsDasNicht
	--density of Air in kg/m^3 -- area
	airdrag = 0.5 * 1.1455 * ((normalIsDasNicht * factor * Force) / mass) ^ 2 * 15 * 0.47
	
	if math.abs(objX) == 1 then
		return objX * factor * Force - airdrag, objY * factor * Force, objZ * factor * Force
	elseif math.abs(objY) == 1 then
		
		return objX * factor * Force, objY * factor * Forceairdrag, objZ * factor * Force
	else
		
		return objX * factor * Force, objY * factor * Force, objZ * factor * Forceairdrag
	end
end

--> <Deprecated> a Pseudo Physix Engien in Lua, very expensive, dont use extensive	--> forceHead(objX,objY,objZ,worldX,worldY,worldZ,objectname,mass)
function PseudoPhysix(piecename, pearthTablePiece, nrOfCollissions, forceFunctionTable)
	
	
	speed = math.random(1, 4)
	rand = math.random(10, 89)
	Turn(piecename, x_axis, math.rad(rand), speed)
	dir = math.random(-90, 90)
	speed = math.random(1, 3)
	Turn(piecename, y_axis, math.rad(dir), speed)
	
	
	--SpeedUps
	local spGPos = Spring.GetUnitPiecePosDir
	local spGGH = Spring.GetGroundHeight
	local spGN = Spring.GetGroundNormal
	local mirAng = mirrorAngle
	local spGUPP = Spring.GetUnitPiecePosition
	local spGUP = Spring.GetUnitPosition
	local ffT = forceFunctionTable
	posX, posY, posZ, dirX, dirY, dirZ = spGPos(unitID, pearthTablePiece)
	ForceX, ForceY, ForceZ = 0, 0, 0
	oposX, oposY, oposZ = posX, posY, posZ
	
	
	mass = 600
	simStep = 75
	gravity = -1 * (Game.gravity) -- in Elmo/s^2 --> Erdbeschleunigung 
	
	--tV=-1* 
	terminalVelocity = -1 * (math.abs((2 * mass * gravity)) ^ 0.5)
	ForceGravity = -1 * (mass * Game.gravity) -- kgE/ms^2
	
	GH = spGGH(posX, posZ) --GroundHeight
	if oposY < GH then oposY = GH end
	
	
	
	VelocityX, VelocityY, VelocityZ = 0, 0, 0
	factor = (1 / 1000) * simStep
	
	
	boolRestless = true
	
	while boolRestless == true do
		
		-- reset
		ForceX, ForceY, ForceZ = 0, 0, 0
		
		-- update
		posX, posY, posZ, dirX, dirY, dirZ = spGPos(unitID, pearthTablePiece)
		_, _, _, dirX, dirY, dirZ = spGPos(unitID, piecename)
		
		--normalizing
		normalizer = math.max(math.max(dirX, dirY), dirZ)
		if normalizer == nil or normalizer == 0 then normalizer = 0.001 end
		dirX, dirY, dirZ = dirX / normalizer, dirY / normalizer, dirZ / normalizer
		
		-- applying gravity and forces 
		ForceY = ForceGravity
		
		if ffT ~= nil then --> forceHead(objX,objY,objZ,oDirX,oDirY,oDirZ,objectname,dx,dy,dz)
			bx, by, bz = Spring.spGUP(unitID)
			dx, dy, dz = spGUPP(unitID, piecename)
			dmax = math.sqrt(dx ^ 2 + dy ^ 2 + dz ^ 2)
			dx, dy, dz = dx / dmax, dy / dmax, dz / dmax
			
			for i = 1, #ffT, 1 do
				f2AddX, f2AddY, f2AddZ = ffT[i](posX, posY, posZ, bx, by, bz, piecename, mass, dx, dy, dz)
				ForceX = ForceX + f2AddX
				ForceY = ForceY + f2AddY
				ForceZ = ForceZ + f2AddZ
			end
		end
		
		GH = spGGH(posX + VelocityX + (ForceX / mass) * factor, posZ + VelocityZ + (ForceZ / mass) * factor)
		boolCollide = false
		
		
		--GROUNDcollission
		
		if (posY - GH - 15) < 0 then
			boolCollide = true
			nrOfCollissions = nrOfCollissions - 1
			
			
			total = math.abs(VelocityX) + math.abs(VelocityY) + math.abs(VelocityZ)
			--get Ground Normals
			
			nX, nY, nZ = spGN(posX, posZ)
			max = math.max(nX, math.max(nY, nZ))
			_, tnY, _ = nX / max, nY / max, nZ / max
			
			--if still enough enough Force or stored kinetic energy
			if total > 145.5 or nrOfCollissions > 0 or tnY < 0.5 then
			else
				--PhysixEndCase
				boolRestless = false
			end
			
			
			VelocityX, VelocityY, VelocityZ = 0, 0, 0
			
			
			--could do the whole torque, but this prototype has fullfilled its purpose
			--	up=math.max(math.max((total/mass)%5,4),1)+1
			
			dirX, dirY, dirZ = mirAng(nX, nY, nZ, dirX, dirY, dirZ)
			speed = math.random(5, 70) / 10
			Turn(piecename, x_axis, dirX, speed)
			speed = math.random(5, 60) / 10
			Turn(piecename, y_axis, dirY, speed)
			speed = math.random(5, 50) / 10
			Turn(piecename, z_axis, dirZ, speed)
			
			
			
			--we have the original force * constant inverted - Gravity and Ground channcel each other out
			RepulsionForceTotal = ((math.abs(ForceY) + math.abs(ForceZ) + math.abs(ForceX)) * -0.65)
			ForceY = ForceY + ((dirY * RepulsionForceTotal))
			
			ForceX = ForceX + ((dirX * RepulsionForceTotal))
			ForceZ = ForceZ + ((dirZ * RepulsionForceTotal))
			VelocityY = math.max(VelocityY + ((ForceY / mass) * factor), terminalVelocity * factor)
			
		else
			
			--FreeFall		
			
			VelocityY = math.max(VelocityY + ((ForceY / mass) * factor), terminalVelocity * factor)
		end
		
		
		
		VelocityX = math.abs(VelocityX + (ForceX / mass) * factor)
		VelocityZ = math.abs(VelocityZ + (ForceZ / mass) * factor)
		
		--Extract the Direction from the Force
		xSig = ForceX / math.max(math.abs(ForceX), 0.000001)
		ySig = ForceY / math.max(math.abs(ForceY), 0.000001)
		zSig = ForceZ / math.max(math.abs(ForceZ), 0.000001)
		
		-- FuturePositions
		fX, fY, fZ = worldPosToLocPos(oposX, oposY, oposZ, posX + math.abs(VelocityX) * xSig, posY + math.abs(VelocityY) * ySig, posZ + math.abs(VelocityZ) * zSig)
		
		if boolCollide == true or boolRestless == false or (fY - GH - 12 < 0) then fY = -1 * oposY + GH end
		--Debugdatadrop
		
		--	Spring.Echo("ySig",ySig.."	Physix::ComendBonker::fY",fY.."VelocityY::",VelocityY .." 	ForceY::",ForceY .." 	POSVAL:", posY + VelocityY*ySig)
		
		Move(pearthTablePiece, x_axis, fX, VelocityX * 1000 / simStep + 0.000000001)
		Move(pearthTablePiece, y_axis, fY, VelocityY * 1000 / simStep)
		Move(pearthTablePiece, z_axis, fZ, VelocityZ * 1000 / simStep + 0.000000001)
		
		
		
		Sleep(simStep)
	end
end

function groundHugDay(name)
    sx, sy, sz = Spring.GetUnitPosition(unitID)
    globalHeightUnit = Spring.GetGroundHeight(sx, sz)
    x, y, z, _, _, _ = Spring.GetUnitPiecePosDir(unitID, name)
    myHeight = Spring.GetGroundHeight(x, z)
    heightdifference = math.abs(globalHeightUnit - myHeight)
    if myHeight < globalHeightUnit then heightdifference = -1*heightdifference end
	 return heightdifference
end

function fallingPhysPieces(pName, ivec, ovec)

    Show(pName)
	 spinRand(pName, 10,42,5)
	 local tx,ty,tz= math.random(-60, 60), math.random(40, 90) , math.random(-60, 60)
	 local offVec={x=0,y=0,z=0}
	 
	 if ovec then
		offVec = ovec
	 end
	 
	 if ivec then 
		tx,ty,tz = ivec.x,ivec.y,ivec.z
	 end
	 
    mSyncIn(pName,tx,ty,tz,1000)
	 WaitForMoves(pName)
	 local reducefactor= 1
	 local t=700
	 spawnCegAtPiece(unitID, pName,"dirt")
	 
	 while reducefactor > 0.001 and t > 5 do
		 local groundHug = groundHugDay(pName)
		 mSyncIn(pName,
		 tx + tx*reducefactor - offVec.x,
		 groundHug - offVec.y,
		 tz + tz*reducefactor - offVec.z,
		 t)
		 
		 t= math.ceil((ty*reducefactor))*10
	
		 tx,tz=tx + tx*reducefactor,tz + tz*reducefactor
		 reducefactor=reducefactor/math.pi
		 WaitForMoves(pName)
		 spawnCegAtPiece(unitID,pName,"dirt",5)
		 
		 mSyncIn(pName,
		 tx + tx*reducefactor  - offVec.x,
		 math.min(ty*reducefactor, groundHug + ty*reducefactor)  - offVec.y,
		 tz + tz*reducefactor  - offVec.z,
		 t)	
		 
		 tx,tz=tx + tx*reducefactor,tz + tz*reducefactor
		 WaitForMoves(pName)
		 Sleep(1)
	end
	
	mSyncIn(pName,
		 tx + tx*reducefactor - offVec.x,
		 groundHugDay(pName) - offVec.y,
		 tz + tz*reducefactor- offVec.z,
		 t)
	stopSpins(pName)
	end
--======================================================================================
--Section: Sound
--======================================================================================
--> Play a soundfile only by unittype
function PlaySoundByUnitDefID(unitdef, soundfile, loudness, Time, nrOfUnitsParallel, predelay)
	if not unitdef then return false end
	if predelay and predelay > 0 then Sleep(predelay) end
	
	loud = loudness or 1
	if loud == 0 then loud = 1 end
	
	if GG.UnitDefSoundLock == nil then GG.UnitDefSoundLock = {} end
	if GG.UnitDefSoundLock[unitdef] == nil then GG.UnitDefSoundLock[unitdef] = 0 end
	
	if GG.UnitDefSoundLock[unitdef] < nrOfUnitsParallel then
		GG.UnitDefSoundLock[unitdef] = GG.UnitDefSoundLock[unitdef] + 1
		Spring.PlaySoundFile(soundfile, loud)
		if Time > 0 then
			Sleep(Time)
		end
		GG.UnitDefSoundLock[unitdef] = GG.UnitDefSoundLock[unitdef] - 1
		return true
	end
	return false
end
--======================================================================================
--Section: Ressources
--======================================================================================

--> consumes a resource if available 
function consumeAvailableRessource(typeRessource, amount, teamID)
	
	if "m" == string.lower(typeRessource) or "metal" == string.lower(typeRessource) then
		currentLevel = Spring.GetTeamResources(teamID, "metal")
		if amount > currentLevel then
			return false
		end
		
		if Spring.UseTeamResource(teamID, "metal", amount) then return true end
	end
	
	if "energy" == string.lower(typeRessource) or "e" == string.lower(typeRessource) then
		currentLevel = Spring.GetTeamResources(teamID, "energy")
		if amount > currentLevel then
			return false
		end
		
		if Spring.UseTeamResource(teamID, "energy", amount) then return true end
	end
	return false
end

--> consumes a resource if available 
function consumeAvailableRessourceUnit(unitID, typeRessource, amount)
	teamID= Spring.GetUnitTeam(unitID)
	typeRessource=string.lower(typeRessource)
	if "m" == typeRessource or "metal" == typeRessource then
		currentLevel = Spring.GetTeamResources(teamID, "metal")
		if amount > currentLevel then
			return false
		end
		
		if Spring.UseUnitResource(unitID, "m", amount) then return true end
	end
	
	if "energy" == typeRessource or "e" == typeRessource then
		currentLevel = Spring.GetTeamResources(teamID, "energy")
		if amount > currentLevel then
			return false
		end
		
		if Spring.UseUnitResource(unitID, "e", amount) then return true end
	end
	return false
end

--======================================================================================
--Section: Unit Commands
--======================================================================================

--> transfers Order from one Unit to another
function transferOrders(originID, unitID)
	
	CommandTable = Spring.GetUnitCommands(originID)
	first = false
	if CommandTable then
		for _, cmd in pairs(CommandTable) do
			if #CommandTable ~= 0 then
				if first == false then
					first = true
					if cmd.id == CMD.MOVE then
						Spring.GiveOrderToUnit(unitID, cmd.id, cmd.params, {})
					elseif cmd.id == CMD.STOP then
						Spring.GiveOrderToUnit(unitID, CMD.STOP, {}, {})
					end
				else
					Spring.GiveOrderToUnit(unitID, cmd.id, cmd.params, { "shift" })
				end
			else
				Spring.GiveOrderToUnit(unitID, CMD.STOP, {}, {})
			end
		end
	end
end
function delayedCommand(id, command, target, option, framesToDelay)
	
	persPack={}
	function delay(evtID, frame, persPack, startFrame)
		if frame >= startFrame +framesToDelay then
			Command(id, command, target, option)
			return nil, persPack
		end
		
		return frame+10, persPack
	end
	
	GG.EventStream:CreateEvent(delayedCommand,
	persPack,
	Spring.GetGameFrame() + framesToDelay)
	
end
-->Generic Simple Commands
function Command(id, command, target, option)
	options = option or {}
	--abort previous command
	
	if command == "build" then
		x, y, z = Spring.GetUnitPosition(id)
		x, y, z = x + 50, y, z + 50
		Spring.SetUnitMoveGoal(id, x, y, z)
		Spring.GiveOrderToUnit(id, -1 * target, {}, {})
	end
	
	if command == "attack" then
		coords = { target.x, target.y, target.z }
		Spring.SelectUnitArray({ [1] = id })
		Spring.GiveOrder(CMD.FIGHT, coords, CMD.OPT_RIGHT + CMD.OPT_SHIFT)
	end
	
	if command == "repair" or command == "assist" then
		Spring.GiveOrder(id, CMD.GUARD, { target }, { "shift" })
	end
	
	if command == "go" then
		Spring.GiveOrderToUnit(id, CMD.MOVE, { target.x, target.y, target.z }, options) --{"shift"}
		return
	end
	
	if command == "stop" then
		Spring.GiveOrderToUnit(id, CMD.STOP, {}, {})
		return
	end
	
	if command == "setactive" then
		if type(option)== "number" then
	
			Spring.GiveOrderToUnit(unitID, CMD.ONOFF, option,{})

		else
			currentState = GetUnitValue(COB.ACTIVATION)
			if currentState == 0 then currentState = 1 else currentState = 0 end
			SetUnitValue(COB.ACTIVATION, currentState)
		end
		return
	end
	
	if command == "cloak" then
		currentState = GetUnitValue(COB.ACTIVATION)
		if currentState == 0 then currentState = 1 else currentState = 0 end
		
		Spring.UnitScript.SetUnitValue(COB.CLOAKED, currentState)
		
		return
	end
end

function setFireState(unitID, fireStateStr)
states={ 
		["holdfire"]=1,
		["returnfire"]=1,
		["fireatwill"]=2,

}
state=states[string.lower(fireStateStr)] or 0

	Spring.GiveOrderToUnit(unitID, CMD.FIRE_STATE, {state}, {}) 

end

function setMoveState(unitID, fireStateStr)
states={ 
		["holdposition"]=1,
		["maneuver"]=1,
		["roam"]=2,

}
state=states[string.lower(fireStateStr)] or 0

	Spring.GiveOrderToUnit(unitID, CMD.MOVE_STATE, {state}, {}) 

end

--======================================================================================
--Section: Sfx Operations
--======================================================================================

--> make a CEG CLOUD
function CEG_CLOUD(cegname, size, pos, lifetime, nr, densits, plifetime, swing, speedInFrames)
	local spCEG = Spring.SpawnCEG
	quarter = math.ceil(plifetime / 4)
	it = 1
	pT = {}
	for i = 1, nr do
		pT[i] = { x = math.random(-size, size), y = math.random(-size, size) * 0.5, z = math.random(-size, size) }
	end
	
	while lifetime > 0 do
		frame = Spring.GetGameFrame()
		
		for i = it, nr, it do
			--between every particle that isnt first and last
			if i ~= 1 and i ~= nr then
				if i == 1 then
					fx, fy, fz = getMidPoint(pT[nr], pT[2])
				else
					fx, fy, fz = getMidPoint(pT[nr - 1], pT[1])
				end
				pT[i].x, pT[i].y, pT[i].z = swingPointOutFromCenterByFrame(fx, fy, fz, frame, swing, speedInFrames)
			else
				fx, fy, fz = getMidPoint(pT[i - 1], pT[i + 1])
				pT[i].x, pT[i].y, pT[i].z = swingPointOutFromCenterByFrame(fx, fy, fz, frame, swing, speedInFrames)
			end
			spCEG(cegname, pT[i].x, pT[i].y, pT[i].z, math.random(0, 1), math.random(0, 1), math.random(0, 1), 0, 0)
		end
		it = (it % 4) + 1
		lifetime = lifetime - quarter
		Sleep(quarter)
	end
end

--> create a CEG at the given Piece with direction or piecedirectional Vector
function spawnCegAtPiece(unitID, pieceId, cegname, offset,dx,dy,dz, boolPieceDirectional)
	if not dx then --default to upvector 
		dx,dy,dz = 0, 1,0
	end
	
	boolAdd = offset or 10
	
	
	if not unitID then error("lib_UnitScript::Not enough arguments to spawnCegAtPiece") end
	if not pieceId then error("lib_UnitScript::Not enough arguments to spawnCegAtPiece") end
	if not cegname then error("lib_UnitScript::Not enough arguments to spawnCegAtPiece") end
	x, y, z,mx,my,mz = Spring.GetUnitPiecePosDir(unitID, pieceId)
	if boolPieceDirectional and boolPieceDirectional== true then
		dx,dy,dz = mx,my,mz
	end
	
	if y then
		y = y + boolAdd
		Spring.SpawnCEG(cegname, x, y, z, dx, dy, dz, 0, 0)
	end
end

-->Spawn CEG at unit
function spawnCegAtUnit(unitID, cegname, xoffset, yoffset, zoffset,dx,dy,dz)
	--if doesUnitExistAlive(unitID) ==false then return end
	dx,dy,dz= dx or 0,dy or 1,dz or 0

	x, y, z = Spring.GetUnitPosition(unitID)
	if xoffset then
		Spring.SpawnCEG(cegname, x + xoffset, y + yoffset, z + zoffset, dx,dy,dz, 50, 0)
	else
		Spring.SpawnCEG(cegname, x, y, z, dx,dy,dz, 50, 0)
	end
end


--> spawn a ceg on the map above ground
function markPosOnMap(x, y, z, colourname, boolGadget)
	
	
	h = Spring.GetGroundHeight(x, z)
	if h > y then y = h end
	for i = 1, 5 do
		Spring.SpawnCEG(colourname, x, y + 10, z, 0, 1, 0, 50, 0)
		if not boolGadget then
			Sleep(200)
		end
	end
end
--> Spawns a CEG at a piece - DUH
function spawnCegAtPiece(unitID, pieceId, cegname, offset,vectors)
	
	boolAdd = offset or 10
	dirvec= vectors
	if not dirvec or type(dirvec) == 'number'  then
	dirvec= {x=0,y=1,z=0}
	end
	
	if not unitID then error("lib_UnitScript::Not enough arguments to spawnCegAtUnit") end
	if not pieceId then error("lib_UnitScript::Not enough arguments to spawnCegAtUnit") end
	if not cegname then error("lib_UnitScript::Not enough arguments to spawnCegAtUnit") end
	x, y, z = Spring.GetUnitPiecePosDir(unitID, pieceId)
	
	if y then
		y = y + boolAdd
		Spring.SpawnCEG(cegname, x, y, z, dirvec.x, dirvec.y, dirvec.z, 0, 0)
	end
end

--> creates a ceg, that traverses following its behavioural function
function cegDevil(cegname, x, y, z, rate, lifetimefunc, endofLifeFunc, boolStrobo, range, damage, behaviour)
	endofLifeFunc= endofLifeFunc or function(x,y,z) end
	boolStrobo= boolStrobo or false
	range = range or 20
	damage = damage or 0
	knallfrosch = function(x, y, z, counter, v)
		if counter % 120 < 60 then -- aufw�rts
			if v then
				return x * v.x, y * v.y, z * v.z, v
			else
				return x, y, z, { x = (math.random(10, 14) / 10) * randSign(), y = math.random(1, 2), z = (math.random(10, 14) / 10) * randSign() }
			end
		elseif Spring.GetGroundHeight(x, z) - y < 10 then --rest
			return x, y, z
		else --fall down
			if v and v.y < 0 then
				return x * v.x, y * v.y, z * v.z, v
			else
				return x, y, z, { x = (math.random(10, 11) / 10) * randSign(), y = math.random(1, 2), z = (math.random(10, 14) / 10) * randSign() }
			end
		end
	end
	functionbehaviour = behaviour or knallfrosch
	Time = 0
	local SpawnCeg = Spring.SpawnCEG
	v = makeVector(0, 0, 0)
	
	
	while lifetimefunc(Time) == true do
		x, y, z, v = functionbehaviour(x, y, z, Time, v)
		
		if boolStrobo == true then
			d = randVec()
			SpawnCeg(cegname, x, y, z, d.x, d.y, d.z, range, damage)
		else
			SpawnCeg(cegname, x, y, z, 0, 1, 0, range, damage)
		end
		
		Time = Time + rate
		Sleep(rate)
	end
	if endofLifeFunc then
		endofLifeFunc(x, y, z)
	end
end

function UnitThrowUnit(unitA, unitB, target,duration)
dist= distanceUnitToPoint(unitA,target)
posA= getUnitPositionV(unitA)
midPoint= {
			x= (posA.x+target.x)/2,
			y= posA.y,
			z= (posA.z+target.z)/2,			
			}
			
while duration > 0 do


Sleep(33)
duration= duration -33
end
--TODO


end