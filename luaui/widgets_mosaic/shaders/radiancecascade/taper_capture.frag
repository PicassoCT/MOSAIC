#version 150 compatibility
uniform sampler2D sourceTex;
uniform sampler2D materialTex;
in vec3 originalPosition;
in vec3 originalNormal;
in vec2 sourceUV;
void main()
{
    // Facades become narrow strips. Integrate within the texel footprint so
    // rows of small windows do not beat against the capture grid as taper changes.
    vec2 dx = dFdx(sourceUV), dy = dFdy(sourceUV);
    vec3 emission = vec3(0.0);
    float coverage = 0.0;
    for (int y = 0; y < 4; ++y) for (int x = 0; x < 4; ++x) {
        vec2 coord = sourceUV + dx * ((float(x)+0.5)/4.0-0.5)
            + dy * ((float(y)+0.5)/4.0-0.5);
        vec4 material = textureGrad(materialTex, coord, dx/4.0, dy/4.0);
        emission += textureGrad(sourceTex, coord, dx/4.0, dy/4.0).rgb * material.r * material.a;
        coverage += material.a;
    }
    emission /= 16.0;
    coverage /= 16.0;
    // Spring texture 2: red = self illumination; alpha = coverage.
    if (coverage < 0.5) discard;
    vec3 normal = normalize(originalNormal);
    float area = length(cross(dFdx(originalPosition), dFdy(originalPosition)));
    // This experiment extracts facades. Roofs still write depth, including
    // unlit roofs, so they cannot reveal hidden surfaces through themselves.
    if (abs(normal.y) > 0.8) emission = vec3(0.0);
    // Derivative area compensates for taper and capture resolution. Do not
    // discard unlit surfaces: they must occlude luminous geometry behind them.
    gl_FragData[0] = vec4(emission, area);
    gl_FragData[1] = vec4(originalPosition, atan(normal.z, normal.x));
}
