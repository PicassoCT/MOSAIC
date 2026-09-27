#version 150 compatibility
out vec4 value;
void main(){gl_Position=vec4(gl_Vertex.xy,0.5,1);value=vec4(gl_Vertex.z,gl_Color.gba);gl_PointSize=1.0;}
