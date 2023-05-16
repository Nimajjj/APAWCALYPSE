class_name IWeapon
extends Node2D

enum Weapon_Weight {LIGHT, MEDIUM, HEAVY}

@export var ref: String = ""

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

@export var secondary_weapon: IWeapon = null
@export var BulletScene: PackedScene = null
@export var ShootEffectScene: PackedScene

var actual_rate: int = 0
var weapon_direction: Vector2
var reloading: bool = false
@export var shoot_effect: GPUParticles2D = null
var can_shoot: bool = true

var player: IPlayer = null : set = _player_setter
	
func _player_setter(val) -> void:
	player = val
	if player != null && Synchronizer != null:
		Synchronizer.set_multiplayer_authority(player.name.to_int())
	
@onready var WeaponEnd = $WeaponEnd
@onready var timer = $Timer
@onready var fire_rate_timer = $FireRateTimer
@onready var Synchronizer: MultiplayerSynchronizer = $Synchronizer/MultiplayerSynchronizer


func _ready():
	Synchronizer.set_multiplayer_authority(1)
	
	if ShootEffectScene != null:
		shoot_effect = ShootEffectScene.instantiate().duplicate()
		_add_shoot_effect(shoot_effect)
		rpc("_add_shoot_effect", shoot_effect)
		

	current_mag = mag_capacity
	bullet_stock = mag_capacity * 2
	max_bullet_stock = bullet_stock * stock_factor

	fire_rate_timer.wait_time = fire_rate
	if(get_parent() is IPlayer):
		timer.wait_time = reload_time * get_parent().reload_factor
	timer.connect("timeout", func(): reload())
	fire_rate_timer.connect("timeout", func(): reset_fire_rate())


@rpc("any_peer")
func _add_shoot_effect(effect) -> void:
	shoot_effect = effect
	WeaponEnd.add_child(shoot_effect)
	Utils.log("_add_shoot_effect({0})".format([effect]), Utils.LOG_DEBUG)

func _process(_delta):
	if player == null: return
	if !player.is_local_authority: 
		weapon_direction = global_position * Vector2.RIGHT.rotated(rotation).normalized()
		weapon_direction = weapon_direction.normalized()
		return
	
	look_at(get_global_mouse_position())
	
	weapon_direction = get_global_mouse_position() - global_position
	weapon_direction = weapon_direction.normalized()
	
	if(current_mag == 0 && !reloading):
		trigger_reload()

	if Input.is_action_just_pressed("reload"):
		trigger_reload()


func has_secondary_weapon() -> bool:
	return (secondary_weapon != null)


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


func shoot(player_damage_factor: int) -> void:
	if player == null: return
	if !player.is_local_authority:
		Utils.log("Fucking huge mess somewhere, this should mever happen!", Utils.LOG_WARN)
		return
			
	if reloading: return
	if(fire_rate_timer.time_left > 0): return
	if(can_shoot):
		if(current_mag > 0):
			rpc_id(1, "shoot_server", player_damage_factor)
			_shoot_impl(player_damage_factor)
		actual_rate += 1

func stop_shooting() -> void:
	shoot_effect.emitting = false

func reset_fire_rate() -> void:
	can_shoot = true

func _on_timer_timeout() -> void:
	reload()


@rpc("any_peer")
func shoot_server(player_damage_factor: int) -> void:
	var caller_id = multiplayer.get_remote_sender_id()
	if str(player.name).to_int() != caller_id:
		Utils.log("Illegally calling shoot_server! The culprit is: " + str(caller_id), Utils.LOG_WARN)
		return

	rpc("shoot_client", player_damage_factor)
	_shoot_impl(player_damage_factor)


@rpc # Called on _all_ clients
func shoot_client(player_damage_factor: int) -> void:
	if player.is_local_authority: return
	_shoot_impl(player_damage_factor)


# Handle all the effects (visual & audio)
# This is called on all clients, including the server & the client initiating the shot
func _shoot_impl(player_damage_factor: int) -> void:
	fire_rate_timer.start()
	can_shoot = false
	if shoot_effect:
		shoot_effect.emitting = true
	var bullet: IBullet = BulletScene.instantiate()
	bullet.position = WeaponEnd.get_global_transform().origin
	bullet.damage = damage * player_damage_factor
	bullet.life_time = weapon_range
	current_mag -= 1
	get_tree().get_root().add_child(bullet)
	var spread_angle = randf_range(-spread, spread)
	var shoot_direction = weapon_direction.rotated(spread_angle)
	bullet.shoot(get_parent(), get_global_mouse_position(), shoot_direction)
	actual_rate = 0
	get_parent().shake_camera(3, shake_power, shake_power, shake_power / 2)
	$AudioStreamPlayer.play()
