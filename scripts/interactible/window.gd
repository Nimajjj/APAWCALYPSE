extends Interactible

@export var hit_possible: bool = true

@export var health: int = 3: set = _setter

func _setter(val) -> void:
	health = val
	rpc("_update_sprite_client")

@onready var sprite: Sprite2D = $Sprite2D
@onready var hitbox = $HitBox
@onready var hit_timer = $HitTimer
@onready var interaction_area = $InteractionArea2D


func _ready():
	$Synchronizer/MultiplayerSynchronizer.set_multiplayer_authority(1)
	message = "Press [E] to repair"
	if !multiplayer.is_server():
		rpc_id(1, "_update_sprite_server")
	hit_timer.connect("timeout", Callable(func(): _hit_timer_timeout()))


func _physics_process(_delta):
	if !multiplayer.is_server(): return
	
	for body in interaction_area.get_overlapping_bodies():
		if body is IEnemy && body.state != 2:
			body.state = 2
			body.target = Global.players[0] if Global.players.size() != 0 else body.target
			body.retarget()
			body.path_timer.start()

	for body in hitbox.get_overlapping_bodies():
		if body is IEnemy and body.state == 0:
			if hit_possible:
				if health > 0:
					_take_damage_server()
					hit_timer.start()
			if health == 0:
				body.state = 1



func activate(player: IPlayer) -> void:
	rpc_id(1, "_activate_server", player)


func can_activate(_player: IPlayer) -> bool:
	return health != 3


func _on_area_2d_body_entered(body) -> void :
	if body is IPlayer:
		body.add_interactible(self)


func _on_area_2d_body_exited(body) -> void :
	if body is IPlayer:
		body.remove_interactible(self)


func _hit_timer_timeout() -> void:
	hit_possible = true


@rpc("any_peer")
func _update_sprite_client() -> void:
	sprite.texture.region.position.y = (3 * 32) - health * 32


@rpc("any_peer")
func _activate_server(player) -> void:
	if !multiplayer.is_server():
		Utils.log("Illegaly calling _activate_server! Culprit is " + str(multiplayer.get_remote_sender_id()), Utils.LOG_WARN)
		return
	health += 1
	if health > 3:
		health = 3
	player.money += 10


func _take_damage_server() -> void:
	if !multiplayer.is_server():
		Utils.log("Illegaly calling _take_damage_server! Culprit is " + str(multiplayer.get_remote_sender_id()), Utils.LOG_WARN)
		return

	health -= 1
	if health <= 0:
		health = 0
	hit_possible = false
	rpc("_update_sprite_client")
	_update_sprite_client()


func _on_multiplayer_synchronizer_synchronized() -> void:
	_update_sprite_client()
	rpc("_update_sprite_client")
