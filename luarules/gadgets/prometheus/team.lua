-- One owner per unit: rescue has priority over the strategy managers.
function CreateTeam(teamID, allyTeamID, side)
    local strategy=CreateMosaicStrategy(teamID,allyTeamID,side)
    local rescue=CreateBetrayalMgr(teamID)
    local team={}
    local last=-90
    function team.GameStart() strategy.GameStart() end
    function team.GameFrame(f)
        if f-last<90 then return end
        last=f
        rescue.GameFrame(f)
        strategy.GameFrame(f)
    end
    team.UnitCreated=strategy.UnitCreated
    team.UnitFinished=strategy.UnitFinished
    team.UnitDestroyed=strategy.UnitDestroyed
    team.UnitTaken=strategy.UnitDestroyed
    function team.UnitGiven(u,def,t) strategy.UnitCreated(u,def,t);strategy.UnitFinished(u,def,t) end
    function team.UnitIdle() end -- manager polls queues, never overwrites long jobs on an idle callback
    function team.Shutdown() rescue.Shutdown() end
    team.GetDiagnostics=strategy.GetDiagnostics
    return team
end
