function gadget:GetInfo()
    return {name='Priority SFX events',desc='Bounded visual-only sticky and EMP notifications',
        author='MOSAIC contributors',license='GPL V2',layer=0,enabled=true}
end
if not gadgetHandler:IsSyncedCode() then return false end
-- The existing combat bridge filters positional LOS before forwarding to LuaUI.
-- These negative IDs are private VISUAL messages, never WeaponDefs or damage.
local ids={sticky=-101,emp=-102}
local frame,count=-1,0
local api={}
function api.Burst(kind,x,y,z,owner)
    local id=ids[kind]
    if not id or type(x)~='number' or type(y)~='number' or type(z)~='number'
        or x~=x or y~=y or z~=z or math.abs(x)>1e8 or math.abs(y)>1e8 or math.abs(z)>1e8 then return false end
    local now=Spring.GetGameFrame()
    if now~=frame then frame,count=now,0 end
    if count>=64 then return false end -- bound even a map-wide payload burst
    count=count+1
    SendToUnsynced('explosion_light',x,y,z,id,owner or -1)
    return true
end
function api.Unit(kind,id,offset)
    local x,y,z=Spring.GetUnitPosition(id)
    if x then return api.Burst(kind,x,y+(offset or 0),z,id) end
    return false
end
function gadget:Initialize() GG.PrioritySFX=api end
function gadget:Shutdown() if GG.PrioritySFX==api then GG.PrioritySFX=nil end end
