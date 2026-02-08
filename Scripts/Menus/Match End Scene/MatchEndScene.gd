extends Node2D
class_name MatchEndScene

@export var player_scene: PackedScene
@export var pedestal_scene: PackedScene
@export var lobby_path: String

@export_group("Spawn Settings")
@export var spawn_positions: Array[Marker2D] # Where to spawn players/pedestals
@export var player_spawn_offset: Vector2 = Vector2(0, -50) # Offset player above pedestal

@export_group("Animation Settings")
@export var initial_pause_duration: float = 1.0
@export var rise_duration: float = 4.0
@export var units_per_point: float = 10.0 # Height growth per score point

@export_group("Exit Portal")
@export var exit_portal: Area2D # The areaplayers enter to return to lobby
@export var exit_hold_duration: float = 3.0

@export_group("Debug Mode")
@export var use_debug_mode: bool = false
@export var debug_player_count: int = 4
@export var debug_character_data: Array[CharacterData] = [] # Assign characters in inspector
@export var debug_scores :Array[int] = [100, 75, 50, 25] # Scores for each player

# Runtime data
var player_instances: Array[Node2D] = []
var pedestal_instances: Array[Node2D] = []
var player_scores: Dictionary = {} # player_id -> score
var player_characters: Dictionary = {} # player_id -> CharacterData

var exit_timer: float = 0.0
var someone_in_exit: bool = false

func _ready() -> void:
	# Get match results from GameModeManager
	fetch_match_results()
	
	# Spawn pedestals and players
	spawn_all()
	
	# Start the sequence
	await get_tree().create_timer(initial_pause_duration).timeout
	animate_pedestals()

func _process(delta: float) -> void:
	# Check exit portal
	if exit_portal and someone_in_exit:
		exit_timer += delta
		
		#TODO: Update UI showing progress (e.g. "Returning to lobby in 2 seconds...")
		
		if exit_timer >= exit_hold_duration:
			return_to_lobby()

func fetch_match_results():
	if use_debug_mode:
		# Use debug data instead of real match results
		print("=== DEBUG MODE ACTIVE ===")
		
		for i in range(debug_player_count):
			var player_id = i
			
			# Join player if not already joined
			if not GameSettings.is_player_joined(player_id):
				GameSettings.join_player(player_id, -1) # -1 = keyboard/mouse
			# Get score
			if i < debug_scores.size():
				player_scores[player_id] = debug_scores[i]
			else:
				player_scores[player_id] = 0
			
			# Get character data
			if i < debug_character_data.size() and debug_character_data[i]:
				player_characters[player_id] = debug_character_data[i]
				# Also set in GameSettings so sprite swapping works
				GameSettings.set_player_character(player_id, debug_character_data[i])
			else:
				# Create dummy character data if none provided
				var dummy_char = CharacterData.new()
				dummy_char.character_name = "Debug Player " + str(i + 1)
				player_characters[player_id] = dummy_char
				GameSettings.set_player_character(player_id, dummy_char)
		
		print("Debug Scores: ", player_scores)
		return
	
	# Normal mode- get real match results
	# Get final scores from GameModeManager
	if GameModeManager and GameModeManager.current_mode:
		player_scores = GameModeManager.current_mode.player_scores.duplicate()
	
	# Get character data from GameSettings
	for player_id in GameSettings.get_joined_player_ids():
		var character = GameSettings.get_player_character(player_id)
		if character:
			player_characters[player_id] = character
	
	print("Match End - Scores: ", player_scores)

func spawn_all():
	var player_ids_to_spawn: Array[int] = []
	
	if use_debug_mode:
		# In debug mode, spawn based on debug_player_count
		for i in range(debug_player_count):
			player_ids_to_spawn.append(i)
	else:
		# Normal mode - use actual joined players
		player_ids_to_spawn = GameSettings.get_joined_player_ids()
		
	for i in range(player_ids_to_spawn.size()):
		if i >= spawn_positions.size():
			push_warning("Not enough spawn positions for all players!")
			break
		
		var player_id = player_ids_to_spawn[i]
		var spawn_pos = spawn_positions[i].global_position
		
		# Spawn pedestal
		spawn_pedestal(player_id, spawn_pos, i)
		
		# Spawn player
		spawn_player(player_id, spawn_pos + player_spawn_offset, i)

func spawn_pedestal(player_id: int, position: Vector2, index:int):
	if not pedestal_scene:
		push_error("No pedestal scene assigned!")
		return
	
	var pedestal = pedestal_scene.instantiate()
	add_child(pedestal)
	pedestal.global_position = position
	
	# Initialize pedestal (if it has a script with setup method)
	if pedestal.has_method("setup"):
		var character_name = ""
		if player_characters.has(player_id):
			character_name = player_characters[player_id].character_name
		
		pedestal.setup(player_id, character_name)
	
	pedestal_instances.append(pedestal)

func spawn_player(player_id: int, position: Vector2, index: int):
	if not player_scene:
		push_error("No player scene assigned!")
		return
	
	var player = player_scene.instantiate()
	add_child(player)
	player.global_position = position
	
	# Setup player
	player.player_id = player_id
	
	# Swap sprite sheet
	var character_data = player_characters.get(player_id)
	if character_data and player.has_node("SpriteManager"):
		var sprite_manager = player.get_node("SpriteManager")
		if sprite_manager.has_method("set_sprite_sheet"):
			sprite_manager.set_sprite_sheet(character_data.sprite_sheet)
	
	# Disabled controls initially
	player.set_physics_process(false)
	player.set_process(false)
	
	# Add to group
	player.add_to_group("Players")
	
	player_instances.append(player)
	print("Spawned Player ", player_id, " at podium position ", index, " with score of ", player_scores[index])

func animate_pedestals():
	print("Animating pedestals based on scores...")
	
	# Get player IDs (either debug or real
	var player_ids_list: Array[int] = []
	if use_debug_mode:
		for i in range(debug_player_count):
			player_ids_list.append(i)
	else:
		player_ids_list = GameSettings.get_joined_player_ids()
	
	# Create one tween for all pedestels to animate simultaneously
	var master_tween = create_tween()
	master_tween.set_trans(Tween.TRANS_CUBIC)
	master_tween.set_ease(Tween.EASE_OUT)
	master_tween.set_parallel(true) # Make all animations parallel by default
	
	# Add all pedestal animations to the same tween
	for i in range(pedestal_instances.size()):
		var pedestal = pedestal_instances[i]
		
		if i >= player_ids_list.size():
			continue
		
		var player_id = player_ids_list[i]
		var score = player_scores.get(player_id, 0)
		var height_increase = score * units_per_point
		
		# Get the pedestal's growable column (must have this node!
		if not pedestal.has_method("grow_to_height_parallel"):
			push_error("Pedestal must have grow_to_height_parallel() method!")
			continue
		
		# Tell pedestal to grow (it will add its tweens to our master tween)
		pedestal.grow_to_height_parallel(height_increase, rise_duration, master_tween)
		
		# Animate player to follow pedestal
		var player = player_instances[i]
		var player_target = player.global_position + Vector2(0, -height_increase * 2)
		master_tween.tween_property(player, "global_position", player_target, rise_duration)
		
		print("Player ", player_id, " - Score: ", score, " - Height increase ", height_increase)
		
	# Wait for all animations to complete
	await get_tree().create_timer(rise_duration).timeout
	
	# Enable player controls after animation
	enable_all_player_controls()
	
	# Setup exit portal
	setup_exit_portal()

func enable_all_player_controls():
	print("Enabling player controls - players can move around!")
	
	for player in player_instances:
		player.set_physics_process(true)
		player.set_process(true)

func setup_exit_portal():
	if not exit_portal:
		push_warning("No exit portal assigned!")
		return
	
	# Connect portal signals
	if not exit_portal.body_entered.is_connected(_on_exit_portal_entered):
		exit_portal.body_entered.connect(_on_exit_portal_entered)
	if not exit_portal.body_exited.is_connected(_on_exit_portal_exited):
		exit_portal.body_exited.connect(_on_exit_portal_exited)
	
	print("Exit portal ready - any player can enter to return to lobby")

func _on_exit_portal_entered(body: Node2D):
	if body.is_in_group("Players"):
		someone_in_exit = true
		exit_timer = 0.0
		print("Player entered exit portal - hold for ", exit_hold_duration, " seconds")

func _on_exit_portal_exited(body: Node2D):
	if body.is_in_group("Players"):
		# Check if anyone else is still in the portal
		var players_in_portal = 0
		for area_body in exit_portal.get_overlapping_bodies():
			if area_body.is_in_group("Players"):
				players_in_portal += 1
		
		if players_in_portal == 0:
			someone_in_exit = false
			exit_timer = 0.0
			print("No players in exit portal - timer reset")

func return_to_lobby():
	print("Returning to Level Select Lobby...")
	
	# Clear player data ("They'll rejoin in lobby
	# Don't clear character selections though
	
	get_tree().change_scene_to_file(lobby_path)
		
