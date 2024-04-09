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
#define DAY_RAIN_DARK_COL vec4(0.26,0.27,0.37,1.0)
#define DAY_RAIN_CITYGLOW_COL vec4(0.72,0.505,0.52,1.0)
//NightColors
#define NIGHT_RAIN_HIGH_COL vec4(0.75,0.75,0.75,1.0)
#define NIGHT_RAIN_DARK_COL vec4(0.06,0.07,0.17,1.0)
#define NIGHT_RAIN_CITYGLOW_COL vec4(0.72,0.505,0.52,1.0)
#define MIRRORED_REFLECTION_FACTOR 0.275f
#define ADD_POND_RIPPLE_FACTOR 0.75f

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
uniform sampler2D emitmaptex;
uniform sampler2D emitunittex;
uniform sampler2D noisetex;
uniform sampler2D raintex;
uniform sampler2D dephtCopyTex;


uniform float time;		
uniform float timePercent;
uniform float rainPercent;
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


//Struc Definition				//////////////////////////////////////////////////////////

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
vec3 worldPos;
vec4 mapDepth;
vec4 depthAtPixel;
vec4 modelDepth;
vec3 pixelDir;
vec4 origColor;
vec3 vertexNormal;
vec3 sunDir;
float cameraZoomFactor;
float screenScaleFactorY = 0.1;
bool  NormalIsOnGround = false;
bool  NormalIsOnUnit = false;
bool NormalIsWaterPuddle = false;
bool NormalIsSky = false;
float emissionAtPixel;

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

	vec4 ppos;
	ppos.xyz = vec3(uvs, depthPixel) * 2. - 1.; 
	ppos.a   = 1.;
	vec4 worldPos4 = viewProjectionInv * ppos;
	worldPos4.xyz /= worldPos4.w;

	if (depthAtPixel == 1.0) 
	{
		vec3 forward = normalize(worldPos4.xyz - eyePos);
		float a = max(MAX_HEIGTH_RAIN - eyePos.y, eyePos.y - MIN_HEIGHT_RAIN) / forward.y;
		return eyePos + forward.xyz * abs(a);		
	}
	return worldPos4.xyz;
}//https://virtexedgedesign.wordpress.com/2018/06/24/shader-series-basic-screen-space-reflections/
//https://github.com/maorachow/monogameMinecraft/blob/1bb43fefb63819db91f89500db736cb90ecd9115/Content/ssreffect.fx#L81
float3 GetUVFromPosition(float3 worldPos)
{
    float4 viewPos = mul(float4(worldPos, 1), matView);
    float4 projectionPos = mul(viewPos, matProjection);

    projectionPos.xyz /= projectionPos.w;
    projectionPos.y = -projectionPos.y;
    projectionPos.xy = projectionPos.xy * 0.5 + 0.5;
    return projectionPos.xyz;
}
vec3  GetUVAtPosInView(vec3 worldPos)
{
	vec4 viewProjectionPos = viewProjection * vec4(worldPos, 1.0);
	viewProjectionPos.xyz /= viewProjectionPos.w;
	viewProjectionPos.y = -viewProjectionPos.y;
    viewProjectionPos.xy = viewProjectionPos.xy * 0.5 + 0.5;
	// Convert to normalized device coordinates
	return viewProjectionPos.xyz;
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
		1-((timePercent - 0.5)*2.0);
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

vec4 GetGroundPondRainRipples(vec2 groundUVs) 
{   
	float zoomFactor = getZoomFactor();
	float f = noise(  zoomFactor * 64.0 * uv, 0.6125); 
	vec3 normal = vec3(-dFdx(f), -dFdy(f), 0.5) + 0.5;
	float avgVal= (normal.x+normal.y+normal.z)/3.0;
	return vec4(vec3(avgVal), 0.75);
	float dotProduct = max(dot(normal, sunDir), 0.0);
	return vec4(vec3(dotProduct), 0.75);
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

vec3 GetGroundVertexNormal(vec2 theUV, out bool IsOnGround, out bool IsOnUnit, out bool IsWaterPuddle, out bool IsSky) 
{
	vec4 unitVertexNormal = texture2D(normalunittex, theUV);
	vec4 groundVertexNormal= texture2D(normaltex, theUV);

	IsOnGround = groundVertexNormal != BLACK;
	IsOnUnit = false;	
	IsOnGround = false;
	IsWaterPuddle =groundVertexNormal.g >= Y_NORMAL_CUTOFFVALUE ;
	IsSky = groundVertexNormal.rgb == BLACK.rgb && unitVertexNormal.rgb == BLACK.rgb;

	if (unitVertexNormal.rgb != BLACK.rgb && unitVertexNormal.a > 0.5) 
	{
		if (mapDepth.r < modelDepth.r  )
		{
			IsOnGround = true;
			return groundVertexNormal.rgb;
		}
		IsOnUnit = true;
		IsOnGround = false;
		IsWaterPuddle =unitVertexNormal.g > Y_NORMAL_CUTOFFVALUE;
		return unitVertexNormal.rgb;	
	}
	IsOnGround = true;
	return groundVertexNormal.rgb;
}


vec3 sampleNormal(const int x, const int y, in vec2 fragCoord)
{
	vec2 ouv = (uv + vec2(x, y)) / viewPortSize.xy;
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
	vec3 n = GetNormals(uv);
	//Add screen normals to add detail
	n =  n+ SobelNormalFromScreen(uv);
	vec3 actualSunPos = sunPos*8192.0;
	vec3 color = vertexNormal * dot(n, normalize(actualSunPos - pixelWorldPos));
    float e = 64.;
	color += pow(clamp(dot(normalize(reflect(actualSunPos - pixelWorldPos, n)), 
					   normalize(pixelWorldPos - eyePos)), 0., 1.), e);	

	float greyValue = 0.2989* color.r + 0.5870* color.g + 0.1140 *color.b;
	return vec4(vec3(greyValue * skyCol), 1);
}

float getEmissionStrengthFactorAtUV(vec2 curUV, float minValue, bool IsOnGround, bool IsOnUnit)
{
	if (IsOnUnit) return max(minValue,texture2D(emitunittex, theUV).r);
	if (IsOnGround) return max(minValue,texture2D(emitMapTex, theUV).r);
	
	return 0.0;
}
 
const vec2 SAMPLE_OFFSETS[4] = vec2[4](
    vec2(1.0, 0.0),  // Right
    vec2(-1.0, 0.0), // Left
    vec2(0.0, 1.0),  // Up
    vec2(0.0, -1.0)  // Down
);

vec4 rayMarchForReflection(vec3 reflectionPosition, vec3 reflectDir)
{
	const float DepthCheckBias = 0.00001;
	int loops = 64;
	// The Current Position in 3D
	vec3 curPos = vec3(0.);
	vec2 HalfPixel = vec2(0.5 / viewPortSize.x, 0.5 / viewPortSize.y);
	 
	// The Current UV
	vec3 curUV = vec3(0.);
	 
	// The Current Length
	float curLength = 0.3; //This is not in world, but in pixelspace coordinates

    for (int i = 0; i < loops; i++)
    {
        // Update the Current Position of the Ray in world
        curPos = reflectionPosition + reflectDir * curLength ;
        // Get the UV Coordinates of the current Ray
        curUV = GetUVAtPosInView(curPos);
        // The Depth of the Current Pixel
        float backgroundDepth = texture2D(dephtCopyTex, curUV.xy).r;

        //Sobelsample at cursor to close uvholes
        for (int j = 0; j < 4; j++)
        {
            if (abs(curUV.z - backgroundDepth) < DepthCheckBias)
            {
            	bool IsOnGround = false;
            	bool IsOnUnit = false;
            	bool IsPuddle = false;
            	bool IsSky = false;

            	vec3 normal = GetGroundVertexNormal(curUV.xy,  IsOnGround,  IsOnUnit, IsPuddle, IsSky);
            	//Detect the sky and avoid reflecting rooftops
            	if (IsSky || (IsPuddle && IsOnUnit)) {return RED;} //not mirrored on the ground
                return GREEN;
                //return texture2D(screentex, curUV.xy) * getEmissionStrengthFactorAtUV(curUV, 0.5, IsOnGround, IsOnUnit); 
            }
            backgroundDepth = texture2D(dephtCopyTex, curUV .xy + (SAMPLE_OFFSETS[j].xy * HalfPixel * 2.0)).r;
        }

        // Get the New Position and Vector
        vec3 newPos = GetWorldPosAtUV(curUV.xy, backgroundDepth );    
        curLength = length(reflectionPosition - newPos);        
    }
    return BLUE;
    //return NONE; //No reflection
}

vec4 getReflection(vec3 reflectionPosition)
{
	if (!NormalIsWaterPuddle) return NONE;

	if (getRandomFactor(reflectionPosition.xz /512.0) < rainPercent) //Puddles
    {
 	// Calculate reflection direction
    vec3 viewDir = normalize(gl_FragCoord.xyz - (eyePos)); // Calculate view direction

    // Assuming ground is flat, normal is (0,1,0)
    vec3 reflectDir = reflect(viewDir, vertexNormal); // Calculate reflection direction

  	return rayMarchForReflection(reflectionPosition ,  reflectDir);
    	
    }	
    return NONE;
}

/////////////////////////////////////////////////////////////////////////////////////////////

vec4 GetGroundReflectionRipples(vec3 pixelPos)
{
	bool rivuletRunning = false;
	float groundMixFactor = 1.0;
	if (!NormalIsWaterPuddle) 
	{
		//rivulets
		if (!(vertexNormal.g  > 0.95)) return NONE;


		rivuletRunning = getRivuletMask(vertexNormal); //TODO get ground coord 
		if (!rivuletRunning) return NONE;

		groundMixFactor= (abs(vertexNormal.r) + abs(vertexNormal.g) + abs(vertexNormal.b))/1.73205;
	}

	vec4 workingColorLayer = MIRRORED_REFLECTION_FACTOR * BLUE;
	workingColorLayer = screen(workingColorLayer,  GetShrinkWrappedSheen(pixelPos));
	workingColorLayer = dodge(workingColorLayer,  getReflection(worldPos));		
 	workingColorLayer = dodge(workingColorLayer, ADD_POND_RIPPLE_FACTOR * GetGroundPondRainRipples(pixelPos.xz));
	
	vec4 maskedColor = mix(	NONE,
			   				workingColorLayer,
			  				groundMixFactor);

	//clamp alpha
	maskedColor.a = max(0.15, min(0.25, maskedColor.a));
	
	return maskedColor;
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
    float reflection = pow(angleCos, 4.0); // Adjust the exponent as needed
    
    // Clamp the reflection value between 0 and 1
    reflection = clamp(reflection, 0.0, 1.0);
    
    return reflection;
}

vec4 getDroplettTexture(vec2 rotatedUV, float rainspeed, float timeOffset)
{
	rotatedUV.y = -1.0 * rotatedUV.y - (time + timeOffset) * rainspeed; 
	float scaleDownFactor = ((mod(time + timeOffset, sixSeconds)/sixSeconds)*0.9)+ 0.1;
	rotatedUV = rotatedUV * scaleDownFactor;
	vec4 rainColor = texture2D(rainDroplettTex, rotatedUV);
	rainColor = vec4(1.0 - rainColor.r);
	vec4 resultColor = rainColor * GetDeterministicRainColor(rotatedUV.xy);
	resultColor.a = mix(0, resultColor.a, generate_wave(sixSeconds));
	float sunlightReflectionFactor = calculateLightReflectionFactor();
	if (sunlightReflectionFactor > 0.1) 
	{
		return vec4(mix( sunCol.rgb, resultColor.rgb, sunlightReflectionFactor), resultColor.a) ;
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

vec4 drawShrinkingDroplets(vec2 roatedUV, float rainspeed)
{
	vec4 droplettTex = getDroplettTexture(roatedUV * DROPLETT_SCALE, rainspeed, eyePos.y);
	droplettTex += getDroplettTexture(roatedUV * DROPLETT_SCALE, rainspeed, eyePos.y + sixSeconds/2.0);
	return droplettTex;
}

vec4 drawRainInSpainOnPlane( vec2 rotatedUV, float rainspeed)
{
	vec2 scale = vec2(8.0, 4.0);
	vec4 raindropColor = getRainTexture(rotatedUV.xy * scale, rainspeed, eyePos.y);
	vec4 finalColor =vec4(raindropColor.rgb, raindropColor.a)  * GetDeterministicRainColor(rotatedUV.xy);
	float sunlightReflectionFactor = calculateLightReflectionFactor();
	finalColor.a *= 2.0;
	if (sunlightReflectionFactor > 0.1) 
	{
		return mix( vec4(sunCol, finalColor.a), finalColor, sunlightReflectionFactor);
	}
	return  finalColor;	
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

	cameraZoomFactor = max(0.0,min(eyePos.y/2048.0, 1.0));
	//Debug code

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

	gl_FragColor = getReflection(worldPos);
	//gl_FragColor = lind(depthAtPixel.rrrr);
	return;

	vec4 accumulatedLightColorRayDownward = GetGroundReflection(startPos,  endPos); // should be eyepos + eyepos *offset*vector for deter

	float upwardnessFactor = 0.0;
	upwardnessFactor = GetUpwardnessFactorOfVector(eyeDir); //[0..1] 1 being up orthogonal to ground and upwards


	vec2 rotatedUV = getRoatedUV();
	//TODO, should pulsate depending on look vector due to the dropletss

	
	accumulatedLightColorRayDownward = mix( screen(accumulatedLightColorRayDownward, drawRainInSpainOnPlane(rotatedUV, 3.0)), 
										    screen(accumulatedLightColorRayDownward, drawShrinkingDroplets(rotatedUV, 0.03)),
											1.0-upwardnessFactor 
											) ;
	
	gl_FragColor = mix(NONE, accumulatedLightColorRayDownward, rainPercent);

	//vec4 upWardrainColor = origColor;
	//https://www.youtube.com/watch?v=W0_zQ-WdxH4

}
