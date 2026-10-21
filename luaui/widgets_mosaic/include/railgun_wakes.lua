-- A shot leaves an observed world-space path after its projectile disappears.
-- Only the short-lived projectile is sampled; cooling/drift happen in the shader.
local M = {maxShots=16, maxSegmentsPerShot=96, maxSpanLength=96,
    visibilityStep=32, visibilityFrames=3, lifetimeSeconds=15}
local function finite(n)
    return type(n)=='number' and n==n and math.abs(n)<1e9
end
local function finished(value) return value==true or value==1 end

function M.New(api, game, weaponDefs)
    local fps=(game and game.gameSpeed) or 30
    local lifetime=M.lifetimeSeconds*fps
    local profiles={}
    for id,wd in pairs(weaponDefs or {}) do
        local cp=wd.customParams or {}
        if tonumber(cp.railgun_wake)==1 then
            profiles[id]={width=tonumber(cp.railgun_wake_width) or 3.5}
        end
    end
    local self={shots={},order={},evicted=0,trimmed=0,visibleSpans=0}
    local lastFrame=api.GetGameFrame()
    local function key(id,born) return tostring(id)..':'..tostring(born) end
    function self:Clear()
        self.shots,self.order={},{}
        self.visibleSpans=0
    end
    function self:Update()
        local frame=api.GetGameFrame()
        if frame<lastFrame then self:Clear() end -- replay seek / new session
        lastFrame=frame
        for i=#self.order,1,-1 do
            local shot=self.shots[self.order[i]]
            if not shot or frame>=shot.expires then
                self.shots[self.order[i]]=nil
                table.remove(self.order,i)
            end
        end
    end
    local function findOrCreate(id,born,weaponID)
        if not finite(id) or not finite(born) or born<0 or not profiles[weaponID] then return end
        local now=api.GetGameFrame()
        if now>=born+lifetime or born>now then return end
        local k=key(id,born)
        local shot=self.shots[k]
        if shot then return shot end
        self:Update()
        if #self.order>=M.maxShots then
            local oldestIndex,oldest=1,self.shots[self.order[1]]
            for i=2,#self.order do
                local candidate=self.shots[self.order[i]]
                if candidate.born<oldest.born or (candidate.born==oldest.born and candidate.id<oldest.id) then
                    oldestIndex,oldest=i,candidate
                end
            end
            -- A rejected older continuation must not evict a retained shot on
            -- every sample. Keep a stable set even during a large salvo.
            if born<oldest.born or (born==oldest.born and id<oldest.id) then return end
            self.shots[table.remove(self.order,oldestIndex)]=nil
            self.evicted=self.evicted+1
        end
        shot={key=k,id=id,born=born,expires=born+lifetime,weaponID=weaponID,
            seed=(id%65521)*.037+(born%1021)*.17,
            width=profiles[weaponID].width,segments={},distance=0,lastFrame=born}
        self.shots[k]=shot
        self.order[#self.order+1]=k
        return shot
    end
    function self:Point(id,born,weaponID,x,y,z,frame,isFinished)
        if not finite(x) or not finite(y) or not finite(z) or not finite(frame)
            or not finite(born) or frame<born then return end
        local _,full=api.GetSpectatingState()
        local ally=api.GetMyAllyTeamID()
        if not full and not api.IsPosInLos(x,y,z,ally) then
            self:Gap(id,born,frame,isFinished)
            return
        end
        local shot=findOrCreate(id,born,weaponID)
        if not shot or shot.ended or shot.weaponID~=weaponID or frame<shot.lastFrame then return end
        local prior=shot.last
        if prior then
            local dx,dy,dz=x-prior.x,y-prior.y,z-prior.z
            local length=math.sqrt(dx*dx+dy*dy+dz*dz)
            -- Corrupt/teleported points must not create a map-spanning ribbon.
            if length>.01 and length<=M.maxSpanLength*M.maxSegmentsPerShot then
                local count=math.ceil(length/M.maxSpanLength)
                local base=shot.distance
                for i=1,count do
                    local a,b=(i-1)/count,i/count
                    local segment={ax=prior.x+dx*a,ay=prior.y+dy*a,az=prior.z+dz*a,
                        bx=prior.x+dx*b,by=prior.y+dy*b,bz=prior.z+dz*b,
                        bornA=prior.frame+(frame-prior.frame)*a,
                        bornB=prior.frame+(frame-prior.frame)*b,
                        expires=shot.expires,seed=shot.seed,shotKey=shot.key,
                        distance=base+length*a,width=shot.width,
                        fadeA=shot.newRun and 0 or 1,fadeB=1}
                    local observed=true
                    if not full then
                        local checks=math.max(1,math.ceil(length/count/M.visibilityStep))
                        for j=0,checks do
                            local t=a+(b-a)*j/checks
                            if not api.IsPosInLos(prior.x+dx*t,prior.y+dy*t,prior.z+dz*t,ally) then
                                observed=false
                                break
                            end
                        end
                    end
                    if observed then
                        shot.segments[#shot.segments+1]=segment
                        shot.newRun=false
                    else
                        -- Visibility later cannot reconstruct a stretch which
                        -- was never observed when the projectile passed it.
                        if shot.segments[#shot.segments] then shot.segments[#shot.segments].fadeB=0 end
                        shot.newRun=true
                    end
                end
                shot.distance=base+length
                while #shot.segments>M.maxSegmentsPerShot do
                    table.remove(shot.segments,1)
                    self.trimmed=self.trimmed+1
                end
                if shot.segments[1] then shot.segments[1].fadeA=0 end
            elseif length>M.maxSpanLength*M.maxSegmentsPerShot then
                if shot.segments[#shot.segments] then shot.segments[#shot.segments].fadeB=0 end
                shot.newRun=true
            end
        else
            shot.newRun=true
        end
        -- Copy positions; never retain a live unit/projectile attachment.
        shot.last={x=x,y=y,z=z,frame=frame}
        shot.lastFrame=frame
        if finished(isFinished) then
            shot.ended=true
            shot.last=nil
            if shot.segments[#shot.segments] then shot.segments[#shot.segments].fadeB=0 end
        end
    end
    function self:Gap(id,born,frame,isFinished)
        local shot=self.shots[key(id,born)]
        if not shot or not finite(frame) or frame<shot.lastFrame then return end
        shot.last=nil
        shot.lastFrame=frame
        shot.newRun=true
        if shot.segments[#shot.segments] then shot.segments[#shot.segments].fadeB=0 end
        if finished(isFinished) then shot.ended=true end
    end
    function self:Collect(frame)
        self:Update()
        frame=frame or api.GetGameFrame()
        local _,full=api.GetSpectatingState()
        local ally=api.GetMyAllyTeamID()
        local out={}
        for _,k in ipairs(self.order) do
            local shot=self.shots[k]
            for _,s in ipairs(shot.segments) do
                if frame<s.expires then
                    local dx,dy,dz=s.bx-s.ax,s.by-s.ay,s.bz-s.az
                    local length=math.sqrt(dx*dx+dy*dy+dz*dz)
                    local mx,my,mz=(s.ax+s.bx)*.5,(s.ay+s.by)*.5,(s.az+s.bz)*.5
                    -- Cull before LOS work; a hidden/offscreen wake still expires.
                    local inView=not api.IsSphereInView or api.IsSphereInView(mx,my,mz,length*.5+s.width*6+12)
                    if inView then
                        if s.losAlly~=ally or s.losFull~=full or not s.nextLosFrame or frame>=s.nextLosFrame then
                            s.visible=true
                            if not full then
                                local checks=math.max(1,math.ceil(length/M.visibilityStep))
                                for i=0,checks do
                                    local t=i/checks
                                    if not api.IsPosInLos(s.ax+dx*t,s.ay+dy*t,s.az+dz*t,ally) then
                                        s.visible=false
                                        break
                                    end
                                end
                            end
                            s.losAlly,s.losFull=ally,full
                            s.nextLosFrame=(math.floor(frame/M.visibilityFrames)+1)*M.visibilityFrames
                        end
                        if s.visible then out[#out+1]=s end
                    end
                end
            end
        end
        self.visibleSpans=#out
        return out
    end
    function self:GetStats()
        self:Update()
        local count,active=0,0
        for _,k in ipairs(self.order) do
            local shot=self.shots[k]
            count=count+#shot.segments
            if not shot.ended then active=active+1 end
        end
        return {tracked=#self.order,active=active,spans=count,visibleSpans=self.visibleSpans,
            maxShots=M.maxShots,maxSegmentsPerShot=M.maxSegmentsPerShot,lifetimeSeconds=M.lifetimeSeconds,
            evicted=self.evicted,trimmed=self.trimmed}
    end
    return self
end
return M
