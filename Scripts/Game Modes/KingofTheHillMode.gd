extends GameMode
class_name KingOfTheHillMode

# Hill zone
var hill_zone: HillZone = null
var players_on_hill: Array[Node2D] = []

# Timers
var hill_relocate_timer: float = 0.0
var hill_warning_active: bool = false
var scoring_tick_timer: float = 0.0

# Signals
signal hill_relocated(new_position: Vector2)

func setup():
	print("Setting up King of the Hill mode")
	
	# Create hill zone
	spawn_hill()
	
	# Reset timers
	hill_relocate_timer = match_settings.hill_relocate_interval
	hill_warning_active = false
	scoring_tick_timer = 0.0
	players_on_hill.clear()

func update_mode(delta: float):
	# Update scoring tick
	scoring_tick_timer += delta
	if scoring_tick_timer >= match_settings.tick_interval:
		scoring_tick_timer = 0.0
		process_hill_scoring()
	
	# Update hill relocation timer
	hill_relocate_timer -= delta
	
	# Start warning before relocation
	if hill_relocate_timer <= match_settings.hill_warning_time and not hill_warning_active:
		hill_warning_active = true
		if hill_zone:
			hill_zone.start_warning()
		print("Hill relocated in ", match_settings.hill_warning_time, " seconds!")
	
	# Relocate hill
	if hill_relocate_timer <= 0:
		relocate_hill()

func cleanup():
	# Remove hill zone
	if hill_zone:
		hill_zone.queue_free()
		hill_zone = null
	
	players_on_hill.clear()

# === HILL MANAGEMENT ===
func spawn_hill():
	# Remove hill zone
	if hill_zone:
		hill_zone.queue_free()
	
	# Create new hill
	hill_zone = HillZone.new()
	get_tree().current_scene.add_child(hill_zone)
	hill_zone.set_radius(match_settings.hill_radius)
	
	# Position at random valid position
	var hill_pos = get_random_hill_position()
	hill_zone.global_position = hill_pos
	
	# Connect signals
	hill_zone.player_entered_hill.connect(_on_player_entered_hill)
	hill_zone.player_exited_hill.connect(_on_player_exited_hill)
	
	print("Hill spawned at: ", hill_pos)
	hill_relocated.emit(hill_pos)

func relocate_hill():
	print("Relocated hill...")
	
	# Reset timer
	hill_relocate_timer = match_settings.hill_relocate_interval
	hill_warning_active = false
	
	# Clear players on hill
	players_on_hill.clear()
	
	# Move to new position
	if hill_zone:
		hill_zone.stop_warning()
		var new_pos = get_random_hill_position()
		hill_zone.global_position = new_pos
		print("Hill relocated to: ", new_pos)
		hill_relocated.emit(new_pos)

func get_random_hill_position() -> Vector2:
	# Get bounds from NaturalResourceSpawner
	var spawn_settings = NaturalResourceSpawner.spawn_settings
	
	# Get random positition within level bounds
	# Make sure at least half the hill is visible (within bounds + radius/2)
	var margin = match_settings.hill_radius / 2
	
	var x = randf_range(
		spawn_settings.min_x + margin,
		spawn_settings.max_x - margin
	)
	var y = randf_range(
		spawn_settings.min_y + margin,
		spawn_settings.max_y - margin
	)
	return Vector2(x, y)

# === SCORING ===

func process_hill_scoring():
	#Check if exactly 1 player on hill
	if players_on_hill.size() == 1:
		# Award point
		var player = players_on_hill[0]
		var player_id = get_player_id(player)
		
		if player_id != -1:
			add_score(player_id, match_settings.points_per_tick)
			
			# Updated visual status
			if hill_zone:
				hill_zone.set_scoring(true)
	elif players_on_hill.size() > 1:
		#Contested - no points
		if hill_zone:
			hill_zone.set_contested(true)
	else:
		# No players
		if hill_zone:
			hill_zone.set_contested(false)
			hill_zone.set_scoring(false)

# == SIGNAL HANDLES ===
func _on_player_entered_hill(player: Node2D):
	if player not in players_on_hill:
		players_on_hill.append(player)
		print("Player entered hill. Players on hill: ", players_on_hill.size())

func _on_player_exited_hill(player: Node2D):
	if player in players_on_hill:
		players_on_hill.erase(player)
		print("Player exited hill. Players on hill: ", players_on_hill.size())
