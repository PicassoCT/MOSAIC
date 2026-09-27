#version 150 compatibility
uniform sampler2D emissionTex;
uniform sampler2D positionTex;
out vec4 sourceEmission;
out vec4 sourcePosition;
void main(){
    sourceEmission=textureLod(emissionTex,gl_Vertex.xy,0.0);
    sourcePosition=textureLod(positionTex,gl_Vertex.xy,0.0);
    gl_Position=vec4(0,0,0,1);
}
