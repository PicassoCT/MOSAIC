#version 150 compatibility	
#line 100002										 

#define PI 3.14159265359
#define PI_HALF (PI*0.5)
#define MAX_DEPTH_RESOLUTION 20.0
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
uniform vec3 eyePos;
uniform vec2 viewPortSize;
uniform mat4 viewProjectionInv;


const vec3 vAA = vec3(-300000.0, 0.0, -300000.0);
const vec3 vBB = vec3( 300000.0, 9000.0,  300000.0);



in Data {
			vec3 fragVertexPosition;
			vec3 viewDirection;
		 };

struct Ray {
	vec3 Origin;
	vec3 Dir;
};

struct AABB {
	vec3 Min;
	vec3 Max;
};


//Lightsource description 
/*
{
vec4  position + distance
vec4  color + strength.a
}
*/
uniform vec4 lightSources[20];

vec4 RayMarchBackgroundLight(vec3 Position)
{
	vec4 lightColorAddition = vec4(0.0, 0.0, 0.0 ,0.0);
	int i=0;
	for ( i=0; i < maxLightSources; i+=2)
	{
		float lightSourceDistance = distance(Position, lightSources[i].xyz);
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

//REFLECTIONMARCH 
 
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
			vec4 lightFactor = RayMarchBackgroundLight(pixelCoord);
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
			colorToShift += RayMarchBackgroundLight(pixelCoord);
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
		vec3 forward = normalize(worldPos4.xyz - eyePos);
		float a = max(-eyePos.y, eyePos.y) / forward.y;
		return eyePos + forward.xyz * abs(a);
	}

	return worldPos4.xyz;
}

vec4 convertHeightToColor(vec3 value) 
{
	

    	if (mod(value.z, 64.0) < 5.0) return RED;
    	if (mod(value.x ,64.0) < 5.0) return GREEN;

   return vec4(0.0,0.0,0.0,0.0);
}

vec4 RayMarchRainBackgroundLight(in vec3 start, in vec3 end)
{	
	return convertHeightToColor(end);

	float l = length(end - start);
	const float numsteps = MAX_DEPTH_RESOLUTION;
	const float tstep = 1. / numsteps;
	float depth = min(l , 1.5);
	vec4 accumulatedColor = vec4(0.0, 0.0,0.0,0.0);

	for (float t=0.0; t<=1.0; t+=tstep) 
	{
		vec3 pos = mix(start, end, t);

		accumulatedColor = accumulatedColor + convertHeightToColor(pos); //rainPixel(pos, 0.5f);	
		//accumulatedColor += RayMarchBackgroundLight(pos);
	}

	return accumulatedColor;
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

vec3 GetWorldPos(in vec2 screenpos)
{
	float z = texture2D(depthtex, screenpos).x;
	vec4 ppos;
	ppos.xyz = vec3(screenpos, z) * 2. - 1.;
	ppos.a   = 1.;
	vec4 worldPos4 = viewProjectionInv * ppos;
	worldPos4.xyz /= worldPos4.w;

	if (z == 1.0) {
		vec3 forward = normalize(worldPos4.xyz - eyePos);
		float a =  eyePos.y / forward.y;
		return eyePos + forward.xyz * abs(a);
	}

	return worldPos4.xyz;
}
struct AABB {
	vec3 Min;
	vec3 Max;
};

bool IntersectBox(in Ray r, in AABB aabb, out float t0, out float t1)
{
	vec3 invR = 1.0 / r.Dir;
	vec3 tbot = invR * (aabb.Min - r.Origin);
	vec3 ttop = invR * (aabb.Max - r.Origin);
	vec3 tmin = min(ttop, tbot);
	vec3 tmax = max(ttop, tbot);
	vec2 t = max(tmin.xx, tmin.yz);
	t0 = max(0.,max(t.x, t.y));
	t  = min(tmax.xx, tmax.yz);
	t1 = min(t.x, t.y);
	//return (t0 <= t1) && (t1 >= 0.);
	return (abs(t0) <= t1);
}


void main(void)
{

	vec2 uv = gl_FragCoord.xy / viewPortSize;
	vec3 worldPos = GetWorldPos(uv);
	float depthValueAtPixel = 0.0;
	vec4 origColor = vec4(0.0,0.0,0.0,0.5);
	AABB box;
	box.Min = vAA;
	box.Max = vBB;
	float t1, t2;

	depthValueAtPixel = (texture2D(depthtex, uv)).x;	

	Ray r;
	r.Origin = eyePos;
	r.Dir = worldPos - eyePos;
	t1 = clamp(t1, 0.0, 1.0);
	t2 = clamp(t2, 0.0, 1.0);
	vec3 startPos = viewDirection * t1 + eyePos;
	vec3 endPos   = viewDirection * t2 + eyePos;

	if (!IntersectBox(r, box, t1, t2)) {
		gl_FragColor = vec4(0.);
		return;
	}

	vec4 accumulatedLightColorRay = RayMarchRainBackgroundLight(startPos,  endPos); 

	float upwardnessFactor = 0.0;
	upwardnessFactor = looksUpwardPercentage(viewDirection);

	vec4 downWardrainColor = (origColor) + accumulatedLightColorRay ;
	//downWardrainColor =  downWardrainColor + vec4(0.25,0.0,0.0,0.0); //DELME DEBUG


	vec4 upWardrainColor = origColor;
	//if player looks upward mix drawing rain and start drawing drops on the camera
	//if (upwardnessFactor > 0.45)
	//{
	//	upWardrainColor = mix(downWardrainColor, upWardrainColor, (upwardnessFactor - 0.5) * 2.0);
	//	gl_FragColor = upWardrainColor;
	//}	
	//else //no Raindrops blended in
	//{
		gl_FragColor = downWardrainColor;
	//}

	gl_FragColor.a *= smoothstep(gl_Fog.end * 10.0, gl_Fog.start, length(worldPos - eyePos));
}
