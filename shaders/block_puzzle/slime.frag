#version 460 core
#include <flutter/runtime_effect.glsl>

// Bubble Gel Slime ASMR: physics-based Phong + visible bubbles + vivid green
// Thick wet slime with dynamic light-reactive highlights computed from FBM surface normals,
// medium-size visible air bubbles, prominent internal flow streaks, and rim SSS

uniform vec2 uSize;
uniform vec2 uOrigin;
uniform float uTime;
uniform vec4 uBase;     // green #43A047
uniform vec4 uGlow;     // mint #A5D6A7
uniform float uOpacity;

out vec4 fragColor;

vec2 hash2(vec2 p) {
  p = fract(p * vec2(0.1031, 0.1030));
  p += dot(p, p.yx + 33.33);
  return fract((p.x + p.y) * p);
}

float hash(vec2 p) {
  return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453);
}

float vnoise(vec2 p) {
  vec2 i = floor(p);
  vec2 f = fract(p);
  f = f * f * (3.0 - 2.0 * f);
  float a = hash(i);
  float b = hash(i + vec2(1.0, 0.0));
  float c = hash(i + vec2(0.0, 1.0));
  float d = hash(i + vec2(1.0, 1.0));
  return mix(mix(a, b, f.x), mix(c, d, f.x), f.y);
}

float fbm3(vec2 p) {
  float h = 0.0, a = 0.5;
  for (int i = 0; i < 3; i++) {
    h += a * vnoise(p);
    p = p * 2.1 + vec2(1.7, 9.2);
    a *= 0.52;
  }
  return h;
}

vec3 voronoiData(vec2 p) {
  vec2 i = floor(p);
  vec2 f = fract(p);
  float minD = 8.0;
  vec2 minR = vec2(0.0);
  for (int dy = -1; dy <= 1; dy++) {
    for (int dx = -1; dx <= 1; dx++) {
      vec2 nb = vec2(float(dx), float(dy));
      vec2 site = hash2(i + nb) * 0.72 + 0.14;
      vec2 r = f - (nb + site);
      float d = length(r);
      if (d < minD) {
        minD = d;
        minR = r;
      }
    }
  }
  return vec3(minD, minR);
}

// Micro-bubble: Voronoi-based sub-pixel glistening sparkle
float microBubble(vec2 uv, float scale, float speed, float seed) {
  vec2 dv = vec2(
    sin(uTime * speed * 0.4 + seed + uv.y * 4.0) * 0.010,
    -uTime * speed * 0.025
  );
  vec3 data = voronoiData((uv + dv) * scale);
  float d = data.x;
  vec2 r = data.yz;
  float rimR = 0.28;
  float inside = step(d, rimR);
  vec2 rn = r / (d + 0.001);
  float hlDir = clamp(-rn.x * 0.50 - rn.y * 0.85, 0.0, 1.0);
  float hlR   = smoothstep(rimR * 0.90, rimR * 0.20, d);
  return hlDir * hlDir * hlR * inside;
}

// Visible medium bubble: 2–4px ring with directional highlight (scale 5–9)
float mediumBubble(vec2 uv, float scale, float speed, float seed) {
  vec2 dv = vec2(
    sin(uTime * speed * 0.5 + seed + uv.y * 2.5) * 0.018,
    -uTime * speed * 0.012
  );
  vec3 data = voronoiData((uv + dv) * scale);
  float d = data.x;
  float bR = 0.32;
  // Ring: bright rim, transparent interior
  float rimO = smoothstep(bR, bR * 0.74, d);
  float rimI = smoothstep(bR * 0.74, bR * 0.46, d);
  float ring = clamp(rimO - rimI, 0.0, 1.0) * 0.55;
  // Upper-left directional highlight on bubble rim
  vec2 rn = normalize(data.yz + vec2(0.0001));
  float hlDir = clamp(-rn.x * 0.45 - rn.y * 0.80, 0.0, 1.0);
  float hlInner = smoothstep(bR * 0.74, bR * 0.28, d);
  float hl = hlDir * hlDir * hlInner * 0.70;
  return clamp(ring + hl, 0.0, 1.0);
}

// Glitter sparkle: scattered bright points twinkling with time
float glitterSparkle(vec2 uv, float scale, vec2 seedOffset) {
  vec2 cell  = floor(uv * scale);
  vec2 local = fract(uv * scale);
  float phase  = hash(cell + seedOffset) * 6.28318;
  float twinkle = pow(0.5 + 0.5 * sin(uTime * 4.0 + phase), 4.0);
  vec2 gPos = hash2(cell + seedOffset + vec2(1.3, 2.1)) * 0.65 + 0.175;
  float d = length(local - gPos);
  return smoothstep(0.09, 0.0, d) * twinkle;
}

void main() {
  vec2 uv = (FlutterFragCoord().xy - uOrigin) / uSize;

  // --- Main liquid flow: domain-warped FBM for thick slime internal movement ---
  vec2 t = vec2(uTime * 0.060, uTime * 0.045);
  vec2 q = vec2(
    fbm3(uv * 2.2 + t),
    fbm3(uv * 2.2 + t + vec2(5.2, 1.3))
  );
  float flow = fbm3(uv * 2.8 + 1.8 * q + t * 0.4);
  float flowMod = (flow - 0.5) * 0.36; // ±0.18 luminance streaks

  // --- Physics-based surface normals from FBM height field ---
  // Slightly different FBM phase so normal bumps differ from color flow
  vec2 nT = vec2(uTime * 0.058, uTime * 0.040);
  vec2 nUV = uv * 3.2;
  float eps = 0.025;
  float hC = fbm3(nUV + nT);
  float hR = fbm3(nUV + vec2(eps * 3.2, 0.0) + nT);
  float hU = fbm3(nUV + vec2(0.0, eps * 3.2) + nT);
  float dnx = (hC - hR) * 4.2;
  float dny = (hC - hU) * 4.2;
  // z=0.35 keeps the surface mostly upright while allowing visible bumpiness
  vec3 surfNorm = normalize(vec3(dnx, dny, 0.35));

  // --- Physics-based Phong lighting ---
  vec3 lightDir = normalize(vec3(-0.55, -0.72, 1.0));
  float ndotl   = max(0.0, dot(surfNorm, lightDir));
  vec3 viewDir  = vec3(0.0, 0.0, 1.0);
  vec3 reflDir  = reflect(-lightDir, surfNorm);
  float NdotR   = max(0.0, dot(reflDir, viewDir));
  // Sharp gloss highlight (wet slime: power 48)
  float specPhong = pow(NdotR, 48.0) * 1.25;
  // Soft secondary lobe (broad wet sheen)
  float specSoft = pow(NdotR, 10.0) * 0.20;

  // --- Center SSS: deep chewy glow from inside ---
  float dist = length(uv - 0.5) * 2.0;
  float sssCenter = smoothstep(1.0, 0.0, dist) * 0.55;

  // --- Rim SSS: light entering from all edges ---
  float edgeX = min(uv.x, 1.0 - uv.x);
  float edgeY = min(uv.y, 1.0 - uv.y);
  float sssRim = smoothstep(0.28, 0.0, min(edgeX, edgeY)) * 0.48;

  // --- Color: vivid saturated green with diffuse variation ---
  vec3 baseGreen = mix(uBase.rgb, vec3(0.18, 0.88, 0.05), 0.65);
  float diffuse = 0.80 + ndotl * 0.22; // subtle directional shading
  vec3 liquidColor = baseGreen * diffuse * (1.0 + flowMod);
  // Center SSS → mint
  vec3 color = mix(liquidColor, uGlow.rgb * 1.65, sssCenter);
  // Rim SSS → bright lime-yellow
  vec3 rimSSS = mix(uGlow.rgb, vec3(0.75, 1.0, 0.35), 0.55);
  color = mix(color, rimSSS, sssRim);

  // --- Medium visible bubbles (2–4px ring + highlight) ---
  float mb1 = mediumBubble(uv, 6.0, 0.035, 0.00);
  float mb2 = mediumBubble(uv, 8.5, 0.028, 5.13);
  float mbMix = clamp(mb1 + mb2 * 0.75, 0.0, 1.0);
  // Bubbles appear as light-green-tinted rings
  color = mix(color, vec3(0.88, 1.0, 0.82) * 1.15, mbMix * 0.42);

  // --- Micro-bubble sparkle (scale 22/30: sub-pixel glistening) ---
  float hl1 = microBubble(uv, 22.0, 0.06, 0.0);
  float hl2 = microBubble(uv, 30.0, 0.09, 4.7);
  color = mix(color, vec3(1.0, 1.0, 0.97), clamp(hl1 * 0.88 + hl2 * 0.72, 0.0, 1.0));

  // --- Glitter sparkles: gold/white twinkling particles ---
  float gl1 = glitterSparkle(uv, 7.0, vec2(0.00, 0.00));
  float gl2 = glitterSparkle(uv, 10.0, vec2(2.71, 1.41));
  float gl3 = glitterSparkle(uv, 5.0, vec2(1.73, 3.14));
  float glitMix = clamp(gl1 * 1.0 + gl2 * 0.8 + gl3 * 1.2, 0.0, 1.0);
  vec3 glitColor = mix(vec3(1.0, 0.88, 0.55), vec3(1.0, 1.0, 1.0), glitMix * 0.5);
  color = mix(color, glitColor, glitMix * 0.85);

  // --- Physics-based dynamic specular (moves with surface bumps) ---
  color = mix(color, vec3(1.0), specPhong * 0.90);
  color += vec3(specSoft) * 0.55;

  // --- Guaranteed wet-surface highlight: small static hotspot (upper-left) ---
  // Ensures there's always a "wet look" reference point even when dynamic spec is dim
  float d1 = length(uv - vec2(0.22, 0.18));
  color = mix(color, vec3(1.0), smoothstep(0.05, 0.0, d1) * 0.55);

  // --- Top wet sheen: horizontal highlight band near top edge ---
  float topSheen = smoothstep(0.14, 0.0, uv.y)
                 * clamp(1.0 - abs(uv.x - 0.5) * 2.2, 0.0, 1.0)
                 * 0.12;
  color += vec3(topSheen);

  color = clamp(color, 0.0, 1.0);
  fragColor = vec4(color, 0.95 * uOpacity);
}
