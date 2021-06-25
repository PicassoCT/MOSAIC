function gadget:GetInfo()
    return {
        name = 'Initial Monument Spawn',
        desc = 'Handles initial spawning of units',
        author = 'Niobium',
        version = 'v1.0',
        date = 'April 2011',
        license = 'GNU GPL, v2 or later',
        layer = 14,
        enabled = true
    }
end

VFS.Include("scripts/lib_UnitScript.lua")
VFS.Include("scripts/lib_Build.lua")
VFS.Include("scripts/lib_mosaic.lua")
local GameConfig = getGameConfig()

----------------------------------------------------------------
-- Synced 
----------------------------------------------------------------
if gadgetHandler:IsSyncedCode() then


    ----------------------------------------------------------------
    -- Speedups
    ----------------------------------------------------------------
    local spGetPlayerInfo = Spring.GetPlayerInfo
    local spGetTeamInfo = Spring.GetTeamInfo
    local spGetTeamRulesParam = Spring.GetTeamRulesParam
    local spSetTeamRulesParam = Spring.SetTeamRulesParam
    local spGetTeamStartPosition = Spring.GetTeamStartPosition
    local spGetAllyTeamStartBox = Spring.GetAllyTeamStartBox
    local spCreateUnit = Spring.CreateUnit
    local spGetGroundHeight = Spring.GetGroundHeight
    local gaiaTeamID = Spring.GetGaiaTeamID()

    function gadget:Initialize()
        boolGameStart = true
    end
   
    ----------------------------------------------------------------
    -- Spawning
    ----------------------------------------------------------------
    boolGameStart = true 
    function gadget:GameFrame(n)
        if boolGameStart == true and n % 10 == 1 then 
            boolGameStart = false
            monumentTable = getMonumentAmountDecorationTypeTable(UnitDefs, GameConfig.instance.culture)
            for defID, data in pairs(monumentTable) do
                if data.maxNr > 0 then
                    for i=1,data.maxNr do
                        data.locationFunc(defID, gaiaTeamID)
                    end
                else
                    if maRa()== true then
                        data.locationFunc(defID, gaiaTeamID)
                    end
                end
            end     
        end     
    end

    ----------------------------------------------------------------
end
----------------------------------------------------------------

