#version 150 compatibility	
#line 100001										 
//Defines //////////////////////////////////////////////////////////
#define PI 3.14159265359
#define PI_HALF (PI*0.5)
#define MAX_DEPTH_RESOLUTION 20.0
#define E_CONST 2.718281828459045235360287471352
#define TOTAL_SCAN_DISTANCE 8192.0

#define METER 0.0025
#define MAX_HEIGTH_RAIN 192.0
#define MIN_HEIGHT_RAIN 0.0
#define TOTAL_LENGTH_RAIN (192.0)
#define MAP_SCALE (4096.0 / 5.0)
#define MIRRORED_REFLECTION_FACTOR 0.45f
#define ADD_POND_RIPPLE_FACTOR 0.75f

#define OFFSET_COL_MIN vec4(-0.05,-0.05,-0.05,0.1)
#define OFFSET_COL_MAX vec4(0.15,0.15,0.15,0.1)
//DayColors
#define DAY_RAIN_HIGH_COL vec4(1.0,1.0,1.0,1.0)
#define DAY_RAIN_DARK_COL vec4(0.26,0.27,0.37,1.0)
#define DAY_RAIN_CITYGLOW_COL vec4(0.72,0.505,0.52,1.0)
//NightColors
#define NIGHT_RAIN_HIGH_COL vec4(0.75,0.75,0.75,1.0)
#define NIGHT_RAIN_DARK_COL vec4(0.06,0.07,0.17,1.0)
#define NIGHT_RAIN_CITYGLOW_COL vec4(0.72,0.505,0.52,1.0)

#define NONE vec4(0.0,0.0,0.0,0.0);
#define RED vec4(1.0, 0.0, 0.0, 1.0)
#define GREEN vec4(0.0, 1.0, 0.0, 1.0)
#define BLUE vec4(0.0, 0.0, 1.0, 1.0)
#define BLACK vec4(0.0, 0.0, 0.0, 1.0)
#define IDENTITY vec4(1.0,1.0,1.0,1.0)
#define SCAN_SCALE 64.0
#define RAIN_THICKNESS_INV (1./(TOTAL_LENGTH_RAIN))
#define RAIN_DROP_DIAMTER (0.06)
#define RAIN_DROP_LENGTH 0.12
#define RAIN_DROP_EMPTYSPACE 1.0
#define SPEED_OF_RAIN_FALL (0.06f * 1666.6f)
// Maximum number of cells a ripple can cross.
#define MAX_RADIUS 2
// Set to 1 to hash twice. Slower, but less patterns.
#define DOUBLE_HASH 0

// Hash functions shamefully stolen from:
// https://www.shadertoy.com/view/4djSRW
#define HASHSCALE1 .1031
#define HASHSCALE3 vec3(.1031, .1030, .0973)


//Constants aka defines for the weak /////////////////////////////////////
const float noiseTexSizeInv = 1.0 / SCAN_SCALE;
const float scale = 1./SCAN_SCALE;		 
const vec3 vMinima = vec3(-300000.0, MIN_HEIGHT_RAIN, -300000.0);
const vec3 vMaxima = vec3( 300000.0, MAX_HEIGTH_RAIN,  300000.0);
const vec3 upwardVector = vec3(0.0, 1.0, 0.0);
float depthValue = 0;

//Uniforms
uniform sampler2D depthtex;
uniform sampler2D noisetex;
uniform sampler2D screentex;
uniform sampler2D normaltex;
uniform sampler2D skyboxtex;


uniform float time;		
uniform float rainDensity;
uniform int maxLightSources;
uniform float timePercent;
uniform vec3 eyePos;
uniform vec3 sundir;
uniform vec3 suncolor;

uniform vec2 viewPortSize;
uniform vec3 cityCenter;
uniform mat4 viewProjectionInv;
uniform mat4 viewProjection;
uniform mat4 viewInv;


//Struc Definition				//////////////////////////////////////////////////////////
//Lightsource description 
/*
{
vec4  position + distance
vec4  color + strength.a
}
*/
uniform vec4 lightSources[20];

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
//Global Variables					//////////////////////////////////////////////////////////
vec2 uv;
vec3 worldPos;
vec4 dephtValueAtPixel;
vec3 pixelDir;
vec4 origColor;
vec3 groundViewNormal;

//Various helper functions && Tools //////////////////////////////////////////////////////////

float hash12(vec2 p)
{
	vec3 p3  = fract(vec3(p.xyx) * HASHSCALE1);
    p3 += dot(p3, p3.yzx + 19.19);
    return fract((p3.x + p3.y) * p3.z);
}

vec2 hash22(vec2 p)
{
	vec3 p3 = fract(vec3(p.xyx) * HASHSCALE3);
    p3 += dot(p3, p3.yzx+19.19);
    return fract((p3.xx+p3.yz)*p3.zy);

}

float noise(in vec3 x)
{
	vec3 p = floor(x);
	vec3 f = fract(x);
	f = f*f*(3.0-2.0*f);
	vec2 uv = (p.xz + vec2(37.0,17.0)*p.y) + f.xz;
	vec2 rg = texture2D( noisetex, (uv + 0.5) * noiseTexSizeInv).yx;
	return smoothstep(0.5 - noiseCloudness, 0.5 + noiseCloudness, mix( rg.x, rg.y, f.y ));
}

bool isInIntervallAround(float value, float targetValue, float intervall)
{
	return value +intervall >= targetValue && value - intervall <= targetValue;
}

float deterministicFactor(vec3 val)
{
	return mod((abs(val.x) + abs(val.y))/2.0, 1.0);
}

vec4 getDeterministicColorOffset(vec3 position)
{ 
	float randomFactor = deterministicFactor(position);
	return mix(OFFSET_COL_MIN, OFFSET_COL_MAX, randomFactor);
}

float getDayPercent()
{
	if (timePercent < 0.25 || timePercent > 0.75)
	{
		return 0.0;
	}else
	{
		return (timePercent - 0.25) * 2.0;
	}	
}

vec4 getVectorColor(vec3 vector){
	vec4 result  = mix(RED,  BLACK, vector.y);
	result.a = 0.75;
	return result;
}

vec4 getUVRainbow(vec2 uv){
	uv = normalize(uv);
	vec4 result  = mix(RED, mix(BLUE, GREEN, uv.y), uv.x);
	result.a = 0.75;
	return result;
}

float GetUpwardnessFactorOfVector(vec3 vectorToCompare)
{
	return dot(normalize(vectorToCompare), upwardVector);
}

//Various helper functions && Tools //////////////////////////////////////////////////////////

vec4 GetDeterminiticRainColor(vec3 pxlPos )
{
	vec4 detRandomRainColOffset = getDeterministicColorOffset(pxlPos);
	vec4 rainHighDayColor;
	vec4 rainHighNightColor;
	vec4 outsideCityRainDayCol;
	vec4 outsideCityRainNightCol;
	float depthOfDropFactor = min(1.0, pxlPos.y/ TOTAL_LENGTH_RAIN);

  	// Night
	rainHighNightColor =  vec4(suncolor, 1.0) * NIGHT_RAIN_HIGH_COL + detRandomRainColOffset;
	outsideCityRainNightCol = mix(rainHighNightColor, NIGHT_RAIN_DARK_COL, depthOfDropFactor);
	;
	
	//Day
	rainHighDayColor =  vec4(suncolor, 1.0) * DAY_RAIN_HIGH_COL + detRandomRainColOffset;
	outsideCityRainDayCol = mix(rainHighDayColor	, DAY_RAIN_DARK_COL, depthOfDropFactor);
	

	return mix(outsideCityRainDayCol, outsideCityRainNightCol, getDayPercent());
}

vec4 renderBackGroundLight(vec3 Position)
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
float getDeterministicRandomValuePerPosition(in vec3 pos, out vec4 rdata)
{
	vec4 data = texture2D(noisetex, pos.xz);
	return data.r;
}

float GetSinCurve( float pulseValue)
{
	return sin(PI_HALF * 0.5 + (pulseValue * PI_HALF));
}

float GetPulseFromIntervall(float currentIntervallShiftPos, float intervallLength, float pulseStart, float pulseEnd)
{
	currentIntervallShiftPos = mod(currentIntervallShiftPos, intervallLength);
	if (currentIntervallShiftPos > pulseEnd) return 0.0;
	if (currentIntervallShiftPos < pulseStart)return 0.0;

	return GetSinCurve((currentIntervallShiftPos - pulseStart)/(pulseEnd - pulseStart));
}

float getTimeWiseOffset(float offset, float scale)
{
	if (offset < 0.5)
	{
		return offset * scale * -2.0;
	}
	if (offset >= 0.5)
	{
		return (offset-0.5) * scale * 2.0 ;
	}
	return 0.0;
}


vec4 GetGroundPondRainRipples(vec2 groundUVs) 
{
    float resolution = 10. * exp2(-3.* -0.1);
	vec2 p0 = floor(groundUVs / MAP_SCALE); 

    vec2 circles = vec2(0.);
    for (int j = -MAX_RADIUS; j <= MAX_RADIUS; ++j)
    {
        for (int i = -MAX_RADIUS; i <= MAX_RADIUS; ++i)
        {
			vec2 pi = p0 + vec2(i, j);
            #if DOUBLE_HASH
            vec2 hsh = hash22(pi);
            #else
            vec2 hsh = pi;
            #endif
            vec2 p = pi + hash22(hsh);

            float t = fract(0.3*time + hash12(hsh));
            vec2 v = p - uv;
            float d = length(v) - (float(MAX_RADIUS) + 1.)*t;

            float h = 1e-3;
            float d1 = d - h;
            float d2 = d + h;
            float p1 = sin(31.*d1) * smoothstep(-0.6, -0.3, d1) * smoothstep(0., -0.3, d1);
            float p2 = sin(31.*d2) * smoothstep(-0.6, -0.3, d2) * smoothstep(0., -0.3, d2);
            circles += 0.5 * normalize(v) * ((p2 - p1) / (2. * h) * (1. - t) * (1. - t));
        }
    }
    circles /= float((MAX_RADIUS*2+1)*(MAX_RADIUS*2+1));

    float intensity = mix(0.01, 0.15, smoothstep(0.1, 0.6, abs(fract(0.05*(time) + 0.5)*2.-1.)));
    vec3 n = vec3(circles, sqrt(1. - dot(circles, circles)));
    vec3 color = BLACK.rgb + suncolor.rgb * 5.* pow(clamp(dot(n, normalize(vec3(1., 0.7, 0.5))), 0., 1.), 6.);
    //Reflection texture lookup to expensive
    //texture(iChannel0, uv/resolution - intensity*n.xy).rgb 	fragColor = vec4(color, 1.0);
    return vec4(color, 1.0);

}

vec2 getSkyboxUVs(vec3 pos)
{
	vec3 reflectionDir = pixelDir;
	// Mirror around pos z-axis

	//translate vector to unfolded cube uv coords


}

vec4 GetGroundReflectionRipples(vec3 pixelPos)
{
	if (groundViewNormal.g < 0.995) return NONE;

	vec2 skyboxUV = 
	vec3 newPosition =  getSkyboxUVs(pixelPos);

	// Transform the new world position to view space
	vec4 newViewCoords = viewProjection * vec4(newPosition, 1.0);

	// Transform the view space position to clip space
	vec4 newClipCoords = gl_ProjectionMatrix * newViewCoords;

	// Transform the clip space position to NDC
	vec2 newNDCCoords = (newClipCoords.xy / newClipCoords.w + 1.0) * 0.5;	

	vec4 mirroredReflection = texture2D(skyboxtex, newNDCCoords);
	
	return		MIRRORED_REFLECTION_FACTOR * mirroredReflection  + 
				ADD_POND_RIPPLE_FACTOR * GetGroundPondRainRipples( pixelPos.xz);

}

float GetYAxisRainPulseFactor(float yAxis, float offsetTimeFactor, vec4 randData)
{
	return GetPulseFromIntervall(SPEED_OF_RAIN_FALL * time + getTimeWiseOffset(offsetTimeFactor, RAIN_DROP_LENGTH), RAIN_DROP_LENGTH + RAIN_DROP_EMPTYSPACE , 0.0, RAIN_DROP_LENGTH );
}



vec3 truncatePosition(in vec3 pixelPosTrunc)
{
	vec3 pixelPos = pixelPosTrunc;
	pixelPos.xz = pixelPos.xz - mod(pixelPos.xz, RAIN_DROP_DIAMTER);
	return pixelPos;
}
 
vec4 renderRainPixel(bool RainHighlight, vec3 pixelCoord, float localRainDensity)
{	
	//return mix(RED,BLACK, abs(sin(time +pixelCoord.z)) );
	vec4 pixelColor = GetDeterminiticRainColor(pixelCoord);//vec4(0.0,0.0,0.0,0.0);
	vec4 randData;
	float noiseValue = getDeterministicRandomValuePerPosition(pixelCoord, randData);
	vec3 pixelCoordTrunc = truncatePosition(pixelCoord);
	vec4 randDataTruncated;
	float noiseValueTruncated = getDeterministicRandomValuePerPosition(pixelCoordTrunc, randDataTruncated);
	float yAxisPulseFactor = GetYAxisRainPulseFactor(pixelColor.y, noiseValue, randData);
	if (yAxisPulseFactor > 0.95 && RainHighlight) pixelColor += IDENTITY * 0.5f;
	pixelColor = vec4(pixelColor.rgb * yAxisPulseFactor, yAxisPulseFactor);// distanceToDropCenter/ RAIN_DROP_LENGTH) ;
	return pixelColor;	
}	

vec3 getPixelWorldPos(vec2 uv)
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

vec4 renderFogClouds(vec3 pixelPos)
{
	//TODO transfer volume_fog code
}

vec4 RayMarchRainBackgroundLight(in vec3 start, in vec3 end)
{	
	float l = length(end - start);
	const float numsteps = MAX_DEPTH_RESOLUTION;
	const float tstep = 1. / numsteps;
	bool highlight = mod(uv.x, 0.05) < 0.0001 && mod(uv.y, 0.05) < 0.0001;
	float depth = min(l * RAIN_THICKNESS_INV , 1.5);
	vec4 accumulatedColor = vec4(0.0, 0.0, 0.0, 0.0);
	accumulatedColor = GetGroundReflectionRipples(end);
	vec3 pxlPosWorld;
	for (float t=1.0; t>=0.; t-=tstep) 
	{
		pxlPosWorld = mix(start, end, t);
		accumulatedColor += renderRainPixel(highlight, pxlPosWorld, 0.5f) * tstep;
		//accumulatedColor += renderBackGroundLight(pxlPosWorld); TODO depends on transfer function
		accumulatedColor +=  renderFogClouds(pxlPosWorld);
	}
	//Prevent the rain from pixelating
	//accumulatedColor.a = max(0.25, accumulatedColor.a);
	return accumulatedColor;
}
											  


vec4 addRainDropsShader(vec4 originalColor, vec2 uv)
{
	return RED;
}

void GetWorldPos()
{
	dephtValueAtPixel = texture2D(depthtex, uv);
	vec4 ppos;
	ppos.xyz = vec3(uv, dephtValueAtPixel.r) * 2. - 1.; 
	ppos.a   = 1.;
	vec4 worldPos4 = viewProjectionInv * ppos;
	worldPos4.xyz /= worldPos4.w;

	if (depthValue == 1.0) 
	{
		vec3 forward = normalize(worldPos4.xyz - eyePos);
		float a = max(MAX_HEIGTH_RAIN - eyePos.y, eyePos.y - MIN_HEIGHT_RAIN) / forward.y;
		worldPos = eyePos + forward.xyz * abs(a);
		return;
	}
	worldPos = worldPos4.xyz;
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

float getAvgValueCol(vec4 col)
{
	return sqrt(col.r*col.r + col.g * col.g + col.r * col.r);
}

vec4 GetRainCoronaFromScreenTex() 
{
	vec2 upUv = uv;
	upUv.x += 0.1;
	vec4 colorAtUpPixel = texture2D(screentex, upUv);

	float avgDown = getAvgValueCol(origColor);
	float avgUp = getAvgValueCol(colorAtUpPixel);

	if (avgDown > avgUp && avgDown-avgUp > 0.25) return GREEN;
	if (avgDown < avgUp && avgUp - avgDown > 0.25) return BLUE;

	return NONE;//DELME
}

void main(void)
{
	uv = gl_FragCoord.xy / viewPortSize;	
	GetWorldPos();
	origColor = texture2D(screentex, uv);
	groundViewNormal = texture(normaltex, uv).xyz;

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
	pixelDir = normalize(startPos - endPos);

	vec4 accumulatedLightColorRayDownward = RayMarchRainBackgroundLight(startPos,  endPos); 

	float upwardnessFactor = 0.0;
	upwardnessFactor = GetUpwardnessFactorOfVector(viewDirection);

	//downWardrainColor =  downWardrainColor + vec4(0.25,0.0,0.0,0.0); //DELME DEBUG
	if (upwardnessFactor < 0.1 || eyePos.y > 1024.0 )
	{
		accumulatedLightColorRayDownward.a = min(0.25,accumulatedLightColorRayDownward.a);
	}

	if (isInIntervallAround(upwardnessFactor, 0.5, 0.125 ))
	{
	//	accumulatedLightColorRayDownward += GetRainCoronaFromScreenTex();
	}

	vec4 upWardrainColor = origColor;
	//if player looks upward mix drawing rain and start drawing drops on the camera
	//if (upwardnessFactor > 0.45)GetRainCoronaFromScreenTex
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
