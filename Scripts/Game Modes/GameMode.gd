extends Node
class_name GameMode

# Player tracking
var player_scores: Dictionary = {} # player_id -> score
var active_players: Array[Node] = []

# Match settings reference
var match_settings: MatchSettings

# Signals
signal score_updated(player_id: int, new_score: int)
signal mode_ended(winner_id: int)

func _init():
	pass

func start_mode(settings: MatchSettings, players: Array[Node]):
	match_settings = settings
	active_players = players
	
	# Initialize scores
	player_scores.clear()
	for i in range(active_players.size()):
		player_scores[i] = 0
	
	setup()

# Override this in subclasses
func setup():
	pass

func update_mode(delta: float):
	pass

func end_mode():
	cleanup()

func cleanup():
	pass

func add_score(player_id: int, points: int):
	if not player_scores.has(player_id):
		player_scores[player_id] = 0
	
	player_scores[player_id] += points
	score_updated.emit(player_id, player_scores[player_id])
	
	# Check win condition
	if match_settings.use_score_target and player_scores[player_id] >= match_settings.score_target:
		end_with_winner(player_id)

func get_player_score(player_id: int) -> int:
	return player_scores.get(player_id, 0)

func get_player_id(player: Node2D) -> int:
	for i in range(active_players.size()):
		if active_players[i] == player:
			return i
	return -1

func get_highest_score_player() -> int:
	var winner_id = -1
	var highest_score = -1
	
	for player_id in player_scores.keys():
		if player_scores[player_id] > highest_score:
			highest_score = player_scores[player_id]
			winner_id = player_id
	
	return winner_id

func end_with_winner(winner_id: int):
	mode_ended.emit(winner_id)

func print_scores():
	print("Current Scores:")
	for player_id in player_scores.keys():
		print("   Player ", player_id, ": ", player_scores[player_id])
