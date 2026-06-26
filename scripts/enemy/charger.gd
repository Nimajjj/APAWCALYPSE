extends IEnemy
## Charger (inspire Brotato) : avance normalement puis effectue periodiquement une
## charge eclair vers le joueur (pic de vitesse + flash d'avertissement).

@export var charge_interval: float = 3.0
@export var charge_duration: float = 0.55
@export var charge_multiplier: float = 3.4

var _t: float = 0.0
var _charging: bool = false


func _physics_process(delta: float) -> void:
	super(delta)
	if dead or _charging:
		return
	_t += delta
	if _t >= charge_interval and chase_target != null:
		_do_charge()


func _do_charge() -> void:
	_charging = true
	_t = 0.0
	var base: int = speed
	speed = int(base * charge_multiplier)
	# Flash d'avertissement (jaune) le temps de la charge.
	Sprite.material.set_shader_parameter("flash_color", Color(1, 0.85, 0.2, 1))
	Sprite.material.set_shader_parameter("flash_modifier", 0.6)
	await get_tree().create_timer(charge_duration).timeout
	if is_instance_valid(self) and not dead:
		speed = base
		Sprite.material.set_shader_parameter("flash_modifier", 0.0)
		Sprite.material.set_shader_parameter("flash_color", Color(1, 1, 1, 1))
	_charging = false
