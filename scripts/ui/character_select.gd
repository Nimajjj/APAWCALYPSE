extends Control
## Selection / deblocage de personnages, payes avec les pieces de meta-progression.

const ACCENT := Color(1, 0.85, 0.3)

var _coins_label: Label
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
	title.text = "PERSONNAGES"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 52)
	title.add_theme_color_override("font_color", ACCENT)
	title.add_theme_color_override("font_outline_color", Color.BLACK)
	title.add_theme_constant_override("outline_size", 6)
	vb.add_child(title)

	_coins_label = Label.new()
	_coins_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_coins_label.add_theme_font_size_override("font_size", 24)
	_coins_label.add_theme_color_override("font_color", ACCENT)
	vb.add_child(_coins_label)

	_rows = VBoxContainer.new()
	_rows.add_theme_constant_override("separation", 6)
	vb.add_child(_rows)

	_rebuild()

	var spacer := Control.new()
	spacer.custom_minimum_size = Vector2(0, 12)
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
	_coins_label.text = "Pieces : %d" % SaveManager.coins

	for id: String in SaveManager.CHARACTERS:
		var def: Dictionary = SaveManager.CHARACTERS[id]
		var unlocked := SaveManager.is_character_unlocked(id)
		var selected := SaveManager.selected_character == id

		var row := HBoxContainer.new()
		row.add_theme_constant_override("separation", 12)

		var name_lbl := Label.new()
		name_lbl.custom_minimum_size = Vector2(280, 0)
		name_lbl.add_theme_font_size_override("font_size", 24)
		name_lbl.text = def.name + ("  *" if selected else "")
		name_lbl.add_theme_color_override("font_color", ACCENT if unlocked else Color(0.6, 0.6, 0.65))
		row.add_child(name_lbl)

		var btn := Button.new()
		btn.custom_minimum_size = Vector2(220, 44)
		var cid := id
		if unlocked:
			btn.text = "SELECTIONNE" if selected else "CHOISIR"
			btn.disabled = selected
			btn.pressed.connect(func() -> void:
				SaveManager.select_character(cid)
				_rebuild())
		else:
			btn.text = "ACHETER (%d)" % def.price
			btn.disabled = SaveManager.coins < def.price
			btn.pressed.connect(func() -> void:
				if SaveManager.buy_character(cid):
					SaveManager.select_character(cid)
					AchievementManager.on_character_bought()
				_rebuild())
		row.add_child(btn)
		_rows.add_child(row)
