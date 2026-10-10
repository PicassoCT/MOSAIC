function gadget:GetInfo()
    return {name='City roads and addresses',desc='Deterministic plot addresses shared by map and game generation',author='MOSAIC contributors',license='GPL3',layer=10,enabled=true}
end
if not gadgetHandler:IsSyncedCode() then return false end
-- Gadgets have separate environments. Load descriptor dependencies here;
-- functions included by game_spawnCity are not globals in this gadget.
VFS.Include('scripts/lib_UnitScript.lua')
VFS.Include('scripts/lib_mosaic.lua')
VFS.Include('scripts/lib_staticstring.lua')
local roads=VFS.Include('scripts/lib_city_roads.lua')
local network, frozen, pending, addresses, mapNetwork
local config
local public={public=true}
local function plot(id)
    local x=Spring.GetUnitRulesParam(id,'city_plot_x')
    local z=Spring.GetUnitRulesParam(id,'city_plot_z')
    if x and z then return x,z end
    local p=GG.BuildingTable and GG.BuildingTable[id]
    if p then return p.x,p.z end
    local x,_,z=Spring.GetUnitPosition(id); return x,z
end
local function apply(id,a,descriptor)
    for _,k in ipairs({'plot_key','street_id','street_name','house_number','number_source','generation'}) do
        Spring.SetUnitRulesParam(id,'city_'..k,a[k],public)
    end
    local x,z=plot(id)
    Spring.SetUnitRulesParam(id,'city_plot_x',x,public)
    Spring.SetUnitRulesParam(id,'city_plot_z',z,public)
    Spring.SetUnitRulesParam(id,'city_sector',roads.sector(x,z,Game.mapSizeX,Game.mapSizeZ),public)
    Spring.SetUnitTooltip(id,descriptor..' - '..a.street_name..' '..a.house_number..' ['..roads.sector(x,z,Game.mapSizeX,Game.mapSizeZ)..']')
    if GG.BuildingTable and GG.BuildingTable[id] then GG.BuildingTable[id].address=a end
end
local function register(id,business,title)
    local x,z=plot(id); if not x then return end
    local key=roads.key(x,z)
    local descriptor=title or (HouseDescriptor and HouseDescriptor(id,roads.hash(key),UnitDefs,business or {}) or 'House')
    local a=addresses[key] or (GG.BuildingTable and GG.BuildingTable[id] or {}).address
        or (GG.GeneratedCityAddresses or {})[key]
    if not a and Spring.GetUnitRulesParam(id,'city_plot_key')==key then
        a={};for _,k in ipairs({'plot_key','street_id','street_name','house_number','number_source','generation'}) do a[k]=Spring.GetUnitRulesParam(id,'city_'..k) end
        if not a.street_name or not a.house_number then a=nil end
    end
    if a then addresses[key]=a; apply(id,a,descriptor); return a end
    if frozen then
        a=roads.assign(network,{{x=x,z=z}})[key]
        -- Late new plots do not renumber established plots. Coordinate suffix
        -- prevents collisions without depending on who was built first.
        a.house_number=a.house_number..'/'..key
        addresses[key]=a; apply(id,a,descriptor); return a
    end
    pending[id]={x=x,z=z,key=key,descriptor=descriptor}
end
local function publish()
    GG.CityRoadNetwork=network
    local wire=roads.encode(network);local count=math.ceil(#wire/1024)
    for i=1,count do Spring.SetGameRulesParam('city_roads_chunk_'..i,wire:sub((i-1)*1024+1,i*1024),public) end
    Spring.SetGameRulesParam('city_roads_chunks',count,public)
    Spring.SetGameRulesParam('city_roads_revision',(Spring.GetGameRulesParam('city_roads_revision') or 0)+1,public)
    GG.UsedStreetNameCounterDict={}
    for _,r in ipairs(network.roads) do GG.UsedStreetNameCounterDict[r.name]=0 end
end
local function finalize()
    local plots,seen={},{}
    for _,p in pairs(pending) do
        if not seen[p.key] then seen[p.key]=true; plots[#plots+1]=p end
    end
    if not mapNetwork then
        local function blocked(x,z)
            if Spring.GetGroundHeight and Spring.GetGroundHeight(x,z)<=0 then return true end
            if Spring.GetGroundNormal then local _,_,_,slope=Spring.GetGroundNormal(x,z);if slope and slope>0.2 then return true end end
            return false
        end
        network=roads.infer(plots,Game.mapSizeX,Game.mapSizeZ,blocked,config.game.culture,Game.mapName,
            math.max(config.city.buildings.sizeX,config.city.buildings.sizeZ)/2+16)
        publish()
    end
    local assigned=roads.assign(network,plots)
    for key,a in pairs(assigned) do if not addresses[key] then addresses[key]=a end end
    for id,p in pairs(pending) do
        if Spring.ValidUnitID(id) and not Spring.GetUnitIsDead(id) then apply(id,addresses[p.key],p.descriptor) end
    end
    pending={}; frozen=true
end
function gadget:Initialize()
    addresses=GG.CityPlotAddresses or {}; GG.CityPlotAddresses=addresses; pending={}; frozen=false
    config=getGameConfig();mapNetwork=false
    if VFS.FileExists('mosaic/roads.lua',VFS.MAP) then
        network=roads.normalize(VFS.Include('mosaic/roads.lua',nil,VFS.MAP));mapNetwork=true
    elseif Game.mapSizeX==8192 and Game.mapSizeZ==8192 and Game.mapName:lower():find('lastdayofdh?ubai') then
        network=roads.normalize(VFS.Include('scripts/city_roads/dhubai.lua'));mapNetwork=true
    else
        network=roads.normalize({schema=1,generation='game',roads={}})
        -- Maps that explicitly mark asphalt can provide authoritative terrain
        -- streets without a separate roads.lua. Old engines use a different
        -- return ordering, so locate the type name rather than an index.
        if Spring.GetGroundInfo and Spring.GetGroundHeight then
            local step=32;local nx,nz=math.floor(Game.mapSizeX/step),math.floor(Game.mapSizeZ/step);local mask,count={},0
            for z=1,nz do for x=1,nx do
                local px,pz=(x-0.5)*step,(z-0.5)*step
                local values={Spring.GetGroundInfo(px,pz)};local name
                for _,v in ipairs(values) do if type(v)=='string' then name=v:lower();break end end
                if name and (name=='street' or name=='road' or name=='asphalt') and Spring.GetGroundHeight(px,pz)>0 then
                    mask[(z-1)*nx+x]=true;count=count+1
                end
            end end
            if count>0 then network=roads.trace(mask,nx,nz,step,config.game.culture,Game.mapName);mapNetwork=#network.roads>0 end
        end
    end
    GG.CityAddressService={Register=register,SetDescriptor=function(id,title) return register(id,nil,title) end}
    publish()
end
function gadget:GameFrame(frame)
    if not frozen and GG.CitySpawnComplete then finalize() end
end
function gadget:Shutdown()
    GG.CityAddressService=nil
end
