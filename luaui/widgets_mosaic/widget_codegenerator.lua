function widget:GetInfo()
    return {
        name = "meta code generator",
        desc = "Generates widget code for a shader pair",
        author = "Picasso",
        date = "2023",
        license = "GNU GPL, v2 or later",
        layer = 3,
        enabled = true, --  loaded by default?
        handler = true
    }
end


--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
local codeGen = "luaui/default_widget_code_generated.lua"
local shaderDirectoryPath = "luaui/shaders/"
local fragmentFileName= "fragmentFileName.frag"
local vertexFileName= "fragmentFileName.vert"
local fragmentShader =  VFS.LoadFile(shaderDirectoryPath .. fragmentFileName) 
local vertexShader = VFS.LoadFile(shaderDirectoryPath .. vertexFileName)

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

local function parseShader(shaderCode)
    local uniforms = {}
    local varyings = {}

    -- Extract uniforms
    for uniformType, dataType, name in shaderCode:gmatch("uniform%s+(%S+)%s+(%S+)%s+([%w_]+)%s-;") do
        table.insert(uniforms, {type = uniformType, dataType = dataType, name = name})
    end

    -- Extract varyings
    for direction, dataType, name in shaderCode:gmatch("(%S+)%s+(%S+)%s+([%w_]+)%s-;") do
        table.insert(varyings, {direction = direction, dataType = dataType, name = name})
    end

    return uniforms, varyings
end


local vert_uniforms, vert_varyings = parseShader(vertexShader)
local frag_uniforms, frag_varyings = parseShader(fragmentShader)



local function codegen()
    Spring.Echo("Begin_Generated_WidgetCode_________________________________________________________________")

    codeGen = string.replace(codeGen, "VAR_VERT_CODE", vertexShader)
    codeGen = string.replace(codeGen, "VAR_FRAG_CODE", fragmentShader)

    local VAR_UNIFORM_INT = {}
    local VAR_UNIFORM_FLOAT = {}
    local VAR_UNIFORM_ALL = {}
    --Uniforms:
    for _, uniform in ipairs(uniforms) do
        Spring.Echo(string.format("Type: %s, DataType: %s, Name: %s", uniform.type, uniform.dataType, uniform.name))

    end

    --TODO

    --Varyings
    for _, varying in ipairs(varyings) do
        Spring.Echo(string.format("Direction: %s, DataType: %s, Name: %s", varying.direction, varying.dataType, varying.name))
    end



    local VAR_TEXTURE_LIST = {}
    local VAR_TEXTURE_INIT_CODE = ""



    local VAR_UPDATE_UNIFORMS_PER_FRAME = ""
    local VAR_SHADER_CALL_CODE_GENERATED = ""





    Spring.Echo(codeGen)
    Spring.Echo("_End_Generated_WidgetCode_________________________________________________________________")
end


function widget:Initialize()
    codegen()  
end

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
