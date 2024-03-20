#version 150 compatibility	
#line 100001										 
//Defines //////////////////////////////////////////////////////////
#define PI 3.1415926535897932384626433832795
#define PI_HALF (PI*0.5)
#define MAX_DEPTH_RESOLUTION 20.0
#define E_CONST 2.718281828459045235360287471352

#define WORLD_POS_SCALE (1.0)
#define WORLD_POS_OFFSET vec3(0,0,0)


#define MAX_HEIGTH_RAIN 1024.0
#define MIN_HEIGHT_RAIN 0.0
#define TOTAL_LENGTH_RAIN (1024.0)
#define INTERVALLLENGTH_DISTANCE 30.0
#define INTERVALLLENGTH_TIME_SEC 1.0

#define MIRRORED_REFLECTION_FACTOR 0.275f
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
#define NONE vec4(0.0,0.0,0.0,0.0)
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
uniform sampler2D modelDepthTex;
uniform sampler2D mapDepthTex;
uniform sampler2D noisetex;
uniform sampler2D screentex;
uniform sampler2D normaltex;
uniform sampler2D normalunittex;
uniform sampler2D skyboxtex;
uniform sampler2D raintex;

uniform vec4 lightSources[20];

uniform float time;		

uniform int maxLightSources;
uniform float timePercent;
uniform float rainPercent;
uniform vec3 eyePos;
uniform vec3 sundir;
uniform vec3 suncolor;
uniform vec3 skycolor;

uniform vec2 viewPortSize;
uniform vec3 cityCenter;
uniform mat4 viewProjectionInv;
uniform mat4 viewProjection;
uniform mat4 viewInv;
uniform mat4 viewMatrix;


//Struc Definition				//////////////////////////////////////////////////////////
//Lightsource description 
/*
{
vec4  position + strength
vec4  color + id
}
*/


in Data {
			vec3 fragVertexPosition;
			vec3 viewDirection;			
		 };

struct Ray {
	vec3 Origin;
	vec3 Dir;
};

struct ColorResult{
	vec4 color;
	bool earlyOut;
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
vec3 viewNormal;
float cameraZoomFactor;
float screenScaleFactorY = 0.1;

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

bool isAbsInIntervallAround(float value, float targetValue, float intervall)
{
	return abs(value) +intervall >= abs(targetValue) && abs(value) - intervall <= abs(targetValue);
}
float deterministicFactor(vec2 val)
{
	return mod((abs(val.x) + abs(val.y))/2.0, 1.0);
}

vec4 getDeterministicColorOffset(vec2 position)
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

vec4 getUVRainbow(vec2 uvs){
	uvs = normalize(uvs);
	vec4 result  = mix(RED, mix(BLUE, GREEN, uvs.y), uvs.x);
	result.a = 0.75;
	return result;
}

float GetUpwardnessFactorOfVector(vec3 vectorToCompare)
{
	return dot(normalize(vectorToCompare), upwardVector);
}

//Various helper functions && Tools //////////////////////////////////////////////////////////

vec4 GetDeterministicRainColor( vec2 uvx)
{
	vec4 rainHighDayColor;
	vec4 rainHighNightColor;
	vec4 outsideCityRainDayCol;
	vec4 outsideCityRainNightCol;

	//basically rain deeper down needs to be slightly darker
	float darkenFactor = mix(0.85, 1.0, uvx.y/viewPortSize.y);
	float depthOfDropFactor = min(1.0, uvx.y/ viewPortSize.y);

  	// Night
	rainHighNightColor =  vec4(suncolor, 1.0) * NIGHT_RAIN_HIGH_COL;
	outsideCityRainNightCol = mix(rainHighNightColor, NIGHT_RAIN_DARK_COL, depthOfDropFactor);
	outsideCityRainNightCol.rgb *= darkenFactor;
	;
	
	//Day
	rainHighDayColor =  vec4(suncolor, 1.0) * DAY_RAIN_HIGH_COL;
	outsideCityRainDayCol = mix(rainHighDayColor, DAY_RAIN_DARK_COL, depthOfDropFactor);
	outsideCityRainDayCol.rgb *= darkenFactor;

	return mix(outsideCityRainDayCol, outsideCityRainNightCol, getDayPercent()  );
}

bool IsInGridPoint(vec3 pos, float size, float space)
{
	return ((mod(pos.x, space) < size) &&   (mod(pos.y, space) < size)  && (mod(pos.z, space) < size)) ;
}

//REFLECTIONMARCH  
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

vec2 calculateCubemapUV(vec3 direction) 
{
    vec3 absDirection = abs(direction);
    float ma;
    vec2 uvs;

    if (absDirection.x >= absDirection.y && absDirection.x >= absDirection.z) {
        ma = 0.5 / absDirection.x;
        if (direction.x > 0.0) {
            uvs = vec2(0.5 - direction.z * ma, 0.5 - direction.y * ma);
        } else {
            uvs = vec2(0.5 + direction.z * ma, 0.5 - direction.y * ma);
        }
    } else if (absDirection.y >= absDirection.x && absDirection.y >= absDirection.z) {
        ma = 0.5 / absDirection.y;
        if (direction.y > 0.0) {
            uvs = vec2(0.5 + direction.x * ma, 0.5 + direction.z * ma);
        } else {
            uvs = vec2(0.5 + direction.x * ma, 0.5 - direction.z * ma);
        }
    } else {
        ma = 0.5 / absDirection.z;
        if (direction.z > 0.0) {
            uvs = vec2(0.5 + direction.x * ma, 0.5 - direction.y * ma);
        } else {
            uvs = vec2(0.5 - direction.x * ma, 0.5 - direction.y * ma);
        }
    }
	return uvs;
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

bool getRivuletMask(vec3 normalAtPos)
{
	float treshold = 0.01;
	if ((abs(normalAtPos.x) < treshold || abs(normalAtPos.y) < treshold || abs(normalAtPos.z) < treshold)) return false;

	vec2 rivUv = normalAtPos.xz;
	rivUv.x +=  0.125 *  sin(time*0.01)* cos(time*0.021);
	rivUv.y +=  0.125 * cos((time)*0.01) *sin(time*0.042);

	float sinX = sin(rivUv.x);
	float cosX = cos(rivUv.x);
	float sizeIntervall = 0.25* (0.25 + abs(0.25*sin(time*0.0125)));

return( isAbsInIntervallAround(sinX, rivUv.y, sizeIntervall) ||
		isAbsInIntervallAround(cosX, rivUv.y, sizeIntervall) ||	
		isAbsInIntervallAround( 1/sinX, rivUv.y, sizeIntervall) ||	
		isAbsInIntervallAround( 1/cosX, rivUv.y, sizeIntervall));
}

vec4 GetGroundReflectionRipples(vec3 pixelPos)
{
	bool rivuletRunning = false;
	float groundMixFactor = 1.0;
	if (viewNormal.g < Y_NORMAL_CUTOFFVALUE) 
	{
		//rivulets
		if (!(viewNormal.g  > 0.95)) return NONE;


		rivuletRunning = getRivuletMask(viewNormal); //TODO get ground coord 
		if (!rivuletRunning) return NONE;

		groundMixFactor= (abs(viewNormal.r) + abs(viewNormal.g) + abs(viewNormal.b))/1.73205;
	}

	//return checkers(pixelPos, time/10.0);
	vec4 mirroredReflection = texture2D(skyboxtex, getSkyboxUVs(pixelPos));

	return mix(NONE,
			  MIRRORED_REFLECTION_FACTOR * BLUE  + ADD_POND_RIPPLE_FACTOR * GetGroundPondRainRipples(pixelPos.xz),
			  groundMixFactor);	
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

vec4 RayMarchCompose(in vec3 start, in vec3 end)
{	
	float l = length(end - start);
	const float numsteps = MAX_DEPTH_RESOLUTION;
	const float tstep = 1. / numsteps;

	vec4 accumulatedColor = vec4(0.0, 0.0, 0.0, 0.0);
	accumulatedColor = GetGroundReflectionRipples(end);

	return accumulatedColor;
}
											  
void GetWorldPos()
{
	dephtValueAtPixel = texture2D(mapDepthTex, uv);
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
	upUv.x -= 2;
	vec3 groundBelowNormal= texture(normaltex, upUv).xyz;
	vec3 unitViewNormal = texture(normalunittex, upUv).xyz;
	if (unitViewNormal.rgb != BLACK.rgb) groundBelowNormal = unitViewNormal.rgb;
	if (groundBelowNormal.g >  Y_NORMAL_CUTOFFVALUE) 
	{
		return vec4( 1.0, 1.0, 1.0, 0.125);
	}
	return NONE;
}

vec3 mergeGroundViewNormal()
{
	float modelDepth = texture(modelDepthTex, uv).r;
	float mapDepth = texture(mapDepthTex, uv).r;
	float modelOccludesMap = float(modelDepth < mapDepth);
	vec3 mapNormal = texture(normaltex, uv).xyz;
	vec3 modelNormal = texture(normalunittex, uv).xyz;

	return mix(mapNormal, modelNormal, modelOccludesMap);
}

vec4 getRainTexture(vec2 uv, float rainspeed, float timeOffset)
{
	//vec2 scaleFactor = vec2(screenScaleFactorY, 1.0)* 0.001; 
	vec2 rainUv = uv ;//* scaleFactor;
	rainUv.y = -1.0 * rainUv.y - (time + timeOffset) * rainspeed; 
	return texture2D(raintex, rainUv);
}

vec4 drawRainInSpainOnPlane(vec2 uv, float rainspeed, float timeOffset)
{	
	vec4 backGroundRain = vec4(0.0, 0.0,0,0.5);

	backGroundRain = getRainTexture(uv, rainspeed, 0.0 + timeOffset);
 	
	return backGroundRain;// * GetDeterministicRainColor(uv);	
}

/*

void main()
{
    // Define the center of the cylinder
    vec3 cylinderCenter = eyePos + viewDirection * cylinderHeight * 0.5;

    // Calculate the vector from the camera to the current fragment
    vec3 fragmentToEye = normalize(eyePos - vec3(TexCoords, 0.0));

    // Calculate the vector from the fragment to the center of the cylinder
    vec3 fragmentToCenter = normalize(cylinderCenter - vec3(TexCoords, 0.0));

    // Calculate the distance from the fragment to the center of the cylinder
    float distanceToCenter = length(cylinderCenter - vec3(TexCoords, 0.0));

    // Calculate the radius of the cylinder
    float cylinderRadius = cylinderDiameter * 0.5;

    // Determine if the fragment is inside the cylinder
    bool insideCylinder = distanceToCenter <= cylinderRadius;

    // Determine the orientation of the cylinder
    vec3 upVector = vec3(0.0, 0.0, 1.0); // Assuming cylinder is always oriented upright

    // Calculate the angle between the fragment's direction and the up vector
    float angle = dot(fragmentToCenter, upVector);

    // Apply red-green chessboard pattern
    vec2 chessboardCoords = abs(mod(TexCoords * 10.0, 2.0) - 1.0);

    // If inside the cylinder and upright, color green, otherwise color red
    vec3 color = (insideCylinder && abs(angle) > 0.95) ? vec3(chessboardCoords.x, chessboardCoords.y, 0.0) : vec3(1.0, 0.0, 0.0);

    FragColor = vec4(color, 1.0);
}
*/

vec4 calculateCylinderUV(vec3 direction, float cylinderHeight, float cylinderDiameter, float uscale, float vscale) 
{
	 // Define the center of the cylinder
    vec3 cylinderCenter = eyePos + viewDirection * cylinderHeight * 0.5;

    // Calculate the vector from the camera to the current fragment
    vec3 fragmentToEye = normalize(eyePos - vec3(TexCoords, 0.0));

    // Calculate the vector from the fragment to the center of the cylinder
    vec3 fragmentToCenter = normalize(cylinderCenter - vec3(TexCoords, 0.0));

    // Calculate the distance from the fragment to the center of the cylinder
    float distanceToCenter = length(cylinderCenter - vec3(TexCoords, 0.0));

    // Calculate the radius of the cylinder
    float cylinderRadius = cylinderDiameter * 0.5;

    // Determine if the fragment is inside the cylinder
    bool insideCylinder = distanceToCenter <= cylinderRadius;

    // Determine the orientation of the cylinder
    vec3 upVector = vec3(0.0, 0.0, 1.0); // Assuming cylinder is always oriented upright

    // Calculate the angle between the fragment's direction and the up vector
    float angle = dot(fragmentToCenter, upVector);

    // Apply red-green chessboard pattern
    vec2 chessboardCoords = abs(mod(TexCoords * 10.0, 2.0) - 1.0);

    // If inside the cylinder and upright, color green, otherwise color red
    vec3 color = (insideCylinder && abs(angle) > 0.95) ? GREEN.rgb : RED.rgb;
    return vec4(color, 1.0);

    //vec2 cylinderUV = vec2(atan(fragmentToCenter.y, fragmentToCenter.x) / (2.0 * PI) + 0.5, (fragmentToCenter.z + 0.5) * cylinderHeight);
	//cylinderUV.u *= uscale;
	//cylinderUV.v *= vscale;
//
    //return cylinderUV;
}


vec4 debug_uv_color(vec2 uv) {
    return vec4(uv.x, uv.y, 1.0 - uv.x * uv.y, 0.5);// Use UV coordinates to generate a color
}

vec4 calculateRainCylinderColors ()
{
	//if (abs(normalize(viewDirection).y) > 0.8) return NONE;
	//return vec4(normalize(viewDirection), 0.8);
	float scale = 1.0;
	//vec2 uvs =
	return calculateCylinderUV(viewDirection, 2048.0, 512.0,  scale, scale); 	

	//return debug_uv_color(uvs);
	float randDet = 0.0;

	//return drawRainInSpainOnPlane(normalize(viewDirection).xy,  0.0001, randDet);
}

void main(void)
{
	uv = gl_FragCoord.xy / viewPortSize;	
	screenScaleFactorY = viewPortSize.x/viewPortSize.y;
	GetWorldPos();
	origColor = texture2D(screentex, uv);

	viewNormal = mergeGroundViewNormal();
	cameraZoomFactor = max(0.0,min(eyePos.y/2048.0, 1.0));

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

	vec4 accumulatedLightColorRayDownward = RayMarchCompose(startPos,  endPos); // should be eyepos + eyepos *offset*vector for deter

	float upwardnessFactor = 0.0;
	upwardnessFactor = GetUpwardnessFactorOfVector(viewDirection);

	//downWardrainColor =  downWardrainColor + vec4(0.25,0.0,0.0,0.0); //DELME DEBUG
	if (upwardnessFactor < 0.1 || eyePos.y > 1024.0 )
	{
		accumulatedLightColorRayDownward.a = min(0.25,accumulatedLightColorRayDownward.a);
	}

	accumulatedLightColorRayDownward = calculateRainCylinderColors();
	gl_FragColor =accumulatedLightColorRayDownward;
	if (isInIntervallAround(upwardnessFactor, 0.5, 0.125 ))
	{
		//accumulatedLightColorRayDownward += GetRainCoronaFromScreenTex();
	}

	vec4 upWardrainColor = origColor;
	//if player looks upward mix drawing rain and start drawing drops on the camera
	//if (upwardnessFactor > 0.45)
	//{
	//https://www.youtube.com/watch?v=W0_zQ-WdxH4
	//	upWardrainColor = mix(downWardrainColor, upWardrainColor, (upwardnessFactor - 0.5) * 2.0);
	//	gl_FragColor = upWardrainColor;
	//}	
	//else //no Raindrops blended in
	//{
		//gl_FragColor = mix(accumulatedLightColorRayDownward, vec4(0.) ,1.0 -rainPercent); 
	//}

	//gl_FragColor.a *= smoothstep(gl_Fog.end * 10.0, gl_Fog.start, length(worldPos - eyePos));
	
}
