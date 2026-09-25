#version 150 compatibility
// Screen quad; the current matrix stack describes a normalized cloud volume.
// Unproject homogeneous endpoints before dividing, including orthographic cameras.
uniform float zeroToOne;
uniform vec3 windView, upView;
uniform float windDeform;
flat out vec3 cloudWind, cloudUp;
noperspective out vec4 nearH;
noperspective out vec4 farH;
void main() {
    vec2 xy=gl_Vertex.xy;
    nearH=gl_ModelViewProjectionMatrixInverse*vec4(xy,mix(-1.0,0.0,zeroToOne),1.0);
    farH=gl_ModelViewProjectionMatrixInverse*vec4(xy,1.0,1.0);
    vec3 windLocal=(gl_ModelViewMatrixInverse*vec4(windView,0.0)).xyz;
    cloudWind=windLocal/max(length(windLocal),1e-7)*windDeform;
    // Height is a covector: transpose, not inverse. This keeps world-up and
    // world-wind correct for spinning, mirrored and non-uniformly scaled pieces.
    vec3 upLocal=(transpose(gl_ModelViewMatrix)*vec4(upView,0.0)).xyz;
    cloudUp=upLocal/max(length(upLocal),1e-7);
    gl_Position=vec4(xy,0.5,1.0);
}
