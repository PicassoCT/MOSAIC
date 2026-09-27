#version 150 compatibility
out vec3 position;
void main(){position=(gl_ModelViewMatrix*gl_Vertex).xyz;gl_Position=vec4(position,1);}
