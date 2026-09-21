#version 150 compatibility	
#line 100001										 
//Defines //////////////////////////////////////////////////////////
//CONSTANTS
#define PI 3.1415926535897932384626433832795
#define PI_HALF (PI*0.5)
#define MAX_DEPTH_RESOLUTION 20.0
#define E_CONST 2.718281828459045235360287471352
#define NONE vec4(0.0,0.0,0.0,0.0)
#define RED vec4(1.0, 0.0, 0.0, 0.95)
#define GREEN vec4(0.0, 1.0, 0.0, 0.95)
#define BLUE vec4(0.0, 0.0, 1.0, 0.95)
#define BLACK vec4(0.0, 0.0, 0.0, 0.95)
#define IDENTITY vec4(1.0,1.0,1.0,1.0)


//CONFIGUREABLES
#define MAX_RAY_MARCH_DISTANCE 250.0
#define DROPLETT_BASE_SCALE 4.0
#define MAX_HEIGTH_RAIN 1024.0
#define MIN_HEIGHT_RAIN 0.0
#define TOTAL_LENGTH_RAIN (1024.0)
#define INTERVALLLENGTH_DISTANCE 30.0
#define INTERVALLLENGTH_TIME_SEC 1.0
#define Y_NORMAL_CUTOFFVALUE 0.995
#define Y_NORMAL_BLEND_OVER_CUTOFFVALUE 0.993
#define DROPLETT_SCALE 8.0

//DayColors
#define DAY_RAIN_HIGH_COL vec4(1.0,1.0,1.0,1.0)
#define DAY_RAIN_DARK_COL vec4(0.21,0.32,0.40,1.0)
//NightColors
#define NIGHT_RAIN_HIGH_COL vec4(0.75,0.75,0.75,1.0)
#define NIGHT_RAIN_DARK_COL vec4(0.14,0.14,0.12,1.0)
#define MIRRORED_REFLECTION_FACTOR 0.275f
#define ADD_POND_RIPPLE_FACTOR 0.75f
// Shared by ripple rings and the sparse splashback impact subset.
#define RAIN_RIPPLE_SCALE 1.125
#define RAIN_RIPPLE_SPEED 1.5

//Functions
#define NORM2SNORM(value) (value * 2.0 - 1.0)
#define lind(value) (fract(0.2* (1.0/(1.0 - value))))
#define OFFSET_COL_MIN vec4(-0.05,-0.05,-0.05,0.1)
#define OFFSET_COL_MAX vec4(0.15,0.15,0.15,0.1)
#define SCAN_SCALE 64.0


//Constants aka defines for the weak /////////////////////////////////////
const float noiseCloudness= float(0.7) * 0.5;
const float scale = 1./SCAN_SCALE;		 
const vec3 vMinima = vec3(-300000.0, MIN_HEIGHT_RAIN, -300000.0);
const vec3 vMaxima = vec3( 300000.0, MAX_HEIGTH_RAIN,  300000.0);
const vec3 upwardVector = vec3(0.0, 1.0, 0.0);
const float sixSeconds = 6.0;

//Uniforms
uniform sampler2D modelDepthTex;
uniform sampler2D mapDepthTex;
uniform sampler2D rainDroplettTex;
uniform sampler2D screentex;
uniform sampler2D normaltex;
uniform sampler2D normalunittex;

uniform sampler2D noisetex;
uniform sampler2D raintex;
uniform sampler2D dephtCopyTex;


uniform float time;		
uniform float timePercent;
uniform float rainPercent;
uniform float clipZeroToOne;
uniform float reflectionDebug;
uniform float rainDetailDebug;
uniform vec3 eyePos;
uniform vec3 eyeDir;
uniform vec3 sunCol;
uniform vec3 sunPos;
uniform vec3 skyCol;

uniform vec2 viewPortSize;
uniform vec3 cityCenter;
uniform mat4 viewProjectionInv;
uniform mat4 viewProjection;
uniform mat4 projection;
uniform mat4 viewInv;
uniform mat4 viewMatrix;


//Struct Definition				//////////////////////////////////////////////////////////

in Data {
			vec3 viewDirection;
			vec4 fragWorldPos;
			noperspective vec2 v_screenUV;
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
//Debug Code         				//////////////////////////////////////////////////////////
vec4 debug_getUVRainbow(vec2 uvs){
	uvs = normalize(uvs);
	vec4 result  = mix(RED, mix(BLUE, GREEN, uvs.y), uvs.x);
	result.a = 0.75;
	return result;
}

vec4 debug_uv_color(vec2 uv) 
{
    return vec4(uv.x, uv.y, 1.0 - uv.x * uv.y, 0.5);// Use UV coordinates to generate a color
}

void debug_testRenderColor(vec3 color)
{	
	gl_FragColor = vec4( color , 1.0);
}

//Global Variables					//////////////////////////////////////////////////////////
vec2 uv;
vec2 sourceRotatedUV;
vec3 worldPos;
vec4 mapDepth;
vec4 depthAtPixel;
vec4 modelDepth;
vec3 pixelDir;
vec4 origColor;
vec3 vertexNormal;
vec3 sunDir;
vec3 detailNormals;
vec3 runoffEnergy = vec3(0);
float runoffCoverage = 0.0;
float cameraZoomFactor;
float screenScaleFactorY = 0.1;
bool  NormalIsOnGround = false;
bool  NormalIsOnUnit = false;
bool NormalIsWaterPuddle = false;
bool NormalIsSky = false;

//TODO https://www.cs.columbia.edu/cg/normalmap/normalmap.pdf
float extractRoughnessFromNormal(vec3 x)
{
return (x.x + x.y + x.z)/3.0;
}

vec4 screen(vec4 a, vec4 b)
{
	return vec4(1.)-(vec4(1.)-a)*(vec4(1.)-b);
}

vec4 dodge(vec4 bottom, vec4 top)
{
	return bottom + top;
}

float vectorDirectionSimilarity(vec3 v1, vec3 v2) {
    return dot(v1, v2) / (length(v1) * length(v2));
}

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

float absinthTime()
{
	return abs(sin(time));
}

vec3 GetWorldPosAtUV(vec2 uvs, float depthPixel)
{
    float ndcDepth = mix(depthPixel * 2.0 - 1.0, depthPixel, clipZeroToOne);
    vec4 position = viewProjectionInv * vec4(uvs * 2.0 - 1.0, ndcDepth, 1.0);
    // Only background pixels can lie at an infinite far plane.
    if (abs(position.w) < 0.0000001)
        return eyePos + normalize(eyeDir) * 100000.0;
    return position.xyz / position.w;
}

//https://virtexedgedesign.wordpress.com/2018/06/24/shader-series-basic-screen-space-reflections/
//https://github.com/maorachow/monogameMinecraft/blob/1bb43fefb63819db91f89500db736cb90ecd9115/Content/ssreffect.fx#L81

vec3  GetUVAtPosInView(vec3 worldPos)
{
	vec4 ProjectionPos =  viewProjection * vec4(worldPos, 1.0)  ;
	ProjectionPos.xyz /= ProjectionPos.w;
    ProjectionPos.xy = ProjectionPos.xy * 0.5 + 0.5;
	// Convert to normalized device coordinates
	return ProjectionPos.xyz;
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
	if (timePercent < 0.5)
	{
		return timePercent * 2.0;
	}
	else
	{
		return 1.0 - ((timePercent - 0.5) * 2.0);
	}
}

float getRandomFactor(vec2 factor)
{
	return texture2D(noisetex, factor).r;
}

vec4 getVectorColor(vec3 vector){
	vec4 result  = mix(RED,  BLACK, vector.y);
	result.a = 0.75;
	return result;
}

float GetUpwardnessFactorOfVector(vec3 vectorToCompare)
{
	float vector=  dot(normalize(vectorToCompare), upwardVector);
	return (vector+1.0);
}

vec3 SobelNormalFromScreen(vec2 uvx)
{
	if (!NormalIsWaterPuddle) return BLACK.rgb;
   
    // Sample the surrounding pixels
    float left = texture2D(screentex, uvx - vec2(1.0 / viewPortSize.x, 0)).r;
    float right = texture2D(screentex, uvx + vec2(1.0 / viewPortSize.x, 0)).r;
    float top = texture2D(screentex, uvx + vec2(0, 1.0 / viewPortSize.y)).r;
    float bottom = texture2D(screentex, uvx - vec2(0, 1.0 / viewPortSize.y)).r;

    // Calculate the gradients using Sobel operator
    float dX = (right - left) * 0.5;
    float dY = (top - bottom) * 0.5;

    // Normalize the gradients and create a normal vector
    vec3 normal = normalize(vec3(dX, dY, 1.0));

    return normal;
    // Convert the normal from [-1,1] to [0,1] range
    //normal = normal * 0.5 + 0.5;
}

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
	rainHighNightColor =  vec4(sunCol, 1.0) * NIGHT_RAIN_HIGH_COL;
	outsideCityRainNightCol = mix(rainHighNightColor, NIGHT_RAIN_DARK_COL, depthOfDropFactor);
	outsideCityRainNightCol.rgb *= darkenFactor;
	;
	
	//Day
	rainHighDayColor =  vec4(sunCol, 1.0) * DAY_RAIN_HIGH_COL;
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
/////////////////////////////////////////////////////////////////////////////////////////////
// Plastic Shrink Wrap  //
#define OFFSET_X 1
#define OFFSET_Y 1
#define DEPTH	 5.5

vec3 GetGroundVertexNormal(vec2 theUV, out bool IsOnGround, out bool IsOnUnit,
                          out bool IsWaterPuddle, out bool IsSky)
{
    vec4 unitNormal = texture2D(normalunittex, theUV);
    vec4 groundNormal = texture2D(normaltex, theUV);
    float groundDepth = texture2D(mapDepthTex, theUV).r;
    float unitDepth = texture2D(modelDepthTex, theUV).r;
    // Restore the original normal-buffer eligibility. Normal alpha is not a
    // portable presence flag; a populated normal must not disappear just because
    // the corresponding deferred depth is clear/unavailable on this render path.
    bool hasGround = dot(groundNormal.rgb, groundNormal.rgb) > 0.0;
    bool hasUnit = dot(unitNormal.rgb, unitNormal.rgb) > 0.0;

    IsOnUnit = hasUnit && (!hasGround || unitDepth < groundDepth);
    IsOnGround = hasGround && !IsOnUnit;
    IsSky = !IsOnGround && !IsOnUnit;
    // Keep encoded values for the existing material masks; decode for lighting/reflection.
    vec3 encodedNormal = IsOnUnit ? unitNormal.rgb : groundNormal.rgb;
    IsWaterPuddle = !IsSky && encodedNormal.g >= Y_NORMAL_CUTOFFVALUE;
    return encodedNormal;
}

// G-buffer normals describe shading (including material normal maps), not
// necessarily drainage geometry. Reconstruct the same world-space slope for
// map and model surfaces. Shorter one-sided tangents avoid crossing silhouettes.
float rainSurfaceDepth(vec2 at, bool unitSurface) {
    return unitSurface ? texture2D(modelDepthTex,at).r : texture2D(mapDepthTex,at).r;
}
vec3 rainGeometryNormal(vec2 at, bool unitSurface, vec3 fallback) {
    if(min(viewPortSize.x,viewPortSize.y)<1.0) return fallback;
    float depth=rainSurfaceDepth(at,unitSurface);
    if(depth>=0.999999) return fallback;
    vec2 texel=1.0/viewPortSize;
    vec3 p=GetWorldPosAtUV(at,depth);
    vec3 tangents[4];
    for(int i=0;i<4;++i) {
        vec2 offset=i==0 ? vec2(texel.x,0) : i==1 ? vec2(-texel.x,0)
                    : i==2 ? vec2(0,texel.y) : vec2(0,-texel.y);
        vec2 neighbor=at+offset;
        float d=rainSurfaceDepth(neighbor,unitSurface);
        bool valid=d<0.999999 && all(greaterThanEqual(neighbor,vec2(0)))
                                  && all(lessThanEqual(neighbor,vec2(1)));
        tangents[i]=valid ? GetWorldPosAtUV(neighbor,d)-p : vec3(1.0e10);
    }
    vec3 dx=dot(tangents[0],tangents[0])<dot(tangents[1],tangents[1]) ? tangents[0] : -tangents[1];
    vec3 dy=dot(tangents[2],tangents[2])<dot(tangents[3],tangents[3]) ? tangents[2] : -tangents[3];
    vec3 n=cross(dx,dy);
    if(dot(n,n)<1.0e-12 || max(dot(dx,dx),dot(dy,dy))>1.0e18) return fallback;
    n=normalize(n);
    return dot(n,eyePos-p)<0.0 ? -n : n;
}

vec3 sampleNormal(const int x, const int y, in vec2 fragCoord)
{
	vec2 ouv = fragCoord + vec2(x, y) / viewPortSize.xy;
	bool IsOnGround = false;
	bool IsOnUnit = false;
	bool IsWaterPuddle = false;
	bool IsSky = false;
	vec3 normal = GetGroundVertexNormal(ouv,  IsOnGround, IsOnUnit, IsWaterPuddle, IsSky);
	if (IsOnGround || IsOnUnit) return normal.rgb;
	return NONE.rgb;
}

float luminance(vec3 c)
{
	return dot(c, vec3(.2126, .7152, .0722));
}

vec3 GetNormals(in vec2 fragCoord)
{
	float R = abs(luminance(sampleNormal( OFFSET_X,0, fragCoord)));
	float L = abs(luminance(sampleNormal(-OFFSET_X,0, fragCoord)));
	float D = abs(luminance(sampleNormal(0, OFFSET_Y, fragCoord)));
	float U = abs(luminance(sampleNormal(0,-OFFSET_Y, fragCoord)));
				 
	float X = (L-R) * .5;
	float Y = (U-D) * .5;

	return normalize(vec3(X, Y, 1. / DEPTH));
}

vec4 GetShrinkWrappedSheen(vec3 pixelWorldPos)
{
    vec3 screenDetail = GetNormals(uv) + SobelNormalFromScreen(uv);
    vec3 n = normalize(vertexNormal * 2.0 - 1.0);
    // Screen derivatives are directions: rotate them before adding to a world normal.
    n = normalize(n + 0.15 * mat3(viewInv) * vec3(screenDetail.xy, 0.0));
    detailNormals = n * 0.5 + 0.5;
    vec3 lightDir = normalize(sunDir);
    vec3 toEye = normalize(eyePos - pixelWorldPos);
    float diffuse = max(dot(n, lightDir), 0.0);
    float specular = pow(max(dot(reflect(-lightDir, n), toEye), 0.0), 64.0);
    return vec4(skyCol * (0.15 * diffuse + specular), 1.0);
}

 
// Bounded screen-space reflection tracing. All distances below are world/view units.
const int REFLECTION_STEPS = 32;
const int REFLECTION_REFINE_STEPS = 6;
const float REFLECTION_DISTANCE = 1024.0;
const float REFLECTION_THICKNESS = 3.0;

bool reflectionDepthDelta(vec3 position, out vec2 screenUV, out float delta)
{
    vec4 projected = viewProjection * vec4(position, 1.0);
    if (projected.w <= 0.00001) return false;
    vec3 ndc = projected.xyz / projected.w;
    screenUV = ndc.xy * 0.5 + 0.5;
    float nearDepth = mix(-1.0, 0.0, clipZeroToOne);
    if (any(lessThanEqual(screenUV, vec2(0.0))) ||
        any(greaterThanEqual(screenUV, vec2(1.0))) ||
        ndc.z < nearDepth || ndc.z > 1.0) return false;

    float depth = texture2D(dephtCopyTex, screenUV).r;
    // Empty background is in front of any potential later geometry intersection.
    delta = -1.0e20;
    if (depth >= 0.999999) return true;
    vec3 surface = GetWorldPosAtUV(screenUV, depth);
    float rayDepth = -(viewMatrix * vec4(position, 1.0)).z;
    float surfaceDepth = -(viewMatrix * vec4(surface, 1.0)).z;
    delta = rayDepth - surfaceDepth;
    return true;
}

vec4 rayMarchForReflection(vec3 reflectionPosition, vec3 reflectDir)
{
    float previousDistance = 0.0;
    bool wasInFront = false;
    for (int i = 1; i <= REFLECTION_STEPS; ++i)
    {
        float fraction = float(i) / float(REFLECTION_STEPS);
        float distanceAlongRay = 0.5 + REFLECTION_DISTANCE * fraction * fraction;
        vec2 hitUV;
        float delta;
        if (!reflectionDepthDelta(reflectionPosition + reflectDir * distanceAlongRay,
                                  hitUV, delta)) return NONE;

        if (delta >= 0.0 && wasInFront)
        {
            float low = previousDistance;
            float high = distanceAlongRay;
            for (int j = 0; j < REFLECTION_REFINE_STEPS; ++j)
            {
                float middle = 0.5 * (low + high);
                vec2 middleUV;
                float middleDelta;
                if (!reflectionDepthDelta(reflectionPosition + reflectDir * middle,
                                          middleUV, middleDelta)) return NONE;
                if (middleDelta >= 0.0) high = middle;
                else low = middle;
            }
            if (!reflectionDepthDelta(reflectionPosition + reflectDir * high,
                                      hitUV, delta)) return NONE;
            // Reject discontinuities rather than reflecting through a foreground edge.
            if (delta < 0.0 || delta > REFLECTION_THICKNESS) return NONE;
            vec2 edgeDistance = min(hitUV, vec2(1.0) - hitUV);
            float fade = smoothstep(0.0, 0.05, min(edgeDistance.x, edgeDistance.y));
            fade *= 1.0 - smoothstep(REFLECTION_DISTANCE * 0.8, REFLECTION_DISTANCE, high);
            return vec4(texture2D(screentex, hitUV).rgb * fade, fade);
        }
        wasInFront = delta < 0.0;
        previousDistance = distanceAlongRay;
    }
    return NONE;
}

vec4 getReflection(vec3 reflectionPosition)
{
    if (!NormalIsWaterPuddle) return NONE;
    if (getRandomFactor(reflectionPosition.xz / 512.0) >= rainPercent) return NONE;

    // G-buffer normals are world-space normals encoded as normal * 0.5 + 0.5.
    vec3 normal = normalize(vertexNormal * 2.0 - 1.0);
    vec3 incidentDir = normalize(reflectionPosition - eyePos);
    vec3 reflectDir = normalize(reflect(incidentDir, normal));
    return rayMarchForReflection(reflectionPosition + normal * 0.25, reflectDir);
}

/////////////////////////////////////////////////////////////////////////////////////////////
float calculateLightReflectionFactor();

vec4 paintRainSky(vec2 rotatedUV)
{
		vec2 scale = vec2(8.0, 4.0);
		vec2 rainUv = vec2(rotatedUV *scale);
		
		rainUv.y = -1.0 * rainUv.y - (time + eyePos.y ) * 0.125; 
		vec4 rainColor = texture2D(noisetex , rainUv);
		vec3 rainRGB = GetDeterministicRainColor(rainUv.xy).rgb;
		float rainAlpha = rainPercent*(1.0-rainColor.r*0.5)* (0.225 + 0.05*absinthTime());
	float sunlightReflectionFactor = calculateLightReflectionFactor();
	if (sunlightReflectionFactor > 0.1) 
	{
		return vec4(mix( sunCol.rgb, rainRGB.rgb, sunlightReflectionFactor), max(rainAlpha, sunlightReflectionFactor));
	}else
	{
		return vec4(rainRGB, rainAlpha);
	}
}

// RAIN_LIGHT_GLITTER
// SURFACE_WATER
vec4 GetGroundReflectionRipples(vec3 pixelPos)
{
    vec3 n = normalize(vertexNormal*2.0-1.0);
    vec2 water = surfaceWaterWeights(n.y);
    float channels = NormalIsOnUnit ? 0.0 : getSurfaceRivulets(pixelPos,n,false);
    vec2 rippleSlope = surfaceRippleProfile(pixelPos.xz);
    vec4 roofBeads = roofWaterBeads(pixelPos,n,NormalIsOnUnit);
    vec3 channelGradient=runoffHeightGradient(channels*0.12,pixelPos,n)*water.x*(1.0-water.y)*step(0.0,pixelPos.y);
    float puddle = surfacePuddleMask(pixelPos.xz);
    runoffCoverage = water.x*(1.0-water.y)*channels;
    float coverage = water.x*mix(channels,0.35+0.65*puddle,water.y);
    coverage=max(coverage,roofBeads.w);
    if (coverage <= 0.0001) return NONE;

    vec3 scene = texture2D(screentex,uv).rgb;
    vec3 lighting = max(sunCol,vec3(0))*0.4 + max(skyCol,vec3(0))*0.6;
    if (rainLightActive > 0.5) lighting += rainLocalLight(pixelPos+n*0.5);
    // Bound highlights without bleaching blue/orange/neon hue.
    float luminance = dot(lighting,vec3(0.2126,0.7152,0.0722));
    lighting *= max(1.0,0.22/max(luminance,0.0001));
    lighting /= 1.0+max(luminance,0.22);
    vec3 toEye = normalize(eyePos-pixelPos);
    float fresnel = 0.08+0.55*pow(1.0-max(dot(n,toEye),0.0),3.0);
    vec4 reflected = getReflection(pixelPos);
    // Dark wet substrate + patchy reflection replaces the old uniform blue veil.
    vec3 target = scene*mix(0.68,0.86,water.y) + max(skyCol,vec3(0))*fresnel*0.08;
    target = mix(target,reflected.rgb/max(reflected.a,0.0001),
                 reflected.a*water.y*puddle*(0.3+fresnel));
    float ringWetness = water.x*water.y*(0.4+0.6*puddle);
    vec3 rippleNormal=normalize(n-vec3(rippleSlope.x,0,rippleSlope.y)*ringWetness);
    vec3 lightDirection=dot(sunPos,sunPos)>0.001 ? normalize(sunPos) : normalize(vec3(0.4,0.7,0.3));
    vec3 halfDirection=normalize(lightDirection+toEye+vec3(0,0.0001,0));
    float curvedLight=dot(rippleNormal-n,lightDirection)*2.5;
    float glint=pow(max(dot(rippleNormal,halfDirection),0.0),32.0)
               -pow(max(dot(n,halfDirection),0.0),32.0);
    // Opposing light/dark faces give the ridge relief without a drawn outline.
    target*=1.0-0.65*max(-curvedLight,0.0)-0.22*max(-glint,0.0);
    runoffEnergy=lighting*(0.65*max(curvedLight,0.0)+0.45*max(glint,0.0)
                         );
    vec3 beadNormal=normalize(n-roofBeads.xyz-channelGradient);
    float beadLight=dot(beadNormal-n,lightDirection)*2.5;
    float beadGlint=max(0.0,pow(max(dot(beadNormal,halfDirection),0.0),32.0)
                              -pow(max(dot(n,halfDirection),0.0),32.0));
    target*=1.0-0.65*max(-beadLight,0.0);
    runoffEnergy+=lighting*(0.65*max(beadLight,0.0)+0.45*beadGlint);
    return vec4(max(target,vec3(0)),coverage*0.65);
}

///////////////////////////////////FOG ///////////////////////////////////////////////////////////
vec4 GetGroundReflection(in vec3 start, in vec3 end)
{	
	float l = length(end - start);
	const float numsteps = MAX_DEPTH_RESOLUTION;
	const float tstep = 1. / numsteps;

	vec4 accumulatedColor = NONE;
	accumulatedColor = GetGroundReflectionRipples(end);

	return accumulatedColor;
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

float generate_wave(float period) {
    float frequency = 1.0 / period; // Calculate frequency
    float phase = sin(2 * PI * frequency * time); // Calculate phase using sine function
    return 0.5 * (1 + phase); // Scale and shift the sine wave to be between 0 and 1
}

float calculateLightReflectionFactor() 
{
    // Normalize the input vectors
    vec3 vSun = normalize(sunPos);
    vec3 vEye = normalize(eyeDir);
    
    // Calculate the angle between the sun direction and the eye direction
    float angleCos = dot(vSun, vEye);
    
    // Ensure the angleCos is within the range [-1, 1] to avoid numerical errors
    angleCos = clamp(angleCos, -1.0, 1.0);
    
    // Calculate the reflection coefficient using the angle between the vectors
    float reflection = pow(abs(angleCos), 4.0); // Adjust the exponent as needed
    
    // Clamp the reflection value between 0 and 1
    reflection = clamp(reflection, 0.0, 1.0);
    
    return reflection;
}

vec4 getDroplettTexture(vec2 rotatedUV, float rainspeed, float timeOffset, out float coverage)
{
	rotatedUV.y = -1.0 * rotatedUV.y - (time + timeOffset) * rainspeed; 
	float scaleDownFactor = ((mod(time + timeOffset, sixSeconds)/sixSeconds)*0.9)+ 0.1;
	rotatedUV = rotatedUV * scaleDownFactor;
	vec4 rainColor = texture2D(rainDroplettTex, rotatedUV);
	rainColor = vec4(1.0 - rainColor.r);
	vec4 resultColor = rainColor * GetDeterministicRainColor(rotatedUV.xy);
	resultColor.a = mix(0, resultColor.a, generate_wave(sixSeconds));
    coverage = clamp(rainColor.r * generate_wave(sixSeconds), 0.0, 1.0);
	float sunlightReflectionFactor = calculateLightReflectionFactor();
	if (sunlightReflectionFactor > 0.1) 
	{
		return vec4(mix( sunCol.rgb, resultColor.rgb, sunlightReflectionFactor), max(resultColor.a, sunlightReflectionFactor)) ;
	}

	return resultColor;
}

vec4 getRainTexture(vec2 rainUv, float rainspeed, float timeOffset)
{
	rainUv.y = -1.0 * rainUv.y - (time + timeOffset) * rainspeed; 
	vec4 rainColor = texture2D(raintex , rainUv);
	vec4 resultColor = vec4(vec3(1.0 - rainColor.r), abs(1.0 - rainColor.r));
	return resultColor;
}

vec2 getRoatedUV()
{
	// Calculate the camera's right and up vectors
    vec3 cameraRight = normalize(cross(upwardVector, eyeDir));
    // Up vector in world space

    // Calculate the rotation matrix
    mat3 rotationMatrix = mat3(
        cameraRight.x, upwardVector.x, eyeDir.x,
        cameraRight.y, upwardVector.y, eyeDir.y,
        cameraRight.z, upwardVector.z, eyeDir.z
    );

    // Apply the rotation to the UV coordinates       
    vec3 rotatedUV = (rotationMatrix * vec3(uv, 0.0)) ;
    return rotatedUV.xy;
}

vec4 drawShrinkingDroplets(vec2 roatedUV, float rainspeed, out float coverage)
{
	float firstCoverage, secondCoverage;
	vec4 droplettTex = getDroplettTexture(roatedUV * DROPLETT_SCALE, rainspeed, eyePos.y, firstCoverage);
	droplettTex += getDroplettTexture(roatedUV * DROPLETT_SCALE, rainspeed, eyePos.y + sixSeconds/2.0, secondCoverage);
    coverage = clamp(firstCoverage + secondCoverage, 0.0, 1.0);
	return droplettTex;
}

vec4 drawRainInSpainOnPlane( vec2 rotatedUV, float rainspeed, out float coverage)
{
	vec2 scale = vec2(8.0, 4.0);
	vec4 raindropColor = getRainTexture(rotatedUV.xy * scale, rainspeed, eyePos.y);
    coverage = clamp(raindropColor.a, 0.0, 1.0);
	vec4 finalColor =vec4(raindropColor.rgb, raindropColor.a)  * GetDeterministicRainColor(rotatedUV.xy);
	float sunlightReflectionFactor = calculateLightReflectionFactor();
	finalColor.a *= 2.0;
	if (sunlightReflectionFactor > 0.1) 
	{
		return mix( vec4(sunCol, finalColor.a), finalColor, sunlightReflectionFactor);
	}
	return  finalColor;	
}



// WORLD_RAIN
// RAIN_SPLASHBACK

vec4 composeRainEffects(vec3 background, vec4 surfaceFX, vec4 rain, vec4 splash,
                        vec3 runoff) {
    float alpha = 1.0-(1.0-surfaceFX.a)*(1.0-rain.a)*(1.0-splash.a);
    // Preserve existing surface blending while adding reflected light from
    // airborne water and runoff. The half-float target preserves RGB > 1 until
    // the final straight-alpha blend; an 8-bit target clips these highlights.
    vec3 premultiplied = surfaceFX.rgb*surfaceFX.a
        + background*(alpha-surfaceFX.a)
        + rain.rgb*rain.a + splash.rgb*splash.a + runoff;
    return vec4(premultiplied/max(alpha,0.00001),alpha*rainPercent);
}

void main(void)
{
	uv = gl_FragCoord.xy / viewPortSize;
	sunDir = sunPos; //its normalized
	screenScaleFactorY = viewPortSize.x/viewPortSize.y;
	mapDepth = texture2D(mapDepthTex,uv).rrrr;
	modelDepth = texture2D(modelDepthTex,uv).rrrr;
	depthAtPixel =  texture2D(dephtCopyTex, uv);
	worldPos = GetWorldPosAtUV(uv, depthAtPixel.r);

	vertexNormal = GetGroundVertexNormal(uv,  NormalIsOnGround,  NormalIsOnUnit, NormalIsWaterPuddle, NormalIsSky);
    if(!NormalIsSky) {
        vec3 geometryNormal=rainGeometryNormal(uv,NormalIsOnUnit,normalize(vertexNormal*2.0-1.0));
        vertexNormal=geometryNormal*0.5+0.5;
        NormalIsWaterPuddle=geometryNormal.y>=0.99;
    }


    if(rainDetailDebug>3.5) {
        if(NormalIsSky) { gl_FragColor=vec4(0,0,0,1); return; }
        vec3 n=normalize(vertexNormal*2.0-1.0);
        if(rainDetailDebug>4.5) {
            vec4 beads=roofWaterBeads(worldPos,n,NormalIsOnUnit);
            gl_FragColor=vec4(vec3(clamp(beads.w*4.0,0.0,1.0)),1);
        } else {
            // Four engine units along each selected world projection axis.
            vec3 an=abs(n);
            vec2 chart=an.y>=max(an.x,an.z) ? worldPos.xz : an.x>an.z ? worldPos.zy : worldPos.xy;
            float check=mod(floor(chart.x/4.0)+floor(chart.y/4.0),2.0);
            vec3 tint=NormalIsOnUnit ? vec3(0.1,0.8,0.9) : vec3(1.0,0.5,0.12);
            gl_FragColor=vec4(mix(tint*0.2,tint,check),1);
        }
        return;
    }

    if (reflectionDebug > 0.5)
    {
        gl_FragColor = vec4(getReflection(worldPos).rgb, 1.0);
        return;
    }

    // Surface effects remain independent of the precipitation volume.
    vec4 surfaceFX = NormalIsSky ? NONE : GetGroundReflectionRipples(worldPos);
    vec3 rayPoint = GetWorldPosAtUV(uv, 0.5);
    vec3 rayDir = normalize(rayPoint - eyePos);
    float sceneDistance = depthAtPixel.r < 0.999999 ? length(worldPos-eyePos) : 1.0e6;
    vec4 rain = drawWorldRain(rayDir, sceneDistance);
    vec4 distantRain=drawDistantRain(rayDir,sceneDistance);
    float rainAlpha=1.0-(1.0-rain.a)*(1.0-distantRain.a);
    rain=vec4((rain.rgb*rain.a+distantRain.rgb*distantRain.a)/max(rainAlpha,0.00001),rainAlpha);
    vec4 splash = drawRainSplashback(worldPos, vertexNormal, rayDir, sceneDistance, NormalIsSky);
    if (rainDetailDebug > 2.5) {
        gl_FragColor = vec4(NormalIsSky ? vec3(0) : vertexNormal,1);
    } else if (rainDetailDebug > 1.5) {
        gl_FragColor = vec4(vec3(runoffCoverage),1);
    } else if (rainDetailDebug > 0.5) {
        gl_FragColor = vec4(rain.rgb*rain.a*4.0,1);
    } else {
        gl_FragColor = composeRainEffects(texture2D(screentex,uv).rgb,surfaceFX,rain,splash,runoffEnergy);
    }
}
