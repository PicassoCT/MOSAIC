#version 150 compatibility

uniform sampler2D diffuseTex;
uniform sampler2D materialTex;
uniform float effectTime;
uniform float seed;
uniform vec3 cameraPosition;
uniform vec3 ambient;
in vec3 worldPosition;
in vec3 worldNormal;
in vec2 materialUV;

float hash(vec2 p)
{
    vec3 q = fract(vec3(p.xyx) * .1031);
    q += dot(q, q.yzx + 33.33);
    return fract((q.x + q.y) * q.z);
}

float noise(vec2 p)
{
    vec2 i = floor(p);
    vec2 f = fract(p);
    f = f * f * (3.0 - 2.0 * f);
    return mix(mix(hash(i), hash(i + vec2(1, 0)), f.x),
               mix(hash(i + vec2(0, 1)), hash(i + vec2(1, 1)), f.x), f.y);
}

// World-space mapping keeps gravity correct on every rotated mesh and avoids
// the atlas's tightly packed/mirrored UVs. Positive phase moves the water down.
vec2 waterDetail(vec2 surface)
{
    vec2 flow = surface * vec2(.65, .18) + vec2(seed, effectTime * 2.2);
    float bend = noise(flow * vec2(.3, .55)) - .5;
    float strands = noise(flow * vec2(1.0, .4) + vec2(bend * 1.2, 0));
    float brokenFoam = noise(flow * vec2(.6, 1.7) + 19.7);
    float foam = smoothstep(.48, .88, strands) * (.35 + .65 * brokenFoam);

    vec2 fine = flow * vec2(3.5, 2.8);
    float facets = noise(fine + vec2(bend, 0));
    // Subpixel sparkles fade into the water instead of producing distant crawl.
    float footprint = max(length(dFdx(fine)), length(dFdy(fine)));
    float resolved = 1.0 - smoothstep(.35, 1.4, footprint);
    float sparkle = smoothstep(.78, .97, facets) * resolved;
    return vec2(foam, sparkle);
}

void main()
{
    vec3 n = normalize(worldNormal);
    vec3 weights = pow(abs(n), vec3(4.0));
    weights /= max(dot(weights, vec3(1)), .0001);
    vec2 detail = waterDetail(worldPosition.zy) * weights.x
                + waterDetail(worldPosition.xy) * weights.z
                + waterDetail(worldPosition.xz) * weights.y;
    vec3 source = texture(diffuseTex, materialUV).rgb;
    float emission = texture(materialTex, materialUV).r;
    vec3 waterColor = mix(source, vec3(.12, .34, .39), .16);
    vec3 lighting = mix(max(ambient, vec3(.32)), vec3(1), max(.6, emission));
    vec3 viewDirection = normalize(cameraPosition - worldPosition);
    float fresnel = pow(1.0 - abs(dot(n, viewDirection)), 3.0);
    vec3 color = waterColor * lighting * (.72 + detail.x * .8);
    color += vec3(.65, .86, .92) * detail.x * .23;
    color += mix(vec3(.8, .92, 1), source, .18) * detail.y * (1.5 + fresnel);
    // This is solid surface shading, never additive or alpha-transparent water.
    gl_FragColor = vec4(color, 1.0);
}
