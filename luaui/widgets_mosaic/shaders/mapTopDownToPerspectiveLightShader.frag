#version 150 compatibility


uniform sampler2D depthTex;
uniform sampler2D neonLightTex;
uniform samplerCube radianceCascade;

unform vec2 viewPortSize;
uniform mat4 invProjView;
uniform vec3 sunColor;
uniform vec3 skyColor;
uniform vec2 worldMin;
uniform vec2 worldMax;


#define RED vec4(1.0,0,0,1.0)

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
    const vec3 lSunColor = SunColor *10.;
    const float SunA = 2.0;
    const float SunS = 64.0;
    const float SSunS = sqrt(SunS);
    const float ISSunS = 1./SSunS;
    vec3 SI = SkyColor*(a1-a0-0.5*(cos(a1)-cos(a0)));
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


void main() {
    float depth = texture(depthTex, gl_FragCoord).r;

    // Reconstruct world position:
    vec4 ndc = vec4(gl_FragCoord * 2.0 - 1.0, depth * 2.0 - 1.0, 1.0);
    vec4 worldPos4 = invProjView * ndc;
    vec3 worldPos = worldPos4.xyz / worldPos4.w;

    // Map world XZ into neon light UV:
    vec2 lightUV;
    lightUV.x = (worldPos.x - worldMin.x) / (worldMax.x - worldMin.x);
    lightUV.y = (worldPos.z - worldMin.y) / (worldMax.y - worldMin.y);

    vec4 lightColor =    mainCubemap(lightUV);

    // Combine with scene color — here simply output light:
    gl_FragColor = lightColor;
    gl_FragColor = RED;
}
