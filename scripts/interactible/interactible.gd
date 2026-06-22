class_name Interactible
extends Node2D

var message: String = ""

func activate(_player: IPlayer) -> void:
	pass


func can_activate(_player: IPlayer) -> bool:
	return false
