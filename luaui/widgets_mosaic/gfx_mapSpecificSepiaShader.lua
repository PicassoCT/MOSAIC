function widget:GetInfo()
    return {
        name = "Sepia Shader Filter",
        desc = "provides the dubai map with a sepia tone colour grading shader",
        author = "ChatGPT",
        date = "2025-06-28",
        license = "MIT",
        layer = math.huge,
        enabled = true,
    }
end

-- CONFIGURATION
local TARGET_MAPS = {"dubai"}
local DAYLENGTH             = 28800
local function getDayTime()
    local morningOffset = (DAYLENGTH / 2)
    local Frame = (Spring.GetGameFrame() + morningOffset) % DAYLENGTH
    local percent = Frame / DAYLENGTH
    local hours = math.floor((Frame / DAYLENGTH) * 24)
    local minutes = math.ceil((((Frame / DAYLENGTH) * 24) - hours) * 60)
    local seconds = 60 - ((24 * 60 * 60 - (hours * 60 * 60) - (minutes * 60)) % 60)
    return hours, minutes, seconds, percent
end

-- Shader variables
local sepiaShader
local screenShader

-- FBO and texture
local fbo, tex

local glCreateShader = gl.CreateShader
local glUseShader = gl.UseShader
local glDeleteShader = gl.DeleteShader
local glTexture = gl.Texture
local glTexRect = gl.TexRect
local glBlending = gl.Blending
local glUniformInt = gl.UniformInt
local glUniform = gl.Uniform
local glUniformMatrix = gl.UniformMatrix
local sepiaMax = 0.75
local sepiaUniformIntensity
local sepiaIntensity = sepiaMax -- change this dynamically as needed (0.0 to 1.0)

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
    })

    return shader
end

function widget:Initialize()
    for i=1, #TARGET_MAPS do
        if string.find(string.lower(Game.mapName), TARGET_MAPS[i]) then
            widgetHandler:RemoveWidget(self)
            return
        end

    end

    sepiaShader = CreateSepiaShader()
    if not sepiaShader then
        Spring.Echo("Sepia shader compilation failed.")
        Spring.Echo(gl.GetShaderLog())
        widgetHandler:RemoveWidget(self)
        return
    end

    sepiaUniformIntensity = gl.GetUniformLocation(sepiaShader, "intensity")
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

function widget:DrawScreenEffects()
    gl.UseShader(sepiaShader)
    if sepiaUniformIntensity then
        gl.Uniform(sepiaUniformIntensity, sepiaIntensity)
    end
    gl.Texture(0, "$framebuffer")
    gl.TexRect(-1, -1, 1, 1)
    gl.Texture(0, false)
    gl.UseShader(0)
end