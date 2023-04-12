extends Interactible

var health: int = 3

@onready var sprite: Sprite2D = $Sprite2D

func _ready():
	message = "Press [E] to repair"
	_update_sprite()


func activate(player: IPlayer) -> void:
	health += 1
	if health > 3:
		health = 3

	player.money += 10

	_update_sprite()


func take_damage(_damage: float = 1) -> void:
	health -= 1
	if health <= 0:
		health = 0


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
