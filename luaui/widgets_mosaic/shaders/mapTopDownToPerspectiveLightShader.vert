#version 150 compatibility

uniform sampler2D neonLightTex;
uniform sampler2D depthTex;

uniform vec2 worldMin;
uniform vec2 worldMax;
uniform mat4 invProjView;

void main() {
    gl_Position = gl_Vertex;
}