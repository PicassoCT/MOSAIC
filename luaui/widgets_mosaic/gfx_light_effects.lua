function widget:GetInfo()
    return {name="Light Effects", desc="Radiance combat lights, FlamePainter fire and explosion heat distortion",
        author="Floris, Beherith, MOSAIC contributors", license="GPL V2", layer=0, enabled=true}
end

local Sources=VFS.Include('luaui/widgets_mosaic/include/combat_light_sources.lua')
local RadianceTime=VFS.Include('luaui/widgets_mosaic/include/radiance_time.lua')
local sources,lightRenderer,flameRenderer,tracerRenderer,capture,hasEmission,api
local globalLightMult,globalRadiusMult,globalLifeMult=1.3,1.3,.75
local enableHeatDistortion=true
local weaponConf={}
local function Split(s,separator)
    local out={}
    for word in s:gmatch('[^'..separator..']+') do out[#out+1]=tonumber(word) end
    return out
end

local function loadWeaponDefs()
	weaponConf = {}
	for i=1, #WeaponDefs do
		local customParams = WeaponDefs[i].customParams or {}
		if customParams.expl_light_skip == nil and tonumber(customParams.no_projectile_vfx)~=1 then
			local params = {}
			params.r, params.g, params.b = 1, 0.8, 0.4
			params.radius = (WeaponDefs[i].damageAreaOfEffect*4.5) * globalRadiusMult
			params.orgMult = (0.35 + (params.radius/2400)) * globalLightMult
			params.life = (14*(0.8+ params.radius/1200))*globalLifeMult

			if customParams.expl_light_color then
				local colorList = Split(customParams.expl_light_color, " ")
				params.r = colorList[1]
				params.g = colorList[2]
				params.b = colorList[3]
			elseif WeaponDefs[i].visuals ~= nil and WeaponDefs[i].visuals.colorR ~= nil then
				params.r = WeaponDefs[i].visuals.colorR
				params.g = WeaponDefs[i].visuals.colorG
				params.b = WeaponDefs[i].visuals.colorB
			end

			if customParams.expl_light_opacity ~= nil then
				params.orgMult = customParams.expl_light_opacity * globalLightMult
			end

			if customParams.expl_light_mult ~= nil then
				params.orgMult = params.orgMult * customParams.expl_light_mult
			end

			if customParams.expl_light_radius then
				params.radius = tonumber(customParams.expl_light_radius) * globalRadiusMult
			end
			if customParams.expl_light_radius_mult then
				params.radius = params.radius * tonumber(customParams.expl_light_radius_mult)
			end

			params.heatradius = (WeaponDefs[i].damageAreaOfEffect*0.5)

			if customParams.expl_light_heat_radius_mult then
				params.heatradius = (params.heatradius * tonumber(customParams.expl_light_heat_radius_mult))
			end

			params.heatlife = (13*(0.8+ params.heatradius/1200)) + (params.heatradius/4)

			if customParams.expl_light_heat_life_mult then
				params.heatlife = params.heatlife * tonumber(customParams.expl_light_heat_life_mult)
			end

			params.heatstrength = 1 + (params.heatradius/30)

			if customParams.expl_light_heat_strength_mult then
				params.heatstrength = params.heatstrength * customParams.expl_light_heat_strength_mult
			end
			if customParams.expl_noheatdistortion then
				params.noheatdistortion = true
			end

			if customParams.expl_light_life then
				params.life = tonumber(customParams.expl_light_life)
			end
			if customParams.expl_light_life_mult then
				params.life = params.life * tonumber(customParams.expl_light_life_mult)
			end
			if WeaponDefs[i].paralyzer then
				params.type = 'paralyzer'
			end
			if WeaponDefs[i].type == 'Flame' then
				params.type = 'flame'
				params.radius = params.radius * 0.66
				params.orgMult = params.orgMult * 0.66
			end
			if WeaponDefs[i].type == 'BeamLaser' then
				local damage = 75
				params.radius = params.radius * 3.5
				for cat=0, #WeaponDefs[i].damages do
					if Game.armorTypes[cat] and Game.armorTypes[cat] == 'default' then
						damage = WeaponDefs[i].damages[cat]
						break
					end
				end
				params.life = 1
				damage = damage/WeaponDefs[i].beamtime
				params.radius = (params.radius*1.4) + (damage/2500)
				params.orgMult = (0.22 + (damage/3000))
				if params.orgMult > 0.8 then
					params.orgMult = 0.8
				end
				params.orgMult = params.orgMult * globalLightMult
			end

			weaponConf[i] = params
		end
	end
end

local function syncOptions()
    loadWeaponDefs()
    if sources then
        sources.weaponConf=weaponConf
        sources.brightness,sources.radius=globalLightMult,globalRadiusMult
    end
end

local function WeaponExplosion(px,py,pz,weaponID)
    if not sources then return end
    sources:AddExplosion(px,py,pz,weaponID,false)
    local conf=weaponConf[weaponID]
    if conf then
        local params={life=conf.life,param={radius=conf.radius}}
		if py > 0 and enableHeatDistortion and WG['Lups'] and params.param.radius > 80 and not weaponConf[weaponID].noheatdistortion and Spring.IsSphereInView(px,py,pz,100) then

			local strength,animSpeed,life,heat,sizeGrowth,size,force

			local cx, cy, cz = Spring.GetCameraPosition()
			local distance = math.max(1,math.sqrt((px-cx)^2+(py-cy)^2+(pz-cz)^2))
			local strengthMult = 1 / (distance*0.001)

			if weaponConf[weaponID].type == 'paralyzer' then
				strength = 10
				animSpeed = 0.1
				life = params.life*0.6 + (params.param.radius/80)
				sizeGrowth = 0
				heat = 15
				size =  params.param.radius/16
				force = {0,0.15,0}
			else
				animSpeed = 1.3
				sizeGrowth = 0.6
				if weaponConf[weaponID].type == 'flame' then
					strength = 1 + (params.life/25)
					size = params.param.radius/2.35
					life = params.life*0.64 + (params.param.radius/90)
					force = {1,5.5,1}
					heat = 8
				else
					strength = weaponConf[weaponID].heatstrength
					size = weaponConf[weaponID].heatradius
					life = weaponConf[weaponID].heatlife
					force = {0,0.35,0}
					heat = 1
				end
			end
			if size*strengthMult > 5 then
				WG['Lups'].AddParticles('JitterParticles2', {
					layer = -35,
					life = life,
					pos = {px,py+10,pz},
					size = size,
					sizeGrowth = sizeGrowth,
					strength = strength*strengthMult,
					animSpeed = animSpeed,
					heat = heat,
					force = force,
				})
			end
		end
    end
end
local function WeaponBarrelfire(px,py,pz,weaponID)
    if sources then sources:AddExplosion(px,py,pz,weaponID,true) end
end
local function CombatFire(id,x,y,z,born,expires)
    if sources then sources:SetFire(id,x,y,z,born,expires) end
end
local function PyroTorchOff(x,y,z,id)
    if sources then sources:AddPyroTorch(x,y,z,id) end
end
local callbacks={GadgetPyroTorchOff=PyroTorchOff,
    GadgetWeaponExplosion=WeaponExplosion,GadgetWeaponBarrelfire=WeaponBarrelfire,
    GadgetCombatFire=CombatFire}

function widget:Initialize()
    syncOptions()
    sources=Sources.New(weaponConf)
    sources.brightness,sources.radius=globalLightMult,globalRadiusMult
    for _,id in ipairs(Spring.GetAllUnits()) do sources:UnitCreated(id,Spring.GetUnitDefID(id)) end
    local err
    lightRenderer,err=VFS.Include('luaui/widgets_mosaic/include/combat_light_renderer.lua')(sources)
    if not lightRenderer then Spring.Echo('Combat radiance unavailable: '..tostring(err)) end
    flameRenderer,err=VFS.Include('luarules/gadgets/include/smoke_ribbon_renderer.lua')()
    if not flameRenderer then Spring.Echo('Combat FlamePainter unavailable: '..tostring(err)) end
    if flameRenderer then flameRenderer.maxVisible=64 end
    tracerRenderer,err=VFS.Include('luaui/widgets_mosaic/include/combat_tracers.lua')()
    if not tracerRenderer then Spring.Echo('Night tracers unavailable: '..tostring(err)) end
    for name,fn in pairs(callbacks) do widgetHandler:RegisterGlobal(name,fn) end
    capture=function(bottom,top,gain,night)
        if lightRenderer then lightRenderer:Capture(bottom,top,gain,night) end
    end
    hasEmission=function(night)
        for _,light in ipairs(sources:Collect()) do
            if light.strength>0 and (not light.nightOnly or night>0) then return true end
        end
        return false
    end
    if lightRenderer then
        WG.CaptureCombatLightEmission=capture
        WG.HasCombatLightEmission=hasEmission
    end
    api={
        setGlobalBrightness=function(v) globalLightMult=v;syncOptions() end,
        setGlobalRadius=function(v) globalRadiusMult=v;syncOptions() end,
        setLife=function(v) globalLifeMult=v;syncOptions() end,
        setHeatDistortion=function(v) enableHeatDistortion=v end,
        getGlobalBrightness=function() return globalLightMult end,
        getGlobalRadius=function() return globalRadiusMult end,
        getLife=function() return globalLifeMult end,
        getHeatDistortion=function() return enableHeatDistortion end,
        getCinderBudgetStats=function() return sources and sources.pyroStats end,
    }
    WG.lighteffects=api
end
function widget:TextCommand(command)
    if command~='cinder fxstats' then return false end
    local s=sources and sources.pyroStats or {}
    Spring.Echo(string.format(
        'Cinder FX: candidates=%d selected=%d detailed=%d simplified=%d rendered=%d ribbons=%d rays=%d lite=%d',
        s.candidateCount or 0,s.selected or 0,s.detailed or 0,
        s.simplified or 0,(s.renderedDetailed or 0)+(s.renderedSimple or 0),
        s.totalRibbons or 0,s.tracesThisFrame or 0,s.liteThisFrame or 0))
    return true
end
function widget:Update(dt) if sources then sources:Update(dt) end end
function widget:UnitCreated(id,defID) if sources then sources:UnitCreated(id,defID) end end
function widget:UnitDestroyed(id) if sources then sources:UnitDestroyed(id) end end
function widget:DrawWorld()
    if sources then
        local _,flames,tracers=sources:Collect()
        if flameRenderer then flameRenderer:Draw(flames) end
        if tracerRenderer then tracerRenderer:Draw(tracers,RadianceTime.AtFrame(Spring.GetGameFrame())) end
    end
end
function widget:Shutdown()
    for name in pairs(callbacks) do widgetHandler:DeregisterGlobal(name) end
    if WG.CaptureCombatLightEmission==capture then WG.CaptureCombatLightEmission=nil end
    if WG.HasCombatLightEmission==hasEmission then WG.HasCombatLightEmission=nil end
    if WG.lighteffects==api then WG.lighteffects=nil end
    if lightRenderer then lightRenderer:Shutdown();lightRenderer=nil end
    if flameRenderer then flameRenderer:Shutdown();flameRenderer=nil end
    if tracerRenderer then tracerRenderer:Shutdown();tracerRenderer=nil end
    sources=nil
end
function widget:GetConfigData()
    return {globalLightMult=globalLightMult,globalRadiusMult=globalRadiusMult,
        globalLifeMult=globalLifeMult,enableHeatDistortion=enableHeatDistortion}
end
function widget:SetConfigData(data)
    globalLightMult=tonumber(data.globalLightMult) or globalLightMult
    globalRadiusMult=tonumber(data.globalRadiusMult) or globalRadiusMult
    globalLifeMult=tonumber(data.globalLifeMult) or globalLifeMult
    if data.enableHeatDistortion~=nil then enableHeatDistortion=data.enableHeatDistortion end
    syncOptions()
end
