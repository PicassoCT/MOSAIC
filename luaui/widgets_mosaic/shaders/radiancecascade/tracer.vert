#version 150 compatibility
out vec2 tracerUV;
out vec3 tracerColor;
void main() {
    tracerUV=gl_MultiTexCoord0.xy;
    tracerColor=gl_Color.rgb;
    gl_Position=gl_ModelViewProjectionMatrix*gl_Vertex;
}
