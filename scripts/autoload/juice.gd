extends Node
## Effets de "juice" reutilisables, 100% natifs (aucun asset) :
## - textes flottants en espace-monde (degats, gains)
## - hit-stop (ralenti tres bref pour l'impact)

var _hitstop_active: bool = false

# Texture radiale douce reutilisee pour les flashs d'impact (deja presente dans le
# projet, utilisee par les balles).
const _IMPACT_LIGHT_TEX := preload("res://assets/debug/light.png")


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


## Impact de balle : flash lumineux bref + gerbe d'etincelles projetees dans
## l'hemisphere oppose a la trajectoire (ricochet), 100% code (aucun asset hormis
## la texture de lumiere). Auto-detruit apres l'animation -> aucun churn durable.
## `dir` = direction de vol de la balle ; `intensity` module taille/portee/nombre.
func spawn_impact(world_pos: Vector2, dir: Vector2, color: Color = Color(1.0, 0.85, 0.45), intensity: float = 1.0) -> void:
	if Global.map == null:
		return
	var root := Node2D.new()
	root.z_index = 180
	root.position = world_pos
	Global.map.add_child(root)

	# Flash lumineux additif qui s'eteint vite (le "pop" de l'impact).
	var light := PointLight2D.new()
	light.texture = _IMPACT_LIGHT_TEX
	light.color = color
	light.blend_mode = Light2D.BLEND_MODE_ADD
	light.texture_scale = 0.45 * intensity
	light.energy = 2.4 * intensity
	root.add_child(light)
	root.create_tween().tween_property(light, "energy", 0.0, 0.12).set_ease(Tween.EASE_OUT)

	# Etincelles : segments lumineux projetes a l'oppose de la trajectoire.
	var base_ang: float = (-dir).angle() if dir != Vector2.ZERO else randf() * TAU
	var count: int = int(round(6 * intensity))
	for _i in count:
		var spark := Line2D.new()
		spark.width = 2.0 * intensity
		spark.begin_cap_mode = Line2D.LINE_CAP_ROUND
		spark.end_cap_mode = Line2D.LINE_CAP_ROUND
		spark.default_color = color
		var seg_len: float = randf_range(4.0, 9.0) * intensity
		spark.add_point(Vector2.ZERO)
		spark.add_point(Vector2(seg_len, 0.0))
		var ang: float = base_ang + randf_range(-1.1, 1.1)
		spark.rotation = ang
		root.add_child(spark)
		var dist: float = randf_range(10.0, 24.0) * intensity
		var dur: float = randf_range(0.12, 0.22)
		var st := root.create_tween()
		st.tween_property(spark, "position", Vector2(cos(ang), sin(ang)) * dist, dur).set_ease(Tween.EASE_OUT)
		st.parallel().tween_property(spark, "modulate:a", 0.0, dur)

	var cleanup := root.create_tween()
	cleanup.tween_interval(0.3)
	cleanup.tween_callback(root.queue_free)


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
