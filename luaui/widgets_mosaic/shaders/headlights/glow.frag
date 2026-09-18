#version 150 compatibility
void main() {
    vec2 p = gl_TexCoord[0].xy * 2.0 - 1.0;
    float r2 = dot(p, p);
    float halo = exp(-r2 * 6.0) * (1.0 - smoothstep(0.65, 1.0, r2));
    float core = exp(-r2 * 65.0);
    gl_FragColor = vec4(gl_Color.rgb * (0.26 * halo + core), gl_Color.a);
}
