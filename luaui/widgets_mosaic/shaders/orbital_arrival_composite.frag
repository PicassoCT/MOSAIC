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
    // The city grows from the passing clouds rather than cutting in at
    // one instant. All movement is texture-space: no camera rotation.
    float progress = smoothstep(0.43, 1.0, descent);
    float zoom = mix(3.0, 1.0, smoothstep(0.44, 1.0, descent));
    vec2 liveUV = (uv - 0.5) * zoom + 0.5;
    // CopyToTexture flips framebuffer Y, never X.
    vec2 liveSampleUV = vec2(liveUV.x, 1.0 - liveUV.y);
    vec3 live = texture2D(liveTex, liveSampleUV).rgb;
    // Identical final framebuffer pixels, preventing image warp at release.
    if (descent >= 0.98) {
        ivec2 size = textureSize(liveTex, 0);
        vec2 finalUV = vec2(uv.x, 1.0 - uv.y);
        live = texelFetch(liveTex,
            clamp(ivec2(finalUV * vec2(size)), ivec2(0), size - 1), 0).rgb;
    }
    vec2 bounds = min(liveUV, 1.0 - liveUV);
    float opening = smoothstep(-0.02, 0.10, min(bounds.x, bounds.y));
    opening = mix(opening, 1.0, smoothstep(0.85, 0.98, descent));
    // Opaque clouds hide the different coordinate systems; thinning clouds
    // expose the enlarged city image continuously over the final beats.
    float reveal = progress * (1.0 - orbit.a) * opening * float(hasLive);
    vec3 scene = mix(orbit.rgb, live, reveal);
    vec2 artUV = (uv - 0.5) * artScale + 0.5;
    vec3 art = texture2D(artworkTex, artUV).rgb;
    scene = mix(art, scene, hasArtwork == 1 ? fade : 1.0);
    gl_FragColor = vec4(scene, 1.0);
}
