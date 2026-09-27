#version 150 compatibility
// Only this offscreen draw is deformed. Keep the undeformed surface for splats.
uniform vec3 buildingOrigin;
uniform float taperAmount;
uniform float taperHeight;
out vec3 originalPosition;
out vec3 originalNormal;
out vec2 sourceUV;
void main()
{
    // Caller supplies the same -90 degree X rotation as the cascade capture.
    vec4 view = gl_ModelViewMatrix * gl_Vertex;
    originalPosition = vec3(view.x, -view.z, view.y);
    vec3 n = gl_NormalMatrix * gl_Normal;
    originalNormal = vec3(n.x, -n.z, n.y);
    sourceUV = gl_MultiTexCoord0.st;
    float height = max(originalPosition.y - buildingOrigin.y, 0.0);
    float scale = 1.0 - taperAmount * clamp(height / taperHeight, 0.0, 1.0);
    view.xy = buildingOrigin.xz + (view.xy - buildingOrigin.xz) * scale;
    gl_Position = gl_ProjectionMatrix * view;
}
