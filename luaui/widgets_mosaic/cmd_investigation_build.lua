function widget:GetInfo()
    return {name="Investigation placement", desc="Place the Investigation build item over a suspect",
        author="MOSAIC contributors", license="GPL3", layer=40, enabled=true}
end
VFS.Include("luarules/configs/commandsIDs.lua")
local buildID=-UnitDefNames.icon_investigation.id
local investigationDef=UnitDefNames.icon_investigation.id
local cfg=VFS.Include("luarules/configs/counterintelligence.lua")

local function pointedUnit()
    local x,y=Spring.GetMouseState()
    local kind,target=Spring.TraceScreenRay(x,y)
    if kind=="unit" then return target end
end

local function orderOptions(options)
    local opts=options and options.coded
    if not opts then
        opts={}
        for _,name in ipairs({"shift","ctrl","alt","right"}) do
            if options and options[name] then opts[#opts+1]=name end
        end
    end
    return opts
end

function widget:CommandNotify(cmd,params,options)
    if cmd~=buildID then return false end
    -- An abstract placement uses a map cursor, not Repair or native footprint
    -- validation. Lock the unit actually clicked (including a factory's roof),
    -- rather than whichever neighbor is closest to the ground-ray intersection.
    local target
    if #params==1 then target=params[1]
    elseif #params==3 or #params==4 then target=pointedUnit() end
    if not target then return false end -- synced placement handles ground coordinates
    Spring.GiveOrder(CMD_BUILD_INVESTIGATION,{target},orderOptions(options))
    return true
end

function widget:DrawWorld()
    local _,cmd=Spring.GetActiveCommand()
    if cmd~=buildID or Spring.IsGUIHidden() then return end
    local target=pointedUnit()
    if not target then return end
    local def=UnitDefs[Spring.GetUnitDefID(target)]
    if not def or (def.customParams or {}).baseclass=="Abstract" then return end
    local x,y,z=Spring.GetUnitPosition(target)
    if not x then return end
    -- Pure preview: no units, commands, resources or hidden guilt checks here.
    gl.PushAttrib(GL.ALL_ATTRIB_BITS)
    gl.DepthTest(true)
    gl.DepthMask(false)
    gl.Blending(GL.SRC_ALPHA,GL.ONE_MINUS_SRC_ALPHA)
    gl.Color(0.3,1,1,0.55)
    gl.PushMatrix()
    gl.Translate(x,y+(Spring.GetUnitHeight(target) or 0)+cfg.markerHeight,z)
    gl.Rotate((Spring.GetGameFrame()%300)*1.2,0,1,0)
    gl.UnitShape(investigationDef,Spring.GetMyTeamID(),false,false,false)
    gl.PopMatrix()
    gl.PopAttrib()
end
