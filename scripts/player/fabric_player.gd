extends Node2D

var players: Array[IPlayer] = []

@export var player_scene: PackedScene
@export var Portrait: TextureRect




func create_player() -> IPlayer:
	# Personnage choisi dans le menu (meta-progression). Fallback sur l'export
	# de la scene si le chargement echoue.
	var ps: PackedScene = load(SaveManager.get_selected_character_scene())
	if ps == null:
		ps = player_scene
	var player: IPlayer = ps.instantiate()

	player.id = Global.players.size()
	Global.players.append(player)
	Global.map.add_child(player)
	player.position = position
	
	return player;


