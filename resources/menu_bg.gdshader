shader_type canvas_item;
// Fond de menu facon Balatro : spirale animee tournante, pixelisee (pixel-art),
// palette apocalyptique (cendres, sang, braises).

uniform vec4 col_dark  : source_color = vec4(0.05, 0.03, 0.04, 1.0); // cendre sombre
uniform vec4 col_mid   : source_color = vec4(0.42, 0.07, 0.06, 1.0); // sang seche
uniform vec4 col_hot   : source_color = vec4(1.00, 0.55, 0.12, 1.0); // braise
uniform float speed = 0.35;
uniform float spiral_arms = 5.0;
uniform float pixel_size = 220.0; // plus grand = plus fin

void fragment() {
	// Pixelisation facon pixel-art.
	vec2 uv = floor(UV * pixel_size) / pixel_size;

	// Coordonnees centrees, corrigees du ratio (approx 16:9).
	vec2 p = (uv - 0.5) * vec2(1.777, 1.0);
	float r = length(p);
	float a = atan(p.y, p.x);

	float t = TIME * speed;

	// Spirale : melange angle + log(rayon) qui tourne dans le temps.
	float swirl = sin(spiral_arms * a + log(r + 0.06) * 9.0 - t * 3.0);
	swirl = swirl * 0.5 + 0.5;

	// Pulsation radiale (anneaux de braise qui respirent).
	float rings = sin(r * 16.0 - t * 2.0) * 0.5 + 0.5;

	// Composition des couleurs.
	vec3 col = mix(col_dark.rgb, col_mid.rgb, swirl);
	col = mix(col, col_hot.rgb, pow(swirl, 3.0) * rings);

	// Coeur lumineux + assombrissement des bords (vignette).
	col += col_hot.rgb * smoothstep(0.45, 0.0, r) * 0.35;
	col *= smoothstep(1.15, 0.25, r);

	// Grain anime discret.
	float n = fract(sin(dot(uv * vec2(123.4, 567.8) + t, vec2(12.9898, 78.233))) * 43758.5453);
	col += (n - 0.5) * 0.03;

	COLOR = vec4(col, 1.0);
}
