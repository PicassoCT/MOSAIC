[[
function widget:GetInfo()
    return {
        name = "Name of the widget",
        desc = "Auto generated widget stub for a shader",
        author = "Your code",
        date = "2023",
        license = "GNU GPL, v2 or later",
        layer = math.huge,
        enabled = true, --  loaded by default?
        handler = true
    }
end

--------------------------------------------------------------------------------
--Localisations and speedups

local spGetGameFrame = Spring.GetGameFrame
local glBeginEnd = gl.BeginEnd
local glVertex = gl.Vertex
local glBlending = gl.Blending
local glDepthTest = gl.DepthTest
local glCopyToTexture = gl.CopyToTexture
local glCreateList = gl.CreateList
local glDeleteList = gl.DeleteList
local glTexture = gl.Texture
local glGetShaderLog = gl.GetShaderLog
local glCreateShader = gl.CreateShader
local glDeleteShader = gl.DeleteShader
local glUseShader = gl.UseShader
local glUniformMatrix = gl.UniformMatrix
local glUniformInt = gl.UniformInt
local glUniform = gl.Uniform
local glGetUniformLocation = gl.GetUniformLocation
local glResetState = gl.ResetState



--------------------------------------------------------------------------------
-- Variables
local vsx, vsy = 0,0
local vertexShaderCode = VAR_VERT_CODE
local fragmentShaderCode = VAR_FRAG_CODE
local uniformInt = VAR_UNIFORM_INT
local uniformFloat = VAR_UNIFORM_FLOAT
local uniForms = VAR_UNIFORM_ALL
local shaderProgram = nil

VAR_TEXTURE_LIST

if not gl.CreateShader then
    Spring.Echo(GetInfo().name .. ": GLSL not supported.")
    return
end

local function ReInitializeTextures()
    VAR_TEXTURE_INIT_CODE

     if screencopy then
        widgetHandler:UpdateCallIn("DrawScreenEffects")
    else
        Spring.Log(widget:GetInfo().name, LOG.ERROR, "CreateTexture failed!")
        widgetHandler:RemoveCallIn("DrawScreenEffects")
    end
end


local function Initialization()
    shaderProgram = gl.CreateShader({
        uniform = uniForms,
        uniformInt = uniformInt,
        unfiormFloat = unfiormFloat,
        fragment = fragmentShaderCode,
        vertex = vertexShaderCode,
    })
    if not shaderProgram then
        Spring.Log(widget:GetInfo().name, LOG.ERROR, gl.GetShaderLog())
        return
    end

    ReInitializeTextures()
end

function widget:ViewResize(viewSizeX, viewSizeY)
    vsx, vsy = viewSizeX, viewSizeY
    ReInitializeTextures()   
end


function widget:Initialize()
    Initialization()
    vsx, vsy = widgetHandler:GetViewSizes()
    widget:ViewResize(vsx, vsy)
end

function widget:Shutdown()
    gl.DeleteShader(shaderProgram)
    if screencopy then
        gl.DeleteTexture(screencopy)
    end
end

function widget:DrawScreenEffects()
    VAR_UPDATE_UNIFORMS_PER_FRAME

    VAR_SHADER_CALL_CODE_GENERATED
end
]]