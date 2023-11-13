
#version 150 compatibility
uniform sampler2D raincanvasTex;
uniform sampler2D depthTex;
uniform float time;		
uniform vec3 camWorldPos;
uniform vec2 viewPortSize;

#define PI 3.14159
#define PI_HALF (PI*0.5)

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


//Lightsource description 
/*
{
vec4  position + distance
vec4  color + strength.a
}
*/
vec4 checkGetLightForPixel(vec3 pixelWorld)
{
	vec4 lightColorAddition = vec4(0.0, 0.0, 0.0 ,0.0)
	for (int i=0; i < maxLightSources; i+=2)
	{
		float lightSourceDistance = distance(pixelWorld, lightSources[i].xyz)
		if ( lightSourceDistance < lightSources[i].a)
		{
			lightColorAddition += lightSources[i+1].rgba * (1.0-exp(-lightSourceDistance));
		}
	}
	return lightColorAddition;
}

vec4 getNoiseShiftedBackgroundColor(float time, vec3 pixelCoord, float lightningFactor, float rainThreshold)
{
	//check if intersects with depth map (max)

	//TODO: Move this whole thing into the pixelshader, cause no background Color here
	vec4 colorToShift = vec4(gl_FragColor);
	vec2 deterministicRandom = vec2(pixelCoord.x, pixelCoord.y);
	float zAxisTime =  sin(time)*
	float noiseValue = Texture2D(deterministicRandom+time);
	if (noiseValue > rainThreshold)// A raindrop in pixel
	{
		//How far along z is it via time and does that intersect
		float dropCenterZ = sin(PI_HALF + mod((time * (PI_HALF)), PI_HALF))* maxHeight;
		float distanceToDropCenter = distance(dropCenterZ, pixelCoord.z);
		if (dropCenterZ < pixelCoord.z && distanceToDropCenter < RAIN_DROP_LENGTH )
		{
			// rain drop 
			colorToShift += vec4(RAIN_COLOR.rgb, distanceToDropCenter/ RAIN_DROP_LENGTH);

			colorToShift += checkGetLightForPixel(pixelCoord);
		}
	}
	
	return colorToShift;
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