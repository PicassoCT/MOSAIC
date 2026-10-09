function gadget:GetInfo()
    return {name="Civilian cover orders",desc="Contextual civilian movement for disguised operatives",
        author="MOSAIC contributors",license="GPL3",layer=2,enabled=true}
end
if not gadgetHandler:IsSyncedCode() then return false end
VFS.Include("luarules/configs/commandsIDs.lua")
local BLEND=CMD_CIVILIAN_BLEND
local eligible, orders={},{}
for _,name in ipairs({"operativeinvestigator","operativepropagator","operativeasset","civilianagent"}) do
    if UnitDefNames[name] then eligible[UnitDefNames[name].id]=true end
end
local descriptor={id=BLEND,type=CMDTYPE.ICON_UNIT_OR_MAP,name="Blend in",action="blendin",cursor="Guard",
    tooltip="While disguised: click a civilian to accompany them, or a building/ground spot to visit and wait. New orders cancel."}
local function register(id,def)
    if eligible[def] and not Spring.FindUnitCmdDesc(id,BLEND) then Spring.InsertUnitCmdDesc(id,descriptor) end
end
function gadget:Initialize()
    gadgetHandler:RegisterCMDID(BLEND)
    local units=Spring.GetAllUnits(); table.sort(units)
    for _,id in ipairs(units) do register(id,Spring.GetUnitDefID(id)) end
end
function gadget:UnitCreated(id,def) register(id,def) end
function gadget:UnitDestroyed(id) orders[id]=nil end
function gadget:AllowCommand(id,def,team,cmd,params)
    if cmd~=BLEND then return true end
    return eligible[def] and (#params==1 or #params==3)
end
function gadget:CommandFallback(id,def,team,cmd,params,options,tag)
    if cmd~=BLEND then return false end
    if not GG.CivilianLife or not Spring.GetUnitIsCloaked(id) then orders[id]=nil; return true,true end
    local frame=Spring.GetGameFrame()
    local state=orders[id]
    if not state or state.tag~=tag then state={tag=tag,nextFrame=0}; orders[id]=state end
    if frame<state.nextFrame then return true,false end
    state.nextFrame=frame+15
    local x,y,z
    if #params==1 then
        local target=params[1]
        if not Spring.ValidUnitID(target) or Spring.GetUnitIsDead(target) or target==id then return true,true end
        x,y,z=GG.CivilianLife:CoverPoint(id,target)
    else x,y,z=params[1],params[2],params[3] end
    if not x or x~=x or not z or z~=z or x<0 or z<0 or x>Game.mapSizeX or z>Game.mapSizeZ then return true,true end
    Spring.SetUnitMoveGoal(id,x,Spring.GetGroundHeight(x,z),z,65)
    return true,false
end
