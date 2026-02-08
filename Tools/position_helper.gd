@tool
extends Node2D

@onready var label = $Label

func _process(delta: float) -> void:
	#if Engine.is_editor_hint():
	label.text = str(Vector2(snappedf(global_position.x, 0.5), snappedf(global_position.y, 0.5)))
	
