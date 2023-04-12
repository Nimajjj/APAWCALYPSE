extends Node

var version: String = "APAWCALYPSE - dev"

var game: Game = null
var map: Map = null
var in_game_ui: CanvasLayer = null

var players: Array[IPlayer] = []
var spawners: Array[ISpawner] = []
var units: Array[IEnemy] = []

var units_left_to_spawn: int = 3
var units_alive: int = 0

func is_all_units_spawned() -> bool:
	return units_left_to_spawn == 0
	
func is_all_units_dead() -> bool:
	return units_alive == 0
