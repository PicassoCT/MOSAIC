
#version 150 compatibility											 
uniform sampler2D raincanvasTex;
uniform sampler2D depthTex;
uniform float time;		
uniform vec3 camWorldPos;
uniform vec2 viewPortSize;
	
in Data {
			vec4 accumulatedLightColorRay;
		 };

void main(void)
{
	vec2 uv = gl_FragCoord.xy / viewPortSize;
	gl_FragColor = texture2D(depthTex, uv); 
}
										
										
