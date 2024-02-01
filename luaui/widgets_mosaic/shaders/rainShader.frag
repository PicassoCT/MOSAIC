#version 150 compatibility	
#line 100001										 
//Defines //////////////////////////////////////////////////////////
#define PI 3.14159265359
#define PI_HALF (PI*0.5)
#define MAX_DEPTH_RESOLUTION 20.0
#define E_CONST 2.718281828459045235360287471352
#define TOTAL_SCAN_DISTANCE 8192.0
#define RAIN_RIPPLE_SCALE (4096.0 / 5.0)
#define WORLD_POS_SCALE (1./(4096.0 / 5.0))
#define WORLD_POS_OFFSET (1./(4096.0 / 5.0))

#define METER 0.0025
#define MAX_HEIGTH_RAIN 1024.0
#define MIN_HEIGHT_RAIN 0.0
#define TOTAL_LENGTH_RAIN (1024.0)
#define INTERVALLLENGTH_DISTANCE 30.0
#define INTERVALLLENGTH_TIME_SEC 25.0

#define MIRRORED_REFLECTION_FACTOR 0.55f
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

#define Y_NORMAL_CUTOFFVALUE 0.995
#define NONE vec4(0.0,0.0,0.0,0.0);
#define RED vec4(1.0, 0.0, 0.0, 1.0)
#define GREEN vec4(0.0, 1.0, 0.0, 1.0)
#define BLUE vec4(0.0, 0.0, 1.0, 1.0)
#define BLACK vec4(0.0, 0.0, 0.0, 1.0)
#define IDENTITY vec4(1.0,1.0,1.0,1.0)
#define SCAN_SCALE 64.0
#define RAIN_THICKNESS_INV (1./(TOTAL_LENGTH_RAIN))
#define RAIN_DROP_DIAMTER (0.06)
#define RAIN_DROP_LENGTH 5.12
#define RAIN_DROP_EMPTYSPACE 1.0

// Maximum number of cells a ripple can cross.
#define MAX_RADIUS 2
// Set to 1 to hash twice. Slower, but less patterns.
#define DOUBLE_HASH 0

// Hash functions shamefully stolen from:
// https://www.shadertoy.com/view/4djSRW
#define HASHSCALE1 .1031
#define HASHSCALE3 vec3(.1031, .1030, .0973)


//Constants aka defines for the weak /////////////////////////////////////
const float noiseCloudness= float(0.7) * 0.5;
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
uniform sampler2D normalunittex;
uniform sampler2D skyboxtex;


uniform float time;		
uniform float rainDensity;
uniform int maxLightSources;
uniform float timePercent;
uniform vec3 eyePos;
uniform vec3 sundir;
uniform vec3 suncolor;
uniform vec3 skycolor;

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

vec3 hash3( vec2 p )
{
    vec3 q = vec3(dot(p,vec2(127.1,311.7)), 
				  dot(p,vec2(269.5,183.3)), 
				  dot(p,vec2(419.2,371.9)));
	return fract(sin(q)*43758.5453);
}

float noise( in vec2 x, float speed)
{
    vec2 p = floor(x);
    vec2 f = fract(x);
		
	float va = 0.0;
    for( int j=-2; j<=2; j++ )
    for( int i=-2; i<=2; i++ )
    {
        vec2 g = vec2( float(i),float(j) );
		vec3 o = hash3( p + g );
		vec2 r = g - f + o.xy;
		float d = sqrt(dot(r,r));
	    float ripple = max(mix(smoothstep(0.99,0.999,max(cos(d - time*speed * 2. + (o.x + o.y) * 5.0), 0.)), 0., d), 0.);
        va += ripple;
    }
	
    return va;
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
		float lightSourceDistance = distance(Position, (lightSources[i].xyz*WORLD_POS_SCALE) + WORLD_POS_OFFSET);
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
float getZoomFactor()
{
	return max(1.0, eyePos.y / 128.0);
}

vec4 GetGroundPondRainRipples(vec2 groundUVs) 
{   
	float zoomFactor = getZoomFactor();
	float f = noise(  zoomFactor * 64.0 * uv, 0.6125); 
	vec3 normal = vec3(-dFdx(f), -dFdy(f), 0.5) + 0.5;
	float avgVal= (normal.x+normal.y+normal.z)/3.0;
	return vec4(vec3(avgVal), 0.75);
	float dotProduct = max(dot(normal, sundir), 0.0);
	return vec4(vec3(dotProduct), 0.75);
}

vec2 calculateCubemapUV(vec3 direction) {
    vec3 absDirection = abs(direction);
    float ma;
    vec2 uv;

    if (absDirection.x >= absDirection.y && absDirection.x >= absDirection.z) {
        ma = 0.5 / absDirection.x;
        if (direction.x > 0.0) {
            uv = vec2(0.5 - direction.z * ma, 0.5 - direction.y * ma);
        } else {
            uv = vec2(0.5 + direction.z * ma, 0.5 - direction.y * ma);
        }
    } else if (absDirection.y >= absDirection.x && absDirection.y >= absDirection.z) {
        ma = 0.5 / absDirection.y;
        if (direction.y > 0.0) {
            uv = vec2(0.5 + direction.x * ma, 0.5 + direction.z * ma);
        } else {
            uv = vec2(0.5 + direction.x * ma, 0.5 - direction.z * ma);
        }
    } else {
        ma = 0.5 / absDirection.z;
        if (direction.z > 0.0) {
            uv = vec2(0.5 + direction.x * ma, 0.5 - direction.y * ma);
        } else {
            uv = vec2(0.5 - direction.x * ma, 0.5 - direction.y * ma);
        }
    }

    return uv;
}

vec2 getSkyboxUVs(vec3 pos)
{
	const float  angle = radians(180.0);
    mat3 rotationMatrixYAxis = mat3(
        cos(angle), -sin(angle), 0.0,
        sin(angle),  cos(angle), 0.0,
        0.0,         0.0,        1.0);

	vec3 reflectionDir = rotationMatrixYAxis *pixelDir;
	// Mirror around pos z-axis

	return calculateCubemapUV(reflectionDir);
}

vec4 checkers(vec3 pos, float xOffset)
{
	pos.x += xOffset;
	float modFactor= 1.0;
	vec3 res = mod(pos, vec3(modFactor));
	if (res.x < modFactor/2 && res.z < modFactor/2) return RED;
	if (res.x > modFactor/2 && res.z > modFactor/2) return RED;
	return GREEN;
}



vec4 GetGroundReflectionRipples(vec3 pixelPos)
{
	if (groundViewNormal.g < Y_NORMAL_CUTOFFVALUE) return NONE;

	//return checkers(pixelPos, time/10.0);

	vec2 skyboxUV =  getSkyboxUVs(pixelPos);

	vec4 mirroredReflection = texture2D(skyboxtex, skyboxUV);
	
	return		MIRRORED_REFLECTION_FACTOR * BLUE*0.5  + 
				ADD_POND_RIPPLE_FACTOR * GetGroundPondRainRipples(pixelPos.xz);
}

float GetYAxisRainPulseFactor(float heigth, float offsetTimeFactor, vec4 randData)
{
	//TODO at random location and random times, have the rain wane
	// getTimeWiseOffset(offsetTimeFactor, RAIN_DROP_LENGTH), RAIN_DROP_LENGTH + RAIN_DROP_EMPTYSPACE , 0.0, RAIN_DROP_LENGTH );

	//make it stupid.. sawtooth pulses
	float timeOffset = time + offsetTimeFactor;
	float sawTooth = mod(timeOffset, INTERVALLLENGTH_TIME_SEC)/ INTERVALLLENGTH_TIME_SEC;
	float position = mod(heigth, INTERVALLLENGTH_DISTANCE)/INTERVALLLENGTH_DISTANCE;

	if (abs(position - sawTooth) < 0.1)
	{
		return 1.0 ;
	}

	return 0.0;
}

vec3 truncatePosition(in vec3 pixelPosTrunc)
{
	vec3 pixelPos = pixelPosTrunc;
	pixelPos.xz = pixelPos.xz - mod(pixelPos.xz, RAIN_DROP_DIAMTER);
	return pixelPos;
}
 
vec4 renderRainPixel(bool RainHighlight, vec3 pixelCoord, float localRainDensity, float onePixelfactor)
{	
	//if (mod(pixelCoord.x, 1.0)< 0.1 && mod(pixelCoord.z, 1.0) < 0.1) return RED;
	onePixelfactor= 0.125;
	//return mix(RED,BLACK, abs(sin(time +pixelCoord.y)) );
	vec4 pixelColor = GetDeterminiticRainColor(pixelCoord);//vec4(0.0,0.0,0.0,0.0);
	vec4 randData;
	float noiseValue = getDeterministicRandomValuePerPosition(pixelCoord, randData);
	vec3 pixelCoordTrunc = truncatePosition(pixelCoord);
	vec4 randDataTruncated;
	float noiseValueTruncated = getDeterministicRandomValuePerPosition(pixelCoordTrunc, randDataTruncated);
	float yAxisPulseFactor = GetYAxisRainPulseFactor(pixelCoord.y, noiseValue * 2.0 * INTERVALLLENGTH_TIME_SEC, randData);
	if (RainHighlight) return vec4(1.0, 1.0, 1.0, 0.85 *onePixelfactor);
	pixelColor = vec4(pixelColor.rgb * yAxisPulseFactor, yAxisPulseFactor *onePixelfactor);// distanceToDropCenter/ RAIN_DROP_LENGTH) ;
	
	return pixelColor ;	
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
///////////////////////////////////FOG ///////////////////////////////////////////////////////////
#define VOLUME_FOG_DENSITY         0.02
#define VOLUME_BRIGHTNESS_CLAMP    0.3

#define VOLUME_RES                 0.5
#define VOLUME_MAX_STEPS           16

#define VOLUME_USE_NOISE           YES
#define VOLUME_ANIMATE_NOISE       YES

#define VOLUME_USE_BILATERAL_BLUR  YES
#define VOLUME_BLUR_SIZE           0.0025
#define VOLUME_BLUR_QUALITY        2.0
#define VOLUME_BLUR_DIRECTIONS     8.0

#define VOLUME_USE_TAA             YES
#define VOLUME_DEBUG_TAA           NO
#define VOLUME_TAA_MAX_REUSE       0.9
#define VOLUME_TAA_MAX_DIST        0.5

vec4 renderFogClouds(vec3 pixelPos)
{
	/*
  	float startOffset = 0.0;

    #if VOLUME_USE_NOISE == 1
    int frame = 0;
        #if VOLUME_ANIMATE_NOISE == 1
            frame = iFrame % 64;
        #endif
    
    float goldenRatio = 1.61803398875;
    float invGoldenRatio = 1.0/goldenRatio;
    
    float blue = texture(iChannel1, pixel / 1024.0f).r;
    startOffset = blue * 1.0;
    startOffset = fract(blue + float(frame) * invGoldenRatio);
    #endif

    float fogLitPercent = 0.0;
    for (int i = 0; i < VOLUME_MAX_STEPS; ++i) {
        float rayPercent = (startOffset + float(i)) / float(VOLUME_MAX_STEPS);
        float rayStep = rayPercent * hitDistance;
        
        vec3 o = ro + rd * rayStep;
        Hit h = trace(o, l, 64, FAR_PLANE, SURF_HIT);
        
        fogLitPercent = mix(fogLitPercent, (h.dist >= FAR_PLANE) ? 1.0 : 0.0, 1.0f / float(i+1));
    }
    
    vec3 fogColor = mix(vec3(0, 0, 0), lightColor, fogLitPercent);
    float absorb = exp(-hitDistance * VOLUME_FOG_DENSITY);
    
    // return mix(fogColor, vec3(0, 0, 0), absorb);
    return clamp(1.-absorb, 0.0, VOLUME_BRIGHTNESS_CLAMP) * fogColor;
	*/
	return BLACK;
}


vec4 RayMarchRainBackgroundLight(in vec3 start, in vec3 end)
{	
	float l = length(end - start);
	const float numsteps = MAX_DEPTH_RESOLUTION;
	const float tstep = 1. / numsteps;
	
	float depth = min(l * RAIN_THICKNESS_INV , 1.5);
	vec4 accumulatedColor = vec4(0.0, 0.0, 0.0, 0.0);
	accumulatedColor = GetGroundReflectionRipples(end);
	 //return accumulatedColor;DELME 
	vec3 pxlPosWorld;
	for (float t=1.0; t > 0.0; t -=tstep) 
	{
		pxlPosWorld = mix(start, end, t);
		bool highlight = mod(pxlPosWorld.x, 0.5) < 0.0025 && mod(pxlPosWorld.z, 0.5) < 0.0025;
		accumulatedColor += renderRainPixel(highlight , pxlPosWorld, 0.5f, tstep);
		//accumulatedColor += renderBackGroundLight(pxlPosWorld); TODO depends on transfer function
		//accumulatedColor +=  renderFogClouds(pxlPosWorld);
	}
	//Prevent the rain from pixelating
	//accumulatedColor.a = max(0.25, accumulatedColor.a);
	return accumulatedColor;
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
	vec4 unitViewNormal = texture(normalunittex, uv);
	//gl_FragColor = vec4(vec3(unitViewNormal.a), 0.75);
	//return;

	if (unitViewNormal.rgb != BLACK.rgb && unitViewNormal.a > 0.5) groundViewNormal = unitViewNormal.rgb;
	//gl_FragColor = vec4(groundViewNormal, 0.75);
	//return;
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
