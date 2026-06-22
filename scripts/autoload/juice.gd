extends Node
## Effets de "juice" reutilisables, 100% natifs (aucun asset) :
## - textes flottants en espace-monde (degats, gains)
## - hit-stop (ralenti tres bref pour l'impact)

var _hitstop_active: bool = false


## Affiche un texte qui monte et s'estompe a la position monde donnee.
func spawn_floating_text(world_pos: Vector2, text: String, color: Color = Color.WHITE, size: int = 22) -> void:
	if Global.map == null:
		return
	var root := Node2D.new()
	root.z_index = 200
	root.position = world_pos

	var lbl := Label.new()
	lbl.text = text
	lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lbl.add_theme_font_size_override("font_size", size)
	lbl.add_theme_color_override("font_color", color)
	lbl.add_theme_color_override("font_outline_color", Color.BLACK)
	lbl.add_theme_constant_override("outline_size", 4)
	lbl.position = Vector2(-60, -28)
	lbl.custom_minimum_size = Vector2(120, 0)
	root.add_child(lbl)
	Global.map.add_child(root)

	var drift := Vector2(randf_range(-14.0, 14.0), -52.0)
	var tw := root.create_tween()
	tw.tween_property(root, "position", world_pos + drift, 0.6).set_ease(Tween.EASE_OUT)
	tw.parallel().tween_property(lbl, "modulate:a", 0.0, 0.45).set_delay(0.2)
	tw.tween_callback(root.queue_free)


## Ralenti global tres bref. Le timer ignore le time_scale et tourne meme en
## pause, ce qui garantit que time_scale est toujours restaure.
func hit_stop(duration: float = 0.06, scale: float = 0.06) -> void:
	if _hitstop_active:
		return
	_hitstop_active = true
	Engine.time_scale = scale
	await get_tree().create_timer(duration, true, false, true).timeout
	Engine.time_scale = 1.0
	_hitstop_active = false
