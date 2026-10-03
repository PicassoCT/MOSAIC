#version 150 compatibility
in vec2 tracerUV;
in vec3 tracerColor;
uniform float nightIntensity;
void main() {
    float across=abs(tracerUV.y*2.0-1.0);
    float core=exp(-across*across*55.0);
    float halo=exp(-across*across*5.0)*(1.0-smoothstep(.7,1.0,across));
    float ends=smoothstep(0.0,.18,tracerUV.x)*(1.0-smoothstep(.86,1.0,tracerUV.x));
    gl_FragColor=vec4(tracerColor*(core*2.0+halo*.45)*ends*nightIntensity,0.0);
}
