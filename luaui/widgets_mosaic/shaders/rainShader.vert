#version 150 compatibility
#line 200002

uniform sampler2D screentex;
uniform sampler2D raincanvastex;
uniform sampler2D depthtex;
uniform sampler2D noisetex;

uniform float time;		
uniform int maxLightSources;
uniform vec3 camWorldPos;
uniform vec2 viewPortSize;
uniform float rainDensity;

out Data {
			vec3 vfragWorldPos;
		};
 
void main(void)
{	
	vec4 eyePos = gl_ModelViewMatrix * vec4(gl_Vertex.xyz, 1.0);
	//if cam goes upwards go to raindrop shader
    //gl_Position =  gl_ModelViewProjectionMatrix * vec4(camWorldPos, 1.0);
    vfragWorldPos = (gl_ModelViewMatrix * vec4(camWorldPos, 1.0)).xyz;
    gl_Position = gl_Vertex;
}