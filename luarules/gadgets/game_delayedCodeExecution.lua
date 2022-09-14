function gadget:GetInfo()
    return {
        name = "Push Delayed Code Execution",
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

local function PushCode(self, ...) self[#self + 1] = {Spring.GetGameFrame(), ...} end


if GG.ExecuteDelayed == nil then
    GG.ExecuteDelayed = {PushCode = PushCode}
end


function gadget:GameFrame(frame)
    if (frame > 1 and frame % 10 == 0) then
        if GG.ExecuteDelayed and GG.ExecuteDelayed[1] and GG.ExecuteDelayed[1][1] < frame then
            local cur = GG.ExecuteDelayed
            GG.ExecuteDelayed = {PushCode = PushCode}
--            Spring.Echo("Spawn Units")
            for i = 1, #cur, 1 do
                local codeToExecute = cur[2]
                codeToExecute(cur[3])          
            end
        end    
    end
end

