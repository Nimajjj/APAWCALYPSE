extends Control

enum Console_Level {
	INFO,
	DEBUG,
	WARN,
	FATAL
}

var commands: Array[Command]

@onready var text_edit: TextEdit = $TextEdit
@onready var text_label: RichTextLabel = $TextLabel


func _ready():
	_init_base_cmd()


func _process(_delta):
	if Input.is_action_just_pressed("key_cr"):
		_send_command(text_edit.text.trim_suffix("\n"))


func new_command(command: String, description: String, arg: String, action: Callable) -> void:
	var new_cmd = Command.new()
	new_cmd.name = command
	new_cmd.description = description
	new_cmd.arg = arg
	new_cmd.action = action
	
	commands.append(new_cmd)


func _init_base_cmd() -> void:
	new_command("help", "Display all commands with their description", "None", Callable(self, "_cmd_help"))
	new_command("test", "Test command", "None", Callable(self, "_cmd_test"))
	new_command("test2", "Test command which print an arg in console", "String", Callable(self, "_cmd_test2"))

		
func _send_command(text: String) -> void:
	_print(text.trim_suffix("\n"), Console_Level.DEBUG)
	var found: bool = false
	for cmd in commands:
		if cmd.name == text.split(" ")[0]:
			if cmd.arg == "None":
				cmd.action.call()
			else:
				if text.split(" ").size() > 1:
					cmd.action.call(text.split(" ")[1])
				else:
					_wrong_arg(text)
				
			found = true
			break
			
	if not found:
		_cmd_not_found(text.split(" ")[0])
			
	text_edit.text = ""
	

func _print(msg: String, console_level: Console_Level = Console_Level.DEBUG) -> void:
	var time: Dictionary = Time.get_time_dict_from_system()
	var formatted_time: String = "{0}:{1}:{2}".format([time.hour, time.minute, time.second])
	var level: String
	var color: String
	
	match console_level:
		Console_Level.INFO:
			level = "INFO"
			color = "[color=689d6a]"
		Console_Level.DEBUG:
			level = "DEBUG"
			color = "[color=e0e0e0]"
		Console_Level.WARN:
			level = "WARN"
			color = "[color=#ffdd65]"
		Console_Level.FATAL:
			level = "FATAL"
			color = "[color=#ff5f5f]"
		_:
			level = "UNKOWN"
	
	var text: String = "\n{0} - [{1}] : {2} {3} [/color]".format([formatted_time, level, color, msg])
	text_label.text += text


func _cmd_help(command: String = ""):
	for cmd in commands:
		if cmd.name == command or command == "":
			var formatted_arg: String
			formatted_arg = "<{0}>".format([cmd.arg])
				
			_print("{0} {1} : {2}".format([cmd.name, formatted_arg, cmd.description]), Console_Level.INFO)


func _cmd_test():
	_print("test command", Console_Level.DEBUG)
	
func _cmd_test2(txt: String):
	_print("test command {0}".format([txt]), Console_Level.DEBUG)


func _cmd_not_found(text: String):
	_print("Command \"{0}\" does not exists.".format([text]), Console_Level.WARN)


func _wrong_arg(text: String):
	_print("Command \"{0}\" need an argument".format([text]), Console_Level.WARN)


class Command:
	var name: String
	var description: String
	var arg: String
	var action: Callable
	
