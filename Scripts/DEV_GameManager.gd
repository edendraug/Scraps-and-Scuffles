extends Node2D

var level_timer: float = 0.0
const INTERVAL: float = 1.0 # The interval in seconds to perform an action

func _process(delta: float) -> void:
	level_timer += delta

func convert_time_to_string(time_elapsed: float = level_timer) -> String:
	var seconds: int = int(time_elapsed) % 60
	var minutes: int = int(time_elapsed / 60.0) % 60
	var hours: int = int(time_elapsed / 3600.0)
	
	#Format the string to ensure leading zeros (e.g. 01:05 instead of 1:5)
	var time_string: String = "%02d:%02d:%02d" % [hours, minutes, seconds]
	
	return time_string
