#version 460 core
#include <flutter/runtime_effect.glsl>

// Glossy: candy/gummy surface with animated orbiting specular highlight

uniform vec2 uSize;
uniform vec2 uOrigin;
uniform float uTime;
uniform vec4 uBase;
uniform vec4 uGlow;
uniform float uOpacity;

out vec4 fragColor;

void main() {
  vec2 uv = (FlutterFragCoord().xy - uOrigin) / uSize;

  // --- Base glossy color ---
  vec3 color = uBase.rgb;

  // --- Animated highlight center (orbits upper-left area) ---
  float speed = 0.45;
  float hlX = 0.3 + 0.1 * sin(uTime * speed);
  float hlY = 0.24 + 0.08 * cos(uTime * speed * 1.4);

  // --- Main specular lobe (sharp, bright) ---
  float specDist = length(uv - vec2(hlX, hlY));
  float spec = pow(max(0.0, 1.0 - specDist * 2.2), 2.5) * 0.6;

  // --- Soft secondary lobe (diffuse falloff) ---
  float spec2 = smoothstep(0.65, 0.0, length(uv - vec2(hlX + 0.12, hlY + 0.12))) * 0.28;

  // --- Bottom subtle shadow ---
  float shadow = smoothstep(0.25, 1.0, uv.y) * 0.22;

  // --- Corner ambient occlusion ---
  float edgeX = min(uv.x, 1.0 - uv.x);
  float edgeY = min(uv.y, 1.0 - uv.y);
  float ao = 0.75 + 0.25 * smoothstep(0.0, 0.1, min(edgeX, edgeY));

  color = color * ao - vec3(shadow) + vec3(spec + spec2);
  color = clamp(color, 0.0, 1.0);

  fragColor = vec4(color, uBase.a * uOpacity);
}
