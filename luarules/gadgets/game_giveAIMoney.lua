function gadget:GetInfo()
    return {
        name = "Give AI Money",
        desc = " ",
        author = "Picasso",
        date = "Sep. 2022",
        license = "GNU GPL, v2 or later",
        layer = 1,
        enabled = true
    }
end

if (gadgetHandler:IsSyncedCode()) then
    VFS.Include("scripts/lib_OS.lua")
    VFS.Include("scripts/lib_UnitScript.lua")
    VFS.Include("scripts/lib_Animation.lua")
    VFS.Include("scripts/lib_Build.lua")
    VFS.Include("scripts/lib_mosaic.lua")

    everyNthFrame = math.floor(0.5*60*30)

    function gadget:GameFrame(frame)

        if frame % everyNthFrame == 0 then
            list= Spring.GetTeamList(),
            for i=1, #list do
                id = list[i]
                 nteamID, leader, isDead, isAiTeam, side, allyTeam, incomeMultiplier, customTeamKeys =  Spring.GetTeamInfo(id)
                    if not isDead and isAiTeam then
                        Spring.AddTeamResource (id,"metal", 350)
                        Spring.AddTeamResource (id,"energy",350)
                    end
            end
        end    
    end
end