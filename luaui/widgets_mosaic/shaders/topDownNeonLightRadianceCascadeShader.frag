#version 150 compatibility  
precision highp float;

in vec3 vWorldPos;
in vec3 vNormal;
in vec2 vUV;

uniform float neonLightPercent;
uniform vec2  viewPortSize;
uniform vec3 eyePos; //The scene eyePos
uniform vec3 eyeDir;
uniform vec3 eyeDir;
uniform vec3 sunCol;
uniform vec3 skyCol;
uniform vec3 sunPos; //uLightDir
uniform mat4 viewProjectionInv;

uniform mat4 viewProjection;
uniform mat4 viewInverse;
uniform mat4 viewProjection;
uniform mat4 projection;
/*
Fix me: ...
[t=00:01:17.360460][f=-000001] gfx_neonlight_radiancecascade: initTopDownRadianceCascadeShader
[t=00:01:17.392235][f=-000001] gfx_neonlights_radiancecascade: Radiance Cascade Perspective Shader failed to compile
[t=00:01:17.392347][f=-000001] 0(12) : error C1038: declaration of "eyeDir" conflicts with previous declaration at 0(11)
0(20) : error C1038: declaration of "viewProjection" conflicts with previous declaration at 0(18)
0(129) : error C1038: declaration of "c_sRes" conflicts with previous declaration at 0(28)
0(131) : error C1038: declaration of "c_dRes" conflicts with previous declaration at 0(30)
0(133) : error C1038: declaration of "nCascades" conflicts with previous declaration at 0(32)
0(136) : error C1038: declaration of "c_intervalLength" conflicts with previous declaration at 0(35)
0(139) : error C1038: declaration of "c_smoothDistScale" conflicts with previous declaration at 0(38)
0(156) : error C1503: undefined variable "screenRes"
0(156) : error C1503: undefined variable "iChannel1"
0(159) : error C1503: undefined variable "screenRes"
0(178) : error C1503: undefined variable "sdDrawing"
0(178) : error C1503: undefined variable "iChannel1"
0(201) : error C1503: undefined variable "sampleDrawing"
0(210) : error C1503: undefined variable "sampleDrawing"
0(225) : error C1503: undefined variable "SunCol"
0(264) : error C1503: undefined variable "iResolution"
0(265) : error C1503: undefined variable "iResolution"
0(273) : error C1016: expression type incompatible with function return type
0(376) : error C1103: too few parameters in function call

*/
uniform sampler2D depthTex; // Depth texture for cascading
uniform sampler2D inputNeonLightTex; // Input: Emissive neon glow map
uniform samplerCube radianceCascade;

// Spatial resolution of cascade 0
const ivec2 c_sRes = ivec2(320, 180);
// Number of directions in cascade 0
const int c_dRes = 16;
// Number of cascades all together
const int nCascades = 4;

// Length of ray interval for cascade 0 (measured in pixels)
const float c_intervalLength = 7.0;

// Length of transition area between cascade 0 and cascade 1
const float c_smoothDistScale = 10.0;


#define BLACK vec4(0.0, 0.0,0.0, 0.0)
#define PI (3.14159265359f)

float getDepthShadow(vec3 worldPos) {
    float sceneDepth = texture(depthTex, vUV).r;
    float currentDepth = length(worldPos - eyePos) / 100.0;
    return currentDepth > sceneDepth + 0.005 ? 0.5 : 1.0; // Soft shadow
}

//Resolution decreases away from camera till min resolution
bool inViewShadowFromCamera(vec3 worldPos)
{
  const int steps = 32;  // or use your RAY_STEP_SAMPLING
    vec3 dir = worldPos - eyePos;
    
    for (int i = 0; i < steps; i++)
    {
        float t = float(i) / float(steps - 1);
        vec3 samplePosWorld = eyePos + dir * t;

        // Project to clip space
        vec4 clipPos = viewProjection * vec4(samplePosWorld, 1.0);
        clipPos /= clipPos.w;

        // Convert to screen UVs [0, 1]
        vec2 uv = clipPos.xy * 0.5 + 0.5;

        // Skip if outside screen (optional)
        if (uv.x < 0.0 || uv.x > 1.0 || uv.y < 0.0 || uv.y > 1.0) continue;

        // Get scene depth (0..1)
        float sceneDepth = texture(depthTex, uv).r;

        // Get current point depth (0..1)
        float pointDepth = clipPos.z * 0.5 + 0.5;

        // Compare with bias to avoid precision issues
        if (pointDepth > sceneDepth + 0.001)
        {
            return true;  // Occluded
        }
    }
    return false;  // Visible
}


vec4 cubemapFetch(samplerCube sampler, int face, ivec2 P) {
    // Look up a single texel in a cubemap
    ivec2 cubemapRes = textureSize(sampler, 0);
    if (clamp(P, ivec2(0), cubemapRes - 1) != P || face < 0 || face > 5) {
        return vec4(0.0);
    }

    vec2 p = (vec2(P) + 0.5) / vec2(cubemapRes) * 2.0 - 1.0;
    vec3 c;
    
    switch (face) {
        case 0: c = vec3( 1.0, -p.y, -p.x); break;
        case 1: c = vec3(-1.0, -p.y,  p.x); break;
        case 2: c = vec3( p.x,  1.0,  p.y); break;
        case 3: c = vec3( p.x, -1.0, -p.y); break;
        case 4: c = vec3( p.x, -p.y,  1.0); break;
        case 5: c = vec3(-p.x, -p.y, -1.0); break;
    }
    
    return texture(sampler, normalize(c));
}

vec4 cascadeFetch(samplerCube cascadeTex, int n, ivec2 p, int d) {
    // Look up the radiance interval at position p in direction d of cascade n
    ivec2 cubemapRes = textureSize(cascadeTex, 0);
    int cn_offset = n > 0
        ? c_sRes.x * c_sRes.y + (c_sRes.x * c_sRes.y * c_dRes * (n - 1)) / 4
        : 0;
    int cn_dRes = n == 0 ? 1 : c_dRes << 2 * (n - 1);
    ivec2 cn_sRes = c_sRes >> n;
    p = clamp(p, ivec2(0), cn_sRes - 1);
    int i = cn_offset + d + cn_dRes * (p.x + cn_sRes.x * p.y);
    int x = i % cubemapRes.x;
    i /= cubemapRes.x;
    int y = i % cubemapRes.y;
    i /= cubemapRes.y;
    return cubemapFetch(cascadeTex, i, ivec2(x, y));
}

//Cube sampling cascade computation

// Spatial resolution of cascade 0
const ivec2 c_sRes = ivec2(320, 180);
// Number of directions in cascade 0
const int c_dRes = 16;
// Number of cascades all together
const int nCascades = 4;

// Length of ray interval for cascade 0 (measured in pixels)
const float c_intervalLength = 7.0;

// Length of transition area between cascade 0 and cascade 1
const float c_smoothDistScale = 10.0;


vec2 intersectAABB(vec2 ro, vec2 rd, vec2 a, vec2 b) {
    // Return the two intersection t-values for the intersection between a ray
    // and an axis-aligned bounding box
    vec2 ta = (a - ro) / rd;
    vec2 tb = (b - ro) / rd;
    vec2 t1 = min(ta, tb);
    vec2 t2 = max(ta, tb);
    vec2 t = vec2(max(t1.x, t1.y), min(t2.x, t2.y));
    return t.x > t.y ? vec2(-1.0) : t;
}

float intersect(vec2 ro, vec2 rd, float tMax) {
    // Return the intersection t-value for the intersection between a ray and
    // the SDF drawing from Buffer B
    screenRes = vec2(textureSize(iChannel1, 0));
    float tOffset = 0.0;
    // First clip the ray to the screen rectangle
    vec2 tAABB = intersectAABB(ro, rd, vec2(0.0001), screenRes - 0.0001);
    
    if (tAABB.x > tMax || tAABB.y < 0.0) {
        return -1.0;
    }
    
    if (tAABB.x > 0.0) {
        ro += tAABB.x * rd;
        tOffset += tAABB.x;
        tMax -= tAABB.x;
    }
    
    if (tAABB.y < tMax) {
        tMax = tAABB.y;
    }

    float t = 0.0;

    for (int i = 0; i < 100; i++) {
        float d = sdDrawing(iChannel1, ro + rd * t);
        t += abs(d);

        if (t >= tMax) {
            break;
        }

        if (0.2 < t && d < 1.0) {
            return tOffset + t;
        }
    }

    return -1.0;
}

struct RayHit
{
    vec4 radiance;
    float dist;
};

RayHit radiance(vec2 ro, vec2 rd, float tMax) {
    // Returns the radiance and visibility term for a ray
    vec4 p = sampleDrawing(inputNeonLightTex, ro);
    float t = 0.0f;
    if (p.r > 0.0) {
        t = intersect(ro, rd, tMax);
        
        if (t == -1.0) {
            return RayHit(vec4(0.0, 0.0, 0.0, 1.0), 1e5f);
        }

        p = sampleDrawing(inputNeonLightTex, ro + rd * t);
    }

    return RayHit(vec4(p.gba, 0.0), t);
}


vec3 integrateSkyRadiance_(vec2 angle) {
    // Sky radiance helper function
    float a1 = angle[1];
    float a0 = angle[0];
    
    // Sky integral formula taken from
    // Analytic Direct Illumination - Mathis
    // https://www.shadertoy.com/view/NttSW7
    const vec3 lSunColor = SunCol *10.;
    const float SunA = 2.0;
    const float SunS = 64.0;
    const float SSunS = sqrt(SunS);
    const float ISSunS = 1./SSunS;
    vec3 SI = skyCol*(a1-a0-0.5*(cos(a1)-cos(a0)));
    SI += lSunColor*(atan(SSunS*(SunA-a0))-atan(SSunS*(SunA-a1)))*ISSunS;
    return SI / 6.0;
}

vec3 integrateSkyRadiance(vec2 angle) {
    // Integrate the radiance from the sky over an interval of directions
    if (angle[1] < 2.0 * PI) {
        return integrateSkyRadiance_(angle);
    }
    
    return
        integrateSkyRadiance_(vec2(angle[0], 2.0 * PI)) +
        integrateSkyRadiance_(vec2(0.0, angle[1] - 2.0 * PI));
}

float smoothDist(int cascadeIndex)
{
    return float(1 << cascadeIndex);
}

vec4 mainCubemap( vec2 fragCoord, vec3 fragRO, vec3 fragRD) {
    // Calculate the index for this cubemap texel
    int face;
    
    if (abs(fragRD.x) > abs(fragRD.y) && abs(fragRD.x) > abs(fragRD.z)) {
        face = fragRD.x > 0.0 ? 0 : 1;
    } else if (abs(fragRD.y) > abs(fragRD.z)) {
        face = fragRD.y > 0.0 ? 2 : 3;
    } else {
        face = fragRD.z > 0.0 ? 4 : 5;
    }
    
    int i =
        int(fragCoord.x) + int(iResolution.x) *
        (int(fragCoord.y) + int(iResolution.y) * face);
    // Figure out which cascade this pixel is in
    vec2 screenRes = vec2(textureSize(inputNeonLightTex, 0));
    int c_size =
        c_sRes.x * c_sRes.y +
        c_sRes.x * c_sRes.y * c_dRes * (nCascades - 1) / 4;    
    
    if (i >= c_size) {
        return;
    }
    
    int n = i < c_sRes.x * c_sRes.y ? 0 : int(
        (4.0 * float(i) / float(c_sRes.x * c_sRes.y) - 4.0) / float(c_dRes)
        + 1.0
    );
    // Figure out this pixel's index within its own cascade
    int j = i - (n > 0
        ? c_sRes.x * c_sRes.y + (c_sRes.x * c_sRes.y * c_dRes * (n - 1)) / 4
        : 0);
    // Calculate this cascades spatial and directional resolution
    ivec2 cn_sRes = c_sRes >> n;
    int cn_dRes = n == 0 ? 1 : c_dRes << 2 * (n - 1);
    // Calculate this pixel's direction and position indices
    int d = j % cn_dRes;
    j /= cn_dRes;
    ivec2 p = ivec2(j % cn_sRes.x, 0);
    j /= cn_sRes.x;
    p.y = j;
    int nDirs = c_dRes << 2 * n;
    // Calculate this pixel's ray interval
    vec2 ro = (vec2(p) + 0.5) / vec2(cn_sRes) * screenRes;
    float c0_intervalLength = 
        length(screenRes) * 4.0 / (float(1 << 2 * nCascades) - 1.0);
    float t1 = c_intervalLength;
    float tMin = n == 0 ? 0.0 : t1 * float(1 << 2 * (n - 1));
    float tMax = t1 * float(1 << 2 * n);
    vec4 s = vec4(0.0);
    
    // Calculate radiance intervals and merge with above cascade
    for (int i = 0; i < nDirs / cn_dRes; ++i) {
        int j = 4 * d + i;
        float angle = (float(j) + 0.5) / float(nDirs) * 2.0 * PI;
        vec2 rd = vec2(cos(angle), sin(angle));
        float sMin = smoothDist(n) * c_smoothDistScale;
        float sMax = smoothDist(n + 1) * c_smoothDistScale;
        
        float tMinSmoothed = tMin - sMin * 0.5f;
        float tMaxSmoothed = tMax + sMax * 0.5f;
        
        float tMinClamped = max(0.0f, tMinSmoothed);
        
        RayHit hit = radiance(ro + rd * tMinClamped, rd, tMaxSmoothed - tMinClamped);
        vec4 empty_radiance = vec4(0.0f, 0.0f, 0.0f, 1.0f);
        hit.radiance = mix(hit.radiance, empty_radiance, 1.0f - clamp((tMinClamped - tMinSmoothed + hit.dist) / sMin, 0.0f, 1.0f));
        hit.radiance = mix(hit.radiance, empty_radiance, clamp(((tMinClamped + hit.dist) - (tMaxSmoothed)) / sMax + 1.0f, 0.0f, 1.0f));
        vec4 si = hit.radiance;
        // If the visibility term is non-zero
        if (si.a != 0.0) {
            if (n == nCascades - 1) {
                // If we are the top-level cascade, then there's no other
                // cascade to merge with, so instead merge with the sky radiance
                vec2 angle = vec2(j, j + 1) / float(nDirs) * 2.0 * PI;
                si.rgb += 0.0f*integrateSkyRadiance(angle) / (angle.y - angle.x);
            } else {
                // Otherwise, find the radiance coming from the above cascade in
                // this direction by interpolating the above cascades
                vec2 pf = (vec2(p) + 0.5) / 2.0;
                ivec2 q = ivec2(round(pf)) - 1;
                vec2 w = pf - vec2(q) - 0.5;
                ivec2 h = ivec2(1, 0);
                vec4 S0 = cascadeFetch(radianceCascade, n + 1, q + h.yy, j);
                vec4 S1 = cascadeFetch(radianceCascade, n + 1, q + h.xy, j);
                vec4 S2 = cascadeFetch(radianceCascade, n + 1, q + h.yx, j);
                vec4 S3 = cascadeFetch(radianceCascade, n + 1, q + h.xx, j);
                vec4 S = mix(mix(S0, S1, w.x), mix(S2, S3, w.x), w.y);
                si.rgb += si.a * S.rgb;
                si.a *= S.a;
            }
        }
        s += si;
    }
    
    s /= float(nDirs / cn_dRes);
    return s;
}

//========================================================================================================================================================================

vec3 fetchRadianceCascade()
{
    ivec2 cubemapRes = textureSize(inputNeonLightTex, 0);
    vec2 p = gl_FragCoord.xy / viewPortSize.xy * vec2(c_sRes);
    ivec2 q = ivec2(round(p)) - 1;
    vec2 w = p - vec2(q) - 0.5;
    ivec2 h = ivec2(1, 0);
    vec4 S0 = cascadeFetch(radianceCascade, 0, q + h.yy, 0);
    vec4 S1 = cascadeFetch(radianceCascade, 0, q + h.xy, 0);
    vec4 S2 = cascadeFetch(radianceCascade, 0, q + h.yx, 0);
    vec4 S3 = cascadeFetch(radianceCascade, 0, q + h.xx, 0);
    vec3 fluence = mix(mix(S0, S1, w.x), mix(S2, S3, w.x), w.y).rgb * 2.0 * PI;

    // Tonemap
    return vec3(1.0 - 1.0 / pow(1.0 + fluence, vec3(2.5)));
}

void main() {
    vec3 N = normalize(vNormal);
    vec3 L = normalize(-sunPos);
    vec3 V = normalize(eyePos - vWorldPos);
    vec3 R = reflect(-L, N);

    mainCubemap();

    // Diffuse and specular lighting
    float diff = max(dot(N, L), 0.0);
    float spec = pow(max(dot(R, V), 0.0), 32.0);

    // Shadow factor from depth map
    float shadow = getDepthShadow(vWorldPos);

    // Radiance cascading (blurred GI-like effect)
    vec3 radiance = fetchRadianceCascade();

    // Neon emission map
    vec3 emission = texture(inputNeonLightTex, vUV).rgb;

    // Final color calculation
    vec3 color = vec3(0.05, 0.05, 0.08); // ambient base
    color += diff * vec3(0.8, 0.9, 1.0); // direct light
    color += spec * vec3(1.0);           // specular
    color += radiance * 0.4;             // indirect bounce
    color += emission * 1.5;             // glow
    color *= shadow;                     // apply depth shadow


    if (inViewShadowFromCamera(vWorldPos)) //Early out if not visible
    {
        gl_FragColor = BLACK;
        return ;
    }
    gl_FragColor = vec4(color, 1.0);
}
