// Decoded world normal: Y is up. Smooth masks keep terrain and unit roofs
// consistent without a material-dependent alpha flag or binary slope cutoff.
vec2 surfaceWaterWeights(float upwardness) {
    float wet = smoothstep(0.25, 0.8, upwardness);
    // Begin runoff on shallow roof/road inclines, keep truly flat roofs puddled.
    float puddle = smoothstep(0.975, 0.9995, upwardness);
    return vec2(wet,puddle);
}

float getSurfaceRivulets(vec3 p, vec3 normal) {
    // Use the actual surface tangent, including height, so steep roofs do not
    // compress their flow into almost stationary bands in the XZ plane.
    vec3 downhill = vec3(0,-1,0)+normal*normal.y;
    if (dot(downhill,downhill)<0.00001) downhill=vec3(1,0,0);
    downhill=normalize(downhill);
    vec3 across=normalize(cross(normal,downhill));
    float along=dot(p,downhill);
    float crossSlope=dot(p,across);
    // Meandering world-space channels, with highlights travelling downhill.
    float lane = crossSlope*0.125 + sin(along*0.075)*0.16;
    float centreDistance = abs(fract(lane+0.5)-0.5);
    float footprint = fwidth(lane);
    float aa = max(footprint*0.5,0.005);
    float channel = 1.0-smoothstep(0.045,0.10+aa,centreDistance);
    // Avoid multiplying two small subpixel factors. Fade once the whole lane
    // spacing is unresolved, rather than erasing narrow channels at normal zoom.
    channel *= 1.0-smoothstep(0.35,0.9,footprint);
    float laneID = floor(lane+0.5);
    float seed = fract(sin(laneID*127.1)*43758.5453);
    float travel = along*0.65 - time*5.0 + seed*6.2831853;
    float beads = 0.6+0.4*pow(0.5+0.5*sin(travel),3.0);
    return channel*beads;
}

// Stable broad puddles, separate from the fine impact pattern.
float surfaceWetNoise(vec2 p) {
    vec2 cell=floor(p), f=fract(p);
    f=f*f*(3.0-2.0*f);
    return mix(mix(hash3(cell).z,hash3(cell+vec2(1,0)).z,f.x),
               mix(hash3(cell+vec2(0,1)).z,hash3(cell+vec2(1,1)).z,f.x),f.y);
}
float surfacePuddleMask(vec2 p) {
    float patch=surfaceWetNoise(p/24.0)*0.7+surfaceWetNoise(p/7.0)*0.3;
    return smoothstep(0.28,0.7,patch);
}

// Explicit expanding crests and troughs, with the same seeds/birth phase as
// splashback. Radius stays below the approved 8/9-world-unit ripple cell size.
vec2 surfaceRippleProfile(vec2 position) {
    vec2 p=position*RAIN_RIPPLE_SCALE;
    vec2 cell=floor(p);
    float pixel=max(length(dFdx(p)),length(dFdy(p)));
    float aa=max(pixel*0.5,0.008);
    float resolved=1.0-smoothstep(0.75,2.0,pixel);
    vec2 result=vec2(0);
    for(int z=-1;z<=1;++z) for(int x=-1;x<=1;++x) {
        vec2 id=cell+vec2(x,z);
        vec3 seed=hash3(id);
        float age=mod(time*RAIN_RIPPLE_SPEED*2.0-(seed.x+seed.y)*5.0,2.0*PI)
                  /(RAIN_RIPPLE_SPEED*2.0);
        float radius=age*0.95;
        float distance=length(p-id-seed.xy);
        float life=smoothstep(0.0,0.06,age)*(1.0-smoothstep(0.45,0.85,age));
        float crest=1.0-smoothstep(0.045,0.045+aa,abs(distance-radius));
        float trough=1.0-smoothstep(0.06,0.06+aa,abs(distance-(radius-0.13)));
        result+=vec2(crest,trough)*life;
    }
    return clamp(result*resolved,0.0,1.0);
}
