shader_type canvas_item;
// Fond officiel de Balatro (algorithme original par localthunk - playbalatro.com),
// porte en canvas_item Godot. Palette adaptee zombie/apocalypse : sang + vert
// toxique. Pixelise (PIXEL_FILTER) ; vitesse reglable via spin_speed.

uniform vec2 screen_size = vec2(1920.0, 1080.0);
uniform vec4 colour_1 : source_color = vec4(0.55, 0.05, 0.06, 1.0); // sang
uniform vec4 colour_2 : source_color = vec4(0.27, 0.85, 0.16, 1.0); // vert toxique
uniform vec4 colour_3 : source_color = vec4(0.04, 0.06, 0.04, 1.0); // fond sombre
uniform float spin_rotation = -2.0;
uniform float spin_speed = 5.0;     // < 7.0 d'origine = un peu plus lent
uniform float contrast = 3.5;
uniform float lighting = 0.4;
uniform float spin_amount = 0.25;
uniform float pixel_filter = 480.0; // plus petit = plus gros pixels
uniform float spin_ease = 1.0;
uniform bool is_rotate = false;

void fragment() {
	vec2 screen_coords = UV * screen_size;

	float pixel_size = length(screen_size.xy) / pixel_filter;
	vec2 uv = (floor(screen_coords.xy * (1.0 / pixel_size)) * pixel_size
		- 0.5 * screen_size.xy) / length(screen_size.xy);
	float uv_len = length(uv);

	float speed = (spin_rotation * spin_ease * 0.2);
	if (is_rotate) {
		speed = TIME * speed;
	}
	speed += 302.2;
	float new_pixel_angle = atan(uv.y, uv.x) + speed
		- spin_ease * 20.0 * (spin_amount * uv_len + (1.0 - spin_amount));
	vec2 mid = (screen_size.xy / length(screen_size.xy)) / 2.0;
	uv = vec2(
		(uv_len * cos(new_pixel_angle) + mid.x),
		(uv_len * sin(new_pixel_angle) + mid.y)
	) - mid;

	uv *= 30.0;
	speed = TIME * spin_speed;
	vec2 uv2 = vec2(uv.x + uv.y);

	for (int i = 0; i < 5; i++) {
		uv2 += sin(max(uv.x, uv.y)) + uv;
		uv += 0.5 * vec2(
			cos(5.1123314 + 0.353 * uv2.y + speed * 0.131121),
			sin(uv2.x - 0.113 * speed)
		);
		uv -= 1.0 * cos(uv.x + uv.y) - 1.0 * sin(uv.x * 0.711 - uv.y);
	}

	float contrast_mod = (0.25 * contrast + 0.5 * spin_amount + 1.2);
	float paint_res = min(2.0, max(0.0, length(uv) * 0.035 * contrast_mod));
	float c1p = max(0.0, 1.0 - contrast_mod * abs(1.0 - paint_res));
	float c2p = max(0.0, 1.0 - contrast_mod * abs(paint_res));
	float c3p = 1.0 - min(1.0, c1p + c2p);
	float light = (lighting - 0.2) * max(c1p * 5.0 - 4.0, 0.0)
		+ lighting * max(c2p * 5.0 - 4.0, 0.0);

	COLOR = (0.3 / contrast) * colour_1
		+ (1.0 - 0.3 / contrast) * (colour_1 * c1p + colour_2 * c2p
			+ vec4(c3p * colour_3.rgb, c3p * colour_1.a))
		+ light;
}
