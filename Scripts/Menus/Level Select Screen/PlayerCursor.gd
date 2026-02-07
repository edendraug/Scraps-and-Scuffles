extends Node2D
class_name PlayerCursor

@export var player_id: int = 0
@export var cursor_speed: float = 500.0
@export var cursor_sprite: Sprite2D
@export var player_color: Color = Color.WHITE # Unique color per player

var is_active: bool = true
var hovered_character: CharacterDisplay = null

signal character_selected(player_id: int, character: CharacterDisplay)

func _ready() -> void:
	if cursor_sprite:
		cursor_sprite.modulate = player_color
	# Start at screen center or spawn position
	global_position = get_viewport_rect().size / 2

func _process(delta: float) -> void:
	if not is_active:
		return
	
	# Move cursor with joystick or mouse
	var input_dir = get_cursor_input()
	global_position += input_dir * cursor_speed * delta
	
	# Clamp to screen bounds
	#var viewport_size = get_viewport_rect().size
	#global_position.x = clamp(global_position.x, 0, viewport_size.x)
	#global_position.y = clamp(global_position.y, 0, viewport_size.y)
	
	# Check for selection input
	if InputManager.is_action_just_pressed(player_id, "confirm"):
		print("Confirm pressed")
		attempt_select_character()

func get_cursor_input() -> Vector2:
	# Use left stick for cursor movement
	var input = Vector2(
		InputManager.get_axis(player_id, "move_left", "move_right"),
		InputManager.get_axis(player_id, "look_up", "look_down")
	)
	
	# Fallback to mouse for player 0 (if keyboard/mouse)
	if player_id == 0 and input.length() < 0.1:
		var mouse_pos = get_global_mouse_position()
		# Just snap cursor to mouse
		global_position = mouse_pos
		return Vector2.ZERO
	
	return input

func attempt_select_character():
	if not hovered_character:
		return
	
	if not hovered_character.can_be_selected():
		print("Character already selected")
		return
	
	# Select the character
	if hovered_character.select_character(player_id):
		character_selected.emit(player_id, hovered_character)
		deactivate_cursor()

func deactivate_cursor():
	is_active = false
	hide()

func activate_cursor():
	is_active = true
	show()

func _on_area_entered(area: Area2D):
	# Detect when hovering over character
	if not area or not is_instance_valid(area):
		return
	
	var parent = area.get_parent()
	if parent is CharacterDisplay:
		hovered_character = parent
		# TODO: Visual feeback
		cursor_sprite.scale = Vector2(1.3, 1.3)
		print("Hovering: ", hovered_character.character_data.character_name)

func _on_area_exited(area: Area2D):
	if not area or not is_instance_valid(area):
		return
	
	var parent = area.get_parent()
	if parent == hovered_character:
		cursor_sprite.scale = Vector2(1.0, 1.0)
		hovered_character = null
