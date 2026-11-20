function widget:GetInfo()
    return {name = "Human Shield command art", desc = "Hostage ability cursor and command icon",
        author = "MOSAIC contributors", license = "GPL v2 or later", layer = 0, enabled = true}
end

VFS.Include("luarules/configs/commandsIDs.lua")

function widget:Initialize()
    Spring.AssignMouseCursor("HumanShield", "icexuick_200/cursorhumanshield", true, true)
    Spring.SetCustomCommandDrawData(CMD_HUMAN_SHIELD, "HumanShield", {1, 0.65, 0.15, 0.8})
end
