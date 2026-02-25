#version 460 core
#include <flutter/runtime_effect.glsl>

// Soap Bar ASMR: fine square grid with ultra-thin cutting lines + sand grain texture
// Like a scored soap bar — small squares with hair-thin white seams,
// each tile has subtle sand-grain texture (fine powdery soap surface)

uniform vec2 uSize;
uniform vec2 uOrigin;
uniform float uTime;    // unused (static surface)
uniform vec4 uBase;     // cyan #4DD0E1
uniform vec4 uGlow;     // light cyan #80DEEA
uniform float uOpacity;

out vec4 fragColor;

float hash(vec2 p) {
  return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453);
}

void main() {
  vec2 uv = (FlutterFragCoord().xy - uOrigin) / uSize;
  vec2 px = FlutterFragCoord().xy;

  // --- Grid: 6px tiles, seam at each boundary ---
  float period = 6.3;
  vec2 tc = mod(px, vec2(period));

  // Distance from nearest period boundary (seam is centered on the boundary)
  float distX = min(tc.x, period - tc.x);
  float distY = min(tc.y, period - tc.y);

  // Anti-aliased seam: fades to tile color ~0.4px from boundary → visual width ≈ 0.25px
  float lineX = 1.0 - smoothstep(0.0, 0.45, distX);
  float lineY = 1.0 - smoothstep(0.0, 0.45, distY);
  float isLine = clamp(lineX + lineY, 0.0, 1.0);

  // --- Sand grain: per-pixel hash for fine powdery texture ---
  vec2 grainPx = floor(px); // snap to pixel grid → static grain
  float grain = hash(grainPx);

  // Bright specks: top 9% of hash → light sand particles
  float brightSpeck = smoothstep(0.91, 1.0, grain) * 0.20;
  // Dark specks: bottom 5% → shadow pits
  float darkSpeck = smoothstep(0.05, 0.0, grain) * 0.10;
  // Continuous fine grain: ±4% luminance modulation everywhere
  float fineGrain = (grain - 0.5) * 0.08;
  float grainMod = brightSpeck - darkSpeck + fineGrain;

  // --- Per-tile bevel (top/left brighter, bottom/right darker) ---
  // tilePos in [0,1] within the tile interior (exclude seam)
  float tileWidth = period - 0.45;
  vec2 tilePos = clamp(tc / tileWidth, 0.0, 1.0);

  float topEdge  = smoothstep(0.25, 0.0, tilePos.y) * 0.07;
  float leftEdge = smoothstep(0.25, 0.0, tilePos.x) * 0.05;
  float btmEdge  = smoothstep(0.75, 1.0, tilePos.y) * 0.04;
  float rgtEdge  = smoothstep(0.75, 1.0, tilePos.x) * 0.03;
  float tileBevel = 1.0 + topEdge + leftEdge - btmEdge - rgtEdge;

  // --- Gentle directional light across the whole surface ---
  float light = 0.87 + 0.13 * (1.0 - uv.x * 0.38 - uv.y * 0.26);

  // --- Color ---
  vec3 soapColor = mix(uBase.rgb, uGlow.rgb, 0.30);
  vec3 color = soapColor * tileBevel * light;

  // Sand grain applied inside tiles only (not on seam lines)
  color += vec3(grainMod) * (1.0 - isLine);

  // White seam lines (slightly cyan-tinted, not pure white)
  vec3 lineColor = mix(vec3(1.0), uGlow.rgb, 0.12);
  color = mix(color, lineColor, isLine * 0.85);

  // Very faint center sheen (ambient reflection on the soap face)
  float centerHL = smoothstep(0.52, 0.0, length(uv - vec2(0.40, 0.33))) * 0.038;
  color += vec3(centerHL);

  color = clamp(color, 0.0, 1.0);
  fragColor = vec4(color, uOpacity);
}
