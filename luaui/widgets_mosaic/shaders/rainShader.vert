
#version 150 compatibility
uniform sampler2D raincanvasTex;
uniform sampler2D depthTex;
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
    gl_Position = projectionMatrix * viewMatrix * vec4(camPosition, 1.0);
    vfragWorldPos = (viewMatrix * vec4(camPosition, 1.0)).xyz;
}
									  ]