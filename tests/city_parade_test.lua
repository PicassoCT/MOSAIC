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
        unitRules={},poses={},starts=0,polls=0,nextID=1000,config=config,
        wind=options.wind or {3,0,-4},windReads=0}
    local defs,names={},{}
    for i,name in ipairs({'truck_arab6','truck_arab7','truck_arab8','truckpayloadparade',
        'civilian_arab0','house_arab0','operative','house_ruin'}) do
        defs[i]={id=i,name=name,moveDef={id=1},speed=60}; names[name]=defs[i]
    end
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
        routeBuilder=routeBuilder,setSpeed=function(id,value) f.speeds[id]=value end}
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
            assert(effect.y==170 and effect.dy<0,'effect did not originate at the roof')
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

check('capturing an active float releases its speed and civilian ownership',function()
    local f=fixture(); f:tour(); local id=next(f.d.vehicles); f.units[id].team=2
    f:step(f.frame+15,5)
    assert(not f.d:OwnsUnit(id) and not f.d.retired[id] and f.speeds[id]==1)
    assert(not f.G.CivilianTable[id] and not f.destroyed[id])
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
