extends Node
## Persistance de la progression long terme dans user://save.cfg.
## Ne stocke que des statistiques de jeu (aucune donnee sensible).

const SAVE_PATH := "user://save.cfg"

const DEFAULT_CHARACTER := "badaboom"
const CHARACTERS := {
	"badaboom": {"name": "Bada-Boom", "scene": "res://scenes/player/bada-boom.tscn", "price": 0},
	"blade": {"name": "Blade", "scene": "res://scenes/player/blade.tscn", "price": 600},
	"candy": {"name": "Candy", "scene": "res://scenes/player/candy.tscn", "price": 1000},
	"grey": {"name": "Grey", "scene": "res://scenes/player/grey.tscn", "price": 1500},
}

const MODIFIERS := {
	"double_enemies": {"name": "Double Ennemis", "desc": "2x plus d'ennemis par vague"},
	"double_money": {"name": "Double Argent", "desc": "Gains d'argent x2"},
}

var high_score: int = 0
var best_wave: int = 0
var total_kills: int = 0
var total_money: int = 0
var games_played: int = 0
var total_play_time: float = 0.0
var total_shots_fired: int = 0
var total_shots_hit: int = 0
var unlocked: Dictionary = {}  # id_succes -> true
var sliders: Dictionary = {"music": 50.0, "sfx": 50.0, "gui": 50.0}  # reglages volume (0-100)
var coins: int = 0  # monnaie meta depensable (gagnee en jouant)
var unlocked_characters: Dictionary = {"badaboom": true}
var selected_character: String = DEFAULT_CHARACTER
var active_modifiers: Dictionary = {}  # id_modificateur -> true


func _ready() -> void:
	load_game()


func load_game() -> void:
	var cfg := ConfigFile.new()
	var err := cfg.load(SAVE_PATH)
	if err != OK:
		return  # pas encore de sauvegarde : on garde les valeurs par defaut
	high_score = int(cfg.get_value("stats", "high_score", 0))
	best_wave = int(cfg.get_value("stats", "best_wave", 0))
	total_kills = int(cfg.get_value("stats", "total_kills", 0))
	total_money = int(cfg.get_value("stats", "total_money", 0))
	games_played = int(cfg.get_value("stats", "games_played", 0))
	total_play_time = float(cfg.get_value("stats", "total_play_time", 0.0))
	total_shots_fired = int(cfg.get_value("stats", "total_shots_fired", 0))
	total_shots_hit = int(cfg.get_value("stats", "total_shots_hit", 0))
	var u: Variant = cfg.get_value("achievements", "unlocked", {})
	if u is Dictionary:
		unlocked = u
	var s: Variant = cfg.get_value("settings", "sliders", {})
	if s is Dictionary:
		for k in sliders.keys():
			if s.has(k):
				sliders[k] = float(s[k])
	coins = int(cfg.get_value("progression", "coins", 0))
	var uc: Variant = cfg.get_value("progression", "unlocked_characters", {})
	if uc is Dictionary:
		for k in uc:
			unlocked_characters[k] = true
	unlocked_characters[DEFAULT_CHARACTER] = true
	selected_character = str(cfg.get_value("progression", "selected_character", DEFAULT_CHARACTER))
	var am2: Variant = cfg.get_value("modifiers", "active", {})
	if am2 is Dictionary:
		active_modifiers = am2


func save_game() -> void:
	var cfg := ConfigFile.new()
	cfg.set_value("stats", "high_score", high_score)
	cfg.set_value("stats", "best_wave", best_wave)
	cfg.set_value("stats", "total_kills", total_kills)
	cfg.set_value("stats", "total_money", total_money)
	cfg.set_value("stats", "games_played", games_played)
	cfg.set_value("stats", "total_play_time", total_play_time)
	cfg.set_value("stats", "total_shots_fired", total_shots_fired)
	cfg.set_value("stats", "total_shots_hit", total_shots_hit)
	cfg.set_value("achievements", "unlocked", unlocked)
	cfg.set_value("settings", "sliders", sliders)
	cfg.set_value("progression", "coins", coins)
	cfg.set_value("progression", "unlocked_characters", unlocked_characters)
	cfg.set_value("progression", "selected_character", selected_character)
	cfg.set_value("modifiers", "active", active_modifiers)
	var err := cfg.save(SAVE_PATH)
	if err != OK:
		push_warning("SaveManager: echec de la sauvegarde (code %d)" % err)


## Enregistre une partie terminee. Retourne les records battus.
func record_run(score: int, wave: int, kills: int, money: int) -> Dictionary:
	var new_high := score > high_score
	var new_best_wave := wave > best_wave
	if new_high:
		high_score = score
	if new_best_wave:
		best_wave = wave
	total_kills += kills
	total_money += money
	games_played += 1
	var coins_earned := int(money / 10.0)
	coins += coins_earned
	save_game()
	return {"new_high_score": new_high, "new_best_wave": new_best_wave, "coins_earned": coins_earned}


func add_session_stats(play_time: float, shots_fired: int, shots_hit: int) -> void:
	total_play_time += play_time
	total_shots_fired += shots_fired
	total_shots_hit += shots_hit
	save_game()


func accuracy_percent() -> float:
	if total_shots_fired <= 0:
		return 0.0
	return float(total_shots_hit) / float(total_shots_fired) * 100.0


func get_slider(group: String) -> float:
	return sliders.get(group, 50.0)


func set_slider(group: String, value: float) -> void:
	sliders[group] = value
	save_game()


func is_character_unlocked(id: String) -> bool:
	return unlocked_characters.get(id, false)


func buy_character(id: String) -> bool:
	if not CHARACTERS.has(id) or is_character_unlocked(id):
		return false
	var price: int = CHARACTERS[id].price
	if coins < price:
		return false
	coins -= price
	unlocked_characters[id] = true
	save_game()
	return true


func select_character(id: String) -> void:
	if is_character_unlocked(id):
		selected_character = id
		save_game()


func get_selected_character_scene() -> String:
	var id := selected_character
	if not is_character_unlocked(id):
		id = DEFAULT_CHARACTER
	return CHARACTERS.get(id, CHARACTERS[DEFAULT_CHARACTER]).scene


func is_unlocked(id: String) -> bool:
	return unlocked.get(id, false)


func mark_unlocked(id: String) -> void:
	unlocked[id] = true
	save_game()


func reset() -> void:
	high_score = 0
	best_wave = 0
	total_kills = 0
	total_money = 0
	games_played = 0
	total_play_time = 0.0
	total_shots_fired = 0
	total_shots_hit = 0
	unlocked = {}
	sliders = {"music": 50.0, "sfx": 50.0, "gui": 50.0}
	coins = 0
	unlocked_characters = {"badaboom": true}
	selected_character = DEFAULT_CHARACTER
	active_modifiers = {}
	save_game()


func is_modifier_active(id: String) -> bool:
	return active_modifiers.get(id, false)


func toggle_modifier(id: String) -> void:
	active_modifiers[id] = not is_modifier_active(id)
	save_game()
