#version 150 compatibility
#line 200001

//Uniforms
uniform sampler2D modelDepthTex;
uniform sampler2D mapDepthTex;
uniform sampler2D noisetex;
uniform sampler2D screentex;
uniform sampler2D normaltex;
uniform sampler2D normalunittex;
uniform sampler2D skyboxtex;
uniform sampler2D raintex;

uniform vec4 lightSources[20];

uniform float time;		
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
uniform mat4 viewMatrix;

out Data {
			vec3 fragVertexPosition;
			vec3 viewDirection;
		};
 
void main(void)
{	
	//if cam goes upwards go to raindrop shader

    fragVertexPosition = gl_Vertex.xyz;

    gl_Position = gl_Vertex;

    vec4 worldPosition =  gl_ModelViewMatrix * gl_Position;
    viewDirection = normalize(worldPosition.xyz -eyePos);

}