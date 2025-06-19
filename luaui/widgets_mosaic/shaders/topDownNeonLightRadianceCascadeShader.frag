#version 150 compatibility  
precision highp float;

in vec3 vWorldPos;
in vec3 vNormal;
in vec2 vUV;

out vec4 fragColor;

uniform vec3 uCameraPos;
uniform vec3 uLightDir; // Directional light (top-down sun/moon)
uniform sampler2D uDepthMap; // Depth texture for cascading
uniform sampler2D uRadianceMap; // Blurred scene texture for indirect light
uniform sampler2D uEmissionMap; // Emissive neon glow map
uniform samplerCube radianceCascade;

#define NEAR_RAY_RESOLUTION 0.1f
#define FAR_RAY_RESOLUTION  0.5f


float getDepthShadow(vec3 worldPos) {
    float sceneDepth = texture(uDepthMap, vUV).r;
    float currentDepth = length(worldPos - uCameraPos) / 100.0;
    return currentDepth > sceneDepth + 0.005 ? 0.5 : 1.0; // Soft shadow
}

//Resolution decreases away from camera till min resolution
int inViewShadowFromCamera(vec3 worldPos)
{
  const int steps = 64;  // or use your RAY_STEP_SAMPLING
    vec3 dir = worldPos - uCameraPos;
    
    for (int i = 0; i < steps; i++)
    {
        float t = float(i) / float(steps - 1);
        vec3 samplePosWorld = uCameraPos + dir * t;

        // Project to clip space
        vec4 clipPos = uProjectionMatrix * uViewMatrix * vec4(samplePosWorld, 1.0);
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
            return 0;  // Occluded
        }
    }
    return 1;  // Visible
}

/*

Main Code - doing the  lookup:
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

// Brush radius used for drawing, measured as fraction of iResolution.y
const float brushRadius = 0.02;

const float MAX_FLOAT = uintBitsToFloat(0x7f7fffffu);
const float PI = 3.1415927;
const float MAGIC = 1e25;

vec2 screenRes;

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

const int KEY_SPACE = 32;
const int KEY_1 = 49;

#ifndef HW_PERFORMANCE
uniform vec4 iMouse;
uniform sampler2D iChannel2;
uniform float iTime;
#endif

bool keyToggled(int keyCode) {
    return texelFetch(iChannel2, ivec2(keyCode, 2), 0).r > 0.0;
}

vec3 hsv2rgb(vec3 c) {
    vec3 rgb = clamp(
        abs(mod(c.x * 6.0 + vec3(0.0, 4.0, 2.0), 6.0) - 3.0) - 1.0,
        0.0,
        1.0
    );
    return c.z * mix(vec3(1.0), rgb, c.y);
}

vec3 getEmissivity() {
    return !keyToggled(KEY_SPACE)
        ? pow(hsv2rgb(vec3(iTime * 0.2, 1.0, 0.8)), vec3(2.2))
        : vec3(0.0);
}

float sdCircle(vec2 p, vec2 c, float r) {
    return distance(p, c) - r;
}

float sdSegment(vec2 p, vec2 a, vec2 b) {
    vec2 ap = p - a;
    vec2 ab = b - a;
    return distance(ap, ab * clamp(dot(ap, ab) / dot(ab, ab), 0.0, 1.0));
}

vec4 sampleDrawing(sampler2D drawingTex, vec2 P) {
    // Return the drawing (in the format listed at the top of Buffer B) at P
    vec4 data = texture(drawingTex, P / vec2(textureSize(drawingTex, 0)));
    
    if (keyToggled(KEY_1) && iMouse.z > 0.0) {
        float radius = brushRadius * screenRes.y;
        //float sd = sdCircle(P, iMouse.xy + 0.5, radius);
        float sd = sdSegment(P, abs(iMouse.zw) + 0.5, iMouse.xy + 0.5) - radius;
        
        if (sd <= max(data.r, 0.0)) {
            data = vec4(min(sd, data.r), getEmissivity());
        }
    }

    return data;
}

float sdDrawing(sampler2D drawingTex, vec2 P) {
    // Return the signed distance for the drawing at P
    return sampleDrawing(drawingTex, P).r;
}
*/

/*
// This buffer draws the SDF: Signed Distance Field
// .r stores signed distance
// .gba stores emissivity

// SDF drawing logic from 
// Smooth Mouse Drawing - fad
// https://www.shadertoy.com/view/dldXR7

// solveQuadratic(), solveCubic(), solve() and sdBezier() are from
// Quadratic Bezier SDF With L2 - Envy24
// https://www.shadertoy.com/view/7sGyWd
// with modification. Thank you! I tried a lot of different sdBezier()
// implementations from across Shadertoy (including trying to make it
// myself) and all of them had bugs and incorrect edge case handling
// except this one.

int solveQuadratic(float a, float b, float c, out vec2 roots) {
    // Return the number of real roots to the equation
    // a*x^2 + b*x + c = 0 where a != 0 and populate roots.
    float discriminant = b * b - 4.0 * a * c;

    if (discriminant < 0.0) {
        return 0;
    }

    if (discriminant == 0.0) {
        roots[0] = -b / (2.0 * a);
        return 1;
    }

    float SQRT = sqrt(discriminant);
    roots[0] = (-b + SQRT) / (2.0 * a);
    roots[1] = (-b - SQRT) / (2.0 * a);
    return 2;
}

int solveCubic(float a, float b, float c, float d, out vec3 roots) {
    // Return the number of real roots to the equation
    // a*x^3 + b*x^2 + c*x + d = 0 where a != 0 and populate roots.
    const float TAU = 6.2831853071795862;
    float A = b / a;
    float B = c / a;
    float C = d / a;
    float Q = (A * A - 3.0 * B) / 9.0;
    float R = (2.0 * A * A * A - 9.0 * A * B + 27.0 * C) / 54.0;
    float S = Q * Q * Q - R * R;
    float sQ = sqrt(abs(Q));
    roots = vec3(-A / 3.0);

    if (S > 0.0) {
        roots += -2.0 * sQ * cos(acos(R / (sQ * abs(Q))) / 3.0 + vec3(TAU, 0.0, -TAU) / 3.0);
        return 3;
    }
    
    if (Q == 0.0) {
        roots[0] += -pow(C - A * A * A / 27.0, 1.0 / 3.0);
        return 1;
    }
    
    if (S < 0.0) {
        float u = abs(R / (sQ * Q));
        float v = Q > 0.0 ? cosh(acosh(u) / 3.0) : sinh(asinh(u) / 3.0);
        roots[0] += -2.0 * sign(R) * sQ * v;
        return 1;
    }
    
    roots.xy += vec2(-2.0, 1.0) * sign(R) * sQ;
    return 2;
}

int solve(float a, float b, float c, float d, out vec3 roots) {
    // Return the number of real roots to the equation
    // a*x^3 + b*x^2 + c*x + d = 0 and populate roots.
    if (a == 0.0) {
        if (b == 0.0) {
            if (c == 0.0) {
                return 0;
            }
            
            roots[0] = -d/c;
            return 1;
        }
        
        vec2 r;
        int num = solveQuadratic(b, c, d, r);
        roots.xy = r;
        return num;
    }
    
    return solveCubic(a, b, c, d, roots);
}

float sdBezier(vec2 p, vec2 a, vec2 b, vec2 c) {
    vec2 A = a - 2.0 * b + c;
    vec2 B = 2.0 * (b - a);
    vec2 C = a - p;
    vec3 T;
    int num = solve(
        2.0 * dot(A, A),
        3.0 * dot(A, B),
        2.0 * dot(A, C) + dot(B, B),
        dot(B, C),
        T
    );
    T = clamp(T, 0.0, 1.0);
    float best = 1e30;
    
    for (int i = 0; i < num; ++i) {
        float t = T[i];
        float u = 1.0 - t;
        vec2 d = u * u * a + 2.0 * t * u * b + t * t * c - p;
        best = min(best, dot(d, d));
    }
    
    return sqrt(best);
}

void mainImage(out vec4 fragColor, vec2 fragCoord) {
    vec4 data = texelFetch(iChannel1, ivec2(fragCoord), 0);
    float sd = iFrame != 0 ? data.r : MAX_FLOAT;
    vec3 emissivity = iFrame != 0 ? data.gba : vec3(0.0);
    vec4 mouseA = iFrame > 0 ? texelFetch(iChannel0, ivec2(0, 0), 0) : vec4(0.0);
    vec4 mouseB = iFrame > 0 ? texelFetch(iChannel0, ivec2(1, 0), 0) : vec4(0.0);
    vec4 mouseC = iFrame > 0 ? texelFetch(iChannel0, ivec2(2, 0), 0) : iMouse;
    mouseA.xy += 0.5;
    mouseB.xy += 0.5;
    mouseC.xy += 0.5;
    float d = MAX_FLOAT;
    
    if (mouseB.z <= 0.0 && mouseC.z > 0.0) {
        d = distance(fragCoord, mouseC.xy);
    } else if (mouseA.z <= 0.0 && mouseB.z > 0.0 && mouseC.z > 0.0) {
        d = sdSegment(fragCoord, mouseB.xy, mix(mouseB.xy, mouseC.xy, 0.5));
    } else if (mouseA.z > 0.0 && mouseB.z > 0.0 && mouseC.z > 0.0) {
        d = sdBezier(
            fragCoord,
            mix(mouseA.xy, mouseB.xy, 0.5),
            mouseB.xy,
            mix(mouseB.xy, mouseC.xy, 0.5)
        );
    } else if (mouseA.z > 0.0 && mouseB.z > 0.0 && mouseC.z <= 0.0) {
        d = sdSegment(fragCoord, mix(mouseA.xy, mouseB.xy, 0.5), mouseB.xy);
    }
    
    d -= brushRadius * iResolution.y;
    
    if (
        d < max(0.0, sd) && !keyToggled(KEY_1) &&
        (mouseC.z != MAGIC || cos(iTime * 20.0) > 0.5)
    ) {
        sd = min(d, sd);
        emissivity = getEmissivity() * float(mouseC.z != MAGIC || cos(iTime * 10.0) > 0.5);
    }
    
    fragColor = vec4(sd, emissivity);
}
*/

vec3 calculateRadianceCascade()
{
    //TODO - implement it yourselfe - the ai,IboolshitYouNod machine has no idea

    return vec3(1.0, 0.0, 0.0);
}

void main() {
    vec3 N = normalize(vNormal);
    vec3 L = normalize(-uLightDir);
    vec3 V = normalize(uCameraPos - vWorldPos);
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
    fragColor = vec4(color, 1.0);
}
