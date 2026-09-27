#version 150 compatibility

uniform sampler2D terrainTex;
uniform vec4 viewport;
uniform float effectTime;
uniform float seed;
uniform float pixelSize;
out vec4 fragColor;

float hash(vec2 p)
{
    return fract(sin(dot(p, vec2(127.1, 311.7)) + seed) * 43758.5453);
}

void main()
{
    // Camera-aligned projection: the canopy shows the terrain the tank covers
    // from THIS view, rather than a top-down map decal sliding over its roof.
    vec2 pixel = gl_FragCoord.xy - viewport.xy;
    float size = max(pixelSize, 1.0);
    vec2 cell = floor(pixel / size);
    vec2 samplePixel = (cell + 0.5) * size;
    float tick = floor(effectTime * 7.0);

    // Rare blocks read a neighbour for one refresh; keep faults local and dim.
    float fault = step(0.978, hash(cell + vec2(tick, -tick)));
    samplePixel.x += fault * (hash(cell + tick + 17.0) < 0.5 ? -size : size);
    vec2 uv = clamp(samplePixel, vec2(0.5), viewport.zw - 0.5) / viewport.zw;
    vec3 color = texture(terrainTex, uv).rgb;

    // Mild quantization and fixed calibration differences leave the device
    // legible. Multiplicative defects preserve darkness at night.
    color = floor(color * 47.0 + 0.5) / 47.0;
    color *= 0.975 + 0.05 * hash(cell + 61.0);
    color *= 1.0 - fault * 0.13;
    float deadPixel = step(0.996, hash(cell + 109.0));
    color *= 1.0 - deadPixel * 0.32;
    fragColor = vec4(clamp(color, 0.0, 1.0), 1.0);
}
