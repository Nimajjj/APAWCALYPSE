extends Interactible

var hit_possible: bool = true

@onready var health: int = 3
@onready var sprite: Sprite2D = $Sprite2D
@onready var hitbox = $HitBox
@onready var hit_timer = $HitTimer
@onready var interaction_area = $InteractionArea2D

func _ready():
	message = "Press [E] to repair"
	_update_sprite()
	hit_timer.connect("timeout", Callable(func(): _hit_timer_timeout()))

func _physics_process(delta):
	for body in interaction_area.get_overlapping_bodies():
		if body is IEnemy && body.state != 2:
			body.state = 2
			body.target = Global.players[0]
			body.retarget()
			body.path_timer.start()
	for body in hitbox.get_overlapping_bodies():
		if body is IEnemy and body.state == 0:
			if hit_possible:
				if health > 0:
					take_damage()
					hit_timer.start()
			if health == 0:
				body.state = 1


func activate(player: IPlayer) -> void:
	health += 1
	if health > 3:
		health = 3
	player.money += 10
	_update_sprite()

func take_damage() -> void:
	health -= 1
	if health <= 0:
		health = 0
	hit_possible = false
	_update_sprite()

func can_activate(player: IPlayer) -> bool:
	return health != 3

func _update_sprite() -> void:
	sprite.texture.region.position.y = (3 * 32) - health * 32

func _on_area_2d_body_entered(body) -> void :
	if body is IPlayer:
		body.add_interactible(self)

func _on_area_2d_body_exited(body) -> void :
	if body is IPlayer:
		body.remove_interactible(self)

func _hit_timer_timeout() -> void:
	hit_possible = true
