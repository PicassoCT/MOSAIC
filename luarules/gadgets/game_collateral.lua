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

if (gadgetHandler:IsSyncedCode()) then

    VFS.Include("scripts/lib_UnitScript.lua")
    VFS.Include("scripts/lib_mosaic.lua")
    local gaiaTeamID = Spring.GetGaiaTeamID()
    local spAddTeamResource = Spring.AddTeamResource
    local spGetUnitTeam = Spring.GetUnitTeam
    local spGetGameFrame = Spring.GetGameFrame
    local spGetUnitPosition = Spring.GetUnitPosition
    local spGetAllUnits = Spring.GetAllUnits
    local GameConfig = getGameConfig()
    local exemptFromRefundDefIds = getExemptFromRefundTypes(UnitDefs)
    local houseTypeTable = getCultureUnitModelNames_Dict_DefIDName("international", "house", UnitDefs)
    local aerosolAffectableUnits = getChemTrailInfluencedTypes(UnitDefs)
    local AerosolTypes = getChemTrailTypes()
    local accumulatedInSecond = {}
    local accumulatedInSecondLocation = {}
    local colourWhite = {r = 1.0, g = 1.0, b = 1.0, a = 1.0 }

    function addInSecond(team, uid_loc, rtype, damage, colour)
        if not accumulatedInSecond[team] then accumulatedInSecond[team] = {}  end
        if not accumulatedInSecondLocation[team] then accumulatedInSecondLocation[team] = {} end

        if type(uid_loc) == "number" then
            if not accumulatedInSecond[team][uid_loc] then
                accumulatedInSecond[team][uid_loc] =
                    {rtype = rtype, damage = 0, colour = colour or colourWhite}
            end

            accumulatedInSecond[team][uid_loc].damage = accumulatedInSecond[team][uid_loc].damage + damage
        else
            id = uid_loc.uid

            if not accumulatedInSecondLocation[team][id] then
                accumulatedInSecondLocation[team][id] =
                    {
                        rtype = rtype,
                        damage = 0,
                        location = uid_loc,
                        colour = colour or colourWhite
                    }
            end
            accumulatedInSecondLocation[team][id].damage = accumulatedInSecondLocation[team][id].damage + damage
        end
    end

    local collectionConfig = VFS.Include("luarules/configs/collateral.lua")
    local newCollector = VFS.Include("luarules/gadgets/include/collateral_collection.lua")
    local collector = newCollector(Spring, UnitDefNames, collectionConfig,
        function(team, amount, debtor, source)
            -- The offender already sees the assessed fine. Teammates see only
            -- the money actually collected from them, not another full fine.
            if team ~= debtor and source then
                addInSecond(team, source, "metal", -amount)
            end
        end,
        function(team, id, hp)
            SendToUnsynced("DisplaytAtUnit", id, team,
                "Collateral: -" .. math.ceil(hp) .. " HP", 1, 0.25, 0.1, 1)
        end)

    local function TransferToTeam(self, money, reciever, data)
        self[#self + 1] = {
            Money = money,
            Reciever = reciever,
            DisplayUnit_Location = data
        }
    end

    -- GG.Bank:TransferToTeam(  money, reciever, displayunit)
    if not GG.Bank then GG.Bank = {TransferToTeam = TransferToTeam} end
    if not GG.DisguiseCivilianFor then GG.DisguiseCivilianFor = {} end
    if not GG.Propgandaservers then GG.Propgandaservers = {} end

    function gadget:Initialize()
        for _, team in ipairs(Spring.GetTeamList()) do
            GG.Propgandaservers[team] = GG.Propgandaservers[team] or 0
        end
        collector:Initialize()
    end

    function gadget:UnitCreated(id, defID, team)
        collector:RegisterUnit(id, defID, team)
    end

    function gadget:UnitGiven(id, defID, newTeam)
        collector:RegisterUnit(id, defID, newTeam)
    end

    function gadget:UnitTaken(id, defID, oldTeam, newTeam)
        collector:RegisterUnit(id, defID, newTeam)
    end

    local function awardOpponents(attackerTeam, amount, unitID, destroyedHouseDefID)
        local teams = Spring.GetTeamList()
        table.sort(teams)
        for _, team in ipairs(teams) do
            if team ~= gaiaTeamID and team ~= attackerTeam
                and not Spring.AreTeamsAllied(attackerTeam, team) then
                local factor = 1 + (GG.Propgandaservers[team] or 0) * GameConfig.propandaServerFactor
                local reward = math.ceil(amount * factor)
                -- Payout is unconditional, including when the offender has no
                -- money or buildings. Collection is a separate liability.
                spAddTeamResource(team, "metal", reward)
                addInSecond(team, unitID, "metal", reward)
                if destroyedHouseDefID then
                    spawnMilitiaInHousesNearby(team, unitID, destroyedHouseDefID)
                end
            end
        end
    end

    local function assessPenalty(attackerTeam, amount, source)
        collector:Charge(attackerTeam, amount, source)
        if source then addInSecond(attackerTeam, source, "metal", -amount) end
    end

    function gadget:UnitDestroyed(unitID, unitDefID, teamID, attackerID, attackerDefID, attackerTeam)
        collector:RemoveUnit(unitID)
        -- Prefer event attribution: the bombing unit may already be dead.
        local attackerTeamID = attackerTeam or (attackerID and spGetUnitTeam(attackerID))
        if not attackerTeamID or attackerTeamID == gaiaTeamID then return end

        if houseTypeTable[unitDefID] then
            local amount = GameConfig.costs.DestroyedHousePropanda
            awardOpponents(attackerTeamID, amount, unitID, unitDefID)
            assessPenalty(attackerTeamID, amount, unitID)
        elseif GG.DisguiseCivilianFor[unitID] and teamID ~= attackerTeamID then
            -- Preserve the existing counter-intelligence bounty, which is not
            -- a civilian-house destruction reward.
            local def = UnitDefs[unitDefID]
            local maxhp = def.health or def.maxDamage
            if maxhp then
                local factor = 1 + (GG.Propgandaservers[teamID] or 0) * GameConfig.propandaServerFactor
                local reward = math.ceil(math.abs(maxhp * factor))
                spAddTeamResource(attackerTeamID, "metal", reward)
                addInSecond(attackerTeamID, attackerID or unitID, "metal", reward)
            end
        end
    end

    function pushSmallestIntoValueTable(IdValueTable, newValue, newID, maxNr)
        currentElementsInTable = count(IdValueTable)
        for id, value in pairs(IdValueTable) do
            if value < newValue then
                if currentElementsInTable < maxNr then
                    IdValueTable[newID] = newValue
                    return IdValueTable
                else
                    IdValueTable[id] = nil
                    IdValueTable[newID] = newValue
                    compressedTable = {}
                    for k,v in pairs(IdValueTable) do
                        if v then
                            compressedTable[k] = v
                        end
                    end
                    return compressedTable
                end
            end
        end
        return IdValueTable
    end

    cache = {}
    function spawnMilitiaInHousesNearby(teamID, houseDestroyedID, houseDefID)
        houseIDDistance = {}
        threeClosestHouses = {}
        if not cache[houseDestroyedID] then
            foreach(Spring.GetTeamUnitsByDefs( teamID, houseDefID), 
                function(id)
                    houseIDDistance[id] = distanceUnitToUnit(id, houseDestroyedID)
                    
                    for id, distances in pairs(threeClosestHouses) do
                        if houseIDDistance[id] < distances and id ~= houseDestroyedID then
                            threeClosestHouses = pushSmallestIntoValueTable(threeClosestHouses,houseIDDistance[id],id, 3)
                            return id
                        end
                    end
                end    
                )
            cache[houseDestroyedID] = threeClosestHouses
        else 
            threeClosestHouses = cache[houseDestroyedID] 
        end

        minimaldistance = math.huge
        minimalCandidate = nil
        for candidate, distance in pairs(threeClosestHouses)do
            if distance < minimaldistance then
                minimaldistance = distance
                minimalCandidate = candidate
            end
        end
        if minimalCandidate and doesUnitExistAlive(minimalCandidate) then
            x,y,z = Spring.GetUnitPosition(minimalCandidate)
            GG.UnitsToSpawn:PushCreateUnit("civilianagent", x, y, z,  math.random(1, 4), teamID)
        end
    end

    function gadget:UnitDamaged(unitID, unitDefID, unitTeam, damage, paralyzer,
                                weaponDefID, projectileID, attackerID,
                                attackerDefID, attackerTeam)
        attackerTeam = attackerTeam or (attackerID and spGetUnitTeam(attackerID))
        if not attackerTeam or attackerTeam == gaiaTeamID or unitTeam ~= gaiaTeamID
            or exemptFromRefundDefIds[unitDefID] or not damage or damage <= 0 then return end

        awardOpponents(attackerTeam, damage, unitID)
        assessPenalty(attackerTeam, damage, unitID)
    end


    function gadget:GameFrame(frame)
        if frame % collectionConfig.collectionIntervalFrames == 0 then
            if GG.Bank and GG.Bank[1] then
                local cur = GG.Bank
                GG.Bank = {TransferToTeam = TransferToTeam}
                for i = 1, #cur do
                    local entry = cur[i]
                    if entry.Money < 0 then
                        -- Interrogation/checkpoint propaganda fines use the
                        -- same escalation. Income still pays without a marker.
                        assessPenalty(entry.Reciever, -entry.Money, entry.DisplayUnit_Location)
                    else
                        spAddTeamResource(entry.Reciever, "metal", entry.Money)
                        if entry.DisplayUnit_Location then
                            addInSecond(entry.Reciever, entry.DisplayUnit_Location,
                                "metal", entry.Money, colourWhite)
                        end
                    end
                end
            end
            collector:Collect()
        end

        if frame % 30 == 0 then
            for team, deedtable in pairs(accumulatedInSecond) do
                for uid, v in pairs(deedtable) do
                    if v then
                            SendToUnsynced("DisplaytAtUnit", uid, team, v.damage,
                                           v.colour.r, v.colour.g, v.colour.b)
                    end
                end
            end   
            accumulatedInSecond = {}

             for team, teamData in pairs(accumulatedInSecondLocation) do
           --     Spring.Echo("Displaying accumulated in Location for team "..team)
                for uid, data in pairs(teamData) do
                    if data then
                            Spring.Echo("Displaying accumulated in Location for dead:"..uid)
                            assert(data.damage)
                            assertNum(data.location.x)
                            assertNum(data.location.y)
                            assertNum(data.location.z)
                            SendToUnsynced("DisplayAtLocation", data.uid, data.location.x, data.location.y, data.location.z , team,
                                           data.damage, data.colour.r, data.colour.g, data.colour.b)
                        end
                end
            end
            accumulatedInSecondLocation = {}
        end

        if frame % 60 == 0 then
           infectWanderlostNearby(GameConfig, AerosolTypes, aerosolAffectableUnits)
        end
    end

else -- UNSYNCED
    local spGetGameFrame = Spring.GetGameFrame
    local spGetLocalTeamID = Spring.GetLocalTeamID
    local myTeamID = spGetLocalTeamID()
    local spGetAllUnits = Spring.GetAllUnits
    local spGetUnitTeam = Spring.GetUnitTeam
    local spGetUnitPosition = Spring.GetUnitPosition
    local spWorldToScreenCoords = Spring.WorldToScreenCoords
    local glText = gl.Text
    local glColor = gl.Color
    local DrawForFrames = 2 * 30
    local Unit_StartFrame_Message = {}
    local UID_Location_Message = {}
    local gaiaTeamID = Spring.GetGaiaTeamID()

    local colRed = {r =  34/255, g = 12/255, b = 1.0, a = 1.0}
    local colGreen ={ r= 171/255, g=  236/255, b= 183/255, a= 255/255}
    local colGray ={r = 175/255, g= 175/255, b= 175/255, a = 128/255}

    local function GetMoneyMessage(number)
        local text =""
        if number < 0 then
            text=  "\255\255\34\12 $ " .. number
        else
           text = "\255\171\236\183 $ " .. number
        end
        return text
    end
    
    -- Display Lost /Gained Money depending on team
    local function DisplaytAtUnit(callname, unitID, team, message, r, g, b, a)
            local col = {r= r, g= g, b= b, a= a}
            local format =  "d"
            local size = 16
        --	 Spring.Echo("Display At Unit")
            if type(message) == "number" then
                format= "od"
                 if message < 0 then                  
                    col = colRed
                else
                    col= colGreen
                end
                message =   GetMoneyMessage(message)               
            else
                message = message
                col.r, col.g, col.b, col.a= 175/255, 175/255, 175/255, 156/255
                size = 10
            end

        Unit_StartFrame_Message[unitID] =
            {
                team = team,
                message = message,
                frame = spGetGameFrame(),
                format = format,
                col = col, 
                size = size
            }
    end

    local function DisplayAtLocation(callname, uid, x,y,z, team, damage, r, g, b, a)
        Spring.Echo("Display at Location Widget called")
        local storedData ={}
        storedData.team = team
        storedData.message = damage
        storedData.x = x
        storedData.y = y
        storedData.z = z
        storedData.frame = frame
        storedData.col = {r = r, g = g, b = b, a= a}
            
        UID_Location_Message[uid] = storedData
            
    end

    function gadget:Initialize()
        Spring.Echo(GetInfo().name .. " Initialization started")
        -- This associate the messages with the functions
        gadgetHandler:AddSyncAction("DisplaytAtUnit", DisplaytAtUnit)
        --	Spring.Echo(GetInfo().name.." Initialization ended")
    end

    function gadget:DrawScreenEffects()
        local currFrame = spGetGameFrame()
        UnitsToNil = {}

        for _, id in ipairs(spGetAllUnits()) do
            -- Spring.Echo("itterating over all units")
            for uid, valueT in pairs(Unit_StartFrame_Message) do

                -- Spring.Echo("itterating over all damaged")
                -- Check if Time has expsired
                if id == uid and valueT then
                    -- if attacker was me or i get a reward for another team attack a gaia unit
                    teamid = spGetUnitTeam(id)
                    if currFrame < valueT.frame + DrawForFrames then
                        -- Spring.Echo("Drawing Prizes")
                        x, y, z = spGetUnitPosition(uid)
                        if x then
                            frameOffset = (255 - (valueT.frame + DrawForFrames - currFrame)) * 0.25
                            local sx, sy =
                                spWorldToScreenCoords(x, y + frameOffset, z)
                                if valueT.col then
                                     gl.Color(valueT.col.r, valueT.col.g, valueT.col.b, valueT.col.a)
                                 end
                                gl.Text(valueT.message, sx, sy, valueT.size, valueT.format)                       
                        end
                    end
                end
            end
        end

        for uid, data in pairs(UID_Location_Message) do
            if data then --and data.team == myTeamID 

                if currFrame > data.frame and  currFrame < data.frame + DrawForFrames then
                        local frameOffset = (255 - (data.frame + DrawForFrames - currFrame)) * 0.25
                        local sx, sy = spWorldToScreenCoords(data.x,
                                                             data.y + frameOffset,
                                                             data.z)

                        if valueT.message < 0 then
                            gl.Color(1.0, 0.0, 0.0, 1.0)
                        else
                            gl.Color(0.0, 1.0, 0.0, 1.0)
                        end
                        gl.Text("$ " .. valueT.message, sx, sy, 16, "od")
                end
            end
        end

        for id, _ in pairs(UnitsToNil) do
            Unit_StartFrame_Message[id] = nil
        end
    end

end
