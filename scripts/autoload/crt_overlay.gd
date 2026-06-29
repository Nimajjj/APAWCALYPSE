extends CanvasLayer
## Filtre ecran CRT/VHS global (facon Balatro), affiche par-dessus tout le jeu en
## permanence. Un ColorRect plein ecran lit le screen texture et applique courbure,
## scanlines, aberration chromatique, vignette, flicker et grain.

const CRT_SHADER := preload("res://resources/crt_filter.gdshader")

var _rect: ColorRect


func _ready() -> void:
	# Au-dessus du jeu mais sous les transitions (layer 200) pour que le fondu
	# au noir recouvre bien l'ecran.
	layer = 100
	process_mode = Node.PROCESS_MODE_ALWAYS

	_rect = ColorRect.new()
	_rect.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var mat := ShaderMaterial.new()
	mat.shader = CRT_SHADER
	_rect.material = mat
	add_child(_rect)

	_update_size()
	get_viewport().size_changed.connect(_update_size)


func _update_size() -> void:
	var s := get_viewport().get_visible_rect().size
	_rect.material.set_shader_parameter("screen_size", s)
