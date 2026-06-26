class_name FireRing
extends Node2D
## Capacite offensive : un cercle de flammes tourne autour du joueur pendant
## quelques secondes, infligeant des degats periodiques (et un flash "enflamme")
## aux ennemis a portee. Entierement construit par code (FX inclus).

const LIGHT_TEX := preload("res://assets/debug/light.png")
const FLAME_COUNT := 10
const FLAME_SCALE := 0.22

@export var radius: float = 56.0          # rayon de placement des flammes
@export var damage_margin: float = 28.0    # marge pour couvrir l'etendue des flammes
@export var duration: float = 4.0
@export var tick_interval: float = 0.3
@export var tick_damage: int = 45
@export var spin_speed: float = 4.5  # rad/s

var _flames: Array = []
var _tick_t: float = 0.0
var _life_t: float = 0.0
var _area: Area2D


func _ready() -> void:
	z_index = 4
	# Reglages centralises (dashboard / sauvegarde).
	radius = GameConfig.effective("abilities", "fire_radius")
	duration = GameConfig.effective("abilities", "fire_duration")
	tick_interval = GameConfig.effective("abilities", "fire_tick")
	tick_damage = int(GameConfig.effective("abilities", "fire_damage"))

	# Zone de degats (meme principe que les balles : detection d'Area2D des
	# HurtBox ennemies). Fiable, sans calcul de distance manuel.
	_area = Area2D.new()
	_area.monitoring = true
	var shape := CollisionShape2D.new()
	var circle := CircleShape2D.new()
	circle.radius = radius + damage_margin
	shape.shape = circle
	_area.add_child(shape)
	add_child(_area)

	for i in FLAME_COUNT:
		var f := Sprite2D.new()
		f.texture = LIGHT_TEX
		f.modulate = Color(1.0, 0.5, 0.12, 0.95)
		f.scale = Vector2(FLAME_SCALE, FLAME_SCALE)
		var a := TAU * float(i) / float(FLAME_COUNT)
		f.position = Vector2(cos(a), sin(a)) * radius
		add_child(f)
		_flames.append(f)
		# Pulsation desynchronisee de chaque flamme.
		var tw := f.create_tween().set_loops()
		tw.tween_property(f, "scale", Vector2(FLAME_SCALE * 1.5, FLAME_SCALE * 1.5), 0.25 + 0.02 * i)
		tw.tween_property(f, "scale", Vector2(FLAME_SCALE, FLAME_SCALE), 0.25 + 0.02 * i)


func _process(delta: float) -> void:
	rotation += spin_speed * delta
	_life_t += delta
	_tick_t += delta
	if _tick_t >= tick_interval:
		_tick_t = 0.0
		_burn_enemies()
	if _life_t >= duration:
		_extinguish()


func _burn_enemies() -> void:
	if _area == null:
		return
	var shooter: IPlayer = get_parent() as IPlayer
	if shooter == null:
		return
	# Detecte les HurtBox ennemies qui chevauchent la zone (comme une balle).
	for a in _area.get_overlapping_areas():
		var e = a.get_parent()
		if e is IEnemy and is_instance_valid(e) and not e.dead:
			# Flash "enflamme" orange.
			e.Sprite.material.set_shader_parameter("flash_color", Color(1, 0.5, 0.1, 1))
			e.Sprite.material.set_shader_parameter("flash_modifier", 0.7)
			e.timer.start()
			e.take_damage(tick_damage, shooter)


func _extinguish() -> void:
	set_process(false)
	var tw := create_tween()
	for f in _flames:
		if is_instance_valid(f):
			tw.parallel().tween_property(f, "modulate:a", 0.0, 0.25)
	tw.tween_callback(queue_free)
