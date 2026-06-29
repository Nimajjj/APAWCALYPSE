extends Node
## Helpers de "juice" UI (le theme statique est resources/ui_theme.tres, defini
## comme theme par defaut du projet). Ajoute des animations de survol/clic facon
## Balatro aux boutons.

func add_button_juice(btn: BaseButton) -> void:
	btn.resized.connect(func() -> void: btn.pivot_offset = btn.size / 2.0)
	btn.mouse_entered.connect(func() -> void: _scale_to(btn, 1.06))
	btn.mouse_exited.connect(func() -> void: _scale_to(btn, 1.0))
	btn.button_down.connect(func() -> void: _scale_to(btn, 0.93))
	btn.button_up.connect(func() -> void: _scale_to(btn, 1.06))


func _scale_to(btn: BaseButton, s: float) -> void:
	if not is_instance_valid(btn):
		return
	var tw := btn.create_tween()
	tw.tween_property(btn, "scale", Vector2(s, s), 0.09).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
