@tool
extends Node2D
class_name CharacterDisplay

@export var character_data: CharacterData:
	set(value):
		character_data = value # Update the sprite when the resource changes
		if is_inside_tree():
			_update_sprite_display()
@export var display_position: Vector2
@export var player_scene: PackedScene # Assign Player.tscn here

var player_character : Node2D = null # Reference to the actual player node
var display_sprite: Sprite2D = null # Static icon when not selected
var is_selected: bool = false
var selected_by_player_id: int = -1

signal character_clicked(display: CharacterDisplay)

func _ready() -> void:
	# Store initial position
	if display_position == Vector2.ZERO:
		display_position = global_position
	
	# Create static display sprite
	create_display_sprite()

func create_display_sprite():
	if not character_data or not character_data.icon_sprite:
		return
	
	display_sprite = Sprite2D.new()
	display_sprite.texture = character_data.icon_sprite
	display_sprite.position = Vector2.ZERO
	display_sprite.scale = Vector2(2.0, 2.0)
	add_child(display_sprite)

func _update_sprite_display():
	if display_sprite:
		if character_data and character_data.icon_sprite:
			display_sprite.texture = character_data.icon_sprite
		else:
			display_sprite.texture = null
	else:
		create_display_sprite()
	#if display_sprite:
		#display_sprite.queue_free()
		#display_sprite = null
	#
	#create_display_sprite()

func can_be_selected() -> bool:
	return not is_selected

func select_character(player_id: int) -> bool:
	if is_selected:
		return false
	
	is_selected = true
	selected_by_player_id = player_id
	
	# Remove static sprite
	if display_sprite:
		display_sprite.queue_free()
		display_sprite = null
	
	# Instantiate actual player
	if player_scene:
		player_character = player_scene.instantiate()
		add_child(player_character)
		player_character.global_position = display_position
	
		# Assign player_id
		if "player_id" in player_character:
			player_character.player_id = player_id
	
		# Swap sprite sheet
		if player_character.has_node("SpriteManager"):
			var sprite_manager = player_character.get_node("SpriteManager")
			if sprite_manager.has_method("set_sprite_sheet"):
				sprite_manager.set_sprite_sheet(character_data.sprite_sheet)
			
	
		# Enable player controls initially
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
	selected_by_player_id = -1
	
	# Remove player instance
	if player_character:
		player_character.queue_free()
		player_character = null
		
	# Recreate static sprite
	create_display_sprite()
	
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

func handle_click():
	# Emit signal when clicked
	character_clicked.emit(self)
