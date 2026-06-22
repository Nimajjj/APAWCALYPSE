extends Node

var version: String = "APAWCALYPSE - dev"

var game: Game = null
var map: Map = null
var in_game_ui: CanvasLayer = null
var blood_container: Node2D = null
var fabric_bonus: Node2D = null


var players: Array[IPlayer] = []
var spawners: Array[ISpawner] = []
var units: Array[IEnemy] = []

var units_left_to_spawn: int = 3
var units_alive: int = 0


func is_all_units_spawned() -> bool:
	return units_left_to_spawn == 0

func is_all_units_dead() -> bool:
	return units_alive == 0


## Appele a la mort d'un ennemi (remplace l'ancien couplage fragile
## get_parent().get_parent().is_last_wave_dead() cote ennemi). Declenche la
## vague suivante quand tous les ennemis sont spawnes ET morts.
func notify_enemy_died() -> void:
	if game != null and is_all_units_spawned() and is_all_units_dead():
		game.wave_activated = false
		game.new_wave()


## Reinitialise l'etat inter-parties. Indispensable avant un redemarrage :
## cet autoload survit a reload_current_scene() et garderait sinon des
## references invalides (anciens joueurs/ennemis liberes).
func reset() -> void:
	players.clear()
	spawners.clear()
	units.clear()
	units_left_to_spawn = 3
	units_alive = 0
