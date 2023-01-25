extends CharacterBody2D

var id: int
enum PC_State { IDLE, MOVE, INTERACT, DOWN, DEAD, RELOAD }
var state: PC_State = PC_State.IDLE
var health: float
var max_health: float
var regeneration: float
var money: int = 0
var velocity: Vector2 = Vector2.ZERO
var speed: float
var acceleration: float
var friction: float
var ability: Ability
var special_consumable: SpecialConsumable
var weapon: Weapon
var aiming_at: Vector2
var active_bonus: Array(Bonus)

func use_ability():
	pass

func start_shooting():
	pass

func stop_shooting():
	pass

func add_bonus(bonus: Bonus):
	active_bonus.append(bonus)

func add_special_consumable(consumable: SpecialConsumable):
	special_consumable = consumable

func add_weapon(new_weapon: Weapon):
	weapon = new_weapon

func drop_weapon():
	weapon = null

