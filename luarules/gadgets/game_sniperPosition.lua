function gadget:GetInfo()
    return {
        name = "set sniper position",
        desc = "",
        author = "",
        date = "Sep. 2008",
        license = "GNU GPL, v2 or later",
        layer = 0,
        enabled = true
    }
end

if (gadgetHandler:IsSyncedCode()) then
    VFS.Include("scripts/lib_OS.lua")
    VFS.Include("scripts/lib_UnitScript.lua")
    VFS.Include("scripts/lib_mosaic.lua")
    VFS.Include("scripts/lib_type.lua")


    -- variables
    local GameConfig = getGameConfig()
	local operativeAssetDefID = UnitDefNames["operativeasset"].id
    local spGetUnitPosition = Spring.GetUnitPosition
    houseTypeTable = getCultureUnitModelTypes(GameConfig.instance.culture, "house", UnitDefs)
    local spSetUnitAlwaysVisible = Spring.SetUnitAlwaysVisible
    local spGetUnitDefID = Spring.GetUnitDefID
    local spDestroyUnit = Spring.DestroyUnit
    local postRoundTimeInSeconds = 15
    local spGetUnitRotation = Spring.GetUnitRotation
    local spSetUnitRotation = Spring.SetUnitRotation
    
    function getEnvironmentAttachToRooftopPiece(buildingID, vector_position, vec_direction)
        --[[Spring.Echo("Rightclick->RecvLuaMsg:getEnvironmentAttachToRooftopPiece")--]]
        env = Spring.UnitScript.GetScriptEnv(buildingID)

        if env and env.traceRayRooftop then
           pieceID= Spring.UnitScript.CallAsUnit(buildingID, 
                                                 env.traceRayRooftop,
        										 vec_position,
                                                 vec_direction
                                                 )
           --[[echo("Called house traceRay succesfully ".. pieceID)--]]
		   return pieceID
        end
    end
	
    function setEnvironmentAttachToRooftop(assetID, buildingID, pieceID)

        Spring.UnitAttach(buildingID, assetID, pieceID)
        
        env = Spring.UnitScript.GetScriptEnv(assetID)

        if env and env.onRooftop then
           result= Spring.UnitScript.CallAsUnit(assetID, 
                                         env.onRooftop
                                         )
           --[[echo("Called unit on rooftop")--]]
        end
    end

    function gadget:RecvLuaMsg(msg, playerID)
        if msg and string.find(msg, "SET_SNIPER_POS_") then --OPROTPOS
		  --[[Spring.Echo("Rightclick->RecvLuaMsg:SET_SNIPER_POS_"..msg)--]]
            T = split(msg, "|")
            unitSelected    = tonumber(T[2])
            unitToAttachTo= tonumber(T[3])
            if distanceUnitToUnit(unitSelected, unitToAttachTo) > GameConfig.SniperAttachMaxDistance then
				--[[Spring.Echo("Rightclick->RecvLuaMsg:Distance exceeded")--]]
                return
            end
			operativeDefID = spGetUnitDefID(unitSelected)
            defID = spGetUnitDefID(unitToAttachTo)
            if operativeDefID == operativeAssetDefID and houseTypeTable[defID] then
				--[[Spring.Echo("Rightclick->RecvLuaMsg:Operative Found")--]]
                x,y,z = T[4],T[5],T[6]
                cx,cy,cz= T[7],T[8],T[9]
				vec_dir = {x-cx, y- cy, z- cz}
                length = math.sqrt(vec_dir[1]^2 + vec_dir[2]^2 + vec_dir[3]^2)
                vec_direction = {vec_dir[1]/length, vec_dir[2]/length, vec_dir[3]/length}
                vec_position = {x, y, z}
                --[[echo("Position:"..toString(vec_position).." Direction:"..toString(vec_direction))--]]
                pieceToAttachTo =  getEnvironmentAttachToRooftopPiece(unitToAttachTo, vec_position, vec_direction)        
                if pieceToAttachTo then 
					--[[Spring.Echo("Rightclick->RecvLuaMsg:setEnvironmentAttachToRooftop")--]]
                    setEnvironmentAttachToRooftop(unitSelected, unitToAttachTo, pieceToAttachTo)            
                end
            end
        end
    end
end 
