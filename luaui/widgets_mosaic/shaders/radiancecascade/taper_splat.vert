#version 150 compatibility
uniform sampler2D captureEmission;
uniform sampler2D capturePosition;
out vec4 sampleEmission;
out vec4 samplePosition;
void main()
{
    // Display-list points address exact texel centres of the capture.
    sampleEmission = textureLod(captureEmission, gl_Vertex.xy, 0.0);
    samplePosition = textureLod(capturePosition, gl_Vertex.xy, 0.0);
    gl_Position = vec4(0.0);
}
