extends Node

const LOG_INFO: String = "INFO"
const LOG_DEBUG: String = "DEBUG"
const LOG_WARN: String = "WARN"
const LOG_ERR: String = "ERR"

func log(txt: String, lvl: String = LOG_DEBUG) -> void:
	var uid = "server\t  " if multiplayer.get_unique_id() == 1 else multiplayer.get_unique_id()
	
	var text: String = "uid.{0} - [{1}]: {2}".format([
		uid,
		lvl,
		txt,
	])
	
	print(text)
