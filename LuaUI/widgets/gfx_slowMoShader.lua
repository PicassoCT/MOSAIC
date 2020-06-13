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
                --handler   = true, -- used widget handlers
                enabled   = true  -- loaded by default,
				--hidden 	  = true
        }
end
----------------------------------------------------------------------------------------------------

local vsx, vsy
local screencopy
local shaderProgram

local glUseShader = gl.UseShader
local glCopyToTexture = gl.CopyToTexture
local glTexture = gl.Texture
local glTexRect = gl.TexRect

--colours
--blueblack (0,0,0.02)   -- fade % 				|15
--blueborder (0.02,0.0, 0.2)	-- 5 %				|20
--blueblack (0,0,0.02) 		-- fade				|30
--innerblue (0.2, 0.15, 0.56 -- fade			|40
--lightblueborder(0.2, 0.4, 0.8) - 5 % no fade	|45
--bluepink (0.4, 0.2, 0.65)						|55
--pin (0.7,0.2,0.45)							|65
--red( 0.85,0.275,0.1)							|75
--greenborder (0.7,0.9,0.45) 5%					|80
--orange(0.95,0.4,0.05)							|85
--yellow (1,0.93, 0.65)							|90
--darkredborder(0.52,0.23,0.23)					|95
--white(1,1,1)									|100




ColourTable={
	[1] = {bGradient= true, r= 0.0, g= 0.0, b =0.35},
	[15] = {bGradient= true, r=0.0, g=0.0, b =0.02},
	[16] = {bGradient= false, r= 0.02, g=0.0, b =0.2},
	[20] = {bGradient= false, r= 0.02, g=0.0, b =0.2},
	[21] = {bGradient= true, r= 0.0, g= 0.0, b =0.02},
	[30] = {bGradient= true, r= 0.0, g= 0.0, b =0.2},
	[31] = {bGradient= true, r= 0.0, g= 0.0, b =0.35},
	[40] = {bGradient= true, r= 0.2, g= 0.15, b =0.56},
	[41] = {bGradient= false, r= 0.2, g=0.4, b =0.8},
	[45] = {bGradient= false, r= 0.2, g=0.4, b =0.8},
	[55] = {bGradient= true, r= 0.4, g=0.2, b =0.65},
	[65] = {bGradient= true, r= 0.0, g=0.0, b =0.02},
	[75] = {bGradient= true, r= 0.0, g=0.0, b =0.22},
	[76] = {bGradient= false, r= 0.7, g= 0.9, b =0.45},
	[80] = {bGradient= false, r= 0.7, g= 0.9, b =0.45},
	[81] = {bGradient= true, r= 0.85, g= 0.275, b =0.1},
	[85] = {bGradient= true, r= 0.95, g= 0.4, b =0.05},
	[90] = {bGradient= true, r= 1.0, g= 0.93, b =0.65},
	[91] = {bGradient= false, r= 0.5, g= 0.23, b =0.23},
	[94] = {bGradient= false, r= 0.5, g= 0.23, b =0.23},
	[95] = {bGradient= true, r= 1.0, g= 0.93, b =0.65},
	[100] = {bGradient= true, r= 1.0, g= 1.0, b = 1.0}
}



	function colourSelector(Type, r,g,b)
		if Type == "R" then return r end
		if Type == "G" then return g end
		if Type == "B" then return b end
	end

	function triMix(val,t1,t2)
		cval= 1.0 -val
		return (t2.r*cval) + (t1.r* val), (t2.g*cval) + (t1.g* val), (t2.b*cval ) + ( t1.b* val)
	end

	function getRGB(Type, index)
		lastFoundIndex=1
		upperIndex=1
	
		for i=1, 100 do
			if ColourTable[i] then
				if index == i  then
					return colourSelector(Type,ColourTable[i].r,ColourTable[i].g,ColourTable[i].b)
				end

				if index > i then
					lastFoundIndex = math.min(100,math.max(1,i))
				end

				if index < i then
				upperIndex = math.min(100,math.max(1,i))

					if  false== true and (ColourTable[lastFoundIndex].bGradient == false and ColourTable[upperIndex].bGradient == false)then
						return colourSelector(Type,ColourTable[lastFoundIndex].r,ColourTable[lastFoundIndex].g,ColourTable[lastFoundIndex].b)
					end

					factor= (index-lastFoundIndex)/(upperIndex - lastFoundIndex)
					factor =  math.min(1.0,math.max(0.0,factor))
					local r,g,b = triMix(factor,ColourTable[lastFoundIndex],ColourTable[upperIndex])
					return colourSelector(Type, r,g,b)
				end
			end
		end

	return colourSelector(Type, 0.0,0.25,0.75)
	end



	tacVision = [[
		uniform sampler2D screencopy;
		
		float getIntensity(vec4 color) {
		  vec3 intensityVector = color.rgb * vec3(0.491, 0.261, 0.831);
		  return length(intensityVector);
		}
		
		void main() {
		  vec2 texCoord = vec2(gl_TextureMatrix[0] * gl_TexCoord[0]);
		  vec4 origColor = texture2D(screencopy, texCoord);
		  float fintensity = getIntensity(origColor);
		  int IntTensity ;
		fintensity= fintensity*1.2;
		  if (fintensity > 1.0) {fintensity = 1.0;}
		

		
	 	fintensity = floor(fintensity *100.0);

		IntTensity =  int(fintensity);
		

		 ]]
		
		for i=1, 100, 1 do
			r,g,b = getRGB("R", i).."",getRGB("G", i).."",getRGB("B", i)..""
			if not string.find(r,".") then r=r..".0" end
			if not string.find(g,".") then g=g..".0" end
			if not string.find(b,".") then b=b..".0" end
			tacVision = tacVision.. "if ( IntTensity ==".. i.." ) { gl_FragColor = vec4("..r.." ,"..g.." ,"..b..",0.9);  } \n"	
		end
		
		tacVision = tacVision .. [[
		
		}
		]]
		
		


	
	nightvision = [[
		uniform sampler2D screencopy;
		
		float getIntensity(vec4 color) {
		  vec3 intensityVector = color.rgb * vec3(0.491, 0.261, 0.831);
		  return length(intensityVector);
		}
		
		void main() {
		  vec2 texCoord = vec2(gl_TextureMatrix[0] * gl_TexCoord[0]);
		  vec4 origColor = texture2D(screencopy, texCoord);
		  float intensity = getIntensity(origColor);
		  intensity = intensity * 1.5;
		  if (intensity > 1) intensity = 1;
		  if (intensity < 0.5) {
			if (intensity < 0.2) {
			  gl_FragColor = vec4(intensity*0.15, intensity*0.15, intensity*0.15, 0.6);
			} else if (intensity < 0.35) {
			  gl_FragColor = vec4(intensity*0.15, intensity*0.25, intensity*0.4, 0.75);
			} else {
			  gl_FragColor = vec4(intensity*0.2, intensity*0.35, intensity*0.8, 0.9);
			}
		  } else {
			if (intensity < 0.75) {
			  if (mod(gl_FragCoord.y, 4.0) < 2.0) {
				gl_FragColor = vec4(intensity*0.1, intensity*0.4, intensity*0.8, 0.9);
			  } else {
				gl_FragColor = vec4(intensity*0.2, intensity*0.4, intensity, 1);
			  }
			} else {
			  gl_FragColor = vec4(intensity*0.5, intensity*0.7, intensity, 0.9);
			}
		  }
		}
	]]

	local uniformInt = {
	  screencopy = 0
	}

	local shaderTable = {
	  fragment = "",
	  uniformInt = uniformInt
	}

function widget:Initialize()
	widgetHandler:RegisterGlobal("ActivateSlowMoShader", ActivateSlowMoShader)

  vsx, vsy = widgetHandler:GetViewSizes()
  widget:ViewResize(vsx, vsy)
  
	if gl.CreateShader then
	playerID = Spring.GetMyPlayerID()
	tname,_, tspec, tteam, tallyteam, tping, tcpu, tcountry, trank = Spring.GetPlayerInfo(playerID)
	local _,_,_,_, side, _                               = Spring.GetTeamInfo(tteam)

	if  side and side == "antagon" then
			shaderTable.fragment=  tacVision
	else
		shaderTable.fragment= 	nightvision
	end
	
	
		shaderProgram = gl.CreateShader(shaderTable)
	else
		Spring.Echo("<Night Vision Shader>: GLSL not supported.")
	end
  
	if not shaderProgram and gl and gl.GetShaderLog then
	 Spring.Echo(tacVision)
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
boolShaderActive= false

function ActivateSlowMoShader(boolActive)
	boolShaderActive = boolActive
end

function widget:DrawScreenEffects()
	if boolShaderActive == true then
	  glCopyToTexture(screencopy, 0, 0, 0, 0, vsx, vsy)
	  glTexture(0, screencopy)
	  glUseShader(shaderProgram)
	  glTexRect(0,vsy,vsx,0)
	  glTexture(0, false)
	  glUseShader(0)
	end
end
	