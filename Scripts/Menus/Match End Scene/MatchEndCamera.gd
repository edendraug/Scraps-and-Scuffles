extends Camera2D
class_name MatchEndCamera

enum CameraState {
	FOCUS_PLAYERS, # Initial - zoomed in on all players
	FOLLOW_WINNER, # During animation - follows winning player upward
	DYNAMIC_FOLLOW # After animation - centered with player influence
}

@export_group("Camera Settings")
@export var initial_zoom: float = 1.4 # Zoomed in at start
@export var follow_zoom: float = 0.8 # Zoomed out to see tall pedestals
@export var final_zoom: float = 1.0 # Normal zoom after animation
@export var zoom_speed: float = 1.0
@export var follow_smoothing: float = 5.0

@export_group("Dynamic Follow Settings")
@export var scene_center: Vector2 = Vector2.ZERO
@export var player_influence: float = 0.3 # How much players pull camera (0-1)
@export var max_offset_from_center: float = 200.0 # Max drift from center

@export_group("Margins")
@export var player_margin: Vector2 = Vector2(150, 200) # Padding around players (increased for tall pedestals)

var current_state: CameraState = CameraState.FOCUS_PLAYERS
var target_position: Vector2 = Vector2.ZERO
var target_zoom: float = 1.0
var player_references: Array[Node2D] = []
var winner_player: Node2D = null

func _ready() -> void:
	# Start with initial zoom
	zoom = Vector2.ONE * initial_zoom
	target_zoom = initial_zoom	

func _process(delta: float) -> void:
	match current_state:
		CameraState.FOCUS_PLAYERS:
			focus_on_players(delta)
		CameraState.FOLLOW_WINNER:
			follow_winner_vertical(delta)
		CameraState.DYNAMIC_FOLLOW:
			dynamic_follow_players(delta)
	
	# Smooth zoom
	var target_zoom_vec = Vector2.ONE * target_zoom
	zoom = zoom.lerp(target_zoom_vec, zoom_speed * delta)

func set_camera_state(state: CameraState):
	current_state = state
	print("MatchEndCamera: State changed to ", CameraState.keys()[state])

func set_player_references(players: Array[Node2D]):
	player_references = players

func set_winner(winner: Node2D):
	winner_player = winner

# === STATE 1: FOCUS PLAYERS (initial) ===
func focus_on_players(delta: float):
	if player_references.is_empty():
		return
	
	# Calculate required zoom to fit all players
	var rect = get_players_bounding_rect()
	if rect != Rect2():
		# Add margin
		rect = rect.grow_individual(player_margin.x, player_margin.y, player_margin.x, player_margin.y)
		
		# Calculate zoom needed to fit this rect
		var viewport_size = get_viewport_rect().size
		var zoom_x = viewport_size.x / rect.size.x
		var zoom_y = viewport_size.y / rect.size.y
		target_zoom = min(zoom_x, zoom_y)
		target_zoom = clamp(target_zoom, 0.3, initial_zoom)
	
	# Smooth movement
	global_position = global_position.lerp(get_average_position(), follow_smoothing * delta)

# === STATE 2: FOLLOW WINNER (During pedestal rise) ===
func follow_winner_vertical(delta: float):
	if not winner_player:
		print("No winning player")
		return
	
	if player_references.is_empty():
		return
	
	# Calculate required zoom to fit all players
	var rect = get_players_bounding_rect()
	if rect != Rect2():		
		# Add margin
		rect = rect.grow_individual(player_margin.x, player_margin.y, player_margin.x, player_margin.y)
		
		# Camera should center on the CENTER of the bounding rect (with margin)
		var rect_center = rect.get_center()
		
		# Calculate zoom needed to fit this rect
		var viewport_size = get_viewport_rect().size
		var zoom_x = viewport_size.x / rect.size.x
		var zoom_y = viewport_size.y / rect.size.y
		
		target_zoom = min(zoom_x, zoom_y)
		target_zoom = clamp(target_zoom, 0.05, follow_zoom)
		
		# Smooth movement to rect center
		var old_y = global_position.y
		global_position = global_position.lerp(rect_center, follow_smoothing * delta)
		var new_y = global_position.y
		
	else:
		target_zoom = follow_zoom
		# Fallback to average position
		global_position = global_position.lerp(get_average_position(), follow_smoothing * delta)

# === STATE 3: DYNAMIC FOLLOW (After animation) ===
func dynamic_follow_players(delta: float):
	if player_references.is_empty():
		return
	
	# Calculate zoom to fit all players with margin
	var rect = get_players_bounding_rect()
	if rect != Rect2():
		# Add margin
		rect = rect.grow_individual(player_margin.x, player_margin.y, player_margin.x, player_margin.y)
		
		# Get the center of the bounding rect
		var rect_center = rect.get_center()
		
		# Calculate offset from scene center based on rect center (not average player position)
		var offset = (rect_center - scene_center) * player_influence
		offset = offset.limit_length(max_offset_from_center)
		
		var target_pos = scene_center + offset
		
		# Calculate zoom needed to fit this rect
		var viewport_size = get_viewport_rect().size
		var zoom_x = viewport_size.x / rect.size.x
		var zoom_y = viewport_size.y / rect.size.y
		target_zoom = min(zoom_x, zoom_y)
		target_zoom = clamp(target_zoom, 0.05, final_zoom)
		
		# Smooth movement to target
		global_position = global_position.lerp(target_pos, follow_smoothing * delta)
	else:
		# Fallback if no rect
		target_zoom = final_zoom
		global_position = global_position.lerp(scene_center, follow_smoothing * delta)

# === HELPER FUNCTIONS ===
func get_players_bounding_rect() -> Rect2:
	if player_references.is_empty():
		return Rect2()
	
	# Start with first player position
	var rect = Rect2(player_references[0].global_position, Vector2.ONE)
	
	# Expand to include all players
	for player in player_references:
		rect = rect.expand(player.global_position)
	
	return rect

func start_pedestal_animation():
	# Called when pedestals start rising
	set_camera_state(CameraState.FOLLOW_WINNER)

func end_pedestal_animation():
	# Called when pedestals are finished
	# Wait a moment, then switch to dynamic follow
	await get_tree().create_timer(1.5).timeout
	
	set_camera_state(CameraState.DYNAMIC_FOLLOW)

func get_average_position() -> Vector2:
	# Calculate average player position
	var avg_pos = Vector2.ZERO
	for player in player_references:
		avg_pos += player.global_position
	avg_pos /= player_references.size()
	
	return avg_pos
