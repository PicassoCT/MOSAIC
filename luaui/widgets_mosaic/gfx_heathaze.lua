
function widget:GetInfo()
    return {
        name = "HeatHaze",
        desc = "Simulates realistic heat haze using depth and view angle",
        author = "Picasso & ChatGPT",
        date = "2025",
        license = "GPL3",
        layer = -5,
        enabled = true,
        hidden = false
    }
end

local heatShader
local vsx, vsy = Spring.GetViewGeometry()
local shaderFilePath = "luaui/widget_map/shaders/"
local noisetextureFilePath = ":l:luaui/images/noisetextures/rgbnoise.png"
local DAYLENGTH = 28800

local heatHazeStrength = 0.0
local depthTexture = "$map_gbuffer_zvaltex"
local normalTexture = "$map_gbuffer_normtex"
local noiseTexture = ":l:luaui/images/noisetextures/rgbnoise.png"
local boolIsMapNameOverride = false
local boolRainyArea = false


local function isRainyArea()
    return getDetermenisticHash() % 2 == 0 or boolIsMapNameOverride 
end

local function getDayTime()
    local morningOffset = (DAYLENGTH / 2)
    local Frame = (Spring.GetGameFrame() + morningOffset) % DAYLENGTH
    local percent = Frame / DAYLENGTH
    local hours = math.floor((Frame / DAYLENGTH) * 24)
    local minutes = math.ceil((((Frame / DAYLENGTH) * 24) - hours) * 60)
    local seconds = 60 - ((24 * 60 * 60 - (hours * 60 * 60) - (minutes * 60)) % 60)
    return hours, minutes, seconds, percent
end

local function isRaining()   

    if boolRainyArea == nil then
        boolRainyArea = isRainyArea()        
        Spring.Echo("Is rainy area:"..tostring(boolRainyArea))
    end

    if boolRainyArea == false then
        return false
    end

    local gameFrames = Spring.GetGameFrame()
    local dayNr = gameFrames / DAYLENGTH

    return dayNr % 3 < 1.0 and (hours > 18 or hours < 7)
end

local function calculateHeatHazeStrength()
    local _,_,_, timePercent = getDayTime()
    if isRaining() then return 0.0 end

    if timePercent < 0.25 then
        return math.max(0, (timePercent - 0.15) * 10.0)
    elseif timePercent < 0.75 then
        return 1.0
    else
        return math.max(0, 1.0 - (timePercent - 0.75) * 4.0)
    end
end

local function getHeatHazeActive(mapName)
    return string.find(map, "mosaic_lastdayofdubai_v" )
end

local function isMapNameRainyOverride(mapName)
    local map = string.lower(mapName)
    local ManualBuildingPlacement = {}        
        ManualBuildingPlacement[1] = "mosaic_lastdayofdubai_v"

      for i=1, #ManualBuildingPlacement do
        if string.find(map, ManualBuildingPlacement[i] ) then return true end
    end
    return false
end



function widget:Initialize()
    boolIsMapNameOverride = isMapNameRainyOverride(Game.mapName)
    Spring.Echo("HeatHaze: Starting")
    local isHeatHazeActive = getHeatHazeActive(Game.mapName)
    if not isHeatHazeActive then
        Spring.Echo("Not a heathaze map")
        widgetHandler:RemoveWidget(self)
    end
    local fragShader = VFS.LoadFile(shaderFilePath .. "heatShader.frag")
    local vertShader = VFS.LoadFile(shaderFilePath .. "heatShader.vert")
    heatShader = gl.CreateShader({
        fragment = fragShader,
        vertex = vertShader,
        uniformInt = {
            depthTex = 1,
            noiseTex = 2,
        },
        uniformFloat = {
            viewPortSize = {vsx, vsy},
        },
        uniform = {
            heatHazeStrength = 0.0,
            time = 0.0,
        }
    })
    if not heatShader then
        Spring.Echo("HeatHaze: Shader failed to compile!")
        widgetHandler:RemoveWidget(self)
    end
    Spring.Echo("HeatHaze: Initalization Completed")
end

function widget:Shutdown()
    if heatShader then
        gl.DeleteShader(heatShader)
    end
end

function widget:Update()

    heatHazeStrength = calculateHeatHazeStrength()
end

function widget:DrawScreenEffects()
    if not heatShader then return end
    gl.UseShader(heatShader)

    gl.Uniform(gl.GetUniformLocation(heatShader, "heatHazeStrength"), heatHazeStrength)
    gl.Uniform(gl.GetUniformLocation(heatShader, "time"), Spring.GetGameSeconds())
    gl.Uniform(gl.GetUniformLocation(heatShader, "viewPortSize"), vsx, vsy)

    gl.Texture(1, depthTexture)
    gl.Texture(2, noiseTexture)
    gl.TexRect(0, vsy, vsx, 0)
    gl.Texture(1, false)
    gl.Texture(2, false)
    gl.UseShader(0)
end
