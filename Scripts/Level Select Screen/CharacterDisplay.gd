extends Node2D
class_name CharacterDisplay

@export var character_data: CharacterData
@export var display_position: Vector2

var player_character : Node2D = null # Reference to the actual player node
var is_selected: bool = false
var selected_by_player_id: int = -1

# Visual indicator (option highlight)
var selection_indicator: Sprite2D

signal character_clicked(display: CharacterDisplay)

func _ready() -> void:
	# Store initial position
	if display_position == Vector2.ZERO:
		display_position = global_position
	
	# Find the player character node (should be child of this display)
	player_character = get_player_node()
	
	if player_character:
		#Disable player controls initially
		disable_player_controls()
		# Make sure it's at display position
		player_character.global_position = display_position

func get_player_node() -> Node2D:
	# Find CharacterBody2D child
	for child in get_children():
		if child is CharacterBody2D:
			return child
	return null

func can_be_selected() -> bool:
	return not is_selected

func select_character(player_id: int) -> bool:
	if is_selected:
		return false
	
	is_selected = true
	selected_by_player_id = player_id
	
	if player_character:
		# Assign player_id to character
		if "player_id" in player_character:
			player_character.player_id = player_id
		
		# Enable player controls
		enable_player_controls()
		
		# Add to Players group
		if not player_character.is_in_group("Players"):
			player_character.add_to_group("Players")
	
	# Visual feedback
	show_selected_indicator()
	
	print("Character '", character_data.character_name, "' selected by Player ", player_id)
	return true

func deselect_character():
	if not is_selected:
		return
	
	print("Character '", character_data.character_name, "' deselected")
	
	is_selected = false
	var prev_player_id = selected_by_player_id
	selected_by_player_id = -1
	
	if player_character:
		# Disable controls
		disable_player_controls()
		
		# Teleport back to display position
		player_character.global_position = display_position
		
		# Reset velocity if applicable
		if player_character is CharacterBody2D:
			player_character.velocity = Vector2.ZERO
		
		# Remove from Players group
		if player_character.is_in_group("Players"):
			player_character.remove_from_group("Players")
		
		# Clear player_id
		if "player_id" in player_character:
			player_character.player_id = -1
	
	# Hide selection indicator
	hide_selected_indicator()

func disable_player_controls():
	if not player_character:
		return
	
	# Disable physics processing
	player_character.set_physics_process(false)
	player_character.set_process(false)
	
	# If using CharacterBody2D, stop movement
	if player_character is CharacterBody2D:
		player_character.velocity = Vector2.ZERO

func enable_player_controls():
	if not player_character:
		return
	
	# Enable physics processing
	player_character.set_physics_process(true)
	player_character.set_process(true)

func show_selected_indicator():
	# TODO: Add visual feedback (highlight, glow, color change, etc.)
	if player_character and "modulate" in player_character:
		player_character.modulate = Color(1.2, 1.2, 1.2) # Slight brightness increase

func hide_selected_indicator():
	# TODO: Add visual feedback (highlight, glow, color change, etc.)
	if player_character and "modulate" in player_character:
		player_character.modulate = Color(1, 1, 1) # Normal brightness

func handle_cliock():
	# Emit signal when clicked
	character_clicked.emit(self)
