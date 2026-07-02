extends CanvasLayer

@onready var DebugLabel: RichTextLabel = $DebugLabel
@onready var InteractibleLabel: Label = $InteractibleLabel
@onready var MoneyLabel: Label = $MoneyLabel
@onready var ScoreLabel: Label = $ScoreLabel
@onready var HealthBar: ProgressBar = $HealthBar
@onready var MunitionLabel: Label = $MunitionLabel
@onready var MunitionLabel2: Label = $MunitionLabel2
@onready var BonusesOverlay: TextureRect = $BonusesOverlay
@onready var BonusesHBox: HBoxContainer = $BonusesOverlay/BonusesHBox
@onready var Portrait: TextureRect = $Portrait

var _last_player_count: int = -1
var _last_health: float = -1.0
var _objective_label: Label
var _ability_widgets: Array = []  # [{root, icon, key, cd_fill, cd_label}]
var _xp_bar: ProgressBar
var _level_label: Label
var _last_level: int = -1

func _enter_tree():
	Global.in_game_ui = self


func _ready() -> void:
	# Panneau de debug : visible seulement en build debug/editeur, bascule par F3.
	DebugLabel.visible = OS.is_debug_build()

	# Indicateur d'objectif (vague + ennemis restants), cree par code pour
	# eviter de modifier la scene a la main.
	_objective_label = Label.new()
	_objective_label.set_anchors_and_offsets_preset(Control.PRESET_TOP_WIDE)
	_objective_label.offset_top = 14.0
	_objective_label.offset_bottom = 56.0
	_objective_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_objective_label.add_theme_font_size_override("font_size", 28)
	_objective_label.add_theme_color_override("font_color", Color(1, 0.85, 0.3))
	_objective_label.add_theme_color_override("font_outline_color", Color.BLACK)
	_objective_label.add_theme_constant_override("outline_size", 5)
	add_child(_objective_label)

	_build_xp_ui()
	_build_abilities_ui()


## Barre d'XP + niveau (roguelike), sous l'indicateur d'objectif en haut d'ecran.
func _build_xp_ui() -> void:
	var row := HBoxContainer.new()
	row.set_anchors_and_offsets_preset(Control.PRESET_TOP_WIDE)
	row.offset_top = 60.0
	row.offset_bottom = 82.0
	row.offset_left = 340.0
	row.offset_right = -340.0
	row.add_theme_constant_override("separation", 10)
	add_child(row)

	_level_label = Label.new()
	_level_label.text = "Niv. 1"
	_level_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_level_label.custom_minimum_size = Vector2(84, 0)
	_level_label.add_theme_font_size_override("font_size", 20)
	_level_label.add_theme_color_override("font_color", Color(0.6, 0.85, 1.0))
	_level_label.add_theme_color_override("font_outline_color", Color.BLACK)
	_level_label.add_theme_constant_override("outline_size", 4)
	row.add_child(_level_label)

	_xp_bar = ProgressBar.new()
	_xp_bar.show_percentage = false
	_xp_bar.min_value = 0.0
	_xp_bar.max_value = 100.0
	_xp_bar.value = 0.0
	_xp_bar.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_xp_bar.custom_minimum_size = Vector2(0, 16)
	var bg := StyleBoxFlat.new()
	bg.bg_color = Color(0.08, 0.08, 0.12, 0.85)
	bg.set_corner_radius_all(8)
	bg.set_border_width_all(2)
	bg.border_color = Color(0.4, 0.6, 0.9, 0.6)
	var fill := StyleBoxFlat.new()
	fill.bg_color = Color(0.4, 0.7, 1.0)
	fill.set_corner_radius_all(8)
	_xp_bar.add_theme_stylebox_override("background", bg)
	_xp_bar.add_theme_stylebox_override("fill", fill)
	row.add_child(_xp_bar)


## Construit l'UI des capacites (bas-gauche, au-dessus des bonus recuperes).
func _build_abilities_ui() -> void:
	var box := HBoxContainer.new()
	box.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_LEFT)
	box.offset_left = 12.0
	box.offset_top = -156.0
	box.offset_bottom = -88.0
	box.add_theme_constant_override("separation", 10)
	add_child(box)

	for i in 2:
		_ability_widgets.append(_make_ability_widget(box))


func _make_ability_widget(parent: Node) -> Dictionary:
	var root := Panel.new()
	root.custom_minimum_size = Vector2(64, 64)
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color(0.1, 0.1, 0.14, 0.85)
	sb.set_corner_radius_all(10)
	sb.set_border_width_all(2)
	sb.border_color = Color(1, 1, 1, 0.25)
	root.add_theme_stylebox_override("panel", sb)
	parent.add_child(root)

	# Logo (glyphe ASCII teinte).
	var icon := Label.new()
	icon.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	icon.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	icon.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	icon.add_theme_font_size_override("font_size", 26)
	root.add_child(icon)

	# Voile de cooldown qui se vide par le bas.
	var cd_fill := ColorRect.new()
	cd_fill.color = Color(0, 0, 0, 0.6)
	cd_fill.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	cd_fill.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(cd_fill)

	# Compteur de secondes restantes.
	var cd_label := Label.new()
	cd_label.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	cd_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	cd_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	cd_label.add_theme_font_size_override("font_size", 24)
	cd_label.add_theme_color_override("font_color", Color(1, 1, 1, 0.95))
	root.add_child(cd_label)

	# Touche associee (coin bas).
	var key := Label.new()
	key.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_WIDE)
	key.offset_top = -20.0
	key.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	key.add_theme_font_size_override("font_size", 14)
	key.add_theme_color_override("font_color", Color(1, 0.85, 0.3))
	root.add_child(key)

	return {"root": root, "icon": icon, "cd_fill": cd_fill, "cd_label": cd_label, "key": key}


func _update_abilities_ui(player: IPlayer) -> void:
	if not player.has_method("get_abilities_status"):
		return
	var st: Array = player.get_abilities_status()
	for i in range(min(st.size(), _ability_widgets.size())):
		var a: Dictionary = st[i]
		var w: Dictionary = _ability_widgets[i]
		w["icon"].text = a["icon"]
		w["icon"].add_theme_color_override("font_color", a["color"])
		w["key"].text = a["key"]
		var ratio: float = 0.0 if a["total"] <= 0.0 else clampf(a["left"] / a["total"], 0.0, 1.0)
		w["cd_fill"].visible = ratio > 0.0
		w["cd_fill"].anchor_top = 1.0 - ratio
		w["cd_label"].visible = a["left"] > 0.05
		w["cd_label"].text = str(int(ceil(a["left"])))


func _process(_delta):
	if Global.players.is_empty():
		return
	var player: IPlayer = Global.players[0]

	_update_abilities_ui(player)

	if _objective_label != null:
		# "Restants" = ennemis pas encore apparus + ennemis en vie : c'est le total
		# a eliminer pour terminer la vague (cf. Global.notify_enemy_died), et non le
		# seul nombre d'ennemis actuellement a l'ecran.
		var remaining: int = Global.units_left_to_spawn + Global.units_alive
		_objective_label.text = "VAGUE %d   -   Ennemis restants : %d" % [Global.game.wave, remaining]

	# Barre d'XP / niveau (progression roguelike).
	if _xp_bar != null:
		_xp_bar.max_value = maxf(1.0, float(Progression.xp_to_next))
		_xp_bar.value = float(Progression.xp)
		if Progression.level != _last_level:
			_last_level = Progression.level
			_level_label.text = "Niv. %d" % Progression.level
			_pulse(_level_label)

	ScoreLabel.text = str(Global.game.score)
	MoneyLabel.text = str(player.money)
	HealthBar.value = player.health
	if _last_health >= 0.0 and player.health < _last_health:
		_pulse(HealthBar)
	_last_health = player.health
	MunitionLabel.text = "{0}".format([player.weapon.current_mag])
	# Reserve de munitions desormais infinie.
	MunitionLabel2.text = "∞"

	# Reconstruction coûteuse : uniquement si le panneau de debug est affiché.
	if DebugLabel.visible:
		var _text: String = ""
		_text += Global.version + "\n"
		_text += "FPS: " + str(Engine.get_frames_per_second()) + "\n"
		_text += "Draw calls: " + str(Performance.get_monitor(Performance.RENDER_TOTAL_DRAW_CALLS_IN_FRAME)) + "\n"
		_text += "Nodes: " + str(Performance.get_monitor(Performance.OBJECT_NODE_COUNT)) + "\n"
		_text += "RAM: " + str(snapped(Performance.get_monitor(Performance.MEMORY_STATIC) / 1048576.0, 0.1)) + " Mo\n"
		_text += "Proc/Phys ms: " + str(snapped(Performance.get_monitor(Performance.TIME_PROCESS) * 1000.0, 0.01)) + " / " + str(snapped(Performance.get_monitor(Performance.TIME_PHYSICS_PROCESS) * 1000.0, 0.01)) + "\n"
		_text += "Time: " + str(snapped(Global.game.time, 0.01)) + "\n"
		_text += "Score: " + str(Global.game.score) + "\n"
		_text += "Wave: " + str(Global.game.wave) + "\n"
		_text += "Money: " + str(player.money) + "\n"
		_text += "Health: " + str(player.health) + "\n"
		_text += "Speed: " + str(player.speed) + "\n"
		_text += "Damage Factor: " + str(player.damage_factor) + "\n"
		_text += "Reload Factor: " + str(player.reload_factor) + "\n"
		_text += "Current Mag: " + str(player.weapon.current_mag) + "\n"
		_text += "Mag Capacity: " + str(player.weapon.mag_capacity) + "\n"
		_text += "Bullet Stock: " + str(player.weapon.bullet_stock) + "\n"
		_text += "Max Bullet Stock: " + str(player.weapon.max_bullet_stock) + "\n"
		_text += "Stock Factor: " + str(player.weapon.stock_factor) + "\n"
		DebugLabel.text = _text

	var active_bonuses: Array = player.active_bonus
	for bonus in BonusesHBox.get_children():
		if bonus.name.to_lower() in active_bonuses:
			bonus.modulate = Color(1, 1, 1, 1.5)
		else:
			bonus.modulate = Color(1, 1, 1, 0.39)

	# Le portrait ne dépend que du nombre de joueurs : on évite une
	# réaffectation (et mutation de texture) inutile à chaque frame.
	if _last_player_count != Global.players.size():
		_last_player_count = Global.players.size()
		for i in range(Global.players.size()):
			Portrait.texture.region = Rect2(0, 32 * (i + 3), 32, 32)


func stop_reloading() -> void:
	$AnimationPlayer.stop()
	$TextureRect.visible = true
	$TextureRect2.visible = false

func reloading() -> void:
	$AnimationPlayer.play("reload")


## Petit pulse d'echelle pour attirer l'oeil (ex. barre de vie qui baisse).
func _pulse(ctrl: Control) -> void:
	ctrl.pivot_offset = ctrl.size / 2.0
	var t := create_tween()
	t.tween_property(ctrl, "scale", Vector2(1.18, 1.18), 0.06)
	t.tween_property(ctrl, "scale", Vector2.ONE, 0.14)


func _input(event: InputEvent) -> void:
	# F3 : afficher/masquer le panneau de debug.
	if event is InputEventKey and event.pressed and not event.echo and event.keycode == KEY_F3:
		DebugLabel.visible = not DebugLabel.visible
