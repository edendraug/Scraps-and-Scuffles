@tool
extends Node2D
class_name PositionHelper

var label: Label
@export var label_offset: Vector2 = Vector2(9.0, -13.0)

@export var radius: float = 5.0:
	set(value):
		radius = value
		queue_redraw()

@export var color: Color = Color.WHITE:
	set(value):
		color = value
		queue_redraw()

func _enter_tree():
	if has_node("PositionLabel"):
		return
	
	label = Label.new()
	label.name = "PositionLabel"
	add_child(label)
	label.owner = get_tree().edited_scene_root
	

func _draw() -> void:
	draw_circle(Vector2.ZERO, radius, color)

func _process(delta: float) -> void:
	#if Engine.is_editor_hint():
	if !label:
		return
	
	label.position = label_offset
	#label.text = str(Vector2(snappedf(global_position.x, 0.5), snappedf(global_position.y, 0.5)))
	label.text = str(global_position)
