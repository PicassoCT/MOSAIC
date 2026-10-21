#version 150 compatibility
uniform vec3 ambient;
in vec4 wakeUVTime;
in vec2 wakeParameters;
in vec3 wakeBoundary;

float hash(vec2 p) {
    vec3 q=fract(vec3(p.xyx)*0.1031);
    q+=dot(q,q.yzx+33.33);
    return fract((q.x+q.y)*q.z);
}
float noise(vec2 p) {
    vec2 i=floor(p),f=fract(p);
    f=f*f*(3.0-2.0*f);
    return mix(mix(hash(i),hash(i+vec2(1,0)),f.x),
        mix(hash(i+vec2(0,1)),hash(i+vec2(1,1)),f.x),f.y);
}
void main() {
    float x=wakeUVTime.x,along=wakeUVTime.y,age=wakeUVTime.z;
    float remaining=wakeUVTime.w,seed=wakeParameters.x;
    float startFade=mix(wakeBoundary.y,1.0,smoothstep(0.0,0.16,wakeBoundary.x));
    float endFade=mix(wakeBoundary.z,1.0,smoothstep(0.0,0.16,1.0-wakeBoundary.x));
    float opacity=wakeParameters.y*startFade*endFade;
    if (age<0.0 || age>=15.0 || remaining<=0.0 || opacity<=0.0) discard;
    float life=clamp(remaining/15.0,0.0,1.0);
    float fade=pow(life,1.15)*smoothstep(0.0,0.35,remaining);
    vec2 flow=vec2(along*0.035-age*0.035+seed*0.17,x*1.8+seed*0.11);
    float broad=noise(flow);
    float detail=noise(flow*2.11+vec2(broad*1.3,age*0.035));
    float edge=1.0-smoothstep(0.56,1.0,abs(x)+(detail-0.5)*0.28);
    float curlA=0.34*sin(along*0.082-age*0.5+seed*0.31);
    float curlB=-0.42*sin(along*0.063-age*0.37+seed*0.43+1.7);
    float filaments=exp(-28.0*(x-curlA)*(x-curlA))
        +0.65*exp(-34.0*(x-curlB)*(x-curlB));
    // Smooth erosion opens holes as the wake cools. Adjacent spans use the
    // same distance/seed field, so no rectangular per-span pattern appears.
    float threshold=mix(0.10,0.62,smoothstep(1.0,14.0,age));
    float holes=smoothstep(threshold,threshold+0.23,broad*0.68+detail*0.32);
    float smoke=edge*holes*(0.16+0.55*filaments)*(0.62+0.38*detail);
    float hot=exp(-age*4.6);
    float afterglow=exp(-age*1.35);
    float aa=max(fwidth(x),0.004);
    float core=(1.0-smoothstep(0.040,0.040+aa,abs(x)))
        *min(1.0,0.080/aa)*hot;
    float halo=exp(-x*x*9.0)*afterglow*0.16;
    float coverage=clamp(opacity*fade,0.0,1.0);
    float alpha=clamp((smoke*0.50+core*0.72+halo)*coverage,0.0,0.95);
    vec3 cold=vec3(0.47,0.59,0.64)*clamp(ambient+vec3(0.22),vec3(0.25),vec3(1.0));
    vec3 cyan=vec3(0.30,0.79,1.0);
    vec3 smokeColor=mix(cold,cyan,afterglow*0.75);
    // Premultiplied energy. Only the first instant exceeds unit emission;
    // old residue has no light-source contribution and no additive dark box.
    vec3 energy=smokeColor*smoke*0.50+cyan*halo
        +vec3(0.67,0.91,1.0)*core*3.2;
    gl_FragColor=vec4(energy*coverage,alpha);
}
