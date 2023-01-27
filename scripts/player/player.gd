extends CharacterBody2D

enum PC_State { IDLE, MOVE, INTERACT, DOWN, DEAD, RELOAD }

var id: int
var state: PC_State = PC_State.IDLE
var health: float
var max_health: float
var regeneration: float
var money: int = 0
var speed: float = 200
var acceleration: float = 0.3
var friction: float = 0.1
#var ability: Ability
#var special_consumable: SpecialConsumable
#var weapon: Weapon
var aiming_at: Vector2
#var active_bonus: Array(Bonus)

@onready var AnimPlayer = $AnimationPlayer


func _physics_process(_delta):
	_move()


func use_ability() -> void:
	pass


func start_shooting() -> void:
	pass


func stop_shooting() -> void:
	pass


#func add_bonus(bonus: Bonus) -> void:
#	active_bonus.append(bonus)
#
#
#func add_special_consumable(consumable: SpecialConsumable) -> void:
#	special_consumable = consumable
#
#
#func add_weapon(new_weapon: Weapon) -> void:
#	weapon = new_weapon
#
#
#func drop_weapon() -> void:
#	weapon = null


func _move() -> void:
	var direction = Vector2.ZERO;
	
	direction.x = Input.get_action_strength("move_right") - Input.get_action_strength("move_left");
	direction.y = Input.get_action_strength("move_down") - Input.get_action_strength("move_up");
	
	if direction.length() > 0:
		velocity = lerp(velocity, direction.normalized() * speed, acceleration);
	else:
		velocity = lerp(velocity, Vector2.ZERO, friction);
	move_and_slide()
	
	
func _inputs_manager() -> void:
	pass
