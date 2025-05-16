
function widget:GetInfo()
    return {
        name = "HeatHaze",
        desc = "Simulates realistic heat haze using depth and view angle",
        author = "Picasso & ChatGPT",
        date = "2025",
        license = "GPL3",
        layer = math.huge,
        enabled = true,
        hidden = false
    }
end

local heatShader
local vsx, vsy = Spring.GetViewGeometry()
local shaderFilePath = "luaui/widgets_mosaic/shaders/"
local noisetextureFilePath = ":l:luaui/images/noisetextures/rgbnoise.png"
local DAYLENGTH = 28800
local screenTex = nil
local heatHazeStrength = 0.0
local depthTexture = "$map_gbuffer_zvaltex"
local normalTexture = "$map_gbuffer_normtex"
local noiseTexture = ":l:luaui/images/noisetextures/rgbnoise.png"
local boolIsMapNameOverride = false
local boolRainyArea = false
local glRenderToTexture      = gl.RenderToTexture
local glTexture = gl.Texture
local glUniform = gl.Uniform
local glCopyToTexture = gl.CopyToTexture
local glUseShader = gl.UseShader
local glTexRect = gl.TexRect
local heatHazeStrengthLocation = nil
local heatShaderTimeLocation = nil
local heatHazeViewPortSizeLocation = nil


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
    end

    if boolRainyArea == false then
        return false
    end

    local gameFrames = Spring.GetGameFrame()
    local dayNr = gameFrames / DAYLENGTH

    return dayNr % 3 < 1.0 and (hours > 18 or hours < 7)
end

local function calculateHeatHazeStrength()
    if true then return 1.0 end
    local hours,minutes,_, timePercent = getDayTime()
    local boolIsRaining = isRaining() 
    if boolIsRaining == true then return 0.0,hours, minutes end

    if timePercent < 0.35 then
        return math.max(0, (timePercent - 0.25) * 10.0),hours, minutes
    elseif timePercent < 0.75 then
        return 1.0 ,hours, minutes
    else
        return math.max(0, 1.0 - (timePercent - 0.75) * 6.0)  ,hours, minutes
    end
end

local function getHeatHazeActive(mapName)
    return string.find(string.lower(mapName), "mosaic_lastdayofdubai_v" )
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

function widget:ViewResize() --TODO test/assert
        vsx, vsy, vpx, vpy = Spring.GetViewGeometry()

        screenTex= gl.CreateTexture(vsx,vsy, {
            target = target,
            min_filter = GL.LINEAR,
            mag_filter = GL.LINEAR,
            wrap_s   = GL.CLAMP_TO_EDGE,
            wrap_t   = GL.CLAMP_TO_EDGE,
          })

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
        textures = {
            [0] = screenTex
        },

        uniformInt = {
            screenTex = 0,
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
        Spring.Echo(gl.GetShaderLog())
        widgetHandler:RemoveWidget(self)
    end
    widget:ViewResize()
    Spring.Echo("HeatHaze: Initalization Completed")
    heatHazeStrengthLocation = gl.GetUniformLocation(heatShader, "heatHazeStrength")
    heatShaderTimeLocation = gl.GetUniformLocation(heatShader, "time")
    heatHazeViewPortSizeLocation = gl.GetUniformLocation(heatShader, "viewPortSize")
end

function widget:Shutdown()
    if heatShader then
        gl.DeleteShader(heatShader)
        glTexture(0, false)
        glTexture(1, false)
        glTexture(2, false)
    end
end

function widget:Update()    
    heatHazeStrength = calculateHeatHazeStrength()
end

function widget:DrawScreenEffects()
    if not heatShader then return end
    local _, _, isPaused = Spring.GetGameSpeed()
    if isPaused then
       return
    end

    glUseShader(heatShader)
    glUniform( heatHazeStrengthLocation, heatHazeStrength)
    glUniform(heatShaderTimeLocation, Spring.GetGameSeconds())
    glUniform(heatHazeViewPortSizeLocation, vsx, vsy)
    glCopyToTexture(screenTex, 0, 0, 0, 0, vsx, vsy) 
    glTexture(1, depthTexture)
    glTexture(2, noiseTexture)

    glTexRect(0, vsy, vsx, 0)
    glTexture(1, false)
    glTexture(2, false)
    glTexture(3, false)
    glUseShader(0)
end
