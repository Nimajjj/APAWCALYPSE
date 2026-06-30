class_name IBullet
extends Area2D

@export var speed: int
@export var piercing: bool = false

var shooter: IPlayer = null
var direction: Vector2
var damage: int
var life_time: float
var _active: bool = false

# Grossissement des projectiles (look "Brotato" : balles bien visibles).
const BULLET_SCALE := 1.9
# Tailles en pixels MONDE (independantes de l'echelle de la balle), converties en
# local au lancement. La camera ayant un zoom ~5, on reste modeste.
const TRAIL_WORLD_LEN := 16.0
const TRAIL_WORLD_WIDTH := 3.5
const LIGHT_TEX := preload("res://assets/debug/light.png")
const GLOW_COLOR := Color(1.0, 0.78, 0.32)  # braise chaude

var _base_scale: Vector2 = Vector2.ONE
var _light: PointLight2D
var _trail: Line2D


func _ready() -> void:
	# Connexion unique : les balles sont recyclees par BulletPool, on ne
	# reconnecte donc pas a chaque tir.
	_base_scale = scale
	scale = _base_scale * BULLET_SCALE
	_setup_fx()
	area_entered.connect(_on_area_entered)
	body_entered.connect(_on_body_entered)
	sleep()


## Cree la lumiere d'accompagnement et la courte trainee qui suit la balle.
func _setup_fx() -> void:
	_light = PointLight2D.new()
	_light.texture = LIGHT_TEX
	_light.color = GLOW_COLOR
	_light.energy = 0.9
	_light.texture_scale = 0.4
	_light.blend_mode = Light2D.BLEND_MODE_ADD
	add_child(_light)

	# Trainee locale : deux points alignes sur l'axe de tir (local +x = avant),
	# donc toujours derriere la balle et solidaire de son mouvement.
	_trail = Line2D.new()
	_trail.begin_cap_mode = Line2D.LINE_CAP_ROUND
	_trail.end_cap_mode = Line2D.LINE_CAP_ROUND
	var grad := Gradient.new()
	grad.set_color(0, Color(GLOW_COLOR.r, GLOW_COLOR.g, GLOW_COLOR.b, 0.0))  # arriere : transparent
	grad.set_color(1, Color(1.0, 1.0, 0.85, 0.85))                          # avant : lumineux
	_trail.gradient = grad
	add_child(_trail)


## Configure la trainee a une taille MONDE constante, quelle que soit l'echelle
## de la balle (qui varie selon l'arme).
func _setup_trail_geometry(size_mult: float) -> void:
	if _trail == null:
		return
	var s: float = max(0.001, scale.x)
	var local_len: float = (TRAIL_WORLD_LEN * size_mult) / s
	_trail.clear_points()
	_trail.add_point(Vector2(-local_len, 0.0))  # arriere
	_trail.add_point(Vector2(0.0, 0.0))         # position de la balle
	_trail.width = (TRAIL_WORLD_WIDTH * size_mult) / s


## (Re)lance la balle. Appele par les armes via BulletPool.acquire().
func launch(pos: Vector2, player: IPlayer, dmg: int, life: float, pierce: bool, dir: Vector2, size_mult: float = 1.0) -> void:
	global_position = pos
	shooter = player
	damage = dmg
	life_time = life
	piercing = pierce
	direction = dir
	rotation = dir.angle()
	scale = _base_scale * BULLET_SCALE * size_mult
	visible = true
	_active = true
	if _light != null:
		_light.visible = true
	_setup_trail_geometry(size_mult)
	set_physics_process(true)
	# Differe (peut etre appele pendant le flush physique).
	set_deferred("monitoring", true)


## Met la balle en sommeil (recyclable).
func sleep() -> void:
	_active = false
	visible = false
	if _light != null:
		_light.visible = false
	if _trail != null:
		_trail.clear_points()
	set_physics_process(false)
	set_deferred("monitoring", false)


func _physics_process(delta: float) -> void:
	if not _active:
		return
	# Deplacement O(1), independant du framerate.
	position += direction * speed * delta
	# La trainee est locale (solidaire de la balle), rien a mettre a jour ici.
	# Duree de vie par decompte (pas de Timer par balle).
	life_time -= delta
	if life_time <= 0.0:
		BulletPool.release(self)


func _on_area_entered(body: Node) -> void:
	if not _active:
		return
	if body.get_parent() is IEnemy and not body.get_parent().dead:
		body.get_parent().take_damage(damage, shooter, direction)
		EventBus.shot_hit.emit()
		# Gerbe d'impact chaude (etincelles + flash) au point de contact.
		Juice.spawn_impact(global_position, direction, Color(1.0, 0.55, 0.25), 1.1)
		if not piercing:
			BulletPool.release(self)
			return


## Collision avec un corps physique : les murs (StaticBody2D) detruisent la balle,
## meme perforante (un mur qui bloque le joueur bloque la balle).
func _on_body_entered(body: Node) -> void:
	if not _active:
		return
	if body is StaticBody2D:
		# Etincelles froides (ricochet) plus discretes sur le decor.
		Juice.spawn_impact(global_position, direction, Color(1.0, 0.92, 0.7), 0.7)
		BulletPool.release(self)
