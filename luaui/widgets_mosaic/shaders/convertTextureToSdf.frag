#version 150 compatibility

out float outSDF;
in vec2 v_uv; // UV coordinates of current fragment

uniform vec2 u_center;   // Center of the circle
uniform float u_radius;  // Radius of the circle

void main() {
    float dist = length(v_uv - u_center) - u_radius;
    float maxDist = 0.05;

    // Normalize to [0,1]
    outSDF = 0.5 + dist / (2.0 * maxDist);
}
