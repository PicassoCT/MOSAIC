#version 150 compatibility  
precision highp float;

in vec3 vWorldPos;
in vec3 vNormal;
in vec2 vUV;

uniform float neonLightPercent;
uniform vec2  viewPortSize;
uniform vec3 eyePos; //The scene eyePos
uniform vec3 eyeDir;
uniform vec3 sunCol;
uniform vec3 skyCol;
uniform vec3 sunPos; //uLightDir

uniform mat4 viewProjectionInv;
uniform mat4 viewProjection;
uniform mat4 viewInverse;
uniform mat4 projection;

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

float sdDrawing(sampler2D drawingTex, vec2 P) {
    // Return the signed distance for the drawing at P
    return texture2D(drawingTex, P).r;
}

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
    vec2 screenRes = vec2(textureSize(depthTex, 0));
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
        float d = sdDrawing(inputNeonLightTex, ro + rd * t);
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
    vec4 p = texture2D(inputNeonLightTex, ro);
    float t = 0.0f;
    if (p.r > 0.0) {
        t = intersect(ro, rd, tMax);
        
        if (t == -1.0) {
            return RayHit(vec4(0.0, 0.0, 0.0, 1.0), 1e5f);
        }

        p = texture2D(inputNeonLightTex, ro + rd * t);
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
    const vec3 lSunColor = vec3(sunCol * 10);
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

vec4 mainCubemap(vec2 fragCoord, vec3 rayOrigin, vec3 rayDirection) {
    // Determine cubemap face based on dominant direction axis
    int cubemapFaceIndex;
    if (abs(rayDirection.x) > abs(rayDirection.y) && abs(rayDirection.x) > abs(rayDirection.z)) {
        cubemapFaceIndex = rayDirection.x > 0.0 ? 0 : 1;
    } else if (abs(rayDirection.y) > abs(rayDirection.z)) {
        cubemapFaceIndex = rayDirection.y > 0.0 ? 2 : 3;
    } else {
        cubemapFaceIndex = rayDirection.z > 0.0 ? 4 : 5;
    }

    // Linear index into the cubemap based on screen coordinates and face
    int globalPixelIndex = int(fragCoord.x) + int(viewPortSize.x) *
                          (int(fragCoord.y) + int(viewPortSize.y) * cubemapFaceIndex);

    // Compute size of the full cascaded texture
    vec2 screenResolution = vec2(textureSize(inputNeonLightTex, 0));
    int fullCascadeSize = c_sRes.x * c_sRes.y + 
                          (c_sRes.x * c_sRes.y * c_dRes * (nCascades - 1)) / 4;

    // If out of bounds, skip processing
    if (globalPixelIndex >= fullCascadeSize) {
        return vec4(0.0);
    }

    // Determine which cascade this pixel belongs to
    int cascadeIndex = globalPixelIndex < c_sRes.x * c_sRes.y ? 0 : int(
        (4.0 * float(globalPixelIndex) / float(c_sRes.x * c_sRes.y) - 4.0) / float(c_dRes) + 1.0
    );

    // Pixel index within its own cascade
    int localPixelIndex = globalPixelIndex - (cascadeIndex > 0
        ? c_sRes.x * c_sRes.y + (c_sRes.x * c_sRes.y * c_dRes * (cascadeIndex - 1)) / 4
        : 0);

    // Resolution for current cascade
    ivec2 cascadeResolution = c_sRes >> cascadeIndex;
    int directionalResolution = cascadeIndex == 0 ? 1 : c_dRes << (2 * (cascadeIndex - 1));

    // Compute spatial and directional indices
    int directionIndex = localPixelIndex % directionalResolution;
    localPixelIndex /= directionalResolution;

    ivec2 positionIndex;
    positionIndex.x = localPixelIndex % cascadeResolution.x;
    localPixelIndex /= cascadeResolution.x;
    positionIndex.y = localPixelIndex;

    int totalDirections = c_dRes << (2 * cascadeIndex);

    // Compute ray origin from pixel position
    vec2 cascadeTexelCoord = (vec2(positionIndex) + 0.5) / vec2(cascadeResolution);
    vec2 cascadeRayOrigin = cascadeTexelCoord * screenResolution;

    // Compute ray interval bounds
    float cascadeIntervalLength = length(screenResolution) * 4.0 / (float(1 << (2 * nCascades)) - 1.0);
    float tMax = cascadeIntervalLength * float(1 << (2 * cascadeIndex));
    float tMin = (cascadeIndex == 0) ? 0.0 : cascadeIntervalLength * float(1 << (2 * (cascadeIndex - 1)));

    vec4 accumulatedRadiance = vec4(0.0);

    // Loop over direction bins
    for (int i = 0; i < totalDirections / directionalResolution; ++i) {
        int directionSampleIndex = 4 * directionIndex + i;

        float angle = (float(directionSampleIndex) + 0.5) / float(totalDirections) * 2.0 * PI;
        vec2 rayDir2D = vec2(cos(angle), sin(angle));

        float smoothMin = smoothDist(cascadeIndex) * c_smoothDistScale;
        float smoothMax = smoothDist(cascadeIndex + 1) * c_smoothDistScale;

        float smoothedMinT = tMin - 0.5 * smoothMin;
        float smoothedMaxT = tMax + 0.5 * smoothMax;
        float clampedMinT = max(0.0f, smoothedMinT);

        // Trace the ray
        RayHit hit = radiance(cascadeRayOrigin + rayDir2D * clampedMinT, rayDir2D, smoothedMaxT - clampedMinT);

        // Apply smoothing fade based on distance
        vec4 emptyRadiance = vec4(0.0, 0.0, 0.0, 1.0);
        hit.radiance = mix(hit.radiance, emptyRadiance, 1.0 - clamp((clampedMinT - smoothedMinT + hit.dist) / smoothMin, 0.0, 1.0));
        hit.radiance = mix(hit.radiance, emptyRadiance, clamp(((clampedMinT + hit.dist) - smoothedMaxT) / smoothMax + 1.0, 0.0, 1.0));

        vec4 radianceContribution = hit.radiance;

        // Accumulate contribution from above cascade or sky
        if (radianceContribution.a != 0.0) {
            if (cascadeIndex == nCascades - 1) {
                // Final cascade: merge with sky
                vec2 skyAngle = vec2(directionSampleIndex, directionSampleIndex + 1) / float(totalDirections) * 2.0 * PI;
                radianceContribution.rgb += 0.0 * integrateSkyRadiance(skyAngle) / (skyAngle.y - skyAngle.x);
            } else {
                // Interpolate from higher-level cascade
                vec2 parentCoord = (vec2(positionIndex) + 0.5) / 2.0;
                ivec2 parentBase = ivec2(round(parentCoord)) - 1;
                vec2 weight = parentCoord - vec2(parentBase) - 0.5;
                ivec2 offset = ivec2(1, 0);

                vec4 s0 = cascadeFetch(radianceCascade, cascadeIndex + 1, parentBase + offset.yy, directionSampleIndex);
                vec4 s1 = cascadeFetch(radianceCascade, cascadeIndex + 1, parentBase + offset.xy, directionSampleIndex);
                vec4 s2 = cascadeFetch(radianceCascade, cascadeIndex + 1, parentBase + offset.yx, directionSampleIndex);
                vec4 s3 = cascadeFetch(radianceCascade, cascadeIndex + 1, parentBase + offset.xx, directionSampleIndex);

                vec4 interpolated = mix(mix(s0, s1, weight.x), mix(s2, s3, weight.x), weight.y);

                radianceContribution.rgb += radianceContribution.a * interpolated.rgb;
                radianceContribution.a *= interpolated.a;
            }
        }

        accumulatedRadiance += radianceContribution;
    }

    // Average the accumulated radiance over all direction samples
    accumulatedRadiance /= float(totalDirections / directionalResolution);
    return accumulatedRadiance;
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

void main() 
{
    if (inViewShadowFromCamera(vWorldPos)) //Early out if not visible
    {
        gl_FragColor = BLACK;
        return ;
    }

    vec3 N = normalize(vNormal);
    vec3 L = normalize(-sunPos);
    vec3 V = normalize(eyePos - vWorldPos);
    vec3 R = reflect(-L, N);
    
    mainCubemap( gl_FragCoord.xy, N-L, V-R);

    // Diffuse and specular lighting
    float diff = max(dot(N, L), 0.0);
    float spec = pow(max(dot(R, V), 0.0), 32.0);

    // Shadow factor from depth map
    float shadow = getDepthShadow(vWorldPos);

    // Radiance cascading (blurred GI-like effect)
    vec3 radiance = fetchRadianceCascade();

    // Neon emission map
    vec3 emission = texture2D(inputNeonLightTex, vUV).rgb;

    // Final color calculation
    vec3 color = vec3(0.05, 0.05, 0.08); // ambient base
    color += diff * vec3(0.8, 0.9, 1.0); // direct light
    color += spec * vec3(1.0);           // specular
    color += radiance * 0.4;             // indirect bounce
    color += emission * 1.5;             // glow
    color *= shadow;                     // apply depth shadow

    gl_FragColor = vec4(color, 1.0);
}
