#version 150 compatibility
uniform sampler2D orbitTex;
uniform sampler2D artworkTex;
uniform sampler2D liveTex;
uniform float descent; // cloud/reveal phase only; planetary snapshots keep this at zero
uniform float fade;
uniform int hasArtwork;
uniform int hasLive;
uniform vec2 artScale;
void main() {
    vec2 uv = gl_TexCoord[0].st;
    vec4 orbit = texture2D(orbitTex, uv);
    // The projected survey already matches the destination's screen plane.
    // Reveal the real ground and objects at that scale, with no extra zoom or
    // rotation. CopyToTexture is an unflipped OpenGL framebuffer copy; every
    // renderer pass supplies explicit bottom-left UVs to avoid TexRect defaults.
    vec3 live = texture2D(liveTex, uv).rgb;
    float grade = 1.0 - smoothstep(0.78, 0.98, descent);
    float luma = dot(live, vec3(0.299, 0.587, 0.114));
    vec3 muted = mix(live, vec3(luma), 0.24);
    vec3 amber = muted * vec3(1.08, 0.92, 0.68);
    amber += vec3(0.025, 0.017, 0.007) * (1.0 - luma);
    live = mix(live, clamp(amber, 0.0, 1.0), grade);

    // Native-resolution texels and a complete grade/overlay release make the
    // final image identical to the captured game framebuffer, including edges.
    if (descent >= 0.98) {
        ivec2 size = textureSize(liveTex, 0);
        live = texelFetch(liveTex,
            clamp(ivec2(uv * vec2(size)), ivec2(0), size - 1), 0).rgb;
        // Even mix(a,b,1) may round on a driver. Bypass every color operation
        // once the artwork is gone, including stale cached cloud opacity.
        if (hasLive != 0 && (hasArtwork == 0 || fade >= 1.0)) {
            gl_FragColor = vec4(live, 1.0);
            return;
        }
    }
    float reveal = smoothstep(0.43, 0.98, descent) * (1.0 - orbit.a) * float(hasLive);
    // A 12 Hz cloud cache can trail this display-rate frame. Release its last
    // residual alpha too, so .98..1 remains exact even between cloud refreshes.
    if (descent >= 0.98) reveal = float(hasLive);
    vec3 scene = mix(orbit.rgb, live, reveal);
    // File-backed artwork follows image-top-left orientation; FBOs do not.
    if (hasArtwork != 0 && fade < 1.0) {
        vec2 artUV = (uv - 0.5) * artScale + 0.5;
        vec3 art = texture2D(artworkTex, vec2(artUV.x, 1.0 - artUV.y)).rgb;
        scene = mix(art, scene, fade);
    }
    gl_FragColor = vec4(scene, 1.0);
}
