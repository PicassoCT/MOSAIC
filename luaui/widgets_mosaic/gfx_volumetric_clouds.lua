
function widget:GetInfo()
  return {
    name      = "Volumetric Clouds",
    version   = 6,
    desc      = "Fog/Dust clouds that scroll with wind along the map's surface. Requires GLSL, expensive even with.",
    author    = "Anarchid, consulted and optimized by jK",
    date      = "november 2014",
    license   = "GNU GPL, v2 or later",
    layer     = -1,
    enabled   = false
  }
end

local enabled = true

local opacityMult = 1

local noiseTex = ":l:luaui/images/noisetextures/rgbnoise.png"
--local noiseTex = "LuaUI/Images/noisetextures/uniformnoise_128_rgba_1pixoffset.tga"
local noiseTex3D = "luaui/images/noisetextures/worley_rgbnorm_01_asum_128_v1.dds"
--https://github.com/beyond-all-reason/Beyond-All-Reason/tree/1e09d1ff75c1069ed0d77d5c655abdb32a2c5cf8/luaui  new version
--https://www.shadertoy.com/view/ssV3zh
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

local CloudDefs = {
	speed = 0.125, -- multiplier for speed of scrolling with wind
	--color    = {0.46, 0.32, 0.2}, -- diffuse color of the fog
	color    = {0.6,0.7,0.8}, -- diffuse color of the fog

	-- all altitude values can be either absolute, in percent, or "auto"
	height   = 1200, -- opacity of fog above and at this altitude will be zero
	bottom = 0, -- no fog below this altitude
	fade_alt = 800, -- fog will linearly fade away between this and "height", should be between height and bottom
	scale = 700, -- how large will the clouds be
	opacity = 0.85, -- what it says
	clamp_to_map = false, -- whether fog volume is sliced to fit map, or spreads to horizon
	sun_penetration = 50, -- how much does the sun penetrate the fog
}

local mapcfg = VFS.Include("mapinfo.lua")
if mapcfg and mapcfg.custom and mapcfg.custom.clouds then
	for k,v in pairs(mapcfg.custom.clouds) do
		CloudDefs[k] = v
	end
else
	--error("<Volumetric Clouds>: no custom defined mapinfo.lua cloud settings found")
end

local gnd_min, gnd_max = Spring.GetGroundExtremes()

local function convertAltitude(input, default)
	local result = input
	if input == nil or input == "auto" then
		result = default
	elseif type(input) == "string" and input:match("(%d+)%%") then
		local percent = input:match("(%d+)%%")
		result = gnd_max * (percent / 100)
	end
	--Spring.Echo(result)
	return result
end

CloudDefs.height = convertAltitude(CloudDefs.height, gnd_max*0.9)
CloudDefs.bottom = convertAltitude(CloudDefs.bottom, 0)
CloudDefs.fade_alt = convertAltitude(CloudDefs.fade_alt, gnd_max*0.8)

local cloudsHeight    = CloudDefs.height
local cloudsBottom    = CloudDefs.bottom or gnd_min
local cloudsColor     = CloudDefs.color
local cloudsScale     = CloudDefs.scale
local cloudsClamp     = CloudDefs.clamp_to_map or false
local speed    		  = CloudDefs.speed
local opacity    	  = CloudDefs.opacity or 0.3
local sunPenetration  = CloudDefs.sun_penetration or (-40.0)
local fade_alt    	  = CloudDefs.fade_alt
local fr,fg,fb        = unpack(cloudsColor)
local sunDir = {0,0,0}
local sunCol = {1,0,0}

assert(type(sunPenetration) == "number")
assert(type(cloudsClamp) == "boolean")
assert(type(cloudsHeight) == "number")
assert(type(cloudsBottom) == "number")
assert(type(fr) == "number")
assert(type(fg) == "number")
assert(type(fb) == "number")
assert(type(opacity) == "number")
assert(type(fade_alt) == "number")
assert(type(cloudsScale) == "number")
assert(type(speed) == "number")


--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
-- Automatically generated local definitions

local GL_NEAREST             = GL.NEAREST
local GL_ONE_MINUS_SRC_ALPHA = GL.ONE_MINUS_SRC_ALPHA
local GL_SRC_ALPHA           = GL.SRC_ALPHA
local glBlending             = gl.Blending
local glCopyToTexture        = gl.CopyToTexture
local glCreateShader         = gl.CreateShader
local glCreateTexture        = gl.CreateTexture
local glDeleteShader         = gl.DeleteShader
local glDeleteTexture        = gl.DeleteTexture
local glGetShaderLog         = gl.GetShaderLog
local glGetUniformLocation   = gl.GetUniformLocation
local glTexture              = gl.Texture
local glUniform              = gl.Uniform
local glUniformMatrix        = gl.UniformMatrix
local glUseShader            = gl.UseShader
local spGetCameraPosition    = Spring.GetCameraPosition
local spGetWind              = Spring.GetWind

local function spEcho(words)
	Spring.Echo('<Volumetric Clouds> '..words)
end

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
--
--  Extra GL constants
--

local GL_DEPTH_COMPONENT24 = 0x81A6

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

if (gnd_min < 0) then gnd_min = 0 end
if (gnd_max < 0) then gnd_max = 0 end
local vsx, vsy, vpx, vpy

local depthShader
local depthTexture
local fogTexture

local uniformEyePos
local uniformViewPrjInv
local uniformOffset
local uniformSundir
local uniformSunColor
local uniformTime

local offsetX = 0
local offsetY = 0
local offsetZ = 0

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

function widget:ViewResize()
	vsx, vsy, vpx, vpy = Spring.GetViewGeometry()

	if depthTexture then
		glDeleteTexture(depthTexture)
	end

	if fogTexture then
		glDeleteTexture(fogTexture)
	end

	depthTexture = glCreateTexture(vsx, vsy, {
		format = GL_DEPTH_COMPONENT24,
		min_filter = GL_NEAREST,
		mag_filter = GL_NEAREST,
	})

	fogTexture = glCreateTexture(vsx / 4, vsy / 4, {
		min_filter = GL.LINEAR,
		mag_filter = GL.LINEAR,
		wrap_s = GL.CLAMP_TO_EDGE,
		wrap_t = GL.CLAMP_TO_EDGE,
		fbo = true,
	})


	if depthTexture == nil then
		spEcho("Removing fog widget, bad depth texture")
		widgetHandler:RemoveWidget()
	end
end

widget:ViewResize()


--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
local shaderFilePath  = "luaui/widgets_mosaic/shaders/"
local fragSrc 				= VFS.LoadFile(shaderFilePath .. "fogShader.frag") 
local vertSrc 			  = VFS.LoadFile(shaderFilePath .. "fogShader.vert") 


--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

function widget:GetConfigData()
	return {opacityMult = opacityMult}
end

function widget:SetConfigData(data)
	if data.opacityMult ~= nil then
		opacityMult = data.opacityMult
	end
end


local function init()

	if depthShader then
		glDeleteShader(depthShader)
	end

	fragSrc = fragSrc:format(
		cloudsScale, cloudsHeight, cloudsBottom,
		cloudsColor[1], cloudsColor[2], cloudsColor[3],
		Game.mapSizeX, Game.mapSizeZ,
		fade_alt, opacity*opacityMult, sunPenetration
	)

	fragSrc = fragSrc:gsub("###DEPTH_CLIP01###", tostring((Platform and Platform.glSupportClipSpaceControl and 1) or 0))
	fragSrc = fragSrc:gsub("###CLAMP_TO_MAP###", tostring((cloudsClamp and 1) or 0))

	if enabled then
		depthShader = glCreateShader({
			vertex = vertSrc,
			fragment = fragSrc,
			uniformInt = {
				depthtex = 0,
				noisetex = 1,
				noise3dtex = 2,
				emitmaptex = 3,
        emitunittex = 4,
        modelDepthTex = 5,
			},
		})

		spEcho(glGetShaderLog())
		if not depthShader then
			spEcho("Bad shader, reverting to non-GLSL widget.")
			enabled = false
		else
			uniformEyePos       = glGetUniformLocation(depthShader, 'eyePos')
			uniformViewPrjInv   = glGetUniformLocation(depthShader, 'viewProjectionInv')
			uniformOffset       = glGetUniformLocation(depthShader, 'offset')
			uniformSundir       = glGetUniformLocation(depthShader, 'sundir')
			uniformSunColor     = glGetUniformLocation(depthShader, 'suncolor')
			uniformTime         = glGetUniformLocation(depthShader, 'time')
		end
	end
end


function widget:Initialize()

	WG['clouds'] = {}
	WG['clouds'].getOpacity = function()
		return opacityMult
	end
	WG['clouds'].setOpacity = function(value)
		opacityMult = value
		init()
	end

	if not glCreateShader then
		enabled = false
	end

	init()

	if not enabled then
		widgetHandler:RemoveWidget()
		return
	end

	if Game.windMax < 5 then
		widgetHandler:RemoveWidget()
		return
	end
end

function widget:Shutdown()
	glDeleteTexture(depthTexture)
	glDeleteTexture(fogTexture)
	if glDeleteShader then
		glDeleteShader(depthShader)
	end
	glDeleteTexture(noiseTex)
end


local function renderToTextureFunc()
	-- render a full screen quad
	glTexture(0, depthTexture)
	glTexture(0, false)
	glTexture(1, noiseTex)
	glTexture(1, false)
	glTexture(2, noiseTex3D)
	glTexture(2, false)
	glTexture(3, "$map_gbuffer_emittex")
	glTexture(4, "$model_gbuffer_emittex")
	glTexture(5, "$model_gbuffer_zvaltex")

	gl.TexRect(-1, -1, 1, 1, 0, 0, 1, 1)
	glTexture(3, false)
	glTexture(4, false)
	glTexture(5, false)
end

local function DrawFogNew()
	-- copy the depth buffer
	glCopyToTexture(depthTexture, 0, 0, vpx, vpy, vsx, vsy) --FIXME scale down?

	-- setup the shader and its uniform values
	glUseShader(depthShader)

	-- set uniforms
	glUniform(uniformEyePos, spGetCameraPosition())
	glUniform(uniformOffset, offsetX, offsetY, offsetZ)

	glUniform(uniformSundir, sunDir[1], sunDir[2], sunDir[3])
	glUniform(uniformSunColor, sunCol[1], sunCol[2], sunCol[3])

	glUniform(uniformTime, Spring.GetGameSeconds() * speed)

	glUniformMatrix(uniformViewPrjInv,  "viewprojectioninverse")

	-- TODO: completely reset the texture before applying shader
	-- TODO: figure out why it disappears in some places
	-- maybe add a switch to make it high-res direct-render
	gl.RenderToTexture(fogTexture, renderToTextureFunc)

	glUseShader(0)
end


--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

function widget:GameFrame()
	local dx,dy,dz = spGetWind()
	offsetX = offsetX-dx*speed
	offsetY = offsetY-0.25-dy*0.25*speed
	offsetZ = offsetZ-dz*speed

	sunDir = {gl.GetSun('pos')}
	sunCol = {gl.GetSun('specular')}
end

local function DrawClouds()
	glBlending(GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA)
	gl.MatrixMode(GL.MODELVIEW)
	gl.PushMatrix()
	gl.LoadIdentity()

		gl.MatrixMode(GL.PROJECTION)
		gl.PushMatrix()
		gl.LoadIdentity()

			glTexture(fogTexture)
			gl.TexRect(-1, -1, 1, 1, 0, 0, 1, 1)
			glTexture(false)

		gl.MatrixMode(GL.PROJECTION)
		gl.PopMatrix()

	gl.MatrixMode(GL.MODELVIEW)
	gl.PopMatrix()
end

--[[
function widget:DrawScreen()
	glBlending(GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA) -- in theory not needed but sometimes evil widgets disable it w/o reenabling it
	glTexture(fogTexture)
	gl.TexRect(0,0,vsx,vsy,0,0,1,1)
	glTexture(false)
end
]]--

function widget:DrawWorld()
	DrawClouds()
end

function widget:DrawUnits()
	--Render bake down into ground AO shadows + lights
	-- only on ground visible by camera with orthogonal top down camera
end

function widget:DrawWorldPreUnit()
	glBlending(false)
	DrawFogNew()
	--DrawClouds()
	glBlending(true)
end
