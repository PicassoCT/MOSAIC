local function Init(gl)
	if not gl then
		return false, "graphics init called without gl"
	end

	Spring.Echo("Instancing gl.InstanceVBOTable and tools")

	gl.InstanceVBOTable = gl.InstanceVBOTable or VFS.Include("modules/graphics/instancevbotable.lua")
	assert(gl.InstanceVBOTable, "Failed to load modules/graphics/instancevbotable.lua")

	gl.InstanceVBOIdTable = gl.InstanceVBOIdTable or VFS.Include("modules/graphics/instancevboidtable.lua")
	assert(gl.InstanceVBOIdTable, "Failed to load modules/graphics/instancevboidtable.lua")

	gl.LuaShader = gl.LuaShader or VFS.Include("modules/graphics/LuaShader.lua")
	assert(gl.LuaShader, "Failed to load modules/graphics/LuaShader.lua")

	gl.R2tHelper = gl.R2tHelper or VFS.Include("modules/graphics/r2thelper.lua")
	assert(gl.R2tHelper, "Failed to load modules/graphics/r2thelper.lua")

	return true
end

return {
	Init = Init,
}
