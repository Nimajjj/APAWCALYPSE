extends CanvasLayer
## Transitions de scene en fondu au noir. Autoload, au-dessus de tout.

var _rect: ColorRect


func _ready() -> void:
	layer = 200
	process_mode = Node.PROCESS_MODE_ALWAYS
	_rect = ColorRect.new()
	_rect.color = Color.BLACK
	_rect.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_rect.modulate.a = 0.0
	add_child(_rect)


func change_scene(path: String) -> void:
	_do(func() -> void: get_tree().change_scene_to_file(path))


func reload_scene() -> void:
	_do(func() -> void: get_tree().reload_current_scene())


func _do(action: Callable) -> void:
	var tw := create_tween()
	tw.tween_property(_rect, "modulate:a", 1.0, 0.25)
	tw.tween_callback(func() -> void:
		get_tree().paused = false
		action.call())
	tw.tween_interval(0.05)
	tw.tween_property(_rect, "modulate:a", 0.0, 0.25)
