extends Camera2D
class_name LobbyCameraController

enum CameraState {
	FOLLOW_PLAYERS, # Follow all players around scene
	FOCUS_VOTED, # Show voted portals
	FOCUS_WINNER # Zoom on winning level
}

@export var lobby_center: Vector2 = Vector2.ZERO
@export var player_influence: float = 0.3
@export var max_offset_from_center: float = 200.0

@export var follow_smoothing: float = 5.0
@export var follow_zoom_level: float = 0.5
@export var vote_zoom_level: float = 0.7 # Zoom out to show voted levels
@export var winner_zoom_level: float = 1.2 # Zoom in on winner
@export var zoom_speed: float = 2.0

var current_state: CameraState = CameraState.FOLLOW_PLAYERS
var target_position: Vector2 = Vector2.ZERO
var target_zoom: float = 1.0
var portal_references: Array[LevelPortal] = []

func _ready():
	# Find all portals in the scene
	await get_tree().process_frame
	find_portals()
	
	# Connect to GameSettings signals
	GameSettings.level_voted.connect(_on_level_voted)

func _process(delta):
	match current_state:
		CameraState.FOLLOW_PLAYERS:
			follow_players(delta)
		CameraState.FOCUS_VOTED:
			focus_on_voted_portals(delta)
		CameraState.FOCUS_WINNER:
			focus_on_winner(delta)

func find_portals():
	portal_references.clear()
	for node in get_tree().get_nodes_in_group("LevelPortals"):
		if node is LevelPortal:
			portal_references.append(node)
	print("Found ", portal_references.size(), " portals")

func follow_players(delta):
	var players = get_tree().get_nodes_in_group("Players")
	var target_pos = lobby_center
	
	if not players.is_empty():
		# Calculate average position of all players
		var avg_player_pos = Vector2.ZERO
		for player in players:
			avg_player_pos += player.global_position
		avg_player_pos /= players.size()
		
		# Offset from center based on player positions
		var offset = (avg_player_pos - lobby_center) * player_influence
		offset = offset.limit_length(max_offset_from_center)
		
		target_pos = lobby_center + offset
	# Smooth camera movement
	global_position = global_position.lerp(target_pos, follow_smoothing * delta)
	
	# Reset zoom
	zoom = zoom.lerp(Vector2(follow_zoom_level, follow_zoom_level), zoom_speed * delta)

func focus_on_voted_portals(delta):
	var voted_levels = GameSettings.get_voted_levels()
	
	if voted_levels.is_empty():
		# No votes yet, follow players
		current_state = CameraState.FOLLOW_PLAYERS
		return
	
	# Find portals with votes
	var voted_portals: Array[LevelPortal] = []
	for portal in portal_references:
		if portal.level_data in voted_levels:
			voted_portals.append(portal)
	
	if voted_portals.is_empty():
		# Fallback to follow players if portals missing
		current_state = CameraState.FOLLOW_PLAYERS
		return
	
	# Calculate center of voted portals
	var center = Vector2.ZERO
	for portal in voted_portals:
		center += portal.global_position
	center /= voted_portals.size()
	
	# SMooth move to center
	global_position = global_position.lerp(center, follow_smoothing * delta)
	
	# Zoom out to show all voted portals
	var target_zoom_vec = Vector2.ONE * vote_zoom_level
	zoom = zoom.lerp(target_zoom_vec, zoom_speed * delta)

func focus_on_winner(delta):
	var winning_level = GameSettings.calculate_winning_level()
	
	if not winning_level:
		return
	
	# Find the winning portal
	var winner_portal: LevelPortal = null
	for portal in portal_references:
		if portal.level_data == winning_level:
			winner_portal = portal
			break
	
	if not winner_portal:
		return
	
	# Zoom in on winner
	global_position = global_position.lerp(winner_portal.global_position, follow_smoothing * delta)
	
	var target_zoom_vec = Vector2.ONE * winner_zoom_level
	zoom = zoom.lerp(target_zoom_vec, zoom_speed * delta)

func set_camera_state(state: CameraState):
	current_state = state
	print("Camera state changed to: ", CameraState.keys()[state])

func _on_level_voted(player_id: int, level: LevelData):
	# When vote changes, check if we should focus on votes
	if GameSettings.have_all_players_voted():
		# Don't change state yet, let voting manager handle it
		pass
