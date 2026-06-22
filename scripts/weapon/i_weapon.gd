class_name IWeapon
extends Node2D

enum Weapon_Weight {LIGHT, MEDIUM, HEAVY}

@export var weapon_name: String = ""
@export var accuracy: int = 0
@export var damage: int = 0
@export var weapon_range: float = 0
@export var spread: float = 0.0
@export var fire_rate: float = 0
@export var bullet_stock: int = 0
@export var stock_factor: int = 0
@export var max_bullet_stock: int = 0
@export var current_mag: int = 0
@export var mag_capacity: int = 0
@export var reload_time: float = 0
@export var price: int = 0
@export var weight: Weapon_Weight
@export var shake_power: float = 0

@export var BulletScene: PackedScene = null
@export var ShootEffectScene: PackedScene

var actual_rate: int = 0
var weapon_direction: Vector2
var reloading: bool = false
var shoot_effect: GPUParticles2D = null
var can_shoot: bool = true
var _recoil_tween: Tween

@onready var WeaponEnd = $WeaponEnd
@onready var timer = $Timer
@onready var fire_rate_timer = $FireRateTimer
@onready var _base_scale: Vector2 = scale


func _ready():
	if ShootEffectScene != null:
		shoot_effect = ShootEffectScene.instantiate()
		WeaponEnd.add_child(shoot_effect)

	current_mag = mag_capacity
	bullet_stock = mag_capacity * 2
	max_bullet_stock = bullet_stock * stock_factor

	fire_rate_timer.wait_time = fire_rate
	if(get_parent() is IPlayer):
		timer.wait_time = reload_time * get_parent().reload_factor
	timer.connect("timeout", func(): reload())
	fire_rate_timer.connect("timeout", func(): reset_fire_rate())


func _process(_delta):

	weapon_direction = get_global_mouse_position() - global_position
	weapon_direction = weapon_direction.normalized()
	if(current_mag == 0 && !reloading):
		trigger_reload()

	if Input.is_action_just_pressed("reload"):
		trigger_reload()


func trigger_reload() -> void:
	if current_mag == mag_capacity: return
	if bullet_stock == 0: return
	if(get_parent() is IPlayer):
		timer.wait_time = reload_time * get_parent().reload_factor # update reload time
	timer.start()
	Global.in_game_ui.reloading()
	reloading = true


func reload() -> void:
	if current_mag < mag_capacity:
		var refilled_bullets: int = mag_capacity - current_mag
		if bullet_stock > 0:
			if bullet_stock >= refilled_bullets:
				current_mag += refilled_bullets
				bullet_stock -= refilled_bullets
			else:
				current_mag += bullet_stock
				bullet_stock = 0
		refilled_bullets = 0
		timer.stop()
		reloading = false
		Global.in_game_ui.stop_reloading()


func shoot(player_damage_factor: float) -> void:
	if reloading: return
	if(fire_rate_timer.time_left > 0): return
	if(can_shoot):
		if(current_mag > 0):
			fire_rate_timer.start()
			can_shoot = false
			_punch()
			if shoot_effect != null:
				shoot_effect.emitting = true
			_fire_bullet(player_damage_factor, false, weapon_direction.rotated(randf_range(-spread, spread)))
			current_mag -= 1
			actual_rate = 0
			get_parent().shake_camera(3, shake_power, shake_power, shake_power / 2)
			$AudioStreamPlayer.play()
		actual_rate += 1

## Tire une balle depuis le pool (recyclage, voir BulletPool).
func _fire_bullet(player_damage_factor: float, pierce: bool, dir: Vector2) -> void:
	var b := BulletPool.acquire(BulletScene)
	b.launch(WeaponEnd.get_global_transform().origin, get_parent() as IPlayer, int(damage * player_damage_factor), weapon_range, pierce, dir)


func stop_shooting() -> void:
	if shoot_effect != null:
		shoot_effect.emitting = false

func reset_fire_rate() -> void:
	can_shoot = true

func _on_timer_timeout() -> void:
	reload()


## Petit "punch" d'echelle a chaque tir (recul visuel). S'auto-corrige vers
## l'echelle de base meme en tir rapide.
func _punch() -> void:
	if _recoil_tween != null and _recoil_tween.is_running():
		_recoil_tween.kill()
	scale = _base_scale
	_recoil_tween = create_tween()
	_recoil_tween.tween_property(self, "scale", _base_scale * 1.12, 0.04)
	_recoil_tween.tween_property(self, "scale", _base_scale, 0.08)
