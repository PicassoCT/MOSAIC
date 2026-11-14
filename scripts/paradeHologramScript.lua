-- Native coloured pixel meshes use the same visible-piece protocol as houses.
local decorations = VFS.Include("luarules/configs/parade_hologram_decorations.lua")
local ghosts = VFS.Include("luarules/configs/parade_ghost_parts.lua")
local selected, yaw, pieces
local current = {}
local blackoutUntil = 0

local function publish(ids)
    ids = ids or {}
    for _,id in ipairs(current) do Hide(id) end
    current = ids
    for _,id in ipairs(ids) do Show(id) end
    GG.VisibleUnitPieces = GG.VisibleUnitPieces or {}
    GG.VisibleUnitPieces[unitID] = ids
    -- Publish the entire assembly atomically to rendering and radiance.
end

local function selectParts(names, catalog, angle)
    local nextSelection = {}
    for _,name in ipairs(names) do
        local art = catalog[name]
        if not art then return false end
        if pieces then
            for index in ipairs(art.frames) do
                if not pieces[name.."_"..index] then return false end
            end
        end
        nextSelection[#nextSelection+1] = {name=name,art=art}
    end
    selected, yaw = nextSelection, angle or 0
    if pieces then Turn(pieces.center,y_axis,yaw,0) end
    return true
end

function SetParadeHologram(name, angle)
    if not name then return false end
    return selectParts({name},decorations.glyphs,angle)
end

function SetParadeGhost(body, face, mask, angle)
    for slot,name in pairs({body=body,face=face,mask=mask}) do
        if not ghosts.parts[name] or ghosts.parts[name].slot ~= slot then return false end
    end
    if not body or not face or not mask then return false end
    return selectParts({body,face,mask},ghosts.parts,angle)
end

function setTimeOutExternal(milliseconds)
    blackoutUntil = math.max(blackoutUntil,Spring.GetGameFrame()+math.ceil(milliseconds*30/1000))
    publish(nil)
end

local function animate()
    while true do
        local frame = Spring.GetGameFrame()
        local blackout = GG.BlackOutDeactivationTime and GG.BlackOutDeactivationTime[unitID]
        if blackout then
            blackoutUntil = math.max(blackoutUntil,blackout+5*60*30)
            GG.BlackOutDeactivationTime[unitID] = nil
        end
        local ids = {}
        if selected and frame >= blackoutUntil then
            for _,part in ipairs(selected) do
                local glyph = part.art
                local index = math.floor((frame/30+unitID*0.173)/(glyph.frameSeconds or 0.2)) % #glyph.frames+1
                ids[#ids+1] = assert(pieces[part.name.."_"..index], "Missing hologram piece: "..part.name)
            end
        end
        local changed = #ids ~= #current
        for i,id in ipairs(ids) do if current[i] ~= id then changed=true; break end end
        if changed then publish(ids) end
        Sleep(100)
    end
end

function script.Create()
    pieces = Spring.GetUnitPieceMap(unitID)
    for _, id in pairs(pieces) do Hide(id) end
    Spring.SetUnitNeutral(unitID,true)
    Spring.SetUnitBlocking(unitID,false,false,false,false,false,false,false)
    Spring.SetUnitNoSelect(unitID,true)
    Spring.SetUnitNoDraw(unitID,true) -- rendered only by the neon pass
    Spring.SetUnitStealth(unitID,true)
    Spring.MoveCtrl.Enable(unitID) -- retain the initial ground-relative position
    Turn(pieces.center,y_axis,yaw or 0,0)
    publish(nil)
    StartThread(animate)
end
function script.HitByWeapon() return 0 end
function script.Killed() publish(nil); return 0 end
