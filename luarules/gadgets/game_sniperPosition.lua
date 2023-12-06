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

    -- variables

    local spGetUnitPosition = Spring.GetUnitPosition
    

    local spSetUnitAlwaysVisible = Spring.SetUnitAlwaysVisible
    local spGetUnitDefID = Spring.GetUnitDefID
    local spDestroyUnit = Spring.DestroyUnit
    local postRoundTimeInSeconds = 15
    local spGetUnitRotation = Spring.GetUnitRotation
    local spSetUnitRotation = Spring.SetUnitRotation
    
    function gadget:Initialize()
    end


    function setEnvironmentAttachToRooftop(assetID, building, pieceID)
        Spring.UnitAttach(assetID, buildingID, pieceID)
        
        env = Spring.UnitScript.GetScriptEnv(assetID)

        if env and env.onRooftop then
           result= Spring.UnitScript.CallAsUnit(assetID, 
                                         env.onRooftop
                                         )
           echo("Called unit on rooftop")
        end
    end

    function getPieceToAttach(id, x,y,z, cx, cy,cz)

    end

    function gadget:RecvLuaMsg(msg, playerID)
        if msg and string.find(msg, "SET_SNIPER_POS_") then --OPROTPOS
            T = split(msg, "|")
            unitSelected    = tonumber(T[2])
            unitToAttachTo= tonumber(T[3])
            defID = spGetUnitDefID(unitToAttachTo)
            if houseTypeTable[defID] then
                x,y,z = T[4],T[5],T[6]
                cx,cy,cz= T[7],T[8],T[9]
                pieceToAttachTo= getPieceToAttach(unitToAttachTo, x,y,z, cx, cy, cz)
                if pieceToAttachTo then 
                    setEnvironmentAttachToRooftop(unitSelected, unitToAttachTo, pieceToAttachTo)            
                end
            end
        end
    end
end 
