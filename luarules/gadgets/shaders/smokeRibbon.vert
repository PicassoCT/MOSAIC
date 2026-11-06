#version 150 compatibility
uniform vec3 origin, direction, cameraPosition;
uniform vec3 directionalDrift;
uniform float effectTime, plumeLength, plumeWidth, curl, seed;
uniform float hairMode, electricMode, stiffness, gravity, strandCount;
uniform float landingMode; // 0: ordinary plume, 1: landing jet, 2: deck-only fan
uniform vec4 landingPad; // deck centre XZ, surface Y, contact radius; negative disables
uniform vec4 terrainBandNear, terrainBandFar; // maximum sampled surface height in each 1/8 of a ribbon
uniform float terrainPad; // nonzero only for ground-guarded combat flames
out vec2 ribbonUV;
out float ribbonSeed;

// The cloud and its attached charge use one material curve, clock and seed.
// Narrow roots rise above the passenger, then open into a diffuse, rolling crown.
vec3 canopyCentre(float t, float strand, vec3 u, vec3 v) {
    float s = seed + strand * 2.399963;
    float count = max(strandCount,1.0);
    vec3 axis = vec3(0,1,0);
    vec3 radial = vec3(direction.x,0,direction.z);
    if (dot(radial,radial) < 1e-8) radial = vec3(1,0,0);
    radial = normalize(radial);
    vec3 around = cross(axis,radial);
    vec3 p = origin + around*plumeWidth*0.035*((strand+0.5)/count-0.5);
    float lockLength = plumeLength*(0.90+0.10*sin(s)*sin(s));
    float airflow = min(1.0,length(directionalDrift)/max(plumeLength,0.001));
    float gust = 1.0+airflow*0.16*sin(effectTime*1.4+s*0.13);
    // Common slow billow keeps the cloud coherent; individual folds lag it.
    vec3 billow = vec3(sin(effectTime*0.43),0,sin(effectTime*0.31+1.4))*0.12;
    for (int i=0; i<12; ++i) {
        float q = t*(float(i)+0.5)/12.0;
        float flex = (1.0-stiffness)*smoothstep(0.06,0.95,q);
        float reach = mix(0.10,1.35,smoothstep(0.08,0.86,q))
            * (0.78+0.22*sin(seed*0.37)*sin(seed*0.37));
        float lift = mix(1.55,0.22,smoothstep(0.30,1.0,q));
        float travel = effectTime*0.65;
        float wave = 0.48*sin(q*6.0-travel+s*0.23)
            + 0.12*sin(q*14.0-travel*1.37+s);
        float crossWave = 0.36*sin(q*7.5-travel*0.79+s*0.31)
            + 0.09*sin(q*17.0-travel*1.61+s);
        float flutter = 0.72+0.28*airflow;
        vec3 bend = axis*(lift-gravity*q*0.25)+radial*reach
            + directionalDrift/max(plumeLength,0.001)*flex*gust
            + (billow+(radial*wave+around*crossWave)*curl*flutter)*flex;
        // Wind can spread and curl the crown without inverting it onto its owner.
        bend.y = max(0.10,bend.y);
        p += normalize(bend)*(lockLength*t/12.0);
    }
    return p;
}

// Analytic, advecting vortex paths: no particle buffers or integration passes.
vec3 centre(float t, float strand, vec3 u, vec3 v) {
    if (hairMode > 1.5) {
        if (electricMode > 1.5) {
            // Charge crawls on the actual moving material before lifting away.
            // Its first 72% coincides exactly with material coordinates .48-.84.
            if (t <= 0.72) return canopyCentre(mix(0.48,0.84,t/0.72),strand,u,v);
            vec3 tip = canopyCentre(0.84,strand,u,v);
            vec3 tangent = normalize(tip-canopyCentre(0.80,strand,u,v));
            float q = (t-0.72)/0.28;
            float s = seed+strand*2.399963;
            float tail = plumeLength*(0.18+0.05*sin(s)*sin(s));
            vec3 curlOffset = u*sin(q*8.0-effectTime*1.7+s)
                + v*sin(q*6.0-effectTime*1.2+s*0.7)*0.5;
            return tip + tangent*(tail*q*(1.0-q)*(1.0-q))
                + vec3(0,tail*q*q,0)
                + curlOffset*(plumeWidth*0.055*sin(q*3.14159265)*q);
        }
        return canopyCentre(t,strand,u,v);
    }
    if (hairMode > 0.5) {
        // Fixed arc length: integrate short unit tangents; roots never advect.
        float s = seed + strand * 2.399963;
        float count = max(strandCount,1.0);
        float rootRadius = plumeWidth * 0.22 * sqrt((strand+0.5)/count);
        vec3 p = origin + rootRadius*(u*cos(s)+v*sin(s));
        float lockLength = plumeLength * (0.88+0.12*sin(s)*sin(s));
        float airflow = min(1.0,length(directionalDrift)/max(plumeLength,0.001));
        float gust = 1.0 + airflow*(0.18*sin(effectTime*1.7+s*0.13)
            + 0.1*sin(effectTime*3.1+s*0.07));
        for (int i=0; i<12; ++i) {
            float q = t * (float(i)+0.5)/12.0;
            float flex = (1.0-stiffness)*q*q;
            float wave = 0.25*sin(q*3.0+s)
                + airflow*sin(effectTime*2.1 + q*3.0 + s);
            float crossWave = 0.25*sin(q*4.0+s)
                + airflow*sin(effectTime*1.3+q*4.0+s);
            vec3 bend = direction + vec3(0,-gravity*q,0)
                + directionalDrift/max(plumeLength,0.001)*flex*gust
                + (u*wave+v*crossWave)*curl*flex;
            p += normalize(bend) * (lockLength*t/12.0);
        }
        return p;
    }
    float s = seed + strand * 2.399963;
    if (electricMode > 0.5) {
        // Split each discharge into rising three-dimensional filaments. The
        // fan is geometric, so it remains readable when viewed from above.
        float angle = seed * 0.23 + strand * 6.2831853 / max(strandCount,1.0);
        vec3 radial = u*cos(angle) + v*sin(angle);
        vec3 crossRadial = -u*sin(angle) + v*cos(angle);
        float phase = t*18.0 - effectTime*2.0 + s;
        float envelope = sin(t*2.67);
        float fan = plumeLength * (0.10+0.04*sin(s)*sin(s)) * t;
        float wave = sin(phase) + 0.28*sin(phase*2.7+s);
        float crossWave = sin(phase*0.73+s) + 0.22*sin(phase*3.1);
        float radius = plumeWidth*curl*envelope;
        return origin + direction*(t*plumeLength*(0.9+0.1*cos(s)*cos(s)))
            + radial*(fan+radius*wave) + crossRadial*radius*crossWave*0.55
            + directionalDrift*(t*t);
    }
    float phase = t * 14.0 - effectTime * 1.7 + s;
    float envelope = t * t * (3.0 - 2.0 * t);
    float radius = plumeWidth * curl * envelope;
    float bend = sin(t * 5.0 - effectTime * 0.43 + seed);
    float p = phase + 0.85 * sin(phase * 0.61 + s);
    vec2 coil = vec2(sin(p), cos(p * 0.91 + s)) * (0.55 + 0.25 * sin(phase * 0.47));
    coil += vec2(bend, sin(t * 7.0 - effectTime * 0.57 + s)) * 0.45;
    if (landingMode > 0.5) {
        // Downward core with separated return-flow lobes curling up around it.
        // Four fixed fan directions remain stable while the wisps advect.
        float angle = seed + strand * 6.2831853 / max(strandCount,1.0);
        vec3 radial = vec3(cos(angle),0,sin(angle));
        float q = smoothstep(0.28,1.0,t);
        vec3 flow = vec3(0,-t*plumeLength,0)
            + radial*(plumeLength*0.28*q)
            + vec3(0,plumeLength*1.75*q*q,0);
        bool overPad = landingPad.w > 0.0 && distance(origin.xz,landingPad.xz) < landingPad.w;
        if (overPad) {
            float gap = max(0.0,origin.y-landingPad.y);
            float contact = 1.0-smoothstep(plumeLength*0.3,plumeLength*0.55,gap);
            float hit = clamp(gap/plumeLength,0.01,0.55);
            bool padOnly = landingMode > 1.5;
            float spread = padOnly ? t : max(0.0,(t-hit)/(1.0-hit));
            // Pad reach is 32% of the original 0.9; retain the core and flight curl.
            vec3 fan = vec3(0,-(padOnly ? gap : min(t*plumeLength,gap)),0)
                + radial*(plumeLength*0.288*spread)
                + vec3(0,plumeLength*0.2*spread*spread,0);
            flow = padOnly ? fan : mix(flow,fan,contact);
        }
        vec3 point = origin + flow + radius*(u*coil.x+v*coil.y) + directionalDrift*(t*t);
        if (overPad) point.y = max(point.y,landingPad.y);
        return point;
    }
    // Axial modulation folds the upper wisps as they roll away from the source.
    float axial = t * plumeLength + radius * 0.4 * sin(p + 0.7);
    return origin + direction * axial + radius * (u * coil.x + v * coil.y)
        + directionalDrift * (t*t);
}
void main() {
    float t = gl_Vertex.x;
    float side = gl_Vertex.y;
    float strand = gl_Vertex.z;
    vec3 helper = abs(direction.y) < 0.9 ? vec3(0,1,0) : vec3(1,0,0);
    vec3 u = normalize(cross(direction, helper));
    vec3 v = cross(direction, u);
    vec3 p = centre(t, strand, u, v);
    vec3 tangent = direction;
    if (hairMode < 1.5) {
        tangent = centre(min(1.0,t+0.005),strand,u,v) - centre(max(0.0,t-0.005),strand,u,v);
    }
    if (dot(tangent,tangent) < 1e-10) tangent = direction;
    tangent = normalize(tangent);
    vec3 across = cross(tangent, cameraPosition-p);
    if (hairMode > 1.5) {
        // A broad veil needs a stable facing plane. Following every local
        // tangent can flip its sides near an inflection and draw black spikes.
        across = cross(direction, cameraPosition-origin);
    }
    if (dot(across,across) < 1e-8) across = cross(tangent,helper);
    if (dot(across,across) < 1e-8) across = cross(tangent,vec3(0,0,1));
    across = normalize(across);
    float spread = (0.035 + 0.55 * pow(t,0.8)) * smoothstep(0.0,0.025,t);
    float breath = 0.8 + 0.2 * sin(t*17.0-effectTime*1.7+seed+strand);
    if (hairMode > 0.5) {
        // Several narrow locks with soft, staggered ends, not one triangular card.
        spread = 0.5/max(strandCount,1.0) * (1.0-smoothstep(0.55,1.0,t));
        breath = 1.0;
        if (hairMode > 1.5) {
            // Keep the blurred cloud: narrow suspension roots open into soft
            // overlapping veils. Fine fibres remain in the opacity field.
            spread = (0.035+0.58*smoothstep(0.06,0.62,t))
                * (1.0-0.40*smoothstep(0.78,1.0,t))/sqrt(max(strandCount,1.0));
            breath = 0.86+0.14*sin(t*11.0-effectTime*0.95+seed+strand);
            if (electricMode > 1.5) {
                // A small part of that veil carries charge; its centre remains
                // attached even while the surrounding cloud rolls in the wind.
                spread = 0.07*(1.0-smoothstep(0.82,1.0,t));
                breath = 1.0;
            }
        }
    } else if (electricMode > 0.5) {
        // A narrow core plus halo, never the expanding triangular smoke card.
        spread = 0.30 * smoothstep(0.0,0.018,t) * (1.0-smoothstep(0.78,1.0,t));
        breath = 0.92 + 0.08*sin(t*23.0-effectTime*3.0+seed+strand);
    }
    p += across * side * plumeWidth * spread * breath;
    if (terrainPad > 0.0) {
        // The eight ceiling bands are sampled across the flame's width too.
        // Clamp AFTER curl and billboard expansion, so the entire ribbon
        // remains above curbs, ridges and inclined pavement.
        int segment = int(floor(min(0.999999, max(0.0, t)) * 8.0));
        float surface = segment < 4
            ? terrainBandNear[segment] : terrainBandFar[segment-4];
        p.y = max(p.y, surface + terrainPad);
    }
    if (landingMode > 0.5 && landingPad.w > 0.0 && distance(origin.xz,landingPad.xz) < landingPad.w) {
        // Camera-facing width must not push vertices through the raised deck.
        p.y = max(p.y,landingPad.y + plumeWidth*0.01);
    }
    ribbonUV = vec2(side,t);
    ribbonSeed = seed + strand * 2.399963;
    gl_Position = gl_ModelViewProjectionMatrix * vec4(p,1.0);
}
