extends Control
class_name TitleScreen

@export var prompt_label: Label # "Press any button to start"
@export var fade_duration: float = 0.5
@export var prompt_fade_speed: float = 2.0 # Pulse effect speed
@export var main_menu_scene_path: String
var waiting_for_input: bool = true
var prompt_alpha: float = 1.0

func _ready():
	# Clear any previous player assignments
	reset_players()
	
	# Show prompt
	if prompt_label:
		prompt_label.show()

func _process(delta: float):
	if waiting_for_input and prompt_label:
		# Pulse prompt text
		prompt_alpha = (sin(Time.get_ticks_msec() / 1000.0 * prompt_fade_speed) + 1.0 / 2.0)
		prompt_label.modulate.a = 0.5 + (prompt_alpha * 0.5) # Range 0.5 to 1.0
	
func _input(event: InputEvent) -> void:
	if not waiting_for_input:
		return
	
	var device_id = -2 # No valid input detected yet
	
	# Check for keyboard input
	if event is InputEventKey and event.pressed:
		device_id = -1
		print("TitleScreen: Keyboard detected")
		
	# Check for mouse button
	if event is InputEventMouseButton and event.pressed:
		device_id = -1
		print("TitleScreen: Keyboard detected")
		
	# Check for any controller button
	elif event is InputEventJoypadButton and event.pressed:
		device_id = event.device
		print("TitleScreen: Controller ", device_id," detected (", Input.get_joy_name(device_id), ")")
	
	# If we got input, assign player 0 and proceed
	if device_id != -2: # -2 means no valid input
		assign_player_zero(device_id)

func assign_player_zero(device_id: int):
	waiting_for_input = false
	
	# Join Player 0 with this device
	if GameSettings.join_player(0, device_id):
		print("TitleScreen: Player 0 assigned to device ", device_id)
		transition_to_main_menu()
	else:
		push_error("TitleScreen: Failed to assign Player 0")

func reset_players():
	# Clear all players from previous sessions
	GameSettings.clear_all_players()
	
	# Also clear InputManager
	for i in range(4):
		InputManager.unregister_player(i)
	
	print("TitleScreen: All players cleared")

func transition_to_main_menu():
	# Fade out prmopt
	if prompt_label:
		var tween = create_tween()
		tween.tween_property(prompt_label, "modulate:a", 0.0, fade_duration)
		await tween.finished
	get_tree().change_scene_to_file(main_menu_scene_path)
