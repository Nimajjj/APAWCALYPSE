shader_type canvas_item;
// Fond de menu anime facon Balatro : gradient ondulant + glows derivants + grain.

uniform vec4 col_a : source_color = vec4(0.09, 0.09, 0.16, 1.0);
uniform vec4 col_b : source_color = vec4(0.22, 0.10, 0.24, 1.0);
uniform vec4 col_glow : source_color = vec4(0.9, 0.7, 0.25, 1.0);
uniform float speed = 0.25;

void fragment() {
	vec2 uv = UV;
	float t = TIME * speed;

	// gradient vertical ondulant
	float wave = sin(uv.x * 5.0 + t) * 0.08 + cos(uv.y * 4.0 - t * 1.2) * 0.08;
	float g = clamp(uv.y + wave, 0.0, 1.0);
	vec3 base = mix(col_a.rgb, col_b.rgb, g);

	// deux glows dorés qui derivent lentement
	vec2 p1 = vec2(0.5 + 0.32 * sin(t * 0.7), 0.45 + 0.28 * cos(t * 0.5));
	vec2 p2 = vec2(0.5 + 0.30 * cos(t * 0.4), 0.55 + 0.30 * sin(t * 0.6));
	base += col_glow.rgb * (0.07 * smoothstep(0.45, 0.0, distance(uv, p1))
		+ 0.05 * smoothstep(0.50, 0.0, distance(uv, p2)));

	// grain tres subtil
	float n = fract(sin(dot(uv * vec2(123.4, 567.8) + t, vec2(12.9898, 78.233))) * 43758.5453);
	base += (n - 0.5) * 0.02;

	COLOR = vec4(base, 1.0);
}
