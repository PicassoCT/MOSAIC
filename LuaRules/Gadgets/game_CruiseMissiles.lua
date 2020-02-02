function gadget:GetInfo()
        return {
                name                    = "CruiseMissile Management",
                desc                    = "SetProjectileTarget etc",
                author          		= "knorke",
                date                    = "Mar 2014",
                license  				= "later horses dont be mean.",
                layer            		= 0,
                enabled  = true, --      loaded by default?
        }
end

if (not gadgetHandler:IsSyncedCode()) then return end

VFS.Include("scripts/lib_OS.lua")
VFS.Include("scripts/lib_UnitScript.lua")
VFS.Include("scripts/lib_Animation.lua")
VFS.Include("scripts/lib_Build.lua")
VFS.Include("scripts/lib_mosaic.lua")
GameConfig = getGameConfig()

local cruiseMissileWeapons = {}
cruiseMissileWeapons[WeaponDefNames["cm_airstrike"].id] = true
cruiseMissileWeapons[WeaponDefNames["cm_walker"].id] = true
cruiseMissileWeapons[WeaponDefNames["cm_antiarmor"].id] = true
cruiseMissileWeapons[WeaponDefNames["cm_turret_ssied"].id] = true

onImpact = {
[WeaponDefNames["cm_airstrike"].id] = function ( projID)
											
									  end,
[WeaponDefNames["cm_airstrike"].id] = function ( projID)
										px,py,pz =Spring.GetProjectilePosition(projID)
										teamID = GetProjectileTeamID (projID)
										for i=1,2 do
											unitID = Spring.CreateUnit("ground_walker_mg", px,py,pz, 1, teamID)
											giveParachutToUnit(unitID,  px,py,pz)
										end
										Spring.DeleteProjectile (projID)
									end,
[WeaponDefNames["cm_antiarmor"].id] =  function ( projID)
										px,py,pz =Spring.GetProjectilePosition(projID)
										teamID = Spring.GetProjectileTeamID (projID)
										pOwner = Spring.GetProjectileOwner(proID)
											for i=1, 6 do
												Spring.SpawnProjectile()
												 ( WeaponDefNames["javelinrocket"].id, {
												   pos = {px,py,pz},
												   ["end"] = {tx,ty,tz},
												   -- speed = {number x, number y, number z},
												   -- spread = {number x, number y, number z},
												   -- error = {number x, number y, number z},
												   owner = pOwner,
												    team = teamID,
												   -- ttl = number,
												   -- gravity = number,
												   -- tracking = number,
												   -- maxRange = number,
												   -- startAlpha = number,
												   -- endAlpha = number,
												   -- model = string,
												   -- cegTag = string,
												 } )
											end
										Spring.DeleteProjectile(projID)	
										end,
[WeaponDefNames["cm_turret_ssied"].id] =  function ( projID)
											px,py,pz =Spring.GetProjectilePosition(projID)
										teamID = GetProjectileTeamID (projID)
										unitID = Spring.CreateUnit("ground_turret_mg", px,py,pz, 1, teamID)
										giveParachutToUnit(unitID,  px,py,pz)
										
										Spring.DeleteProjectile (projID)
end
}
onLastPointBeforeImpactSetTargetTo ={
[WeaponDefNames["cm_airstrike"].id] = function (tx,ty,tz, projID)
										px,py,pz =Spring.GetProjectilePosition(projID)
										teamID = GetProjectileTeamID (projID)
										
										for i=1, 4 do
											GG.UnitsToSpawn:PushCreateUnit("air_copter_ssied",px,py,pz,1,teamID)
										end
										return tx, ty , tz
									  end,
[WeaponDefNames["cm_walker"].id] = function (tx,ty,tz, projID)
										return tx, ty + GameConfig.CruiseMissilesHeightOverGround, tz
									end
[WeaponDefNames["cm_antiarmor"].id] =  function (tx,ty,tz, projID)
										return tx, ty + GameConfig.CruiseMissilesHeightOverGround, tz
									end,
[WeaponDefNames["cm_turret_ssied"].id] =  function (tx,ty,tz, projID)
										return tx, ty + 3* GameConfig.CruiseMissilesHeightOverGround, tz
									end,
}

local redirectProjectiles = {}  -- [frame][projectileID] = table with .targetType .targetX .targetY .targetZ .targetID

function gadget:Initialize()
	for id, boolActive in pairs(cruiseMissileWeapons) do
		Script.SetWatchWeapon (id, true)
	end
end

 
 function gadget:GameFrame (frame)
	-- if frame%60==0 then Spring.Echo ("projectile_test.lua"..frame) end

	if redirectProjectiles[frame] then
		for projectileID,_ in pairs (redirectProjectiles[frame]) do
			if (Spring.GetProjectileType (projectileID)) then
				setTargetTable (projectileID, redirectProjectiles[frame][projectileID])		
			end
		end
	redirectProjectiles[frame] = nil
	end
end
 



 function gadget:ProjectileCreated(proID, proOwnerID, proWeaponDefID)
	if (cruiseMissileWeapons [proWeaponDefID] or cruiseMissileWeapons[Spring.GetProjectileDefID(proID)]) then
		local originalTarget = getTargetTable (proID)
		local tx,ty,tz = getProjectileTargetXYZ (proID)
		local x,y,z = Spring.GetUnitPosition (proOwnerID)		
		local resolution = 20
		local preCog = 3
		
		for i= 1, resolution, 1 do
			
			rx,  rz = mix(tx, x, resolution/i), mix(tz, z, resolution/i)
			
			interpolate_Y = 0
			for add= 0, preCog, 1 do
				it = math.max(0, math.min(resolution, i+add))
				ix, iz =  mix(tx, x, resolution/it), mix(tz, z, resolution/it)
				interpolate_Y =  math.max(Spring.GetSmoothMeshHeight(ix,iz),interpolate_Y)
			end
			
			addProjectileRedirect (proID, rx, interpolate_Y + GameConfig.CruiseMissilesHeightOverGround , rz)
		end
		
		addProjectileRedirect (proID, tx, ty + GameConfig.CruiseMissilesHeightOverGround, tz)		
		
		return true
	end
end


function getProjectileTargetXYZ (proID)
	local targetTypeInt, target  = Spring.GetProjectileTarget (proID)
	if targetTypeInt == string.byte('g') then
		return target[1],target[2],target[3]
	end
	if targetTypeInt == string.byte('u') then
		return Spring.GetUnitPosition (target)
	end
	if targetTypeInt == string.byte('f') then
		return Spring.GetFeaturePosition (target)
	end
	if targetTypeInt == string.byte('p') then
		return Spring.GetProjectilePosition (target)
	end
end

function addProjectileRedirect (proID, targetTable, delay)
	local f = Spring.GetGameFrame() + delay
	if not redirectProjectiles[f] then redirectProjectiles[f] = {} end
	redirectProjectiles[f][proID] = targetTable
end

function makeTargetTable (x,y,z)
	return {targetType = string.byte('g'), targetX=x,targetY=y,targetZ=z}
end

function getTargetTable (proID)
	local targetTable = {}
	local targetTypeInt, target  = Spring.GetProjectileTarget (proID)
	if targetTypeInt == string.byte('g') then 	--target is position on ground
		targetTable = {targetType = targetTypeInt, targetX=target[1],targetY=target[2],targetZ=target[3],}	
	else 										--target is unit,feature or projectile
		targetTable = {targetType = targetTypeInt, targetID=target,}		
	end
	return targetTable
end

function setTargetTable (proID, targetTable)	
	if targetTable.targetType == string.byte('g') then
		Spring.SetProjectileTarget (proID, targetTable.targetX, targetTable.targetY, targetTable.targetZ)
	else
		Spring.SetProjectileTarget (proID, targetTable.targetID, targetTable.targetType)		
	end
end