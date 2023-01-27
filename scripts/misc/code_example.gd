class_name PC
extends CharacterBody2D
# Player Character main class
# [Curently in progress]

signal player_die

const MAX_SPEED: float = 650.0
const ACCELERATION: float = 0.25
const FRICTION: float = 0.15

@export var health: float = 100.0

var in_contact: Array[StaticBody2D] = []

@onready var AnimPlayer: AnimationPlayer = $AnimationPlayer
@onready var Camera: Camera2D = $Camera2D
@onready var HealthBar: ProgressBar = $Camera2D/InGameUI/HealthProgressBar


func _ready():
	Camera.current = true


func _physics_process(_delta):
	_movement_handler()


# Handle PC movements and apply Walk aninimation
# use facing direction, acceleration and friction
# @see _get_direction()
func _movement_handler() -> void :
	var direction = _get_direction()
	
	if direction.length() > 0:
		velocity = lerp(velocity, direction * MAX_SPEED, ACCELERATION)
		AnimPlayer.play("walk")
	else:
		velocity = lerp(velocity, Vector2.ZERO, FRICTION)
		AnimPlayer.stop()
	
	move_and_slide()


# Calcul PC facing direction
# Returned direction is normalized
# Direction is compute from action_strength of 4 base axises
func _get_direction() -> Vector2:
	var d: Vector2 = Vector2.ZERO
	
	d.x = Input.get_action_strength("right") - Input.get_action_strength("left")
	d.y = Input.get_action_strength("down") - Input.get_action_strength("up")
	
	return d.normalized()
	

# Register enemy if it enter in contact with HurtBox
func _on_hurt_box_body_entered(body) -> void:
	in_contact.push_back(body)


# Remove from _in)contact Array enemy if it exit the HurtBox zone
func _on_hurt_box_body_exited(body) -> void:
	in_contact.erase(body)


# Each Timer timeout take damage from each enemy in contact with the PC
# @see _on_hurt_box_body_entered(body)
# @see _on_hurt_box_body_exited(body)
func _on_timer_timeout() -> void:
	for body in in_contact:
		if (body.is_in_group("enemies")):
			health -= 9
			HealthBar.value = health
			
			if (health <= 0):
				emit_signal("dead")
