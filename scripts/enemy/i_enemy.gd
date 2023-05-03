class_name IEnemy
extends CharacterBody2D

var blood_effect_scene: PackedScene = preload("res://scenes/effects/gpu_blood_effect.tscn")
var bonus_scene: PackedScene = preload("res://scenes/bonus/i_bonus.tscn")

var dead: bool = false
var slowed: bool = false

@onready var Sprite = $Sprite2D
@onready var HealthBar = $HealthBar
@onready var timer = $Timer
@onready var slow_timer = $SlowTimer

@export var max_health: int
@export var speed_stock: int
@export var speed: int
@export var money: int
@export var damage: int
@export var knockback_force: float = 0
@export var knockback_direction: Vector2 = Vector2.ZERO

#var bonus: IBonus = null
var health: int


func _ready():
	HealthBar.visible = false
	HealthBar.max_value = max_health
	HealthBar.value = max_health
	speed_stock = speed
	
	
	Sprite.material = Sprite.material.duplicate()
	timer.connect("timeout", func():
		Sprite.material.set_shader_parameter("flash_modifier", 0.0)
	)
	slow_timer.connect("timeout", func(): slow_timeout())

func _physics_process(delta):
	_move(delta)


func take_damage(dmg: int, shooter: IPlayer) -> void:
	HealthBar.visible = true
	Sprite.material.set_shader_parameter("flash_modifier", 1.0)
	timer.start()
	
	slow()
	
	health -= dmg
	if health <= 0:
		dies(shooter)
		
	HealthBar.value = health

func _move(delta) -> void:
	var target = Global.players[0]
	var _direction = (target.global_position - global_position).normalized()
	if _direction.x < 0:
		Sprite.flip_h = false
	elif _direction.x > 0:
		Sprite.flip_h = true
	var _velocity = _direction * speed * delta
	position += _velocity

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

func dies(shooter: IPlayer) -> void:
	if not dead:
		dead = true
		var blood_effect: GPUParticles2D = blood_effect_scene.instantiate()
		blood_effect.global_position = global_position
		blood_effect.rotation = global_position.angle_to_point(shooter.global_position) + PI
		Global.blood_container.add_child(blood_effect)
		
		shooter.gain_money(money)
		shooter.gain_score(randi_range(1, 10))
		Global.units_alive -= 1
		get_parent().get_parent().is_last_wave_dead()
		
		Sprite.material.set_shader_parameter("flash_modifier", 0.0)

		if randi_range(0, 1) == 0: #todo: increase drop rate (low drop rate to test)
			print("spawn bonus")
			Global.fabric_bonus.spawn_bonus(global_position)
		
		queue_free()
