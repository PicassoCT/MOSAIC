-- Run from the game root with Lua 5.1 or newer. Exercise the production
-- director with deterministic engine services, not a duplicate state machine.
local controller = dofile('luarules/gadgets/include/city_parade.lua')
local catalog = dofile('scripts/lib_truck_parade_payloads.lua')
CMD = {MOVE=10, STOP=0}
local function copy(t)
    local result={}; for k,v in pairs(t) do result[k]=type(v)=='table' and copy(v) or v end
    return result
end
local function count(t) local n=0; for _ in pairs(t) do n=n+1 end; return n end
local function when(day,hour) return math.floor((day-1+hour/24-0.5)*28800+0.5) end
local function check(name,fn) fn(); print('PASS: '..name) end

local function fixture(options)
    options=options or {}
    local config=copy(dofile('luarules/configs/city_parade.lua'))
    for k,v in pairs(options.config or {}) do config[k]=v end
    local f={frame=0,units={},orders={},effects={},rules={},speeds={},destroyed={},trips={},
        unitRules={},poses={},nativeHidden={},nativeHiddenCalls={},cylinderQueries={},starts=0,polls=0,nextID=1000,config=config,
        wind=options.wind or {3,0,-4},windReads=0,messages={}}
    local defs,names={},{}
    for i,name in ipairs({'truck_arab6','truck_arab7','truck_arab8','truckpayloadparade',
        'civilian_arab0','house_arab0','operative','house_ruin',
        'house_western_hologram_buisness','paradehologram','animated_hologram','animated_hologramv2'}) do
        defs[i]={id=i,name=name,moveDef={id=1},speed=60}; names[name]=defs[i]
    end
    defs[10].customParams={parade_hologram=true}
    f.G={GlobalGameState='normal',CitySpawnComplete=true,CivilianTable={},UnitArrivedAtTarget={},
        BuildingTable={},CivilianUnitInternalLogicActive={},DisguiseCivilianFor={},
        AerosolAffectedCivilians={},CityParadeRetired={}}
    function f:add(id,def,x,z,team)
        self.units[id]={def=def,x=x,z=z,team=team or 0,hp=100,maxhp=100}
        self.unitRules[id]={}
        if def==6 then self.G.BuildingTable[id]={x=x,z=z} end
        return id
    end
    f:add(100,6,500,500); f:add(101,6,2000,500)
    f:add(102,6,2000,2000); f:add(103,6,500,2000)
    local graph={[100]={101,103},[101]={100,102},[102]={101,103},[103]={100,102}}
    local function live(id) local u=f.units[id]; return u and not u.dead end
    local S={
        Echo=function(message) f.messages[#f.messages+1]=message end,
        GetGaiaTeamID=function() return 0 end,
        GetGameFrame=function() return f.frame end,
        GetGameRulesParam=function(key) return f.rules[key] end,
        SetGameRulesParam=function(key,value) f.rules[key]=value end,
        GetUnitRulesParam=function(id,key) return (f.unitRules[id] or {})[key] end,
        SetUnitRulesParam=function(id,key,value) f.unitRules[id][key]=value end,
        ValidUnitID=function(id) return live(id)~=nil and live(id)~=false end,
        GetUnitIsDead=function(id) return not live(id) end,
        GetUnitPosition=function(id) local u=f.units[id]; if live(id) then return u.x,0,u.z end end,
        GetUnitDefID=function(id) return live(id) and f.units[id].def end,
        GetUnitTeam=function(id) return live(id) and f.units[id].team end,
        GetUnitTransporter=function(id) return live(id) and f.units[id].parent end,
        GetUnitHealth=function(id) local u=f.units[id]; if live(id) then return u.hp,u.maxhp end end,
        GetUnitRadius=function(id) return f.units[id].def==6 and 100 or 30 end,
        GetUnitHeight=function(id) return f.units[id].def==6 and 200 or 40 end,
        GetGroundHeight=function() return 0 end,
        GetWind=function()
            f.windReads=f.windReads+1
            local x,y,z=f.wind[1],f.wind[2],f.wind[3]
            local strength=math.sqrt(x*x+y*y+z*z)
            local divisor=math.max(strength,1)
            return x,y,z,strength,x/divisor,y/divisor,z/divisor
        end,
        TestMoveOrder=function() return not options.blocked end,
        GetAllUnits=function()
            local ids={}; for id in pairs(f.units) do if live(id) then ids[#ids+1]=id end end
            table.sort(ids); return ids
        end,
        GetUnitsInCylinder=function(x,z,radius,team)
            f.cylinderQueries[#f.cylinderQueries+1]={x=x,z=z,radius=radius}
            local ids={}
            for id,u in pairs(f.units) do
                if live(id) and (team==nil or u.team==team) and (u.x-x)^2+(u.z-z)^2<=radius^2 then
                    ids[#ids+1]=id
                end
            end
            table.sort(ids); return ids
        end,
        GiveOrderToUnit=function(id,cmd,params)
            assert(live(id)); f.orders[#f.orders+1]={id=id,cmd=cmd,params=copy(params)}
        end,
        DestroyUnit=function(id,selfDestruct,reclaimed)
            assert(reclaimed and not selfDestruct); f.destroyed[id]=true; f.units[id].dead=true
        end,
        SpawnCEG=function(name,x,y,z,dx,dy,dz)
            assert(type(x)=='number' and type(z)=='number')
            f.effects[#f.effects+1]={name=name,x=x,y=y,z=z,dx=dx,dy=dy,dz=dz}
        end,
        UnitScript={CallAsUnit=function(_,fn,...) return fn(...) end},
    }
    S.UnitScript.GetScriptEnv=function(id)
        if not live(id) then return nil end
        if f.units[id].def==4 then
            return {SetParadeVariant=function(index)
                assert(index>=1 and index<=#catalog.variants)
                f.units[id].variant=index; return not options.rejectVariant
            end}
        end
        if f.units[id].def==11 or f.units[id].def==12 then
            return {SetParadeCommercialHidden=function(hidden)
                f.nativeHidden[id]=hidden
                f.nativeHiddenCalls[#f.nativeHiddenCalls+1]={id=id,hidden=hidden}
            end}
        end
        return {
            startParadeParticipation=function(index)
                assert(index>=1 and index<=8)
                local old=f.G.CivilianUnitInternalLogicActive[id]
                if options.rejectPerson or old and old.state=='started' then return false end
                f.G.CivilianUnitInternalLogicActive[id]={state='started',behaviour='parade'}
                f.poses[id]=true; return true
            end,
            stopParadeParticipation=function()
                local old=f.G.CivilianUnitInternalLogicActive[id]
                if old and old.behaviour=='parade' then old.state='ended' end
                f.poses[id]=nil; return true
            end,
        }
    end
    f.G.CivilianTraffic={
        GetRoutes=function() return graph end,
        Spawn=function() error('parade used the ordinary culture spawn boundary') end,
        SpawnParade=function(def,x,z,startID,goalID)
            if options.rejectSpawn then return nil end
            f.nextID=f.nextID+1; local id=f:add(f.nextID,def,x,z)
            f.G.CivilianTable[id]={defID=def,startID=startID,goalID=goalID}
            f.G.UnitArrivedAtTarget[id]=true
            return id
        end,
        Load=function(id,name)
            assert(name==catalog.unitName)
            if options.rejectPayload then return nil end
            f.nextID=f.nextID+1; local payload=f:add(f.nextID,4,f.units[id].x,f.units[id].z)
            f.units[payload].parent=id; return payload
        end,
        BeginTravel=function(id)
            if options.rejectTrip then return false end
            f.trips[#f.trips+1]=id; return true
        end,
    }
    f.G.CivilianLife={
        CanSocialize=function(_,id) return not (f.G.CivilianUnitInternalLogicActive[id] or {}).state end,
        IsProtected=function(_,id) return (options.protected or {})[id] end,
    }
    f.G.CityAreaState={IsDangerous=function(_,x,z) return options.danger==true end}
    local routeBuilder={
        Begin=function(_,day,def)
            f.starts=f.starts+1
            if options.noRoute then return nil end
            return {nodes={100,101,102,103},points={{x=650,y=0,z=500},{x=850,y=0,z=500},
                {x=2000,y=0,z=500},{x=2000,y=0,z=2000},{x=500,y=0,z=2000},{x=650,y=0,z=500}}}
        end,
        Poll=function()
            f.polls=f.polls+1
            if options.invalidRoute then return 'invalid' end
            return f.polls<=(options.pendingPolls or 0) and 'pending' or 'ready'
        end,
    }
    f.context={Spring=S,GG=f.G,Game={mapSizeX=4096,mapSizeZ=4096},UnitDefs=defs,UnitDefNames=names,
        config=config,catalog=catalog,gameConfig={game={states={normal='normal'},dayLengthFrames=28800},
            civilians={activityStates={started='started',ended='ended'}}},
        walkerTypes={[5]=true},truckTypes={[1]=true,[2]=true,[3]=true},buildingTypes={[6]=true},
        commercialHologramTypes={[9]=true,[11]=true,[12]=true},
        clearance=options.clearance,routeBuilder=routeBuilder,setSpeed=function(id,value) f.speeds[id]=value end}
    f.d=controller.New(f.context)
    function f:step(frame,progress)
        self.frame=frame
        if progress then for id in pairs(self.d.vehicles) do self.units[id].x=self.units[id].x+progress end end
        self.d:Frame(frame)
    end
    function f:assemble(day,previewStart)
        local begin=previewStart or when(day or 7,19)
        if previewStart then self.frame=begin; assert(self.d:RequestPreview(begin)) end
        self:step(begin); self:step(begin+15)
        assert(self.d.phase=='assembling' and count(self.d.vehicles)==1)
        for i=1,3 do self:step(begin+15+i*config.spawnIntervalFrames,170) end
        assert(count(self.d.vehicles)==4,'four floats did not assemble')
        return begin
    end
    function f:tour()
        self:assemble(7); self:step(when(7,20),5)
        assert(self.d.phase=='touring' and self.rules.city_parade_active==1)
    end
    return f
end

check('noon-offset calendar, seventh evenings, midnight and 03:00 finish',function()
    local d,h=controller.Clock(0,28800); assert(d==1 and h==12)
    for _,day in ipairs({7,14,21}) do
        d,h=controller.Clock(when(day,19),28800); assert(d==day and h==19)
        assert(controller.EndFrame(day,28800,3)==when(day+1,3))
    end
    local f=fixture(); f:step(when(6,19)); assert(f.starts==0)
    f:tour(); assert(f.rules.city_parade_last_day==7)
    for id in pairs(f.d.vehicles) do assert(f.speeds[id]==0.22) end
    f:step(when(8,0),5); assert(f.d.phase=='touring','parade ended at midnight')
    f:step(when(8,3)); assert(f.d.phase=='idle' and f.rules.city_parade_active==0)
    assert(count(f.d.retired)==4,'floats disappeared instead of returning to traffic')
    for id in pairs(f.d.retired) do assert(f.speeds[id]==1 and f.unitRules[id].city_parade_retiring==1) end
    f:step(when(8,19)); assert(f.starts==1,'a missed night caught up on another day')
end)

check('emergency evenings skip assembly; normal times do not replay a skipped night',function()
    local f=fixture(); f.G.GlobalGameState='anarchy'; f:step(when(7,19))
    assert(f.starts==0 and f.rules.city_parade_last_day==7)
    f.G.GlobalGameState='normal'; f:step(when(7,19)+90)
    assert(f.d.phase=='idle' and f.starts==0)
    f:assemble(14); assert(f.rules.city_parade_last_day==14)
end)

check('native routes must finish validation before the first float',function()
    local f=fixture({pendingPolls=2}); local t=when(7,19)
    f:step(t); f:step(t+15); f:step(t+30)
    assert(count(f.d.vehicles)==0 and f.rules.city_parade_last_day==nil)
    f:step(t+45); assert(count(f.d.vehicles)==1 and f.rules.city_parade_last_day==7)
    local bad=fixture({invalidRoute=true}); bad:step(t); bad:step(t+15)
    assert(count(bad.d.vehicles)==0 and bad.d.phase=='idle')
    bad:step(when(7,20)); assert(bad.d.phase=='idle')
end)

check('failed payload, variant and ordinary-trip setup clean up assembly',function()
    for _,key in ipairs({'rejectPayload','rejectVariant','rejectTrip'}) do
        local f=fixture({[key]=true}); local t=when(7,19)
        f:step(t); f:step(t+15)
        assert(count(f.d.vehicles)==0 and count(f.destroyed)>0,key..' leaked a float')
        f:step(when(7,20)); assert(f.d.phase=='idle' and f.rules.city_parade_last_stop=='assembly incomplete')
    end
end)

check('commercial holos respect the assembly radius without hiding parade scenery or other units',function()
    local f=fixture({config={commercialHologramRadius=180}})
    f:add(200,9,650,680); f:add(201,9,650,681)
    f:add(202,10,650,500); f:add(203,7,650,500); f:add(204,9,660,500,1)
    f:add(205,11,650,500); f:add(206,12,650,500)
    local t=when(7,19)
    f:step(t)
    assert(not f.unitRules[200].city_parade_hide_commercial,'route preparation hid ads before any floats existed')
    f:step(t+15)
    assert(f.d.phase=='assembling' and f.unitRules[200].city_parade_hide_commercial==1,
        'an ad on the configured radius boundary stayed visible during assembly')
    assert(f.unitRules[204].city_parade_hide_commercial==1,'nearby ads were filtered by team')
    assert(f.nativeHidden[205]==true and f.nativeHidden[206]==true,
        'native animated ads did not receive their hide callbacks')
    for _,id in ipairs({201,202,203}) do
        assert(not f.unitRules[id].city_parade_hide_commercial,'a distant ad, parade projection or ordinary unit was hidden')
    end
    f.d:Stop('assembly cancelled')
    assert(f.unitRules[200].city_parade_hide_commercial==0 and f.unitRules[204].city_parade_hide_commercial==0)
    assert(f.nativeHidden[205]==false and f.nativeHidden[206]==false)
end)

check('endpoint scans keep ads hidden through gaps and stops until the tail passes',function()
    local f=fixture({config={commercialHologramRadius=100,stalledFrames=100000}}); f:tour()
    local radius=f.config.commercialHologramRadius
    local front,back=f.units[f.d.startFloat],f.units[f.d.endFloat]
    local middle
    for id in pairs(f.d.vehicles) do
        if id~=f.d.startFloat and id~=f.d.endFloat then middle=f.units[id]; break end
    end
    assert(front.x-middle.x>radius and middle.x-back.x>radius)
    local x,z=front.x,front.z
    f:add(200,9,x,z); f:add(201,9,middle.x,middle.z)
    f:add(205,11,x,z); f:add(206,12,x,z)
    f.cylinderQueries={}; f:step(f.frame+15)
    local scans={}
    for _,query in ipairs(f.cylinderQueries) do
        if query.radius==radius then scans[#scans+1]=query end
    end
    assert(#scans==2 and scans[1].x~=scans[2].x,'commercial searches must visit exactly two distinct endpoints')
    for _,query in ipairs(scans) do
        assert(query.z==z and (query.x==front.x or query.x==back.x),'a middle float searched for ads')
    end
    assert(f.unitRules[200].city_parade_hide_commercial==1)
    assert(f.nativeHidden[205]==true and f.nativeHidden[206]==true and #f.nativeHiddenCalls==2)
    assert(not f.unitRules[201].city_parade_hide_commercial,'an ad near only a middle float was hidden')

    f:step(f.frame+15,200)
    assert(front.x-x>radius and x-back.x>radius,'both endpoints must be outside the ad radius')
    assert(f.unitRules[200].city_parade_hide_commercial==1,'ads returned in the gap before the tail arrived')
    -- This pause exceeds the roughly 1,614-frame nominal timer for this formation.
    f:step(f.frame+3000)
    assert(f.d.phase=='touring' and f.unitRules[200].city_parade_hide_commercial==1,
        'a stopped tail consumed the ad timer')
    assert(f.nativeHidden[205]==true and f.nativeHidden[206]==true and #f.nativeHiddenCalls==2,
        'native ads toggled during the gap or stop')

    f:step(f.frame+15,x-back.x)
    assert(f.unitRules[200].city_parade_hide_commercial==1 and #f.nativeHiddenCalls==2,
        'tail arrival interrupted suppression')
    f:step(f.frame+1,radius+1)
    assert(f.unitRules[200].city_parade_hide_commercial==1,'suppression changed outside its 15-frame tick')
    f:step(f.frame+14)
    assert(f.d.phase=='touring' and back.x-x>radius)
    assert(f.unitRules[200].city_parade_hide_commercial==0,'observed tail exit did not restore the ad')
    assert(f.nativeHidden[205]==false and f.nativeHidden[206]==false and #f.nativeHiddenCalls==4,
        'native ads were not restored once after the tail passed')

    for _,id in ipairs({200,205,206}) do f.units[id].x=back.x end
    f:add(202,9,back.x+10,back.z+20)
    f:step(f.frame+15)
    assert(f.unitRules[200].city_parade_hide_commercial==1,'an ad returning to parade range was not hidden again')
    assert(f.nativeHidden[205]==true and f.nativeHidden[206]==true and #f.nativeHiddenCalls==6)
    assert(f.unitRules[202].city_parade_hide_commercial==1,'an ad first encountered by the tail stayed visible')
end)

check('ad timers expire by travelled parade length without continually rearming near the start',function()
    local f=fixture({config={commercialHologramRadius=100}}); f:tour()
    local front,back=f.units[f.d.startFloat],f.units[f.d.endFloat]
    local radius=f.config.commercialHologramRadius
    local travelBudget=front.x-back.x+2*radius
    f:add(200,9,front.x,front.z); f:add(205,11,front.x,front.z)
    f:step(f.frame+15)
    assert(f.unitRules[200].city_parade_hide_commercial==1 and f.nativeHidden[205]==true)
    f:step(f.frame+15,radius)
    assert(f.unitRules[200].city_parade_hide_commercial==1 and #f.nativeHiddenCalls==1)
    for _,id in ipairs({200,205}) do f.units[id].x=3000; f.units[id].z=3000 end
    f:step(f.frame+15,travelBudget-radius-1)
    assert(f.unitRules[200].city_parade_hide_commercial==1 and f.nativeHidden[205]==true,
        'a moving ad was restored before its passage timer expired')
    f:step(f.frame+15,2)
    assert(f.d.phase=='touring' and f.unitRules[200].city_parade_hide_commercial==0,
        'the timer failed to expire without an observed tail visit')
    assert(f.nativeHidden[205]==false and #f.nativeHiddenCalls==2,
        'fallback expiry did not restore the native ad exactly once')
end)

check('ending, cancellation and reload restore ads while preserving unrelated visibility flags',function()
    local endings={
        {'late night',function(f) f:step(when(8,3)) end},
        {'city emergency',function(f) f.G.GlobalGameState='anarchy'; f:step(f.frame+15) end},
        {'attack',function(f) f.d:UnitDamaged(next(f.d.vehicles),1) end},
        {'manual stop',function(f) f.d:Stop('manual preview stop') end},
        {'shutdown',function(f) f.d:Shutdown() end},
        {'reload',function(f) f.d=controller.New(f.context); f.d:Recover() end},
    }
    for _,ending in ipairs(endings) do
        local f=fixture(); f:add(200,9,650,500)
        f:add(205,11,650,500); f:add(206,12,650,500)
        f.unitRules[200].unrelated_hidden=1
        f:tour(); assert(f.unitRules[200].city_parade_hide_commercial==1)
        assert(f.nativeHidden[205]==true and f.nativeHidden[206]==true)
        ending[2](f)
        assert(f.d.phase=='idle' and f.unitRules[200].city_parade_hide_commercial==0,
            ending[1]..' left an ad suppressed')
        assert(f.unitRules[200].unrelated_hidden==1,ending[1]..' cleared another visibility owner')
        assert(f.nativeHidden[205]==false and f.nativeHidden[206]==false,
            ending[1]..' did not restore native ads through their callbacks')
    end
end)

check('destroyed ad IDs can be reused without carrying suppression ownership',function()
    local f=fixture(); f:tour()
    local u=f.units[next(f.d.vehicles)]
    f:add(200,9,u.x,u.z); f:step(f.frame+15)
    assert(f.unitRules[200].city_parade_hide_commercial==1)
    f.units[200].dead=true; f.d:UnitDestroyed(200)
    f:add(200,9,u.x,u.z); f:step(f.frame+15)
    assert(f.unitRules[200].city_parade_hide_commercial==1,'replacement ad could not be hidden again')
    f.units[200].dead=true; f.d:UnitDestroyed(200)
    f:add(200,7,u.x,u.z); f.d:Stop('manual preview stop')
    assert(f.unitRules[200].city_parade_hide_commercial==nil,'cleanup tagged an unrelated replacement unit')
end)

check('spectators and followers perform poses; damaged, disguised and protected people stay out',function()
    local f=fixture({protected={[31]=true}}); f:tour()
    local truck=next(f.d.vehicles); local u=f.units[truck]
    for id=10,33 do
        f:add(id,5,u.x+40+(id%3)*10,u.z+140)
        f.G.CivilianTable[id]={defID=5,startID=100,goalID=101}
    end
    f.units[30].hp=40; f.G.DisguiseCivilianFor[32]=true; f.G.AerosolAffectedCivilians[33]=true
    f:step(f.frame+60,5)
    local watchers,followers=0,0
    for id,p in pairs(f.d.participants) do
        assert(f.poses[id] and id<30 and f.unitRules[id].city_parade_role==(p.following and 2 or 1))
        if p.following then followers=followers+1 else watchers=watchers+1 end
    end
    assert(watchers>0 and followers>0,'audience did not contain both roles')
    local id,p=next(f.d.participants)
    f.G.CivilianUnitInternalLogicActive[id]={state='started',behaviour='aerosol'}
    f:step(f.frame+15,5)
    assert(not f.d.participants[id] and f.G.CivilianUnitInternalLogicActive[id].behaviour=='aerosol')
    local remaining=next(f.d.participants)
    assert(remaining); f.d:UnitDamaged(remaining,1)
    assert(f.d.phase=='idle' and count(f.d.participants)==0)
end)

check('a removed float releases its own spectators even when the truck remains alive',function()
    local f=fixture(); f:tour()
    local first=next(f.d.vehicles); local u=f.units[first]
    for id=10,25 do f:add(id,5,u.x+40,u.z+120); f.G.CivilianTable[id]={defID=5,startID=100} end
    f:step(f.frame+60,5)
    local person,target
    for id,p in pairs(f.d.participants) do if not p.following then person,target=id,p.truck; break end end
    assert(person)
    f.units[f.d.vehicles[target].payload].parent=nil
    f:step(f.frame+15,5)
    assert(f.d.phase=='touring' and f.d.retired[target] and not f.units[target].dead)
    assert(not f.d.participants[person],'spectator kept praying beside a retired float')
end)

check('roof showers use building height, bounded bursts, cooldown and all four effects',function()
    local f=fixture(); f:tour()
    local names={}
    for i=1,16 do
        f:step(f.frame+60,2)
        for _,effect in ipairs(f.effects) do
            assert(effect.y==(effect.name=='parade_petals' and 320 or 170) and effect.dy<0,'incorrect paper release height')
            names[effect.name]=true
        end
        assert(#f.effects<=(i+1)*f.config.maxBuildingBursts,'unbounded rooftop emission')
    end
    assert(count(names)==4,'not all requested CEG families were emitted')
    local before=#f.effects; f.G.GlobalGameState='anarchy'; f:step(f.frame+15)
    assert(f.d.phase=='idle' and #f.effects==before and f.rules.city_parade_active==0)
end)

check('petal bursts sample changing map wind without changing their downward launch',function()
    local f=fixture({config={effects={'parade_petals'},maxBuildingBursts=1,
        buildingCooldownFrames=0}})
    f:tour()
    local first=f.effects[#f.effects]
    assert(first.y==320, "petals must start well above the 200-unit building")
    assert(first and first.dx>0 and first.dz<0 and first.dy<0)
    assert(math.abs(first.dx/first.dz-f.wind[1]/f.wind[3])<1e-9,
        'petals did not use the map wind vector')
    f.wind={6,0,-8}; f:step(f.frame+60,2)
    local stronger=f.effects[#f.effects]
    assert(math.abs(stronger.dx-first.dx*2)<1e-9 and math.abs(stronger.dz-first.dz*2)<1e-9,
        'wind strength did not affect petal drift')
    f.wind={-6,0,8}; f:step(f.frame+60,2)
    local reversed=f.effects[#f.effects]
    assert(reversed.dx==-stronger.dx and reversed.dz==-stronger.dz and reversed.dy==first.dy,
        'new petal bursts ignored the changed wind')
    f.wind={0,0,0}; f:step(f.frame+60,2)
    local calm=f.effects[#f.effects]
    assert(calm.dx==0 and calm.dz==0 and calm.dy<0,'calm petals lost gravity')
    assert(f.windReads==#f.effects,'wind was not sampled once per petal burst')

    local petals=dofile('gamedata/explosions/parade.lua').parade_petals.petals.properties
    assert(petals.emitvector=='0, -1, 0' and petals.gravity=='dir')
    assert(petals.emitrot>=0 and petals.emitrot+petals.emitrotspread<90,
        'a petal launch can point upward')
    assert(petals.numparticles==12 and petals.texture=='parade_petal')
    -- CSimpleParticleSystem updates position, then gravity, then drag. Even
    -- the slowest downward launch must reach a 170-unit roof's ground before
    -- the shortest particle life; this is arrival, not terrain collision.
    local y=first.y+5
    local vy=-math.cos(math.rad(petals.emitrot+petals.emitrotspread))*petals.particlespeed
    for frame=1,petals.particlelife do
        y=y+vy
        vy=(vy+first.dy)*petals.airdrag
        assert(vy<0,'petal gravity or drag reversed its descent')
    end
    assert(y<=0,'petal expired above the ground')
end)

check('banknotes fall vertically while confetti and origami keep their toss variation',function()
    local f=fixture({config={effects={'parade_inflationmoney'}}}); f:tour()
    assert(#f.effects>0 and f.windReads==0)
    for _,effect in ipairs(f.effects) do
        assert(effect.dx==0 and effect.dy<0 and effect.dz==0,
            'banknote burst received sideways or upward travel')
    end
    local effects=dofile('gamedata/explosions/parade.lua')
    local notes=effects.parade_inflationmoney.notes.properties
    assert(notes.emitvector=='0, -1, 0' and notes.emitrot==0 and notes.emitrotspread==0)
    assert(notes.gravity=='0, -0.05, 0' and notes.particlespeed>0 and notes.particlespeedspread>=0)
    assert(notes.numparticles==8 and notes.texture=='parade_banknote')
    for _,name in ipairs({'parade_confetti','parade_origami'}) do
        for _,part in pairs(effects[name]) do
            local p=part.properties
            assert(p.emitvector=='dir' and p.emitrot==15 and p.emitrotspread==30)
            assert(p.gravity=='0, -0.05, 0' and p.particlespeed==1.6 and p.particlespeedspread==1.2)
        end
    end
end)

check('normal retirement despawns attached floats, while captured carriers survive',function()
    local f=fixture(); f:tour(); f.d:Stop('test stop')
    local id,record=next(f.d.retired); local payload=record.payload
    f.G.GlobalGameState='anarchy'; assert(not f.d:OnArrived(id) and not f.destroyed[id])
    f.G.GlobalGameState='normal'; f.G.CivilianUnitInternalLogicActive[id]={state='started',behaviour='flee'}
    assert(not f.d:OnArrived(id)); f.G.CivilianUnitInternalLogicActive[id]=nil
    assert(f.d:OnArrived(id) and f.destroyed[id] and f.destroyed[payload])
    id,record=next(f.d.retired); payload=record.payload
    f.units[id].team=1; local orders=#f.orders
    assert(not f.d:OnArrived(id)); assert(not f.destroyed[id] and not f.destroyed[payload])
    assert(not f.G.CivilianTable[id] and #f.orders==orders and f.unitRules[id].city_parade_retiring==0)
end)

check('capturing endpoint floats releases ownership and republishes roles without spectators',function()
    local f=fixture({config={maxParticipants=0}}); f:tour()
    for _,role in ipairs({'endFloat','startFloat'}) do
        local id=f.d[role]; f.units[id].team=2
        f:step(f.frame+15,5)
        assert(not f.d:OwnsUnit(id) and not f.d.retired[id] and f.speeds[id]==1)
        assert(not f.G.CivilianTable[id] and not f.destroyed[id])
        assert(f.d.phase=='touring' and f.d[role]~=id)
        assert(f.rules.city_parade_start_float==f.d.startFloat and f.rules.city_parade_end_float==f.d.endFloat
            and f.rules.city_parade_vehicle_count==count(f.d.vehicles),'published endpoints retained a captured float')
    end
end)

check('reload finds tagged floats and resumes traffic when its registration was lost',function()
    local f=fixture(); f:tour(); local id=next(f.d.vehicles); local payload=f.d.vehicles[id].payload
    f.G.CivilianTable[id]=nil
    f.d=controller.New(f.context); f.d:Recover()
    assert(f.d.phase=='idle' and f.d.retired[id].payload==payload and f.speeds[id]==1)
    assert(f.unitRules[id].city_parade_vehicle==0 and f.unitRules[id].city_parade_retiring==1)
    local trips=#f.trips; f:step(f.frame+15)
    assert(f.G.CivilianTable[id] and #f.trips==trips+1,'recovered float did not regain its ordinary trip')
    local second=controller.New(f.context); second:Recover()
    assert(second.retired[id] and second.retired==f.G.CityParadeRetired)
end)

check('preview validates routes, assembles for 45 seconds, tours for 3 minutes and preserves calendar',function()
    local f=fixture(); local begin=f:assemble(1,150)
    local tour=begin+15+45*30; f:step(tour,5)
    assert(f.d.phase=='touring' and f.rules.city_parade_last_day==nil)
    assert(not f.d:RequestPreview(f.frame),'overlapping preview accepted')
    f:step(tour+3*60*30)
    assert(f.d.phase=='idle' and f.rules.city_parade_last_day==nil)
    local bad=fixture({noRoute=true}); bad.frame=150
    assert(bad.d:RequestPreview(150)); bad:step(150); bad:step(150+60*30)
    assert(bad.rules.city_parade_last_stop=='preview route unavailable' and count(bad.d.vehicles)==0)
    bad.G.GlobalGameState='anarchy'; assert(not bad.d:RequestPreview(bad.frame))
end)

check('blocked procession stops without deleting its trucks in place',function()
    local f=fixture(); f:tour(); f:step(f.frame+f.config.stalledFrames+15)
    assert(f.d.phase=='idle' and f.rules.city_parade_last_stop=='route blocked')
    assert(count(f.d.retired)==4 and count(f.destroyed)==0)
end)

check('preview reports preparation, exact spawn location and distinct failure reasons',function()
    local f=fixture(); f.frame=150; assert(f.d:RequestPreview(150))
    local phase,reason=f.d:GetStatus()
    assert(phase=='preparing' and reason=='searching for a safe route')
    f:step(150); f:step(165)
    local messages=table.concat(f.messages,'\n')
    assert(messages:find('assembly starts at x=650.0 y=0.0 z=500.0',1,true))
    assert(messages:find('spawned truck=1001 payload=1002 variant=',1,true))
    assert(messages:find('at x=650.0 y=0.0 z=500.0 (frame 165)',1,true))
    for option,expected in pairs({rejectSpawn='carrier creation failed',rejectPayload='payload creation failed',
        rejectVariant='payload rejected float variant',rejectTrip='civilian travel registration failed'}) do
        local bad=fixture({[option]=true});bad.frame=150;assert(bad.d:RequestPreview(150))
        bad:step(150);bad:step(165)
        assert(bad.d.waitingReason:find(expected,1,true))
        local before=#bad.messages;bad:step(180)
        assert(#bad.messages==before,'repeated failure spammed the log')
        bad:step(165+bad.config.previewAssemblyFrames)
        local status,wait,stopped=bad.d:GetStatus()
        assert(status=='idle' and wait==nil and stopped=='assembly incomplete')
        assert(bad.messages[#bad.messages]:find(expected,1,true),'stop omitted last spawn blocker')
    end
end)

check('minor area damage permits spawning and touring; heavy damage still disperses',function()
    local f=fixture({config={combatHeatThreshold=450}})
    local area=dofile('luarules/gadgets/include/city_area_state.lua')(
        dofile('luarules/configs/city_area.lua'),4096,4096,function()return f.frame end)
    f.G.CityAreaState=area
    f.frame=when(7,19)
    area:ReportIncident(1000,1000,350,4000)
    f:assemble(7)
    f.frame=when(7,20)
    area:ReportIncident(1000,1000,350,4000)
    f:step(f.frame,5)
    assert(f.d.phase=='touring','minor damage cancelled the parade')
    area:ReportIncident(1000,1000,200,4000)
    f:step(f.frame+15,5)
    assert(f.d.phase=='idle' and f.rules.city_parade_last_stop=='danger')
end)

local function convoyIDs(f)
    local ids={};for id in pairs(f.d.vehicles)do ids[#ids+1]=id end;table.sort(ids);return ids
end
check('convoy slows before stopping and measures separation around a bend',function()
    local f=fixture();f:tour();local ids=convoyIDs(f)
    for i,id in ipairs(ids)do
        f.units[id].x,f.units[id].z=1770-i*170,500
        f.d.vehicles[id].goal=3
    end
    f.units[ids[2]].x=1470
    f:step(f.frame+15)
    assert(not f.d.vehicles[ids[2]].held and f.speeds[ids[2]]<f.config.speedFactor,'follower did not brake gradually')
    f.units[ids[2]].x=1510;f:step(f.frame+15)
    assert(f.d.vehicles[ids[2]].held,'follower closed below minimum spacing')
    f.units[ids[1]].x,f.units[ids[1]].z=2000,600;f.d.vehicles[ids[1]].goal=4
    for i=2,#ids do
        f.units[ids[i]].x,f.units[ids[i]].z=1930-(i-2)*170,500
        f.d.vehicles[ids[i]].goal=3
    end
    f:step(f.frame+15)
    assert(not f.d.vehicles[ids[2]].held and f.speeds[ids[2]]==f.config.speedFactor,'bend caused unnecessary bunching')
end)
check('lap closure retains convoy order and spacing',function()
    local f=fixture();f:tour();local ids=convoyIDs(f)
    f.units[ids[1]].x,f.units[ids[1]].z=700,500
    f.d.vehicles[ids[1]].goal,f.d.vehicles[ids[1]].lap=2,1
    for i=2,#ids do
        local z=640+(i-2)*170
        f.units[ids[i]].x,f.units[ids[i]].z=650-(z-500)*.1,z
        f.d.vehicles[ids[i]].goal,f.d.vehicles[ids[i]].lap=6,0
    end
    f:step(f.frame+15)
    assert(not f.d.vehicles[ids[1]].held and not f.d.vehicles[ids[2]].held,'lap seam broke route distance')
end)
check('waypoint advancement cannot cut a house corner and a new obstruction stops the truck',function()
    local obstructed=false
    local clearance={Refresh=function()end,SegmentClear=function(_,a,b)
        return not obstructed and not (a.x<849 and b.x==2000 and b.z==500)
    end}
    local f=fixture({clearance=clearance});f.frame=150;assert(f.d:RequestPreview(150));f:step(150);f:step(165)
    local id=next(f.d.vehicles)
    f.units[id].x=820;f:step(180);assert(f.d.vehicles[id].goal==2,'truck skipped a building corner')
    f.units[id].x=850;f:step(195);assert(f.d.vehicles[id].goal==3)
    obstructed=true;f:step(210)
    assert(f.d.vehicles[id].held and f.orders[#f.orders].cmd==CMD.STOP,'truck drove toward a new house obstruction')
end)
