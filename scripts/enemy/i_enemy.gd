class_name IEnemy
extends CharacterBody2D

var blood_effect_scene: PackedScene = preload("res://scenes/effects/gpu_blood_effect.tscn")
var bonus_scene: PackedScene = preload("res://scenes/bonus/i_bonus.tscn")

var dead: bool = false
var slowed: bool = false
var direction: String
var target
var state: int = 0
var destination: Vector2
var knockback_force: float = 0
var knockback_direction: Vector2 = Vector2.ZERO
var speed_stock: int


var spawner: ISpawner = null

@onready var Sprite = $Sprite2D
@onready var HealthBar = $HealthBar
@onready var timer = $Timer
@onready var slow_timer = $SlowTimer
@onready var path_timer = $PathTimer
@onready var agent := $NavigationAgent2D as NavigationAgent2D
@onready var bite_sound: AudioStreamPlayer2D = $BiteSound
@onready var death_sound: AudioStreamPlayer2D = $DeathSound


@export var max_health: int
@export var speed: int
@export var money: int
@export var damage: int
@export var health: int = 0 # do not change in editor

@onready var Synchronizer: MultiplayerSynchronizer = $Synchronizer/MultiplayerSynchronizer
@export var is_boss: bool = false
@export var is_miser: bool = false
@export var is_reaper: bool = false


#var bonus: IBonus = null


func _ready():
	Synchronizer.set_multiplayer_authority(1)

	HealthBar.visible = false
	HealthBar.max_value = max_health
	HealthBar.value = max_health
	speed_stock = speed


	Sprite.material = Sprite.material.duplicate()

	timer.connect("timeout", func():
		Sprite.material.set_shader_parameter("flash_modifier", 0.0)
	)
	slow_timer.connect("timeout", func(): slow_timeout())
	path_timer.connect("timeout", func(): retarget_timeout())

	death_sound.connect("finished", func(): death_sound_finished())

func _physics_process(delta):
	if Synchronizer.get_multiplayer_authority() != 1: return

	if dead:
		return
	if state == 0:
		if target is Vector2:
			var _direction = (target - global_position).normalized()
			_move(delta, _direction)
	elif state == 1:
		var _velocity: Vector2
		if direction == "down":
			_velocity = (Vector2.DOWN * speed * delta) / 125
		elif direction == "up":
			_velocity = (Vector2.UP * speed * delta) / 125
		elif direction == "left":
			_velocity = (Vector2.LEFT * speed * delta) / 125
		else:
			_velocity = (Vector2.RIGHT * speed * delta) / 125
		position += _velocity
	elif state == 2:
		var _direction = to_local(agent.get_next_path_position()).normalized()
		_move(delta, _direction)

func take_damage(dmg: int, shooter: IPlayer) -> void:
	HealthBar.visible = true
	Sprite.material.set_shader_parameter("flash_modifier", 1.0)
	timer.start()

	if(shooter.dead_shot) and !is_boss:
		dies(shooter)
		return

	slow()

	health -= dmg
	if health <= 0:
		dies(shooter)

	HealthBar.value = health

func _move(delta, _direction) -> void:
	if _direction.x < 0:
		Sprite.flip_h = false
	elif _direction.x > 0:
		Sprite.flip_h = true
	var _velocity = _direction * speed * delta
	velocity = _velocity
	move_and_slide()

func retarget() -> void:
	if Global.players.size() != 0:
		for player in Global.players:
			if target == null: target = player

			if (position - player.position).length() < (position - target.position).length():
				target = player

		agent.target_position = target.global_position

func retarget_timeout() -> void:
	retarget()

func slow() -> void:
	slow_timer.start()
	if not slowed:
		speed -= 20
		if speed <= 0:
			speed = 5
		slowed = true

func slow_timeout() -> void:
	speed = speed_stock
	slowed = false

func death_sound_finished() -> void:
	queue_free()

func dies(shooter: IPlayer) -> void:
	if !multiplayer.is_server(): return

	if not dead:
		dead = true

		$AnimationPlayer.stop()
		$Hitbox.disabled = true
		$HurtBox.get_child(0).disabled = true

		var blood_effect: GPUParticles2D = blood_effect_scene.instantiate()
		blood_effect.global_position = global_position
		blood_effect.rotation = global_position.angle_to_point(shooter.global_position) + PI
		Global.blood_container.add_child(blood_effect)
		death_sound.play()

		shooter.rpc_id(str(shooter.name).to_int(), "gain_money", money)
		shooter.gain_score(randi_range(1, 10))
		Global.units_alive -= 1

		Global.units.erase(self)

		if spawner:
			spawner.is_last_wave_dead()

		Sprite.material.set_shader_parameter("flash_modifier", 0.0)

		if randi_range(0, 1) == 0: #todo: increase drop rate (low drop rate to test)
			Global.fabric_bonus.spawn_bonus(global_position)

