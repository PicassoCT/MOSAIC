-- MOSAIC-specific managers. Decisions use owned units, visible enemies and
-- public objective state. All command submission goes through framework.lua.
function CreateMosaicStrategy(teamID, allyTeamID, side)
    local S={}
    local difficulty=gadget.difficulty or "medium"
    local hard=difficulty=="hard" or difficulty=="impossible"
    local caps={servers=hard and 4 or 3, operatives=hard and 4 or 3,
        assets=hard and 3 or 2, scouts=2, combat=hard and 12 or 8, agents=2}
    local safe=side.."safehouse"
    local operative=side=="antagon" and "operativepropagator" or "operativeinvestigator"
    local assembly=side.."assembly"
    local gaia=Spring.GetGaiaTeamID()
    local morphs=VFS.Include("luarules/configs/side_morph_defs/"..(side=="antagon" and "Antagon" or "Protagon")..".lua")
    local morphOptions=morphs[safe] or {}
    local frame=0
    local owned,ready,counts={}, {}, {}
    local pending,orders,settings,missions,visited,blockedSites={}, {}, {}, {}, {}, {}
    local houses,targets,threats={}, {}, {}
    local budgetM,budgetE=0,0
    local diagnostics={ticks=0,queued=0,rejected=0,economy="not started",recon="not started",tactics="not started"}
    local nextReport,reportCount=0,0
    local home={x=Game.mapSizeX/2,z=Game.mapSizeZ/2}
    local economicNames={[safe]=true,propagandaserver=true,[assembly]=true}
    local specialistNames={[operative]=true,operativeasset=true,civilianagent=true,air_copter_scoutlett=true}
    local function definition(id) return UnitDefs[Spring.GetUnitDefID(id) or -1] end
    local function alive(id) return id and Spring.ValidUnitID(id) and not Spring.GetUnitIsDead(id) end
    local function position(id)
        local x,y,z=Spring.GetUnitPosition(id)
        if x then return {x=x,y=y,z=z} end
    end
    local function distance(a,b) return (a.x-b.x)^2+(a.z-b.z)^2 end
    local function mobile(def) return (def.speed or 0)>0 and not (def.customParams or {}).isupgrade end
    local function house(def)
        local n=def.name
        return (n:find("^house_asian") or n:find("^house_western") or n:find("^house_arab"))
            and not n:find("hologram") and not n:find("decal") and not n:find("ruin")
    end
    local function busy(id)
        if pending[id] then return true end
        local def=definition(id)
        local q=def and def.isFactory and Spring.GetFactoryCommands(id,0) or Spring.GetUnitCommands(id,0)
        if type(q)=="table" then return #q>0 end
        return (q or 0)>0
    end
    local function available(id)
        return ready[id] and not gadget.betrayalContacts[id]
            and Spring.GetUnitRulesParam(id,"betrayal_runner")~=1 and not Spring.GetUnitTransporter(id)
    end
    local function send(id,cmd,params,job,force)
        if not available(id) then return false end
        local signature=tostring(cmd)..":"..table.concat(params or {},",")
        local instantaneous=cmd==CMD.CLOAK or cmd==CMD.FIRE_STATE
        local last=instantaneous and settings[id] and settings[id][cmd] or (not instantaneous and orders[id])
        if not force and last and last.signature==signature and (busy(id) or frame-last.frame<300) then return true end
        local ok=GiveOrderToUnit(id,cmd,params or {},{})
        if ok then
            diagnostics.queued=diagnostics.queued+1
            local record={signature=signature,frame=frame,job=job}
            if instantaneous then
                settings[id]=settings[id] or {};settings[id][cmd]=record
            else orders[id]=record end
            return true
        end
        diagnostics.rejected=diagnostics.rejected+1
        return false
    end
    local function productionBusy(id)
        if pending[id] then return true end
        if not busy(id) then return false end
        local job=orders[id] and orders[id].job or ""
        return not (job:find("scout") or job:find("recon") or job:find("raid") or job:find("defend"))
    end
    local function count(name) return counts[name] or 0 end
    local function canBuild(id,defID)
        for _,opt in ipairs((definition(id) or {}).buildOptions or {}) do if opt==defID then return true end end
        return false
    end
    local function afford(m,e)
        return budgetM>=(m or 0) and budgetE>=(e or 0)
    end
    local function reserve(m,e) budgetM=budgetM-(m or 0);budgetE=budgetE-(e or 0) end
    local function risk(p,radius)
        local value=0
        for _,enemy in ipairs(threats) do
            if distance(p,enemy.pos)<radius*radius then value=value+enemy.power end
        end
        return value
    end
    local function scan()
        owned=Spring.GetTeamUnits(teamID) or {};table.sort(owned)
        ready,counts={},{}
        for _,id in ipairs(owned) do
            local def=definition(id)
            if def and alive(id) then
                counts[def.name]=count(def.name)+1
                local hp,maxHP,paralyze,_,built=Spring.GetUnitHealth(id)
                if hp and (built or 0)>=1 and (paralyze or 0)<hp then ready[id]=true end
                local p=pending[id]
                if p and def.id~=p.source then pending[id]=nil end -- completed morph or recycled ID
            end
        end
        for id,p in pairs(pending) do
            if not alive(id) or Spring.GetUnitTeam(id)~=teamID then
                pending[id]=nil
            elseif frame>p.expires then
                -- No creation/progress before deadline: release the job and choose
                -- another building, rather than leaving the producer idle forever.
                if p.house then blockedSites[p.house]=frame+1800 end
                send(id,CMD.STOP,{},"cancel stalled production",true)
                pending[id]=nil
            else
                counts[p.target]=count(p.target)+1
                if p.morph then counts[safe]=math.max(0,count(safe)-1) end
            end
        end
        budgetM=Spring.GetTeamResources(teamID,"metal") or 0
        budgetE=Spring.GetTeamResources(teamID,"energy") or 0
        for _,id in ipairs(owned) do
            if ready[id] and economicNames[definition(id).name] then home=position(id) or home;break end
        end
        houses,targets,threats={}, {}, {}
        local all=Spring.GetAllUnits() or {};table.sort(all)
        for _,id in ipairs(all) do
            local t=Spring.GetUnitTeam(id)
            local neutral=t==gaia
            local enemy=t and t~=gaia and not Spring.AreTeamsAllied(t,teamID)
            -- Explicit LOS guard even when the host is a full-view spectator.
            local los=enemy and Spring.GetUnitLosState(id,allyTeamID)
            local visible=los==true or (type(los)=="table" and los.los)
            if neutral or visible then
                local def=definition(id)
                local pos=position(id)
                if def and pos then
                    if neutral and house(def) then houses[#houses+1]={id=id,pos=pos} end
                    if visible and not Spring.GetUnitIsCloaked(id) then
                        local power=math.max(1,(def.metalCost or 100)/500)
                        if #(def.weapons or {})>0 then threats[#threats+1]={id=id,pos=pos,power=power,def=def} end
                        local value=economicNames[def.name] and 8 or (def.name:find("safehouse") and 10 or 3)
                        if def.name=="propagandaserver" or def.name=="launcher" then value=12 end
                        if def.name:find("operative") then value=10 end
                        targets[#targets+1]={id=id,pos=pos,value=value,def=def,kind="enemy"}
                    elseif neutral then
                        local defender=Spring.GetUnitRulesParam(id,"objective_protagon")
                        local destroyed=Spring.GetUnitRulesParam(id,"objective_destroyed")==1
                        if defender~=nil then
                            local ours=(defender==1)==(side=="protagon")
                            if (not ours and not destroyed) or (ours and destroyed) then
                                targets[#targets+1]={id=id,pos=pos,value=6+(Spring.GetUnitRulesParam(id,"objective_income") or 0),
                                    def=def,kind="objective"}
                            end
                        elseif Spring.GetUnitRulesParam(id,"objective_security_site") and
                            (function() local l=Spring.GetUnitLosState(id,allyTeamID);return l==true or (type(l)=="table" and l.los) end)() then
                            threats[#threats+1]={id=id,pos=pos,power=math.max(1,(def.metalCost or 500)/500),def=def}
                        end
                    end
                end
            end
        end
        table.sort(houses,function(a,b) return a.id<b.id end)
    end
    local function site(builder)
        local origin=position(builder)
        if not origin then return end
        local best,score
        for _,h in ipairs(houses) do
            local occupied=false
            for _,id in ipairs(owned) do
                local def=definition(id)
                local p=def and economicNames[def.name] and position(id)
                if p and distance(p,h.pos)<180^2 then occupied=true;break end
            end
            for _,p in pairs(pending) do if p.house==h.id then occupied=true end end
            if not occupied and (blockedSites[h.id] or 0)<=frame and risk(h.pos,650)<2 then
                local y=Spring.GetGroundHeight(h.pos.x,h.pos.z)
                local def=UnitDefNames[safe]
                if def and Spring.TestBuildOrder(def.id,h.pos.x,y,h.pos.z,0)>0 then
                    local s=distance(origin,h.pos)+risk(h.pos,1000)*500000
                    if not score or s<score then best,score=h,s end
                end
            end
        end
        return best
    end
    local function build(id,name,h)
        local def=UnitDefNames[name]
        if not def or not canBuild(id,def.id) or productionBusy(id) then return false end
        if not afford(def.metalCost,def.energyCost) then diagnostics.economy="waiting: resources for "..name;diagnostics.economyBlocker=diagnostics.economyBlocker or diagnostics.economy;return false end
        local params={}
        if not definition(id).isFactory then
            if not h then return false end
            params={h.pos.x,Spring.GetGroundHeight(h.pos.x,h.pos.z),h.pos.z,0}
        end
        if send(id,-def.id,params,"produce "..name) then
            pending[id]={target=name,source=definition(id).id,house=h and h.id,expires=frame+1800}
            counts[name]=count(name)+1
            reserve(def.metalCost,def.energyCost)
            diagnostics.economy="building "..name
            return true
        end
        return false
    end
    local function upgrade(id,name)
        local dest=UnitDefNames[name]
        if not dest or busy(id) then return false end
        local spec
        for _,opt in ipairs(morphOptions) do if opt.into==name then spec=opt;break end end
        if not spec or not afford(spec.metal,spec.energy) then
            diagnostics.economy="waiting: upgrade resources for "..name;diagnostics.economyBlocker=diagnostics.economyBlocker or diagnostics.economy;return false
        end
        -- Use the command descriptor installed by UnitMorph. No assumptions
        -- about global GG in the unsynced realm or command ID allocation order.
        local command
        for _,desc in ipairs(Spring.GetUnitCmdDescs(id) or {}) do
            if desc.id>0 and desc.texture=="#"..dest.id and not desc.disabled then command=desc.id;break end
        end
        if not command then diagnostics.economy="waiting: morph menu for "..name;diagnostics.economyBlocker=diagnostics.economyBlocker or diagnostics.economy;return false end
        if send(id,command,{},"upgrade "..name) then
            pending[id]={target=name,source=definition(id).id,morph=true,expires=frame+(spec.time+60)*30}
            counts[name]=count(name)+1
            counts[safe]=math.max(0,count(safe)-1) -- conversion consumes this safehouse
            reserve(spec.metal,spec.energy)
            diagnostics.economy="upgrading "..name
            return true
        end
        return false
    end
    local function nearestHome(p)
        local best,score=home,nil
        for _,id in ipairs(owned) do
            if ready[id] and economicNames[definition(id).name] then
                local q=position(id)
                local s=q and distance(p,q)+risk(q,650)*500000
                if s and (not score or s<score) then best,score=q,s end
            end
        end
        return best
    end
    local function move(id,p,job,cmd)
        local def=definition(id)
        local x=math.max(16,math.min(Game.mapSizeX-16,p.x))
        local z=math.max(16,math.min(Game.mapSizeZ-16,p.z))
        local y=Spring.GetGroundHeight(x,z)
        if not def.canFly and Spring.TestMoveOrder and not Spring.TestMoveOrder(def.id,x,y,z) then return false end
        return send(id,cmd or CMD.MOVE,{x,y,z},job)
    end
    local function economy()
        diagnostics.economy="waiting: producers busy / roster at role limits"
        diagnostics.economyBlocker=nil
        local desiredServers=math.min(caps.servers,1+math.floor(frame/5400))
        local wantedUpgrade=count("propagandaserver")<desiredServers and "propagandaserver"
            or (count(assembly)<1 and count("propagandaserver")>=2 and assembly or nil)
        -- Keep one active recruitment hub while another converts. Upgrades
        -- require separate city buildings, not stacking everything at home.
        local desiredSafe=wantedUpgrade and 2 or 1
        local builders={}
        for _,id in ipairs(owned) do
            if available(id) and definition(id).name==operative then builders[#builders+1]=id end
        end
        if count(safe)<desiredSafe then
            for _,id in ipairs(builders) do
                if not productionBusy(id) then
                    local h=site(id)
                    if h then build(id,safe,h);break else diagnostics.economy="waiting: unoccupied safe building" end
                end
            end
        end
        local recruitmentHubs=0
        for _,id in ipairs(owned) do
            if ready[id] and definition(id).name==safe and not (pending[id] and pending[id].morph) then
                recruitmentHubs=recruitmentHubs+1
            end
        end
        if wantedUpgrade and recruitmentHubs>=2 then
            for _,id in ipairs(owned) do
                if available(id) and definition(id).name==safe and upgrade(id,wantedUpgrade) then break end
            end
        end
        -- Train roles instead of an unbounded cheapest-unit queue. Respect the
        -- current roster AND outstanding orders; never queue more than one job.
        local combatCount=0
        for _,id in ipairs(owned) do
            local def=definition(id)
            if def and mobile(def) and not specialistNames[def.name] and #(def.weapons or {})>0 then combatCount=combatCount+1 end
        end
        for _,p in pairs(pending) do
            local def=UnitDefNames[p.target]
            if def and mobile(def) and not specialistNames[p.target] and #(def.weapons or {})>0 then combatCount=combatCount+1 end
        end
        local armored,airborne=0,0
        for _,t in ipairs(threats) do
            if t.def.canFly then airborne=airborne+1 end
            if (t.def.metalCost or 0)>2000 then armored=armored+1 end
        end
        for _,id in ipairs(owned) do
            local def=definition(id)
            if available(id) and def.isFactory and not busy(id) then
                local choices={}
                if count(operative)<caps.operatives then choices[#choices+1]=operative end
                if count("air_copter_scoutlett")<caps.scouts then choices[#choices+1]="air_copter_scoutlett" end
                if count("operativeasset")<caps.assets and count("propagandaserver")>=1 then choices[#choices+1]="operativeasset" end
                if count("civilianagent")<caps.agents then choices[#choices+1]="civilianagent" end
                if combatCount<caps.combat and count("propagandaserver")>=1 then
                    local roster=side=="antagon" and {"ground_walker_mg","ground_walker_grenade","civilian_truck_mg","ground_walker_flame","air_copter_antiarmor"}
                        or {"ground_walker_mg","ground_truck_mg","air_copter_mg","air_copter_antiarmor"}
                    if armored>0 then table.insert(roster,1,"air_copter_antiarmor") end
                    if airborne>0 then table.insert(roster,1,"ground_truck_rocket") end
                    for _,name in ipairs(roster) do if count(name)<3 then choices[#choices+1]=name end end
                end
                for _,name in ipairs(choices) do
                    -- Avoid consuming the recovery economy's last funds on
                    -- optional combat when a server is still missing.
                    if not wantedUpgrade or name==operative or count("propagandaserver")>=1 then
                        if build(id,name) then
                            if not specialistNames[name] then combatCount=combatCount+1 end
                            break
                        end
                    end
                end
            end
        end
        -- Finite emergency cybercrime near a fresh city building. The icon's
        -- actual construction and resource costs are used, and each site has a
        -- recovery cooldown; it is never spammed as an infinite money exploit.
        if count("propagandaserver")==0 and (budgetM<2000 or budgetE<2000) and count("icon_cybercrime")==0 then
            for _,id in ipairs(builders) do
                if not busy(id) then
                    local p=position(id)
                    for _,h in ipairs(houses) do
                        if p and distance(p,h.pos)<400^2 and (visited["cyber"..h.id] or 0)<=frame then
                            if build(id,"icon_cybercrime",h) then visited["cyber"..h.id]=frame+7200;break end
                        end
                    end
                    break
                end
            end
        end
    end
    local function scout(id)
        local p=position(id)
        if not p then return end
        local mission=missions[id]
        if mission then
            if distance(p,mission.pos)<140^2 or frame-mission.start>1200 or risk(mission.pos,600)>3 then
                visited[mission.site]=frame+3600;missions[id]=nil
            else move(id,mission.pos,"reconnaissance");return end
        end
        local best,score
        for _,h in ipairs(houses) do
            if (visited[h.id] or 0)<=frame and risk(h.pos,650)<2 then
                local assigned=false
                for _,m in pairs(missions) do if m.site==h.id then assigned=true end end
                local s=distance(p,h.pos)+distance(home,h.pos)*0.15
                if not assigned and (not score or s<score) then best,score=h,s end
            end
        end
        if best then
            missions[id]={site=best.id,pos=best.pos,start=frame}
            move(id,best.pos,"scout city block")
            diagnostics.recon="scouting separate city blocks"
        else diagnostics.recon="waiting: no safe unexplored block" end
    end
    local function recon()
        diagnostics.recon="waiting: no available scouts"
        for _,id in ipairs(owned) do
            local def=definition(id)
            if available(id) and (def.name=="air_copter_scoutlett" or def.name=="civilianagent") then
                if risk(position(id) or home,500)>3 then move(id,nearestHome(position(id) or home),"withdraw scout")
                else scout(id) end
            end
        end
    end
    local function selectTarget(p,role,group,assignments,attacker)
        local best,score
        for _,t in ipairs(targets) do
            local raidable=(t.def.name:find("safehouse") or t.def.name=="propagandaserver" or t.def.name=="launcher" or t.def.name:find("assembly"))
            local eligible=not role or (role=="raid" and t.kind=="enemy" and raidable)
                or (role=="assassin" and t.kind=="enemy" and t.def.name:find("operative"))
            -- Do not send anti-air trucks to shoot a ground building, or
            -- anti-armour gunships to intercept planes they cannot damage.
            if attacker.name=="ground_truck_rocket" and not t.def.canFly then eligible=false end
            if attacker.name=="air_copter_antiarmor" and t.def.canFly then eligible=false end
            if role and t.def.canFly then eligible=false end
            if eligible and (assignments[t.id] or 0)<(role and 1 or 3) then
                local danger=risk(t.pos,650)
                if danger<=math.max(group*2,role and (attacker.metalCost or 500)/500*1.5 or 0) then
                    local s=t.value/(1+distance(p,t.pos)/1000000+danger)
                    if not score or s>score then best,score=t,s end
                end
            end
        end
        return best
    end
    local function tactics()
        diagnostics.tactics="waiting: reconnaissance / local superiority"
        local assignments={}
        local fighters={}
        for _,id in ipairs(owned) do
            local def=definition(id)
            if available(id) and mobile(def) and not pending[id] and not busy(id) then
                -- idle operatives get real orders; base construction remains
                -- reserved while its order is active.
                if def.name==operative or def.name=="operativeasset" then fighters[#fighters+1]=id
                elseif not specialistNames[def.name] and #(def.weapons or {})>0 then fighters[#fighters+1]=id end
            elseif available(id) and mobile(def) and not pending[id] then
                -- Ongoing tactical orders are revisited for defence and retreat.
                local job=orders[id] and orders[id].job or ""
                if job:find("raid") or job:find("attack") or job:find("defend") or job:find("retreat") then fighters[#fighters+1]=id end
            end
        end
        for index,id in ipairs(fighters) do
            local def=definition(id)
            local p=position(id)
            local hp,maxHP=Spring.GetUnitHealth(id)
            if p and hp and maxHP and maxHP>0 then
                local retreat=hp/maxHP<0.4 or risk(p,500)>math.max(3,#fighters,(def.metalCost or 500)/500*2)
                local isOp=def.name==operative or def.name=="operativeasset"
                if retreat then
                    move(id,nearestHome(p),"retreat wounded unit")
                    if def.canCloak then send(id,CMD.CLOAK,{1},"retreat cloak") end
                    diagnostics.tactics="retreating damaged / outmatched team"
                else
                    local intruder
                    for _,t in ipairs(threats) do
                        if distance(t.pos,home)<900^2 and Spring.GetUnitTeam(t.id)~=gaia then intruder=t;break end
                    end
                    if intruder and not isOp and (assignments[intruder.id] or 0)<3
                        and not (def.name=="ground_truck_rocket" and not intruder.def.canFly)
                        and not (def.name=="air_copter_antiarmor" and intruder.def.canFly) then
                        assignments[intruder.id]=(assignments[intruder.id] or 0)+1
                        send(id,CMD.ATTACK,{intruder.id},"defend network")
                        diagnostics.tactics="defending threatened network"
                    else
                        local role=def.name==operative and "raid" or (def.name=="operativeasset" and "assassin" or nil)
                        local target=selectTarget(p,role,isOp and 1 or math.min(3,#fighters),assignments,def)
                        if target then
                            assignments[target.id]=(assignments[target.id] or 0)+1
                            if isOp then
                                if distance(p,target.pos)>200^2 then
                                    if def.canCloak then send(id,CMD.CLOAK,{1},"approach cloak") end
                                    move(id,target.pos,role=="assassin" and "attack covert approach" or "raid approach")
                                else
                                    if def.canCloak then send(id,CMD.CLOAK,{0},"raid decloak") end
                                    send(id,CMD.ATTACK,{target.id},role=="assassin" and "attack exposed operative" or "raid exposed network")
                                end
                            else
                                -- At most three combat units assigned per target.
                                -- Approach from alternating offsets, then engage.
                                if distance(p,target.pos)>500^2 then
                                    local offset=(index%2==0 and -1 or 1)*200
                                    move(id,{x=target.pos.x+offset,z=target.pos.z-offset},"attack flank",CMD.FIGHT)
                                else send(id,CMD.ATTACK,{target.id},"attack strategic target") end
                            end
                            diagnostics.tactics="raids / split pressure on exposed targets"
                        elseif isOp then
                            if busy(id) and orders[id] and orders[id].job=="raid exposed network" then
                                diagnostics.tactics="waiting: raid resolution"
                            else scout(id) end
                        else
                            local offset=(index%4)*160
                            move(id,{x=home.x+offset,z=home.z-240},"defend dispersed reserve")
                        end
                    end
                end
            end
        end
    end
    function S.GameStart()
        local x,_,z=Spring.GetTeamStartPosition(teamID)
        if x and x>=0 and z and z>=0 then home={x=x,z=z} end
    end
    function S.GameFrame(f)
        frame=f;diagnostics.ticks=diagnostics.ticks+1
        scan();economy();recon();tactics()
        if frame>=nextReport then
            nextReport=frame+900;reportCount=reportCount+1
            if reportCount<=5 or gadget.IsDebug(teamID) then
                Spring.Echo("Prometheus team "..teamID..": managers="..diagnostics.ticks.." queued="..diagnostics.queued
                    .." rejected="..diagnostics.rejected.."; economy="..diagnostics.economy
                    .."; economy blocker="..(diagnostics.economyBlocker or "none")
                    .."; recon="..diagnostics.recon.."; tactics="..diagnostics.tactics)
            end
        end
    end
    function S.UnitCreated(id,defID,t,builder)
        local p=pending[builder]
        if p and UnitDefs[defID] and UnitDefs[defID].name==p.target then pending[builder]=nil end
    end
    function S.UnitFinished() end -- inventory reconciliation covers delayed spawn, reload and transfers
    function S.UnitDestroyed(id)
        pending[id],orders[id],settings[id],missions[id]=nil,nil,nil,nil
    end
    function S.GetDiagnostics() return diagnostics end
    return S
end
