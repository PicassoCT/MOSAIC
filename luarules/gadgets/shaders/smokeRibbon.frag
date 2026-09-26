#version 150 compatibility
uniform float effectTime, strandOpacity, hairMode;
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
