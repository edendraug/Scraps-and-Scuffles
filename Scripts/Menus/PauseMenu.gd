extends Control
class_name PauseMenu

@export var resume_button: Button
@export var quit_to_level_select_button: Button
@export var quit_to_main_menu_button: Button

@export var dim_overlay: ColorRect

@export var lobby_path: String
@export var main_menu_path: String

var is_paused: bool = false
var pausing_player_id: int = -1

func _ready():
	# Hide by default
	hide()
	process_mode = Node.PROCESS_MODE_ALWAYS  # Always process even when paused
	
	# Connect buttons
	if resume_button:
		resume_button.pressed.connect(_on_resume_pressed)
	if quit_to_level_select_button:
		quit_to_level_select_button.pressed.connect(_on_quit_to_level_select_pressed)
	if quit_to_main_menu_button:
		quit_to_main_menu_button.pressed.connect(_on_quit_to_main_menu_pressed)

func _input(event: InputEvent):
	# Check for pause input from any player
	for player_id in range(4):  # Check all possible players
		if InputManager.is_action_just_pressed(player_id, "pause"):
			if is_paused:
				resume_game()
			else:
				pause_game(player_id)
			get_viewport().set_input_as_handled()
			break

func pause_game(player_id: int):
	if is_paused:
		return
	
	is_paused = true
	pausing_player_id = player_id
	
	# Pause the game tree
	get_tree().paused = true
	
	# Show pause menu
	show()
	
	# Focus resume button
	if resume_button:
		resume_button.grab_focus()
	
	print("Game paused by Player ", player_id)

func resume_game():
	if not is_paused:
		return
	
	is_paused = false
	pausing_player_id = -1
	
	# Hide menu
	hide()
	
	# Unpause the game tree
	get_tree().paused = false
	
	print("Game resumed")

func _on_resume_pressed():
	resume_game()

func _on_quit_to_level_select_pressed():
	# Unpause before changing scene
	get_tree().paused = false
	is_paused = false
	
	print("Returning to Level Select Lobby")
	get_tree().change_scene_to_file(lobby_path)

func _on_quit_to_main_menu_pressed():
	# Unpause before changing scene
	get_tree().paused = false
	is_paused = false
	
	print("Returning to Main Menu")
	get_tree().change_scene_to_file(main_menu_path)
