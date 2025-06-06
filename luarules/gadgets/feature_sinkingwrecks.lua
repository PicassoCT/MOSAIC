function gadget:GetInfo()
    return {
        name = "Sinking Wrecks",
        desc = "Make wrecks sink into the ground like in all those dumb commercial R.T.S. (modified for The Cursed)",
        author = "zwzsg",
        date = "3rd of May 2010",
        license = "Free",
        layer = 0,
        version = 1,
        enabled = true
    }
end

-- modified the script: only corpses with the customParam "featuredecaytime" will disappear

local corpsePrideTable = {[FeatureDefNames["bodybag"].id] = true}

if (gadgetHandler:IsSyncedCode()) then
    VFS.Include("scripts/lib_UnitScript.lua")
    VFS.Include("scripts/lib_mosaic.lua")
    GameConfig = getGameConfig()
    gaiaTeamID = Spring.GetGaiaTeamID()
    -- Configuration:
    local SinkEndTime = -35 * 10 -- In frame (10 seconds x 30 frames per seconds)
    local SinkBeginTime = 30 * 10

    function isWreck(FeatureID)
        FeatureDefID = Spring.GetFeatureDefID(FeatureID)
        if corpsePrideTable[FeatureDefID] then return true end

        return false
    end

    -- Now the code:
    local WreckList = {}

    function gadget:FeatureCreated(FeatureID)
        if isWreck(FeatureID) == true then
            WreckList[#WreckList + 1] = {}
            WreckList[#WreckList] = {id = FeatureID, sinkTime = SinkBeginTime}
     
        
        end
    end

    function gadget:FeatureDestroyed(FeatureID)
        if WreckList ~= nil then
            for i = table.getn(WreckList), 1, -1 do
                if WreckList[i].id == FeatureID then
                    table.remove(WreckList, i)
                end
            end
        end
    end

    function gadget:GameFrame(frame)

        if frame % 25 == 0 and WreckList ~= nil and table.getn(WreckList) ~= 0 then
            local spSetFeaturePosition = Spring.SetFeaturePosition
            local spGetFeaturePosition = Spring.GetFeaturePosition
            local spValidFeatureID = Spring.ValidFeatureID
            boolIKnowThatGuy = false
            for i = 1, table.getn(WreckList), 1 do
                -- CountDown all the Features
                WreckList[i].sinkTime = WreckList[i].sinkTime - 25
                -- Move Down all The Negative Features
                if WreckList[i].sinkTime <= 0 and
                    spValidFeatureID(WreckList[i].id) == true then
                    tx, tz, ty = spGetFeaturePosition(WreckList[i].id)
                    spSetFeaturePosition(WreckList[i].id, tx, tz - 0.1, ty)
                end

                if WreckList[i].sinkTime < SinkEndTime then
                    boolIKnowThatGuy = true
                    if math.random(1,100) > 50 and GG.GlobalGameState and GG.GlobalGameState == GameConfig.GameState.normal then
                        x,y,z = Spring.GetFeaturePosition(WreckList[i].id)
                        memorialId = Spring.CreateUnit("memorial", x, 0, z, 1, gaiaTeamID )
                        if memorialId then
                            dx,dy,dz = Spring.GetFeatureRotation(WreckList[i].id)
                            Spring.SetUnitRotation(memorialId, dx, dy, dz)
                        end
                    end
                end
            end

            -- Remove all the Features which are Negative
            if boolIKnowThatGuy == true then
                local spDestroyFeature = Spring.DestroyFeature

                for i = 1, #WreckList, 1 do
                    if WreckList[i] and WreckList[i].sinkTime < SinkEndTime and
                        spValidFeatureID(WreckList[i].id) == true then
                        spDestroyFeature(WreckList[i].id)
                    end
                end
            end

            -- something is in the wreckList
        end
    end
end
