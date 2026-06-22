shader_type canvas_item;
// Post-traitement plein ecran in-game : aberration chromatique + scanlines +
// vignette. Subtil par defaut (parametres exposes). Lit le rendu courant.

uniform sampler2D screen_texture : hint_screen_texture, filter_linear;
uniform float aberration : hint_range(0.0, 6.0) = 2.2;        // decalage RVB (px)
uniform float scanline_strength : hint_range(0.0, 0.5) = 0.12;
uniform float scanline_density : hint_range(100.0, 1200.0) = 540.0;
uniform float vignette_strength : hint_range(0.0, 1.0) = 0.5;
uniform float damage_flash : hint_range(0.0, 1.0) = 0.0;      // anime par le code a l'encaissement
uniform vec3 damage_color : source_color = vec3(0.85, 0.06, 0.06);

void fragment() {
	vec2 uv = SCREEN_UV;
	vec2 px = 1.0 / vec2(textureSize(screen_texture, 0));

	// aberration chromatique (plus forte vers les bords)
	float edge = distance(uv, vec2(0.5)) * 2.0;
	vec2 off = vec2(aberration * edge * px.x, 0.0);
	float r = texture(screen_texture, uv - off).r;
	float g = texture(screen_texture, uv).g;
	float b = texture(screen_texture, uv + off).b;
	vec3 col = vec3(r, g, b);

	// scanlines (densite independante de la resolution, lisible meme reduite)
	float scan = sin(uv.y * scanline_density * 3.14159) * 0.5 + 0.5;
	col *= 1.0 - scanline_strength * scan;

	// vignette
	float vig = smoothstep(0.85, 0.45, distance(uv, vec2(0.5)));
	col *= mix(1.0 - vignette_strength, 1.0, vig);

	// flash rouge a l'encaissement : plus marque sur les bords (effet "blessure")
	float dmg = damage_flash * mix(1.0, 0.35, vig);
	col = mix(col, damage_color, clamp(dmg, 0.0, 1.0));

	COLOR = vec4(col, 1.0);
}
