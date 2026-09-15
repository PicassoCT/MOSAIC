#version 150 compatibility

uniform sampler2D diffuseTex;
uniform sampler2D shadingTex;
uniform vec3 teamColor;
uniform float opacity;
uniform float time;
uniform float glitch;
uniform float seed;

in vec2 iconUV;

float hash(float value)
{
    return fract(sin(value * 127.1 + seed * 311.7) * 43758.5453);
}

void main()
{
    // Spring model convention: diffuse alpha is TEAM COLOUR, not opacity.
    // The second texture's alpha is the model's transparency/cutout mask.
    vec4 diffuse = texture2D(diffuseTex, iconUV);
    float alpha = texture2D(shadingTex, iconUV).a * opacity;
    if (alpha <= 0.01) discard;
    vec3 colour = mix(diffuse.rgb, teamColor, diffuse.a);

    if (glitch > 0.5) {
        // Screen-space interference leaves atlas UVs and silhouette intact.
        // Never offset atlas UVs into another icon's tile or add white bloom.
        float tick = floor(time * 12.0);
        float band = floor(gl_FragCoord.y / 7.0);
        float burst = step(0.82, hash(tick));
        float tear = burst * step(0.62, hash(band + tick * 19.0));
        float scanline = 0.90 + 0.10 * sin(gl_FragCoord.y * 1.7 + time * 8.0);
        vec3 interference = mix(vec3(0.1, 0.9, 1.0), vec3(1.0, 0.15, 0.55),
                                step(0.5, hash(band + tick)));
        colour = mix(colour, interference, tear * 0.55);
        alpha *= scanline * (1.0 - tear * 0.60);
    }

    gl_FragColor = vec4(colour, alpha);
}
