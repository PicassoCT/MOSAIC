----------------------------------------------------------------------------------------------------
--                         Slow Motion Shader                  
--                         Displays the Slow Motion Shader.                        
----------------------------------------------------------------------------------------------------
function widget:GetInfo()
        return {
                name      = "SlowMo Shader",
                desc      = "Tactical Grid Tool",
                author    = "a1983",
                date      = "21 12 2012",
                license   = "xxx",     
                layer     =  1,
                handler   = true,
   							enabled   = true  --  loaded by default?
								-- hidden 	  = true
        				}
end
----------------------------------------------------------------------------------------------------

local vsx, vsy = 1600, 1200
local screencopy
local shaderProgram
local boolShaderActive = false
local boolShaderActivePreviously = false

local glUseShader = gl.UseShader
local glCopyToTexture = gl.CopyToTexture
local glTexture = gl.Texture
local glTexRect = gl.TexRect
local glUniform = gl.Uniform
local startTimer = Spring.GetTimer()
local glGetUniformLocation = gl.GetUniformLocation
local diffTime = 0

flirshader = [[
uniform sampler2D screencopy;
uniform float resx;
uniform float resy;

float getIntensity(vec4 color) {
  vec3 intensityVector = color.rgb * vec3(0.831, 0.261, 0.491);
  return length(intensityVector);
}

vec2 skew(vec2 st) {
  vec2 r = vec2(0.0);
  r.x = 1.1547 * st.x;
  r.y = st.y + 0.5 * r.x;
  return r;
}

vec3 simplexGrid(vec2 st) {
  vec3 xyz = vec3(0.0);

  vec2 p = fract(skew(st));
  if (p.x > p.y) {
    xyz.xy = 1.0 - vec2(p.x, p.y - p.x);
    xyz.z = p.y;
  } else {
    xyz.yz = 1.0 - vec2(p.x - p.y, p.y);
    xyz.x = p.x;
  }

  return fract(xyz);
}

float clamp(float color) {
  if (color <= 1.0) {
    return color;
  }
  return 1.0;
}

void main() {
  vec2 resolution = vec2(resx, resy);
  int pixzelSize = 1.5;
  float pixelx = pixzelSize / resolution.x;
  float pixely = pixzelSize / resolution.y;

  vec2 texCoord = vec2(pixelx * int(gl_TexCoord[0].x / pixelx), pixely * int(gl_TexCoord[0].y / pixely));
  vec4 origColor = texture2D(screencopy, texCoord);
  float intensity = getIntensity(origColor);
  if (intensity < origColor.r) {
    intensity = origColor.r;
  }
  vec2 st = texCoord.xy / resolution.xy;

  gl_FragColor = vec4(1.0 - clamp(intensity),
    1.0 - clamp(intensity),
    1.0 - clamp(intensity - 0.125),
    1.0);
}
]]

local uniformInt = {
	  screencopy = 0,
	  resx = vsx,
	  resy = vsy
	}


local shaderTable = {
  fragment = flirshader,
  uniformInt = uniformInt,
  uniformFloat = {resx,resy}
}

local resxLocation = nil
local resyLocation = nil
function widget:Initialize()
	boolShaderActive = false
  	vsx, vsy = widgetHandler:GetViewSizes()
  	widget:ViewResize(vsx, vsy)
  	screencopy = gl.CreateTexture(vsx, vsy, {
	    border = false,
	    min_filter = GL.NEAREST,
	    mag_filter = GL.NEAREST,
		})
	
	if not gl.CreateShader then Spring.Echo("No gl.CreateShader existing") end
	
	if gl.CreateShader then		
		shaderProgram = gl.CreateShader(shaderTable)
		if shaderProgram then
			resxLocation = glGetUniformLocation(shaderProgram, "resx")
			resyLocation = glGetUniformLocation(shaderProgram, "resy")
		end
	else
		Spring.Echo("<Night Vision Shader>: GLSL not supported.")
	end
  
	if not shaderProgram and gl and gl.GetShaderLog then
    	Spring.Log(widget:GetInfo().name, LOG.ERROR, gl.GetShaderLog())
   		widgetHandler:RemoveWidget()
	end	

end

function widget:Shutdown()
	if shaderProgram then
		gl.DeleteShader(shaderProgram)
	end
end
	
function widget:ViewResize(viewSizeX, viewSizeY)
	vsx, vsy = viewSizeX, viewSizeY

screencopy = gl.CreateTexture(vsx, vsy, {
    border = false,
    min_filter = GL.NEAREST,
    mag_filter = GL.NEAREST,
	})
end

function widget:RecvLuaMsg(msg, playerID)

	if string.find(msg, "SlowMoShader") then
		if msg == "SlowMoShader_Active" then
			boolShaderActive = true	
			screencopy = gl.CreateTexture(vsx, vsy, {
			    border = false,
			    min_filter = GL.NEAREST,
			    mag_filter = GL.NEAREST,
				})	
			widget:ViewResize(vsx,vsy)	
		elseif msg == "SlowMoShader_Deactivated" then
			boolShaderActive = false			
		end
	end
end

local pausedTime = 0
local lastFrametime = Spring.GetTimer()
function widget:DrawScreenEffects()
	if  boolShaderActive == true then
	  glCopyToTexture(screencopy, 0, 0, 0, 0, vsx, vsy)
	  glTexture(0, screencopy)
	  glUseShader(shaderProgram)
	  glUniform(resyLocation, vsy)	 
	  glUniform(resxLocation, vsx)	 
	  glTexRect(0,vsy,vsx,0)
	  glTexture(0, false)
	  glUseShader(0)
	end

	if boolShaderActive ~= boolShaderActivePreviously then
 		widget:ViewResize(vsx,vsy)
 	end

	boolShaderActivePreviously = boolShaderActive
end
	
