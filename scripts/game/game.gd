class_name Game
extends Node2D

var score: int = 0
var wave: int = 0
var wave_activated: bool = false
var spawners_activated: bool = false
var time: float = 0.0
var enabled_spawner: int = 0
var kills: int = 0
var run_money_earned: int = 0
var _game_over: bool = false

const GameOverLayer := preload("res://scripts/ui/game_over_layer.gd")

@onready var GameTimer: Timer = $GameTimer
@onready var WaveTimer: Timer = $WaveTimer
@onready var FabricPlayer: Node2D = $FabricPlayer

func _enter_tree():
	Global.game = self
	
func _ready():
	# Reactions aux evenements de jeu (decouple des emetteurs via EventBus).
	EventBus.enemy_killed.connect(_on_enemy_killed)
	EventBus.score_gained.connect(_on_score_gained)
	EventBus.money_gained.connect(_on_money_gained)
	EventBus.player_died.connect(trigger_game_over)
	start_game()


func _on_enemy_killed(is_boss: bool) -> void:
	kills += 1
	AchievementManager.on_enemy_killed(is_boss, kills)


func _on_score_gained(amount: int) -> void:
	score += amount


func _on_money_gained(amount: int) -> void:
	run_money_earned += amount
	
func start_game() -> void:
	Global.reset()
	_new_player()
	GameTimer.start()
	
	var spawners := get_tree().get_nodes_in_group("spawners")
	for spawner in spawners:
		Global.spawners.append(spawner as ISpawner)
					
	new_wave()

func new_wave():
	if !wave_activated:
		WaveTimer.start()
		wave_activated = true
		spawners_activated = false
		wave += 1
		EventBus.wave_started.emit(wave)
		enabled_spawner = 0
		for spawner in Global.spawners:
			if spawner.enabled:
				enabled_spawner += 1
		Global.units_left_to_spawn = enabled_spawner * 3 * wave
	
func end_game() -> void:
	wave = 0
	time = 0.0
	score = 0

func trigger_game_over() -> void:
	if _game_over:
		return
	_game_over = true
	var result := SaveManager.record_run(score, wave, kills, run_money_earned)
	AchievementManager.on_run_recorded()
	get_tree().paused = true
	var layer := GameOverLayer.new()
	add_child(layer)
	layer.setup({
		"wave": wave, "score": score, "kills": kills,
		"high_score": SaveManager.high_score, "best_wave": SaveManager.best_wave,
		"new_high_score": result.new_high_score, "new_best_wave": result.new_best_wave,
	})

func _new_player() -> void:
	FabricPlayer.create_player()
	
	
func _on_game_timer_timeout():
	time += 0.1
	
func _on_wave_timer_timeout():
	if !spawners_activated:
		# Garde anti-crash : randi() % 0 lève une erreur "Division by zero".
		# En jeu normal la map active >= 1 spawner, mais on protege le cas limite
		# (aucun spawner active) qui sinon ferait planter le moteur.
		if enabled_spawner <= 0:
			return
		var boss_spawn = randi() % enabled_spawner
		var spawner_index = 0
		for spawner in Global.spawners:
			if spawner.enabled:
				if spawner_index == boss_spawn && wave % 5 == 0:
					spawner.start_spawner(Global.units_left_to_spawn / enabled_spawner, true)
				else:
					spawner.start_spawner(Global.units_left_to_spawn / enabled_spawner, false)
				spawner_index += 1
		spawners_activated = true
