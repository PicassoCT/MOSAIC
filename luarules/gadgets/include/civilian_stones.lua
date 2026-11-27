-- Native cannon gravity/bounce/collisions, with one terminal ground feature.
-- Explosion is only a visual veto; impactOnly supplies exactly one direct hit.
local M={}
function M.New(S,Game,weapons)
    local api={flying={},pending={},debris={}}
    local cap,lifetime=96,4*60*30
    local gravity=math.abs(Game.gravity or 120)/(Game.gameSpeed or 30)^2
    local function keys(t) local out={};for k in pairs(t) do out[#out+1]=k end;table.sort(out);return out end
    local function groundFeature(p,frame)
        local y=S.GetGroundHeight(p.x,p.z)
        if y<0 or math.abs(p.y-y)>3 or p.x<0 or p.z<0 or p.x>Game.mapSizeX or p.z>Game.mapSizeZ then return end
        local id=S.CreateFeature("civilianstone"..p.variant,p.x,y,p.z,0,S.GetGaiaTeamID())
        if id then
            S.SetFeatureBlocking(id,false)
            S.SetFeatureRulesParam(id,"civilian_stone_expires",frame+lifetime)
            api.debris[#api.debris+1]={id=id,expires=frame+lifetime}
        end
    end
    function api:Throw(owner,target,variant,range)
        local def=weapons[variant]
        local pieces=S.GetUnitPieceMap(owner)
        local hand=pieces and pieces["stone"..variant]
        if not def or not hand then return false end
        local x,y,z=S.GetUnitPiecePosDir(owner,hand)
        local tx,ty,tz=S.GetUnitPosition(target)
        if not x or not tx then return false end
        -- Aim near the facing wall, rather than through the building centre.
        local dx,dz=tx-x,tz-z
        local d=math.sqrt(dx*dx+dz*dz)
        local radius=math.min(d-1,(S.GetUnitRadius(target) or 0)*.7)
        tx,tz=tx-dx/math.max(d,1)*radius,tz-dz/math.max(d,1)*radius
        d=math.sqrt((tx-x)^2+(tz-z)^2)
        if d<range.minRange or d>range.range then return false end
        tx,tz=tx+math.random(-20,20),tz+math.random(-20,20)
        ty=S.GetGroundHeight(tx,tz)+5
        local time=math.max(24,math.min(55,d/4))
        local id=S.SpawnProjectile(def,{pos={x,y,z},speed={(tx-x)/time,
            (ty-y)/time+gravity*(time+1)*.5,(tz-z)/time},gravity=-gravity,
            owner=owner,team=S.GetUnitTeam(owner),ttl=180})
        if id then self.flying[id]={variant=variant,expires=S.GetGameFrame()+180};return true end
        return false
    end
    function api:Explosion(id,x,y,z)
        local p=self.flying[id]
        if p then
            self.pending[id]={variant=p.variant,x=x,y=y,z=z,frame=S.GetGameFrame(),
                expired=S.GetGameFrame()>=p.expires-1,hit=p.hit}
        end
        return true -- suppress CEG; engine still applies impactOnly damage
    end
    function api:Hit(id)
        if self.flying[id] then self.flying[id].hit=true end
        if self.pending[id] then self.pending[id].hit=true end
    end
    function api:Destroyed(id) self.flying[id]=nil end
    function api:Frame(frame)
        for _,id in ipairs(keys(self.flying)) do
            local p=self.flying[id]
            local x,y,z=S.GetProjectilePosition(id)
            local vx,vy,vz=S.GetProjectileVelocity(id)
            if not x then self.flying[id]=nil
            elseif frame>=p.expires then S.DeleteProjectile(id);self.flying[id]=nil
            elseif vx then
                local ground=S.GetGroundHeight(x,z)
                if p.vy and p.vy<0 and vy>0 and y-ground<10 and ground>=0 then
                    S.PlaySoundFile("sounds/physics/civilian_stone.wav",.25,x,y,z)
                end
                -- Delete without Collision, so a nearly stationary stone cannot
                -- explode/hit again. Native three-bounce terminal impacts use
                -- the deferred Explosion path below instead.
                if ground>=0 and y-ground<2 and vx*vx+vy*vy+vz*vz<.06 then
                    self.flying[id]=nil
                    S.DeleteProjectile(id)
                    groundFeature({variant=p.variant,x=x,y=y,z=z},frame)
                else p.vy=vy end
            end
        end
        for _,id in ipairs(keys(self.pending)) do
            local p=self.pending[id]
            -- Damage callins follow Explosion within the collision frame.
            if frame>p.frame then
                if not p.hit and not p.expired then groundFeature(p,frame) end
                self.pending[id]=nil
            end
        end
        while #self.debris>0 do
            local p=self.debris[1]
            if #self.debris<=cap and frame<p.expires and S.ValidFeatureID(p.id) then break end
            table.remove(self.debris,1)
            if S.ValidFeatureID(p.id) then S.DestroyFeature(p.id) end
        end
    end
    function api:Recover()
        for _,id in ipairs(S.GetAllFeatures()) do
            local expires=S.GetFeatureRulesParam(id,"civilian_stone_expires")
            if expires then self.debris[#self.debris+1]={id=id,expires=expires} end
        end
        table.sort(self.debris,function(a,b) return a.expires<b.expires or (a.expires==b.expires and a.id<b.id) end)
        -- Safely retire in-flight stones after a gadget reload; without their
        -- release record we cannot distinguish expiration from ground contact.
        local stoneDefs={};for _,id in pairs(weapons) do stoneDefs[id]=true end
        for _,id in ipairs(S.GetProjectilesInRectangle(0,0,Game.mapSizeX,Game.mapSizeZ,false,false) or {}) do
            if stoneDefs[S.GetProjectileDefID(id)] then S.DeleteProjectile(id) end
        end
        self:Frame(S.GetGameFrame())
    end
    return api
end
return M
