extends Node

# Maximum number of players
const MAX_PLAYERS = 4

# Device assignments (player_id -> device_id)
# -1 = keyboard/mouse, 0+ = joypad device
var player_devices: Array[int] = [-1, -1, -1, -1]

# Track which devices are in use
var active_players: Array[bool] = [false, false, false, false]

# Input action names (these should match you Project Settings > Input Map)
const ACTIONS = {
	"move_left": "move_left",
	"move_right": "move_right",
	"jump": "jump",
	"attack": "attack",
	"build_menu": "build_menu",
	"switch_building_type": "switch_building_type",
	"rotate_building": "rotate_building",
	"confirm_placement": "confirm_placement",
	"cancel_placement": "cancel_placement",
}

const AXES = {
	"move_horizontal": "move_horizontal",
	"move_vertical": "move_vertical",
	"right_stick_horizontal": "right_stick_horizontal",
	"right_stick_vertical": "right_stick_vertical",
}

func _ready():
	# Auto-detect connected joypads
	detect_controllers()
	
	# Listen for controller connections/disconnections
	Input.joy_connection_changed.connect(_on_joy_connection_changed)

func detect_controllers():
	var connected_joypads = Input.get_connected_joypads()
	print("InputManager: Detected %d controller(s)" % connected_joypads.size())
	
	for joypad_id in connected_joypads:
		print(" - Controller %d: %s" % [joypad_id, Input.get_joy_name(joypad_id)])

# === PLAYER MANAGEMENT ===

func register_player(player_id: int, device_id: int = -1) -> bool:
	if player_id < 0 or player_id >= MAX_PLAYERS:
		push_error("InputManager: Invalid player_id %d" % player_id)
		return false
	
	# Auto-assign device if not specified
	if device_id == -1:
		device_id = get_next_available_device()
	
	player_devices[player_id] = device_id
	active_players[player_id] = true
	
	print("InputManager: Player %d registered with device %d (%s)" % [player_id, device_id, get_device_name(device_id)])
	return true

func unregister_player(player_id: int):
	if player_id >= 0 and player_id < MAX_PLAYERS:
		active_players[player_id] = false
		player_devices[player_id] = -1

func get_next_available_device() -> int:
	# Check if keyboard is free
	if -1 not in player_devices:
		# Keyboard taken, try controllers
		var connected = Input.get_connected_joypads()
		for joypad_id in connected:
			if joypad_id not in player_devices:
				return joypad_id
	return -1 # Default to keyboard

func get_device_name(device_id: int) -> String:
	if device_id == -1:
		return "Keyboard/Mouse"
	return Input.get_joy_name(device_id)

# === INPUT QUERIES ===

# Check if action is pressed for specific player
func is_action_pressed(player_id: int, action: String) -> bool:
	if not is_player_active(player_id):
		return false
		
	var device = player_devices[player_id]
	var action_name = get_action_name(action, player_id)
		
	if device == -1:
		# Keyboard/Mouse
		return Input.is_action_pressed(action_name)
	else:
		# Controller
		return Input.is_action_pressed(action_name)

func is_action_just_pressed(player_id: int, action: String) -> bool:
	if not is_player_active(player_id):
		return false
	
	var action_name = get_action_name(action, player_id)
	return Input.is_action_just_pressed(action_name)

func is_action_just_released(player_id: int, action: String) -> bool:
	if not is_player_active(player_id):
		return false
	
	var action_name = get_action_name(action, player_id)
	return Input.is_action_just_released(action_name)

# Get action strength (for analog inputs like triggers)
func get_action_strength(player_id: int, action: String) -> float:
	if not is_player_active(player_id):
		return 0.0
	
	var action_name = get_action_name(action, player_id)
	return Input.is_action_just_pressed(action_name)

# Get axis value (for movement, aiming)
func get_axis(player_id: int, negative_action: String, positive_action: String) -> float:
	if not is_player_active(player_id):
		return 0.0
	
	var device = player_devices[player_id]
	
	if device == 1:
		#Keyboard (digital input)
		return Input.get_axis(
			get_action_name(negative_action, player_id),
			get_action_name(positive_action, player_id)
		)
	else:
		# Controller (analog input with deadzone
		var value = Input.get_axis(
			get_action_name(negative_action, player_id),
			get_action_name(positive_action, player_id),
		)
		return apply_deadzone(value)

# Get 2D vector for movement (e.g., left stick)
func get_vector(player_id: int, left: String, right: String, down: String, up: String) -> Vector2:
	if not is_player_active(player_id):
		return Vector2.ZERO
	
	var x = get_axis(player_id, left, right)
	var y = get_axis(player_id, up, down)
	return Vector2(x, y)

func get_right_stick(player_id: int) -> Vector2:
	if not is_player_active(player_id):
		return Vector2.ZERO
	
	var device = player_devices[player_id]
	
	if device == -1:
		# Mouse position for keyboard players
		return Vector2.ZERO # Or implement mouse-based aiming
	else:
		# Controller right stick
		var x = Input.get_axis(
			get_action_name("ui_get_right_stick_left", player_id),
			get_action_name("ui_get_right_stick_right", player_id)
		)
		var y = Input.get_axis(
			get_action_name("ui_get_right_stick_up", player_id),
			get_action_name("ui_get_right_stick_down", player_id)
		)
		
		var vec = Vector2(x, y)
		return apply_deadzone_vector(vec)

# === HELPER FUNCTIONS ===

func get_action_name(base_action: String, player_id: int) -> String:
	# Player 0 (P1) uses base actions: "jump"
	# Player 1 (P2) uses suffixed: "jump_p2"
	# Player 2 (P3) uses: "jump_p3", etc.
	if player_id == 0:
		return base_action
	else:
		return base_action + "_p" + str(player_id + 1)

func is_player_active(player_id: int ) -> bool:
	if player_id < 0 or player_id >= MAX_PLAYERS:
		return false
	return active_players[player_id]

func get_player_device(player_id: int) -> int:
	if player_id >= 0 and player_id < MAX_PLAYERS:
		return player_devices[player_id]
	return -1

func apply_deadzone(value: float, deadzone: float = 0.2) -> float:
	if abs(value) < deadzone:
		return 0.0
	return value

func apply_deadzone_vector(vec: Vector2, deadzone: float = 0.2) -> Vector2:
	if vec.length() < deadzone:
		return Vector2.ZERO
	return vec

# === CONTROLLER EVENTS ===

func _on_joy_connection_changed(device: int, connected: bool):
	if connected:
		print("InputManager: Controller connected - Device %d: %s" % [device, Input.get_joy_name(device)])
	else:
		print("InputManager: Controller disconnected - Device %d" % device)
		
		# Unassign any player using this device
		for i in range(MAX_PLAYERS):
			if player_devices[i] == device:
				print(" - Player %d lost their controller" % i)
				unregister_player(i)

# === VIBRATION (Optional) ===

func vibrate(player_id: int, weak_magnitude: float = 0.5, strong_magnitude: float = 0.5, duration: float = 0.2):
	var device = get_player_device(player_id)
	if device >= 0: # Only controllers can vibrate
		Input.start_joy_vibration(device, weak_magnitude, strong_magnitude, duration)

func stop_vibration(player_id: int):
	var device = get_player_device(player_id)
	if device >= 0:
		Input.stop_joy_vibration(device)
