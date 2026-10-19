#version 150 compatibility
// Cached once per viewport. The engine's raw $minimap contains authored ground
// imagery only. Explicit bottom-left UVs match WorldToScreenCoords and the FBO.
uniform sampler2D mapTex;
uniform vec3 mapRow0;
uniform vec3 mapRow1;
uniform vec3 mapRow2;
void main() {
    vec3 q = vec3(gl_TexCoord[0].st, 1.0);
    float denominator = dot(mapRow2, q);
    if (abs(denominator) < 0.00001) {
        gl_FragColor = vec4(0.0);
        return;
    }
    vec2 mapUV = vec2(dot(mapRow0, q), dot(mapRow1, q)) / denominator;
    if (any(lessThan(mapUV, vec2(0.0))) || any(greaterThan(mapUV, vec2(1.0)))) {
        gl_FragColor = vec4(0.0);
        return;
    }
    // Map edges can lie inside the screen. Feather their coverage as well as
    // the screen edge in the Earth pass, avoiding a rectangular survey stamp.
    vec2 edgeDistance = min(mapUV, 1.0 - mapUV);
    float coverage = smoothstep(0.0, 0.07, min(edgeDistance.x, edgeDistance.y));
    gl_FragColor = vec4(texture2D(mapTex, mapUV).rgb, coverage);
}
