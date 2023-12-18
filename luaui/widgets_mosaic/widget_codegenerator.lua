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
local vert_uniforms, vert_varyings = parseShader(vertexShader)
local frag_uniforms, frag_varyings = parseShader(fragmentShader)
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
local textureName_dataMap = {}
local uniformType_Name_DataMap = {}
local Name_DataMap = {}
local function registerUniform(data)
	Name_DataMap[data.name] = data
	local typeD = data.dataType
	if typeD == "sampler2D" then
		textureName_dataMap[data.name] = data
	else
		if uniformType_Name_DataMap[typeD] == nil then uniformType_Name_DataMap[typeD] = {}
		uniformType_Name_DataMap[typeD][data.name] = data
	end
end

local function codegen()
    Spring.Echo("Begin_Generated_WidgetCode_________________________________________________________________")

    codeGen = string.replace(codeGen, "VAR_VERT_CODE", vertexShader)
    codeGen = string.replace(codeGen, "VAR_FRAG_CODE", fragmentShader)

	
    --Uniforms:
    for _, uniform in ipairs(vert_uniforms) do
		registerUniform(unfiorm)
        Spring.Echo(string.format("Type: %s, DataType: %s, Name: %s", vert_uniforms.type, vert_uniforms.dataType, vert_uniforms.name))
    end	
	for _, uniform in ipairs(frag_uniforms) do
		registerUniform(unfiorm)
        Spring.Echo(string.format("Type: %s, DataType: %s, Name: %s", frag_uniforms.type, frag_uniforms.dataType, frag_uniforms.name))
    end
	
	--TODO Code generated
    local VAR_UNIFORM_INT = {}
    local VAR_UNIFORM_FLOAT = {}
    local VAR_UNIFORM_ALL = {}


	-- Varyings only check the back and forth is in order
    --Varyings
    for _, varying in ipairs(vert_varyings) do
        Spring.Echo(string.format("Direction: %s, DataType: %s, Name: %s", vert_varyings.direction, vert_varyings.dataType, vert_varyings.name))
		--TODO assert as in in varying_frag
    end
	for _, varying in ipairs(frag_varyings) do
        Spring.Echo(string.format("Direction: %s, DataType: %s, Name: %s", frag_varyings.direction, frag_varyings.dataType, frag_varyings.name))
    end

    local VAR_TEXTURE_LIST = {}
    local VAR_TEXTURE_INIT_CODE = ""

    local VAR_UPDATE_UNIFORMS_PER_FRAME = ""
    local VAR_SHADER_CALL_CODE_GENERATED = ""

    Spring.Echo(codeGen)
    Spring.Echo("End__Generated_WidgetCode_________________________________________________________________")
end


function widget:Initialize()
    codegen()  
end

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
