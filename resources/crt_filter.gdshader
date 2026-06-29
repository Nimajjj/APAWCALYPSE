shader_type canvas_item;
// Filtre ecran post-process facon Balatro : courbure d'ecran (barrel distortion),
// aberration chromatique RGB, scanlines, vignette, flicker et grain anime.
// A poser sur un ColorRect plein ecran qui lit le screen texture (au-dessus du jeu).

uniform sampler2D screen_tex : hint_screen_texture, filter_linear, repeat_disable;
uniform vec2 screen_size = vec2(1920.0, 1080.0);
uniform float curvature = 6.0;        // plus petit = ecran plus bombe
uniform float aberration = 1.6;       // decalage RGB en pixels
uniform float scanline_count = 540.0; // nombre de scanlines
uniform float scanline_intensity = 0.12;
uniform float vignette_strength = 0.35;
uniform float flicker = 0.03;
uniform float noise_amount = 0.03;

float rand(vec2 co) {
	return fract(sin(dot(co, vec2(12.9898, 78.233))) * 43758.5453);
}

// Courbure facon tube cathodique (barrel distortion).
vec2 curve_uv(vec2 uv) {
	uv = uv * 2.0 - 1.0;
	vec2 offset = abs(uv.yx) / vec2(curvature, curvature);
	uv = uv + uv * offset * offset;
	return uv * 0.5 + 0.5;
}

void fragment() {
	vec2 uv = curve_uv(SCREEN_UV);

	// Hors-ecran apres courbure -> bord noir du tube.
	if (uv.x < 0.0 || uv.x > 1.0 || uv.y < 0.0 || uv.y > 1.0) {
		COLOR = vec4(0.0, 0.0, 0.0, 1.0);
	} else {
		// Aberration chromatique : R et B decales horizontalement.
		float ab = aberration / screen_size.x;
		vec3 col;
		col.r = texture(screen_tex, uv + vec2(ab, 0.0)).r;
		col.g = texture(screen_tex, uv).g;
		col.b = texture(screen_tex, uv - vec2(ab, 0.0)).b;

		// Scanlines.
		float scan = sin(uv.y * scanline_count * 6.2831853) * 0.5 + 0.5;
		col *= 1.0 - scanline_intensity * scan;

		// Leger masque d'apertures verticales (aspect grille CRT).
		float aperture = 0.5 + 0.5 * sin(uv.x * screen_size.x * 3.14159);
		col *= 1.0 - 0.04 * aperture;

		// Vignette douce.
		vec2 cuv = uv - 0.5;
		float vig = clamp(1.0 - dot(cuv, cuv) * vignette_strength * 4.0, 0.0, 1.0);
		col *= pow(vig, 1.2);

		// Flicker temporel discret.
		col *= 1.0 - flicker * (0.5 + 0.5 * sin(TIME * 120.0));

		// Grain anime.
		col += (rand(uv + fract(TIME)) - 0.5) * noise_amount;

		COLOR = vec4(col, 1.0);
	}
}
