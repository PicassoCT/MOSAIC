#version 150 compatibility
in vec3 coneWorld;
uniform sampler2D buildingOccupancy;
uniform vec2 mapSize;
uniform vec3 lamp;
uniform vec2 forward;
uniform float lightRange;
uniform float strength;
uniform float hasOccupancy;
uniform int sourceMetadata=0;
uniform float sourceOwner=-1.0;
void main() {
    vec2 delta = coneWorld.xz - lamp.xz;
    float along = dot(delta, forward);
    if (along <= 0.0 || along >= lightRange) discard;
    float across = abs(dot(delta, vec2(forward.y,-forward.x)));
    float halfWidth = 3.0 + along * 0.42;
    float cone = 1.0-smoothstep(halfWidth*0.45,halfWidth,across);
    float fade = smoothstep(0.0,8.0,along)*(1.0-smoothstep(lightRange*0.55,lightRange,along));
    if (cone*fade < 0.001) discard;
    // Clip before emitting: propagation cannot remove sources behind a wall.
    if (hasOccupancy > 0.5) {
        float cells = length(delta / mapSize * vec2(textureSize(buildingOccupancy,0)));
        int steps = min(96,max(1,int(ceil(cells*2.0))));
        for(int i=1;i<=96;++i) {
            if(i>steps) break;
            vec2 p=mix(lamp.xz,coneWorld.xz,float(i)/float(steps))/mapSize;
            if(any(lessThan(p,vec2(0))) || any(greaterThanEqual(p,vec2(1)))) discard;
            if(texture2D(buildingOccupancy,p).r>0.5) discard;
        }
    }
    float energy=cone*fade*strength/(1.0+along*along/6000.0);
    vec3 radiance=vec3(1.0,0.91,0.76)*energy;
    float luminance=dot(radiance,vec3(0.2126,0.7152,0.0722));
    if(sourceMetadata!=0) {
        if(luminance<0.00001)discard;
        gl_FragColor=vec4(lamp,sourceOwner>=0.0 ? sourceOwner+1.0 : 0.5);
        gl_FragDepth=1.0/(1.0+luminance);
    } else {
        gl_FragColor=vec4(radiance,luminance*lamp.y/2048.0);
        gl_FragDepth=gl_FragCoord.z;
    }
}
