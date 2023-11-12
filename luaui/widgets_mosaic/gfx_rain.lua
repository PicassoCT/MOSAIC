
function widget:GetInfo()
  return {
    name      = "Rain",
    desc      = "Lets it automaticly rain",
    author    = "Picasso",
    date      = "2023",
    license   = "GNU GPL, v2 or later",
    layer     = 0,
    enabled   = true  --  loaded by default?
  }
end

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

-- /rain    -- toggles snow on current map (also remembers this)

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

local vsx,vsy = Spring.GetViewGeometry()

-- > debugEchoT(


local shader

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
local spGetGameFrame       = Spring.GetGameFrame
local glBeginEnd           = gl.BeginEnd
local glVertex             = gl.Vertex
local glColor              = gl.Color
local glBlending           = gl.Blending
local glTranslate          = gl.Translate
local glCallList           = gl.CallList
local glDepthTest          = gl.DepthTest
local glCopyToTexture			 = gl.CopyToTexture
local glCreateList         = gl.CreateList
local glDeleteList         = gl.DeleteList
local glTexture            = gl.Texture
local glGetShaderLog       = gl.GetShaderLog
local glCreateShader       = gl.CreateShader
local glDeleteShader       = gl.DeleteShader
local glUseShader          = gl.UseShader
local glUniformMatrix      = gl.UniformMatrix
local glUniformInt         = gl.UniformInt
local glUniform            = gl.Uniform
local glGetUniformLocation = gl.GetUniformLocation
local glGetActiveUniforms  = gl.GetActiveUniforms
local glBeginEnd = gl.BeginEnd
local glPointSprite = gl.PointSprite
local glPointSize = gl.PointSize
local glPointParameter = gl.PointParameter
local glResetState = gl.ResetState
local GL_POINTS = GL.POINTS
local boolRainActive = false
local pausedTime = 0
local lastFrametime = Spring.GetTimer()
local raincanvasTex = nil
local depthTex = nil
local startOsClock

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------


function init()
	
	-- abort if not enabled
	if enabled == false then return end
	
	if (glCreateShader == nil) then
		Spring.Echo("[Snow widget:Initialize] no shader support")
		widgetHandler:RemoveWidget(self)
		return
	end
	--https://www.shadertoy.com/view/wd2GDG inspiration
	local fragmentShader = [[
											  	#version 150 compatibility											 
											  	uniform sampler2D raincanvasTex;
										  		uniform sampler2D depthTex;
											  	uniform float time;		
													uniform vec3 camWorldPos;
													uniform vec2 viewPortSize;
											
									in Data {
											  		vec4 accumulatedLightColorRay;
											  	 };
													void main(void)
													{
														vec2 uv = gl_FragCoord.xy / viewPortSize;
														gl_FragColor = texture2D(depthTex, uv); 
													}
												]]

	local vertexShader = [[
										  	#version 150 compatibility
										  	uniform sampler2D raincanvasTex;
										  	uniform sampler2D depthTex;
												uniform float time;		

												uniform vec3 camWorldPos;
												uniform vec2 viewPortSize;

								out Data {
											  		vec4 accumulatedLightColorRay;
											  	};
											  
											vec4 rainPixel(vec3 worldPos, float time, int randSeed)
											{
												//rainPixel
											return vec4(1.0,0.0,0.0,0.5);
												//Check for lightsourcecloseness
											}	

											  void rainRayPixel(vec2 camPixel, vec3 worldVector, float time)
											  {
												vec3 worldPosPixel = vec3 (1.0,2.0,3.0);
												int randSeed= 42;
											  	vec4 accumulatedColor = vec4(0.0, 0.0,0.0,0.0);
											  	//for depthresolution 
											  	//{
											  	    accumulatedColor = accumulatedColor + rainPixel(worldPosPixel,  time, randSeed);
												//}
											  }											  

												void main(void)
												{
											
													vec4 eyePos = gl_ModelViewMatrix * vec4(gl_Vertex.xyz, 1.0);
													gl_Position = gl_ProjectionMatrix * eyePos;
												}
											  ]]
local uniformInt = {
	  raincanvasTex = 0,
	  depthTex = 1
	}

local shader = glCreateShader({
		fragment = fragmentShader,
		vertex = vertexShader,
		uniformInt = uniformInt,
		uniform = {
			time   = diffTime,
			scale  = 0,
			camWorldPos = {0,0,0},
		},
		uniformFloat = {
			viewPortSize = {vsx, vsy},
		},
	})

	if (shader == nil) then
		Spring.Echo("[Rain widget:Initialize] particle shader compilation failed")
		Spring.Echo(glGetShaderLog())
		widgetHandler:RemoveWidget(self)
		return
	end
	
	shaderTimeLoc			= glGetUniformLocation(shader, 'time')
	shaderCamPosLoc		= glGetUniformLocation(shader, 'camWorldPos')
end


function widget:Initialize()
	init()
	vsx, vsy = widgetHandler:GetViewSizes()
	widget:ViewResize(vsx, vsy)
	startOsClock = os.clock()
end

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
 local function getDetermenisticHash()
  local accumulated = 0
  local mapName = Game.mapName
  local mapNameLength = string.len(mapName)

  for i=1, mapNameLength do
    accumulated = accumulated + string.byte(mapName,i)
  end

  accumulated = accumulated + Game.mapSizeX
  accumulated = accumulated + Game.mapSizeZ
  return accumulated
end

local function isRainyArea()
		return getDetermenisticHash() % 2 == 0 
end

local DAYLENGTH = 28800
local function getDayTime()
				local morningOffset = (DAYLENGTH / 2)
				local Frame = (Spring.GetGameFrame() + morningOffset) % DAYLENGTH
				local percent = Frame / DAYLENGTH
				local hours = math.floor((Frame / DAYLENGTH) * 24)
				local minutes = math.ceil((((Frame / DAYLENGTH) * 24) - hours) * 60)
				local seconds = 60 - ((24 * 60 * 60 - (hours * 60 * 60) - (minutes * 60)) % 60)
				return hours, minutes, seconds, percent
			end


 local boolRainyArea
 local function isRaining()
                if boolRainyArea == nil then
                    boolRainyArea = isRainyArea()
                end
                if not boolRainyArea then return false end

                local hours = getDayTime() 
                local gameFrames = Spring.GetGameFrame()
                local dayNr = gameFrames/ DAYLENGTH

                return dayNr % 3 < 1.0 and (hours > 18 or hours < 7)
   end

function widget:GameFrame(gameFrame)
		boolRainActive  = isRaining()
end

function widget:Shutdown()
	glDeleteTexture(0, raincanvasTex)
	glDeleteTexture(1, depthTex)
	enabled = false
end

function widget:ViewResize(viewSizeX, viewSizeY)
	vsx, vsy = viewSizeX, viewSizeY

	raincanvasTex = gl.CreateTexture(vsx, vsy, {
	    border = false,
	    min_filter = GL.NEAREST,
	    mag_filter = GL.NEAREST,
		})

  depthTex = gl.CreateTexture(vsx,vsy, {
            border = false,
            format = GL_DEPTH_COMPONENT24,
            min_filter = GL.NEAREST,
            mag_filter = GL.NEAREST,
        })
end

function widget:Shutdown()
	if glDeleteTexture then
		glDeleteTexture(raincanvasTex or "")
		glDeleteTexture(depthTex or "")
	end

	if shader then
		gl.DeleteShader(shader)
	end
end
	

function widget:DrawWorld()
	--if not boolRainActive then return end

	local _, _, isPaused = Spring.GetGameSpeed()
	if isPaused then
		pausedTime = pausedTime + Spring.DiffTimers(Spring.GetTimer(), lastFrametime)
	end

	lastFrametime = Spring.GetTimer()
	if os.clock() - startOsClock > 0.5 then		-- delay to prevent no textures being shown
		if shader ~= nil  then
			glCopyToTexture("depthTex", 0, 0, 0, 0, vsx, vsy) -- the original screen image	
			camX,camY,camZ = Spring.GetCameraPosition()
			diffTime = Spring.DiffTimers(lastFrametime, startTimer) - pausedTime

			glUniform(shaderTimeLoc,diffTime * 1)
			glUniform(shaderCamPosLoc, camX, camY, camZ)
			glTexture(0, raincanvasTex)
			glTexture(1, depthTex)
	  	glUseShader(shader)	
	  	glBlending(GL_ONE, GL_ONE_MINUS_SRC_ALPHA)  
	  	glTexRect(0,vsy,vsx,0)	  
			glBlending(GL.SRC_ALPHA, GL.ONE)						
			local osClock = os.clock()
			local timePassed = osClock - prevOsClock
			prevOsClock = osClock
			glTexture(0, false)
			glTexture(1, false)
			glResetState()
			glUseShader(0)
		end
	end
end

function widget:ViewResize(newX,newY)
	vsx, vsy = newX, newY
end

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
