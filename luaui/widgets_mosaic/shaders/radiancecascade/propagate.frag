#version 150 compatibility

uniform sampler2D emissionTex;
uniform sampler2D occupancyTex;
uniform sampler2D parentTex;
uniform vec2 mapSize;
uniform int cascadeIndex;
uniform int hasParent;
uniform float baseInterval;

// Injected: BASE_PROBES, CASCADE_COUNT, MAX_TRACE_STEPS.
// Each cascade occupies the same texture area: quarter the probes, four times
// the angular samples. Direction tiles prevent filtering across directions.
// A parent probe starts its interval elsewhere. Test the connector from the
// child probe to that entry point before interpolating, otherwise bright parent
// probes on the other side of a wall leak through the coarse spatial grid.
vec4 visibleParentTap(vec2 originUV, ivec2 probe, int probes, ivec2 tile, int direction, int directions)
{
    vec4 value=texelFetch(parentTex,tile*probes+probe,0);
    if(max(value.r,max(value.g,value.b))<=0.0) return value;
    vec2 parentUV=(vec2(probe)+0.5)/float(probes);
    float angle=6.28318530718*(float(direction)+0.5)/float(directions);
    float entryDistance=baseInterval*(pow(4.0,float(cascadeIndex+1))-1.0)/3.0;
    vec2 entryUV=parentUV+vec2(cos(angle),sin(angle))*entryDistance/mapSize;
    vec2 delta=(entryUV-originUV)*mapSize;
    vec2 texelWorld=mapSize/vec2(textureSize(occupancyTex,0));
    int steps=min(MAX_TRACE_STEPS,max(1,int(ceil(length(delta)/(0.5*min(texelWorld.x,texelWorld.y))))));
    for(int i=0;i<MAX_TRACE_STEPS;++i) {
        if(i>=steps) break;
        vec2 uv=mix(originUV,entryUV,(float(i)+0.5)/float(steps));
        if(any(lessThan(uv,vec2(0.0))) || any(greaterThanEqual(uv,vec2(1.0)))) return vec4(0.0);
        if(texture2D(occupancyTex,uv).r>0.5) return vec4(0.0);
    }
    return value;
}

vec4 fetchParent(vec2 worldUV, int direction)
{
    int probes = BASE_PROBES >> (cascadeIndex + 1);
    int tiles = 2 << (cascadeIndex + 1);
    ivec2 tile = ivec2(direction % tiles, direction / tiles);
    vec2 p = worldUV * float(probes) - 0.5;
    ivec2 b = ivec2(floor(p));
    vec2 w = fract(p);
    ivec2 a = clamp(b, ivec2(0), ivec2(probes - 1));
    ivec2 c = clamp(b + ivec2(1), ivec2(0), ivec2(probes - 1));
    vec4 q00 = visibleParentTap(worldUV,a,probes,tile,direction,tiles*tiles);
    vec4 q10 = visibleParentTap(worldUV,ivec2(c.x,a.y),probes,tile,direction,tiles*tiles);
    vec4 q01 = visibleParentTap(worldUV,ivec2(a.x,c.y),probes,tile,direction,tiles*tiles);
    vec4 q11 = visibleParentTap(worldUV,c,probes,tile,direction,tiles*tiles);
    return mix(mix(q00,q10,w.x),mix(q01,q11,w.x),w.y);
}

void main()
{
    int probes = BASE_PROBES >> cascadeIndex;
    int tiles = 2 << cascadeIndex;
    ivec2 pixel = ivec2(gl_FragCoord.xy);
    ivec2 probe = pixel % probes;
    ivec2 tile = pixel / probes;
    int direction = tile.x + tile.y * tiles;
    int directions = tiles * tiles;
    vec2 originUV = (vec2(probe) + 0.5) / float(probes);
    float angle = 6.28318530718 * (float(direction) + 0.5) / float(directions);
    vec2 ray = vec2(cos(angle),sin(angle));
    float interval = baseInterval * pow(4.0,float(cascadeIndex));
    float start = baseInterval * (pow(4.0,float(cascadeIndex))-1.0) / 3.0;
    vec2 texelWorld = mapSize / vec2(textureSize(emissionTex,0));
    // Half an emission texel per step, bounded by the injected loop limit.
    int steps = min(MAX_TRACE_STEPS, max(1,int(ceil(interval / (0.5 * min(texelWorld.x,texelWorld.y))))));
    vec4 result = vec4(0.0,0.0,0.0,1.0); // RGB radiance, A transmittance
    for (int i=0; i<MAX_TRACE_STEPS; ++i) {
        if (i>=steps) break;
        float distance = start + (float(i)+0.5) * interval / float(steps);
        vec2 uv = originUV + ray * distance / mapSize;
        if (any(lessThan(uv,vec2(0.0))) || any(greaterThanEqual(uv,vec2(1.0)))) {
            result.a=0.0; // no clamped edge emission and no out-of-map parent
            break;
        }
        vec3 emitted = texture2D(emissionTex,uv).rgb;
        // An emitting surface may occupy the same cell as its host building.
        if (max(emitted.r,max(emitted.g,emitted.b)) > 0.001) {
            result=vec4(emitted,0.0);
            break;
        }
        if (texture2D(occupancyTex,uv).r > 0.5) {
            result.a=0.0;
            break;
        }
    }
    if (result.a > 0.0 && hasParent != 0) {
        vec4 farInterval=vec4(0.0);
        for (int child=0; child<4; ++child)
            farInterval += fetchParent(originUV,direction*4+child) * 0.25;
        result.rgb += result.a * farInterval.rgb;
        result.a *= farInterval.a;
    }
    gl_FragColor=result;
}
