#version 150 compatibility
layout(points) in;
layout(triangle_strip, max_vertices=4) out;
in vec4 sampleEmission[];
in vec4 samplePosition[];
flat out vec3 emitted;
uniform vec2 domainOrigin;
uniform vec2 domainSize;
uniform vec2 atlasSize;
uniform vec2 heightRange;
uniform float heightFalloff;
uniform float emissionStrength;
uniform float sourceOffset;
void main()
{
    vec4 e = sampleEmission[0];
    if (e.a <= 0.0 || max(e.r, max(e.g, e.b)) <= 0.001) return;
    vec4 p = samplePosition[0];
    // Preserve source heights through capture, then weight EACH contribution
    // before addition. This is an artistic 2.5D approximation, not 3D transport.
    float gap = max(max(heightRange.x - p.y, p.y - heightRange.y), 0.0);
    float weight = 1.0 / (1.0 + pow(gap / heightFalloff, 2.0));
    vec2 normal = vec2(cos(p.w), sin(p.w));
    vec2 texelWorld = domainSize / atlasSize;
    // Fixed world footprint when zoomed in; at least two target texels when far
    // away. Snap its centre to texels so additive raster area is deterministic.
    vec2 halfPixels = max(vec2(1.0), ceil(vec2(8.0) / texelWorld));
    vec2 halfWorld = halfPixels * texelWorld;
    float clearance = sourceOffset + dot(abs(normal), halfWorld);
    vec2 position = p.xz + normal * clearance;
    vec2 pixel = floor((position - domainOrigin) / texelWorld) + vec2(0.5);
    float area = 4.0 * halfWorld.x * halfWorld.y;
    emitted = e.rgb * (e.a / area) * weight * emissionStrength;
    for (int i = 0; i < 4; ++i) {
        vec2 corner = vec2(i % 2 == 0 ? -1.0 : 1.0, i < 2 ? -1.0 : 1.0);
        vec2 uv = (pixel + corner * halfPixels) / atlasSize;
        gl_Position = vec4(uv * 2.0 - 1.0, 0.0, 1.0);
        EmitVertex();
    }
    EndPrimitive();
}
