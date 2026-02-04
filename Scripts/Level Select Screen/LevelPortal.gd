extends Area2D
class_name LevelPortal

@export var level_data: LevelData

var players_in_portal: Array[Node2D] = []

signal player_entered_portal(player: Node2D, level, LevelData)
signal player_exited_portal(player: Node2D, level: LevelData)

func _ready():
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)
	
	# Set collisions to detect players
	collision_layer = 0
	collision_mask = 0b1000 # Layer 4 (players)
	
	if not level_data:
		push_warning("LevelPortal has no level_data assigned!")

func _on_body_entered(body: Node2D):
	if body.is_in_group("Players"):
		players_in_portal.append(body)
		player_entered_portal.emit(body, level_data)
		
		# Auto vote when entering portal
		var player_id = get_player_id(body)
		if player_id != -1:
			GameSettings.vote_for_level(player_id, level_data)

func _on_body_exited(body: Node2D):
	if body in players_in_portal:
		players_in_portal.erase(body)
		player_exited_portal.emit(body, level_data)

func get_player_id(player: Node2D) -> int:
	# Try to get player_id from the player node
	if player.has_method("get_player_id"):
		return player.get_player_id()
	
	if "player_id" in player:
		return player.player_id
	
	return -1

func get_vote_count() -> int:
	var count = 0
	for player_id in GameSettings.get_joined_player_ids():
		if GameSettings.get_player_vote(player_id) == level_data:
			count += 1
	return count
