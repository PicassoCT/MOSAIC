#version 150 compatibility	
#line 100002										 

#define PI 3.14159265359
#define PI_HALF (PI*0.5)
#define MAX_DEPTH_RESOLUTION 15
#define E_CONST 2.718281828459045235360287471352
#define TOTAL_SCAN_DISTANCE 8192.0f
#define COL_RED vec4(1.0,0.0,0.0,1.0)
#define MAX_HEIGTH_RAIN 512.0
#define RAIN_DROP_LENGTH 15.0
#define RAIN_COLOR vec4(0.0, 1.0, 0.0, 1.0)

#define RED vec4(1.0, 0.0, 0.0, 0.25)
#define GREEN vec4(0.0, 1.0, 0.0, 0.25)
#define BLUE vec4(0.0, 0.0, 1.0, 0.25)

uniform sampler2D depthtex;
uniform sampler2D noisetex;
uniform sampler2D screentex;
uniform sampler2D raincanvastex;

uniform float time;		
uniform float rainDensity;
uniform int maxLightSources;
uniform vec3 camWorldPos;
uniform vec2 viewPortSize;
uniform mat4 viewProjectionInv;


in Data {
			vec3 fragVertexPosition;
			vec3 viewDirection;
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

vec4 rainbowValue(float value)
{
	vec4 red = RED;
	vec4 blue = BLUE;
	vec4 green = GREEN;

	if (value > 200.0)
	{
		return mix(red, blue, value/200.0f);
	}
	else 
	{
		return mix(blue, green , value/2048.0f);
	}
}
 
vec4 rainPixel(vec3 pixelCoord, float localRainDensity)
{
	vec4 pixelColor = vec4(0.0,0.0,0.0,0.0);
	vec2 deterministicRandom = vec2(pixelCoord.x, pixelCoord.y);
	float zAxisTime =  sin(time);
	if(1==1)
	return rainbowValue(pixelCoord.z);

	float noiseValue = (texture2D(noisetex, deterministicRandom)).r;
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
	float noiseValue = (texture2D(noisetex, deterministicRandom)).r;
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

vec3 getPixelWorldPos( vec2 uv)
{
	float z = texture2D(depthtex, uv).x;
	vec4 ppos;
	ppos.xyz = vec3(uv, z) * 2. - 1.;
	ppos.a   = 1.;
	vec4 worldPos4 = viewProjectionInv * ppos;
	worldPos4.xyz /= worldPos4.w;

	if (z == 1.0) {
		vec3 forward = normalize(worldPos4.xyz - camWorldPos);
		float a = max(-camWorldPos.y, camWorldPos.y) / forward.y;
		return camWorldPos + forward.xyz * abs(a);
	}

	return worldPos4.xyz;
}

Vec4 convertHeightToColor(float value) {
    Vec4 color;

    // Adjust these parameters for the desired gradient
    float minVal = -500.0;
    float maxVal = 8192.0;

    // Map the value to the range [0, 1]
    float t = (value - minVal) / (maxVal - minVal);
    
    // Use a sine function for a smooth oscillating gradient
    color.r = 0.5f + 0.5f * sin(2.0f * M_PI * t);
    color.g = 0.5f + 0.5f * sin(2.0f * M_PI * (t + 1.0f / 3.0f));
    color.b = 0.5f + 0.5f * sin(2.0f * M_PI * (t + 2.0f / 3.0f));
    color.a = 1.0f / MAX_DEPTH_RESOLUTION ; // Alpha channel, you can adjust it if needed

    return color;
}


// TODO: Problem der Regen ist in festen Bändern vor der Kamera, flackert evtl wenn sich die Kamera verschiebt
vec4 rainRayPixel(vec2 camPixel, vec3 viewDirection)
{
	vec4 accumulatedColor = vec4(0.0, 0.0,0.0,0.0);
	vec3 startPixel =  getPixelWorldPos(camPixel);
	float scanFactor = 0.0;
	float factor = 0.0;
	//für diesen Pixel im Weltkoordinatensystem gerastert vor der Kamera

	int i= 0;
	for (i= 0; i < MAX_DEPTH_RESOLUTION; i++) 
	{
		factor = (float(i)/MAX_DEPTH_RESOLUTION);
		scanFactor =  float(exp((factor)/(1.0 - E_CONST)) * TOTAL_SCAN_DISTANCE);
		vec3 newWorldPixelToCheck = startPixel * (viewDirection * scanFactor);
		// deterministic trace a ray back into world for log lightfalloff  in depth resolution
	
		//check if there is rain that pixel (x,y,z)   by time, coords  + windblow (sin(time))
		accumulatedColor = accumulatedColor + convertHeightToColor(newWorldPixelToCheck.y);//rainPixel(newWorldPixelToCheck, 0.5f);	


	}
	return accumulatedColor;
}											  

vec4 rayHoloGramLightBackround(vec2 TexCoord, float localRainDensity, float depthValueAtRay )
{
    vec3 worldSpacePosition = getPixelWorldPos(TexCoord);

	return checkGetLightForPixel(worldSpacePosition) * localRainDensity;
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

	vec2 uv = gl_FragCoord.xy / viewPortSize;
	vec4 origColor = texture2D(screentex, uv);
	float depthValueAtPixel = 0.0;
	depthValueAtPixel = (texture2D(depthtex, uv)).x;	
	
	vec4 accumulatedLightColorRay = rainRayPixel(uv,  viewDirection); 
	//vec4 backGroundLightIntersect = rayHoloGramLightBackround(uv, rainDensity, depthValueAtPixel);
	vec4 backGroundLightIntersect = vec4(0.0,0.0,0.0, 0.05);

	float upwardnessFactor = 0.0;
	upwardnessFactor = looksUpwardPercentage(viewDirection);


	vec4 downWardrainColor = (origColor);//+ accumulatedLightColorRay + backGroundLightIntersect; 
	//downWardrainColor =  downWardrainColor + vec4(0.25,0.0,0.0,0.0); //DELME DEBUG
	if( 1== 1)
			gl_FragColor = downWardrainColor;
			return;

	vec4 upWardrainColor = origColor;
	//if player looks upward mix drawing rain and start drawing drops on the camera
	if (upwardnessFactor > 0.45)
	{
		upWardrainColor = mix(downWardrainColor, upWardrainColor, (upwardnessFactor - 0.5) * 2.0);
		gl_FragColor = upWardrainColor;
	}	
	else //no Raindrops blended in
	{
		gl_FragColor = downWardrainColor;
	}
}
