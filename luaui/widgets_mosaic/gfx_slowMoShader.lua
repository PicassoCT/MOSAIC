----------------------------------------------------------------------------------------------------
--                                          Slow Motion Shader                                         --
--                         Displays the Slow Motion Shader.                          --
----------------------------------------------------------------------------------------------------
function widget:GetInfo()
        return {
                name      = "SlowMo Shader",
                desc      = "Tactical Grid Tool",
                author    = "a1983",
                date      = "21 12 2012",
                license   = "xxx",
                layer     = math.huge,
                handler   = true, -- used widget handlers
                enabled   = true, -- loaded by default,
				-- hidden 	  = true
        }
end
----------------------------------------------------------------------------------------------------

local vsx, vsy
local screencopy
local shaderProgram
local boolShaderActive = false
local boolShaderActivePreviously = false

local glUseShader = gl.UseShader
local glCopyToTexture = gl.CopyToTexture
local glTexture = gl.Texture
local glTexRect = gl.TexRect



	flirshader = [[
		uniform sampler2D screencopy;
		uniform vec2 u_resolution;
		uniform vec2 u_mouse;
		uniform float u_time;

		vec2 skew (vec2 st) {
		    vec2 r = vec2(0.0);
		    r.x = 1.1547*st.x;
		    r.y = st.y+0.5*r.x;
		    return r;
		}

		vec3 simplexGrid (vec2 st) {
		    vec3 xyz = vec3(0.0);

		    vec2 p = fract(skew(st));
		    if (p.x > p.y) {
			xyz.xy = 1.0-vec2(p.x,p.y-p.x);
			xyz.z = p.y;
		    } else {
			xyz.yz = 1.0-vec2(p.x-p.y,p.y);
			xyz.x = p.x;
		    }

		    return fract(xyz);
		}

		float getIntensity(vec4 color) {
		  vec3 intensityVector = color.rgb * vec3(0.491, 0.261, 0.831);
		  return length(intensityVector);
		}

		float clamp(float color) {
			if (color <= 1.0) return color;

		return 1.0;
		}
		
		void main() {
		  vec2 texCoord = vec2(gl_TextureMatrix[0] * gl_TexCoord[0]);
		  vec4 origColor = texture2D(screencopy, texCoord);
		  float intensity = getIntensity(origColor);
   		  vec2 st = gl_FragCoord.xy/u_resolution.xy;
    		  vec3 color = vec3(0.0);
   		  st*= 10.;
     		  color.rg = fract(skew(st));
                  color = simplexGrid(st);
		  if (intensity < origColor.r ) {intensity = origColor.r};


		  gl_FragColor = vec4(clamp(intensity+ color.r/100), clamp(intensity+ color.g/100), clamp(intensity + color.b/100 + 0.02), 1.0);
		}
	]]

	local uniformInt = {
	  screencopy = 0
	}

	local shaderTable = {
	  fragment = "",
	  uniformInt = uniformInt
	}
local  side  = "antagon"

function widget:Initialize()
	boolShaderActive = false
  	vsx, vsy = widgetHandler:GetViewSizes()
  	widget:ViewResize(vsx, vsy)
  	
	if not gl.CreateShader then Spring.Echo("No gl.CreateShader existing") end
	
	if gl.CreateShader then
		shaderTable.fragment= flirshader		
		shaderProgram = gl.CreateShader(shaderTable)
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
			if not boolShaderActivePreviously then
 				widget:ViewResize(vsx,vsy)
			end
			
		elseif msg == "SlowMoShader_Deactivated" then
			boolShaderActive = false			
		end
	end
end

function widget:DrawScreenEffects()
	if  boolShaderActive == true then
	  glCopyToTexture(screencopy, 0, 0, 0, 0, vsx, vsy)
	  glTexture(0, screencopy)
	  glUseShader(shaderProgram)
	  glTexRect(0,vsy,vsx,0)
	  glTexture(0, false)
	  glUseShader(0)
	end
	boolShaderActivePreviously = boolShaderActive
end
	
