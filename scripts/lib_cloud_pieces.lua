-- Install only in the spaceport's Lua unit-script environment. Group helpers call
-- these same Show/Hide functions, so every animation path shares one lifecycle.
local Config=VFS.Include('luarules/gadgets/include/cloud_volume_config.lua')
local rawShow,rawHide=Show,Hide
local radianceShow=ShowRadiancePiece
local presets,active={},{}
for name,id in pairs(Spring.GetUnitPieceMap(unitID) or {}) do presets[id]=Config.SpaceportPreset(name) end
local dead=false
function Show(id)
    local preset=presets[id]
    if preset and GG.CloudVolume and not dead then
        if GG.CloudVolume.SetPiece(unitID,id,preset) then rawHide(id);active[id]=true;return end
    end
    if not dead then rawShow(id) end
end
function Hide(id)
    if active[id] then
        if GG.CloudVolume then GG.CloudVolume.RemovePiece(unitID,id) end
        active[id]=nil
    end
    rawHide(id)
end
function ShowRadiancePiece(id)
    if not id then return end
    if presets[id] then
        Show(id)
        -- Keep the existing radiance emitter despite hiding its old solid mesh.
        if GG.SetObjectiveRadiancePieceVisible then GG.SetObjectiveRadiancePieceVisible(unitID,id,not dead) end
    else radianceShow(id) end
end
function HideRadiancePiece(id)
    if not id then return end
    Hide(id)
    if GG.SetObjectiveRadiancePieceVisible then GG.SetObjectiveRadiancePieceVisible(unitID,id,false) end
end
return {
    Shutdown=function()
        dead=true
        for id in pairs(active) do
            if GG.CloudVolume then GG.CloudVolume.RemovePiece(unitID,id) end
            if GG.SetObjectiveRadiancePieceVisible then GG.SetObjectiveRadiancePieceVisible(unitID,id,false) end
        end
        active={}
    end,
}
