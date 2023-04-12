extends Interactible

@export var price: int = 100
@export var weapon_scene: PackedScene = null

var weapon : IWeapon = null

func _ready():
	weapon = weapon_scene.instantiate()
	message = "Press E to buy {0} for {1}$".format([weapon.name, price])
	add_child(weapon)


func activate(player: IPlayer) -> void:
	if can_activate(player) :
		player.money -= price
		player.add_weapon(weapon)


func can_activate(player: IPlayer) -> bool:
	return player.money >= price


func _on_area_2d_body_entered(body) -> void :
	if body is IPlayer:
		body.add_interactible(self)


func _on_area_2d_body_exited(body) -> void :
	if body is IPlayer:
		body.remove_interactible(self)



