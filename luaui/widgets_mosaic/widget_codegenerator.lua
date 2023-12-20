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
    local VAR_UNIFORM_INT = "{"
	for name, dataset in pairs(uniformType_Name_DataMap["int"]) do
		VAR_UNIFORM_INT = VAR_UNIFORM_INT .."\n"..name.." = TODO_AddInitial_Int_Value, "
	end
	VAR_UNIFORM_INT= VAR_UNIFORM_INT.."}"
	codeGen = string.replace(codeGen, "VAR_UNIFORM_INT", VAR_UNIFORM_INT)
	
    local VAR_UNIFORM_FLOAT = "{"
	for name, dataset in pairs(uniformType_Name_DataMap["float"]) do
		VAR_UNIFORM_FLOAT = VAR_UNIFORM_FLOAT .."\n"..name.." = TODO_AddInitial_Float_Value, "
	end
	VAR_UNIFORM_FLOAT= VAR_UNIFORM_FLOAT.."}"
	codeGen = string.replace(codeGen, "VAR_UNIFORM_FLOAT", VAR_UNIFORM_FLOAT)
	
    local VAR_UNIFORM_ALL = {}
	
	local DRAWCALLNAME = "DrawScreenEffects" --TODO Define and fallback
	codeGen = string.replace(codeGen, "DRAWCALLNAME", DRAWCALLNAME)
		
    local VAR_TEXTURE_LIST = "local textureName = nil"
	
	local VAR_TEXTURE_INIT_CODE = ""
	local template = [[
	  NAME =
        gl.CreateTexture(
        vsx,
        vsy,
        {
        fbo = true, 
        min_filter = GL.LINEAR, 
        mag_filter = GL.LINEAR,
        wrap_s = GL.CLAMP_TO_EDGE, 
        wrap_t = GL.CLAMP_TO_EDGE,
        }
    )
    if NAME == nil then
        Spring.Echo("No NAME - aborting")
        widgetHandler:RemoveWidget(self)
        return 
    else
        widgetHandler:UpdateCallIn("DRAWCALLNAME")
    end
	]]
	
	for name, data in pairs(textureName_dataMap) do
		VAR_TEXTURE_INIT_CODE = VAR_TEXTURE_INIT_CODE.."\n"..(template.replace("NAME", name).replace("DRAWCALLNAME",DRAWCALLNAME))
	end
	codeGen = string.replace(codeGen, "VAR_TEXTURE_INIT_CODE", VAR_TEXTURE_INIT_CODE)
	

    local VAR_UPDATE_UNIFORMS_PER_FRAME = "TODO"
	local VAR_SHADER_CALL_CODE_GENERATED_START = "
		glTexture(barGlowCenterTexture)"
		for name, data in pairs(textureName_dataMap) do
		VAR_SHADER_CALL_CODE_GENERATED_START = VAR_TEXTURE_INIT_CODE.. "glTexture("..name..")"
	end
	codeGen = string.replace(codeGen, "VAR_SHADER_CALL_CODE_GENERATED_START", VAR_SHADER_CALL_CODE_GENERATED_START)
	
	local VAR_SHADER_CALL_CODE_GENERATED_END = "glTexture(false)"
    local VAR_SHADER_CALL_CODE_GENERATED = ""

    Spring.Echo(codeGen)
    Spring.Echo("End__Generated_WidgetCode_________________________________________________________________")
end


function widget:Initialize()
    codegen()  
end

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
