#version 150 compatibility
#line 200001
#define NORM2SNORM(value) (value * 2.0 - 1.0)
#define SNORM2NORM(value) (value * 0.5 + 0.5)

//Uniforms
uniform sampler2D modelDepthTex;
uniform sampler2D mapDepthTex;
uniform sampler2D rainDroplettTex;
uniform sampler2D screentex;
uniform sampler2D normaltex;
uniform sampler2D normalunittex;
uniform sampler2D noisetex;
uniform sampler2D raintex;
uniform sampler2D dephtCopyTex;


uniform float time;		
uniform float timePercent;
uniform float rainPercent;
uniform vec3 eyePos;
uniform vec3 sunCol;
uniform vec3 sunPos;
uniform vec3 eyeDir;
uniform vec3 skyCol;

uniform vec2 viewPortSize;
uniform vec3 cityCenter;
uniform mat4 viewProjectionInv;
uniform mat4 viewProjection;
uniform mat4 viewInv;
uniform mat4 viewMatrix;

out Data {
			vec3 viewDirection;
			vec4 fragWorldPos;
			noperspective vec2 v_screenUV;
		};
 
void main(void)
{	
	//if cam goes upwards go to raindrop shader
    gl_Position = gl_Vertex;
    //procues a noralized vector showing the camera direction
    //vec4 worldPosition =  gl_ModelViewMatrix * gl_Position;
    viewDirection = normalize(eyePos - (viewMatrix * gl_Vertex).xyz);
    //viewDirection = normalize(viewProjectionInv* vec4(eyeDir,1)).xyz;
    fragWorldPos= viewProjectionInv * vec4(vec3(gl_TexCoord[0].st,  texture2D(dephtCopyTex, gl_TexCoord[0].st ).x) * 2.0 - 1.0, 1.0);
    fragWorldPos.xyz = fragWorldPos.xyz / fragWorldPos.w;// YAAAY this works!
    v_screenUV = SNORM2NORM(gl_Position.xy / gl_Position.w);
}