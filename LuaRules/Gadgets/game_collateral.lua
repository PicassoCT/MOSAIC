function gadget:GetInfo()
    return {
        name = "Collateral damage Gadget",
        desc = "Handles damage to civilian Units",
        author = "nanonymous",
        date = "3rd of May 2010",
        license = "Free",
        layer = 0,
        version = 1,
        enabled = true
    }
end

--GG.UnitsToSpawn:PushCreateUnit(name,x,y,z,dir,teamID)

if ( gadgetHandler:IsSyncedCode()) then
	   

	VFS.Include("scripts/lib_UnitScript.lua")
	VFS.Include("scripts/lib_mosaic.lua")
	local gaiaTeamID= Spring.GetGaiaTeamID()
	
	accumulatedInSecond ={}
	function addInSecond(team, uid,  rtype, damage)
		if not accumulatedInSecond[uid] then 
			accumulatedInSecond[uid] ={ team = team, rtype = rtype, damage = 0}
		end
		
	accumulatedInSecond[uid].damage = 		accumulatedInSecond[uid].damage  + damage
	
	end
	
	gameConfig = getGameConfig()
	function gadget:UnitDamaged(unitID, unitDefID, unitTeam, damage, paralyzer, weaponDefID, projectileID, attackerID, attackerDefID, attackerTeam)
		assert(damage)
		if not attackerID then echo("Unit "..unitID .. " was damaged without perpetrator with weapon ".. WeaponDefs[weaponDefID].name ); return end
		if ( GG.DisguiseCivilianFor[unitID] ) then return damage end 
		
		--civilian attacked
		if unitTeam == gaiaTeamID and attackerID and attackerTeam ~= unitTeam then
		--	Spring.Echo("UnitDamaged is gaia "..gaiaTeamID)
			attackerPlayerList = Spring.GetPlayerList(attackerTeam)

			for _, team in pairs(Spring.GetTeamList()) do

				if not GG.Propgandaservers then GG.Propgandaservers ={} end
				if not GG.Propgandaservers[team] then GG.Propgandaservers[team] = 0 end

				if team ~= gaiaTeamID  then
					boolTeamsAreAllied = Spring.AreTeamsAllied(attackerTeam, team)
					
					if  boolTeamsAreAllied == true then		
						 Spring.UseTeamResource(team, "metal", damage)
						 addInSecond(team, unitID, "metal",  math.ceil(-1.0 * damage))
					else  -- get enemy Teams -- tranfer damage as budget to them
						factor = 1 + (GG.Propgandaservers[team]* gameConfig.propandaServerFactor)
						Spring.AddTeamResource(team, "metal", math.ceil(math.abs(damage * factor)))
						 addInSecond(team, unitID, "metal",   math.ceil(math.abs(damage * factor)))
					end
				end
			end
		end  
	end
	
	function gadget:GameFrame(frame)
		if frame % 30 == 0 then
			for uid,v in pairs(accumulatedInSecond) do
				SendToUnsynced("DisplaytAtUnit", uid, v.team, v.damage)
			end
			accumulatedInSecond= {}				
		end
	
	end

else -- UNSYNCED
	DrawForFrames = 1 * 30
	Unit_StartFrame_Message={}
	constOffsetY= 25	

	
	-- Display Lost /Gained Money depending on team
    local function DisplaytAtUnit(callname,  unitID, team, damage)
		Spring.Echo("Arriving in Unsynced")
		Unit_StartFrame_Message[unitID]={team= team, message= damage, frame=Spring.GetGameFrame()}

    end
	
	 function gadget:Initialize()
        -- This associate the messages with the functions
        gadgetHandler:AddSyncAction("DisplaytAtUnit", DisplaytAtUnit)
    end
	
	

	function gadget:DrawScreenEffects()
	currFrame = Spring.GetGameFrame()
		UnitsToNil={}
		myPlayerTeam = Spring.GetLocalTeamID()
	
		for _,id in ipairs(Spring.GetAllUnits()) do	
			-- Spring.Echo("itterating over all units")
			for uid, valueT in pairs(Unit_StartFrame_Message) do
			-- Spring.Echo("itterating over all damaged")
				-- Check if Time has expsired
				if id == uid and valueT then
				-- Spring.Echo("id == uid")
				-- Spring.Echo("".. valueT.team.. " -> ".. myPlayerTeam)
					 if currFrame < valueT.frame + DrawForFrames then
						-- Spring.Echo("Drawing Prizes")
						 x, y, z = Spring.GetUnitPosition(uid)	
						 frameOffset=  (255 -( valueT.frame + DrawForFrames -currFrame ))*0.25
						 local sx, sy = Spring.WorldToScreenCoords(x, y + frameOffset, z)
						 if valueT.message < 0 then 
							gl.Color(1.0,0.0,0.0)
						 else
							gl.Color(0.0,1.0,0.0)
						 end
						 
						 gl.Text("$ "..valueT.message, sx, sy, 16, "od")
					 elseif currFrame > valueT.frame + DrawForFrames then
						UnitsToNil[uid]=true
					end
				end
			end
		end
	
		
		for id, _ in pairs(UnitsToNil) do
			Unit_StartFrame_Message[id] = nil
		end
	end

end