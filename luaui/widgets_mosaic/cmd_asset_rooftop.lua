function widget:GetInfo()
    return {name="Asset roof orders", desc="Use movement clicks to garrison assets",
        author="Mosaic contributors", license="GNU GPL, v2 or later", layer=20, enabled=true}
end
VFS.Include("luarules/configs/commandsIDs.lua")
local assetDef = UnitDefNames.operativeasset.id
local issuing = false
local function isBuilding(id)
    local defID = Spring.GetUnitDefID(id)
    local def = defID and UnitDefs[defID]
    return def and (def.isBuilding or def.name:find("house_",1,true) == 1)
end
function widget:DefaultCommand(kind,id)
    if kind ~= "unit" or not isBuilding(id) then return end
    local selected = Spring.GetSelectedUnits()
    if #selected == 0 then return end
    for _,unit in ipairs(selected) do
        if Spring.GetUnitDefID(unit) ~= assetDef then return end
    end
    -- Preserve a unit target so CommandNotify can resolve the mouse ray.
    return CMD_ASSET_ROOFTOP
end
function widget:CommandNotify(cmd,p,opts)
    if issuing or (cmd ~= CMD.MOVE and cmd ~= CMD.ATTACK and cmd ~= CMD_ASSET_ROOFTOP) then return false end
    local x,y = Spring.GetMouseState()
    local kind,house = Spring.TraceScreenRay(x,y,false)
    if cmd == CMD.ATTACK and #p == 1 then house=p[1]; kind="unit" end
    if kind ~= "unit" or not isBuilding(house) or Spring.IsAboveMiniMap(x,y) then return false end
    local assets,others = {},{}
    for _,id in ipairs(Spring.GetSelectedUnits()) do
        local list = Spring.GetUnitDefID(id) == assetDef and assets or others
        list[#list+1] = id
    end
    if #assets == 0 then return false end
    local _,point = Spring.TraceScreenRay(x,y,true)
    local roofParams = {house}
    if type(point) == "table" then
        local cx,cy,cz = Spring.GetCameraPosition()
        roofParams = {house,cx,cy,cz,point[1]-cx,point[2]-cy,point[3]-cz}
    end
    local options = opts.coded
    if not options then
        options = {}
        for _,name in ipairs({"shift","ctrl","alt","right","meta"}) do
            if opts[name] then options[#options+1] = name end
        end
    end
    issuing = true
    Spring.GiveOrderToUnitArray(assets,CMD_ASSET_ROOFTOP,roofParams,options)
    if #others > 0 then Spring.GiveOrderToUnitArray(others,cmd,p,options) end
    issuing = false
    return true
end
