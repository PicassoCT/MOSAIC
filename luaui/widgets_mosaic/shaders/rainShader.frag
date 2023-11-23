#version 150 compatibility											 

#define PI 3.14159265359
#define PI_HALF (PI*0.5)
#define MAX_DEPTH_RESOLUTION 15
#define E_CONST 2.718281828459045235360287471352
#define TOTAL_SCAN_DISTANCE 800.0f
#define COL_RED vec4(1.0,0.0,0.0,1.0)
#define MAX_HEIGTH_RAIN 512.0
#define RAIN_DROP_LENGTH 15.0
#define RAIN_COLOR vec4(0.0, 1.0, 0.0, 1.0)
#define VEC_TODO vec3(1.0, 0.5, 0.5)

uniform sampler2D raincanvasTex;
uniform sampler2D depthTex;
uniform sampler2D noiseTex;

uniform float time;		
uniform float rainDensity;
uniform int maxLightSources;
uniform vec3 camWorldPos;
uniform vec2 viewPortSize;


in Data {
			vec3 vfragWorldPos;
		 };


//Lightsource description 
/*
{
vec4  position + distance
vec4  color + strength.a
}
*/
uniform vec4 lightSources[20];

vec4 checkGetLightForPixel(vec3 pixelWorld)
{
	vec4 lightColorAddition = vec4(0.0, 0.0, 0.0 ,0.0);
	int i=0;
	for ( i=0; i < maxLightSources; i+=2)
	{
		float lightSourceDistance = distance(pixelWorld, lightSources[i].xyz);
		if ( lightSourceDistance < lightSources[i].a)
		{
			lightColorAddition += lightSources[i+1].rgba * (1.0-exp(-lightSourceDistance));
		}
	}
	return lightColorAddition;
}
 
vec4 rainPixel(vec3 pixelCoord, float localRainDensity)
{
	vec4 pixelColor = vec4(0.0,0.0,0.0,0.0);
	vec2 deterministicRandom = vec2(pixelCoord.x, pixelCoord.y);
	float zAxisTime =  sin(time);
	float noiseValue = (texture2D(noiseTex, deterministicRandom)).r;
	if (noiseValue > (1.0 -localRainDensity))// A raindrop in pixel
	{
		//How far along z is it via time and does that intersect
		float dropCenterZ = sin(PI_HALF + mod((zAxisTime * (PI_HALF)), PI_HALF))* MAX_HEIGTH_RAIN;
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

vec4 getNoiseShiftedBackgroundColor(float time, vec3 pixelCoord, float localRainDensity)
{
	//check if intersects with depth map (max)

	//TODO: Move this whole thing into the pixelshader, cause no background Color here
	vec4 colorToShift = vec4(gl_FragColor);
	vec2 deterministicRandom = vec2(pixelCoord.x, pixelCoord.y);
	float zAxisTime =  sin(time);
	float noiseValue = (texture2D(noiseTex, deterministicRandom)).r;
	if (noiseValue > (1.0 -localRainDensity))// A raindrop in pixel
	{
		//How far along z is it via time and does that intersect
		float dropCenterZ = sin(PI_HALF + mod((zAxisTime * (PI_HALF)), PI_HALF))* MAX_HEIGTH_RAIN;
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
vec4 rainRayPixel(vec2 camPixel, vec3 worldVector)
{
	vec4 accumulatedColor = vec4(0.0, 0.0,0.0,0.0);
	vec3 camToWorldPixelVector = VEC_TODO;
	float scanFactor = 0.0;
	float factor = 0.0;
	//für diesen Pixel im Weltkoordinatensystem gerastert vor der Kamera
	vec3 startPixel = VEC_TODO;
	int i= 0;
	for (i= 0; i < MAX_DEPTH_RESOLUTION; i++) 
	{
		factor = (float(i)/MAX_DEPTH_RESOLUTION);
		scanFactor =  float(exp((factor)/(1.0- E_CONST)) * TOTAL_SCAN_DISTANCE);
		vec3 newWorldPixelToCheck = startPixel * (camToWorldPixelVector * scanFactor);
		// deterministic trace a ray back into world for log lightfalloff  in depth resolution
	
		//check if there is rain that pixel (x,y,z)   by time, coords  + windblow (sin(time))
		accumulatedColor = accumulatedColor + rainPixel(newWorldPixelToCheck, 0.5f);	

	}
	return accumulatedColor;
}											  

vec4 rayHoloGramLightBackround(vec2 TexCoord, float localRainDensity, float depthValueAtRay )
{
	//Basis: https://stackoverflow.com/questions/32227283/getting-world-position-from-depth-buffer-value
	vec4 clipSpacePosition = vec4(TexCoord * 2.0 - 1.0, depthValueAtRay, 1.0);
    vec4 viewSpacePosition = gl_ProjectionMatrixInverse * clipSpacePosition;

    // Perspective division
    viewSpacePosition /= viewSpacePosition.w;
    mat4 cameraViewInv = inverse(gl_ProjectionMatrix);
    vec4 worldSpacePosition = cameraViewInv * viewSpacePosition;

	return checkGetLightForPixel(worldSpacePosition.xyz) * localRainDensity;
}

float looksUpwardPercentage(vec3 viewDirection)
{
	vec3 upwardVec = vec3(0.0, 1.0, 0.0);
	return dot(normalize(viewDirection), upwardVec);
}

vec4 addRainDropsShader(vec4 originalColor, vec2 uv)
{
	return COL_RED;
}

float avg(vec3 val)
{
return sqrt(val.x*val.x + val.y*val.y + val.z *val.z);
}

void main(void)
{
	vec3 viewDirection = normalize(camWorldPos - vfragWorldPos);
	vec2 uv = gl_FragCoord.xy / viewPortSize;
	float depthValueAtPixel = 0.0;
	depthValueAtPixel = (texture2D(depthTex, uv)).r *  2.0f - 1.0f;	
	vec4 accumulatedLightColorRay = rainRayPixel(uv,  viewDirection); 
	vec4 backGroundLightIntersect = rayHoloGramLightBackround(uv, rainDensity, depthValueAtPixel);
	float upwardnessFactor = 0.0;
	upwardnessFactor = looksUpwardPercentage(viewDirection);
	vec4 origColor = texture2D(raincanvasTex, uv);
	vec4 downWardrainColor = (origColor)+ accumulatedLightColorRay + backGroundLightIntersect; 
	vec4 upWardrainColor = origColor;
	if (upwardnessFactor > 0.5)
	{
		upWardrainColor = addRainDropsShader(origColor, uv);
		upWardrainColor = mix(downWardrainColor, upWardrainColor, upwardnessFactor - 0.5);
		gl_FragColor = upWardrainColor;
	}	
	else //no Raindrops blended in
	{
		gl_FragColor = downWardrainColor;
	}
}