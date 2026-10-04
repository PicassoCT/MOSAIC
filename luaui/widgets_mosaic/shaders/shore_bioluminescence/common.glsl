// Shared by the moving swash, persistent deposits and radiance capture.
// All distances are engine units; all clocks are simulation seconds.
uniform float shoreTime;
uniform float halfLife;
uniform float intensity;
float shoreHash(vec2 p) { return fract(sin(dot(p,vec2(127.1,311.7)))*43758.5453); }
float shoreNoise(vec2 p) {
    vec2 i=floor(p),f=fract(p);f=f*f*(3.0-2.0*f);
    return mix(mix(shoreHash(i),shoreHash(i+vec2(1,0)),f.x),
               mix(shoreHash(i+vec2(0,1)),shoreHash(i+vec2(1)),f.x),f.y);
}
float shoreOffset(vec2 p) { return 1.5*shoreNoise(p/600.0); }
float shoreRunup(vec2 p,float cycle) {
    return 12.0+24.0*shoreNoise(p/180.0+vec2(cycle*7.1,cycle*3.7))
        +3.0*shoreNoise(p/19.0);
}
float shoreRibbon(float distance,float centre,float width) {
    return 1.0-smoothstep(width*0.35,width,abs(distance-centre));
}
float shoreGrain(vec2 p) { return 0.35+0.65*smoothstep(0.2,0.8,shoreNoise(p/7.0)); }
float shoreFront(vec2 p,vec4 mask,float width) {
    float t=shoreTime-shoreOffset(p),cycle=floor(t/7.0),phase=fract(t/7.0);
    float runup=shoreRunup(p,cycle);
    float advance=smoothstep(0.0,0.4,phase);
    float retreat=smoothstep(0.4,1.0,phase);
    float position=phase<0.4 ? mix(-48.0,runup,advance) : mix(runup,-48.0,retreat);
    float envelope=smoothstep(0.02,0.13,phase)*(1.0-smoothstep(0.75,1.0,phase));
    return shoreRibbon(mask.r,position,width)*envelope*shoreGrain(p)*mask.g;
}
float shoreDeposit(vec2 p,vec4 mask,float previousTime,float width) {
    if(mask.r<=0.0 || mask.b<0.0) return 0.0;
    float offset=shoreOffset(p),cycle=floor((shoreTime-offset)/7.0),value=0.0;
    // Include the previous peak when one 10 Hz update straddles a cycle.
    for(int i=0;i<2;++i) {
        float n=cycle-float(i),peak=n*7.0+offset+2.8;
        if(peak>previousTime && peak<=shoreTime)
            value=max(value,shoreRibbon(mask.r,shoreRunup(p,n),width)
                *exp2(-(shoreTime-peak)/halfLife));
    }
    return value*shoreGrain(p)*mask.g;
}
