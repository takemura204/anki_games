#version 460 core
#include <flutter/runtime_effect.glsl>

// Polished Black Granite: mineral crystal flecks + animated Phong specular + bevel edge
// ASMR: light slowly drifts across polished stone surface

uniform vec2 uSize;     // [0,1]  cell dimensions
uniform vec2 uOrigin;   // [2,3]  cell top-left in canvas coords
uniform float uTime;    // [4]    animation time in seconds
uniform vec4 uBase;     // [5-8]  onSurface (pure black #000000)
uniform vec4 uGlow;     // [9-12] glowColor (#1A1A1A, slightly lighter)
uniform float uOpacity; // [13]   overall opacity

out vec4 fragColor;

float hash(vec2 p) {
  p = fract(p * vec2(127.1, 311.7));
  p += dot(p, p.yx + 19.19);
  return fract(p.x * p.y);
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

void main() {
  vec2 uv = (FlutterFragCoord().xy - uOrigin) / uSize;
  vec2 fragPx = FlutterFragCoord().xy;

  // --- Base gradient: glowColor (top) → pure black (bottom) ---
  vec3 baseColor = mix(uGlow.rgb, uBase.rgb, uv.y);

  // --- Mineral crystal texture ---
  // Coarse quartz crystals (sparse bright flecks)
  float n1 = vnoise(fragPx * 0.18);
  // Fine mica shimmer (higher frequency, mirror-like flecks)
  float n2 = vnoise(fragPx * 0.52 + vec2(7.3, 3.1));
  // Micro-surface grain
  float n3 = (hash(fragPx * 0.35) - 0.5) * 0.015;

  float crystal = smoothstep(0.80, 0.96, n1) * 0.14   // coarse white quartz
                + smoothstep(0.87, 0.99, n2) * 0.09   // fine mica shimmer
                + n3;                                   // micro grain

  // --- Animated Phong specular (light slowly orbits) ---
  // Polished surface = narrow specular lobe
  float lightSpeed = 0.14;
  float lightX = 0.3 + 0.22 * cos(uTime * lightSpeed);
  float lightY = 0.25 + 0.14 * sin(uTime * lightSpeed * 0.75);
  vec2 lightPos = vec2(lightX, lightY);

  float specDist = length(uv - lightPos);
  float spec = pow(max(0.0, 1.0 - specDist * 3.2), 5.0) * 0.28;
  float spec2 = smoothstep(0.6, 0.0, specDist) * 0.06;  // soft secondary lobe

  // --- Ambient occlusion (corner darkening) ---
  float edgeX = min(uv.x, 1.0 - uv.x);
  float edgeY = min(uv.y, 1.0 - uv.y);
  float ao = 0.75 + 0.25 * smoothstep(0.0, 0.13, min(edgeX, edgeY));

  // --- Bevel edge highlight (top and left brighter = 3D cut stone look) ---
  float topEdge  = (1.0 - smoothstep(0.0, 0.06, uv.y)) * 0.14;
  float leftEdge = (1.0 - smoothstep(0.0, 0.06, uv.x)) * 0.07;
  // Bottom/right shadow (receding edge)
  float bottomEdge = (1.0 - smoothstep(0.0, 0.05, 1.0 - uv.y)) * 0.08;
  float rightEdge  = (1.0 - smoothstep(0.0, 0.05, 1.0 - uv.x)) * 0.04;

  // --- Assemble ---
  vec3 color = baseColor * ao;
  color += vec3(crystal);                        // mineral flecks
  color += vec3(spec + spec2);                   // specular highlight
  color += vec3(topEdge + leftEdge);             // bevel highlight
  color -= vec3(bottomEdge + rightEdge);         // bevel shadow
  color = clamp(color, 0.0, 1.0);

  fragColor = vec4(color, uOpacity);
}
