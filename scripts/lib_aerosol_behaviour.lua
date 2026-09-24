-- Per-victim controller, called by the existing 250 ms unit-script worker.
-- All timers use deadlines: the worker need not land on an exact game frame.
return function(unitID, kind, status)
    local config=GG.GameConfig or getGameConfig()
    local settings=assert(config.Aerosols[kind])
    local fps=Game.gameSpeed or 30
    local born=Spring.GetGameFrame()
    local expires=born+(settings.VictimLiftime or settings.VictimLifetime)*fps/1000
    local radius=settings.searchRadius or 900
    local types=GG.AerosolBehaviourTypes
    if not types then
        types={civilians=getChemTrailInfluencedTypes(UnitDefs),danger={}}
        for id,def in pairs(UnitDefs) do
            local name=def.name or ''
            if not def.canFly and def.weapons and #def.weapons>0 and
                (name:match('^ground_') or name=='policetruck') then types.danger[id]=true end
        end
        GG.AerosolBehaviourTypes=types
    end
    status=status or {}
    status.aerosolType=kind
    local target, nextThink, nextSearch, nextOrder, nextHit=nil,born,born+unitID%fps,0,0
    local progressFrame,progressX,progressZ=born
    local rejected={}
    local lastSpeed,goalX,goalZ
    local function alive(id)
        return id and Spring.ValidUnitID(id) and not Spring.GetUnitIsDead(id)
    end
    local function distance2(x,z,xx,zz)return (x-xx)^2+(z-zz)^2 end
    local function speed(value)
        if value~=lastSpeed then setSpeedIntern(unitID,value);lastSpeed=value end
    end
    local function hiveAvailable(id)
        local team=Spring.GetUnitTeam(id)
        local hive=GG.HiveMind and GG.HiveMind[team] and GG.HiveMind[team][id]
        if not hive then return false end
        local _,_,_,_,build=Spring.GetUnitHealth(id)
        return (not build or build>=1) and (hive.rewindMilliSeconds or 0)<
            config.maxNumberIntegratedIntoHive*config.addSlowMoTimeInMsPerCitizen
    end
    local function eligible(id,mode)
        if id==unitID or not alive(id) or Spring.GetUnitTransporter(id) then return false end
        if mode=='hive' then return hiveAvailable(id) end
        if Spring.GetUnitIsCloaked(id) then return false end
        local def=Spring.GetUnitDefID(id)
        if mode=='danger' then
            local team=Spring.GetUnitTeam(id)
            return types.danger[def] and team and
                not Spring.AreTeamsAllied(Spring.GetUnitTeam(unitID),team)
        end
        local affected=GG.AerosolAffectedCivilians or {}
        return types.civilians[def] and not (GG.DisguiseCivilianFor or {})[id] and
            (mode=='herd' and affected[id]==kind or mode=='prey' and not affected[id])
    end
    local function position(t)
        if t.id then return Spring.GetUnitPosition(t.id) end
        return t.x,t.y,t.z
    end
    local function move(x,y,z,frame)
        if frame>=nextOrder and (not goalX or distance2(x,z,goalX,goalZ)>24^2 or
            not Spring.GetUnitCurrentCommand(unitID)) then
            Command(unitID,'go',{x=x,y=y,z=z}) -- replace; never accumulate shifted orders
            goalX,goalZ=x,z;nextOrder=frame+fps
        end
    end
    local function discard(frame)
        if target then rejected[target.key]=frame+20*fps end
        target=nil;goalX=nil;nextSearch=frame+fps
        progressFrame=frame;progressX=nil
    end
    local function findWater(x,z,frame)
        -- Bounded shoreline search. Only enter shallow, walkable water beside a
        -- deeper body; never force a civilian through a cliff or move-control it.
        local choices={}
        local range=settings.waterSearchRadius or radius
        for ray=0,7 do
            local angle=(ray+unitID%8/8)*math.pi/4
            for _,fraction in ipairs({.125,.25,.5,1}) do
                local wx=math.max(8,math.min(Game.mapSizeX-8,x+math.cos(angle)*range*fraction))
                local wz=math.max(8,math.min(Game.mapSizeZ-8,z+math.sin(angle)*range*fraction))
                if Spring.GetGroundHeight(wx,wz)<-12 then
                    choices[#choices+1]={wx,wz,distance2(x,z,wx,wz)};break
                end
            end
        end
        table.sort(choices,function(a,b)return a[3]<b[3] end)
        for i=1,math.min(4,#choices) do
            local dryX,dryZ,wetX,wetZ=x,z,choices[i][1],choices[i][2]
            for _=1,12 do
                local mx,mz=(dryX+wetX)*.5,(dryZ+wetZ)*.5
                if Spring.GetGroundHeight(mx,mz)<-3 then wetX,wetZ=mx,mz else dryX,dryZ=mx,mz end
            end
            local y=Spring.GetGroundHeight(wetX,wetZ)
            local key='water:'..math.floor(wetX/64)..':'..math.floor(wetZ/64)
            if y>=-5 and y<-1 and (rejected[key] or 0)<=frame and
                Spring.TestMoveOrder(Spring.GetUnitDefID(unitID),wetX,y,wetZ) then
                return {mode='water',x=wetX,y=y,z=wetZ,key=key}
            end
        end
    end
    local function choose(x,z,frame)
        for key,untilFrame in pairs(rejected) do if frame>=untilFrame then rejected[key]=nil end end
        local best,score
        local function consider(id,mode,weight)
            local key='unit:'..id
            if (rejected[key] or 0)>frame or not eligible(id,mode) then return end
            local tx,ty,tz=Spring.GetUnitPosition(id)
            if not tx or ty>Spring.GetGroundHeight(tx,tz)+100 then return end
            local d2=distance2(x,z,tx,tz)
            if d2>radius^2 then return end
            local s=d2*weight
            if not score or s<score or (s==score and id<(best.id or math.huge)) then
                best,score={id=id,mode=mode,key=key},s
            end
        end
        if kind=='depressol' then
            for _,hives in pairs(GG.HiveMind or {}) do
                if type(hives)=='table' then for id,hive in pairs(hives) do
                    if type(id)=='number' and type(hive)=='table' then consider(id,'hive',.5) end
                end end
            end
            for _,id in ipairs(Spring.GetUnitsInCylinder(x,z,radius) or {}) do consider(id,'danger',1.4) end
            local water=findWater(x,z,frame)
            if water and (not score or distance2(x,z,water.x,water.z)<score) then best=water end
        else
            local near=Spring.GetUnitsInCylinder(x,z,radius) or {}
            for _,id in ipairs(near) do consider(id,'prey',1) end
            -- Pursue fresh civilians before joining a loose group of afflicted.
            if not best then for _,id in ipairs(near) do consider(id,'herd',1) end end
        end
        if not best then
            local angle=(unitID*.618+frame/(8*fps))*2.399963
            local wx=math.max(8,math.min(Game.mapSizeX-8,x+math.cos(angle)*240))
            local wz=math.max(8,math.min(Game.mapSizeZ-8,z+math.sin(angle)*240))
            local y=Spring.GetGroundHeight(wx,wz)
            if Spring.TestMoveOrder(Spring.GetUnitDefID(unitID),wx,y,wz) then
                best={mode='wander',x=wx,y=y,z=wz,key='wander',untilFrame=frame+8*fps}
            end
        end
        target=best;goalX=nil;progressX,progressZ=x,z;progressFrame=frame
        nextSearch=frame+(kind=='depressol' and 6 or 3)*fps+unitID%fps
    end
    -- Script attacks retain an attacker ID so military targets can retaliate.
    local function strike(id,frame)
        if frame<nextHit then return end
        nextHit=frame+(kind=='tollwutox' and 1.25 or 2.5)*fps
        status.aerosolAttackUntil=frame+fps
        Spring.SetUnitNeutral(unitID,false)
        Spring.AddUnitDamage(id,settings.meleeDamage or 8,0,unitID,-1)
        if kind=='tollwutox' and alive(id) then spawnCegAtUnit(id,'bloodslay') end
    end
    local initialized=false
    return function()
        local frame=Spring.GetGameFrame()
        if not alive(unitID) or frame>=expires then return 'Exit' end
        if not initialized then
            initialized=true
            GG.AerosolAffectedCivilians=GG.AerosolAffectedCivilians or {}
            GG.AerosolAffectedCivilians[unitID]=kind
            Command(unitID,'stop')
        end
        if Spring.GetUnitTransporter(unitID) then return 'Outbreak' end
        if status.aerosolDrowning then
            if frame>=status.aerosolDrowning then return 'Exit' end
            return 'Outbreak'
        end
        if frame<nextThink then return 'Outbreak' end
        nextThink=frame+math.ceil(fps*.5)+unitID%3
        local x,y,z=Spring.GetUnitPosition(unitID)
        if not x then return 'Exit' end
        if target and ((target.id and not eligible(target.id,target.mode)) or
            (target.untilFrame and frame>=target.untilFrame)) then discard(frame) end
        if not target and frame>=nextSearch then choose(x,z,frame) end
        status.aerosolAgitated=kind=='tollwutox' and target and target.mode=='prey' or false
        speed(status.aerosolAgitated and (settings.lungeSpeed or .85) or (settings.shambleSpeed or .35))
        if not target then return 'Outbreak' end
        local tx,ty,tz=position(target)
        if not tx or distance2(x,z,tx,tz)>(radius*1.5)^2 then discard(frame);return 'Outbreak' end
        local d2=distance2(x,z,tx,tz)
        if target.mode=='water' and d2<20^2 and Spring.GetGroundHeight(x,z)<-1 then
            Command(unitID,'stop');status.aerosolDrowning=frame+3*fps
            return 'Outbreak'
        end
        local reach=target.mode=='danger' and math.min(80,(Spring.GetUnitRadius(target.id) or 20)+16) or 24
        if (kind=='tollwutox' and target.mode=='prey' or target.mode=='danger') and
            d2<reach^2 and math.abs(y-ty)<80 then
            if goalX then Command(unitID,'stop');goalX=nil end
            progressFrame=frame
            strike(target.id,frame)
        elseif target.mode=='hive' and d2<(config.integrationRadius*.8)^2 then
            progressFrame=frame -- wait for the hive's existing integration worker
        elseif target.mode=='herd' and d2<70^2 or kind=='wanderlost' and target.mode=='prey' and d2<28^2 then
            if goalX then Command(unitID,'stop');goalX=nil end
            progressFrame=frame -- existing collateral gadget spreads Wanderlost
        else
            move(tx,ty,tz,frame)
            if distance2(x,z,progressX or x,progressZ or z)>16^2 then
                progressX,progressZ=x,z;progressFrame=frame
            elseif frame-progressFrame>8*fps then discard(frame) end
        end
        return 'Outbreak'
    end
end
