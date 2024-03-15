#version 150 compatibility
#line 200001

//Uniforms
uniform sampler2D depthtex;
uniform sampler2D noisetex;
uniform sampler2D screentex;
uniform sampler2D normaltex;
uniform sampler2D normalunittex;
uniform sampler2D skyboxtex;
uniform sampler2D raintex;

uniform vec4 lightSources[20];

uniform float time;		
uniform float rainDensity;
uniform int maxLightSources;
uniform float timePercent;
uniform float rainPercent;
uniform vec3 eyePos;
uniform vec3 sundir;
uniform vec3 suncolor;
uniform vec3 skycolor;

uniform vec2 viewPortSize;
uniform vec3 cityCenter;
uniform mat4 viewProjectionInv;
uniform mat4 viewProjection;
uniform mat4 viewInv;

out Data {
			vec3 fragVertexPosition;
			vec3 viewDirection;
		};
 
void main(void)
{	
	//if cam goes upwards go to raindrop shader

    fragVertexPosition = gl_Vertex.xyz;
    gl_Position = gl_Vertex;
    viewDirection = normalize(gl_Position.xyz - eyePos);
}