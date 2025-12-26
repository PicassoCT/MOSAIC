local function Init(gl)
	if gl then
		Spring.Echo("Instancing gl.InstanceVBOTable and tools")
		gl.InstanceVBOTable = VFS.Include("modules/graphics/instancevbotable.lua")
		assert(gl.InstanceVBOIdTable)
		gl.InstanceVBOIdTable = VFS.Include("modules/graphics/instancevboidtable.lua")
		gl.LuaShader = VFS.Include("modules/graphics/LuaShader.lua")
		gl.R2tHelper = VFS.Include("modules/graphics/r2thelper.lua")
	end
end

return {
	Init = Init,
}

