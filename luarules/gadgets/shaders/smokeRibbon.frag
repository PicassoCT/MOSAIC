#version 150 compatibility
uniform float effectTime, strandOpacity, hairMode, electricMode;
uniform vec4 colorStart, colorEnd;
uniform vec4 sourceGlow;
uniform vec2 emission;
uniform vec3 ambient;
in vec2 ribbonUV;
in float ribbonSeed;
float hash(vec2 p) {
    vec3 q = fract(vec3(p.xyx) * 0.1031);
    q += dot(q,q.yzx + 33.33);
    return fract((q.x+q.y)*q.z);
}
float noise(vec2 p) {
    vec2 i=floor(p), f=fract(p);
    f=f*f*(3.0-2.0*f);
    return mix(mix(hash(i),hash(i+vec2(1,0)),f.x),
               mix(hash(i+vec2(0,1)),hash(i+vec2(1,1)),f.x),f.y);
}
void main() {
    float x=ribbonUV.x, age=ribbonUV.y;
    if (hairMode > 1.5 && electricMode > 1.5) {
        // Sparse cyan/violet branches are embedded in the moving cloud curve.
        // Each bundle has a different smooth pulse; long upward tips are occasional.
        float activation = smoothstep(0.46,0.80,
            noise(vec2(effectTime*0.47,ribbonSeed*0.19+11.0)));
        float flow = age*18.0-effectTime*3.4;
        float jitter = (noise(vec2(flow,ribbonSeed))-0.5)*0.28;
        float aa = max(fwidth(x),0.008);
        float core = (1.0-smoothstep(0.075,0.075+aa,abs(x-jitter)))
            * min(1.0,0.15/aa);
        float forkGate = smoothstep(0.14,0.30,age)*(1.0-smoothstep(0.52,0.73,age));
        float forkX = jitter+(sin(ribbonSeed)>0.0 ? 1.0 : -1.0)
            *(0.38+0.12*sin(flow*1.3))*forkGate;
        float fork = (1.0-smoothstep(0.04,0.04+aa,abs(x-forkX)))
            * min(1.0,0.08/aa)*forkGate;
        float halo = exp(-9.0*x*x)*0.10;
        float fade = smoothstep(0.0,0.05,age)*(1.0-smoothstep(0.80,1.0,age));
        float pulse = (0.10+0.90*activation)
            * (0.55+0.45*noise(vec2(age*7.0-effectTime*2.6,ribbonSeed+4.0)));
        pulse *= mix(1.0,0.15+0.85*activation,smoothstep(0.68,0.80,age));
        vec4 color = mix(colorStart,colorEnd,age);
        float coverage = color.a*strandOpacity*fade*pulse;
        float alpha = clamp((core+fork*0.65+halo)*coverage,0.0,0.96);
        vec3 hot = mix(color.rgb,vec3(1.0),0.12);
        float glow = max(1.0,mix(emission.x,emission.y,age));
        gl_FragColor = vec4((hot*(core+fork*0.65)*1.4+color.rgb*halo)*glow*coverage,alpha);
        return;
    }
    if (hairMode > 1.5) {
        // A cloud of unresolved fibres, not a handful of hard black stripes.
        // Broad moving folds carry fine anisotropic detail. Average subpixel
        // fibres before they alias, preserving the veil at tactical zoom.
        vec2 flow = vec2(x*2.8+ribbonSeed,age*5.0-effectTime*0.4);
        float broad = noise(flow);
        float folds = noise(flow*1.93+vec2(broad*1.4,0.0));
        float warp = x+0.18*(noise(vec2(age*4.0-effectTime*0.3,ribbonSeed))-0.5);
        float fibreCoord = warp*96.0+ribbonSeed*7.0;
        float fibres = noise(vec2(fibreCoord,age*3.0-effectTime*0.28));
        fibres = mix(fibres,0.5,smoothstep(0.6,1.5,fwidth(fibreCoord)));
        float edge = 1.0-smoothstep(0.30,1.0,abs(x)+(broad-0.5)*0.22);
        float density = mix(0.30,0.90,broad)*mix(0.65,1.0,folds)*mix(0.65,1.0,fibres);
        // The material remains a blurred cloud. Only a few short dark branches
        // emerge from it; their contrast vanishes as they become subpixel.
        float branchX = 0.24*sin(age*5.0-effectTime*0.22+ribbonSeed);
        float branchWidth = max(0.045,fwidth(x)*1.4);
        float branchDistance = (x-branchX)/branchWidth;
        float branch = exp(-branchDistance*branchDistance)
            * smoothstep(0.76,0.94,hash(vec2(ribbonSeed,3.1)))
            * smoothstep(0.24,0.43,age)*(1.0-smoothstep(0.72,0.90,age));
        branch *= 0.045/branchWidth;
        density = clamp(density+branch*0.16,0.0,1.0);
        float fade = smoothstep(0.0,0.10+0.05*broad,age)
            * (1.0-smoothstep(0.65+0.1*folds,1.0,age));
        // A faint tint lets nearby charge show through the soot-like material.
        // Bright energy belongs to the attached filaments, not every broad tip.
        float tip = smoothstep(0.62,0.92,age);
        vec4 color = mix(colorStart,colorEnd,tip*0.035);
        float alpha = clamp(0.68*edge*density*fade*color.a*strandOpacity,0.0,0.92);
        float glow = mix(emission.x,emission.y,tip);
        vec3 lighting = mix(ambient,vec3(1.0),clamp(glow,0.0,1.0));
        vec3 electric = mix(colorEnd.rgb,vec3(0.08,0.30,1.0),fibres*0.45);
        float pulse = 0.25+0.75*noise(vec2(effectTime*0.34,ribbonSeed));
        vec3 energy = electric*glow*tip*(0.025+branch*0.3)*pulse;
        gl_FragColor = vec4((color.rgb*lighting+energy)*alpha,alpha);
        return;
    }
    if (hairMode > 0.5) {
        // Static longitudinal fibres; no smoke holes, scrolling or emission.
        float phase = x*3.5 + ribbonSeed + 0.1*sin(age*5.0+ribbonSeed);
        float line = abs(fract(phase)-0.5);
        float aa = max(fwidth(phase),0.015);
        float fibres = 1.0-smoothstep(0.28-aa,0.28+aa,line);
        // Preserve coverage when individual fibres become smaller than a pixel.
        fibres = mix(fibres,0.56,smoothstep(0.35,0.8,aa));
        float edge = 1.0-smoothstep(0.75,1.0,abs(x));
        vec4 color = mix(colorStart,colorEnd,age);
        float tips = 1.0-smoothstep(0.82+0.1*sin(phase*2.0),1.0,age);
        float alpha = color.a*edge*fibres*strandOpacity*tips;
        gl_FragColor = vec4(color.rgb*ambient*alpha,alpha);
        return;
    }
    if (electricMode > 0.5) {
        // Bright continuous cores and short forks retain the discharge colour.
        // A small white highlight keeps the core hot without washing out its hue.
        // Pixel coverage keeps narrow filaments
        // visible at tactical zoom without widening them into opaque bands.
        float flow = age*25.0-effectTime*3.0;
        float jitter = (noise(vec2(flow,ribbonSeed))-0.5)*0.22;
        float aa = max(fwidth(x),0.006);
        float core = (1.0-smoothstep(0.065,0.065+aa,abs(x-jitter)))
            * min(1.0,0.13/aa);
        float forkGate = smoothstep(0.20,0.33,age)*(1.0-smoothstep(0.55,0.86,age));
        float forkSide = sin(ribbonSeed)>0.0 ? 1.0 : -1.0;
        float forkX = jitter+forkSide*(0.35+0.09*sin(flow*1.9))*forkGate;
        float fork = (1.0-smoothstep(0.035,0.035+aa,abs(x-forkX)))
            * min(1.0,0.07/aa)*forkGate;
        float halo = exp(-6.0*x*x)*(1.0-smoothstep(0.72,1.0,abs(x)))*0.22;
        float pulse = 0.78+0.22*noise(vec2(age*9.0-effectTime*4.0,ribbonSeed+7.0));
        float fade = smoothstep(0.0,0.02,age)*(1.0-smoothstep(0.78,1.0,age));
        vec4 color = mix(colorStart,colorEnd,age);
        float coverage = fade*color.a*strandOpacity*pulse;
        float alpha = clamp((halo+core+fork*0.7)*coverage,0.0,0.98);
        vec3 coreColor = mix(color.rgb,vec3(1.0),0.16);
        float glow = max(1.0,mix(emission.x,emission.y,age));
        float sourceFade = 1.0-smoothstep(0.0,max(sourceGlow.a,0.0001),age);
        vec3 energy = color.rgb*halo + coreColor*(core+fork*0.7)*1.4;
        gl_FragColor = vec4((energy*glow+sourceGlow.rgb*sourceFade*halo)*coverage,alpha);
        return;
    }
    vec2 flow=vec2(x*2.0+ribbonSeed,age*7.0-effectTime*0.85);
    float broad=noise(flow);
    float detail=noise(flow*2.07+vec2(broad*1.8,0));
    float edge=1.0-smoothstep(0.32,1.0,abs(x)+(broad-0.5)*0.35);
    float folds=0.5+0.5*sin(x*13.0 + broad*7.0 + age*10.0-effectTime*1.4);
    float body=mix(0.35,1.0,broad)*mix(0.55,1.0,detail);
    float density=edge*body*mix(0.55,1.0,folds);
    float fade=smoothstep(0.0,0.035,age)*(1.0-smoothstep(0.65,1.0,age));
    vec4 color=mix(colorStart,colorEnd,age);
    float alpha=clamp(density*fade*color.a*strandOpacity,0.0,0.98);
    float glow=mix(emission.x,emission.y,age);
    vec3 lighting=mix(ambient,vec3(1.0),clamp(glow,0.0,1.0))+vec3(max(0.0,glow-1.0));
    // Local ember tint fades near the source, independently of the grey plume.
    float sourceFade=1.0-smoothstep(0.0,max(sourceGlow.a,0.0001),age);
    // Premultiplied alpha: soft grey smoke and bright wisps share one blend mode.
    gl_FragColor=vec4((color.rgb*lighting+sourceGlow.rgb*sourceFade)*alpha,alpha);
}
