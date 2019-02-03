function gadget:GetInfo()
	return {
		name = "Projectiles",
		desc = "This gadget handles projectileimpacts",
		author = "",
		date = "Sep. 2008",
		license = "GNU GPL, v2 or later",
		layer = 0,
		enabled = true,
	}
end

if (gadgetHandler:IsSyncedCode()) then
	VFS.Include("scripts/lib_OS.lua")
	VFS.Include("scripts/lib_UnitScript.lua")
	VFS.Include("scripts/lib_Animation.lua")
	VFS.Include("scripts/lib_Build.lua")
	VFS.Include("scripts/lib_mosaic.lua")
	
	local UnitDamageFuncT = {}
	local StunnedUnitsTable = {}
	
	--1 unitid
	--2 counter
	--3 orgBuildSpeed
	--local stunTime=9
	--local selectRange=300
	--local totalTime=9000
	
	--Centrail Weapons
	
	exampleDefID = -1
	
	--units To be exempted from instantly lethal force

		
	function ShockWaveRippleOutwards(x, z, force, speed, range)
		-- get all units in range
		if not GG.ShockWaves then GG.ShockWaves = {} end
		local OtherWaves = GG.ShockWaves
		assert(range)
		T = getAllInCircle(x, z, range)
		
		for i = 1, #T do
			ex, ey, ez = Spring.GetUnitPosition(T[i])
			
			dist = distance(x, z, ex, ez)
			const = force / dist
			
			if not OtherWaves[math.ceil(dist / speed)] then OtherWaves[math.ceil(dist / speed)] = {} end
			myT = { id = T[i], impulse = { x = 0, y = const, z = 0 } }
			table.insert(OtherWaves[math.ceil(dist / speed)], myT)
		end
		GG.ShockWaves = OtherWaves
	end
	

	
	local explosionFunc = {
		-- [exampleDefID] = function(weaponDefID, px, py, pz, AttackerID)
			
		-- end
	}
	
	function gadget:Explosion(weaponDefID, px, py, pz, AttackerID)
		
		if explosionFunc[weaponDefID] then explosionFunc[weaponDefID](weaponDefID, px, py, pz, AttackerID) 
			return true
		end
	
	end
	
	--===========UnitDamaged Functions ====================================================
	

	UnitDamageFuncT[exampleDefID] = function(unitID, unitDefID, unitTeam, damage, paralyzer, weaponDefID, attackerID, attackerDefID, attackerTeam)
	

	end
	
	GG.exploAmmoBlowTable ={}
	function addChainExplosion(unitID, damage, weaponDefID, cegName, NumberOfExplosions, delayMin, delayMax )
		
		if not GG.exploAmmoBlowTable[unitID] then 
			GG.exploAmmoBlowTable[unitID] = {number=0,id= unitID} 
		end

		GG.exploAmmoBlowTable[unitID].number = GG.exploAmmoBlowTable[unitID].number + NumberOfExplosions
		
		persPack = {startFrame = Spring.GetGameFrame()}
		for i=1,NumberOfExplosions do
			persPack[#persPack + 1] = math.random(delayMin, delayMax)
		end
		persPack.ListOfPieces= getPieceTable(unitID)
		
		--Start Chain Explosion EventStream
		eventFunction = function(id, frame, persPack)
			nextFrame = frame + 1
			if persPack then
				if persPack.unitID then
					--check
					boolDead = Spring.GetUnitIsDead(persPack.unitID)
					
					if boolDead and boolDead == true then
						return
					end
					
					if not persPack.startFrame then
						persPack.startFrame = frame
					end
					
					if not persPack[1] then 
						return 
					end
					
					if persPack.startFrame then
						nextFrame = persPack.startFrame + persPack[1]
						table.remove(persPack,1)
					end
					val= math.random(1,#persPack.ListOfPieces)
					shakeUnitPieceRelative(persPack.unitID, persPack.ListOfPieces[val],math.random(-25,25),50 )
					Spring.AddUnitDamage(persPack.unitID, 15)

				end
			end
			return nextFrame, persPack
		end
		
		GG.EventStream:CreateEvent(eventFunction, persPack, Spring.GetGameFrame() + 1)
	end

	function gadget:UnitDamaged(unitID, unitDefID, unitTeam, damage, paralyzer, weaponDefID, projectileID, attackerID, attackerDefID, attackerTeam)

		if UnitDamageFuncT[weaponDefID] then
			resultDamage = UnitDamageFuncT[weaponDefID](unitID, unitDefID, unitTeam, damage, paralyzer, weaponDefID,  attackerID, attackerDefID, attackerTeam)
			if resultDamage then return resultDamage end
		end

	end
	
	--===========Projectile Persistence Functions ====================================================
	
	
	function gadget:ProjectileCreated(proID, proOwnerID, projWeaponDefID)
		
		
	end


GROUND= string.byte('g') 
UNIT=   string.byte('u') 
FEATURE=   string.byte('f') 
PROJECTILE=   string.byte('p') 	

	projectileDestroyedFunctions = {
	-- [c4WeaponDefID] = function (projID, defID, teamID)
	
		-- x,y,z= getProjectileTargetXYZ(proID)
		
		-- Spring.CreateUnit("stationaryssied",x,y,z, 1, teamID)
		
	
	-- end
	
	
	}
	function gadget:ProjectileDestroyed(proID)
	defid= Spring.GetProjectileDefID(proID)
	if projectileDestroyedFunctions[defID] then
		return projectileDestroyedFunctions[defID] (proID, defID, Spring.GetProjectileTeamID (proID))
	end
		
	
	end
	
	local everyNthFrame = 30
	function gadget:GameFrame(frame)
		
	
		
		if frame % everyNthFrame == 0 then
		
		end
		
	end
	
	
	
	function getProjectileTargetXYZ(proID)
		targetTypeInt, target = Spring.GetProjectileTarget(proID)
		
		if targetTypeInt == GROUND then
			echo("ProjectileTarget:",target[1], target[2], target[3])
			return target[1], target[2], target[3]
		end
		if targetTypeInt == UNIT then
			ux,uy,uz = Spring.GetUnitPosition(target)
			return ux,uy,uz
		end
		if targetTypeInt == FEATURE then
			fx,fy,fz = Spring.GetFeaturePosition(target)
			return fx, fy, fz
		end
		if targetTypeInt == PROJECTILE then
			px,py,pz = Spring.GetProjectilePosition(target)
			return px,py,pz
		end
	end
	
	
	function gadget:ShieldPreDamaged(proID, proOwnerID, shieldEmitterWeaponNum, shieldCarrierUnitID, bounceProjectile,startx, starty, startz, hitx, hity, hitz)
	
		return false
	end
end