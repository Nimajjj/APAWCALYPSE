extends SceneTree
## Suite de tests native (sans addon, respecte la regle "pas de dependance tierce").
## Lancer :
##   <godot> --headless --path <projet> --script res://tests/test_runner.gd
## Code de sortie 0 si tout passe, 1 sinon. Le fichier de sauvegarde du joueur
## est sauvegarde puis restaure (les tests ne l'ecrasent pas durablement).

var _pass: int = 0
var _fail: int = 0


func _check(label: String, cond: bool) -> void:
	if cond:
		_pass += 1
		print("  PASS  ", label)
	else:
		_fail += 1
		print("  FAIL  ", label)


func _initialize() -> void:
	var sm := get_root().get_node_or_null("SaveManager")
	var am := get_root().get_node_or_null("AchievementManager")
	if sm == null or am == null:
		print("autoloads indisponibles"); quit(1); return

	var had := FileAccess.file_exists(sm.SAVE_PATH)
	var original: PackedByteArray = FileAccess.get_file_as_bytes(sm.SAVE_PATH) if had else PackedByteArray()

	print("== SaveManager ==")
	sm.reset()
	_check("reset: high_score=0", sm.high_score == 0)
	_check("reset: coins=0", sm.coins == 0)
	_check("reset: seul badaboom debloque", sm.unlocked_characters.size() == 1 and sm.is_character_unlocked("badaboom"))
	_check("reset: selected=badaboom", sm.selected_character == "badaboom")

	var r1: Dictionary = sm.record_run(100, 3, 5, 200)
	_check("record_run: high_score=100", sm.high_score == 100)
	_check("record_run: best_wave=3", sm.best_wave == 3)
	_check("record_run: total_kills=5", sm.total_kills == 5)
	_check("record_run: coins=20 (200/10)", sm.coins == 20)
	_check("record_run: new_high_score=true", r1.new_high_score == true)
	var r2: Dictionary = sm.record_run(50, 2, 1, 0)
	_check("record_run inferieur: high_score reste 100", sm.high_score == 100)
	_check("record_run inferieur: new_high_score=false", r2.new_high_score == false)

	print("== Personnages ==")
	sm.reset()
	sm.coins = 1000
	_check("buy blade (600) ok", sm.buy_character("blade") == true)
	_check("buy blade: coins=400", sm.coins == 400)
	_check("buy blade: debloque", sm.is_character_unlocked("blade"))
	_check("buy grey (1500) refuse (solde insuffisant)", sm.buy_character("grey") == false)
	sm.select_character("blade")
	_check("select blade", sm.selected_character == "blade")
	_check("scene = blade.tscn", sm.get_selected_character_scene() == "res://scenes/player/blade.tscn")

	print("== Reglages : persistance disque ==")
	sm.reset()
	sm.set_slider("music", 80.0)
	sm.high_score = -1
	sm.load_game()
	_check("slider music persiste a 80", sm.get_slider("music") == 80.0)

	print("== Succes ==")
	sm.reset()
	am.on_wave_reached(5)
	_check("vague 5 -> survivor", sm.is_unlocked("survivor"))
	am.on_wave_reached(20)
	_check("vague 20 -> immortal", sm.is_unlocked("immortal"))
	am.on_enemy_killed(false, 50)
	_check("50 kills cumules -> hunter", sm.is_unlocked("hunter"))
	am.on_enemy_killed(true, 51)
	_check("boss tue -> boss_slayer", sm.is_unlocked("boss_slayer"))
	for id in sm.CHARACTERS:
		sm.unlocked_characters[id] = true
	am.on_character_bought()
	_check("tous persos debloques -> collector", sm.is_unlocked("collector"))

	# Restauration du fichier joueur d'origine.
	sm.reset()
	if had:
		var f := FileAccess.open(sm.SAVE_PATH, FileAccess.WRITE)
		f.store_buffer(original)
		f.close()
	elif FileAccess.file_exists(sm.SAVE_PATH):
		DirAccess.remove_absolute(sm.SAVE_PATH)

	print("")
	print("RESULTAT: %d PASS / %d FAIL" % [_pass, _fail])
	quit(0 if _fail == 0 else 1)
