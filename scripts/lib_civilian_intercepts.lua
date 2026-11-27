-- Shared eligibility for ambient crowds and player-directed civilian control.
-- False/empty interrogation records are preparation, not an active detention.
local M={}
M.crowdActivities={gathering=true,parade=true}
M.emergencyStarts={startFleeing=true,startAnarchyBehaviour=true}
M.crowdTakeovers={startPeacefullProtest=true}
function M.IsDetained(G,id)
    if (G.CloseCombatInvolved or {})[id] then return true end
    for _,active in pairs((G.InterrogationTable or {})[id] or {}) do
        if active then return true end
    end
    return false
end
function M.IsStunned(S,id)
    return S.GetUnitIsStunned and S.GetUnitIsStunned(id)==true or false
end
function M.SocialEngineer(G,S,id)
    local engineer=(G.SocialEngineeredPeople or {})[id]
    if type(engineer)=="number" and (G.SocialEngineers or {})[engineer]
        and S.ValidUnitID(engineer) and not S.GetUnitIsDead(engineer) then return engineer end
end
return M
