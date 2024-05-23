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
    local spUseTeamResource = Spring.UseTeamResource
    local spAddTeamResource = Spring.AddTeamResource
    local spGetUnitTeam = Spring.GetUnitTeam
    local spGetGameFrame = Spring.GetGameFrame
    local spGetUnitPosition = Spring.GetUnitPosition
    local spGetAllUnits = Spring.GetAllUnits
    local GameConfig = getGameConfig()
    local exemptFromRefundDefIds = getExemptFromRefundTypes(UnitDefs)
    local houseTypeTable = getCultureUnitModelNames_Dict_DefIDName(GameConfig.instance.culture,
                                                "house", UnitDefs)
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

    function gadget:Intialize()
        if not GG.Bank then GG.Bank = {TransferToTeam = TransferToTeam} end
        if not GG.DisguiseCivilianFor then GG.DisguiseCivilianFor = {} end
        if not GG.Propgandaservers then GG.Propgandaservers = {} end
    end

    allTeams = Spring.GetTeamList()
    for i = 1, #allTeams do GG.Propgandaservers[allTeams[i]] = 0 end

    function gadget:UnitDestroyed(unitID, unitDefID, teamID, attackerID)
        if attackerID  then
            attackerTeamID = Spring.GetUnitTeam(attackerID) 

            if(GG.DisguiseCivilianFor[unitID]) and
              teamID ~= attackerTeamID then
                maxhp = UnitDefs[unitDefID].health or UnitDefs[unitDefID].maxDamage
                if maxhp then

                    factor = 1.0
                    if GG.Propgandaservers and GG.Propgandaservers[teamID] then
                        factor = factor +
                                     (GG.Propgandaservers[teamID] *
                                         GameConfig.propandaServerFactor)
                    end
                    spAddTeamResource(attackerTeamID, "metal",
                                      math.ceil(math.abs(maxhp * factor)))
                    addInSecond(teamID, attackerID, "metal",
                                math.ceil((maxhp * factor)))
                end
            end

            if  houseTypeTable[unitDefID] then
                for _, team in pairs(Spring.GetTeamList()) do

                    if team ~= gaiaTeamID and team ~=attackerTeam then                    
                        if not GG.Propgandaservers[team] then
                            GG.Propgandaservers[team] = 0
                        end

                        factor = 1.0
                        if GG.Propgandaservers and GG.Propgandaservers[teamID] then
                            factor = factor +
                                         (GG.Propgandaservers[teamID] *
                                             GameConfig.propandaServerFactor)
                        end
                        spAddTeamResource(team, "metal",
                                          math.ceil(math.abs(GameConfig.costs.DestroyedHousePropanda * factor)))
                        addInSecond(team, unitID, "metal",
                                    math.ceil((GameConfig.costs.DestroyedHousePropanda * factor)))
                        
                        spawnMilitiaInHousesNearby(team, unitID, unitDefID)

                    end
                end

                   spUseTeamResource(attackerTeamID, "metal",
                                              GameConfig.costs.DestroyedHousePropanda)
                   addInSecond(attackerTeamID, unitID, "metal",
                                    -1*math.ceil((GameConfig.costs.DestroyedHousePropanda)))

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
        if not attackerID and weaponDefID then
            --ssieds are ignored - cause who know who really was the attacker
            return damage
        end

        if attackerTeam == gaiaTeamID then
            return damage 
        end

        -- civilian attacked by a not civilian
        if unitTeam == gaiaTeamID and attackerID and attackerTeam ~= unitTeam then

            if exemptFromRefundDefIds[unitDefID] then return end

            -- attackerPlayerList = Spring.GetPlayerList(attackerTeam)
            for _, team in pairs(Spring.GetTeamList()) do
                -- for all teams 
                -- if no propagandaserver registered 
                if not GG.Propgandaservers[team] then
                    GG.Propgandaservers[team] = 0
                end

                if team ~= gaiaTeamID then

                    boolTeamsAreAllied =
                        Spring.AreTeamsAllied(attackerTeam, team)
                    if boolTeamsAreAllied == true then
                        spUseTeamResource(team, "metal", damage)
                        addInSecond(team, unitID, "metal",
                                    -1 * math.ceil(damage))
                    else -- get enemy Teams -- tranfer damage as budget to them
                        factor = 1 +
                                     (GG.Propgandaservers[team] *
                                         GameConfig.propandaServerFactor)
                        spAddTeamResource(team, "metal",
                                          math.ceil(math.abs(damage * factor)))
                        addInSecond(team, unitID, "metal",
                                    math.ceil((damage * factor)))

                    end
                    -- This table contains per team- for each gaia Unit a entry of how much damage was done - per second
                end
            end
        end
    end


    function gadget:GameFrame(frame)
        if frame % 10 == 0 then
            if GG.Bank and GG.Bank[1] then
                local cur = GG.Bank
                GG.Bank = {TransferToTeam = TransferToTeam}

                for i = 1, #cur, 1 do
                    -- assert(cur[i].Reciever, "Reciever team missing ")
                    -- assert(cur[i].Money, "Money missing ")
                    -- assert(cur[i].DisplayUnit, "DisplayUnit /Location missing ")
                    if cur[i].DisplayUnit_Location then

                        -- assert(Spring.GetTeamInfo(cur[i].Reciever), "DisplayUnit missing ")
                        if cur[i].Money < 0 then
                            spUseTeamResource(cur[i].Reciever, "metal",
                                              math.abs(cur[i].Money))
                        else
                            spAddTeamResource(cur[i].Reciever, "metal",
                                              cur[i].Money)
                        end
                        addInSecond(cur[i].Reciever,
                                    cur[i].DisplayUnit_Location, "metal",
                                    cur[i].Money, colourWhite)
                    end
                end
            end
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
    local DrawForFrames = 1 * 30
    local Unit_StartFrame_Message = {}
    local UID_Location_Message = {}
    local gaiaTeamID = Spring.GetGaiaTeamID()

    local colRed = {r =  34/255, g = 12/255, b = 1.0, a = 1.0}
    local colGreen ={ r= 171/255, g=  236/255, b= 183/255, a= 255/255}


    
    -- Display Lost /Gained Money depending on team
    local function DisplaytAtUnit(callname, unitID, team, message, r, g, b, a)
            local col = {r= r, g= g, b= b, a= a}
            local format =  "d"
            local size = 16
        --	 Spring.Echo("Display At Unit")
            if type(message) == "number" then
                format= "od"
                if message < 0 then 
                    message =   message
                    col = colRed
                else
                    message =  message
                    col= colGreen
                end
            else
                message = message
                col.r, col.g, col.b, col.a= 175/255, 175/255, 175/255, 175/255
                size = 12
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
