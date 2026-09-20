// Decoded world normal: Y is up. Smooth masks keep terrain and unit roofs
// consistent without a material-dependent alpha flag or binary slope cutoff.
vec2 surfaceWaterWeights(float upwardness) {
    float wet = smoothstep(0.05, 0.65, upwardness);
    // Begin runoff on shallow roof/road inclines, keep truly flat roofs puddled.
    float puddle = smoothstep(0.975, 0.9995, upwardness);
    return vec2(wet,puddle);
}

// Fixed world charts avoid position*dNormal phase distortion on curved roofs.
// Height always increases uphill, so downward animation works for every azimuth.
// Choose the less foreshortened vertical projection; chart boundaries can seam.
vec3 runoffChartAcross(vec3 normal) {
    return abs(normal.x)>abs(normal.z) ? vec3(0,0,normal.x>=0.0 ? -1.0 : 1.0)
                                    : vec3(normal.z>=0.0 ? 1.0 : -1.0,0,0);
}
vec2 runoffChart(vec3 p, vec3 across) {
    return vec2(dot(p,across),-p.y*1.41421356);
}
float surfaceWetNoise(vec2 p);
float getSurfaceRivulets(vec3 p, vec3 normal, bool building) {
    vec3 across=runoffChartAcross(normal);
    vec2 at=runoffChart(p,across);
    // Independent world scales: fine building lanes, broad terrain channels.
    float scale=building ? 8.0 : 1.0;
    float along=at.y*scale;
    float crossSlope=at.x*scale;
    vec2 pixelX=runoffChart(dFdx(p),across)*scale;
    vec2 pixelY=runoffChart(dFdy(p),across)*scale;
    vec2 uvX=pixelX/vec2(5,18), uvY=pixelY/vec2(5,18);
    float footprint=max(length(uvX),length(uvY));
    // Independently timed channels, with only a gentle swell over a wet baseline.
    float laneID=floor(at.x/(building ? 1.0 : 5.0)+0.5);
    vec3 timing=hash3(vec2(laneID,building ? 31.0 : 59.0));
    float travel=along*(0.48+0.25*timing.y)-time*(2.5+2.0*timing.x)+timing.z*6.2831853;
    float beads=0.92+0.08*pow(0.5+0.5*sin(travel),3.0);
    if(building) {
        float lane=crossSlope*0.125+sin(along*0.075)*0.16;
        float distance=abs(fract(lane+0.5)-0.5);
        float lanePixel=max(abs(pixelX.x),abs(pixelY.x))*0.125;
        float widthScale=mix(0.45,1.8,timing.z);
        widthScale*=mix(0.8,1.2,surfaceWetNoise(vec2(laneID,at.y*0.18)));
        float channel=1.0-smoothstep(0.045*widthScale,0.10*widthScale+max(lanePixel*0.5,0.005),distance);
        return channel*beads*(1.0-smoothstep(0.35,0.9,lanePixel));
    }
    // A stationary, elongated UV Voronoi network supplies irregular channels,
    // forks and junctions. Only the water pulses move, monotonically downhill.
    vec2 flowUV=vec2(crossSlope/5.0,along/18.0);
    flowUV.x += 0.18*sin(flowUV.y*2.3)+0.09*sin(flowUV.y*5.1+1.7);
    vec2 cell=floor(flowUV), local=fract(flowUV);
    float nearest=100.0, second=100.0;
    vec2 nearOffset=vec2(0), secondOffset=vec2(0);
    for(int y=-1;y<=1;++y) for(int x=-1;x<=1;++x) {
        vec2 id=cell+vec2(x,y);
        vec2 offset=vec2(x,y)+0.15+0.7*hash3(id).xy-local;
        float distance=dot(offset,offset);
        if(distance<nearest) {
            second=nearest; secondOffset=nearOffset;
            nearest=distance; nearOffset=offset;
        } else if(distance<second) { second=distance; secondOffset=offset; }
    }
    float edge=sqrt(second)-sqrt(nearest);

    float width=mix(0.018,0.09,surfaceWetNoise(flowUV*0.7+vec2(13,37)));
    float channel=1.0-smoothstep(width,width+max(footprint*0.65,0.018),edge);
    channel*=1.0-smoothstep(0.5,1.25,footprint);
    // Boundary tangent must have a downhill component: avoid a glowing wire mesh.
    vec2 edgeNormal=normalize(secondOffset-nearOffset+vec2(0.00001));
    float downhill=smoothstep(0.2,0.75,abs(edgeNormal.x));
    float surge=pow(0.5+0.5*sin(travel+surfaceWetNoise(flowUV)*2.0),3.0);
    return channel*downhill*(0.72+0.28*surge);
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
    vec3 chartAcross=runoffChartAcross(normal);
    vec2 at=runoffChart(p,chartAcross);
    vec3 across=chartAcross-normal*dot(normal,chartAcross);
    vec3 down=(vec3(0,-1,0)+normal*normal.y)*1.41421356;
    float pixel=max(length(dFdx(p)),length(dFdy(p)));
    float resolved=1.0-smoothstep(2.0,5.0,pixel);
    if(eligible*resolved<0.0001) return vec4(0);
    vec2 cell=floor(at/vec2(3,6));
    vec3 gradient=vec3(0);
    float mask=0.0;
    for(int y=-1;y<=1;++y) for(int x=-1;x<=1;++x) {
        vec2 id=cell+vec2(x,y);
        vec3 seed=hash3(id+vec2(71,19));
        float age=fract(time*(0.14+0.08*seed.x)+seed.z);
        // Grow in place, then accelerate downhill; fade before the reset.
        float slide=max(age-0.55,0.0)/0.45;
        float head=id.y*6.0+0.4+4.8*slide*slide;
        float centre=id.x*3.0+(seed.y-0.5)*1.2-0.16*sin(head*0.6);
        vec2 delta=at-vec2(centre,head);
        vec2 radius=vec2(0.45+0.35*seed.y,0.67+0.51*seed.x);
        radius*=mix(0.45,1.0,smoothstep(0.0,0.55,age));
        vec2 filtered=sqrt(radius*radius+vec2(pixel*pixel*0.16));
        vec2 q=delta/filtered;
        float cap=max(1.0-dot(q,q),0.0);
        float life=smoothstep(0.0,0.12,age)*(1.0-smoothstep(0.85,1.0,age));
        float energy=radius.x*radius.y/(filtered.x*filtered.y);
        vec2 slope=-4.0*q/filtered*cap*0.22*life*energy;
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
