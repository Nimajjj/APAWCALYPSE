extends Control
## Menu principal (construit par code). Premier ecran du jeu.

const ACCENT := Color(1, 0.85, 0.3)
const GAME_SCENE := "res://scenes/game/game.tscn"
const AchievementsPanel := preload("res://scripts/ui/achievements_panel.gd")
const CharacterSelect := preload("res://scripts/ui/character_select.gd")


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)

	var bg := ColorRect.new()
	bg.color = Color(0.13, 0.13, 0.18)
	bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(bg)

	var center := CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(center)

	var vb := VBoxContainer.new()
	vb.alignment = BoxContainer.ALIGNMENT_CENTER
	vb.add_theme_constant_override("separation", 16)
	center.add_child(vb)

	var title := Label.new()
	title.text = "APAWCALYPSE"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 96)
	title.add_theme_color_override("font_color", ACCENT)
	title.add_theme_color_override("font_outline_color", Color.BLACK)
	title.add_theme_constant_override("outline_size", 12)
	vb.add_child(title)

	var sub := Label.new()
	sub.text = "Meilleur score : %d     Meilleure vague : %d     Pieces : %d" % [SaveManager.high_score, SaveManager.best_wave, SaveManager.coins]
	sub.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	sub.add_theme_color_override("font_color", Color(0.75, 0.75, 0.8))
	vb.add_child(sub)

	var spacer := Control.new()
	spacer.custom_minimum_size = Vector2(0, 24)
	vb.add_child(spacer)

	var play := _button("JOUER", _on_play)
	vb.add_child(play)
	vb.add_child(_button("PERSONNAGES", _on_characters))
	vb.add_child(_button("SUCCES", _on_achievements))
	vb.add_child(_button("QUITTER", func(): get_tree().quit()))
	play.grab_focus()

	modulate.a = 0.0
	create_tween().tween_property(self, "modulate:a", 1.0, 0.3)


func _button(text: String, cb: Callable) -> Button:
	var b := Button.new()
	b.text = text
	b.custom_minimum_size = Vector2(360, 60)
	b.add_theme_font_size_override("font_size", 30)
	b.pressed.connect(cb)
	return b


func _on_play() -> void:
	Transitions.change_scene(GAME_SCENE)


func _on_achievements() -> void:
	var panel := AchievementsPanel.new()
	add_child(panel)
	panel.setup()


func _on_characters() -> void:
	var panel := CharacterSelect.new()
	add_child(panel)
	panel.setup()
