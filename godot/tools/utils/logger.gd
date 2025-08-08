@tool
extends Object
class_name Logger

var path: String
var name: String

func _init(_path: String, _name: String) -> void:
	path = _path
	name = _name

## Log with a timestamp and the configured name prefix.
func log(message: String) -> void:
	var log_file: FileAccess = FileAccess.open(path, FileAccess.WRITE_READ)
	if log_file:
		log_file.seek_end()
		var success: bool = log_file.store_line("%s [%s]: %s" % [Time.get_datetime_string_from_system(), name, message])
		if not success:
			push_error("Failed to write to log file: %s" % path)
		log_file.close()
	else:
		push_error("Failed to open log file for writing: %s" % path)

func print(message: String, should_log: bool = false) -> void:
	# For debugging, we can also print to the console.
	print("%s [%s]: %s" % [Time.get_datetime_string_from_system(), name, message])
	if should_log:
		self.log(message)