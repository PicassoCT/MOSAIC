#version 150 compatibility

uniform sampler2D occ0;
uniform sampler2D occ1;
uniform sampler2D occ2;
uniform sampler2D occ3;
uniform sampler2D occ4;
uniform sampler2D occ5;
uniform sampler2D occ6;
uniform sampler2D occ7;
uniform sampler2D occ8;
uniform sampler2D occ9;
uniform sampler2D occ10;
uniform sampler2D occ11;
uniform sampler2D occ12;
uniform sampler2D occ13;
uniform sampler2D occ14;
uniform sampler2D occ15;

uniform vec2 emitterUV;
uniform float emitterHeight;
uniform vec2 mapSize;
uniform float lightRange;

// Do not let the emitter's host building occlude the ray at its endpoint.
// This is world-space distance, not UV distance.
const float EMITTER_OCCLUSION_CLEARANCE = 128.0;

float sampleOcclusion(int layer, vec2 uv)
{
    if (layer <= 0) return texture2D(occ0, uv).r;
    if (layer == 1) return texture2D(occ1, uv).r;
    if (layer == 2) return texture2D(occ2, uv).r;
    if (layer == 3) return texture2D(occ3, uv).r;
    if (layer == 4) return texture2D(occ4, uv).r;
    if (layer == 5) return texture2D(occ5, uv).r;
    if (layer == 6) return texture2D(occ6, uv).r;
    if (layer == 7) return texture2D(occ7, uv).r;
    if (layer == 8) return texture2D(occ8, uv).r;
    if (layer == 9) return texture2D(occ9, uv).r;
    if (layer == 10) return texture2D(occ10, uv).r;
    if (layer == 11) return texture2D(occ11, uv).r;
    if (layer == 12) return texture2D(occ12, uv).r;
    if (layer == 13) return texture2D(occ13, uv).r;
    if (layer == 14) return texture2D(occ14, uv).r;
    return texture2D(occ15, uv).r;
}

void main()
{
    vec2 receiverUV = gl_TexCoord[0].st;
    vec2 worldDelta = (emitterUV - receiverUV) * mapSize;
    float distanceToLight = length(worldDelta);
    float visibility = 1.0;

    for (int stepIndex = 1; stepIndex < DIRECT_LIGHT_STEPS; ++stepIndex) {
        float t = float(stepIndex) / float(DIRECT_LIGHT_STEPS);
        vec2 rayUV = mix(receiverUV, emitterUV, t);
        float rayHeight = mix(8.0, emitterHeight, t);
        int layer = int(clamp(
            floor(rayHeight * OCCLUSION_LAYER_COUNT / OCCLUSION_WORLD_HEIGHT),
            0.0,
            OCCLUSION_LAYER_COUNT - 1.0
        ));

        vec2 remainingWorldDelta = (emitterUV - rayUV) * mapSize;
        bool outsideEmitterClearance =
            length(remainingWorldDelta) > EMITTER_OCCLUSION_CLEARANCE;

        if (outsideEmitterClearance && sampleOcclusion(layer, rayUV) > 0.5) {
            visibility = 0.0;
            break;
        }
    }

    float attenuation = max(0.0, 1.0 - distanceToLight / lightRange);
    attenuation *= attenuation;
    gl_FragColor = vec4(vec3(visibility * attenuation), 1.0);
}
