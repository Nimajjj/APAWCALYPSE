extends Interactible

@export var price: int = 300
@export var nextGain: float = 0.05
@export var minReloadFactor: float = 0.5

func _ready():
	message = "Press [E] to buy reload up bonus for {0}$ (-{1}% RELOAD TIME)".format([price, nextGain*100])

func activate(player: IPlayer) -> void:
	if can_activate(player) :
		player.money -= price
		player.reload_factor -= snappedf(nextGain, 0.01)

		# Increase the price
		price = floor(price * 1.2)
		$AudioStreamPlayer.play()
		if(player.reload_factor > minReloadFactor):
			message = "Press [E] to buy reload up bonus for {0}$ (-{1}% RELOAD TIME)".format([price, snappedf(nextGain*100, 0.01)])
		else:
			message = "You already have the max reload up bonus (-{0}% RELOAD TIME)".format([snappedf(player.reload_factor*100, 0.01)])
		_on_interaction_area_2d_body_exited(player)
		_on_interaction_area_2d_body_entered(player)


func can_activate(player: IPlayer) -> bool:
	return player.money >= price && player.reload_factor > minReloadFactor


func _on_interaction_area_2d_body_entered(body):
	if body is IPlayer:
		body.add_interactible(self)


func _on_interaction_area_2d_body_exited(body):
	if body is IPlayer:
		body.remove_interactible(self)
