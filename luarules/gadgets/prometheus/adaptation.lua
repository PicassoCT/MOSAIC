-- Engagement learning uses our own combat losses and recently observed enemy
-- casualties. It never reads a hidden enemy roster or grants free resources.
return function(teamID, gaia, baseCaps)
    local self={tier=0,opponentVictories=0,won=0,drawn=0,mode='balanced',visible=0,material=0}
    local observed,hits,conflicts={},{},{}
    local function value(def) return math.max(100,def and def.metalCost or 100) end
    local function relevant(def)
        return def and (#(def.weapons or {})>0 or def.name:find('operative')
            or def.name:find('safehouse') or def.name:find('assembly') or def.name=='propagandaserver')
    end
    local function hostile(team)
        return team and team~=gaia and team~=teamID and not Spring.AreTeamsAllied(teamID,team)
    end
    local function conflict(team,frame)
        if not conflicts[team] then conflicts[team]={start=frame,last=frame,lost=0,won=0} end
        conflicts[team].last=frame
        return conflicts[team]
    end
    function self.Observe(targets,home,frame)
        self.visible,self.material=0,0
        for _,t in ipairs(targets) do
            if t.kind=='enemy' then
                local team=Spring.GetUnitTeam(t.id)
                if hostile(team) then
                    observed[t.id]={def=t.def,team=team,pos={x=t.pos.x,z=t.pos.z},seen=frame}
                    self.visible=self.visible+1
                    self.material=self.material+value(t.def)
                end
            end
        end
        local air,armor,raids,forts,economy=0,0,0,0,0
        for id,o in pairs(observed) do
            if frame-o.seen>2700 then observed[id]=nil
            else
                local def=o.def
                if def.canFly and #(def.weapons or {})>0 then air=air+1 end
                if not def.canFly and (def.metalCost or 0)>2000 and #(def.weapons or {})>0 then armor=armor+1 end
                if #(def.weapons or {})>0 then
                    if (o.pos.x-home.x)^2+(o.pos.z-home.z)^2<900^2 then raids=raids+1 end
                    if (def.speed or 0)==0 then forts=forts+1 end
                end
                if def.name:find('safehouse') or def.name=='propagandaserver' then economy=economy+1 end
            end
        end
        if air>0 then self.mode='air'
        elseif armor>0 then self.mode='armor'
        elseif raids>0 then self.mode='raids'
        elseif forts>0 then self.mode='fortified'
        elseif economy>1 then self.mode='expansion'
        else self.mode='balanced' end
    end
    function self.Damaged(id,damage,paralyzer,attackerTeam,frame)
        if damage<=0 or paralyzer or not hostile(attackerTeam) then return end
        hits[id]={team=attackerTeam,frame=frame}
        if conflicts[attackerTeam] then conflicts[attackerTeam].last=frame end
    end
    function self.Lost(id,def,frame)
        local hit=hits[id];hits[id]=nil
        if hit and frame-hit.frame<=900 and relevant(def) then
            local c=conflict(hit.team,frame);c.lost=c.lost+value(def)
        end
    end
    function self.EnemyDestroyed(id,attackerTeam,frame)
        local o=observed[id];observed[id]=nil
        if o and attackerTeam==teamID and frame-o.seen<=90 and relevant(o.def) then
            local c=conflict(o.team,frame);c.won=c.won+value(o.def)
        end
    end
    function self.Forget(id) hits[id]=nil end
    function self.Update(frame)
        for team,c in pairs(conflicts) do
            -- A quiet 15 seconds closes a fight. Prolonged battles are assessed
            -- in one-minute stages, not once per kill or damage callback.
            if frame-c.last>=450 or frame-c.start>=1800 then
                local result='draw'
                if c.lost>c.won*1.1 then
                    self.opponentVictories=self.opponentVictories+1
                    self.tier=math.min(6,self.tier+1)
                    result='opponent victory'
                elseif c.won>c.lost*1.1 then self.won=self.won+1;result='AI victory'
                else self.drawn=self.drawn+1 end
                Spring.Echo('Prometheus engagement team '..teamID..' vs '..team..': '..result
                    ..'; lost_material='..c.lost..'; destroyed_material='..c.won..'; response_tier='..self.tier)
                conflicts[team]=nil
            end
        end
        for id,hit in pairs(hits) do if frame-hit.frame>900 then hits[id]=nil end end
    end
    function self.Caps()
        local t=self.tier
        return {servers=baseCaps.servers+math.min(3,t),operatives=baseCaps.operatives+math.floor(t/2),
            assets=baseCaps.assets+math.floor(t/3),scouts=baseCaps.scouts+math.floor(t/3),
            combat=baseCaps.combat+t*3,agents=baseCaps.agents+math.floor(t/3)}
    end
    return self
end
