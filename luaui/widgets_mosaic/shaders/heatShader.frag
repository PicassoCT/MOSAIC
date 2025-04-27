
#version 150 compatibility

uniform sampler2D depthTex;
uniform sampler2D noiseTex;
uniform vec2 viewPortSize;
uniform float heatHazeStrength;
uniform float time;

float LinearizeDepth(float depth)
{
    float zNear = 1.0;
    float zFar = 5000.0;
    return (2.0 * zNear) / (zFar + zNear - depth * (zFar - zNear));
}

void main()
{
    vec2 uv = gl_TexCoord[0].st;

    float depth = texture2D(depthTex, uv).r;
    float linearDepth = LinearizeDepth(depth);

    float depthFactor = clamp(1.0 - linearDepth, 0.0, 1.0);

    vec3 upVec = vec3(0.0, 1.0, 0.0);
    vec3 viewRay = normalize(vec3(uv - 0.5, 0.5));
    float viewAngleFactor = 1.0 - abs(dot(viewRay, upVec));

    vec2 noiseCoord = uv * 10.0 + vec2(time * 0.1, time * 0.1);
    vec2 noiseSample = texture2D(noiseTex, noiseCoord).rg;
    noiseSample = (noiseSample - 0.5) * 2.0;

    float distortionStrength = heatHazeStrength * depthFactor * viewAngleFactor;

    uv += noiseSample * 0.01 * distortionStrength;

    vec4 finalColor = texture2D(tex0, uv);
    gl_FragColor = finalColor;
}
