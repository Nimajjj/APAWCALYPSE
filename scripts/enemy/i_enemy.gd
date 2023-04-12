class_name IEnemy
extends CharacterBody2D

var blood_effect_scene: PackedScene = preload("res://scenes/effects/gpu_blood_effect.tscn")

@onready var Sprite = $Sprite2D
@onready var HealthBar = $HealthBar

@export var max_health: int
@export var speed: int
@export var money: int
@export var damage: int

#var bonus: IBonus = null
var health: int


func _ready():
	HealthBar.visible = false
	HealthBar.max_value = max_health
	HealthBar.value = max_health

func _physics_process(delta):
	_move(delta)


func take_damage(dmg: int, shooter: IPlayer) -> void:
	HealthBar.visible = true
	
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


func dies(shooter: IPlayer) -> void:
	var blood_effect: GPUParticles2D = blood_effect_scene.instantiate()
	blood_effect.global_position = global_position
	blood_effect.rotation = global_position.angle_to_point(shooter.global_position) + PI
	Global.blood_container.add_child(blood_effect)
	
	shooter.gain_money(money)
	shooter.gain_score(randi_range(1, 10))
	Global.units_alive -= 1
	get_parent().get_parent().is_last_wave_dead()
	queue_free()


