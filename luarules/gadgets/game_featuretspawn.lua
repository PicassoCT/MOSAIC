function gadget:GetInfo()
    return {
        name = "Spawn A Feature API",
        desc = "Its not easy to Workaround ",
        author = "jk - cause everyone else was either to lazy, to dumb or busy bitching",
        date = "3rd of May 2010",
        license = "Free",
        layer = 0,
        version = 1,
        enabled = true
    }
end

if (not gadgetHandler:IsSyncedCode()) then return end

local function PushKillFeature(self, ...) self[#self + 1] = {...} end

local function PushCreateFeature(self, ...) self[#self + 1] = {...} end

if GG.FeaturesToSpawn == nil then
    GG.FeaturesToSpawn = {PushCreateFeature = PushCreateFeature}
end
if GG.FeaturesToKill == nil then
    GG.FeaturesToKill = {PushKillFeature = PushKillFeature}
end

function gadget:GameFrame(frame)
    if (frame % 10 == 0) then
        if GG.FeaturesToSpawn and GG.FeaturesToSpawn[1] then
            local cur = GG.FeaturesToSpawn
            GG.FeaturesToSpawn = {PushCreateFeature = PushCreateFeature}
            Spring.Echo("Spawn Features")
            for i = 1, #cur, 1 do
                --	Spring.Echo(unpack(cur[i]))
                assert(cur[i][4], "Z missing in PushCreateFeature " .. cur[i][1])
                assert(cur[i][5],
                       "teamID missing in PushCreateFeature " .. cur[i][1])
                teamID, leader, isDead, isAiTeam, side, allyTeam, customTeamKeys, incomeMultiplier =
                    Spring.GetTeamInfo(cur[i][6])

                if teamID and isDead == false then
                    Spring.CreateFeature(unpack(cur[i]))
                end
            end
        end

        if GG.FeaturesToKill and GG.FeaturesToKill[1] then
            local cur = GG.FeaturesToKill
            GG.FeaturesToKill = {PushKillFeature = PushKillFeature}
            Spring.Echo("Destroy Feature")
            for i = 1, #cur, 1 do
                Spring.DestroyFeature(unpack(cur[i]))
            end
        end
    end
end

