-- Install in the owning Lua unit-script environment. Group helpers call
-- these same Show/Hide functions, so every animation path shares one lifecycle.
local Config=VFS.Include('luarules/gadgets/include/cloud_volume_config.lua')
return function(kind)
local selectPreset=assert(Config.PiecePresets[kind], 'Unknown cloud piece family: '..tostring(kind))
local rawShow,rawHide=Spring.UnitScript.Show,Spring.UnitScript.Hide
local radianceShow=ShowRadiancePiece
local presets,active,warned={},{},{}
local radianceModes,lit={},{}
for name,id in pairs(Spring.GetUnitPieceMap(unitID) or {}) do
    presets[id]=selectPreset(name)
    local p=presets[id] and Config.Preset(presets[id])
    if p and (p.emission>0 or (p.glow or 0)>0) then radianceModes[id]='cloud' end
    if kind=='spaceport' and (name=='SpaceHarbour' or name:match('^CrawlerBooster%d+$')
        or name=='CrawlerMain' or name=='RocketCrawler'
        or name=='LoadCraneNight' or name=='PickUpBoosterNight') then
        radianceModes[id]='material'
    end
end
local dead=false
local function light(id,on)
    if GG.SetObjectiveRadiancePieceVisible then
        GG.SetObjectiveRadiancePieceVisible(unitID,id,on,radianceModes[id],presets[id])
        lit[id]=on or nil
    end
end
local function cloudShow(id)
    if not dead and radianceModes[id] then light(id,true) end
    local preset=presets[id]
    if preset and not dead then
        local ok,reason
        if GG.CloudVolume then ok,reason=GG.CloudVolume.SetPiece(unitID,id,preset)
        else reason='synced cloud gadget unavailable' end
        if ok then
            rawHide(id);active[id]=true
            return
        end
        if not warned[id] then
            warned[id]=true
            Spring.Echo('Cloud piece fallback: unit '..unitID..', piece '..id..': '..tostring(reason or 'registration rejected'))
        end
    end
    if not dead then rawShow(id) end
end
local function cloudHide(id)
    if lit[id] or radianceModes[id] then light(id,false) end
    if active[id] then
        if GG.CloudVolume then (GG.CloudVolume.ReleasePiece or GG.CloudVolume.RemovePiece)(unitID,id) end
        active[id]=nil
    end
    rawHide(id)
end
function ShowRadiancePiece(id)
    if not id then return end
    if presets[id] or radianceModes[id] then
        cloudShow(id)
    elseif not dead then radianceShow(id);lit[id]=true end
end
function HideRadiancePiece(id)
    if not id then return end
    cloudHide(id)
    light(id,false)
end
-- Explicit environment writes: this file also has header-local Show/Hide.
_G.CloudPieceShow,_G.CloudPieceHide=cloudShow,cloudHide
_G.Show,_G.Hide=cloudShow,cloudHide
return {
    Shutdown=function()
        dead=true
        for id in pairs(active) do
            if GG.CloudVolume then GG.CloudVolume.RemovePiece(unitID,id) end
        end
        for id in pairs(lit) do light(id,false) end
        active={}
    end,
}

end
