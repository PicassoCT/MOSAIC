#version 150 compatibility	
#line 100002										 

#define PI 3.14159265359
#define PI_HALF (PI*0.5)
#define MAX_DEPTH_RESOLUTION 20.0
#define E_CONST 2.718281828459045235360287471352
#define TOTAL_SCAN_DISTANCE 8192.0f
#define COL_RED vec4(1.0,0.0,0.0,1.0)
#define MAX_HEIGTH_RAIN 2048.0f
#define MIN_HEIGHT_RAIN 0.0f
#define LENGTH_RAIN (2048.0f)
#define RAIN_DROP_LENGTH 32.0
#define OFFSET_COL_MIN vec4(-0.05, -0.05, -0.05, 0.1)
#define OFFSET_COL_MAX vec4(0.05, 0.05, 0.05, 0.1)


#define COL_RAIN_HIGH vec4(0.019, 0.615, 0.823, 0.10)
#define COL_RAIN_DARK vec4(0.06, 0.07, 0.27, 0.10)
#define COL_RAIN_CITYGLOW vec4(0.52.0, 0.19, 0.07, 0.10)
#define CITY_GLOW_MAX_DISTANCE 2048.0f

#define RED vec4(1.0, 0.0, 0.0, 0.125)
#define GREEN vec4(0.0, 1.0, 0.0, 0.125)
#define BLUE vec4(0.0, 0.0, 1.0, 0.125)
#define BLACK vec4(0.0, 0.0, 0.0, 0.125)
#define SCAN_SCALE 64.0
#define RAIN_THICKNESS_INV (1./(LENGTH_RAIN))
const float noiseTexSizeInv = 1.0 / SCAN_SCALE;
const float scale = 1./SCAN_SCALE;		 
const vec3 vMinima = vec3(-300000.0, MIN_HEIGHT_RAIN, -300000.0);
const vec3 vMaxima = vec3( 300000.0, MAX_HEIGTH_RAIN,  300000.0);

uniform sampler2D depthtex;
uniform sampler2D noisetex;
uniform sampler2D screentex;

uniform float time;		
uniform float rainDensity;
uniform int maxLightSources;
uniform vec3 eyePos;
uniform vec2 viewPortSize;
uniform vec3 cityCenter;
uniform mat4 viewProjectionInv;

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



float deterministicFactor(vec3 val)
{
	return mod((abs(val.x) + abs(val.y))/2.0, 1.0);
}

vec4 getDeterministicColorOffset(vec3 position)
{ 
	float randomFactor = deterministicFactor(position);
	return mix(OFFSET_COL_MIN, OFFSET_COL_MAX, randomFactor);
}

vec4 GetDeterminiticRainColor(vec3 pxlPos)
{
	float distanceToCityCore = distance(pxlPos, cityCenter);
	vec4 detRandomRainColOffset =getDeterministicColorOffset(pxlPos);
	vec4 rainHighColor = COL_RAIN_HIGH + detRandomRainColOffset;
	float cityGlowFactor = distanceToCityCore/ CITY_GLOW_MAX_DISTANCE;
	vec4 outsideCityRainCol = mix(rainHighColor, COL_RAIN_DARK, pxlPos.y/ LENGTH_RAIN);
	vec4 insideCityRainCol = mix(rainHighColor, COL_RAIN_CITYGLOW, pxlPos.y/ LENGTH_RAIN);

	return mix (outsideCityRainCol, insideCityRainCol, cityGlowFactor);
}

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
	for (i=0; i < maxLightSources; i+=2)
	{
		float lightSourceDistance = distance(Position, lightSources[i].xyz);
		if ( lightSourceDistance < lightSources[i].a)
		{
			lightColorAddition += lightSources[i+1].rgba * (1.0-exp(-lightSourceDistance));
		}
	}
	return lightColorAddition;
}

bool IsInGridPoint(vec3 pos, float size, float space)
{

	return ((mod(pos.x, space) < size) &&   (mod(pos.y, space) < size)  && (mod(pos.z, space) < size)) ;
}


//REFLECTIONMARCH 
 
float getDeterministicRandomValue(in vec3 pos)
{
	vec4 data = texture2D( noisetex, pos.xz);
	return data.r;
}

float GetYAxisTime(float offset)
{
	float yAxisTime =  sin(time*offset);
	if (yAxisTime < 0.0 ) yAxisTime = yAxisTime + 1.0;
	return yAxisTime;
}


vec4 getUVRainbow(vec2 uv){
	uv = normalize(uv);
	vec4 result  = mix(RED, mix(BLUE, GREEN, uv.y), uv.x);
	result.a = 0.75;
	return result;
}
 
vec4 renderRainPixel(vec3 pixelCoord, float localRainDensity)
{	
	//return mix(RED,BLACK, abs(sin(time +pixelCoord.z)) );
	vec4 pixelColor = vec4(0.0,0.0,0.0,0.0);

	float noiseValue = getDeterministicRandomValue(pixelCoord);
	float yAxisTime = GetYAxisTime(noiseValue);


	//How far along y is it via time and does that intersect
	float dropCenterY = yAxisTime * MAX_HEIGTH_RAIN;
	if (dropCenterY > pixelCoord.y ) return pixelColor;

	float distanceToDropCenter = distance(dropCenterY, pixelCoord.y);
	float dropAlphaFactor = 1.0 - min(distanceToDropCenter/RAIN_DROP_LENGTH, 1.0)*0.10;


		// rain drop 
		//vec4 lightFactor = RayMarchBackgroundLight(pixelCoord);
	pixelColor += vec4(GetDeterminiticRainColor(pixelCoord).rgb, dropAlphaFactor);// distanceToDropCenter/ RAIN_DROP_LENGTH) ;
	
	return pixelColor;	
}	

/*
vec4 getNoiseShiftedBackgroundColor(float time, vec3 pixelCoord, float localRainDensity)
{
	//check if intersects with depth map (max)

	//TODO: Move this whole thing into the pixelshader, cause no background Color here
	vec4 colorToShift = vec4(gl_FragColor);
	float zAxisTime =  sin(time);
	float noiseValue = getDeterministicRandomValue(pixelCoord);
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
*/

vec3 getPixelWorldPos( vec2 uv)
{
	float z = texture2D(depthtex, uv).z;
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

vec4 GetGradient(vec3 uvx, float distance){
	uvx = normalize(uvx);
	vec4 result  = mix(BLACK, mix(RED, mix(BLUE, GREEN, uvx.x), uvx.y),uvx.z);
	result.a = distance;
	return result;
}

vec4 RayMarchRainBackgroundLight(in vec3 start, in vec3 end)
{	
	float l = length(end - start);
	const float numsteps = MAX_DEPTH_RESOLUTION;
	const float tstep = 1. / numsteps;
	float depth = min(l * RAIN_THICKNESS_INV , 1.5);
	vec4 accumulatedColor = vec4(0.0, 0.0,0.0,0.0);

	for (float t=0.0; t<=1.0; t+=tstep) 
	{
		vec3 pxlPosWorld = mix(start, end, t);

		//if (IsInGrid(pxlPosWorld, 5.0, 512.0))
		//{
			accumulatedColor += renderRainPixel(pxlPosWorld, 0.5f) * tstep; //GetGradient(pxlPosWorld, tstep);//			
		//}

		//accumulatedColor += RayMarchBackgroundLight(pos);
	}
	
	return accumulatedColor;
}
											  
float looksUpwardPercentage()
{
	vec3 upwardVec = vec3(0.0, 1.0, 0.0);
	return dot(normalize(viewDirection), upwardVec);
}

vec4 addRainDropsShader(vec4 originalColor, vec2 uv)
{
	return COL_RED;
}


vec3 GetWorldPos(in vec2 screenpos)
{
	float z = texture2D(depthtex, screenpos).z;
	vec4 ppos;
	ppos.xyz = vec3(screenpos, z) * 2. - 1.;
	ppos.a   = 1.;
	vec4 worldPos4 = viewProjectionInv * ppos;
	worldPos4.xyz /= worldPos4.w;

	if (z == 1.0) {
		vec3 forward = normalize(worldPos4.xyz - eyePos);
		float a = max(MAX_HEIGTH_RAIN - eyePos.y, eyePos.y - MIN_HEIGHT_RAIN) / forward.y;
		return eyePos + forward.xyz * abs(a);
	}

	return worldPos4.xyz;
}

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

	float depthValueAtPixel = texture2D(depthtex, uv).z;

	vec4 origColor = texture2D(screentex, uv);
	AABB box;
	box.Min = vMinima;
	box.Max = vMaxima;
	float t1, t2;


	Ray r;
	r.Origin = eyePos;
	r.Dir = worldPos - eyePos;

	if (!IntersectBox(r, box, t1, t2))
	{
		gl_FragColor = vec4(0.);
		return;
	}

	t1 = clamp(t1, 0.0, 1.0);
	t2 = clamp(t2, 0.0, 1.0);
	vec3 startPos = r.Dir * t1 + eyePos;
	vec3 endPos   = r.Dir * t2 + eyePos;

	vec4 accumulatedLightColorRayDownward = RayMarchRainBackgroundLight(startPos,  endPos); 

	//float upwardnessFactor = 0.0;
	//upwardnessFactor = looksUpwardPercentage();

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
		gl_FragColor = accumulatedLightColorRayDownward; 
	//}

	//gl_FragColor.a *= smoothstep(gl_Fog.end * 10.0, gl_Fog.start, length(worldPos - eyePos));
	
}
