// Silhouette "rayon X" du joueur : redessine la forme du sprite en aplat de
// couleur, mais UNIQUEMENT sur la bande verticale (en coordonnees monde)
// reellement recouverte par un decor. Le sprite silhouette est rendu a un
// z_index eleve pour passer par-dessus murs et props ; ce shader garde l'alpha
// du sprite et n'affiche que les pixels compris dans [band_top, band_bottom].
shader_type canvas_item;

uniform vec4 silhouette_color : source_color = vec4(0.45, 0.8, 1.0, 1.0);
// Opacite globale de la silhouette (0 = invisible, 1 = pleine).
uniform float fill_alpha : hint_range(0.0, 1.0) = 0.65;
// Bande recouverte, en Y monde. Defaut : bande vide (rien d'affiche).
uniform float band_top = 100000.0;
uniform float band_bottom = -100000.0;

varying vec2 world_pos;

void vertex() {
	world_pos = (MODEL_MATRIX * vec4(VERTEX, 0.0, 1.0)).xy;
}

void fragment() {
	float a = texture(TEXTURE, UV).a;
	// 1.0 seulement si band_top <= world_pos.y <= band_bottom.
	float inside = step(band_top, world_pos.y) * step(world_pos.y, band_bottom);
	COLOR = vec4(silhouette_color.rgb, a * silhouette_color.a * fill_alpha * inside);
}
