function widget:GetInfo()
    return {
        name = "Sepia Shader Filter",
        desc = "provides the dubai map with a sepia tone colour grading shader",
        author = "ChatGPT",
        date = "2025-06-28",
        license = "MIT",
        layer = 0,
        enabled = true,
    }
end

-- CONFIGURATION
local TARGET_MAPS = {}
TARGET_MAPS[#TARGET_MAPS +1] = "lastdayofdubai"
TARGET_MAPS[#TARGET_MAPS +1] = "tabula"
local DAYLENGTH             = 28800
local morningOffset = (DAYLENGTH / 2)
local function getDayTime()
    local Frame = (Spring.GetGameFrame() + morningOffset) % DAYLENGTH
    local percent = Frame / DAYLENGTH
    local hours = math.floor((Frame / DAYLENGTH) * 24)
    local minutes = math.ceil((((Frame / DAYLENGTH) * 24) - hours) * 60)
    local seconds = 60 - ((24 * 60 * 60 - (hours * 60 * 60) - (minutes * 60)) % 60)
    return hours, minutes, seconds, percent
end

-- Shader variables
local sepiaShader
local sepiaRenderTexture = nil

local glCreateShader = gl.CreateShader
local glUseShader = gl.UseShader
local glDeleteShader = gl.DeleteShader
local glTexture = gl.Texture
local glTexRect = gl.TexRect
local glBlending = gl.Blending
local glRenderToTexture = gl.RenderToTexture
local glUniformInt = gl.UniformInt
local glUniform = gl.Uniform
local glUniformMatrix = gl.UniformMatrix
local sepiaMax = 0.75
local sepiaUniformIntensity
local sepiaIntensity = sepiaMax -- change this dynamically as needed (0.0 to 1.0)
local vsx,vsy

local function CreateSepiaShader()
    local shader = gl.CreateShader({
        fragment = [[
            uniform sampler2D tex0;
            uniform float intensity;
            void main() {
                vec4 color = texture2D(tex0, gl_TexCoord[0].st);

                float r = color.r;
                float g = color.g;
                float b = color.b;

                vec3 sepia = vec3(
                    dot(vec3(r, g, b), vec3(0.393, 0.769, 0.189)),
                    dot(vec3(r, g, b), vec3(0.349, 0.686, 0.168)),
                    dot(vec3(r, g, b), vec3(0.272, 0.534, 0.131))
                );

                vec3 finalColor = mix(color.rgb, sepia, intensity);
                gl_FragColor = vec4(finalColor, color.a);
            }
        ]],
        vertex = [[
            void main() {
                gl_Position = gl_Vertex;
                gl_TexCoord[0] = gl_MultiTexCoord0;
            }
        ]],
        uniformInt = {
            tex0 = 0,
        },
        uniformFloat = {
            intensity = 0.0
        }
    })

    return shader
end


function widget:ViewResize()
    vsx, vsy = gl.GetViewSizes()
    sepiaRenderTexture =
        gl.CreateTexture(
        vsx,
        vsy,
        {
        min_filter = GL.LINEAR, 
        mag_filter = GL.LINEAR,
        wrap_s = GL.CLAMP_TO_EDGE, 
        wrap_t = GL.CLAMP_TO_EDGE,
        }
    )

    sepiaUniformIntensity = gl.GetUniformLocation(sepiaShader, "intensity")
end

function widget:Initialize()
    vsx, vsy = gl.GetViewSizes()
    local boolWidgetActive = false
    for i=1, #TARGET_MAPS do
        local mapNameToSearch = string.lower(Game.mapName)
        local keyword =  TARGET_MAPS[i]
        if string.find(mapNameToSearch, keyword) then
            boolWidgetActive = true           
        end
    end
    
    if boolWidgetActive  then
        Spring.Echo("Sepia shader is not active")
        widgetHandler:RemoveWidget(self)
        return
    else
        Spring.Echo("Sepia shader is active")
    end

    sepiaShader = CreateSepiaShader()
    if not sepiaShader then
        Spring.Echo("Sepia shader compilation failed.")
        Spring.Echo(gl.GetShaderLog())
        widgetHandler:RemoveWidget(self)
        return
    end
    widget:ViewResize() 
end


function widget:Shutdown()
    if sepiaShader then gl.DeleteShader(sepiaShader) end
end

function widget:Update(dt)
    local hours,minutes, seconds, percent = getDayTime()
    if percent >= 0.25 and percent <= 0.75 then
        sepiaIntensity= math.sin((percent -0.25)* 2 *math.pi)*sepiaMax
    else
        sepiaIntensity = 0.0
    end
end

local function renderToTextureFunc()
    glTexRect(-1, -1, 1, 1, 0, 0, 1, 1)
end

function widget:DrawScreenEffects()
    glUseShader(sepiaShader)
    if sepiaUniformIntensity then
        glUniform(sepiaUniformIntensity, sepiaIntensity)
    end
    if sepiaRenderTexture then
        glRenderToTexture(sepiaRenderTexture, renderToTextureFunc)
        glTexture(0, sepiaRenderTexture)
        glTexRect(0, vsy, vsx, 0)
    end    
    glTexture(0, false)
    glUseShader(0)
end



