#version 150 compatibility
uniform vec3 origin, direction, cameraPosition;
uniform vec3 directionalDrift;
uniform float effectTime, plumeLength, plumeWidth, curl, seed;
uniform float hairMode, stiffness, gravity;
out vec2 ribbonUV;
out float ribbonSeed;

// Analytic, advecting vortex paths: no particle buffers or integration passes.
vec3 centre(float t, float strand, vec3 u, vec3 v) {
    if (hairMode > 0.5) {
        // Fixed arc length: integrate short unit tangents; roots never advect.
        vec3 p = origin;
        for (int i=0; i<12; ++i) {
            float q = t * (float(i)+0.5)/12.0;
            float flex = (1.0-stiffness)*q*q;
            float wave = sin(effectTime*2.1 + q*3.0 + seed + strand*2.4);
            vec3 bend = direction + vec3(0,-gravity*q,0)
                + directionalDrift/max(plumeLength,0.001)*flex
                + u*(wave*curl*flex);
            p += normalize(bend) * (plumeLength*t/12.0);
        }
        return p;
    }
    float s = seed + strand * 2.399963;
    float phase = t * 14.0 - effectTime * 1.7 + s;
    float envelope = t * t * (3.0 - 2.0 * t);
    float radius = plumeWidth * curl * envelope;
    float bend = sin(t * 5.0 - effectTime * 0.43 + seed);
    float p = phase + 0.85 * sin(phase * 0.61 + s);
    vec2 coil = vec2(sin(p), cos(p * 0.91 + s)) * (0.55 + 0.25 * sin(phase * 0.47));
    coil += vec2(bend, sin(t * 7.0 - effectTime * 0.57 + s)) * 0.45;
    // Axial modulation folds the upper wisps as they roll away from the source.
    float axial = t * plumeLength + radius * 0.4 * sin(p + 0.7);
    return origin + direction * axial + radius * (u * coil.x + v * coil.y)
        + directionalDrift * (t*t);
}
void main() {
    float t = gl_Vertex.x;
    float side = gl_Vertex.y;
    float strand = gl_Vertex.z;
    vec3 helper = abs(direction.y) < 0.9 ? vec3(0,1,0) : vec3(1,0,0);
    vec3 u = normalize(cross(direction, helper));
    vec3 v = cross(direction, u);
    vec3 p = centre(t, strand, u, v);
    vec3 tangent = centre(min(1.0,t+0.005),strand,u,v) - centre(max(0.0,t-0.005),strand,u,v);
    if (dot(tangent,tangent) < 1e-10) tangent = direction;
    tangent = normalize(tangent);
    vec3 across = cross(tangent, cameraPosition-p);
    if (dot(across,across) < 1e-8) across = cross(tangent,helper);
    if (dot(across,across) < 1e-8) across = cross(tangent,vec3(0,0,1));
    across = normalize(across);
    float spread = (0.035 + 0.55 * pow(t,0.8)) * smoothstep(0.0,0.025,t);
    float breath = 0.8 + 0.2 * sin(t*17.0-effectTime*1.7+seed+strand);
    if (hairMode > 0.5) {
        spread = 0.5 * pow(max(0.0,1.0-t),0.65);
        breath = 1.0;
    }
    p += across * side * plumeWidth * spread * breath;
    ribbonUV = vec2(side,t);
    ribbonSeed = seed + strand * 2.399963;
    gl_Position = gl_ModelViewProjectionMatrix * vec4(p,1.0);
}
