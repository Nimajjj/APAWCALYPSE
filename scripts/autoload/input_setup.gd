extends Node
## Configure les entrees manette par defaut et applique les remaps clavier
## sauvegardes. Charge apres SaveManager (ordre des autoloads).

const REBINDABLE := ["move_up", "move_down", "move_left", "move_right", "shoot", "reload", "interact"]


func _ready() -> void:
	_setup_gamepad()
	_apply_saved_bindings()


func _setup_gamepad() -> void:
	_add_joy_button("shoot", JOY_BUTTON_A)
	_add_joy_button("reload", JOY_BUTTON_X)
	_add_joy_button("interact", JOY_BUTTON_B)
	_add_joy_button("ability_dash", JOY_BUTTON_RIGHT_SHOULDER)
	_add_joy_button("ability_fire", JOY_BUTTON_LEFT_SHOULDER)
	_add_joy_button("esc", JOY_BUTTON_START)
	_add_joy_button("move_up", JOY_BUTTON_DPAD_UP)
	_add_joy_button("move_down", JOY_BUTTON_DPAD_DOWN)
	_add_joy_button("move_left", JOY_BUTTON_DPAD_LEFT)
	_add_joy_button("move_right", JOY_BUTTON_DPAD_RIGHT)
	_add_joy_axis("move_up", JOY_AXIS_LEFT_Y, -1.0)
	_add_joy_axis("move_down", JOY_AXIS_LEFT_Y, 1.0)
	_add_joy_axis("move_left", JOY_AXIS_LEFT_X, -1.0)
	_add_joy_axis("move_right", JOY_AXIS_LEFT_X, 1.0)


func _apply_saved_bindings() -> void:
	for action: String in SaveManager.key_bindings:
		if InputMap.has_action(action):
			_set_keyboard_event(action, int(SaveManager.key_bindings[action]))


## Reassigne la touche clavier d'une action, persiste, et l'applique.
func rebind(action: String, physical_keycode: int) -> void:
	if not InputMap.has_action(action):
		return
	_set_keyboard_event(action, physical_keycode)
	SaveManager.key_bindings[action] = physical_keycode
	SaveManager.save_game()


## Libelle de la touche clavier courante d'une action.
func current_key_label(action: String) -> String:
	for e in InputMap.action_get_events(action):
		if e is InputEventKey:
			return OS.get_keycode_string(e.physical_keycode)
	return "-"


func _set_keyboard_event(action: String, physical_keycode: int) -> void:
	for e in InputMap.action_get_events(action):
		if e is InputEventKey:
			InputMap.action_erase_event(action, e)
	var ev := InputEventKey.new()
	ev.physical_keycode = physical_keycode
	InputMap.action_add_event(action, ev)


func _add_joy_button(action: String, button: int) -> void:
	if not InputMap.has_action(action):
		return
	var e := InputEventJoypadButton.new()
	e.button_index = button
	InputMap.action_add_event(action, e)


func _add_joy_axis(action: String, axis: int, value: float) -> void:
	if not InputMap.has_action(action):
		return
	var e := InputEventJoypadMotion.new()
	e.axis = axis
	e.axis_value = value
	InputMap.action_add_event(action, e)
