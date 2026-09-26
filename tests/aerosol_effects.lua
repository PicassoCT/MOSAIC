-- Execute the real drone spray worker and both effect registration APIs.
local kinds={'depressol','tollwutox','orgyanyl','wanderlost'}
for index,kind in ipairs(kinds) do
    local frame,flying,destroyed=0,false,false
    local workers,masks,stopped={},{},{}
    local config={Aerosols={sprayRange=250}}
    config.Aerosols[kind]={sprayTimePerUnitInMs=12000}
    GG={GameConfig=config};Game={gameSpeed=30};unitID=7;unitDefID=index
    UnitDefs={[index]={name='air_copter_aerosol_'..kind}};UnitDefNames={};script={}
    Spring={GetGameFrame=function()return frame end,ValidUnitID=function()return true end,
        GetUnitIsDead=function()return destroyed end,GetUnitPieceMap=function()return {emitor=2,center=1}end,
        GetUnitPiecePosDir=function()return frame,128,40 end,GetUnitDefID=function()return index end,
        SetUnitNoSelect=function()end,DestroyUnit=function()destroyed=true;script.Killed()end,Echo=function()end}
    VFS={Include=function(p)return dofile(p)end}
    gadgetHandler={IsSyncedCode=function()return true end,AddChatAction=function()end,RemoveChatAction=function()end}
    gadget={};dofile('luarules/gadgets/gfx_cloud_volumes.lua');local cloud=gadget;cloud:Initialize()
    gadget={};dofile('luarules/gadgets/gfx_smoke_ribbons.lua');local ribbon=gadget;ribbon:Initialize()
    include=function(p)if p=='lib_aerosol_effects.lua' then return dofile('scripts/'..p)end end
    piece=function(n)return n=='emitor' and 2 or 1 end
    getChemTrailTypes=function()return {}end
    getAerosolUnitDefIDs=function()return {[index]=kind}end
    getChemTrailInfluencedTypes=function()return {}end
    getGameConfig=function()return config end
    getPieceTableByNameGroups=function()return {Tank={3,4,5,6}}end
    hideT=function()end;Show=function()end;Hide=function()end
    isUnitFlying=function()return flying end
    getAllNearUnit=function(_,range)assert(range==250);return {}end
    foreach=function()end
    EmitSfx=function()error('aerosol still emits legacy CEG')end
    PlaySoundByUnitDefID=function()end
    StartThread=function(fn,...)
        if fn~=PlaySoundByUnitDefID then workers[#workers+1]=coroutine.create(fn) end
    end
    SetSignalMask=function(mask) masks[coroutine.running()]=mask end
    Signal=function(mask)
        for worker,active in pairs(masks) do
            if active==mask then stopped[worker]=true end
        end
    end
    Sleep=function(ms)coroutine.yield(ms)end
    dofile('scripts/air_copter_aerosolscript.lua');script.Create()
    assert(#workers==1,'extra aerosol polling worker')
    local function tick()
        if stopped[workers[1]] then return end
        local ok,ms=coroutine.resume(workers[1]);assert(ok,ms)
        frame=frame+(ms or 0)*30/1000;cloud:GameFrame(frame)
    end
    local function count(records)local n=0;for _ in pairs(records)do n=n+1 end;return n end
    tick();tick();assert(count(CloudVolumeRecords)==0 and count(SmokeRibbonRecords)==0,'landed drone spraying')
    flying=true
    for _=1,25 do tick()end
    assert(timeTank==9600,'visuals changed tank consumption cadence')
    local r=next(SmokeRibbonRecords) and select(2,next(SmokeRibbonRecords))
    assert(r and r.width==42 and r.length==120 and r.motionAffected and r.windAffected)
    assert(r.direction[2]==-1 and r.emission[1]==3,'missing bright downwards spray')
    local color=dofile('luarules/gadgets/include/cloud_volume_config.lua').aerosolColors[kind]
    for i=1,3 do assert(r.colorStart[i]==color[i],'wrong aerosol type colour')end
    local positions={}
    for _,p in pairs(CloudVolumeRecords)do
        assert(p.preset=='aerosol_'..kind and p.y==104,'wrong aerosol cloud preset/attachment')
        positions[p.x]=true
    end
    assert(count(positions)>1,'clouds do not remain along the flight path')
    flying=false;tick()
    assert(count(SmokeRibbonRecords)==0 and count(CloudVolumeRecords)>0,'landing cleanup removed residual gas')
    flying=true
    for _=1,65 do tick();assert(count(CloudVolumeRecords)<=8,'unbounded per-drone cloud emission')end
    local fuel=timeTank
    BeginAircraftCrash()
    assert(stopped[workers[1]] and count(SmokeRibbonRecords)==0,'crash leaves spray worker running')
    tick();assert(timeTank==fuel,'crashing drone continues to consume/spray aerosol')
    script.Killed();assert(count(SmokeRibbonRecords)==0,'death leaves attached spray')
    local n=count(CloudVolumeRecords)
    tick();assert(count(CloudVolumeRecords)<=n and count(SmokeRibbonRecords)==0,'worker restarts dead emitter')
    frame=frame+6*30;frame=math.ceil(frame/15)*15;cloud:GameFrame(frame)
    assert(count(CloudVolumeRecords)==0,'residual aerosol never expires')
    cloud:Shutdown();ribbon:Shutdown()
end
print('PASS: four aerosol types, real drone worker/APIs, larger bright spray, moving wake, bounded puffs, landing/crash/death/expiry, unchanged gameplay cadence, no legacy CEG')
