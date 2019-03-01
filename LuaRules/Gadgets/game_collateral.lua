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

	gameConfig = getGameConfig()
	function gadget:UnitDamaged(unitID, unitDefID, unitTeam, damage, paralyzer, weaponDefID, projectileID, attackerID, attackerDefID, attackerTeam)
		assert(damage)
		if not attackerID then echo("Unit "..unitID .. " was damaged without perpetrator with weapon ".. WeaponDefs[weaponDefID].name ); return end
		if ( GG.DisguiseCivilianFor[unitID] ) then return damage end 
		
		--civilian attacked
		if unitTeam == gaiaTeamID and attackerID and attackerTeam ~= unitTeam then
			Spring.Echo("UnitDamaged is gaia "..gaiaTeamID)
			attackerPlayerList = Spring.GetPlayerList(attackerTeam)

			for _, team in pairs(Spring.GetTeamList()) do

				if not GG.Propgandaservers then GG.Propgandaservers ={} end
				if not GG.Propgandaservers[team] then GG.Propgandaservers[team] = 0 end

				if team ~= gaiaTeamID  then
					boolTeamsAreAllied = Spring.AreTeamsAllied(attackerTeam, team)
					
					if  boolTeamsAreAllied == true then		
						 Spring.UseTeamResource(team, "metal", damage)
						 SendToUnsynced("DisplaytAtUnit", unitID, team, -1* damage)
					else  -- get enemy Teams -- tranfer damage as budget to them
						factor = 1 + (GG.Propgandaservers[team]* gameConfig.propandaServerFactor)
						Spring.AddTeamResource(team, "metal", damage * factor)
						SendToUnsynced("DisplaytAtUnit", unitID, team, damage*factor)
					end
				end
			end
		end  
	end

else -- UNSYNCED
	DrawForFrames = 5 * 30
	Unit_StartFrame_Message={}
	constOffsetY= 25	
	
	-- Display Lost /Gained Money depending on team
    local function DisplaytAtUnit(callname,  unitID, team, damage)
		Unit_StartFrame_Message[unitID]={team= team, message= damage, frame=Spring.GetGameFrame()}
    end
	
	 function gadget:Initialize()
        -- This associate the messages with the functions
        gadgetHandler:AddSyncAction("DisplaytAtUnit", DisplaytAtUnit)
    end
	
	function gadget:GameFrame(currFrame)
		UnitsToNil={}
		myPlayerTeam = Spring.GetLocalTeamID()
	
		for id, valueT in pairs(Unit_StartFrame_Message) do
			-- Check if Time has expsired
			if valueT then
				if id and valueT.team == myPlayerTeam and currFrame < valueT.frame + DrawForFrames then
					 x, y, z = Spring.GetUnitPosition(id)	
					 sx, sy = Spring.WorldToScreenCoords(x, y + constOffsetY, z)
					 glText("$ "..valueT.message, sx, sy, fontsize, "laos")
				else
					UnitsToNil[id]=true
				end
			end
		end
		
		for id, _ in pairs(UnitsToNil) do
			Unit_StartFrame_Message[id] = nil
		end
	end

end