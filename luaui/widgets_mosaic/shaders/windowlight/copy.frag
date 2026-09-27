#version 150 compatibility
uniform sampler2D sourceTex;
uniform int channel;
uniform float gain;
uniform float minimumLight;
void main(){
    vec4 value=texture2D(sourceTex,gl_TexCoord[0].st);
    vec3 light=value.rgb*gain;
    if(minimumLight>0.0)light*=smoothstep(minimumLight,minimumLight*2.0,max(light.r,max(light.g,light.b)));
    gl_FragColor=channel<0?vec4(light,0):vec4(value[channel],0,0,0);
}
