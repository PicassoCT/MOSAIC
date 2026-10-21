#version 150 compatibility
uniform sampler2D orbitTex;
uniform sampler2D artworkTex;
uniform sampler2D liveTex;
uniform float descent; // cloud/reveal phase only; planetary snapshots keep this at zero
uniform float fade;
uniform int hasArtwork;
uniform int hasLive;
uniform vec2 artScale;
// Screen-space projection only: no table geometry, camera change, extra render
// target or access to live-map pixels. Both images share this temporary plane.
float tileNoise(vec2 cell, uint salt) {
    uvec2 c = uvec2(ivec2(cell));
    uint h = c.x * 374761393u + c.y * 668265263u + salt * 2246822519u;
    h = (h ^ (h >> 13u)) * 1274126177u;
    return float(h ^ (h >> 16u)) * (1.0 / 4294967295.0);
}
vec3 loadingArt(vec2 uv) {
    vec2 q = (uv - 0.5) * artScale + 0.5;
    return texture2D(artworkTex, vec2(q.x, 1.0 - q.y)).rgb;
}
vec3 holotableBlend(vec2 uv, float t) {
    // Zero outside the handover. The uniform branch in main bypasses this
    // entire function at both endpoints and throughout the accepted zoom.
    float projection = smoothstep(0.0, 0.18, t)
        * (1.0 - smoothstep(0.58, 1.0, t));
    float hologram = smoothstep(0.0, 0.12, t)
        * (1.0 - smoothstep(0.66, 0.98, t));
    vec2 pixels = vec2(textureSize(orbitTex, 0));
    float aspect = pixels.x / max(pixels.y, 1.0);

    // Inverse of a gently tilted plane: its far edge is narrower, with a
    // small diagonal shear. Recover identity continuously, never a 180 flip.
    vec2 p = (uv - 0.5) * 2.0;
    float tilt = 0.13 * projection;
    float py = p.y + 0.015 * projection;
    float y = py / (1.0 - 0.20 * projection - tilt * py);
    float x = (p.x * (1.0 + tilt * y) - 0.045 * projection * y)
        / (1.0 - 0.12 * projection);
    vec2 plane = vec2(x, y) * 0.5 + 0.5;
    vec2 edge = min(plane, 1.0 - plane);
    vec2 pixel = max(fwidth(plane), vec2(0.00001));
    float distance = min(edge.x / pixel.x, edge.y / pixel.y);
    float inside = smoothstep(-0.5, 0.5, distance);
    vec2 q = clamp(plane, vec2(0.0), vec2(1.0));

    // Mixed-size tiles. Every two-by-two cell group makes one stable decision
    // to merge, so neighboring fragments never disagree about their boundary.
    vec2 grid = vec2(2.0 * floor(7.0 * aspect + 0.5), 14.0);
    vec2 group = floor(q * grid * 0.5);
    grid *= tileNoise(group, 5u) > 0.55 ? 0.5 : 1.0;
    vec2 tile = floor(q * grid);
    float seed = tileNoise(tile, uint(grid.y));
    float survivor = step(0.82, seed);
    float release = mix(0.19 + 0.32 * seed + 0.12 * q.x,
                        0.70 + 0.11 * tileNoise(tile, 41u), survivor);
    float oldImage = 1.0 - smoothstep(release, release + 0.07, t);
    float breakup = smoothstep(release - 0.12, release - 0.025, t)
        * (1.0 - smoothstep(release + 0.025, release + 0.07, t));
    // Flicker is local and shallow; no full-frame white flashes or strobing.
    float tick = floor(t * 28.0);
    float signal = tileNoise(tile + vec2(tick * 3.0, tick), 73u);
    float dropout = breakup * (0.10 + 0.24 * step(0.79, signal));
    float slip = (signal - 0.5) * 0.005 * breakup * hologram;
    vec2 source = clamp(q + vec2(slip, 0.0), vec2(0.0), vec2(1.0));
    vec3 art = loadingArt(source) * (1.0 - dropout);
    vec3 satellite = texture2D(orbitTex, q).rgb;
    // Incoming data lights up on the same surface underneath the last old
    // fragments. Their late release supplies the requested stay-behind tiles.
    vec3 picture = mix(satellite, art, oldImage);
    float luma = dot(picture, vec3(0.299, 0.587, 0.114));
    vec3 phosphor = mix(picture * vec3(0.38, 1.02, 1.05),
                        luma * vec3(0.11, 0.90, 0.94), 0.48);
    float scan = 0.95 + 0.05 * sin(q.y * pixels.y * 3.14159265);
    picture = mix(picture, phosphor * scan, hologram * 0.88);

    vec2 cellEdge = min(fract(q * grid), 1.0 - fract(q * grid));
    vec2 cellPixel = max(fwidth(q * grid), vec2(0.0001));
    float tileLine = 1.0 - smoothstep(0.4, 1.6,
        min(cellEdge.x / cellPixel.x, cellEdge.y / cellPixel.y));
    float sweep = exp(-abs(q.y - (1.12 - t * 1.42)) * 90.0);
    float tileLight = (0.025 + oldImage * 0.035 + breakup * 0.16) * tileLine;
    picture += vec3(0.10, 0.72, 0.76) * hologram * (tileLight + sweep * 0.15);

    // A thin luminous frame and its soft halo imply a projection plate. No
    // permanent cockpit, room or border is introduced around either endpoint.
    float rim = exp(-abs(distance - 1.2) * 0.60);
    float glow = exp(-abs(distance) * 0.08);
    vec3 surround = vec3(0.002, 0.006, 0.009);
    surround += vec3(0.012, 0.060, 0.066) * glow * hologram;
    vec3 result = mix(surround, picture, inside);
    result += vec3(0.22, 0.87, 0.89) * hologram * (rim * 0.48 + glow * 0.06);
    return clamp(result, 0.0, 1.0);
}

void main() {
    vec2 uv = gl_TexCoord[0].st;
    // Strictly transition-only; keep all accepted zoom/reveal code below intact.
    if (hasArtwork != 0 && descent <= 0.0 && fade > 0.0 && fade < 1.0) {
        gl_FragColor = vec4(holotableBlend(uv, fade), 1.0);
        return;
    }
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
