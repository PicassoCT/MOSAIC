#version 150 compatibility											 

#define PI 3.14159265359
#define PI_HALF (PI*0.5)
#define MAX_DEPTH_RESOLUTION 15
#define E_CONST 2.718281828459045235360287471352
#defione TOTAL_SCAN_DISTANCE = 800

uniform sampler2D raincanvasTex;
uniform sampler2D depthTex;
uniform float time;		
uniform float rainDensity;
uniform int maxLightSources;
uniform vec3 camWorldPos;
uniform vec2 viewPortSize;
uniform vec4 lightSources[20];

	
in Data {
			vec3 vfragWorldPos;
		 };

 
vec4 rainPixel(vec3 pixelCoord, float time, int randSeed, float rainDensity, float windFactor)
{
	vec4 pixelColor = vec4(0.0,0.0,0.0,0.0);
	vec2 deterministicRandom = vec2(pixelCoord.x, pixelCoord.y);
	float zAxisTime =  sin(time);
	float noiseValue = Texture2D(deterministicRandom);
	if (noiseValue > (1.0 -rainDensity))// A raindrop in pixel
	{
		//How far along z is it via time and does that intersect
		float dropCenterZ = sin(PI_HALF + mod((zAxisTime * (PI_HALF)), PI_HALF))* maxHeight;
		float distanceToDropCenter = distance(dropCenterZ, pixelCoord.z);
		if (dropCenterZ < pixelCoord.z && distanceToDropCenter < RAIN_DROP_LENGTH )
		{
			// rain drop 
			vec4 lightFactor = checkGetLightForPixel(pixelCoord);
			pixelColor += vec4(RAIN_COLOR.rgb, distanceToDropCenter/ RAIN_DROP_LENGTH) ;
		}
	}
	return pixelColor;
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

vec4 getNoiseShiftedBackgroundColor(float time, vec3 pixelCoord, float rainDensity)
{
	//check if intersects with depth map (max)

	//TODO: Move this whole thing into the pixelshader, cause no background Color here
	vec4 colorToShift = vec4(gl_FragColor);
	vec2 deterministicRandom = vec2(pixelCoord.x, pixelCoord.y);
	float zAxisTime =  sin(time);
	float noiseValue = Texture2D(deterministicRandom);
	if (noiseValue > (1.0 -rainDensity))// A raindrop in pixel
	{
		//How far along z is it via time and does that intersect
		float dropCenterZ = sin(PI_HALF + mod((zAxisTime * (PI_HALF)), PI_HALF))* maxHeight;
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

	vec3 camToWorldPixelVector = vec3(TODO)
	//für diesen Pixel im Weltkoordinatensystem gerastert vor der Kamera
	vec3 startPixel = vec3 (TODO);

	for (int i= 0; i < MAX_DEPTH_RESOLUTION; i++) 
	{
		float factor = (float)(i/MAX_DEPTH_RESOLUTION);
		float scanFactor =  exp((factor)/(1.0- E_CONST)*TOTAL_SCAN_DISTANCE;
		vec3 newWorldPixelToCheck = startPixel * (camToWorldPixelVector * scanFactor);
		// deterministic trace a ray back into world for log lightfalloff  in depth resolution
	
		//check if there is rain that pixel (x,y,z)   by time, coords and randomseed + windblow (sin(time))

		accumulatedColor = accumulatedColor + rainPixel(newWorldPixelToCheck,  time);	
	}
	
	return accumulatedColor;
}											  

vec4 rayHoloGramLight(float depthValueAtPos )
{
	//TODO Prompt - I have a depthTextureMap, a CameraPixel + vector
	//How to computate the Position of that pixel in the world where the ray intersects 
	vec3 intersectPixel= vec3(TODO);
	return checkGetLightForPixel(intersectPixel) * rainDensity;
}

float looksUpwardPercentage(vec3 viewDirection)
{
	vec3 upwardVec = vec3(0.0, 1.0, 0.0);
	return dot(normalize(viewDirection), upwardVec);
}

void main(void)
{
	vec3 viewDirection = normalize(cameraWorldPos - vfragWorldPos);
	vec2 uv = gl_FragCoord.xy / viewPortSize;
	float depthValueAtPos = texture2D(depthTex, uv);	

	vec4 accumulatedLightColorRay = rainRayPixel(TODO); 
	vec4 backGroundLightIntersect = rayHoloGramLight(rainDensity, depthValueAtPos);
	float upwardnessFactor = looksUpwardPercentage(viewDirection);
	vec4 downWardrainColor = (vec4(0.5, 0.5, 0.25, 1.0) *depthValueAtPos)+ accumulatedLightColorRay + backGroundLightIntersect; 
	vec4 upWardrainColor = vec3(0.0, 0.0,0.0, 1.0);
	if (upwardnessFactor > 0.5)
	{
		upWardrainColor = getRainDropsShader(time, uv);
		upWardrainColor = mix(downWardrainColor, upWardrainColor, upwardnessFactor - 0.5);
	}	
	else //no Raindrops blended in
	{
		gl_FragColor = downWardrainColor;
	}
	
}
										
										
