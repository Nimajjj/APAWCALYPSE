extends Interactible

@export var price: int = 100
@export var open: bool = false
@export var spawner_id: int = -1


func _ready():
	message = "Press [E] to open the door for {0}$".format([price])

func activate(player: IPlayer) -> void:
	if can_activate(player) :
		player.money -= price
		
		rpc_id(1, "_open_server", player)

@rpc("any_peer")
func _open_server(player) -> void:
	var caller_id = multiplayer.get_remote_sender_id()
#	if str(player.name).to_int() != caller_id:
#		print("Illegally calling shoot_server! The culprit is: " + str(caller_id))
#		return
	
	_activate_spawners()
	rpc("_open_client")


@rpc
func _open_client() -> void:
	open = true
	queue_free()
	

func _activate_spawners() -> void:
	print("activate spawners")
	if spawner_id != -1:
		var spawners := get_tree().get_nodes_in_group("spawners")
		for spawner in spawners:
			if spawner.id == spawner_id:
				spawner.enabled = true
				print(spawner_id, " ", spawner.enabled)


func can_activate(player: IPlayer) -> bool:
	return player.money >= price && !open


func _on_area_2d_body_entered(body) -> void :
	if body is IPlayer:
		body.add_interactible(self)


func _on_area_2d_body_exited(body) -> void :
	if body is IPlayer:
		body.remove_interactible(self)
