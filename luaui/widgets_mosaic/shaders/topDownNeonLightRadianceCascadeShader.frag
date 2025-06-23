#version 150 compatibility  
precision highp float;

in vec3 vWorldPos;
in vec3 vNormal;
in vec2 vUV;


uniform vec3 eyePos;
uniform vec3 uLightDir; // Directional light (top-down sun/moon)
uniform sampler2D uDepthMap; // Depth texture for cascading
uniform sampler2D uEmissionMap; // Input: Emissive neon glow map
uniform samplerCube radianceCascade;
uniform mat4 viewprojectioninverse;
uniform mat4 viewinverse;
uniform mat4 viewprojection;
uniform mat4 projection;
uniform vec2  viewPortSize;

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
    float sceneDepth = texture(uDepthMap, vUV).r;
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
        vec4 clipPos = viewprojection * vec4(samplePosWorld, 1.0);
        clipPos /= clipPos.w;

        // Convert to screen UVs [0, 1]
        vec2 uv = clipPos.xy * 0.5 + 0.5;

        // Skip if outside screen (optional)
        if (uv.x < 0.0 || uv.x > 1.0 || uv.y < 0.0 || uv.y > 1.0) continue;

        // Get scene depth (0..1)
        float sceneDepth = texture(uDepthMap, uv).r;

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



vec3 calculateRadianceCascade()
{
    ivec2 cubemapRes = textureSize(uEmissionMap, 0);
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
    if (inViewShadowFromCamera(vWorldPos)) //Early out if not visible
    {
        gl_FragColor = BLACK;
        return ;
    }

    vec3 N = normalize(vNormal);
    vec3 L = normalize(-uLightDir);
    vec3 V = normalize(eyePos - vWorldPos);
    vec3 R = reflect(-L, N);

    // Diffuse and specular lighting
    float diff = max(dot(N, L), 0.0);
    float spec = pow(max(dot(R, V), 0.0), 32.0);

    // Shadow factor from depth map
    float shadow = getDepthShadow(vWorldPos);

    // Radiance cascading (blurred GI-like effect)
    vec3 radiance = calculateRadianceCascade();

    // Neon emission map
    vec3 emission = texture(uEmissionMap, vUV).rgb;

    // Final color calculation
    vec3 color = vec3(0.05, 0.05, 0.08); // ambient base
    color += diff * vec3(0.8, 0.9, 1.0); // direct light
    color += spec * vec3(1.0);           // specular
    color += radiance * 0.4;             // indirect bounce
    color += emission * 1.5;             // glow
    color *= shadow;                     // apply depth shadow

    gl_FragColor = vec4(color, 1.0);
}
