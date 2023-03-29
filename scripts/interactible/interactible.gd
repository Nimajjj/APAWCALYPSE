class_name Interactible
extends Node2D

var message: String = ""

func activate(player: IPlayer) -> void:
	pass


func can_activate(player: IPlayer) -> bool:
	return false
