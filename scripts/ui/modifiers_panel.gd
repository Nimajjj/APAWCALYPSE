extends Control
## Modificateurs de partie ("defis"), actives/desactives et persistes.
## Appliques a la partie suivante (double ennemis, double argent...).

const ACCENT := Color(1, 0.85, 0.3)

var _rows: VBoxContainer


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
	vb.add_theme_constant_override("separation", 10)
	center.add_child(vb)

	var title := Label.new()
	title.text = "DEFIS"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 52)
	title.add_theme_color_override("font_color", ACCENT)
	title.add_theme_color_override("font_outline_color", Color.BLACK)
	title.add_theme_constant_override("outline_size", 6)
	vb.add_child(title)

	var sub := Label.new()
	sub.text = "Modificateurs appliques a la prochaine partie"
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
	back.grab_focus()


func _rebuild() -> void:
	for c in _rows.get_children():
		c.queue_free()
	for id: String in SaveManager.MODIFIERS:
		var def: Dictionary = SaveManager.MODIFIERS[id]
		var active := SaveManager.is_modifier_active(id)
		var row := HBoxContainer.new()
		row.add_theme_constant_override("separation", 12)

		var lbl := Label.new()
		lbl.custom_minimum_size = Vector2(340, 0)
		lbl.add_theme_font_size_override("font_size", 22)
		lbl.text = "%s  -  %s" % [def.name, def.desc]
		lbl.add_theme_color_override("font_color", ACCENT if active else Color(0.7, 0.7, 0.75))
		row.add_child(lbl)

		var btn := Button.new()
		btn.custom_minimum_size = Vector2(120, 44)
		btn.text = "ACTIF" if active else "INACTIF"
		var mid := id
		btn.pressed.connect(func() -> void:
			SaveManager.toggle_modifier(mid)
			_rebuild())
		row.add_child(btn)
		_rows.add_child(row)
