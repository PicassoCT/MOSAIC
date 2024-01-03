#version 150 compatibility
#line 200002

uniform sampler2D screentex;
uniform sampler2D raincanvastex;
uniform sampler2D depthtex;
uniform sampler2D noisetex;

uniform float time;		
uniform int maxLightSources;
uniform vec3 eyePos;
uniform vec2 viewPortSize;
uniform float rainDensity;
uniform mat4 viewProjectionInv;

out Data {
			vec3 fragVertexPosition;
			vec3 viewDirection;
		};
 
void main(void)
{	
	//if cam goes upwards go to raindrop shader

    fragVertexPosition = gl_Vertex.xyz;
    gl_Position = gl_Vertex;
}