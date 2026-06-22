extends Control
## Reassignation des touches clavier. Clic sur une touche, puis appui sur la
## nouvelle. Persiste via InputSetup/SaveManager. (Manette geree par defaut.)

const ACCENT := Color(1, 0.85, 0.3)
const LABELS := {
	"move_up": "Haut", "move_down": "Bas", "move_left": "Gauche", "move_right": "Droite",
	"shoot": "Tirer", "reload": "Recharger", "interact": "Interagir",
}

var _rows: VBoxContainer
var _listening: String = ""


func setup() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)

	var bg := ColorRect.new()
	bg.color = Color(0, 0, 0, 0.9)
	bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(bg)

	var center := CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(center)

	var vb := VBoxContainer.new()
	vb.add_theme_constant_override("separation", 8)
	center.add_child(vb)

	var title := Label.new()
	title.text = "COMMANDES"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 52)
	title.add_theme_color_override("font_color", ACCENT)
	title.add_theme_color_override("font_outline_color", Color.BLACK)
	title.add_theme_constant_override("outline_size", 6)
	vb.add_child(title)

	var sub := Label.new()
	sub.text = "Clic sur une touche puis appuie sur la nouvelle (manette OK par defaut)"
	sub.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	sub.add_theme_color_override("font_color", Color(0.7, 0.7, 0.75))
	vb.add_child(sub)

	_rows = VBoxContainer.new()
	_rows.add_theme_constant_override("separation", 6)
	vb.add_child(_rows)
	_rebuild()

	var spacer := Control.new()
	spacer.custom_minimum_size = Vector2(0, 14)
	vb.add_child(spacer)

	var back := Button.new()
	back.text = "RETOUR"
	back.custom_minimum_size = Vector2(260, 50)
	back.add_theme_font_size_override("font_size", 26)
	back.pressed.connect(queue_free)
	vb.add_child(back)


func _rebuild() -> void:
	for c in _rows.get_children():
		c.queue_free()
	for action: String in InputSetup.REBINDABLE:
		var row := HBoxContainer.new()
		row.add_theme_constant_override("separation", 12)
		var lbl := Label.new()
		lbl.custom_minimum_size = Vector2(220, 0)
		lbl.add_theme_font_size_override("font_size", 22)
		lbl.text = LABELS.get(action, action)
		row.add_child(lbl)
		var btn := Button.new()
		btn.custom_minimum_size = Vector2(200, 40)
		btn.text = "..." if _listening == action else InputSetup.current_key_label(action)
		var a := action
		btn.pressed.connect(func() -> void:
			_listening = a
			_rebuild())
		row.add_child(btn)
		_rows.add_child(row)


func _input(event: InputEvent) -> void:
	if _listening != "" and event is InputEventKey and event.pressed and not event.echo:
		InputSetup.rebind(_listening, event.physical_keycode)
		_listening = ""
		_rebuild()
		get_viewport().set_input_as_handled()
