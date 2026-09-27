#version 150 compatibility
uniform vec3 captureOrigin;
uniform vec2 captureSize;
uniform vec2 captureDirection;
out vec3 worldPosition;
out vec3 worldNormal;
out vec2 sourceUV;
void main() {
    // The caller starts with identity MODELVIEW; gl.Unit supplies real transforms.
    worldPosition=(gl_ModelViewMatrix*gl_Vertex).xyz;
    worldNormal=normalize(gl_NormalMatrix*gl_Normal);
    sourceUV=gl_MultiTexCoord0.st;
    vec3 p=worldPosition-captureOrigin;
    vec2 right=vec2(captureDirection.y,-captureDirection.x);
    gl_Position=vec4(2.0*dot(p.xz,right)/captureSize.x,
        2.0*p.y/captureSize.y-1.0,
        0.5-dot(p.xz,captureDirection)/(2.0*captureSize.x),1.0);
    // Explicit [0,1] depth works in both legacy and Recoil clip conventions.
}
