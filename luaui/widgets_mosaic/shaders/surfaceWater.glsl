// Decoded world normal: Y is up. Smooth masks keep terrain and unit roofs
// consistent without a material-dependent alpha flag or binary slope cutoff.
vec2 surfaceWaterWeights(float upwardness) {
    float wet = smoothstep(0.45, 0.92, upwardness);
    float puddle = smoothstep(0.94, 0.995, upwardness);
    return vec2(wet,puddle);
}

float getSurfaceRivulets(vec3 p, vec3 normal) {
    // Gravity projected onto the tangent plane has horizontal component n.y*n.xz.
    // On flat surfaces the direction is irrelevant: the puddle mask takes over.
    vec2 downhill = normal.xz / max(length(normal.xz),0.0001);
    if (dot(downhill,downhill) < 0.5) downhill = vec2(1,0);
    vec2 across = vec2(-downhill.y,downhill.x);
    float along = dot(p.xz,downhill);
    float crossSlope = dot(p.xz,across);
    // Meandering world-space channels, with highlights travelling downhill.
    float lane = crossSlope*0.35 + sin(along*0.075)*0.16;
    float centreDistance = abs(fract(lane+0.5)-0.5);
    float aa = max(fwidth(lane),0.005);
    float channel = 1.0-smoothstep(0.035,0.09+aa,centreDistance);
    channel *= 0.09 / (0.09+aa);
    float laneID = floor(lane+0.5);
    float seed = fract(sin(laneID*127.1)*43758.5453);
    float travel = along*0.65 - time*5.0 + seed*6.2831853;
    float beads = 0.35+0.65*pow(0.5+0.5*sin(travel),3.0);
    return channel*beads;
}
