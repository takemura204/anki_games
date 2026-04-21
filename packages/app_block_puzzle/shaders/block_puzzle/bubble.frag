#version 460 core
#include <flutter/runtime_effect.glsl>

// Bubble Wrap ASMR: vivid 3D sphere with sharp vinyl specular and strong iridescence
// Vinyl plastic bubble: proper 3D sphere with sharp primary specular (power 64),
// soft secondary lobe, vivid saturated rainbow iridescence, and bottom depth shadow

uniform vec2 uSize;
uniform vec2 uOrigin;
uniform float uTime;
uniform vec4 uBase;
uniform vec4 uGlow;
uniform float uOpacity;

out vec4 fragColor;

vec3 hue2rgb(float h) {
  float r = abs(h * 6.0 - 3.0) - 1.0;
  float g = 2.0 - abs(h * 6.0 - 2.0);
  float b = 2.0 - abs(h * 6.0 - 4.0);
  return clamp(vec3(r, g, b), 0.0, 1.0);
}

void main() {
  vec2 uv = (FlutterFragCoord().xy - uOrigin) / uSize;
  vec2 centered = uv - 0.5;

  // --- Circular bubble mask ---
  float r = length(centered) * 2.0;
  float circleMask = 1.0 - smoothstep(0.80, 0.96, r);
  if (circleMask <= 0.001) {
    fragColor = vec4(0.0);
    return;
  }

  // --- Sphere surface normal (3D sphere illusion) ---
  float sphereZ = sqrt(max(0.0, 1.0 - r * r * 0.85));
  vec3 normal = normalize(vec3(centered * 2.0, sphereZ));

  // --- Animated Phong lighting ---
  float lightAngle = uTime * 0.32;
  vec3 lightDir = normalize(vec3(
    0.55 + 0.25 * cos(lightAngle),
    -0.65 + 0.15 * sin(lightAngle),
    0.90
  ));

  vec3 viewDir = vec3(0.0, 0.0, 1.0);
  float diffuse = max(0.0, dot(normal, lightDir));

  vec3 reflectDir = reflect(-lightDir, normal);
  float NdotR = max(0.0, dot(reflectDir, viewDir));

  // Sharp primary specular (vinyl plastic: power 64 for crisp highlight)
  float spec = pow(NdotR, 64.0) * 1.05;
  // Soft secondary specular (wide lobe: wet plastic surface feel)
  float spec2 = pow(NdotR, 8.0) * 0.22;

  // --- Fresnel: edge brightening ---
  float fresnel = pow(1.0 - max(0.0, dot(normal, viewDir)), 2.2);

  // --- Vivid thin-film iridescence: saturated rainbow at Fresnel edges ---
  float hue = fract(atan(centered.y, centered.x) / 6.28318 + uTime * 0.065);
  // Boost saturation by mixing towards pure hue from grey
  vec3 rainbow = mix(vec3(0.5), hue2rgb(hue), 1.55);
  rainbow = clamp(rainbow, 0.0, 1.0);
  float iridStrength = fresnel * 0.80; // was 0.58

  // --- Base translucent color with sphere depth shading ---
  vec3 deepColor = uBase.rgb * (0.38 + diffuse * 0.48);
  vec3 color = mix(deepColor, rainbow, iridStrength);

  // Primary sharp specular (the satisfying bright "pop" highlight)
  color += vec3(spec);
  // Secondary soft specular
  color += vec3(spec2) * 0.55;

  // Center darkening (sphere depth — convex center looks thicker)
  float centerDark = (1.0 - smoothstep(0.0, 0.28, r)) * 0.08;
  color -= vec3(centerDark);

  // Bottom depth shadow (enhances 3D sphere illusion — lighter top, darker bottom)
  float bottomShadow = smoothstep(-0.3, 0.45, centered.y)
                     * (1.0 - smoothstep(0.50, 0.82, r))
                     * 0.10;
  color -= vec3(bottomShadow);

  // Rim glow from glowColor (slightly stronger than before)
  color += uGlow.rgb * fresnel * 0.22;

  color = clamp(color, 0.0, 1.0);

  // Alpha: translucent plastic — fresnel + specular boost opacity at edges/highlights
  float alpha = uBase.a * (0.52 + fresnel * 0.26 + spec * 0.30) * circleMask * uOpacity;
  alpha = clamp(alpha, 0.0, 1.0);

  fragColor = vec4(color, alpha);
}
