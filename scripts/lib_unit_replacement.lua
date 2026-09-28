-- Recreate team-caching scripts without treating an ownership change as a death.
-- A failed spawn leaves the original and its inventory intact. Never copy orders.
return function(id, team, options)
    options = options or {}
    if not id or not Spring.ValidUnitID(id) or Spring.GetUnitIsDead(id) then return end
    local def, oldTeam = Spring.GetUnitDefID(id), Spring.GetUnitTeam(id)
    local x,y,z = Spring.GetUnitPosition(id)
    if options.position then x,y,z = unpack(options.position) end
    local hp,_,paralyze,capture,built = Spring.GetUnitHealth(id)
    local experience = Spring.GetUnitExperience(id)
    local rx,ry,rz = Spring.GetUnitRotation(id)
    local previous = GG.UnitReplacement
    GG.UnitReplacement = {oldID=id, team=team}
    local newID = Spring.CreateUnit(def,x,y,z,Spring.GetUnitBuildFacing(id) or 0,team,false,false)
    if not newID then GG.UnitReplacement=previous;return end
    GG.UnitReplacement.newID = newID
    Spring.SetUnitHealth(newID,{health=hp,paralyze=paralyze,capture=capture,build=built})
    Spring.SetUnitExperience(newID,experience or 0)
    Spring.SetUnitRotation(newID,rx,ry,rz)
    if GG.TransferStickyBombInventory then GG.TransferStickyBombInventory(id,newID) end
    if GG.Counterintelligence then GG.Counterintelligence.UnitReplaced(id,newID) end
    if options.preserveGraph~=false and GG.BetrayalUnitReplaced then GG.BetrayalUnitReplaced(id,newID,oldTeam,team) end
    for house, occupant in pairs(GG.houseHasSafeHouseTable or {}) do
        if occupant==id then GG.houseHasSafeHouseTable[house]=newID end
    end
    if options.beforeDestroy then options.beforeDestroy(newID) end
    Spring.DestroyUnit(id,false,true)
    GG.UnitReplacement = previous
    return newID
end
