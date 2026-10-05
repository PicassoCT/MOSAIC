#version 150 compatibility
uniform sampler2D orbitTex;
uniform sampler2D artworkTex;
uniform sampler2D liveTex;
uniform float descent;
uniform float fade;
uniform int hasArtwork;
uniform int hasLive;
uniform vec2 artScale;
void main() {
    vec2 uv = gl_TexCoord[0].st;
    vec4 orbit = texture2D(orbitTex, uv);
    // The world is an image plane. No camera, geometry or simulation movement.
    float arrival = smoothstep(0.47, 0.55, descent) * float(hasLive);
    // The dramatic part of the dive happens in the Earth/cloud pass. Keep the
    // live image's final approach small so its captured bounds stay concealed.
    float zoom = mix(1.18, 1.0, smoothstep(0.50, 0.96, descent));
    vec2 liveUV = (uv - 0.5) * zoom + 0.5;
    vec3 live = texture2D(liveTex, liveUV).rgb;
    if (descent >= 0.96) {
        ivec2 size = textureSize(liveTex, 0);
        live = texelFetch(liveTex, clamp(ivec2(uv * vec2(size)), ivec2(0), size - 1), 0).rgb;
    }
    vec3 scene = mix(orbit.rgb, live, arrival);
    vec3 cloud = mix(vec3(0.79, 0.85, 0.90), orbit.rgb, smoothstep(0.35, 0.42, descent));
    // Cover the edges of the expanding image plane while it is smaller than
    // the screen: no clamped-border smearing as the city rushes towards us.
    vec2 distanceToEdge = min(liveUV, 1.0 - liveUV);
    float borderCloud = 1.0 - smoothstep(0.0, 0.10, min(distanceToEdge.x, distanceToEdge.y));
    borderCloud *= (1.0 - smoothstep(0.85, 0.96, descent)) * arrival;
    scene = mix(scene, cloud, max(orbit.a, borderCloud));
    vec2 artUV = (uv - 0.5) * artScale + 0.5;
    vec3 art = texture2D(artworkTex, artUV).rgb;
    scene = mix(art, scene, hasArtwork == 1 ? fade : 1.0);
    // At descent=1 this is exactly the unmodified live framebuffer at original UV.
    gl_FragColor = vec4(scene, 1.0);
}
