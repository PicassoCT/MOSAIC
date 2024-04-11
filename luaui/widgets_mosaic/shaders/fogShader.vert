#version 150 compatibility
const vec4 frustumCorners[8] = vec4[](
	vec4(-1.0,  1.0, -1.0, 1.0),
	vec4( 1.0,  1.0, -1.0, 1.0),
	vec4( 1.0, -1.0, -1.0, 1.0),
	vec4(-1.0, -1.0, -1.0, 1.0),
	vec4(-1.0,  1.0,  1.0, 1.0),
	vec4( 1.0,  1.0,  1.0, 1.0),
	vec4( 1.0, -1.0,  1.0, 1.0),
	vec4(-1.0, -1.0,  1.0, 1.0)
);

struct AABB {
	vec3 Min;
	vec3 Max;
};

uniform mat4 viewProjectionInv;
uniform sampler2D emitmaptex;
uniform sampler2D emitunittex;
uniform sampler2D modelDepthTex;

out AABB aabbCamera;

const float BIG_NUM = 1e+20;

void main(void)
{
	aabbCamera.Min = vec3( BIG_NUM);
	aabbCamera.Max = vec3(-BIG_NUM);

	for (int i = 0; i < 8; ++i) {
		vec4 frustumCorner = frustumCorners[i];
		vec4 frustumCornersWS = viewProjectionInv * frustumCorner;
		frustumCornersWS /= frustumCornersWS.w;

		aabbCamera.Min = min(aabbCamera.Min, frustumCornersWS.xyz);
		aabbCamera.Max = max(aabbCamera.Max, frustumCornersWS.xyz);
	}

	gl_TexCoord[0] = gl_MultiTexCoord0;
	gl_Position    = gl_Vertex;
}
