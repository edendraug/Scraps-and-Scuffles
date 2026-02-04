extends Node
class_name LevelManager

@export var player_spawn_points: Array[Marker2D] = [] # Assign spawn positions in editor
@export var default_spawn_position: Vector2 = Vector2(0, 0) # Fallback if no markers
@export var player_scene: PackedScene
var spawned_players: Array[Node] = []

signal players_spawned
signal level_ready

func _ready() -> void:
	# Wait a frame for scene to fully load
	await get_tree().process_frame
	
	# Spawn players based on GameSettings
	spawn_players()
	
	# Setup camera targets
	setup_camera()
	
	# Start game mode if GameModeManager exists
	if GameModeManager:
		GameModeManager.start_match()
	
	# Start natural resource spawning if applicable
	if NaturalResourceSpawner:
		NaturalResourceSpawner.spawn_initial_resources()
		NaturalResourceSpawner.start_spawning()
	
	level_ready.emit()

func spawn_players():
	print("=== SPAWNING PLAYERS ===")
	
	var joined_players = GameSettings.get_joined_player_ids()
	print("Joined players: ", joined_players)
	
	if joined_players.is_empty():
		push_warning("LevelManager: No players joined!")
		return
	
	for i in range(joined_players.size()):
		var player_id = joined_players[i]
		var character_data = GameSettings.get_player_character(player_id)
		
		print("Spawning Player ", player_id, " - Character: ", character_data)
		
		if not character_data:
			push_warning("LevelManager: Player ", player_id, " has no character selected!")
			continue
			
		# Get spawn position
		var spawn_pos = get_spawn_position(i)
		
		# Spawn the player
		var player = spawn_player(player_id, character_data, spawn_pos)
		
		if player:
			spawned_players.append(player)
			print("  Spawned Player ", player_id, " as ", character_data.character_name, " at ", spawn_pos)
	
	players_spawned.emit()
	print("=== ", spawned_players.size(), " PLAYERS SPAWNED ===")

func spawn_player(player_id: int, character_data: CharacterData, spawn_pos: Vector2) -> Node2D:
	if not player_scene:
		push_error("LevelManager: Could not load Player scene!")
		return null
	
	# Instantiate player
	var player = player_scene.instantiate()
	get_tree().current_scene.add_child(player)
	
	# Set position
	player.global_position = spawn_pos
	
	# Assign player ID
	if "player_id" in player:
		player.player_id = player_id
	
	# Swap sprite sheet based on character selection
	if character_data.sprite_sheet and player.has_node("SpriteManager"):
			var sprite_manager = player.get_node("SpriteManager")
			if sprite_manager.has_method("set_sprite_sheet"):
				sprite_manager.set_sprite_sheet(character_data.sprite_sheet)
	
	# Add to Players group
	if not player.is_in_group("Players"):
		player.add_to_group("Players")
	
	# Enabled controls (should be default, but just to be safe)
	if player.has_method("set_physics_process"):
		player.set_physics_process(true)
	if player.has_method("set_process"):
		player.set_process(true)
	
	return player

func get_spawn_position(player_index: int) -> Vector2:
	# Use spawn markers if available
	if player_index < player_spawn_points.size() and player_spawn_points[player_index]:
		return player_spawn_points[player_index].global_position
	
	# Fallback: sprear players horizontally from default position
	var offset = Vector2(player_index * 100, 0) # 100 pixel separation
	return default_spawn_position + offset

func setup_camera():
	# Find LevelCamera in scene
	var camera = get_tree().get_first_node_in_group("LevelCamera")
	
	if not camera:
		# Try to find any Camera2D
		for node in get_tree().current_scene.get_children():
			if node is Camera2D:
				camera = node
				break
	
	if camera and camera.has_method("_ready"):
		# Camera should automatically find players in "Players" group
		# Just make sure it refreshes its targets
		if "targets" in camera:
			camera.targets = get_tree().get_nodes_in_group("Players")

func get_spawned_players() -> Array[Node]:
	return spawned_players

func get_player_by_id(player_id: int) -> Node2D:
	for player in spawned_players:
		if "player_id" in player and player.player_id == player_id:
			return player
	return null
