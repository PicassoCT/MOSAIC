function widget:GetInfo()
    return {name="Clandestine operation status", desc="Private extraction and police influence feedback",
        author="Mosaic contributors", license="GPL3", layer=0, enabled=true}
end
local bribeDef = UnitDefNames.icon_bribe.id
local cyberDef = UnitDefNames.icon_cybercrime.id
local operatives = {}
for _, name in ipairs({"operativeasset","operativepropagator","operativeinvestigator","civilianagent"}) do
    if UnitDefNames[name] then operatives[UnitDefNames[name].id] = true end
end
function widget:DefaultCommand(kind, id)
    if kind ~= "unit" or not operatives[Spring.GetUnitDefID(id)] or
        not Spring.AreTeamsAllied(Spring.GetMyTeamID(),Spring.GetUnitTeam(id)) then return end
    local selected = Spring.GetSelectedUnits()
    if #selected == 0 then return end
    for _, unit in ipairs(selected) do
        if Spring.GetUnitDefID(unit) ~= bribeDef then return end
    end
    return CMD.GUARD
end
local function param(id, name) return Spring.GetUnitRulesParam(id,name) end
function widget:DrawWorld()
    if Spring.IsGUIHidden() then return end
    local frame, team = Spring.GetGameFrame(), Spring.GetMyTeamID()
    for _, id in ipairs(Spring.GetSelectedUnits()) do
        if Spring.GetUnitTeam(id) == team then
            local def = Spring.GetUnitDefID(id)
            local text, expires
            if def == bribeDef then
                expires = param(id,"bribe_until")
                if expires then
                    local count = param(id,"bribe_count") or 0
                    local protecting = (param(id,"bribe_target") or -1) >= 0
                    text = (protecting and "Police cover" or "False dispatch").." | "..count.." officers"
                    gl.Color(0.3,0.8,1,0.8)
                    for n=1,count do
                        local officer = param(id,"bribe_officer_"..n)
                        if officer and officer >= 0 then
                            local x,y,z = Spring.GetUnitPosition(officer)
                            if x then gl.DrawGroundCircle(x,y,z,55,24) end
                        end
                    end
                end
            elseif def == cyberDef then
                expires = param(id,"cybercrime_until")
                if expires then
                    text = "Extracted "..math.floor(param(id,"cybercrime_paid") or 0)
                    if param(id,"cybercrime_comeback") then text = text.." | Recovery aid received" end
                end
            end
            if text then
                local x,y,z = Spring.GetUnitViewPosition(id)
                if x then
                    gl.Color(1,1,1,1)
                    gl.PushMatrix()
                    gl.Translate(x,y+60,z)
                    gl.Billboard()
                    gl.Text(text.." | "..math.max(0,math.ceil((expires-frame)/30)).."s",0,0,14,"oc")
                    gl.PopMatrix()
                end
            end
        end
    end
    gl.Color(1,1,1,1)
end
