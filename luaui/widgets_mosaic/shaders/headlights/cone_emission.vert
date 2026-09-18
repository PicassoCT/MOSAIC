#version 150 compatibility
out vec3 coneWorld;
void main() {
    coneWorld = gl_Vertex.xyz;
    gl_Position = gl_ModelViewProjectionMatrix * gl_Vertex;
}
