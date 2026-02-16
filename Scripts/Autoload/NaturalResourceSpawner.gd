extends Node

@export var spawn_settings: SpawnSettings

# References to natural building data
var wood_building_data: BuildingData
var stone_building_data: BuildingData
var energy_building_data: BuildingData

# Spawn behavior scenes
var tree_seed_scene: PackedScene
var rock_scene: PackedScene
var energy_crystal_scene: PackedScene

# Runtime tracking
var active_natural_buildings: int = 0
var spawn_timer: Timer
var is_spawning_active: bool = false

func _ready():
	# Load default settings if none provided
	if not spawn_settings:
		spawn_settings = SpawnSettings.new()
	
	add_to_group("resource_spawner")
	
	# Setup spawn timer
	spawn_timer = Timer.new()
	add_child(spawn_timer)
	spawn_timer.timeout.connect(_on_spawn_timer_timeout)
	
	# Load natural building data and scenes
	load_natural_resources()

func load_natural_resources():
	# Load BuildingData resources for natural buildings
	# Adjust paths to match your project structure
	wood_building_data = load("res://Resources/Buildings/Natural/Tree_Data.tres") as BuildingData
	stone_building_data = load("res://Resources/Buildings/Natural/RockS_Data.tres") as BuildingData
	energy_building_data = load("res://Resources/Buildings/Natural/RockL_Data.tres") as BuildingData
	
	# Load spawn behavior scenes
	tree_seed_scene = preload("res://Scenes/Buildings/Natural/Spawners/Tree_Seed.tscn")
	rock_scene = preload("res://Scenes/Buildings/Natural/Spawners/Rock_Spawner.tscn")
	# energy_crystal_scene = preload("")

func start_spawning():
	is_spawning_active = true
	schedule_next_spawn()

func stop_spawning():
	is_spawning_active = false
	spawn_timer.stop()

func spawn_initial_resources():
	for i in range(spawn_settings.initial_spawn_count):
		spawn_natural_building_instant()

func spawn_natural_building_instant():
	# Instant spawn (no animation) - used for initial level setup
	if active_natural_buildings >= spawn_settings.max_natural_buildings:
		return
	
	var resource_type = spawn_settings.get_random_resource_type()
	var spawn_pos = get_random_spawn_position()
	
	if spawn_pos == Vector2.ZERO:
		print("No valid position found")
		return
	
	var building_data = get_building_data_for_type(resource_type)
	if not building_data or not building_data.building_scene:
		return
	
	# Get random variant scene
	var building_scene = building_data.get_random_building_scene()
	if not building_scene:
		return
	
	# Directly instantiate the building at the position
	var building = building_scene.instantiate()
	get_tree().current_scene.add_child(building)
	building.global_position = spawn_pos
	
	# Initialize the building
	if building.has_method("initialize"):
		building.initialize(building_data)
	
	# Track it
	active_natural_buildings += 1
	building.tree_exited.connect(_on_building_destroyed)

func spawn_natural_building_animated():
	# Animated spawn (drop from sky) - used during gameplay
	if active_natural_buildings >= spawn_settings.max_natural_buildings:
		return
	
	var resource_type = spawn_settings.get_random_resource_type()
	var spawn_target = get_random_spawn_position()
	
	if spawn_target == Vector2.ZERO:
		print("No valid position found")
		return
	
	match resource_type:
		"wood":
			spawn_tree_seed(spawn_target)
		"stone":
			spawn_rock(spawn_target)
		"energy":
			spawn_energy_crystal(spawn_target)

func spawn_tree_seed(target_pos: Vector2):
	if not tree_seed_scene:
		push_warning("Tree seed scene not loaded")
		return
	print("seed spawning")
	var seed = tree_seed_scene.instantiate()
	get_tree().current_scene.add_child(seed)
	
	# Start at top of screen at target X position
	seed.global_position = Vector2(target_pos.x, spawn_settings.min_y - 50)
	
	# Pass target and building data
	if seed.has_method("initialize"):
		seed.initialize(target_pos, wood_building_data)
	
	active_natural_buildings += 1

func spawn_rock(target_pos: Vector2):
	if not rock_scene:
		push_warning("Rock scene not loaded")
		return
	
	var rock = rock_scene.instantiate()
	get_tree().current_scene.add_child(rock)
	
	# Start at top of screen at target X position
	rock.global_position = Vector2(target_pos.x, spawn_settings.min_y - 50)
	
		# Pass target and building data
	if rock.has_method("initialize_rock"):
		rock.initialize_rock(target_pos, stone_building_data)
	
	active_natural_buildings += 1

func spawn_energy_crystal(target_pos: Vector2):
	if not energy_crystal_scene:
		#push_warning("Energy crystal scene not loaded")
		spawn_natural_building_instant()
		return
	
	var crystal = energy_crystal_scene.instantiate()
	get_tree().current_scene.add_child(crystal)
	
	# Start at top of screen at target X position
	crystal.global_position = Vector2(target_pos.x, spawn_settings.min_y - 50)
	
	active_natural_buildings += 1

func get_random_spawn_position() -> Vector2:
	var max_attempts = 10
	
	for attempt in range(max_attempts):
		# Random X within bounds
		var random_x = randf_range(spawn_settings.min_x, spawn_settings.max_x)
		
		# Raycast down to find platforms
		var space_state = get_tree().root.get_world_2d().direct_space_state
		var query = PhysicsRayQueryParameters2D.create(
			Vector2(random_x, spawn_settings.min_y),
			Vector2(random_x, spawn_settings.max_y)
		)
		query.collision_mask = 1 # Layer 1 (terrain)
		query.collide_with_areas = false
		query.collide_with_bodies = true
		
		# Collect all platforms this ray hits
		var platforms = []
		var current_y = spawn_settings.min_y
		
		# Cast multiple rays to find all platforms
		while current_y < spawn_settings.max_y:
			query.from = Vector2(random_x, current_y)
			var result = space_state.intersect_ray(query)
			
			if result:
				platforms.append(result.position)
				current_y = result.position.y + 10 # Move past this platform
			else:
				break
		
		if platforms.is_empty():
			continue # Try another X position
		
		# Pick random platforms from those found
		var chosen_platform = platforms[randi() % platforms.size()]
		
		# Check if position is clear (not too close to existing buildings/players)
		if is_position_clear(chosen_platform):
			return chosen_platform
	
	return Vector2.ZERO # Failed to find valid position

func is_position_clear(pos: Vector2, radius: float = 50.0) -> bool:
	# Check for nearby players
	var players = get_tree().get_nodes_in_group("Players")
	for player in players:
		if player.global_position.distance_to(pos) < radius:
			return false
	
	# Check for nearby buildings (optional might want resources to cluster)
	# For now, we'll allow clustering
	
	return true

func get_building_data_for_type(resource_type: String) -> BuildingData:
	match resource_type:
		"wood":
			return wood_building_data
		"stone":
			return stone_building_data
		"energy":
			return energy_building_data
	return null

func schedule_next_spawn():
	if not is_spawning_active:
		return
	
	var wait_time = randf_range(spawn_settings.spawn_interval_min, spawn_settings.spawn_interval_max)
	spawn_timer.start(wait_time)

func _on_spawn_timer_timeout():
	spawn_natural_building_animated()
	schedule_next_spawn()

func _on_building_destroyed():
	active_natural_buildings -= 1
