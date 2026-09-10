#version 150 compatibility

uniform sampler2D screencopy;
uniform vec2 resolution;
uniform float realTime;
uniform float slowAmount;
uniform float temporalPrivilege;
uniform float activationAge;

float luminance(vec3 c)
{
    return dot(c, vec3(0.299, 0.587, 0.114));
}

void main()
{
    vec2 uv = gl_TexCoord[0].st;
    vec2 safeResolution = max(resolution, vec2(1.0));
    vec2 px = 1.0 / safeResolution;

    float slow = clamp(slowAmount, 0.0, 1.0);
    float privilege = clamp(temporalPrivilege, 0.0, 1.0);
    float outsider = 1.0 - privilege;

    vec3 original = texture2D(screencopy, uv).rgb;

    float aspect = safeResolution.x / safeResolution.y;
    vec2 centered = (uv - vec2(0.5)) * vec2(aspect, 1.0);

    float pulseEnvelope = 1.0 - smoothstep(0.0, 0.8, activationAge);
    float ringRadius = activationAge * 1.35;
    float ringDistance = abs(length(centered) - ringRadius);
    float activationRing = (1.0 - smoothstep(0.012, 0.045, ringDistance)) * pulseEnvelope * slow;

    float chromaOffset = px.x * (1.0 + 4.0 * activationRing);
    vec3 shifted = vec3(
        texture2D(screencopy, uv + vec2(chromaOffset, 0.0)).r,
        original.g,
        texture2D(screencopy, uv - vec2(chromaOffset, 0.0)).b
    );

    vec3 color = mix(original, shifted, activationRing * 0.70);

    float luma = luminance(color);
    color = mix(color, vec3(luma), 0.34 * slow);

    vec3 coolGrade = color * vec3(0.95, 0.99, 1.06);
    color = mix(color, coolGrade, 0.55 * slow);

    float lumaLeft  = luminance(texture2D(screencopy, uv - vec2(px.x * 2.0, 0.0)).rgb);
    float lumaRight = luminance(texture2D(screencopy, uv + vec2(px.x * 2.0, 0.0)).rgb);
    float lumaDown  = luminance(texture2D(screencopy, uv - vec2(0.0, px.y * 2.0)).rgb);
    float lumaUp    = luminance(texture2D(screencopy, uv + vec2(0.0, px.y * 2.0)).rgb);

    float temporalEdge = max(
        abs(lumaRight - lumaLeft),
        abs(lumaUp - lumaDown)
    );
    temporalEdge = clamp(temporalEdge * 3.5, 0.0, 1.0);

    color += temporalEdge * slow * vec3(0.0, 0.030, 0.060);

    vec2 fieldUV = vec2(uv.x * aspect, uv.y);
    float fieldA = sin((fieldUV.x + fieldUV.y * 0.63) * 62.0 + realTime * 2.1);
    float fieldB = sin((fieldUV.x * 0.37 - fieldUV.y) * 47.0 - realTime * 1.3);
    float field = fieldA * fieldB;
    color += vec3(0.0, 0.012, 0.022) * field * slow * (0.55 + 0.45 * privilege);

    float vignette = smoothstep(0.30, 0.90, length(centered));
    color *= 1.0 - outsider * slow * 0.24 * vignette;

    float scan = 0.5 + 0.5 * sin(gl_FragCoord.y * 1.10 + realTime * 2.0);
    color -= vec3(0.012, 0.016, 0.020) * scan * outsider * slow;

    color += activationRing * vec3(0.025, 0.080, 0.120);

    gl_FragColor = vec4(clamp(color, 0.0, 1.0), 1.0);
}
