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
uniform sampler2D screentex;
uniform sampler2D normaltex;
uniform sampler2D normalunittex;

uniform sampler2D neonLightcanvastex;
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
uniform mat4 viewProjectionInv;
uniform mat4 viewProjection;
uniform mat4 projection;
uniform mat4 viewInv;
uniform mat4 viewMatrix;


//Struct Definition             //////////////////////////////////////////////////////////

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
//Debug Code                        //////////////////////////////////////////////////////////
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

//Global Variables                  //////////////////////////////////////////////////////////
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
float cameraZoomFactor;
float screenScaleFactorY = 0.1;
bool  NormalIsOnGround = false;
bool  NormalIsOnUnit = false;
bool NormalIsWaterPuddle = false;
bool NormalIsSky = false;



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
    vec4 ppos = vec4( vec3(uvs* 2. - 1., depthPixel), 1.0);
    //vec4 ppos =  vec4(vec3(uvs, depthPixel)* 2. - 1., 1.0);
    vec4 worldPos4 = viewProjectionInv * ppos;
    worldPos4.xyz /= worldPos4.w;

    if (depthAtPixel == 1.0) 
    {
        vec3 forward = normalize(worldPos4.xyz - eyePos);
        float a = max(MAX_HEIGTH_RAIN - eyePos.y, eyePos.y - MIN_HEIGHT_RAIN) / forward.y;
        return eyePos + forward.xyz * abs(a);       
    }
    return worldPos4.xyz;
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

/////////////////////////////////////////////////////////////////////////////////////////////
// Plastic Shrink Wrap  //
#define OFFSET_X 1
#define OFFSET_Y 1
#define DEPTH    5.5

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
        if (mapDepth.r <= modelDepth.r  )
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



///////////////////////////////////FOG ///////////////////////////////////////////////////////////

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
    sourceRotatedUV = getRoatedUV();


    t1 = clamp(t1, 0.0, 1.0);
    t2 = clamp(t2, 0.0, 1.0);
    vec3 startPos = r.Dir * t1 + eyePos;
    vec3 endPos   = r.Dir * t2 + eyePos;
    pixelDir = normalize(startPos - endPos);

    
    gl_FragColor = vec4(1.0, 0.0, 0.0, 1.0);
}
