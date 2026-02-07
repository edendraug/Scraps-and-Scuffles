extends Node
class_name CharacterSelectionManager

@export var cursor_scene: PackedScene # PlayerCursor scene
@export var cursor_colors: Array[Color] = [
	Color.BLUE,
	Color.RED,
	Color.GREEN,
	Color.YELLOW
]
@export var deselect_hold_time: float = 1.5
var deselect_timers: Dictionary = {} # player_id -> time held

var character_displays: Array[CharacterDisplay] = []
var player_cursors: Dictionary = {} # player_id -> PlayerCursor
var player_selections: Dictionary = {} # player_id ->CharacterDisplay

signal all_players_ready
signal player_selected_character(player_id: int)
signal player_deselected_character(player_id: int)

func _ready():
	# Find all character displays in scene
	await get_tree().process_frame
	find_character_displays()
	
	# TEMPORARY: Force join player 0 if not already joined
	if not GameSettings.is_player_joined(0):
		GameSettings.join_player(0, -1)
	
	# Create cursor for Player 0 (already joined by default)
	if GameSettings.is_player_joined(0):
		create_cursor_for_player(0)
		
	# Listen for new players joining
	GameSettings.player_joined.connect(_on_player_joined)
	GameSettings.player_left.connect(_on_player_left)

func _process(delta: float) -> void:
	# Check for deslection input (hold B)
	for player_id in player_selections.keys():
		if InputManager.is_action_pressed(player_id, "cancel"):
			# Increment hold timer
			if not deselect_timers.has(player_id):
				deselect_timers[player_id] = 0.0
			
			deselect_timers[player_id] += delta
			
			# Visual feedback - could add a progress bar here
			#print("Player ", player_id, " deselect hold: ", deselect_timers[player_id], " / ", deselect_hold_time)
			
			if deselect_timers[player_id] >= deselect_hold_time:
				deselect_player_character(player_id)
				deselect_timers.erase(player_id)
		else:
			# Button released - reset timer
			if deselect_timers.has(player_id):
				#print("Player ", player_id, " released cancel button - timer reset")
				deselect_timers.erase(player_id)
			
func find_character_displays():
	character_displays.clear()
	
	# Find all CharacterDisplay nodes
	for node in get_tree().get_nodes_in_group("CharacterDisplays"):
		if node is CharacterDisplay:
			character_displays.append(node)
			# Connect click signal
			node.character_clicked.connect(_on_character_clicked)
	
	print("Found ", character_displays.size(), " character displays")

func create_cursor_for_player(player_id: int):
	if player_cursors.has(player_id):
		return # Already has a cursor
	
	if not cursor_scene:
		push_error("No cursor scene assigned!")
		return
	
	var cursor = cursor_scene.instantiate()
	add_child(cursor)
	
	# Setup cursor
	if "player_id" in cursor:
		cursor.player_id = player_id
	
	if "player_color" in cursor and player_id < cursor_colors.size():
		cursor.player_color = cursor_colors[player_id]
	
	# Connect signals
	if cursor.has_signal("character_selected"):
		cursor.character_selected.connect(_on_character_selected)
	
	player_cursors[player_id] = cursor
	print("Created cursor for Player ", player_id)
	
func _on_character_selected(player_id: int, character_display: CharacterDisplay):
	# Store selected
	player_selections[player_id] = character_display
	
	# Update GameSettings
	GameSettings.set_player_character(player_id, character_display.character_data)
	
	player_selected_character.emit(player_id)
	
	print("Player ", player_id, " selected character")
	
	# Check if all players have selected
	check_if_all_ready()

func deselect_player_character(player_id: int):
	if not player_selections.has(player_id):
		return
	
	var character_display = player_selections[player_id]
	
	# Deselect the character
	character_display.deselect_character()
	
	# Clear from GameSettings
	GameSettings.set_player_character(player_id, null)
	
	# Remove from selections
	player_selections.erase(player_id)
	
	# Reactive cursor
	if player_cursors.has(player_id):
		player_cursors[player_id].activate_cursor()
	
	player_deselected_character.emit(player_id)
	print("Player ", player_id, " deselected character")

func check_if_all_ready() -> bool:
	# Check if all joined players have selected characters
	for player_id in GameSettings.get_joined_player_ids():
		if not player_selections.has(player_id):
			return false
	
	# All ready!
	print("All players have selected characters!")
	all_players_ready.emit()
	return true

func _on_character_clicked(display: CharacterDisplay):
	# Handle click events (for mouse input)
	# Find which cursor clicked it
	# For now, this is mainly for visual feedback
	print(display, " clicked")
	pass

func _on_player_joined(player_id: int):
	# Create cursor for newly joined player
	create_cursor_for_player(player_id)

func _on_player_left(player_id: int):
	# Remove cursor
	if player_cursors.has(player_id):
		player_cursors[player_id].queue_free()
		player_cursors.erase(player_id)
	
	# Deselect their character if they had one
	if player_selections.has(player_id):
		var character_display = player_selections[player_id]
		character_display.deselect_character()
		player_selections.erase(player_id)
