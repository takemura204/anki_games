#version 460 core
#include <flutter/runtime_effect.glsl>

// Glacier Ice ASMR: crystal facets + vivid caustics + deep blue SSS + dense bubbles
// Like a thick glacier ice block — Voronoi crystal faces with sharp specular (power 56),
// vivid flowing cyan caustic light, deep interior SSS blue glow, dense air bubble
// inclusions with bright Fresnel rims, and frost dendrites at edges

uniform vec2 uSize;
uniform vec2 uOrigin;
uniform float uTime;
uniform vec4 uBase;   // blue-grey #607D8B
uniform vec4 uGlow;   // light cyan #B2EBF2
uniform float uOpacity;

out vec4 fragColor;

float hash(vec2 p) {
  return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453);
}

vec2 hash2(vec2 p) {
  p = fract(p * vec2(0.1031, 0.1030));
  p += dot(p, p.yx + 33.33);
  return fract((p.x + p.y) * p);
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
    p = p * 2.0 + vec2(1.7, 9.2);
    a *= 0.50;
  }
  return h;
}

// Voronoi: returns (dist_to_nearest_site, vector_to_nearest_site)
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

void main() {
  vec2 uv = (FlutterFragCoord().xy - uOrigin) / uSize;

  // Slightly faster drift for glacier dynamism
  vec2 drift = vec2(uTime * 0.050, uTime * 0.032);

  vec2 sway = vec2(
    sin(uTime * 0.52 + uv.y * 4.1) * 0.032,
    cos(uTime * 0.44 + uv.x * 3.7) * 0.024
  );

  vec2 q = vec2(
    fbm3(uv * 2.1 + drift + sway),
    fbm3(uv * 2.1 + drift + sway + vec2(5.1, 1.7))
  );

  // Height field for swaying surface normals
  float eps = 0.012;
  vec2 wp = uv * 2.5 + 2.2 * q + drift * 0.8;
  float hC = fbm3(wp);
  float hR = fbm3(wp + vec2(eps * 1.8, 0.0));
  float hU = fbm3(wp + vec2(0.0, eps * 1.8));

  float nx = (hC - hR) * 7.5;
  float ny = (hC - hU) * 7.5;
  // Lower z → sharper bumps → more vivid specular on glacier surface
  vec3 normal = normalize(vec3(nx, ny, 0.05));

  vec3 lightDir = normalize(vec3(-0.55, -0.65, 1.0));
  float ndotl = max(0.0, dot(normal, lightDir));
  // Strengthened specular: power 56 (pristine glacier ice)
  float spec = pow(ndotl, 56.0) * 1.80;

  vec3 fillDir = normalize(vec3(0.4, -0.3, 1.0));
  float fillLight = max(0.0, dot(normal, fillDir)) * 0.28;

  // --- Voronoi crystal facets (ice crystal structure) ---
  vec3 facetData = voronoiData(uv * 3.5 + vec2(2.7, 1.4));
  vec2 facetNormal2D = -normalize(facetData.yz + vec2(0.0001));
  float facetLight = 0.5 + 0.5 * dot(facetNormal2D, normalize(vec2(-0.55, -0.65)));
  // Sharper facet edges for crisper crystal definition
  float facetEdge = smoothstep(0.08, 0.014, facetData.x) * 0.34;
  float facetBright = facetLight * 0.18;

  // --- Vivid caustics (strengthened: faster, broader, more intense) ---
  vec2 cauUV = uv * 4.8 + q * 1.2 + drift * 2.0;
  float wave = fbm3(cauUV + vec2(uTime * 0.085, uTime * 0.065));
  // pow 6 for sharper, more vivid caustic interference bands (was pow 5)
  float caustic = pow(abs(cos(wave * 3.14159 * 3.0)), 6.0);

  float edgeX = min(uv.x, 1.0 - uv.x);
  float edgeY = min(uv.y, 1.0 - uv.y);
  float edgeDist = min(edgeX, edgeY);
  float innerMask = smoothstep(0.0, 0.18, edgeDist);
  caustic *= innerMask;

  // --- Frost dendrite pattern at edges ---
  float frostA = fbm3(uv * 9.0 + vec2(7.3, 2.1));
  float frostB = fbm3(uv * 17.0 + vec2(1.5, 5.8));
  float frostPattern = frostA * 0.6 + frostB * 0.4;
  float frostEdgeMask = smoothstep(0.22, 0.0, edgeDist);
  float frost = frostPattern * frostEdgeMask;

  // --- Dense air bubbles (scale 10: more inclusions like glacier ice, was scale 7) ---
  vec3 bubbleData = voronoiData(uv * 10.0 + vec2(4.2, 3.1));
  float bubbleR = 0.22;
  float bubbleRim = (smoothstep(bubbleR, bubbleR * 0.70, bubbleData.x)
                   - smoothstep(bubbleR * 0.70, bubbleR * 0.38, bubbleData.x));
  bubbleRim = clamp(bubbleRim, 0.0, 1.0) * 0.34;
  float bubbleInner = smoothstep(bubbleR * 0.70, bubbleR * 0.32, bubbleData.x) * 0.09;

  // --- Fresnel edge glow ---
  float edgeGlow = 1.0 - smoothstep(0.0, 0.13, edgeDist);
  edgeGlow = edgeGlow * edgeGlow * 1.4;

  // Corner accents
  float cornerTL = smoothstep(0.20, 0.0, length(uv - vec2(0.0, 0.0))) * 1.3;
  float cornerTR = smoothstep(0.12, 0.0, length(uv - vec2(1.0, 0.0))) * 0.8;

  // --- Deep interior SSS (glacier ice glows deep blue-white from within) ---
  float distToCenter = length(uv - 0.5) * 2.0;
  float sssDeep = smoothstep(1.0, 0.0, distToCenter) * 0.50;
  // Center: deep blue; transitioning outward to cyan-white
  vec3 sssDeepColor = mix(
    vec3(0.42, 0.78, 1.0),
    vec3(0.82, 0.97, 1.0),
    sssDeep * 0.6
  );

  // --- Color composition ---
  vec3 glassCool   = mix(uBase.rgb, vec3(0.72, 0.82, 0.90), 0.68);
  vec3 glassBright = mix(uGlow.rgb, vec3(0.90, 0.96, 1.00), 0.55);

  float reflBright = ndotl * 0.65 + fillLight + hC * 0.12 + facetBright;
  vec3 reflected = mix(glassCool * 0.55, glassBright, reflBright);

  // Vivid caustic: deep cyan-blue → cyan → pure white at peak
  vec3 causticCold = mix(vec3(0.48, 0.85, 1.0), vec3(0.82, 0.97, 1.0), caustic);
  vec3 causticColor = mix(causticCold, vec3(1.0, 1.0, 1.0), caustic * caustic);

  vec3 color = mix(reflected, causticColor, caustic * 0.78);

  // Deep blue SSS from glacier interior
  color = mix(color, sssDeepColor, sssDeep * 0.38);

  // Crystal facet edges (bright white lines between facets)
  color += vec3(facetEdge);

  // Sharp specular highlight
  color += vec3(spec);

  // Frost overlay at edges (white-blue crystalline film)
  color = mix(color, vec3(0.88, 0.94, 1.0), frost * 0.54);

  // Air bubble rims (bright) and darkened interiors
  color += vec3(bubbleRim);
  color -= vec3(bubbleInner);

  // Bright white edge glow
  color = mix(color, vec3(1.0), clamp(edgeGlow * 0.90, 0.0, 1.0));

  // Corner highlights
  color = mix(color, vec3(1.0), clamp(cornerTL * 0.94, 0.0, 1.0));
  color = mix(color, vec3(1.0), clamp(cornerTR * 0.75, 0.0, 1.0));

  // Glacier-blue overall tint (thick ice absorbs warm wavelengths)
  vec3 glacierTint = mix(uBase.rgb, vec3(0.38, 0.72, 1.0), 0.55);
  color = mix(color, glacierTint, 0.08);

  color = clamp(color, 0.0, 1.0);

  // Alpha: caustic/spec/sss boost opacity at bright areas
  float alpha = uOpacity * (
    0.70 + spec * 0.20 + edgeGlow * 0.12
    + caustic * 0.10 + frost * 0.06 + sssDeep * 0.04
  );
  alpha = clamp(alpha, 0.0, 1.0);

  fragColor = vec4(color, alpha);
}
