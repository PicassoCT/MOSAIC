local GL_RG16F = 0x822F
local GL_COLOR_ATTACHMENT0_EXT = 0x8CE0

local function new(class, textureSize)
	return setmetatable(
	{
		textureSize = textureSize or 512,
		brdfShader = nil,
		brdfTexture = nil,
		brdfFBO = nil,
	}, class)
end

local genBrdfLut = setmetatable({}, {
	__call = function(self, ...) return new(self, ...) end,
	})
genBrdfLut.__index = genBrdfLut

function genBrdfLut:Initialize()
	self.brdfTexture = gl.CreateTexture(self.textureSize, self.textureSize, {
		format = GL_RG16F,
		border = false,
		min_filter = GL.LINEAR,
		mag_filter = GL.LINEAR,
		wrap_s = GL.CLAMP_TO_EDGE,
		wrap_t = GL.CLAMP_TO_EDGE,
	})

	if not self.brdfTexture then
		Spring.Echo("genBrdfLut: [%s] brdfTexture creation error:\n%s")
	end

	self.brdfFBO = gl.CreateFBO({
		color0 = self.brdfTexture,
		drawbuffers = {GL_COLOR_ATTACHMENT0_EXT},
	})

	if not self.brdfFBO then
		Spring.Echo("genBrdfLut: [%s] FBO creation error:\n%s")
	end

	self.brdfShader = gl.CreateShader({
		vertex = VFS.LoadFile("ModelMaterials/Shaders/genBrdfLut.vert"),
		fragment = VFS.LoadFile("ModelMaterials/Shaders/genBrdfLut.frag"),
		uniformInt = {
			texSize = {self.textureSize, self.textureSize},
		},
	})

	local shLog = gl.GetShaderLog() or ""

	if not self.brdfShader then
		Spring.Echo(string.format("genBrdfLut: [%s] shader errors:\n%s", "genBrdfLut", shLog))
		return false
	elseif shLog ~= "" then
		Spring.Echo(string.format("genBrdfLut: [%s] shader warnings:\n%s", "genBrdfLut", shLog))
	end
end

function genBrdfLut:GetTexture()
	return self.brdfTexture
end

function genBrdfLut:Execute(isScreenSpace)
	if gl.IsValidFBO(self.brdfFBO) then
		gl.ActiveShader(self.brdfShader, function ()
			gl.ActiveFBO(self.brdfFBO, function()
				gl.DepthTest(false)
				gl.Blending(false)
				if isScreenSpace then
					gl.TexRect(0, 0, self.textureSize, self.textureSize)
				else
					gl.TexRect(-1, -1, 1, 1)
				end
				--gl.SaveImage( 0, 0, self.textureSize, self.textureSize, string.format("brdf_%s.png", select(1, Spring.GetGameFrame())) )
			end)
		end)
	end
end


function genBrdfLut:Finalize()
	gl.DeleteFBO(self.brdfFBO)
	gl.DeleteTexture(self.brdfTexture)
	gl.DeleteShader(self.brdfShader)
end

return genBrdfLut