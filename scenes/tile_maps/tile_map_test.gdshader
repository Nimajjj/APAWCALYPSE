shader_type canvas_item;

uniform vec2 player_position;
uniform vec4 wrld_vertex;


varying vec2 world_pos;

void vertex() {
	world_pos = (MODEL_MATRIX * vec4(VERTEX, 1.0, 1.0)).xy;
}

void fragment(){
	vec4 color = texture(TEXTURE, UV);

	vec2 dv = player_position - world_pos;
	float d = sqrt(dv.x * dv.x + dv.y * dv.y);
	
	if (d < 16.0) {
		color.a = 0.0;
	}

	
	COLOR = color;
}