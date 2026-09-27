#version 150 compatibility
in vec2 worldXZ;
uniform vec2 sourceXZ;
uniform vec3 sourceShape; // footprint radius, horizontal reach, vertical fade distance
uniform vec2 sourceY; // actual world-space base/top (or lamp interval)
void main() {
    float distance=max(0.0,length(worldXZ-sourceXZ)-sourceShape.x);
    float r=distance/max(sourceShape.y,1.0);
    if(r>=1.0) discard;
    // Nearest source wins; interpolating heights would invent a source between floors.
    gl_FragDepth=min(0.9999,distance/2048.0);
    float coverage=1.0-smoothstep(0.65,1.0,r);
    float fade=sourceShape.z*sqrt(max(0.0,1.0-r*r));
    gl_FragColor=vec4(sourceY,max(1.0,fade),coverage);
}
