class_name IBullet
extends Area2D

@export var speed: int
@export var piercing: bool = false

var shooter: IPlayer = null
var direction: Vector2
var damage: int
var life_time: float
var _active: bool = false


func _ready() -> void:
	# Connexion unique : les balles sont recyclees par BulletPool, on ne
	# reconnecte donc pas a chaque tir.
	area_entered.connect(_on_area_entered)
	sleep()


## (Re)lance la balle. Appele par les armes via BulletPool.acquire().
func launch(pos: Vector2, player: IPlayer, dmg: int, life: float, pierce: bool, dir: Vector2) -> void:
	global_position = pos
	shooter = player
	damage = dmg
	life_time = life
	piercing = pierce
	direction = dir
	rotation = dir.angle()
	visible = true
	_active = true
	set_physics_process(true)
	# Differe (peut etre appele pendant le flush physique).
	set_deferred("monitoring", true)


## Met la balle en sommeil (recyclable).
func sleep() -> void:
	_active = false
	visible = false
	set_physics_process(false)
	set_deferred("monitoring", false)


func _physics_process(delta: float) -> void:
	if not _active:
		return
	# Deplacement O(1), independant du framerate.
	position += direction * speed * delta
	# Duree de vie par decompte (pas de Timer par balle).
	life_time -= delta
	if life_time <= 0.0:
		BulletPool.release(self)


func _on_area_entered(body: Node) -> void:
	if not _active:
		return
	if body.get_parent() is IEnemy and not body.get_parent().dead:
		body.get_parent().take_damage(damage, shooter)
		EventBus.shot_hit.emit()
		if not piercing:
			BulletPool.release(self)
			return
	if body.name == "WallCollisions":
		BulletPool.release(self)
