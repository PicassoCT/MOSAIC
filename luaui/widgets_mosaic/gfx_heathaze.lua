
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

local function getDayTime()
    local morningOffset = (DAYLENGTH / 2)
    local Frame = (Spring.GetGameFrame() + morningOffset) % DAYLENGTH
    return Frame / DAYLENGTH
end

local function calculateHeatHazeStrength(timePercent)
    if timePercent < 0.25 then
        return math.max(0, (timePercent - 0.15) * 10.0)
    elseif timePercent < 0.75 then
        return 1.0
    else
        return math.max(0, 1.0 - (timePercent - 0.75) * 4.0)
    end
end

local function getHeatHazeActive()

end

function widget:Initialize()
    Spring.Echo("HeatHaze: Starting")
    local isHeatHazeActive = getHeatHazeActive()
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
    local timePercent = getDayTime()
    heatHazeStrength = calculateHeatHazeStrength(timePercent)
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
