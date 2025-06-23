// Fork of "Radiance Cascades" by fad. https://shadertoy.com/view/mtlBzX
// 2023-09-02 14:11:55

// Controls:
// Click and drag with mouse to draw
// Press space to toggle betweem emissive and non-emissive brush
// Press 1 to switch to drawing a temporary light instead of permanent

// A 2D implementation of 
// Radiance Cascades: A Novel Approach to Calculating Global Illumination
// https://drive.google.com/file/d/1L6v1_7HY2X-LV3Ofb6oyTIxgEaP4LOI6/view

// You can set the parameters to the algorithm in the Common tab

// Sky integral formula taken from
// Analytic Direct Illumination - Mathis
// https://www.shadertoy.com/view/NttSW7

// sdBezier() formula taken from
// Quadratic Bezier SDF With L2 - Envy24
// https://www.shadertoy.com/view/7sGyWd

// In this Shadertoy implementation there is a bit of temporal lag which
// is not due to a flaw in the actual algorithm, but rather a limitation
// of Shadertoy - one of the steps in the algorithm is to merge cascades
// in a reverse mipmap-like fashion which would actually be done within
// one frame, but in Shadertoy we have to split that work up over
// multiple frames. Even with this limitation, it still looks good and
// only has an n-frame delay to fully update the lighting, where n is
// the total number of cascades.

// For small point lights, a ringing artefact is visible. I couldn't
// figure out a way to fix this properly :(

// This buffer interpolates the radiance coming from cascade 0

void mainImage(out vec4 fragColor, vec2 fragCoord) {
    screenRes = iResolution.xy;
    ivec2 cubemapRes = textureSize(iChannel0, 0);
    vec2 p = fragCoord / iResolution.xy * vec2(c_sRes);
    ivec2 q = ivec2(round(p)) - 1;
    vec2 w = p - vec2(q) - 0.5;
    ivec2 h = ivec2(1, 0);
    vec4 S0 = cascadeFetch(iChannel0, 0, q + h.yy, 0);
    vec4 S1 = cascadeFetch(iChannel0, 0, q + h.xy, 0);
    vec4 S2 = cascadeFetch(iChannel0, 0, q + h.yx, 0);
    vec4 S3 = cascadeFetch(iChannel0, 0, q + h.xx, 0);
    vec3 fluence = mix(mix(S0, S1, w.x), mix(S2, S3, w.x), w.y).rgb * 2.0 * PI;
    // Overlay actual SDF drawing to fix low resolution edges
    vec4 data = sampleDrawing(iChannel1, fragCoord);
    fluence = mix(fluence, data.gba * 2.0 * PI, clamp(3.0 - data.r, 0.0, 1.0));
    // Tonemap
    fragColor = vec4(1.0 - 1.0 / pow(1.0 + fluence, vec3(2.5)), 1.0);
}

/*
CubeA
*/

// This buffer calculates and merges radiance cascades. Normally the
// merging would happen within one frame (like a mipmap calculation),
// meaning this technique actually has no termporal lag - but since
// Shadertoy has no way of running a pass multiple times per frame, we 
// have to resort to spreading out the merging of cascades over multiple
// frames.

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
    vec4 p = sampleDrawing(iChannel1, ro);
    float t = 0.0f;
    if (p.r > 0.0) {
        t = intersect(ro, rd, tMax);
        
        if (t == -1.0) {
            return RayHit(vec4(0.0, 0.0, 0.0, 1.0), 1e5f);
        }

        p = sampleDrawing(iChannel1, ro + rd * t);
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
    const vec3 SkyColor = vec3(0.2,0.5,1.);
    const vec3 SunColor = vec3(1.,0.7,0.1)*10.;
    const float SunA = 2.0;
    const float SunS = 64.0;
    const float SSunS = sqrt(SunS);
    const float ISSunS = 1./SSunS;
    vec3 SI = SkyColor*(a1-a0-0.5*(cos(a1)-cos(a0)));
    SI += SunColor*(atan(SSunS*(SunA-a0))-atan(SSunS*(SunA-a1)))*ISSunS;
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

void mainCubemap(out vec4 fragColor, vec2 fragCoord, vec3 fragRO, vec3 fragRD) {
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
    vec2 screenRes = vec2(textureSize(iChannel1, 0));
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
                vec4 S0 = cascadeFetch(iChannel0, n + 1, q + h.yy, j);
                vec4 S1 = cascadeFetch(iChannel0, n + 1, q + h.xy, j);
                vec4 S2 = cascadeFetch(iChannel0, n + 1, q + h.yx, j);
                vec4 S3 = cascadeFetch(iChannel0, n + 1, q + h.xx, j);
                vec4 S = mix(mix(S0, S1, w.x), mix(S2, S3, w.x), w.y);
                si.rgb += si.a * S.rgb;
                si.a *= S.a;
            }
        }
        
        s += si;
    }
    
    s /= float(nDirs / cn_dRes);
    fragColor = s;
}




/*Buffer  B*/

// This buffer draws the SDF:
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



/*
Buffer A:*/


// SDF drawing logic from 
// Smooth Mouse Drawing - fad
// https://www.shadertoy.com/view/dldXR7

// This buffer tracks smoothed mouse positions over multiple frames.

// See https://lazybrush.dulnan.net/ for what these mean:
#define RADIUS (iResolution.y * 0.015)
#define FRICTION 0.05

void mainImage(out vec4 fragColor, vec2 fragCoord) {
    if (fragCoord.y != 0.5 || fragCoord.x > 3.0) {
        return;
    }

    if (iFrame == 0) {
        if (fragCoord.x == 2.5) {
            fragColor = iMouse;
        } else {
            fragColor = vec4(0.0);
        }
        
        return;
    }
    
    vec4 iMouse = iMouse;
    
    if (iMouse == vec4(0.0)) {
        float t = iTime * 3.0;
        iMouse.xy = vec2(
            cos(3.14159 * t) + sin(0.72834 * t + 0.3),
            sin(2.781374 * t + 3.47912) + cos(t)
        ) * 0.25 + 0.5;
        iMouse.xy *= iResolution.xy;
        iMouse.z = MAGIC;
    }
    
    vec4 mouseA = texelFetch(iChannel0, ivec2(1, 0), 0);
    vec4 mouseB = texelFetch(iChannel0, ivec2(2, 0), 0);
    vec4 mouseC;
    mouseC.zw = iMouse.zw;
    float dist = distance(mouseB.xy, iMouse.xy);
    
    if (mouseB.z > 0.0 && (mouseB.z != MAGIC || iMouse.z == MAGIC) && dist > 0.0) {
        vec2 dir = (iMouse.xy - mouseB.xy) / dist;
        float len = max(dist - RADIUS, 0.0);
        float ease = 1.0 - pow(FRICTION, iTimeDelta * 10.0);
        mouseC.xy = mouseB.xy + dir * len * ease;
    } else {
        mouseC.xy = iMouse.xy;
    }
    
    if (fragCoord.x == 0.5) {
        fragColor = mouseA;
    } else if (fragCoord.x == 1.5) {
        fragColor = mouseB.z == MAGIC && iMouse.z != MAGIC ? vec4(0.0) : mouseB;
    } else {
        fragColor = mouseC;
    }
}

/*Common */
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