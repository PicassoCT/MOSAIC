
	#version 150 compatibility
	uniform sampler2D raincanvasTex;
	uniform sampler2D depthTex;
		uniform float time;		

		uniform vec3 camWorldPos;
		uniform vec2 viewPortSize;

out Data {
			vec4 accumulatedLightColorRay;
		};
  
vec4 rainPixel(vec3 worldPos, float time, int randSeed, float rainDensity, float lightningFactor)
{
	//rain likelihood depends on current storm density
	//rainPixel
return vec4(1.0,0.0,0.0,0.5);
	//Check for lightsourcecloseness
}	

vec4 getNoiseShiftedBackgroundColor(float time, vec3 pixelCoord)
{
	//TODO: Move this whole thing into the pixelshader, cause no background Color here
	vec4 colorToShift = vec4(gl_FragColor);
	vec2 deterministicRandom = vec2(pixelCoord.x, pixelCoord.y);
	float zAxisTime =  sin(time)*
	float noiseValue = Texture2D(deterministicRandom
	
}

// TODO: Problem der Regen ist in festen Bändern vor der Kamera, flackert evtl wenn sich die Kamera verschiebt
void rainRayPixel(vec2 camPixel, vec3 worldVector, float time)
{
	vec4 accumulatedColor = vec4(0.0, 0.0,0.0,0.0);

	//für diesen Pixel im Weltkoordinatensystem gerastert von der Kamera
	vec3 worldPosPixel = vec3 (1.0,2.0,3.0);
	
	//add noise overlay * rainDensity shifted downward by time

	for (int i= 0; i < MAX_DEPTH_RESOLUTION; i++) 
	{
		// deterministic trace a ray back into world for log lightfalloff  in depth resolution
	
		//check if there is rain that pixel (x,y,z)   by time, coords and randomseed + windblow (sin(time))

		accumulatedColor = accumulatedColor + rainPixel(worldPosPixel,  time, randSeed);	
	}
	
	return accumulatedColor;
}											  

void main(void)
{

	vec4 eyePos = gl_ModelViewMatrix * vec4(gl_Vertex.xyz, 1.0);
	gl_Position = gl_ProjectionMatrix * eyePos;
}
									  ]