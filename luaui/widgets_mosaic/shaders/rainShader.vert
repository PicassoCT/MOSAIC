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
    //viewDirection = normalize(gl_Position.xyz - eyePos);
    //viewDirection = normalize((viewProjectionInv * vec4(0, 0, 1.0, 1.0)).xyz);
    //viewDirection = gl_Normal.xyz; 
    //viewDirection = normalize(eyePos - (viewMatrix * gl_Vertex).xyz);
 	//viewDirection      = normalize( (gl_ModelViewMatrix * gl_Vertex).xyz - eyePos);
 	viewDirection = normalize(eyePos - (viewMatrix * gl_Vertex).xyz);


}