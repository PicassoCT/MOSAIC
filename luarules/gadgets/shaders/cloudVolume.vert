#version 150 compatibility
// Screen quad; the current matrix stack describes a normalized cloud volume.
// Unproject homogeneous endpoints before dividing, including orthographic cameras.
uniform float zeroToOne;
noperspective out vec4 nearH;
noperspective out vec4 farH;
void main() {
    vec2 xy=gl_Vertex.xy;
    nearH=gl_ModelViewProjectionMatrixInverse*vec4(xy,mix(-1.0,0.0,zeroToOne),1.0);
    farH=gl_ModelViewProjectionMatrixInverse*vec4(xy,1.0,1.0);
    gl_Position=vec4(xy,0.5,1.0);
}
