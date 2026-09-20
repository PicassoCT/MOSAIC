// Decoded world normal: Y is up. Smooth masks keep terrain and unit roofs
// consistent without a material-dependent alpha flag or binary slope cutoff.
vec2 surfaceWaterWeights(float upwardness) {
    float wet = smoothstep(0.05, 0.65, upwardness);
    // Begin runoff on shallow roof/road inclines, keep truly flat roofs puddled.
    float puddle = smoothstep(0.975, 0.9995, upwardness);
    return vec2(wet,puddle);
}

float getSurfaceRivulets(vec3 p, vec3 normal, bool building) {
    // Use the actual surface tangent, including height, so steep roofs do not
    // compress their flow into almost stationary bands in the XZ plane.
    vec3 downhill = vec3(0,-1,0)+normal*normal.y;
    if (dot(downhill,downhill)<0.00001) downhill=vec3(1,0,0);
    downhill=normalize(downhill);
    vec3 across=normalize(cross(normal,downhill));
    // Double spatial frequency: runoff features are half their former size.
    float along=dot(p,downhill)*2.0;
    float crossSlope=dot(p,across)*2.0;
    // Measure the pixel on the surface, holding its local frame fixed. Taking
    // derivatives of dot(worldPosition, varyingNormal) introduces a spurious
    // worldPosition*dNormal term, erasing channels on curved/quantized slopes.
    vec3 pixelX=dFdx(p)*2.0, pixelY=dFdy(p)*2.0;
    vec2 uvX=vec2(dot(pixelX,across)/5.0,dot(pixelX,downhill)/18.0);
    vec2 uvY=vec2(dot(pixelY,across)/5.0,dot(pixelY,downhill)/18.0);
    float footprint=max(length(uvX),length(uvY));
    float travel=along*0.65-time*5.0+0.7*sin(crossSlope*0.23);
    float beads=0.4+0.6*pow(0.5+0.5*sin(travel),3.0);
    if(building) {
        // Manufactured surfaces shed into mostly straight, gently wandering lanes.
        float lane=crossSlope*0.125+sin(along*0.075)*0.16;
        float distance=abs(fract(lane+0.5)-0.5);
        float lanePixel=max(abs(dot(pixelX,across)),abs(dot(pixelY,across)))*0.125;
        float channel=1.0-smoothstep(0.045,0.10+max(lanePixel*0.5,0.005),distance);
        return channel*beads*(1.0-smoothstep(0.35,0.9,lanePixel));
    }
    // A stationary, elongated UV Voronoi network supplies irregular channels,
    // forks and junctions. Only the water pulses move, monotonically downhill.
    vec2 flowUV=vec2(crossSlope/5.0,along/18.0);
    flowUV.x += 0.18*sin(flowUV.y*2.3)+0.09*sin(flowUV.y*5.1+1.7);
    vec2 cell=floor(flowUV), local=fract(flowUV);
    float nearest=100.0, second=100.0;
    for(int y=-1;y<=1;++y) for(int x=-1;x<=1;++x) {
        vec2 id=cell+vec2(x,y);
        vec2 offset=vec2(x,y)+0.15+0.7*hash3(id).xy-local;
        float distance=dot(offset,offset);
        if(distance<nearest) { second=nearest; nearest=distance; }
        else second=min(second,distance);
    }
    float edge=sqrt(second)-sqrt(nearest);

    float width=0.035+0.025*(0.5+0.5*sin(along*0.19+crossSlope*0.31));
    float channel=1.0-smoothstep(width,width+max(footprint*0.65,0.018),edge);
    channel*=1.0-smoothstep(0.35,0.9,footprint);
    return channel*beads;
}

// Terrain default for standalone surface probes.
float getSurfaceRivulets(vec3 p, vec3 normal) {
    return getSurfaceRivulets(p,normal,false);
}

// Original roof-space bead model, visually inspired by BigWings' Heartfelt.
// Analytic ellipsoidal caps and short wakes; no screen-glass shader code used.
// xyz: world-space height gradient, w: bead/wake coverage.
vec4 roofWaterBeads(vec3 p, vec3 normal, bool building) {
    vec2 water=surfaceWaterWeights(normal.y);
    float eligible=building ? water.x*(1.0-water.y) : 0.0;
    vec3 gravity=vec3(0,-1,0)+normal*normal.y;
    if(dot(gravity,gravity)<0.00001) gravity=vec3(1,0,0);
    vec3 down=normalize(gravity), across=normalize(cross(normal,down));
    vec2 at=vec2(dot(p,across),dot(p,down));
    float pixel=max(length(dFdx(p)),length(dFdy(p)));
    float resolved=1.0-smoothstep(0.3,0.9,pixel);
    if(eligible*resolved<0.0001) return vec4(0);
    vec2 cell=floor(at/vec2(4,6));
    vec3 gradient=vec3(0);
    float mask=0.0;
    for(int y=-1;y<=1;++y) for(int x=-1;x<=1;++x) {
        vec2 id=cell+vec2(x,y);
        vec3 seed=hash3(id+vec2(71,19));
        float age=fract(time*(0.24+0.12*seed.x)+seed.z);
        // Grow in place, then accelerate downhill; fade before the reset.
        float slide=max(age-0.3,0.0)/0.7;
        float head=id.y*6.0+0.3+5.2*slide*slide;
        float centre=id.x*4.0-0.64*sin(head*0.15);
        vec2 delta=at-vec2(centre,head);
        vec2 radius=vec2(0.12+0.10*seed.y,0.18+0.16*seed.x);
        radius*=mix(0.45,1.0,smoothstep(0.0,0.3,age));
        vec2 filtered=sqrt(radius*radius+vec2(pixel*pixel*0.16));
        vec2 q=delta/filtered;
        float cap=max(1.0-dot(q,q),0.0);
        float life=smoothstep(0.0,0.12,age)*(1.0-smoothstep(0.85,1.0,age));
        float energy=radius.x*radius.y/(filtered.x*filtered.y);
        vec2 slope=-4.0*q/filtered*cap*0.055*life*energy;
        gradient+=across*slope.x+down*slope.y;
        float wakeLength=0.2+1.0*slide;
        float behind=-delta.y;
        float wake=(1.0-smoothstep(0.035,0.08+pixel*0.3,abs(delta.x)))
                  *smoothstep(0.0,0.12,behind)*(1.0-smoothstep(0.1,wakeLength,behind));
        mask=max(mask,(cap*cap*energy+wake*0.25)*life);
    }
    return vec4(gradient,clamp(mask,0.0,1.0))*eligible*resolved;
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

// Analytic gradient of a small Gaussian water ridge. Keep the existing impact
// seeds, expanding radii and lifetime, but light its curved surface instead of
// painting a uniformly bright circle. Broader pixel filters conserve amplitude.
vec2 surfaceRippleProfile(vec2 position) {
    vec2 p=position*RAIN_RIPPLE_SCALE;
    vec2 cell=floor(p);
    float pixel=max(length(dFdx(p)),length(dFdy(p)));
    float width=sqrt(0.075*0.075+pixel*pixel*0.25);
    float resolved=1.0-smoothstep(0.75,2.0,pixel);
    vec2 gradient=vec2(0);
    for(int z=-1;z<=1;++z) for(int x=-1;x<=1;++x) {
        vec2 id=cell+vec2(x,z);
        vec3 seed=hash3(id);
        float age=mod(time*RAIN_RIPPLE_SPEED*2.0-(seed.x+seed.y)*5.0,2.0*PI)
                  /(RAIN_RIPPLE_SPEED*2.0);
        float radius=age*0.95;
        vec2 radial=p-id-seed.xy;
        float distance=length(radial);
        float life=smoothstep(0.0,0.06,age)*(1.0-smoothstep(0.45,0.85,age));
        float t=(distance-radius)/width;
        float slope=-2.0*t*exp(-t*t)*0.032/width;
        gradient+=radial/max(distance,0.001)*slope*life*(0.075/width);
    }
    return gradient*resolved;
}
